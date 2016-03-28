import Foundation
import SwiftSignalKit

public enum ViewUpdateType {
    case Generic
    case FillHole
}

final class ViewTracker {
    private let queue: Queue
    private let fetchEarlierHistoryEntries: (PeerId, MessageIndex?, Int, MessageTags?) -> [MutableMessageHistoryEntry]
    private let fetchLaterHistoryEntries: (PeerId, MessageIndex?, Int, MessageTags?) -> [MutableMessageHistoryEntry]
    private let fetchEarlierChatEntries: (MessageIndex?, Int) -> [MutableChatListEntry]
    private let fetchLaterChatEntries: (MessageIndex?, Int) -> [MutableChatListEntry]
    private let renderMessage: IntermediateMessage -> Message
    private let fetchChatListHole: ChatListHole -> Disposable
    private let fetchMessageHistoryHole: (MessageHistoryHole, MessageTags?) -> Disposable
    private let sendUnsentMessage: MessageIndex -> Disposable
    
    private var chatListViews = Bag<(MutableChatListView, Pipe<(ChatListView, ViewUpdateType)>)>()
    private var messageHistoryViews: [PeerId: Bag<(MutableMessageHistoryView, Pipe<(MessageHistoryView, ViewUpdateType)>)>] = [:]
    private var unsentMessageView: UnsentMessageHistoryView
    
    private var chatListHoleDisposables: [(ChatListHole, Disposable)] = []
    private var holeDisposablesByPeerId: [PeerId: [(MessageHistoryHole, Disposable)]] = [:]
    private var unsentMessageDisposables: [MessageIndex: Disposable] = [:]
    
    init(queue: Queue, fetchEarlierHistoryEntries: (PeerId, MessageIndex?, Int, MessageTags?) -> [MutableMessageHistoryEntry], fetchLaterHistoryEntries: (PeerId, MessageIndex?, Int, MessageTags?) -> [MutableMessageHistoryEntry], fetchEarlierChatEntries: (MessageIndex?, Int) -> [MutableChatListEntry], fetchLaterChatEntries: (MessageIndex?, Int) -> [MutableChatListEntry], renderMessage: IntermediateMessage -> Message, fetchChatListHole: ChatListHole -> Disposable, fetchMessageHistoryHole: (MessageHistoryHole, MessageTags?) -> Disposable, sendUnsentMessage: MessageIndex -> Disposable, unsentMessageIndices: [MessageIndex]) {
        self.queue = queue
        self.fetchEarlierHistoryEntries = fetchEarlierHistoryEntries
        self.fetchLaterHistoryEntries = fetchLaterHistoryEntries
        self.fetchEarlierChatEntries = fetchEarlierChatEntries
        self.fetchLaterChatEntries = fetchLaterChatEntries
        self.renderMessage = renderMessage
        self.fetchChatListHole = fetchChatListHole
        self.fetchMessageHistoryHole = fetchMessageHistoryHole
        self.sendUnsentMessage = sendUnsentMessage
        
        self.unsentMessageView = UnsentMessageHistoryView(indices: unsentMessageIndices)
        self.unsentViewUpdated()
    }
    
    deinit {
        for (_, disposable) in chatListHoleDisposables {
            disposable.dispose()
        }
        
        for (_, indexToDisposable) in holeDisposablesByPeerId {
            for (_, disposable) in indexToDisposable {
                disposable.dispose()
            }
        }
    }
    
    func addMessageHistoryView(peerId: PeerId, view: MutableMessageHistoryView) -> (Bag<(MutableMessageHistoryView, Pipe<(MessageHistoryView, ViewUpdateType)>)>.Index, Signal<(MessageHistoryView, ViewUpdateType), NoError>) {
        let record = (view, Pipe<(MessageHistoryView, ViewUpdateType)>())
        
        let index: Bag<(MutableMessageHistoryView, Pipe<(MessageHistoryView, ViewUpdateType)>)>.Index
        if let bag = self.messageHistoryViews[peerId] {
            index = bag.add(record)
        } else {
            let bag = Bag<(MutableMessageHistoryView, Pipe<(MessageHistoryView, ViewUpdateType)>)>()
            index = bag.add(record)
            self.messageHistoryViews[peerId] = bag
        }
        
        self.updateTrackedHoles(peerId)
        
        return (index, record.1.signal())
    }
    
    func removeMessageHistoryView(peerId: PeerId, index: Bag<(MutableMessageHistoryView, Pipe<(MessageHistoryView, ViewUpdateType)>)>.Index) {
        if let bag = self.messageHistoryViews[peerId] {
            bag.remove(index)
            
            self.updateTrackedHoles(peerId)
        }
    }
    
    func addChatListView(view: MutableChatListView) -> (Bag<(MutableChatListView, Pipe<(ChatListView, ViewUpdateType)>)>.Index, Signal<(ChatListView, ViewUpdateType), NoError>) {
        let record = (view, Pipe<(ChatListView, ViewUpdateType)>())
        let index = self.chatListViews.add(record)
        
        self.updateTrackedChatListHoles()
        
        return (index, record.1.signal())
    }
    
    func removeChatListView(index: Bag<(MutableChatListView, Pipe<ChatListView>)>.Index) {
        self.chatListViews.remove(index)
        self.updateTrackedChatListHoles()
    }
    
    func updateViews(currentOperationsByPeerId currentOperationsByPeerId: [PeerId: [MessageHistoryOperation]], peerIdsWithFilledHoles: Set<PeerId>, chatListOperations: [ChatListOperation], currentUpdatedPeers: [PeerId: Peer], unsentMessageOperations: [IntermediateMessageHistoryUnsentOperation]) {
        var updateTrackedHolesPeerIds: [PeerId] = []
        
        for (peerId, bag) in self.messageHistoryViews {
            var updateHoles = false
            if let operations = currentOperationsByPeerId[peerId] {
                updateHoles = true
                for (mutableView, pipe) in bag.copyItems() {
                    let context = MutableMessageHistoryViewReplayContext()
                    var updated = false
                    
                    if mutableView.replay(operations, context: context) {
                        mutableView.complete(context, fetchEarlier: { index, count in
                            return self.fetchEarlierHistoryEntries(peerId, index, count, mutableView.tagMask)
                        }, fetchLater: { index, count in
                            return self.fetchLaterHistoryEntries(peerId, index, count, mutableView.tagMask)
                        })
                        updated = true
                    }
                    
                    if mutableView.updatePeers(currentUpdatedPeers) {
                        updated = true
                    }
                    
                    if updated {
                        mutableView.render(self.renderMessage)
                        pipe.putNext((MessageHistoryView(mutableView), peerIdsWithFilledHoles.contains(peerId) ? .FillHole : .Generic))
                    }
                }
            }
            
            if updateHoles {
                updateTrackedHolesPeerIds.append(peerId)
            }
        }
        
        if chatListOperations.count != 0 {
            for (mutableView, pipe) in self.chatListViews.copyItems() {
                let context = MutableChatListViewReplayContext()
                if mutableView.replay(chatListOperations, context: context) {
                    mutableView.complete(context, fetchEarlier: self.fetchEarlierChatEntries, fetchLater: self.fetchLaterChatEntries)
                    mutableView.render(self.renderMessage)
                    pipe.putNext((ChatListView(mutableView), .Generic))
                }
            }
            
            self.updateTrackedChatListHoles()
        }
        
        for peerId in updateTrackedHolesPeerIds {
            self.updateTrackedHoles(peerId)
        }
        
        if self.unsentMessageView.replay(unsentMessageOperations) {
            self.unsentViewUpdated()
        }
    }
    
    private func updateTrackedChatListHoles() {
        var disposeHoles: [Disposable] = []
        var firstHoles: [ChatListHole] = []
        
        for (view, _) in self.chatListViews.copyItems() {
            if let hole = view.firstHole() {
                var exists = false
                for existingHole in firstHoles {
                    if existingHole == hole {
                        exists = true
                        break
                    }
                }
                if !exists {
                    firstHoles.append(hole)
                }
            }
        }
    
        var i = 0
        for (hole, disposable) in self.chatListHoleDisposables {
            var exists = false
            for firstHole in firstHoles {
                if hole == firstHole {
                    exists = true
                    break
                }
            }
            if !exists {
                disposeHoles.append(disposable)
                self.chatListHoleDisposables.removeAtIndex(i)
            } else {
                i += 1
            }
        }
        
        for disposable in disposeHoles {
            disposable.dispose()
        }
        
        for hole in firstHoles {
            var exists = false
            for (existingHole, _) in self.chatListHoleDisposables {
                if existingHole == hole {
                    exists = true
                    break
                }
            }
            
            if !exists {
                self.chatListHoleDisposables.append((hole, self.fetchChatListHole(hole)))
            }
        }
    }
    
    private func updateTrackedHoles(peerId: PeerId) {
        if let bag = self.messageHistoryViews[peerId]  {
            var disposeHoles: [Disposable] = []
            var firstHolesAndTags: [(MessageHistoryHole, MessageTags?)] = []
            
            for (view, _) in bag.copyItems() {
                if let hole = view.firstHole() {
                    firstHolesAndTags.append((hole, view.tagMask))
                }
            }
            
            if let holes = self.holeDisposablesByPeerId[peerId] {
                var i = 0
                for (hole, disposable) in holes {
                    var exists = false
                    for (firstHole, _) in firstHolesAndTags {
                        if hole == firstHole {
                            exists = true
                            break
                        }
                    }
                    if !exists {
                        disposeHoles.append(disposable)
                        self.holeDisposablesByPeerId[peerId]!.removeAtIndex(i)
                    } else {
                        i += 1
                    }
                }
            }
            
            for disposable in disposeHoles {
                disposable.dispose()
            }
            
            if let anyHoleAndTag = firstHolesAndTags.first {
                if self.holeDisposablesByPeerId[peerId] == nil || self.holeDisposablesByPeerId[peerId]!.count == 0 {
                    var exists = false
                    if let existingHoles = self.holeDisposablesByPeerId[peerId] {
                        for (existingHole, _) in existingHoles {
                            if existingHole == anyHoleAndTag.0 {
                                exists = true
                                break
                            }
                        }
                    }
                    
                    if !exists {
                        if self.holeDisposablesByPeerId[peerId] == nil {
                            self.holeDisposablesByPeerId[peerId] = []
                        }
                        
                        self.holeDisposablesByPeerId[peerId]!.append((anyHoleAndTag.0, self.fetchMessageHistoryHole(anyHoleAndTag.0, anyHoleAndTag.1)))
                    }
                }
            }
        } else if let holes = self.holeDisposablesByPeerId[peerId] {
            self.holeDisposablesByPeerId[peerId]?.removeAll()
            
            for (_, disposable) in holes {
                disposable.dispose()
            }
        }
    }
    
    private func unsentViewUpdated() {
        var removeIndices: [MessageIndex] = []
        for (index, _) in unsentMessageDisposables {
            var found = false
            for currentIndex in self.unsentMessageView.indices {
                if currentIndex == index {
                    found = true
                    break
                }
            }
            
            if !found {
                removeIndices.append(index)
            }
        }
        
        for index in removeIndices {
            self.unsentMessageDisposables.removeValueForKey(index)?.dispose()
        }
        
        for index in self.unsentMessageView.indices {
            var found = false
            for (currentIndex, _) in unsentMessageDisposables {
                if index == currentIndex {
                    found = true
                    break
                }
            }
            
            if !found {
                self.unsentMessageDisposables[index] = self.sendUnsentMessage(index)
            }
        }
    }
}
