import Foundation
import AsyncDisplayKit
import Postbox
import SwiftSignalKit
import Display
import TelegramCore

struct PeerMediaCollectionMessageForGallery {
    let message: Message
    let fromSearchResults: Bool
}

private func historyNodeImplForMode(_ mode: PeerMediaCollectionMode, account: Account, peerId: PeerId, messageId: MessageId?, controllerInteraction: ChatControllerInteraction, selectedMessages: Signal<Set<MessageId>?, NoError>) -> ChatHistoryNode & ASDisplayNode {
    switch mode {
        case .photoOrVideo:
            return ChatHistoryGridNode(account: account, peerId: peerId, messageId: messageId, tagMask: .photoOrVideo, controllerInteraction: controllerInteraction)
        case .file:
            let node = ChatHistoryListNode(account: account, chatLocation: .peer(peerId), tagMask: .file, messageId: messageId, controllerInteraction: controllerInteraction, selectedMessages: selectedMessages, mode: .list(search: true, reversed: false))
            node.preloadPages = true
            return node
        case .music:
            let node = ChatHistoryListNode(account: account, chatLocation: .peer(peerId), tagMask: .music, messageId: messageId, controllerInteraction: controllerInteraction, selectedMessages: selectedMessages, mode: .list(search: true, reversed: false))
            node.preloadPages = true
            return node
        case .webpage:
            let node = ChatHistoryListNode(account: account, chatLocation: .peer(peerId), tagMask: .webPage, messageId: messageId, controllerInteraction: controllerInteraction, selectedMessages: selectedMessages, mode: .list(search: true, reversed: false))
            node.preloadPages = true
            return node
    }
}

private func updateLoadNodeState(_ node: PeerMediaCollectionEmptyNode, _ loadState: ChatHistoryNodeLoadState?) {
    if let loadState = loadState {
        switch loadState {
            case .messages:
                node.isHidden = true
                node.isLoading = false
            case .empty:
                node.isHidden = false
                node.isLoading = false
            case .loading:
                node.isHidden = false
                node.isLoading = true
        }
    } else {
        node.isHidden = false
        node.isLoading = true
    }
}

private func tagMaskForMode(_ mode: PeerMediaCollectionMode) -> MessageTags {
    switch mode {
        case .photoOrVideo:
            return .photoOrVideo
        case .file:
            return .file
        case .music:
            return .music
        case .webpage:
            return .webPage
    }
}

class PeerMediaCollectionControllerNode: ASDisplayNode {
    private let account: Account
    private let peerId: PeerId
    private let controllerInteraction: ChatControllerInteraction
    private let interfaceInteraction: ChatPanelInterfaceInteraction
    private let navigationBar: NavigationBar?
    
    private let sectionsNode: PeerMediaCollectionSectionsNode
    
    private(set) var historyNode: ChatHistoryNode & ASDisplayNode
    private var historyEmptyNode: PeerMediaCollectionEmptyNode
    
    private var searchDisplayController: SearchDisplayController?
    
    private let candidateHistoryNodeReadyDisposable = MetaDisposable()
    private var candidateHistoryNode: (ASDisplayNode, PeerMediaCollectionMode)?
    
    private var containerLayout: (ContainerViewLayout, CGFloat)?
    
    var requestLayout: (ContainedViewLayoutTransition) -> Void = { _ in }
    var requestUpdateMediaCollectionInterfaceState: (Bool, (PeerMediaCollectionInterfaceState) -> PeerMediaCollectionInterfaceState) -> Void = { _, _ in }
    let requestDeactivateSearch: () -> Void
    
    private var mediaCollectionInterfaceState: PeerMediaCollectionInterfaceState
    
    private let selectedMessagesPromise = Promise<Set<MessageId>?>(nil)
    var selectedMessages: Set<MessageId>? {
        didSet {
            if self.selectedMessages != oldValue {
                self.selectedMessagesPromise.set(.single(self.selectedMessages))
            }
        }
    }
    private var selectionPanel: ChatMessageSelectionInputPanelNode?
    private var selectionPanelSeparatorNode: ASDisplayNode?
    private var selectionPanelBackgroundNode: ASDisplayNode?
    
    private var chatPresentationInterfaceState: ChatPresentationInterfaceState
    
    private var presentationData: PresentationData
    
    init(account: Account, peerId: PeerId, messageId: MessageId?, controllerInteraction: ChatControllerInteraction, interfaceInteraction: ChatPanelInterfaceInteraction, navigationBar: NavigationBar?, requestDeactivateSearch: @escaping () -> Void) {
        self.account = account
        self.peerId = peerId
        self.controllerInteraction = controllerInteraction
        self.interfaceInteraction = interfaceInteraction
        self.navigationBar = navigationBar
        
        self.requestDeactivateSearch = requestDeactivateSearch
        
        self.presentationData = (account.applicationContext as! TelegramApplicationContext).currentPresentationData.with { $0 }
        self.mediaCollectionInterfaceState = PeerMediaCollectionInterfaceState(theme: self.presentationData.theme, strings: self.presentationData.strings)
        
        self.sectionsNode = PeerMediaCollectionSectionsNode(theme: self.presentationData.theme, strings: self.presentationData.strings)
        
        self.historyNode = historyNodeImplForMode(self.mediaCollectionInterfaceState.mode, account: account, peerId: peerId, messageId: messageId, controllerInteraction: controllerInteraction, selectedMessages: self.selectedMessagesPromise.get())
        self.historyEmptyNode = PeerMediaCollectionEmptyNode(mode: self.mediaCollectionInterfaceState.mode, theme: self.presentationData.theme, strings: self.presentationData.strings)
        self.historyEmptyNode.isHidden = true
        
        self.chatPresentationInterfaceState = ChatPresentationInterfaceState(chatWallpaper: self.presentationData.chatWallpaper, theme: self.presentationData.theme, strings: self.presentationData.strings, fontSize: self.presentationData.fontSize, accountPeerId: account.peerId, mode: .standard(previewing: false), chatLocation: .peer(self.peerId))
        
        super.init()
        
        self.setViewBlock({
            return UITracingLayerView()
        })
        
        self.historyNode.backgroundColor = self.presentationData.theme.list.plainBackgroundColor
        self.backgroundColor = self.presentationData.theme.list.plainBackgroundColor
        
        self.addSubnode(self.historyNode)
        self.addSubnode(self.historyEmptyNode)
        if let navigationBar = navigationBar {
            self.addSubnode(navigationBar)
        }
        if let navigationBar = self.navigationBar {
            self.insertSubnode(self.sectionsNode, aboveSubnode: navigationBar)
        } else {
            self.addSubnode(self.sectionsNode)
        }
        
        self.sectionsNode.indexUpdated = { [weak self] index in
            if let strongSelf = self {
                let mode: PeerMediaCollectionMode
                switch index {
                    case 0:
                        mode = .photoOrVideo
                    case 1:
                        mode = .file
                    case 2:
                        mode = .webpage
                    case 3:
                        mode = .music
                    default:
                        mode = .photoOrVideo
                }
                strongSelf.requestUpdateMediaCollectionInterfaceState(true, { $0.withMode(mode) })
            }
        }
        
        updateLoadNodeState(self.historyEmptyNode, self.historyNode.loadState)
        self.historyNode.setLoadStateUpdated { [weak self] loadState, _ in
            if let strongSelf = self {
                updateLoadNodeState(strongSelf.historyEmptyNode, loadState)
            }
        }
    }
    
    deinit {
        self.candidateHistoryNodeReadyDisposable.dispose()
    }
    
    func containerLayoutUpdated(_ layout: ContainerViewLayout, navigationBarHeight: CGFloat, transition: ContainedViewLayoutTransition, listViewTransaction: (ListViewUpdateSizeAndInsets) -> Void) {
        self.containerLayout = (layout, navigationBarHeight)
        
        var vanillaInsets = layout.insets(options: [])
        vanillaInsets.top += navigationBarHeight
        
        var additionalInset: CGFloat = 0.0
        
        if (navigationBarHeight - (layout.statusBarHeight ?? 0.0)).isLessThanOrEqualTo(44.0) {
        } else {
            additionalInset += 10.0
        }
        
        if let searchDisplayController = self.searchDisplayController {
            searchDisplayController.containerLayoutUpdated(layout, navigationBarHeight: navigationBarHeight, transition: transition)
            if !searchDisplayController.isDeactivating {
                vanillaInsets.top += 20.0
            }
        }
        
        let sectionsHeight = self.sectionsNode.updateLayout(width: layout.size.width, additionalInset: additionalInset, transition: transition)
        var sectionOffset: CGFloat = 0.0
        if navigationBarHeight.isZero {
            sectionOffset = -sectionsHeight
        }
        transition.updateFrame(node: self.sectionsNode, frame: CGRect(origin: CGPoint(x: 0.0, y: navigationBarHeight + sectionOffset), size: CGSize(width: layout.size.width, height: sectionsHeight)))
        
        var insets = vanillaInsets
        if !navigationBarHeight.isZero {
            insets.top += sectionsHeight
        }
        
        if let inputHeight = layout.inputHeight {
            insets.bottom += inputHeight
        }
        
        if let selectionState = self.mediaCollectionInterfaceState.selectionState {
            let interfaceState = self.chatPresentationInterfaceState.updatedPeer({ _ in self.mediaCollectionInterfaceState.peer.flatMap(RenderedPeer.init) })
            
            if let selectionPanel = self.selectionPanel {
                selectionPanel.selectedMessages = selectionState.selectedIds
                let panelHeight = selectionPanel.updateLayout(width: layout.size.width, leftInset: layout.safeInsets.left, rightInset: layout.safeInsets.right, maxHeight: 0.0, transition: transition, interfaceState: interfaceState)
                transition.updateFrame(node: selectionPanel, frame: CGRect(origin: CGPoint(x: 0.0, y: layout.size.height - insets.bottom - panelHeight), size: CGSize(width: layout.size.width, height: panelHeight)))
                if let selectionPanelSeparatorNode = self.selectionPanelSeparatorNode {
                    transition.updateFrame(node: selectionPanelSeparatorNode, frame: CGRect(origin: CGPoint(x: 0.0, y: layout.size.height - insets.bottom - panelHeight), size: CGSize(width: layout.size.width, height: UIScreenPixel)))
                }
                if let selectionPanelBackgroundNode = self.selectionPanelBackgroundNode {
                    transition.updateFrame(node: selectionPanelBackgroundNode, frame: CGRect(origin: CGPoint(x: 0.0, y: layout.size.height - insets.bottom - panelHeight), size: CGSize(width: layout.size.width, height: insets.bottom + panelHeight)))
                }
            } else {
                let selectionPanelBackgroundNode = ASDisplayNode()
                selectionPanelBackgroundNode.isLayerBacked = true
                selectionPanelBackgroundNode.backgroundColor = self.presentationData.theme.chat.inputPanel.panelBackgroundColor
                self.addSubnode(selectionPanelBackgroundNode)
                self.selectionPanelBackgroundNode = selectionPanelBackgroundNode
                
                let selectionPanel = ChatMessageSelectionInputPanelNode(theme: self.chatPresentationInterfaceState.theme)
                selectionPanel.account = self.account
                selectionPanel.backgroundColor = self.presentationData.theme.chat.inputPanel.panelBackgroundColor
                selectionPanel.interfaceInteraction = self.interfaceInteraction
                selectionPanel.selectedMessages = selectionState.selectedIds
                let panelHeight = selectionPanel.updateLayout(width: layout.size.width, leftInset: layout.safeInsets.left, rightInset: layout.safeInsets.right, maxHeight: 0.0, transition: .immediate, interfaceState: interfaceState)
                self.selectionPanel = selectionPanel
                self.addSubnode(selectionPanel)
                
                let selectionPanelSeparatorNode = ASDisplayNode()
                selectionPanelSeparatorNode.isLayerBacked = true
                selectionPanelSeparatorNode.backgroundColor = self.presentationData.theme.chat.inputPanel.panelStrokeColor
                self.addSubnode(selectionPanelSeparatorNode)
                self.selectionPanelSeparatorNode = selectionPanelSeparatorNode
                
                selectionPanel.frame = CGRect(origin: CGPoint(x: 0.0, y: layout.size.height), size: CGSize(width: layout.size.width, height: panelHeight))
                selectionPanelBackgroundNode.frame = CGRect(origin: CGPoint(x: 0.0, y: layout.size.height), size: CGSize(width: layout.size.width, height: 0.0))
                selectionPanelSeparatorNode.frame = CGRect(origin: CGPoint(x: 0.0, y: layout.size.height), size: CGSize(width: layout.size.width, height: UIScreenPixel))
                transition.updateFrame(node: selectionPanel, frame: CGRect(origin: CGPoint(x: 0.0, y: layout.size.height - insets.bottom - panelHeight), size: CGSize(width: layout.size.width, height: panelHeight)))
                transition.updateFrame(node: selectionPanelBackgroundNode, frame: CGRect(origin: CGPoint(x: 0.0, y: layout.size.height - insets.bottom - panelHeight), size: CGSize(width: layout.size.width, height: insets.bottom + panelHeight)))
                transition.updateFrame(node: selectionPanelSeparatorNode, frame: CGRect(origin: CGPoint(x: 0.0, y: layout.size.height - insets.bottom - panelHeight), size: CGSize(width: layout.size.width, height: UIScreenPixel)))
            }
        } else if let selectionPanel = self.selectionPanel {
            self.selectionPanel = nil
            transition.updateFrame(node: selectionPanel, frame: selectionPanel.frame.offsetBy(dx: 0.0, dy: selectionPanel.bounds.size.height + insets.bottom), completion: { [weak selectionPanel] _ in
                selectionPanel?.removeFromSupernode()
            })
            if let selectionPanelSeparatorNode = self.selectionPanelSeparatorNode {
                transition.updateFrame(node: selectionPanelSeparatorNode, frame: selectionPanelSeparatorNode.frame.offsetBy(dx: 0.0, dy: selectionPanel.bounds.size.height + insets.bottom), completion: { [weak selectionPanelSeparatorNode] _ in
                    selectionPanelSeparatorNode?.removeFromSupernode()
                })
            }
            if let selectionPanelBackgroundNode = self.selectionPanelBackgroundNode {
                transition.updateFrame(node: selectionPanelBackgroundNode, frame: selectionPanelBackgroundNode.frame.offsetBy(dx: 0.0, dy: selectionPanel.bounds.size.height + insets.bottom), completion: { [weak selectionPanelSeparatorNode] _ in
                    selectionPanelSeparatorNode?.removeFromSupernode()
                })
            }
        }
        
        var duration: Double = 0.0
        var curve: UInt = 0
        switch transition {
            case .immediate:
                break
            case let .animated(animationDuration, animationCurve):
                duration = animationDuration
                switch animationCurve {
                    case .easeInOut:
                        break
                    case .spring:
                        curve = 7
                }
        }
        
        let previousBounds = self.historyNode.bounds
        self.historyNode.bounds = CGRect(x: previousBounds.origin.x, y: previousBounds.origin.y, width: layout.size.width, height: layout.size.height)
        self.historyNode.position = CGPoint(x: layout.size.width / 2.0, y: layout.size.height / 2.0)

        self.historyEmptyNode.updateLayout(size: layout.size, insets: vanillaInsets, transition: transition)
        transition.updateFrame(node: self.historyEmptyNode, frame: CGRect(origin: CGPoint(), size: layout.size))

        let listViewCurve: ListViewAnimationCurve
        if curve == 7 {
            listViewCurve = .Spring(duration: duration)
        } else {
            listViewCurve = .Default
        }
        
        var additionalBottomInset: CGFloat = 0.0
        if let selectionPanel = self.selectionPanel {
            additionalBottomInset = selectionPanel.bounds.size.height
        }
        
        listViewTransaction(ListViewUpdateSizeAndInsets(size: layout.size, insets: UIEdgeInsets(top: insets.top, left:
            insets.right + layout.safeInsets.right, bottom: insets.bottom + additionalBottomInset, right: insets.left + layout.safeInsets.right), duration: duration, curve: listViewCurve))
        
        if let (candidateHistoryNode, _) = self.candidateHistoryNode {
            let previousBounds = candidateHistoryNode.bounds
            candidateHistoryNode.bounds = CGRect(x: previousBounds.origin.x, y: previousBounds.origin.y, width: layout.size.width, height: layout.size.height)
            candidateHistoryNode.position = CGPoint(x: layout.size.width / 2.0, y: layout.size.height / 2.0)
            
            (candidateHistoryNode as! ChatHistoryNode).updateLayout(transition: transition, updateSizeAndInsets: ListViewUpdateSizeAndInsets(size: layout.size, insets: UIEdgeInsets(top: insets.top, left:
                insets.right + layout.safeInsets.right, bottom: insets.bottom + additionalBottomInset, right: insets.left + layout.safeInsets.left), duration: duration, curve: listViewCurve))
        }
    }
    
    func activateSearch() {
        guard let (containerLayout, navigationBarHeight) = self.containerLayout, let navigationBar = self.navigationBar else {
            return
        }
        
        var maybePlaceholderNode: SearchBarPlaceholderNode?
        if let listNode = historyNode as? ListView {
            listNode.forEachItemNode { node in
                if let node = node as? ChatListSearchItemNode {
                    maybePlaceholderNode = node.searchBarNode
                }
            }
        }
        
        if let _ = self.searchDisplayController {
            return
        }
        
        if let placeholderNode = maybePlaceholderNode {
            self.searchDisplayController = SearchDisplayController(theme: self.presentationData.theme, strings: self.presentationData.strings, contentNode: ChatHistorySearchContainerNode(account: self.account, peerId: self.peerId, tagMask: tagMaskForMode(self.mediaCollectionInterfaceState.mode), interfaceInteraction: self.controllerInteraction), cancel: { [weak self] in
                self?.requestDeactivateSearch()
            })
            
            self.searchDisplayController?.containerLayoutUpdated(containerLayout, navigationBarHeight: navigationBarHeight, transition: .immediate)
            self.searchDisplayController?.activate(insertSubnode: { subnode in
                self.insertSubnode(subnode, belowSubnode: navigationBar)
            }, placeholder: placeholderNode)
        }
    }
    
    func deactivateSearch() {
        if let searchDisplayController = self.searchDisplayController {
            self.searchDisplayController = nil
            var maybePlaceholderNode: SearchBarPlaceholderNode?
            if let listNode = self.historyNode as? ListView {
                listNode.forEachItemNode { node in
                    if let node = node as? ChatListSearchItemNode {
                        maybePlaceholderNode = node.searchBarNode
                    }
                }
            }
            
            searchDisplayController.deactivate(placeholder: maybePlaceholderNode)
        }
    }
    
    func updateMediaCollectionInterfaceState(_ mediaCollectionInterfaceState: PeerMediaCollectionInterfaceState, animated: Bool) {
        if self.mediaCollectionInterfaceState != mediaCollectionInterfaceState {
            if self.mediaCollectionInterfaceState.mode != mediaCollectionInterfaceState.mode {
                let previousMode = self.mediaCollectionInterfaceState.mode
                if let containerLayout = self.containerLayout, self.candidateHistoryNode == nil || self.candidateHistoryNode!.1 != mediaCollectionInterfaceState.mode {
                    let node = historyNodeImplForMode(mediaCollectionInterfaceState.mode, account: self.account, peerId: self.peerId, messageId: nil, controllerInteraction: self.controllerInteraction, selectedMessages: self.selectedMessagesPromise.get())
                    node.backgroundColor = self.presentationData.theme.list.plainBackgroundColor
                    self.candidateHistoryNode = (node, mediaCollectionInterfaceState.mode)
                    
                    var vanillaInsets = containerLayout.0.insets(options: [])
                    vanillaInsets.top += containerLayout.1
                    
                    if let searchDisplayController = self.searchDisplayController {
                        if !searchDisplayController.isDeactivating {
                            vanillaInsets.top += 20.0
                        }
                    }
                    
                    var insets = vanillaInsets
                    
                    if !containerLayout.1.isZero {
                        insets.top += self.sectionsNode.bounds.size.height
                    }
                    
                    if let inputHeight = containerLayout.0.inputHeight {
                        insets.bottom += inputHeight
                    }
                    
                    let previousBounds = node.bounds
                    node.bounds = CGRect(x: previousBounds.origin.x, y: previousBounds.origin.y, width: containerLayout.0.size.width, height: containerLayout.0.size.height)
                    node.position = CGPoint(x: containerLayout.0.size.width / 2.0, y: containerLayout.0.size.height / 2.0)
                    
                    var additionalBottomInset: CGFloat = 0.0
                    if let selectionPanel = self.selectionPanel {
                        additionalBottomInset = selectionPanel.bounds.size.height
                    }
                    
                    node.updateLayout(transition: .immediate, updateSizeAndInsets: ListViewUpdateSizeAndInsets(size: containerLayout.0.size, insets: UIEdgeInsets(top: insets.top, left: insets.right + containerLayout.0.safeInsets.right, bottom: insets.bottom + additionalBottomInset, right: insets.left + containerLayout.0.safeInsets.left), duration: 0.0, curve: .Default))
                    
                    let historyEmptyNode = PeerMediaCollectionEmptyNode(mode: mediaCollectionInterfaceState.mode, theme: self.presentationData.theme, strings: self.presentationData.strings)
                    historyEmptyNode.isHidden = true
                    historyEmptyNode.updateLayout(size: containerLayout.0.size, insets: vanillaInsets, transition: .immediate)
                    historyEmptyNode.frame = CGRect(origin: CGPoint(), size: containerLayout.0.size)
                    
                    self.candidateHistoryNodeReadyDisposable.set((node.historyState.get()
                        |> deliverOnMainQueue).start(next: { [weak self, weak node] _ in
                            if let strongSelf = self, let strongNode = node, strongNode == strongSelf.candidateHistoryNode?.0 {
                                strongSelf.candidateHistoryNode = nil
                                strongSelf.insertSubnode(strongNode, belowSubnode: strongSelf.historyNode)
                                strongSelf.insertSubnode(historyEmptyNode, aboveSubnode: strongNode)
                                
                                let previousNode = strongSelf.historyNode
                                let previousEmptyNode = strongSelf.historyEmptyNode
                                strongSelf.historyNode = strongNode
                                strongSelf.historyEmptyNode = historyEmptyNode
                                updateLoadNodeState(strongSelf.historyEmptyNode, strongSelf.historyNode.loadState)
                                strongSelf.historyNode.setLoadStateUpdated { loadState, _ in
                                    if let strongSelf = self {
                                        updateLoadNodeState(strongSelf.historyEmptyNode, loadState)
                                    }
                                }
                                
                                let directionMultiplier: CGFloat
                                if previousMode.rawValue < mediaCollectionInterfaceState.mode.rawValue {
                                    directionMultiplier = 1.0
                                } else {
                                    directionMultiplier = -1.0
                                }
                                
                                previousNode.layer.animatePosition(from: CGPoint(), to: CGPoint(x: -directionMultiplier * strongSelf.bounds.width, y: 0.0), duration: 0.4, timingFunction: kCAMediaTimingFunctionSpring, removeOnCompletion: false, additive: true, completion: { [weak previousNode] _ in
                                    previousNode?.removeFromSupernode()
                                })
                                previousEmptyNode.layer.animatePosition(from: CGPoint(), to: CGPoint(x: -directionMultiplier * strongSelf.bounds.width, y: 0.0), duration: 0.4, timingFunction: kCAMediaTimingFunctionSpring, removeOnCompletion: false, additive: true, completion: { [weak previousEmptyNode] _ in
                                    previousEmptyNode?.removeFromSupernode()
                                })
                                strongSelf.historyNode.layer.animatePosition(from: CGPoint(x: directionMultiplier * strongSelf.bounds.width, y: 0.0), to: CGPoint(), duration: 0.4, timingFunction: kCAMediaTimingFunctionSpring, additive: true)
                                strongSelf.historyEmptyNode.layer.animatePosition(from: CGPoint(x: directionMultiplier * strongSelf.bounds.width, y: 0.0), to: CGPoint(), duration: 0.4, timingFunction: kCAMediaTimingFunctionSpring, additive: true)
                            }
                        }))
                }
            }
            
            self.mediaCollectionInterfaceState = mediaCollectionInterfaceState
            
            self.requestLayout(animated ? .animated(duration: 0.4, curve: .spring) : .immediate)
        }
    }
    
    func updateHiddenMedia() {
        self.historyNode.forEachItemNode { itemNode in
            if let itemNode = itemNode as? ChatMessageItemView {
                itemNode.updateHiddenMedia()
            } else if let itemNode = itemNode as? ListMessageNode {
                itemNode.updateHiddenMedia()
            } else if let itemNode = itemNode as? GridMessageItemNode {
                itemNode.updateHiddenMedia()
            }
        }
        
        if let searchContentNode = self.searchDisplayController?.contentNode as? ChatHistorySearchContainerNode {
            searchContentNode.updateHiddenMedia()
        }
    }
    
    func messageForGallery(_ id: MessageId) -> PeerMediaCollectionMessageForGallery? {
        if let message = self.historyNode.messageInCurrentHistoryView(id) {
            return PeerMediaCollectionMessageForGallery(message: message, fromSearchResults: false)
        }
        
        if let searchContentNode = self.searchDisplayController?.contentNode as? ChatHistorySearchContainerNode {
            if let message = searchContentNode.messageForGallery(id) {
                return PeerMediaCollectionMessageForGallery(message: message, fromSearchResults: true)
            }
        }
        
        return nil
    }
    
    func transitionNodeForGallery(messageId: MessageId, media: Media) -> (ASDisplayNode, () -> UIView?)? {
        if let searchContentNode = self.searchDisplayController?.contentNode as? ChatHistorySearchContainerNode {
            if let transitionNode = searchContentNode.transitionNodeForGallery(messageId: messageId, media: media) {
                return transitionNode
            }
        }
        
        var transitionNode: (ASDisplayNode, () -> UIView?)?
        self.historyNode.forEachItemNode { itemNode in
            if let itemNode = itemNode as? ChatMessageItemView {
                if let result = itemNode.transitionNode(id: messageId, media: media) {
                    transitionNode = result
                }
            } else if let itemNode = itemNode as? ListMessageNode {
                if let result = itemNode.transitionNode(id: messageId, media: media) {
                    transitionNode = result
                }
            } else if let itemNode = itemNode as? GridMessageItemNode {
                if let result = itemNode.transitionNode(id: messageId, media: media) {
                    transitionNode = result
                }
            }
        }
        if let transitionNode = transitionNode {
            return transitionNode
        }
        
        return nil
    }
}
