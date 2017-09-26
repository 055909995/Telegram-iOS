import Foundation
import UIKit
import AsyncDisplayKit
import Postbox
import Display
import SwiftSignalKit
import TelegramCore

class ChatListRecentPeersListItem: ListViewItem {
    let theme: PresentationTheme
    let strings: PresentationStrings
    let account: Account
    let peers: [Peer]
    let peerSelected: (Peer) -> Void
    
    let header: ListViewItemHeader?
    
    init(theme: PresentationTheme, strings: PresentationStrings, account: Account, peers: [Peer], peerSelected: @escaping (Peer) -> Void) {
        self.theme = theme
        self.strings = strings
        self.account = account
        self.peers = peers
        self.peerSelected = peerSelected
        self.header = nil
    }
    
    func nodeConfiguredForWidth(async: @escaping (@escaping () -> Void) -> Void, width: CGFloat, previousItem: ListViewItem?, nextItem: ListViewItem?, completion: @escaping (ListViewItemNode, @escaping () -> (Signal<Void, NoError>?, () -> Void)) -> Void) {
        async {
            let node = ChatListRecentPeersListItemNode()
            let makeLayout = node.asyncLayout()
            let (nodeLayout, nodeApply) = makeLayout(self, width, nextItem != nil)
            node.contentSize = nodeLayout.contentSize
            node.insets = nodeLayout.insets
            
            completion(node, nodeApply)
        }
    }
    
    func updateNode(async: @escaping (@escaping () -> Void) -> Void, node: ListViewItemNode, width: CGFloat, previousItem: ListViewItem?, nextItem: ListViewItem?, animation: ListViewItemUpdateAnimation, completion: @escaping (ListViewItemNodeLayout, @escaping () -> Void) -> Void) {
        if let node = node as? ChatListRecentPeersListItemNode {
            Queue.mainQueue().async {
                let layout = node.asyncLayout()
                async {
                    let (nodeLayout, apply) = layout(self, width, nextItem != nil)
                    Queue.mainQueue().async {
                        completion(nodeLayout, {
                            apply().1()
                        })
                    }
                }
            }
        }
    }
}

private let separatorHeight = 1.0 / UIScreen.main.scale

class ChatListRecentPeersListItemNode: ListViewItemNode {
    private let backgroundNode: ASDisplayNode
    private let separatorNode: ASDisplayNode
    private var peersNode: ChatListSearchRecentPeersNode?
    
    private var item: ChatListRecentPeersListItem?
    
    required init() {
        self.backgroundNode = ASDisplayNode()
        self.backgroundNode.isLayerBacked = true
        
        self.separatorNode = ASDisplayNode()
        self.separatorNode.isLayerBacked = true
        
        super.init(layerBacked: false, dynamicBounce: false)
        
        self.addSubnode(self.backgroundNode)
        self.addSubnode(self.separatorNode)
    }
    
    override func layoutForWidth(_ width: CGFloat, item: ListViewItem, previousItem: ListViewItem?, nextItem: ListViewItem?) {
        if let item = self.item {
            let makeLayout = self.asyncLayout()
            let (nodeLayout, nodeApply) = makeLayout(item, width, nextItem == nil)
            self.contentSize = nodeLayout.contentSize
            self.insets = nodeLayout.insets
            let _ = nodeApply()
        }
    }
    
    func asyncLayout() -> (_ item: ChatListRecentPeersListItem, _ width: CGFloat, _ last: Bool) -> (ListViewItemNodeLayout, () -> (Signal<Void, NoError>?, () -> Void)) {
        let currentItem = self.item
        
        return { [weak self] item, width, last in
            let nodeLayout = ListViewItemNodeLayout(contentSize: CGSize(width: width, height: 130.0), insets: UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0))
            
            return (nodeLayout, { [weak self] in
                var updatedTheme: PresentationTheme?
                if currentItem?.theme !== item.theme {
                    updatedTheme = item.theme
                }
                
                return (nil, {
                    if let strongSelf = self {
                        strongSelf.item = item
                        
                        if let _ = updatedTheme {
                            strongSelf.separatorNode.backgroundColor = item.theme.list.itemSeparatorColor
                            strongSelf.backgroundNode.backgroundColor = item.theme.list.itemBackgroundColor
                        }
                        
                        let peersNode: ChatListSearchRecentPeersNode
                        if let currentPeersNode = strongSelf.peersNode {
                            peersNode = currentPeersNode
                            peersNode.updateThemeAndStrings(theme: item.theme, strings: item.strings)
                        } else {
                            peersNode = ChatListSearchRecentPeersNode(account: item.account, theme: item.theme, strings: item.strings, peerSelected: { peer in
                                self?.item?.peerSelected(peer)
                            }, isPeerSelected: { _ in
                                return false
                            })
                            strongSelf.peersNode = peersNode
                            strongSelf.addSubnode(peersNode)
                        }
                        
                        let separatorHeight = UIScreenPixel
                        
                        peersNode.frame = CGRect(origin: CGPoint(), size: nodeLayout.contentSize)
                        
                        strongSelf.backgroundNode.frame = CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: CGSize(width: nodeLayout.contentSize.width, height: nodeLayout.contentSize.height))
                        strongSelf.separatorNode.frame = CGRect(origin: CGPoint(x: 0.0, y: nodeLayout.contentSize.height - separatorHeight), size: CGSize(width: nodeLayout.size.width, height: separatorHeight))
                        strongSelf.separatorNode.isHidden = true
                    }
                })
            })
        }
    }
    
    override func animateInsertion(_ currentTimestamp: Double, duration: Double, short: Bool) {
        self.layer.animateAlpha(from: 0.0, to: 1.0, duration: duration * 0.5)
    }
    
    override func animateRemoved(_ currentTimestamp: Double, duration: Double) {
        self.layer.animateAlpha(from: 1.0, to: 0.0, duration: duration * 0.5, removeOnCompletion: false)
    }
    
    override public func header() -> ListViewItemHeader? {
        if let item = self.item {
            return item.header
        } else {
            return nil
        }
    }
    
    func viewAndPeerAtPoint(_ point: CGPoint) -> (UIView, PeerId)? {
        if let peersNode = self.peersNode {
            let adjustedLocation = self.convert(point, to: peersNode)
            if let result = peersNode.viewAndPeerAtPoint(adjustedLocation) {
                return result
            }
        }
        return nil
    }
    
    func removePeer(_ peerId: PeerId) {
        self.peersNode?.removePeer(peerId)
    }
}
