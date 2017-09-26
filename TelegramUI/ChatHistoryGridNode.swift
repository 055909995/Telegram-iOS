import Foundation
import Postbox
import SwiftSignalKit
import Display
import AsyncDisplayKit
import TelegramCore

struct ChatHistoryGridViewTransition {
    let historyView: ChatHistoryView
    let topOffsetWithinMonth: Int
    let deleteItems: [Int]
    let insertItems: [GridNodeInsertItem]
    let updateItems: [GridNodeUpdateItem]
    let scrollToItem: GridNodeScrollToItem?
    let stationaryItems: GridNodeStationaryItems
}

private func mappedInsertEntries(account: Account, peerId: PeerId, controllerInteraction: ChatControllerInteraction, entries: [ChatHistoryViewTransitionInsertEntry], theme: PresentationTheme, strings: PresentationStrings) -> [GridNodeInsertItem] {
    return entries.map { entry -> GridNodeInsertItem in
        switch entry.entry {
            case let .MessageEntry(message, _, _, _, _):
                return GridNodeInsertItem(index: entry.index, item: GridMessageItem(theme: theme, strings: strings, account: account, message: message, controllerInteraction: controllerInteraction), previousIndex: entry.previousIndex)
            case .HoleEntry:
                return GridNodeInsertItem(index: entry.index, item: GridHoleItem(), previousIndex: entry.previousIndex)
            case .UnreadEntry:
                assertionFailure()
                return GridNodeInsertItem(index: entry.index, item: GridHoleItem(), previousIndex: entry.previousIndex)
            case .ChatInfoEntry, .EmptyChatInfoEntry, .SearchEntry:
                assertionFailure()
                return GridNodeInsertItem(index: entry.index, item: GridHoleItem(), previousIndex: entry.previousIndex)
        }
    }
}

private func mappedUpdateEntries(account: Account, peerId: PeerId, controllerInteraction: ChatControllerInteraction, entries: [ChatHistoryViewTransitionUpdateEntry], theme: PresentationTheme, strings: PresentationStrings) -> [GridNodeUpdateItem] {
    return entries.map { entry -> GridNodeUpdateItem in
        switch entry.entry {
            case let .MessageEntry(message, _, _, _, _):
                return GridNodeUpdateItem(index: entry.index, previousIndex: entry.previousIndex, item: GridMessageItem(theme: theme, strings: strings, account: account, message: message, controllerInteraction: controllerInteraction))
            case .HoleEntry:
                return GridNodeUpdateItem(index: entry.index, previousIndex: entry.previousIndex, item: GridHoleItem())
            case .UnreadEntry:
                assertionFailure()
                return GridNodeUpdateItem(index: entry.index, previousIndex: entry.previousIndex, item: GridHoleItem())
            case .ChatInfoEntry, .EmptyChatInfoEntry, .SearchEntry:
                assertionFailure()
                return GridNodeUpdateItem(index: entry.index, previousIndex: entry.previousIndex, item: GridHoleItem())
        }
    }
}

private func mappedChatHistoryViewListTransition(account: Account, peerId: PeerId, controllerInteraction: ChatControllerInteraction, transition: ChatHistoryViewTransition, from: ChatHistoryView?, theme: PresentationTheme, strings: PresentationStrings) -> ChatHistoryGridViewTransition {
    var mappedScrollToItem: GridNodeScrollToItem?
    if let scrollToItem = transition.scrollToItem {
        let mappedPosition: GridNodeScrollToItemPosition
        switch scrollToItem.position {
            case .top:
                mappedPosition = .top
            case .center:
                mappedPosition = .center
            case .bottom:
                mappedPosition = .bottom
        }
        let scrollTransition: ContainedViewLayoutTransition
        if scrollToItem.animated {
            switch scrollToItem.curve {
                case .Default:
                    scrollTransition = .animated(duration: 0.3, curve: .easeInOut)
                case let .Spring(duration):
                    scrollTransition = .animated(duration: duration, curve: .spring)
            }
        } else {
            scrollTransition = .immediate
        }
        let directionHint: GridNodePreviousItemsTransitionDirectionHint
        switch scrollToItem.directionHint {
            case .Up:
                directionHint = .up
            case .Down:
                directionHint = .down
        }
        mappedScrollToItem = GridNodeScrollToItem(index: scrollToItem.index, position: mappedPosition, transition: scrollTransition, directionHint: directionHint, adjustForSection: true, adjustForTopInset: true)
    }
    
    var stationaryItems: GridNodeStationaryItems = .none
    if let previousView = from {
        if let stationaryRange = transition.stationaryItemRange {
            var fromStableIds = Set<UInt64>()
            for i in 0 ..< previousView.filteredEntries.count {
                if i >= stationaryRange.0 && i <= stationaryRange.1 {
                    fromStableIds.insert(previousView.filteredEntries[i].stableId)
                }
            }
            var index = 0
            var indices = Set<Int>()
            for entry in transition.historyView.filteredEntries {
                if fromStableIds.contains(entry.stableId) {
                    indices.insert(transition.historyView.filteredEntries.count - 1 - index)
                }
                index += 1
            }
            stationaryItems = .indices(indices)
        } else {
            var fromStableIds = Set<UInt64>()
            for i in 0 ..< previousView.filteredEntries.count {
                fromStableIds.insert(previousView.filteredEntries[i].stableId)
            }
            var index = 0
            var indices = Set<Int>()
            for entry in transition.historyView.filteredEntries {
                if fromStableIds.contains(entry.stableId) {
                    indices.insert(transition.historyView.filteredEntries.count - 1 - index)
                }
                index += 1
            }
            stationaryItems = .indices(indices)
        }
    }
    
    var topOffsetWithinMonth: Int = 0
    if let lastEntry = transition.historyView.filteredEntries.last {
        switch lastEntry {
            case let .MessageEntry(_, _, _, _,  monthLocation):
                if let monthLocation = monthLocation {
                    topOffsetWithinMonth = Int(monthLocation.indexInMonth)
                }
            default:
                break
        }
    }
    
    return ChatHistoryGridViewTransition(historyView: transition.historyView, topOffsetWithinMonth: topOffsetWithinMonth, deleteItems: transition.deleteItems.map { $0.index }, insertItems: mappedInsertEntries(account: account, peerId: peerId, controllerInteraction: controllerInteraction, entries: transition.insertEntries, theme: theme, strings: strings), updateItems: mappedUpdateEntries(account: account, peerId: peerId, controllerInteraction: controllerInteraction, entries: transition.updateEntries, theme: theme, strings: strings), scrollToItem: mappedScrollToItem, stationaryItems: stationaryItems)
}

private func itemSizeForContainerLayout(size: CGSize) -> CGSize {
    let side = floor(size.width / 4.0)
    return CGSize(width: side, height: side)
}

public final class ChatHistoryGridNode: GridNode, ChatHistoryNode {
    private let account: Account
    private let peerId: PeerId
    private let messageId: MessageId?
    private let tagMask: MessageTags?
    
    private var historyView: ChatHistoryView?
    
    private let historyDisposable = MetaDisposable()
    
    private let messageViewQueue = Queue()
    
    private var dequeuedInitialTransitionOnLayout = false
    private var enqueuedHistoryViewTransition: (ChatHistoryGridViewTransition, () -> Void)?
    var layoutActionOnViewTransition: ((ChatHistoryGridViewTransition) -> (ChatHistoryGridViewTransition, ListViewUpdateSizeAndInsets?))?
    
    public let historyState = ValuePromise<ChatHistoryNodeHistoryState>()
    private var currentHistoryState: ChatHistoryNodeHistoryState?
    
    public var preloadPages: Bool = true {
        didSet {
            if self.preloadPages != oldValue {
                
            }
        }
    }
    
    private let _chatHistoryLocation = ValuePromise<ChatHistoryLocation>(ignoreRepeated: true)
    private var chatHistoryLocation: Signal<ChatHistoryLocation, NoError> {
        return self._chatHistoryLocation.get()
    }
    
    private let galleryHiddenMesageAndMediaDisposable = MetaDisposable()
    
    private var presentationData: PresentationData
    private let themeAndStringsPromise = Promise<(PresentationTheme, PresentationStrings)>()
    
    public private(set) var loadState: ChatHistoryNodeLoadState?
    private var loadStateUpdated: ((ChatHistoryNodeLoadState) -> Void)?
    
    public init(account: Account, peerId: PeerId, messageId: MessageId?, tagMask: MessageTags?, controllerInteraction: ChatControllerInteraction) {
        self.account = account
        self.peerId = peerId
        self.messageId = messageId
        self.tagMask = tagMask
        
        self.presentationData = account.telegramApplicationContext.currentPresentationData.with { $0 }
        
        super.init()
        
        self.themeAndStringsPromise.set(.single((self.presentationData.theme, self.presentationData.strings)))
        
        self.floatingSections = true
        
        //self.preloadPages = false
        
        let messageViewQueue = self.messageViewQueue
        
        let historyViewUpdate = self.chatHistoryLocation
            |> distinctUntilChanged
            |> mapToSignal { location in
                return chatHistoryViewForLocation(location, account: account, peerId: peerId, fixedCombinedReadState: nil, tagMask: tagMask, additionalData: [], orderStatistics: [.locationWithinMonth])
        }
        
        let previousView = Atomic<ChatHistoryView?>(value: nil)
        
        let historyViewTransition = combineLatest(historyViewUpdate, self.themeAndStringsPromise.get()) |> mapToQueue { [weak self] update, themeAndStrings -> Signal<ChatHistoryGridViewTransition, NoError> in
            switch update {
                case .Loading:
                    Queue.mainQueue().async { [weak self] in
                        if let strongSelf = self {
                            let loadState: ChatHistoryNodeLoadState = .loading
                            if strongSelf.loadState != loadState {
                                strongSelf.loadState = loadState
                                strongSelf.loadStateUpdated?(loadState)
                            }
                            
                            let historyState: ChatHistoryNodeHistoryState = .loading
                            if strongSelf.currentHistoryState != historyState {
                                strongSelf.currentHistoryState = historyState
                                strongSelf.historyState.set(historyState)
                            }
                        }
                    }
                    return .complete()
                case let .HistoryView(view, type, scrollPosition, _):
                    let reason: ChatHistoryViewTransitionReason
                    var prepareOnMainQueue = false
                    switch type {
                        case let .Initial(fadeIn):
                            reason = ChatHistoryViewTransitionReason.Initial(fadeIn: fadeIn)
                            prepareOnMainQueue = !fadeIn
                        case let .Generic(genericType):
                            switch genericType {
                                case .InitialUnread:
                                    reason = ChatHistoryViewTransitionReason.Initial(fadeIn: false)
                                case .Generic:
                                    reason = ChatHistoryViewTransitionReason.InteractiveChanges
                                case .UpdateVisible:
                                    reason = ChatHistoryViewTransitionReason.Reload
                                case let .FillHole(insertions, deletions):
                                    reason = ChatHistoryViewTransitionReason.HoleChanges(filledHoleDirections: insertions, removeHoleDirections: deletions)
                            }
                    }
                    
                    let processedView = ChatHistoryView(originalView: view, filteredEntries: chatHistoryEntriesForView(view, includeUnreadEntry: false, includeEmptyEntry: false, includeChatInfoEntry: false, includeSearchEntry: false, theme: themeAndStrings.0, strings: themeAndStrings.1))
                    let previous = previousView.swap(processedView)
                    
                    return preparedChatHistoryViewTransition(from: previous, to: processedView, reason: reason, account: account, peerId: peerId, controllerInteraction: controllerInteraction, scrollPosition: scrollPosition, initialData: nil, keyboardButtonsMessage: nil, cachedData: nil, cachedDataMessages: nil, readStateData: nil) |> map({ mappedChatHistoryViewListTransition(account: account, peerId: peerId, controllerInteraction: controllerInteraction, transition: $0, from: previous, theme: themeAndStrings.0, strings: themeAndStrings.1) }) |> runOn(prepareOnMainQueue ? Queue.mainQueue() : messageViewQueue)
            }
        }
        
        let appliedTransition = historyViewTransition |> deliverOnMainQueue |> mapToQueue { [weak self] transition -> Signal<Void, NoError> in
            if let strongSelf = self {
                return strongSelf.enqueueHistoryViewTransition(transition)
            }
            return .complete()
        }
        
        self.historyDisposable.set(appliedTransition.start())
        
        if let messageId = messageId {
            self._chatHistoryLocation.set(ChatHistoryLocation.InitialSearch(location: .id(messageId), count: 100))
        } else {
            self._chatHistoryLocation.set(ChatHistoryLocation.Initial(count: 100))
        }
        
        self.visibleItemsUpdated = { [weak self] visibleItems in
            if let strongSelf = self, let historyView = strongSelf.historyView, let top = visibleItems.top, let bottom = visibleItems.bottom {
                if top.0 < 5 && historyView.originalView.laterId != nil {
                    let lastEntry = historyView.filteredEntries[historyView.filteredEntries.count - 1 - top.0]
                    strongSelf._chatHistoryLocation.set(ChatHistoryLocation.Navigation(index: lastEntry.index, anchorIndex: historyView.originalView.anchorIndex))
                } else if bottom.0 >= historyView.filteredEntries.count - 5 && historyView.originalView.earlierId != nil {
                    let firstEntry = historyView.filteredEntries[historyView.filteredEntries.count - 1 - bottom.0]
                    strongSelf._chatHistoryLocation.set(ChatHistoryLocation.Navigation(index: firstEntry.index, anchorIndex: historyView.originalView.anchorIndex))
                }
            }
        }
        
        /*self.displayedItemRangeChanged = { [weak self] displayedRange in
            if let strongSelf = self {
                /*if let transactionTag = strongSelf.listViewTransactionTag {
                 strongSelf.messageViewQueue.dispatch {
                 if transactionTag == strongSelf.historyViewTransactionTag {
                 if let range = range, historyView = strongSelf.historyView, firstEntry = historyView.filteredEntries.first, lastEntry = historyView.filteredEntries.last {
                 if range.firstIndex < 5 && historyView.originalView.laterId != nil {
                 strongSelf._chatHistoryLocation.set(.single(ChatHistoryLocation.Navigation(index: lastEntry.index, anchorIndex: historyView.originalView.anchorIndex)))
                 } else if range.lastIndex >= historyView.filteredEntries.count - 5 && historyView.originalView.earlierId != nil {
                 strongSelf._chatHistoryLocation.set(.single(ChatHistoryLocation.Navigation(index: firstEntry.index, anchorIndex: historyView.originalView.anchorIndex)))
                 } else {
                 //strongSelf.account.postbox.updateMessageHistoryViewVisibleRange(messageView.id, earliestVisibleIndex: viewEntries[viewEntries.count - 1 - range.lastIndex].index, latestVisibleIndex: viewEntries[viewEntries.count - 1 - range.firstIndex].index)
                 }
                 }
                 }
                 }
                 }*/
                
                if let visible = displayedRange.visibleRange, let historyView = strongSelf.historyView {
                    if let messageId = maxIncomingMessageIdForEntries(historyView.filteredEntries, indexRange: (historyView.filteredEntries.count - 1 - visible.lastIndex, historyView.filteredEntries.count - 1 - visible.firstIndex)) {
                        strongSelf.updateMaxVisibleReadIncomingMessageId(messageId)
                    }
                }
            }
        }*/
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.historyDisposable.dispose()
    }
    
    public func setLoadStateUpdated(_ f: @escaping (ChatHistoryNodeLoadState) -> Void) {
        self.loadStateUpdated = f
    }
    
    public func scrollToStartOfHistory() {
        self._chatHistoryLocation.set(ChatHistoryLocation.Scroll(index: MessageIndex.lowerBound(peerId: self.peerId), anchorIndex: MessageIndex.lowerBound(peerId: self.peerId), sourceIndex: MessageIndex.upperBound(peerId: self.peerId), scrollPosition: .bottom(0.0), animated: true))
    }
    
    public func scrollToEndOfHistory() {
        self._chatHistoryLocation.set(ChatHistoryLocation.Scroll(index: MessageIndex.upperBound(peerId: self.peerId), anchorIndex: MessageIndex.upperBound(peerId: self.peerId), sourceIndex: MessageIndex.lowerBound(peerId: self.peerId), scrollPosition: .top(0.0), animated: true))
    }
    
    public func scrollToMessage(from fromIndex: MessageIndex, to toIndex: MessageIndex) {
        self._chatHistoryLocation.set(ChatHistoryLocation.Scroll(index: toIndex, anchorIndex: toIndex, sourceIndex: fromIndex, scrollPosition: .center(.bottom), animated: true))
    }
    
    public func messageInCurrentHistoryView(_ id: MessageId) -> Message? {
        if let historyView = self.historyView {
            for case let .MessageEntry(message, _, _, _, _) in historyView.filteredEntries where message.id == id {
                return message
            }
        }
        return nil
    }
    
    private func enqueueHistoryViewTransition(_ transition: ChatHistoryGridViewTransition) -> Signal<Void, NoError> {
        return Signal { [weak self] subscriber in
            if let strongSelf = self {
                if let _ = strongSelf.enqueuedHistoryViewTransition {
                    preconditionFailure()
                }
                
                strongSelf.enqueuedHistoryViewTransition = (transition, {
                    subscriber.putCompletion()
                })
                
                if strongSelf.isNodeLoaded {
                    strongSelf.dequeueHistoryViewTransition()
                } else {
                    let loadState: ChatHistoryNodeLoadState
                    if transition.historyView.filteredEntries.isEmpty {
                        loadState = .empty
                    } else {
                        loadState = .messages
                    }
                    if strongSelf.loadState != loadState {
                        strongSelf.loadState = loadState
                        strongSelf.loadStateUpdated?(loadState)
                    }
                    
                    let historyState: ChatHistoryNodeHistoryState = .loaded(isEmpty: transition.historyView.originalView.entries.isEmpty)
                    if strongSelf.currentHistoryState != historyState {
                        strongSelf.currentHistoryState = historyState
                        strongSelf.historyState.set(historyState)
                    }
                }
            } else {
                subscriber.putCompletion()
            }
            
            return EmptyDisposable
        } |> runOn(Queue.mainQueue())
    }
    
    private func dequeueHistoryViewTransition() {
        if let (transition, completion) = self.enqueuedHistoryViewTransition {
            self.enqueuedHistoryViewTransition = nil
            
            let completion: (GridNodeDisplayedItemRange) -> Void = { [weak self] visibleRange in
                if let strongSelf = self {
                    strongSelf.historyView = transition.historyView
                    
                    if let range = visibleRange.loadedRange {
                        strongSelf.account.postbox.updateMessageHistoryViewVisibleRange(transition.historyView.originalView.id, earliestVisibleIndex: transition.historyView.filteredEntries[transition.historyView.filteredEntries.count - 1 - range.upperBound].index, latestVisibleIndex: transition.historyView.filteredEntries[transition.historyView.filteredEntries.count - 1 - range.lowerBound].index)
                    }
                    
                    let loadState: ChatHistoryNodeLoadState
                    if let historyView = strongSelf.historyView {
                        if historyView.filteredEntries.isEmpty {
                            loadState = .empty
                        } else {
                            loadState = .messages
                        }
                    } else {
                        loadState = .loading
                    }
                    
                    if strongSelf.loadState != loadState {
                        strongSelf.loadState = loadState
                        strongSelf.loadStateUpdated?(loadState)
                    }
                    
                    let historyState: ChatHistoryNodeHistoryState = .loaded(isEmpty: transition.historyView.originalView.entries.isEmpty)
                    if strongSelf.currentHistoryState != historyState {
                        strongSelf.currentHistoryState = historyState
                        strongSelf.historyState.set(historyState)
                    }
                    
                    completion()
                }
            }
            
            if let layoutActionOnViewTransition = self.layoutActionOnViewTransition {
                self.layoutActionOnViewTransition = nil
                let (mappedTransition, updateSizeAndInsets) = layoutActionOnViewTransition(transition)
                
                var updateLayout: GridNodeUpdateLayout?
                if let updateSizeAndInsets = updateSizeAndInsets {
                    updateLayout = GridNodeUpdateLayout(layout: GridNodeLayout(size: updateSizeAndInsets.size, insets: updateSizeAndInsets.insets, preloadSize: 400.0, type: .fixed(itemSize: CGSize(width: 200.0, height: 200.0), lineSpacing: 0.0)), transition: .immediate)
                }
                
                self.transaction(GridNodeTransaction(deleteItems: mappedTransition.deleteItems, insertItems: mappedTransition.insertItems, updateItems: mappedTransition.updateItems, scrollToItem: mappedTransition.scrollToItem, updateLayout: updateLayout, itemTransition: .immediate, stationaryItems: transition.stationaryItems, updateFirstIndexInSectionOffset: mappedTransition.topOffsetWithinMonth), completion: completion)
            } else {
                self.transaction(GridNodeTransaction(deleteItems: transition.deleteItems, insertItems: transition.insertItems, updateItems: transition.updateItems, scrollToItem: transition.scrollToItem, updateLayout: nil, itemTransition: .immediate, stationaryItems: transition.stationaryItems, updateFirstIndexInSectionOffset: transition.topOffsetWithinMonth), completion: completion)
            }
        }
    }
    
    public func updateLayout(transition: ContainedViewLayoutTransition, updateSizeAndInsets: ListViewUpdateSizeAndInsets) {
        self.transaction(GridNodeTransaction(deleteItems: [], insertItems: [], updateItems: [], scrollToItem: nil, updateLayout: GridNodeUpdateLayout(layout: GridNodeLayout(size: updateSizeAndInsets.size, insets: updateSizeAndInsets.insets, preloadSize: 400.0, type: .fixed(itemSize: itemSizeForContainerLayout(size: updateSizeAndInsets.size), lineSpacing: 0.0)), transition: .immediate), itemTransition: .immediate, stationaryItems: .none,updateFirstIndexInSectionOffset: nil), completion: { _ in })
        
        if !self.dequeuedInitialTransitionOnLayout {
            self.dequeuedInitialTransitionOnLayout = true
            self.dequeueHistoryViewTransition()
        }
    }
    
    public func disconnect() {
        self.historyDisposable.set(nil)
    }
}
