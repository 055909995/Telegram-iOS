import Foundation
import TelegramCore
import Postbox
import Display
import SwiftSignalKit

final class OverlayPlayerController: ViewController {
    private let account: Account
    let peerId: PeerId
    let type: MediaManagerPlayerType
    let initialMessageId: MessageId
    let initialOrder: MusicPlaybackSettingsOrder
    
    private weak var parentNavigationController: NavigationController?
    
    private var animatedIn = false
    
    private var controllerNode: OverlayPlayerControllerNode {
        return self.displayNode as! OverlayPlayerControllerNode
    }
    
    init(account: Account, peerId: PeerId, type: MediaManagerPlayerType, initialMessageId: MessageId, initialOrder: MusicPlaybackSettingsOrder, parentNavigationController: NavigationController?) {
        self.account = account
        self.peerId = peerId
        self.type = type
        self.initialMessageId = initialMessageId
        self.initialOrder = initialOrder
        self.parentNavigationController = parentNavigationController
        
        super.init(navigationBarPresentationData: nil)
        
        self.statusBar.statusBarStyle = .Ignore
        
        self.ready.set(.never())
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func loadDisplayNode() {
        self.displayNode = OverlayPlayerControllerNode(account: self.account, peerId: self.peerId, type: self.type, initialMessageId: self.initialMessageId, initialOrder: self.initialOrder, requestDismiss: { [weak self] in
            self?.dismiss()
        }, requestShare: { [weak self] messageId in
            if let strongSelf = self {
                let _ = (strongSelf.account.postbox.transaction { transaction -> Message? in
                    return transaction.getMessage(messageId)
                } |> deliverOnMainQueue).start(next: { message in
                    if let strongSelf = self, let message = message {
                        let shareController = ShareController(account: strongSelf.account, subject: .messages([message]), showInChat: { message in
                            if let strongSelf = self, let navigationController = strongSelf.parentNavigationController {
                                navigateToChatController(navigationController: navigationController, account: strongSelf.account, chatLocation: .peer(message.id.peerId), messageId: messageId, animated: true)
                                strongSelf.dismiss()
                            }
                        }, externalShare: true)
                        strongSelf.controllerNode.view.endEditing(true)
                        strongSelf.present(shareController, in: .window(.root))
                    }
                })
            }
        })
        
        self.ready.set(self.controllerNode.ready.get())
        
        self.displayNodeDidLoad()
    }
    
    override public func loadView() {
        super.loadView()
        
        self.statusBar.removeFromSupernode()
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !self.animatedIn {
            self.animatedIn = true
            self.controllerNode.animateIn()
        }
    }
    
    override public func dismiss(completion: (() -> Void)? = nil) {
        self.controllerNode.animateOut(completion: { [weak self] in
            self?.presentingViewController?.dismiss(animated: false, completion: nil)
            completion?()
        })
    }
    
    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        
        self.controllerNode.containerLayoutUpdated(layout, transition: transition)
    }
}
