import Foundation
import AsyncDisplayKit
import Display
import Postbox
import TelegramCore

enum ChatMessageBubbleContentBackgroundHiding {
    case never
    case emptyWallpaper
    case always
}

enum ChatMessageBubbleContentAlignment {
    case none
    case center
}

struct ChatMessageBubbleContentProperties {
    let hidesSimpleAuthorHeader: Bool
    let headerSpacing: CGFloat
    let hidesBackground: ChatMessageBubbleContentBackgroundHiding
    let forceFullCorners: Bool
    let forceAlignment: ChatMessageBubbleContentAlignment
}

enum ChatMessageBubbleNoneMergeStatus {
    case Incoming
    case Outgoing
    case None
}

enum ChatMessageBubbleMergeStatus {
    case None(ChatMessageBubbleNoneMergeStatus)
    case Left
    case Right
}

enum ChatMessageBubbleRelativePosition {
    case None(ChatMessageBubbleMergeStatus)
    case Neighbour
}

enum ChatMessageBubbleContentMosaicNeighbor {
    case merged
    case none(tail: Bool)
}

struct ChatMessageBubbleContentMosaicPosition {
    let topLeft: ChatMessageBubbleContentMosaicNeighbor
    let topRight: ChatMessageBubbleContentMosaicNeighbor
    let bottomLeft: ChatMessageBubbleContentMosaicNeighbor
    let bottomRight: ChatMessageBubbleContentMosaicNeighbor
}

enum ChatMessageBubbleContentPosition {
    case linear(top: ChatMessageBubbleRelativePosition, bottom: ChatMessageBubbleRelativePosition)
    case mosaic(position: ChatMessageBubbleContentMosaicPosition)
}

enum ChatMessageBubblePreparePosition {
    case linear(top: ChatMessageBubbleRelativePosition, bottom: ChatMessageBubbleRelativePosition)
    case mosaic(top: ChatMessageBubbleRelativePosition, bottom: ChatMessageBubbleRelativePosition)
}

enum ChatMessageBubbleContentTapAction {
    case none
    case url(String)
    case textMention(String)
    case peerMention(PeerId, String)
    case botCommand(String)
    case hashtag(String?, String)
    case instantPage
    case call(PeerId)
    case ignore
}

final class ChatMessageBubbleContentItem {
    let account: Account
    let controllerInteraction: ChatControllerInteraction
    let message: Message
    let read: Bool
    let presentationData: ChatPresentationData
    
    init(account: Account, controllerInteraction: ChatControllerInteraction, message: Message, read: Bool, presentationData: ChatPresentationData) {
        self.account = account
        self.controllerInteraction = controllerInteraction
        self.message = message
        self.read = read
        self.presentationData = presentationData
    }
}

class ChatMessageBubbleContentNode: ASDisplayNode {
    var supportsMosaic: Bool {
        return false
    }
    
    var visibility: ListViewItemNodeVisibility = .none
    
    var item: ChatMessageBubbleContentItem?
    
    required override init() {
        super.init()
    }
    
    func asyncLayoutContent() -> (_ item: ChatMessageBubbleContentItem, _ layoutConstants: ChatMessageItemLayoutConstants, _ preparePosition: ChatMessageBubblePreparePosition, _ messageSelection: Bool?, _ constrainedSize: CGSize) -> (ChatMessageBubbleContentProperties, unboundSize: CGSize?, maxWidth: CGFloat, layout: (CGSize, ChatMessageBubbleContentPosition) -> (CGFloat, (CGFloat) -> (CGSize, (ListViewItemUpdateAnimation) -> Void))) {
        preconditionFailure()
    }
    
    func animateInsertion(_ currentTimestamp: Double, duration: Double) {
    }
    
    func animateAdded(_ currentTimestamp: Double, duration: Double) {
    }
    
    func animateRemoved(_ currentTimestamp: Double, duration: Double) {
    }
    
    func animateInsertionIntoBubble(_ duration: Double) {
    }
    
    func animateRemovalFromBubble(_ duration: Double, completion: @escaping () -> Void) {
        self.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.25, removeOnCompletion: false, completion: { _ in
            completion()
        })
    }
    
    func transitionNode(messageId: MessageId, media: Media) -> (ASDisplayNode, () -> UIView?)? {
        return nil
    }
    
    func peekPreviewContent(at point: CGPoint) -> (Message, ChatMessagePeekPreviewContent)? {
        return nil
    }
    
    func updateHiddenMedia(_ media: [Media]?) -> Bool {
        return false
    }
    
    func updateAutomaticMediaDownloadSettings(_ settings: AutomaticMediaDownloadSettings) {
    }
    
    func tapActionAtPoint(_ point: CGPoint) -> ChatMessageBubbleContentTapAction {
        return .none
    }
    
    func updateTouchesAtPoint(_ point: CGPoint?) {
    }
    
    func updateHighlightedState(animated: Bool) -> Bool {
        return false
    }
}
