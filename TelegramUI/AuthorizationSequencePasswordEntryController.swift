import Foundation
import Display
import AsyncDisplayKit

final class AuthorizationSequencePasswordEntryController: ViewController {
    private var controllerNode: AuthorizationSequencePasswordEntryControllerNode {
        return self.displayNode as! AuthorizationSequencePasswordEntryControllerNode
    }
    
    private let strings: PresentationStrings
    private let theme: AuthorizationTheme
    
    var loginWithPassword: ((String) -> Void)?
    var forgot: (() -> Void)?
    var reset: (() -> Void)?
    var hint: String?
    
    var didForgotWithNoRecovery: Bool = false {
        didSet {
            if self.didForgotWithNoRecovery != oldValue {
                if self.isNodeLoaded, let hint = self.hint {
                    self.controllerNode.updateData(hint: hint, didForgotWithNoRecovery: didForgotWithNoRecovery)
                }
            }
        }
    }
    
    private let hapticFeedback = HapticFeedback()
    
    var inProgress: Bool = false {
        didSet {
            if self.inProgress {
                let item = UIBarButtonItem(customDisplayNode: ProgressNavigationButtonNode(color: self.theme.accentColor))
                self.navigationItem.rightBarButtonItem = item
            } else {
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: self.strings.Common_Next, style: .done, target: self, action: #selector(self.nextPressed))
            }
            self.controllerNode.inProgress = self.inProgress
        }
    }
    
    init(strings: PresentationStrings, theme: AuthorizationTheme) {
        self.strings = strings
        self.theme = theme
        
        super.init(navigationBarPresentationData: NavigationBarPresentationData(theme: AuthorizationSequenceController.navigationBarTheme(theme), strings: NavigationBarStrings(presentationStrings: strings)))
        
        self.hasActiveInput = true
        
        self.statusBar.statusBarStyle = theme.statusBarStyle
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: self.strings.Common_Next, style: .done, target: self, action: #selector(self.nextPressed))
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func loadDisplayNode() {
        self.displayNode = AuthorizationSequencePasswordEntryControllerNode(strings: self.strings, theme: self.theme)
        self.displayNodeDidLoad()
        
        self.controllerNode.loginWithCode = { [weak self] _ in
            self?.nextPressed()
        }
        
        self.controllerNode.forgot = { [weak self] in
            self?.forgotPressed()
        }
        
        self.controllerNode.reset = { [weak self] in
            self?.resetPressed()
        }
        
        if let hint = self.hint {
            self.controllerNode.updateData(hint: hint, didForgotWithNoRecovery: self.didForgotWithNoRecovery)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.controllerNode.activateInput()
    }
    
    func updateData(hint: String) {
        if self.hint != hint {
            self.hint = hint
            if self.isNodeLoaded {
                self.controllerNode.updateData(hint: hint, didForgotWithNoRecovery: self.didForgotWithNoRecovery)
            }
        }
    }
    
    override func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        
        self.controllerNode.containerLayoutUpdated(layout, navigationBarHeight: self.navigationHeight, transition: transition)
    }
    
    @objc func nextPressed() {
        if self.controllerNode.currentPassword.isEmpty {
            hapticFeedback.error()
            self.controllerNode.animateError()
        } else {
            self.loginWithPassword?(self.controllerNode.currentPassword)
        }
    }
    
    func forgotPressed() {
        if self.didForgotWithNoRecovery {
            self.present(standardTextAlertController(theme: AlertControllerTheme(authTheme: self.theme), title: nil, text: self.strings.TwoStepAuth_RecoveryUnavailable, actions: [TextAlertAction(type: .defaultAction, title: self.strings.Common_OK, action: {})]), in: .window(.root))
        } else {
            self.forgot?()
        }
    }
    
    func resetPressed() {
        self.reset?()
    }
}
