import Foundation
import AsyncDisplayKit
import Display
import SwiftSignalKit
import Postbox
import TelegramCore

private enum ContactListSearchGroup {
    case contacts
    case global
    case deviceContacts
}

private struct ContactListSearchEntry: Identifiable, Comparable {
    let index: Int
    let peer: ContactListPeer
    let group: ContactListSearchGroup
    let enabled: Bool
    
    var stableId: ContactListPeerId {
        return self.peer.id
    }
    
    static func ==(lhs: ContactListSearchEntry, rhs: ContactListSearchEntry) -> Bool {
        if lhs.index != rhs.index {
            return false
        }
        if lhs.peer != rhs.peer {
            return false
        }
        if lhs.group != rhs.group {
            return false
        }
        if lhs.enabled != rhs.enabled {
            return false
        }
        return true
    }
    
    static func <(lhs: ContactListSearchEntry, rhs: ContactListSearchEntry) -> Bool {
        return lhs.index < rhs.index
    }
    
    func item(account: Account, theme: PresentationTheme, strings: PresentationStrings, openPeer: @escaping (ContactListPeer) -> Void) -> ListViewItem {
        let header: ListViewItemHeader
        switch self.group {
            case .contacts:
                header = ChatListSearchItemHeader(type: .contacts, theme: theme, strings: strings, actionTitle: nil, action: nil)
            case .global:
                header = ChatListSearchItemHeader(type: .globalPeers, theme: theme, strings: strings, actionTitle: nil, action: nil)
            case .deviceContacts:
                header = ChatListSearchItemHeader(type: .deviceContacts, theme: theme, strings: strings, actionTitle: nil, action: nil)
        }
        let peer = self.peer
        let peerItem: ContactsPeerItemPeer
        switch peer {
            case let .peer(peer, _):
                peerItem = .peer(peer: peer, chatPeer: peer)
            case let .deviceContact(stableId, contact):
                peerItem = .deviceContact(stableId: stableId, contact: contact)
        }
        return ContactsPeerItem(theme: theme, strings: strings, account: account, peerMode: .peer, peer: peerItem, status: .none, enabled: self.enabled, selection: .none, editing: ContactsPeerItemEditing(editable: false, editing: false, revealed: false), index: nil, header: header, action: { _ in
            openPeer(peer)
        })
    }
}

struct ContactListSearchContainerTransition {
    let deletions: [ListViewDeleteItem]
    let insertions: [ListViewInsertItem]
    let updates: [ListViewUpdateItem]
    let isSearching: Bool
}

private func contactListSearchContainerPreparedRecentTransition(from fromEntries: [ContactListSearchEntry], to toEntries: [ContactListSearchEntry], isSearching: Bool, account: Account, theme: PresentationTheme, strings: PresentationStrings, openPeer: @escaping (ContactListPeer) -> Void) -> ContactListSearchContainerTransition {
    let (deleteIndices, indicesAndItems, updateIndices) = mergeListsStableWithUpdates(leftList: fromEntries, rightList: toEntries)
    
    let deletions = deleteIndices.map { ListViewDeleteItem(index: $0, directionHint: nil) }
    let insertions = indicesAndItems.map { ListViewInsertItem(index: $0.0, previousIndex: $0.2, item: $0.1.item(account: account, theme: theme, strings: strings, openPeer: openPeer), directionHint: nil) }
    let updates = updateIndices.map { ListViewUpdateItem(index: $0.0, previousIndex: $0.2, item: $0.1.item(account: account, theme: theme, strings: strings, openPeer: openPeer), directionHint: nil) }
    
    return ContactListSearchContainerTransition(deletions: deletions, insertions: insertions, updates: updates, isSearching: isSearching)
}

struct ContactsSearchCategories: OptionSet {
    var rawValue: Int32
    
    init(rawValue: Int32) {
        self.rawValue = rawValue
    }
    
    static let cloudContacts = ContactsSearchCategories(rawValue: 1 << 0)
    static let global = ContactsSearchCategories(rawValue: 1 << 1)
    static let deviceContacts = ContactsSearchCategories(rawValue: 1 << 2)
}

final class ContactsSearchContainerNode: SearchDisplayControllerContentNode {
    private let account: Account
    private let openPeer: (ContactListPeer) -> Void
    
    private let dimNode: ASDisplayNode
    private let listNode: ListView
    
    private let searchQuery = Promise<String?>()
    private let searchDisposable = MetaDisposable()
    
    private var presentationData: PresentationData
    private let themeAndStringsPromise: Promise<(PresentationTheme, PresentationStrings)>
    
    private var containerViewLayout: (ContainerViewLayout, CGFloat)?
    private var enqueuedTransitions: [ContactListSearchContainerTransition] = []
    
    init(account: Account, onlyWriteable: Bool, categories: ContactsSearchCategories, filter: ContactListFilter = [.excludeSelf], openPeer: @escaping (ContactListPeer) -> Void) {
        self.account = account
        self.openPeer = openPeer
        
        self.presentationData = account.telegramApplicationContext.currentPresentationData.with { $0 }
        
        self.themeAndStringsPromise = Promise((self.presentationData.theme, self.presentationData.strings))
        
        self.dimNode = ASDisplayNode()
        self.dimNode.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        self.listNode = ListView()
        self.listNode.backgroundColor = self.presentationData.theme.list.plainBackgroundColor
        self.listNode.isHidden = true
        
        super.init()
        
        self.backgroundColor = nil
        self.isOpaque = false
        
        self.addSubnode(self.dimNode)
        self.addSubnode(self.listNode)
        
        self.listNode.isHidden = true
        
        let themeAndStringsPromise = self.themeAndStringsPromise
        
        let searchItems = searchQuery.get()
        |> mapToSignal { query -> Signal<[ContactListSearchEntry]?, NoError> in
            if let query = query, !query.isEmpty {
                let foundLocalContacts = account.postbox.searchContacts(query: query.lowercased())
                let foundRemoteContacts: Signal<([FoundPeer], [FoundPeer])?, NoError>
                if categories.contains(.global) {
                    foundRemoteContacts = .single(nil)
                    |> then(
                        searchPeers(account: account, query: query)
                        |> map { ($0.0, $0.1) }
                        |> delay(0.2, queue: Queue.concurrentDefaultQueue())
                    )
                } else {
                    foundRemoteContacts = .single(([], []))
                }
                let searchDeviceContacts = categories.contains(.deviceContacts)
                let foundDeviceContacts: Signal<[DeviceContactStableId: DeviceContactBasicData]?, NoError>
                if searchDeviceContacts {
                    foundDeviceContacts = account.telegramApplicationContext.contactDataManager.search(query: query)
                    |> map(Optional.init)
                } else {
                    foundDeviceContacts = .single([:])
                }
                
                return combineLatest(foundLocalContacts, foundRemoteContacts, foundDeviceContacts, themeAndStringsPromise.get())
                    |> delay(0.1, queue: Queue.concurrentDefaultQueue())
                    |> map { localPeers, remotePeers, deviceContacts, themeAndStrings -> [ContactListSearchEntry] in
                        var entries: [ContactListSearchEntry] = []
                        var existingPeerIds = Set<PeerId>()
                        if filter.contains(.excludeSelf) {
                            existingPeerIds.insert(account.peerId)
                        }
                        var existingNormalizedPhoneNumbers = Set<DeviceContactNormalizedPhoneNumber>()
                        var index = 0
                        for peer in localPeers {
                            if existingPeerIds.contains(peer.id) {
                                continue
                            }
                            existingPeerIds.insert(peer.id)
                            var enabled = true
                            if onlyWriteable {
                                enabled = canSendMessagesToPeer(peer)
                            }
                            entries.append(ContactListSearchEntry(index: index, peer: .peer(peer: peer, isGlobal: false), group: .contacts, enabled: enabled))
                            if searchDeviceContacts, let user = peer as? TelegramUser, let phone = user.phone {
                                existingNormalizedPhoneNumbers.insert(DeviceContactNormalizedPhoneNumber(rawValue: formatPhoneNumber(phone)))
                            }
                            index += 1
                        }
                        /*for peer in remotePeers.1 {
                            if !existingPeerIds.contains(peer.peer.id) {
                                existingPeerIds.insert(peer.peer.id)
                                var enabled = true
                                if onlyWriteable {
                                    enabled = canSendMessagesToPeer(peer.peer)
                                }
                         
                                entries.append(ContactListSearchEntry(index: index, peer: peer.peer, enabled: enabled))
                                index += 1
                            }
                        }*/
                        if let remotePeers = remotePeers {
                            for peer in remotePeers.1 {
                                if !existingPeerIds.contains(peer.peer.id) {
                                    existingPeerIds.insert(peer.peer.id)
                                    
                                    var enabled = true
                                    if onlyWriteable {
                                        enabled = canSendMessagesToPeer(peer.peer)
                                    }
                                    
                                    entries.append(ContactListSearchEntry(index: index, peer: .peer(peer: peer.peer, isGlobal: true), group: .global, enabled: enabled))
                                    if searchDeviceContacts, let user = peer.peer as? TelegramUser, let phone = user.phone {
                                        existingNormalizedPhoneNumbers.insert(DeviceContactNormalizedPhoneNumber(rawValue: formatPhoneNumber(phone)))
                                    }
                                    index += 1
                                }
                            }
                        }
                        if let _ = remotePeers, let deviceContacts = deviceContacts {
                            outer: for (stableId, contact) in deviceContacts {
                                inner: for phoneNumber in contact.phoneNumbers {
                                    let normalizedNumber = DeviceContactNormalizedPhoneNumber(rawValue: formatPhoneNumber(phoneNumber.value))
                                    if existingNormalizedPhoneNumbers.contains(normalizedNumber) {
                                        continue outer
                                    }
                                }
                                entries.append(ContactListSearchEntry(index: index, peer: .deviceContact(stableId, contact), group: .deviceContacts, enabled: true))
                                index += 1
                            }
                        }
                        return entries
                    }
            } else {
                return .single(nil)
            }
        }
        
        let previousSearchItems = Atomic<[ContactListSearchEntry]>(value: [])
        
        self.searchDisposable.set((searchItems
            |> deliverOnMainQueue).start(next: { [weak self] items in
                if let strongSelf = self {
                    let previousItems = previousSearchItems.swap(items ?? [])
                    
                    let transition = contactListSearchContainerPreparedRecentTransition(from: previousItems, to: items ?? [], isSearching: items != nil, account: account, theme: strongSelf.presentationData.theme, strings: strongSelf.presentationData.strings, openPeer: { peer in self?.listNode.clearHighlightAnimated(true)
                        self?.openPeer(peer)
                    })
                    
                    /*var listItems: [ListViewItem] = []
                    for item in items {
                        switch item {
                            case let .peer(peer, theme, strings):

                                
                                listItems.append(ContactsPeerItem(theme: theme, strings: strings, account: account, peerMode: .peer, peer: peer, chatPeer: peer, status: .none, enabled: enabled, selection: .none, editing: ContactsPeerItemEditing(editable: false, editing: false, revealed: false), index: nil, header: nil, action: { [weak self] _ in
                                    if let openPeer = self?.openPeer {
                                        self?.listNode.clearHighlightAnimated(true)
                                        openPeer(peer.id)
                                    }
                                }))
                        }
                    }*/
                    
                    strongSelf.enqueueTransition(transition)
                }
            }))
        
        self.listNode.beganInteractiveDragging = { [weak self] in
            self?.dismissInput?()
        }
    }
    
    deinit {
        self.searchDisposable.dispose()
    }
    
    override func didLoad() {
        super.didLoad()
        
        self.dimNode.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.dimTapGesture(_:))))
    }
    
    override func searchTextUpdated(text: String) {
        if text.isEmpty {
            self.searchQuery.set(.single(nil))
        } else {
            self.searchQuery.set(.single(text))
        }
    }
    
    override func containerLayoutUpdated(_ layout: ContainerViewLayout, navigationBarHeight: CGFloat, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, navigationBarHeight: navigationBarHeight, transition: transition)
        
        let hadValidLayout = self.containerViewLayout != nil
        self.containerViewLayout = (layout, navigationBarHeight)
        
        let topInset = navigationBarHeight
        transition.updateFrame(node: self.dimNode, frame: CGRect(origin: CGPoint(x: 0.0, y: topInset), size: CGSize(width: layout.size.width, height: layout.size.height - topInset)))
        
        self.listNode.frame = CGRect(origin: CGPoint(), size: layout.size)
        self.listNode.transaction(deleteIndices: [], insertIndicesAndItems: [], updateIndicesAndItems: [], options: [.Synchronous], scrollToItem: nil, updateSizeAndInsets: ListViewUpdateSizeAndInsets(size: layout.size, insets: UIEdgeInsets(top: topInset, left: 0.0, bottom: layout.intrinsicInsets.bottom, right: 0.0), duration: 0.0, curve: .Default), stationaryItemRange: nil, updateOpaqueState: nil, completion: { _ in })
        
        if !hadValidLayout {
            while !self.enqueuedTransitions.isEmpty {
                self.dequeueTransition()
            }
        }
    }
    
    private func enqueueTransition(_ transition: ContactListSearchContainerTransition) {
        self.enqueuedTransitions.append(transition)
        
        if self.containerViewLayout != nil {
            while !self.enqueuedTransitions.isEmpty {
                self.dequeueTransition()
            }
        }
    }
    
    private func dequeueTransition() {
        if let transition = self.enqueuedTransitions.first {
            self.enqueuedTransitions.remove(at: 0)
            
            var options = ListViewDeleteAndInsertOptions()
            options.insert(.PreferSynchronousDrawing)
            
            let isSearching = transition.isSearching
            self.listNode.transaction(deleteIndices: transition.deletions, insertIndicesAndItems: transition.insertions, updateIndicesAndItems: transition.updates, options: options, updateSizeAndInsets: nil, updateOpaqueState: nil, completion: { [weak self] _ in
                self?.listNode.isHidden = !isSearching
                self?.dimNode.isHidden = isSearching
            })
        }
    }
    
    @objc func dimTapGesture(_ recognizer: UITapGestureRecognizer) {
        if case .ended = recognizer.state {
            self.cancel?()
        }
    }
}
