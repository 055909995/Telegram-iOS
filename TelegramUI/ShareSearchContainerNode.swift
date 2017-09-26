import Foundation
import AsyncDisplayKit
import Postbox
import TelegramCore
import SwiftSignalKit
import Display

private let separatorColor: UIColor = UIColor(rgb: 0xbcbbc1)

private let cancelFont = Font.regular(17.0)
private let cancelColor = UIColor(rgb: 0x007ee5)
private let subtitleFont = Font.regular(12.0)
private let subtitleColor = UIColor(rgb: 0x7b7b81)

private enum ShareSearchRecentEntryStableId: Hashable {
    case topPeers
    case peerId(PeerId)
    
    static func ==(lhs: ShareSearchRecentEntryStableId, rhs: ShareSearchRecentEntryStableId) -> Bool {
        switch lhs {
            case .topPeers:
                if case .topPeers = rhs {
                    return true
                } else {
                    return false
                }
            case let .peerId(peerId):
                if case .peerId(peerId) = rhs {
                    return true
                } else {
                    return false
                }
        }
    }
    
    var hashValue: Int {
        switch self {
            case .topPeers:
                return 0
            case let .peerId(peerId):
                return peerId.hashValue
        }
    }
}

private enum ShareSearchRecentEntry: Comparable, Identifiable {
    case topPeers(PresentationTheme, PresentationStrings)
    case peer(index: Int, peer: Peer, associatedPeer: Peer?, PresentationStrings)
    
    var stableId: ShareSearchRecentEntryStableId {
        switch self {
            case .topPeers:
                return .topPeers
            case let .peer(_, peer, _, _):
                return .peerId(peer.id)
        }
    }
    
    static func ==(lhs: ShareSearchRecentEntry, rhs: ShareSearchRecentEntry) -> Bool {
        switch lhs {
            case let .topPeers(lhsTheme, lhsStrings):
                if case let .topPeers(rhsTheme, rhsStrings) = rhs {
                    if lhsTheme !== rhsTheme {
                        return false
                    }
                    if lhsStrings !== rhsStrings {
                        return false
                    }
                    return true
                } else {
                    return false
                }
            case let .peer(lhsIndex, lhsPeer, lhsAssociatedPeer, lhsStrings):
                if case let .peer(rhsIndex, rhsPeer, rhsAssociatedPeer, rhsStrings) = rhs, lhsPeer.isEqual(rhsPeer) && arePeersEqual(lhsAssociatedPeer, rhsAssociatedPeer) && lhsIndex == rhsIndex && lhsStrings === rhsStrings {
                    return true
                } else {
                    return false
                }
        }
    }
    
    static func <(lhs: ShareSearchRecentEntry, rhs: ShareSearchRecentEntry) -> Bool {
        switch lhs {
            case .topPeers:
                return true
            case let .peer(lhsIndex, _, _, _):
                switch rhs {
                    case .topPeers:
                        return false
                    case let .peer(rhsIndex, _, _, _):
                        return lhsIndex <= rhsIndex
                }
        }
    }
    
    func item(account: Account, interfaceInteraction: ShareControllerInteraction) -> GridItem {
        switch self {
            case let .topPeers(theme, strings):
                return ShareControllerRecentPeersGridItem(account: account, theme: theme, strings: strings, controllerInteraction: interfaceInteraction)
            case let .peer(_, peer, associatedPeer, strings):
                let primaryPeer: Peer
                var chatPeer: Peer?
                if let associatedPeer = associatedPeer {
                    primaryPeer = associatedPeer
                    chatPeer = peer
                } else {
                    primaryPeer = peer
                    chatPeer = associatedPeer
                }
                return ShareControllerPeerGridItem(account: account, peer: primaryPeer, chatPeer: chatPeer, controllerInteraction: interfaceInteraction, sectionTitle: strings.DialogList_SearchSectionRecent)
        }
    }
}

private struct ShareSearchPeerEntry: Comparable, Identifiable {
    let index: Int32
    let peer: Peer
    
    var stableId: Int64 {
        return self.peer.id.toInt64()
    }
    
    static func ==(lhs: ShareSearchPeerEntry, rhs: ShareSearchPeerEntry) -> Bool {
        if lhs.index != rhs.index {
            return false
        }
        if !arePeersEqual(lhs.peer, rhs.peer) {
            return false
        }
        return true
    }
    
    static func <(lhs: ShareSearchPeerEntry, rhs: ShareSearchPeerEntry) -> Bool {
        return lhs.index < rhs.index
    }
    
    func item(account: Account, interfaceInteraction: ShareControllerInteraction) -> GridItem {
        return ShareControllerPeerGridItem(account: account, peer: self.peer, chatPeer: nil, controllerInteraction: interfaceInteraction)
    }
}

private struct ShareSearchGridTransaction {
    let deletions: [Int]
    let insertions: [GridNodeInsertItem]
    let updates: [GridNodeUpdateItem]
    let animated: Bool
}

private func preparedGridEntryTransition(account: Account, from fromEntries: [ShareSearchPeerEntry], to toEntries: [ShareSearchPeerEntry], interfaceInteraction: ShareControllerInteraction) -> ShareSearchGridTransaction {
    let (deleteIndices, indicesAndItems, updateIndices) = mergeListsStableWithUpdates(leftList: fromEntries, rightList: toEntries)
    
    let deletions = deleteIndices
    let insertions = indicesAndItems.map { GridNodeInsertItem(index: $0.0, item: $0.1.item(account: account, interfaceInteraction: interfaceInteraction), previousIndex: $0.2) }
    let updates = updateIndices.map { GridNodeUpdateItem(index: $0.0, previousIndex: $0.2, item: $0.1.item(account: account, interfaceInteraction: interfaceInteraction)) }
    
    return ShareSearchGridTransaction(deletions: deletions, insertions: insertions, updates: updates, animated: false)
}

private func preparedRecentEntryTransition(account: Account, from fromEntries: [ShareSearchRecentEntry], to toEntries: [ShareSearchRecentEntry], interfaceInteraction: ShareControllerInteraction) -> ShareSearchGridTransaction {
    let (deleteIndices, indicesAndItems, updateIndices) = mergeListsStableWithUpdates(leftList: fromEntries, rightList: toEntries)
    
    let deletions = deleteIndices
    let insertions = indicesAndItems.map { GridNodeInsertItem(index: $0.0, item: $0.1.item(account: account, interfaceInteraction: interfaceInteraction), previousIndex: $0.2) }
    let updates = updateIndices.map { GridNodeUpdateItem(index: $0.0, previousIndex: $0.2, item: $0.1.item(account: account, interfaceInteraction: interfaceInteraction)) }
    
    return ShareSearchGridTransaction(deletions: deletions, insertions: insertions, updates: updates, animated: false)
}

final class ShareSearchContainerNode: ASDisplayNode, ShareContentContainerNode {
    private let account: Account
    private let strings: PresentationStrings
    private let controllerInteraction: ShareControllerInteraction
    
    private var entries: [ShareSearchPeerEntry] = []
    private var recentEntries: [ShareSearchRecentEntry] = []
    
    private var enqueuedTransitions: [(ShareSearchGridTransaction, Bool)] = []
    private var enqueuedRecentTransitions: [(ShareSearchGridTransaction, Bool)] = []
    
    private let contentGridNode: GridNode
    private let recentGridNode: GridNode
    
    private let contentSeparatorNode: ASDisplayNode
    private let searchNode: ShareSearchBarNode
    private let cancelButtonNode: HighlightableButtonNode
    
    private var contentOffsetUpdated: ((CGFloat, ContainedViewLayoutTransition) -> Void)?
    
    var cancel: (() -> Void)?
    
    private var ensurePeerVisibleOnLayout: PeerId?
    private var validLayout: (CGSize, CGFloat)?
    private var overrideGridOffsetTransition: ContainedViewLayoutTransition?
    
    private let recentDisposable = MetaDisposable()
    
    private let searchQuery = ValuePromise<String>("", ignoreRepeated: true)
    private let searchDisposable = MetaDisposable()
    
    init(account: Account, theme: PresentationTheme, strings: PresentationStrings, controllerInteraction: ShareControllerInteraction, recentPeers: [RenderedPeer]) {
        self.account = account
        self.strings = strings
        self.controllerInteraction = controllerInteraction
        
        self.recentGridNode = GridNode()
        self.contentGridNode = GridNode()
        self.contentGridNode.isHidden = true
        
        self.searchNode = ShareSearchBarNode(placeholder: strings.Common_Search)
        
        self.cancelButtonNode = HighlightableButtonNode()
        self.cancelButtonNode.setTitle(strings.Common_Cancel, with: cancelFont, with: cancelColor, for: [])
        self.cancelButtonNode.hitTestSlop = UIEdgeInsets(top: -8.0, left: -8.0, bottom: -8.0, right: -8.0)
        
        self.contentSeparatorNode = ASDisplayNode()
        self.contentSeparatorNode.isLayerBacked = true
        self.contentSeparatorNode.displaysAsynchronously = false
        self.contentSeparatorNode.backgroundColor = separatorColor
        
        super.init()
        
        self.addSubnode(self.recentGridNode)
        self.addSubnode(self.contentGridNode)
        
        self.addSubnode(self.searchNode)
        self.addSubnode(self.cancelButtonNode)
        self.addSubnode(self.contentSeparatorNode)
        
        self.recentGridNode.presentationLayoutUpdated = { [weak self] presentationLayout, transition in
            if let strongSelf = self, !strongSelf.recentGridNode.isHidden {
                strongSelf.gridPresentationLayoutUpdated(presentationLayout, transition: transition)
            }
        }
        
        self.contentGridNode.presentationLayoutUpdated = { [weak self] presentationLayout, transition in
            if let strongSelf = self, !strongSelf.contentGridNode.isHidden {
                strongSelf.gridPresentationLayoutUpdated(presentationLayout, transition: transition)
            }
        }
        
        self.cancelButtonNode.addTarget(self, action: #selector(self.cancelPressed), forControlEvents: .touchUpInside)
        
        let foundItems = searchQuery.get()
            |> mapToSignal { query -> Signal<[ShareSearchPeerEntry]?, NoError> in
                if !query.isEmpty {
                    let foundLocalPeers = account.postbox.searchPeers(query: query.lowercased())
                    let foundRemotePeers: Signal<[Peer], NoError> = .single([]) |> then(searchPeers(account: account, query: query)
                        |> delay(0.2, queue: Queue.concurrentDefaultQueue()))
                    
                    return combineLatest(foundLocalPeers, foundRemotePeers)
                        |> map { foundLocalPeers, foundRemotePeers -> [ShareSearchPeerEntry]? in
                            var entries: [ShareSearchPeerEntry] = []
                            var index: Int32 = 0
                            for renderedPeer in foundLocalPeers {
                                if let peer = renderedPeer.peers[renderedPeer.peerId] {
                                    var associatedPeer: Peer?
                                    if let associatedPeerId = peer.associatedPeerId {
                                        associatedPeer = renderedPeer.peers[associatedPeerId]
                                    }
                                    //entries.append(.localPeer(peer, associatedPeer, index, themeAndStrings.0, themeAndStrings.1))
                                    entries.append(ShareSearchPeerEntry(index: index, peer: peer))
                                    index += 1
                                }
                            }
                            
                            for peer in foundRemotePeers {
                                entries.append(ShareSearchPeerEntry(index: index, peer: peer))
                                //entries.append(.globalPeer(peer, index, themeAndStrings.0, themeAndStrings.1))
                                index += 1
                            }
                            
                            return entries
                    }
                } else {
                    return .single(nil)
                }
        }
        
        let previousSearchItems = Atomic<[ShareSearchPeerEntry]?>(value: nil)
        self.searchDisposable.set((foundItems
            |> deliverOnMainQueue).start(next: { [weak self] entries in
                if let strongSelf = self {
                    let previousEntries = previousSearchItems.swap(entries)
                    strongSelf.entries = entries ?? []
                    
                    let firstTime = previousEntries == nil
                    let transition = preparedGridEntryTransition(account: account, from: previousEntries ?? [], to: entries ?? [], interfaceInteraction: controllerInteraction)
                    strongSelf.enqueueTransition(transition, firstTime: firstTime)
                    
                    if (previousEntries == nil) != (entries == nil) {
                        if previousEntries == nil {
                            strongSelf.recentGridNode.isHidden = true
                            strongSelf.contentGridNode.isHidden = false
                            strongSelf.transitionToContentGridLayout()
                        } else {
                            strongSelf.recentGridNode.isHidden = false
                            strongSelf.contentGridNode.isHidden = true
                            strongSelf.transitionToRecentGridLayout()
                        }
                    }
                }
            }))
        
        self.searchNode.textUpdated = { [weak self] text in
            self?.searchQuery.set(text)
        }
        
        var recentItemList: [ShareSearchRecentEntry] = []
        recentItemList.append(.topPeers(theme, strings))
        var index = 0
        for peer in recentPeers {
            if let mainPeer = peer.peers[peer.peerId] {
                recentItemList.append(.peer(index: index, peer: mainPeer, associatedPeer: mainPeer.associatedPeerId.flatMap { peer.peers[$0] }, strings))
                index += 1
            }
        }
        
        let recentItems: Signal<[ShareSearchRecentEntry], NoError> = .single(recentItemList)
        let previousRecentItems = Atomic<[ShareSearchRecentEntry]?>(value: nil)
        self.recentDisposable.set((recentItems
            |> deliverOnMainQueue).start(next: { [weak self] entries in
                if let strongSelf = self {
                    let previousEntries = previousRecentItems.swap(entries)
                    strongSelf.recentEntries = entries
                    
                    let firstTime = previousEntries == nil
                    let transition = preparedRecentEntryTransition(account: account, from: previousEntries ?? [], to: entries, interfaceInteraction: controllerInteraction)
                    strongSelf.enqueueRecentTransition(transition, firstTime: firstTime)
                }
            }))
    }
    
    deinit {
        self.searchDisposable.dispose()
        self.recentDisposable.dispose()
    }
    
    func setEnsurePeerVisibleOnLayout(_ peerId: PeerId?) {
        self.ensurePeerVisibleOnLayout = peerId
    }
    
    func setContentOffsetUpdated(_ f: ((CGFloat, ContainedViewLayoutTransition) -> Void)?) {
        self.contentOffsetUpdated = f
    }
    
    func activate() {
        self.searchNode.activateInput()
    }
    
    func deactivate() {
        self.searchNode.deactivateInput()
    }
    
    private func calculateMetrics(size: CGSize) -> (topInset: CGFloat, itemWidth: CGFloat) {
        let itemCount: Int
        if self.contentGridNode.isHidden {
            itemCount = self.recentEntries.count
        } else {
            itemCount = self.entries.count
        }
        
        let itemInsets = UIEdgeInsets(top: 0.0, left: 12.0, bottom: 0.0, right: 12.0)
        let minimalItemWidth: CGFloat = 70.0
        let effectiveWidth = size.width - itemInsets.left - itemInsets.right
        
        let itemsPerRow = Int(effectiveWidth / minimalItemWidth)
        
        let itemWidth = floor(effectiveWidth / CGFloat(itemsPerRow))
        var rowCount = itemCount / itemsPerRow + (itemCount % itemsPerRow != 0 ? 1 : 0)
        rowCount = max(rowCount, 4)
        
        let minimallyRevealedRowCount: CGFloat = 3.7
        let initiallyRevealedRowCount = min(minimallyRevealedRowCount, CGFloat(rowCount))
        
        let gridTopInset = max(0.0, size.height - floor(initiallyRevealedRowCount * itemWidth) - 14.0)
        return (gridTopInset, itemWidth)
    }
    
    func updateLayout(size: CGSize, bottomInset: CGFloat, transition: ContainedViewLayoutTransition) {
        let firstLayout = self.validLayout == nil
        self.validLayout = (size, bottomInset)
        
        let gridLayoutTransition: ContainedViewLayoutTransition
        if firstLayout {
            gridLayoutTransition = .immediate
            self.overrideGridOffsetTransition = transition
        } else {
            gridLayoutTransition = transition
            self.overrideGridOffsetTransition = nil
        }
        
        let (gridTopInset, itemWidth) = self.calculateMetrics(size: size)
        
        var scrollToItem: GridNodeScrollToItem?
        if !self.contentGridNode.isHidden, let ensurePeerVisibleOnLayout = self.ensurePeerVisibleOnLayout {
            self.ensurePeerVisibleOnLayout = nil
            if let index = self.entries.index(where: { $0.peer.id == ensurePeerVisibleOnLayout }) {
                scrollToItem = GridNodeScrollToItem(index: index, position: .visible, transition: transition, directionHint: .up, adjustForSection: false)
            }
        }
        
        var scrollToRecentItem: GridNodeScrollToItem?
        if !self.recentGridNode.isHidden, let ensurePeerVisibleOnLayout = self.ensurePeerVisibleOnLayout {
            self.ensurePeerVisibleOnLayout = nil
            if let index = self.recentEntries.index(where: {
                switch $0 {
                    case .topPeers:
                        return false
                    case let .peer(_, peer, _, _):
                        return peer.id == ensurePeerVisibleOnLayout
                }
            }) {
                scrollToRecentItem = GridNodeScrollToItem(index: index, position: .visible, transition: transition, directionHint: .up, adjustForSection: false)
            }
        }
        
        let gridSize = CGSize(width: size.width, height: size.height - 5.0)
        
        self.recentGridNode.transaction(GridNodeTransaction(deleteItems: [], insertItems: [], updateItems: [], scrollToItem: scrollToRecentItem, updateLayout: GridNodeUpdateLayout(layout: GridNodeLayout(size: gridSize, insets: UIEdgeInsets(top: gridTopInset, left: 6.0, bottom: bottomInset, right: 6.0), preloadSize: 80.0, type: .fixed(itemSize: CGSize(width: itemWidth, height: itemWidth + 25.0), lineSpacing: 0.0)), transition: gridLayoutTransition), itemTransition: .immediate, stationaryItems: .none, updateFirstIndexInSectionOffset: nil), completion: { _ in })
        gridLayoutTransition.updateFrame(node: self.recentGridNode, frame: CGRect(origin: CGPoint(x: floor((size.width - gridSize.width) / 2.0), y: 5.0), size: gridSize))
        
        self.contentGridNode.transaction(GridNodeTransaction(deleteItems: [], insertItems: [], updateItems: [], scrollToItem: scrollToItem, updateLayout: GridNodeUpdateLayout(layout: GridNodeLayout(size: gridSize, insets: UIEdgeInsets(top: gridTopInset, left: 6.0, bottom: bottomInset, right: 6.0), preloadSize: 80.0, type: .fixed(itemSize: CGSize(width: itemWidth, height: itemWidth + 25.0), lineSpacing: 0.0)), transition: gridLayoutTransition), itemTransition: .immediate, stationaryItems: .none, updateFirstIndexInSectionOffset: nil), completion: { _ in })
        gridLayoutTransition.updateFrame(node: self.contentGridNode, frame: CGRect(origin: CGPoint(x: floor((size.width - gridSize.width) / 2.0), y: 5.0), size: gridSize))
        
        if firstLayout {
            self.animateIn()
            
            while !self.enqueuedTransitions.isEmpty {
                self.dequeueTransition()
            }
            
            while !self.enqueuedRecentTransitions.isEmpty {
                self.dequeueRecentTransition()
            }
        }
    }
    
    private func transitionToRecentGridLayout(_ transition: ContainedViewLayoutTransition = .animated(duration: 0.3, curve: .spring)) {
        if let (size, bottomInset) = self.validLayout {
            let (gridTopInset, itemWidth) = self.calculateMetrics(size: size)
            
            let offset = self.recentGridNode.scrollView.contentOffset.y - self.contentGridNode.scrollView.contentOffset.y
            
            let gridSize = CGSize(width: size.width, height: size.height - 5.0)
            self.recentGridNode.transaction(GridNodeTransaction(deleteItems: [], insertItems: [], updateItems: [], scrollToItem: nil, updateLayout: GridNodeUpdateLayout(layout: GridNodeLayout(size: gridSize, insets: UIEdgeInsets(top: gridTopInset, left: 6.0, bottom: bottomInset, right: 6.0), preloadSize: 80.0, type: .fixed(itemSize: CGSize(width: itemWidth, height: itemWidth + 25.0), lineSpacing: 0.0)), transition: transition), itemTransition: .immediate, stationaryItems: .none, updateFirstIndexInSectionOffset: nil), completion: { _ in })
            
            transition.animatePositionAdditive(node: self.recentGridNode, offset: offset)
        }
    }
    
    private func transitionToContentGridLayout(_ transition: ContainedViewLayoutTransition = .animated(duration: 0.3, curve: .spring)) {
        if let (size, bottomInset) = self.validLayout {
            let (gridTopInset, itemWidth) = self.calculateMetrics(size: size)
            
            let offset = self.recentGridNode.scrollView.contentOffset.y - self.contentGridNode.scrollView.contentOffset.y
            
            let gridSize = CGSize(width: size.width, height: size.height - 5.0)
            self.contentGridNode.transaction(GridNodeTransaction(deleteItems: [], insertItems: [], updateItems: [], scrollToItem: nil, updateLayout: GridNodeUpdateLayout(layout: GridNodeLayout(size: gridSize, insets: UIEdgeInsets(top: gridTopInset, left: 6.0, bottom: bottomInset, right: 6.0), preloadSize: 80.0, type: .fixed(itemSize: CGSize(width: itemWidth, height: itemWidth + 25.0), lineSpacing: 0.0)), transition: transition), itemTransition: .immediate, stationaryItems: .none, updateFirstIndexInSectionOffset: nil), completion: { _ in })
            
            transition.animatePositionAdditive(node: self.contentGridNode, offset: -offset)
        }
    }
    
    private func gridPresentationLayoutUpdated(_ presentationLayout: GridNodeCurrentPresentationLayout, transition: ContainedViewLayoutTransition) {
        let actualTransition = self.overrideGridOffsetTransition ?? transition
        self.overrideGridOffsetTransition = nil
        
        let titleAreaHeight: CGFloat = 64.0
        
        let size = self.bounds.size
        let rawTitleOffset = -titleAreaHeight - presentationLayout.contentOffset.y
        let titleOffset = max(-titleAreaHeight, rawTitleOffset)
        
        let cancelButtonSize = self.cancelButtonNode.measure(CGSize(width: 320.0, height: 100.0))
        let cancelButtonFrame = CGRect(origin: CGPoint(x: bounds.size.width - cancelButtonSize.width - 12.0, y: titleOffset + 25.0), size: cancelButtonSize)
        transition.updateFrame(node: self.cancelButtonNode, frame: cancelButtonFrame)
        
        let searchNodeFrame = CGRect(origin: CGPoint(x: 16.0, y: titleOffset + 16.0), size: CGSize(width: cancelButtonFrame.minX - 16.0 - 10.0, height: 40.0))
        transition.updateFrame(node: self.searchNode, frame: searchNodeFrame)
        self.searchNode.updateLayout(width: searchNodeFrame.size.width, transition: transition)
        
        transition.updateFrame(node: self.contentSeparatorNode, frame: CGRect(origin: CGPoint(x: 0.0, y: titleOffset + titleAreaHeight + 5.0), size: CGSize(width: size.width, height: UIScreenPixel)))
        
        if rawTitleOffset.isLess(than: -titleAreaHeight) {
            self.contentSeparatorNode.alpha = 1.0
        } else {
            self.contentSeparatorNode.alpha = 0.0
        }
        
        self.contentOffsetUpdated?(presentationLayout.contentOffset.y, actualTransition)
    }
    
    func animateIn() {
    }
    
    func updateSelectedPeers() {
        self.contentGridNode.forEachItemNode { itemNode in
            if let itemNode = itemNode as? ShareControllerPeerGridItemNode {
                itemNode.updateSelection(animated: true)
            }
        }
        self.recentGridNode.forEachItemNode { itemNode in
            if let itemNode = itemNode as? ShareControllerPeerGridItemNode {
                itemNode.updateSelection(animated: true)
            } else if let itemNode = itemNode as? ShareControllerRecentPeersGridItemNode {
                itemNode.updateSelection(animated: true)
            }
        }
    }
    
    @objc func cancelPressed() {
        self.cancel?()
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let nodes: [ASDisplayNode] = [self.searchNode, self.cancelButtonNode]
        for node in nodes {
            let nodeFrame = node.frame
            if let result = node.hitTest(point.offsetBy(dx: -nodeFrame.minX, dy: -nodeFrame.minY), with: event) {
                return result
            }
        }
        
        return super.hitTest(point, with: event)
    }
    
    private func enqueueTransition(_ transition: ShareSearchGridTransaction, firstTime: Bool) {
        self.enqueuedTransitions.append((transition, firstTime))
        
        if self.validLayout != nil {
            while !self.enqueuedTransitions.isEmpty {
                self.dequeueTransition()
            }
        }
    }
    
    private func dequeueTransition() {
        if let (transition, firstTime) = self.enqueuedTransitions.first {
            self.enqueuedTransitions.remove(at: 0)
            
            var itemTransition: ContainedViewLayoutTransition = .immediate
            if transition.animated {
                itemTransition = .animated(duration: 0.3, curve: .spring)
            }
            self.contentGridNode.transaction(GridNodeTransaction(deleteItems: transition.deletions, insertItems: transition.insertions, updateItems: transition.updates, scrollToItem: nil, updateLayout: nil, itemTransition: itemTransition, stationaryItems: .none, updateFirstIndexInSectionOffset: nil), completion: { _ in })
        }
    }
    
    private func enqueueRecentTransition(_ transition: ShareSearchGridTransaction, firstTime: Bool) {
        self.enqueuedRecentTransitions.append((transition, firstTime))
        
        if self.validLayout != nil {
            while !self.enqueuedRecentTransitions.isEmpty {
                self.dequeueRecentTransition()
            }
        }
    }
    
    private func dequeueRecentTransition() {
        if let (transition, firstTime) = self.enqueuedRecentTransitions.first {
            self.enqueuedRecentTransitions.remove(at: 0)
            
            var itemTransition: ContainedViewLayoutTransition = .immediate
            if transition.animated {
                itemTransition = .animated(duration: 0.3, curve: .spring)
            }
            self.recentGridNode.transaction(GridNodeTransaction(deleteItems: transition.deletions, insertItems: transition.insertions, updateItems: transition.updates, scrollToItem: nil, updateLayout: nil, itemTransition: itemTransition, stationaryItems: .none, updateFirstIndexInSectionOffset: nil), completion: { _ in })
        }
    }
}
