import Foundation
import Display
import AsyncDisplayKit
import TelegramCore
import SwiftSignalKit
import Postbox

enum BotCheckoutWebInteractionControllerIntent {
    case addPaymentMethod((BotCheckoutPaymentMethod) -> Void)
    case externalVerification((Bool) -> Void)
}

final class BotCheckoutWebInteractionController: ViewController {
    private var controllerNode: BotCheckoutWebInteractionControllerNode {
        return self.displayNode as! BotCheckoutWebInteractionControllerNode
    }
    
    private let account: Account
    private let url: String
    private let intent: BotCheckoutWebInteractionControllerIntent
    
    private var presentationData: PresentationData
    
    private var didPlayPresentationAnimation = false
    
    init(account: Account, url: String, intent: BotCheckoutWebInteractionControllerIntent) {
        self.account = account
        self.url = url
        self.intent = intent
        
        self.presentationData = account.telegramApplicationContext.currentPresentationData.with { $0 }
        
        super.init(navigationBarTheme: NavigationBarTheme(rootControllerTheme: (account.telegramApplicationContext.currentPresentationData.with { $0 }).theme))
        
        self.statusBar.statusBarStyle = self.presentationData.theme.rootController.statusBar.style.style
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: self.presentationData.strings.Common_Cancel, style: .plain, target: self, action: #selector(self.cancelPressed))
        
        switch intent {
            case .addPaymentMethod:
                self.title = self.presentationData.strings.Checkout_NewCard_Title
            case .externalVerification:
                self.title = self.presentationData.strings.Checkout_WebConfirmation_Title
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func cancelPressed() {
        if case let .externalVerification(completion) = self.intent {
            completion(false)
        }
        self.dismiss()
    }
    
    override func loadDisplayNode() {
        self.displayNode = BotCheckoutWebInteractionControllerNode(presentationData: self.presentationData, url: self.url, intent: self.intent)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !self.didPlayPresentationAnimation {
            self.didPlayPresentationAnimation = true
            self.controllerNode.animateIn()
        }
    }
    
    override func dismiss(completion: (() -> Void)? = nil) {
        self.controllerNode.animateOut(completion: { [weak self] in
            self?.presentingViewController?.dismiss(animated: false, completion: nil)
            completion?()
        })
    }
    
    override func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        
        self.controllerNode.containerLayoutUpdated(layout, navigationBarHeight: self.navigationHeight, transition: transition)
    }
}
