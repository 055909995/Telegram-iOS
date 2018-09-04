import Foundation
import Display
import AsyncDisplayKit
import Postbox
import TelegramCore

final class SecureIdAuthControllerNode: ViewControllerTracingNode {
    private let account: Account
    private var presentationData: PresentationData
    private let requestLayout: (ContainedViewLayoutTransition) -> Void
    private let interaction: SecureIdAuthControllerInteraction
    
    private var validLayout: (ContainerViewLayout, CGFloat)?
    
    private let scrollNode: ASScrollNode
    private let headerNode: SecureIdAuthHeaderNode
    private var contentNode: (ASDisplayNode & SecureIdAuthContentNode)?
    private var dismissedContentNode: (ASDisplayNode & SecureIdAuthContentNode)?
    private let acceptNode: SecureIdAuthAcceptNode
    
    private var scheduledLayoutTransitionRequestId: Int = 0
    private var scheduledLayoutTransitionRequest: (Int, ContainedViewLayoutTransition)?
    
    private var state: SecureIdAuthControllerState?
    
    init(account: Account, presentationData: PresentationData, requestLayout: @escaping (ContainedViewLayoutTransition) -> Void, interaction: SecureIdAuthControllerInteraction) {
        self.account = account
        self.presentationData = presentationData
        self.requestLayout = requestLayout
        self.interaction = interaction
        
        self.scrollNode = ASScrollNode()
        self.headerNode = SecureIdAuthHeaderNode(account: account, theme: presentationData.theme, strings: presentationData.strings)
        self.acceptNode = SecureIdAuthAcceptNode(title: presentationData.strings.Passport_Authorize, theme: presentationData.theme)
        
        super.init()
        
        self.scrollNode.view.alwaysBounceVertical = true
        self.addSubnode(self.scrollNode)
        
        self.backgroundColor = presentationData.theme.list.blocksBackgroundColor
        self.acceptNode.pressed = { [weak self] in
            self?.interaction.grant()
        }
    }
    
    func animateIn() {
        self.layer.animatePosition(from: CGPoint(x: self.layer.position.x, y: self.layer.position.y + self.layer.bounds.size.height), to: self.layer.position, duration: 0.5, timingFunction: kCAMediaTimingFunctionSpring)
    }
    
    func animateOut(completion: (() -> Void)? = nil) {
        self.view.endEditing(true)
        self.layer.animatePosition(from: self.layer.position, to: CGPoint(x: self.layer.position.x, y: self.layer.position.y + self.layer.bounds.size.height), duration: 0.2, timingFunction: kCAMediaTimingFunctionEaseInEaseOut, removeOnCompletion: false, completion: { _ in
            completion?()
        })
    }
    
    func containerLayoutUpdated(_ layout: ContainerViewLayout, navigationBarHeight: CGFloat, transition: ContainedViewLayoutTransition) {
        self.validLayout = (layout, navigationBarHeight)
        
        var insets = layout.insets(options: [.input])
        insets.bottom = max(insets.bottom, layout.safeInsets.bottom)
        
        let headerNodeTransition: ContainedViewLayoutTransition = headerNode.bounds.isEmpty ? .immediate : transition
        let headerHeight: CGFloat
        if self.headerNode.alpha.isZero {
            headerHeight = 0.0
        } else {
            headerHeight = self.headerNode.updateLayout(width: layout.size.width, transition: headerNodeTransition)
        }
        
        let acceptHeight = self.acceptNode.updateLayout(width: layout.size.width, bottomInset: layout.intrinsicInsets.bottom, transition: transition)
        
        var footerHeight: CGFloat = 0.0
        var contentSpacing: CGFloat
        transition.updateFrame(node: self.acceptNode, frame: CGRect(origin: CGPoint(x: 0.0, y: layout.size.height - acceptHeight), size: CGSize(width: layout.size.width, height: acceptHeight)))
        if self.acceptNode.supernode != nil {
            footerHeight += acceptHeight
            contentSpacing = 25.0
        } else {
            if self.contentNode is SecureIdAuthListContentNode {
                contentSpacing = 16.0
            } else if self.contentNode is SecureIdAuthPasswordSetupContentNode {
                contentSpacing = 24.0
            } else {
                contentSpacing = 56.0
            }
        }
        
        insets.bottom += footerHeight
        
        let wrappingContentRect = CGRect(origin: CGPoint(x: 0.0, y: navigationBarHeight), size: CGSize(width: layout.size.width, height: layout.size.height - insets.bottom - navigationBarHeight))
        let contentRect = CGRect(origin: CGPoint(), size: wrappingContentRect.size)
        let overscrollY = self.scrollNode.view.bounds.minY
        transition.updateFrame(node: self.scrollNode, frame: wrappingContentRect)
        
        if let contentNode = self.contentNode {
            let contentFirstTime = contentNode.bounds.isEmpty
            let contentNodeTransition: ContainedViewLayoutTransition = contentFirstTime ? .immediate : transition
            let contentLayout = contentNode.updateLayout(width: layout.size.width, transition: contentNodeTransition)
            
            let boundingHeight = headerHeight + contentLayout.height + contentSpacing
            
            var boundingRect = CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: CGSize(width: layout.size.width, height: boundingHeight))
            if contentNode is SecureIdAuthListContentNode {
                boundingRect.origin.y = contentRect.minY
            } else {
                boundingRect.origin.y = contentRect.minY + floor((contentRect.height - boundingHeight) / 2.0)
            }
            boundingRect.origin.y = max(boundingRect.origin.y, 14.0)
            
            if self.headerNode.alpha.isZero {
                headerNodeTransition.updateFrame(node: self.headerNode, frame: CGRect(origin: CGPoint(x: -boundingRect.width, y: self.headerNode.frame.minY), size: CGSize(width: boundingRect.width, height: headerHeight)))
            } else {
                headerNodeTransition.updateFrame(node: self.headerNode, frame: CGRect(origin: CGPoint(x: 0.0, y: boundingRect.minY), size: CGSize(width: boundingRect.width, height: headerHeight)))
            }
            
            contentNodeTransition.updateFrame(node: contentNode, frame: CGRect(origin: CGPoint(x: 0.0, y: boundingRect.minY + headerHeight + contentSpacing), size: CGSize(width: boundingRect.width, height: contentLayout.height)))
            
            if contentFirstTime {
                contentNode.didAppear()
                if transition.isAnimated {
                    contentNode.animateIn()
                    if !(contentNode is SecureIdAuthPasswordOptionContentNode || contentNode is SecureIdAuthPasswordSetupContentNode) {
                        transition.animatePositionAdditive(node: contentNode, offset: CGPoint(x: layout.size.width, y: 0.0))
                    }
                }
            }
            
            self.scrollNode.view.contentSize = CGSize(width: boundingRect.width, height: 14.0 + boundingRect.height + 16.0)
        }
        
        if let dismissedContentNode = self.dismissedContentNode {
            self.dismissedContentNode = nil
            transition.updatePosition(node: dismissedContentNode, position: CGPoint(x: -layout.size.width / 2.0, y: dismissedContentNode.position.y), completion: { [weak dismissedContentNode] _ in
                dismissedContentNode?.removeFromSupernode()
            })
        }
    }
    
    func transitionToContentNode(_ contentNode: (ASDisplayNode & SecureIdAuthContentNode)?, transition: ContainedViewLayoutTransition) {
        if let current = self.contentNode {
            current.willDisappear()
            if let dismissedContentNode = self.dismissedContentNode, dismissedContentNode !== current {
                dismissedContentNode.removeFromSupernode()
            }
            self.dismissedContentNode = current
        }
        
        self.contentNode = contentNode
        
        if let contentNode = self.contentNode {
            self.scrollNode.addSubnode(contentNode)
            if let _ = self.validLayout {
                self.scheduleLayoutTransitionRequest(.animated(duration: 0.5, curve: .spring))
            }
        }
    }
    
    func updateState(_ state: SecureIdAuthControllerState, transition: ContainedViewLayoutTransition) {
        self.state = state
        
        switch state {
            case let .form(form):
                if let encryptedFormData = form.encryptedFormData, let verificationState = form.verificationState {
                    if self.headerNode.supernode == nil {
                        self.scrollNode.addSubnode(self.headerNode)
                        self.headerNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.3)
                    }
                    self.headerNode.updateState(formData: encryptedFormData, verificationState: verificationState)
                    
                    var contentNode: (ASDisplayNode & SecureIdAuthContentNode)?
                    
                    switch verificationState {
                        case .noChallenge:
                            if let _ = self.contentNode as? SecureIdAuthPasswordSetupContentNode {
                            } else {
                                let current = SecureIdAuthPasswordSetupContentNode(theme: self.presentationData.theme, strings: self.presentationData.strings, setupPassword: { [weak self] in
                                    self?.interaction.setupPassword()
                                })
                                contentNode = current
                            }
                        case let .passwordChallenge(hint, challengeState):
                            if let current = self.contentNode as? SecureIdAuthPasswordOptionContentNode {
                                current.updateIsChecking(challengeState == .checking)
                                contentNode = current
                            } else {
                                let current = SecureIdAuthPasswordOptionContentNode(theme: presentationData.theme, strings: presentationData.strings, hint: hint, checkPassword: { [weak self] password in
                                    if let strongSelf = self {
                                        strongSelf.interaction.checkPassword(password)
                                    }
                                }, passwordHelp: { [weak self] in
                                    if let strongSelf = self {
                                        
                                    }
                                })
                                current.updateIsChecking(challengeState == .checking)
                                contentNode = current
                            }
                        case .verified:
                            if let encryptedFormData = form.encryptedFormData, let formData = form.formData {
                                if let current = self.contentNode as? SecureIdAuthFormContentNode {
                                    current.updateValues(formData.values)
                                    contentNode = current
                                } else {
                                    let current = SecureIdAuthFormContentNode(theme: self.presentationData.theme, strings: self.presentationData.strings, peer: encryptedFormData.servicePeer, privacyPolicyUrl: encryptedFormData.form.termsUrl, form: formData, openField: { [weak self] field in
                                        if let strongSelf = self {
                                            switch field {
                                                case .identity, .address:
                                                    strongSelf.presentDocumentSelection(field: field)
                                                case .phone:
                                                    strongSelf.presentPlaintextSelection(type: .phone)
                                                case .email:
                                                    strongSelf.presentPlaintextSelection(type: .email)
                                            }
                                        }
                                    }, openURL: { [weak self] url in
                                        self?.interaction.openUrl(url)
                                    }, openMention: { [weak self] mention in
                                        self?.interaction.openMention(mention)
                                    })
                                    contentNode = current
                                }
                            }
                    }
                    
                    if case .verified = verificationState {
                        if self.acceptNode.supernode == nil {
                            self.addSubnode(self.acceptNode)
                            self.acceptNode.layer.animatePosition(from: CGPoint(x: 0.0, y: self.acceptNode.bounds.height), to: CGPoint(), duration: 0.3, timingFunction: kCAMediaTimingFunctionSpring, additive: true)
                        }
                    }
                    
                    if self.contentNode !== contentNode {
                        self.transitionToContentNode(contentNode, transition: transition)
                    }
                }
            case let .list(list):
                if let _ = list.encryptedValues, let verificationState = list.verificationState {
                    if case .verified = verificationState {
                        if !self.headerNode.alpha.isZero {
                            self.headerNode.alpha = 0.0
                            self.headerNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.3)
                        }
                    } else {
                        if self.headerNode.supernode == nil {
                            self.scrollNode.addSubnode(self.headerNode)
                            self.headerNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.3)
                        }
                        self.headerNode.updateState(formData: nil, verificationState: verificationState)
                    }
                    
                    var contentNode: (ASDisplayNode & SecureIdAuthContentNode)?
                    
                    switch verificationState {
                        case let .passwordChallenge(hint, challengeState):
                            if let current = self.contentNode as? SecureIdAuthPasswordOptionContentNode {
                                current.updateIsChecking(challengeState == .checking)
                                contentNode = current
                            } else {
                                let current = SecureIdAuthPasswordOptionContentNode(theme: presentationData.theme, strings: presentationData.strings, hint: hint, checkPassword: { [weak self] password in
                                    if let strongSelf = self {
                                        strongSelf.interaction.checkPassword(password)
                                    }
                                    }, passwordHelp: { [weak self] in
                                        if let strongSelf = self {
                                            
                                        }
                                })
                                current.updateIsChecking(challengeState == .checking)
                                contentNode = current
                            }
                        case .noChallenge:
                            contentNode = nil
                        case .verified:
                            if let _ = list.encryptedValues, let values = list.values {
                                if let current = self.contentNode as? SecureIdAuthListContentNode {
                                    current.updateValues(values)
                                    contentNode = current
                                } else {
                                    let current = SecureIdAuthListContentNode(theme: self.presentationData.theme, strings: self.presentationData.strings, openField: { [weak self] field in
                                        self?.openListField(field)
                                    }, deleteAll: { [weak self] in
                                        self?.deleteAllValues()
                                    })
                                    current.updateValues(values)
                                    contentNode = current
                                }
                            }
                    }
                    
                    if self.contentNode !== contentNode {
                        self.transitionToContentNode(contentNode, transition: transition)
                    }
                }
        }
    }
    
    private func scheduleLayoutTransitionRequest(_ transition: ContainedViewLayoutTransition) {
        let requestId = self.scheduledLayoutTransitionRequestId
        self.scheduledLayoutTransitionRequestId += 1
        self.scheduledLayoutTransitionRequest = (requestId, transition)
        (self.view as? UITracingLayerView)?.schedule(layout: { [weak self] in
            if let strongSelf = self {
                if let (currentRequestId, currentRequestTransition) = strongSelf.scheduledLayoutTransitionRequest, currentRequestId == requestId {
                    strongSelf.scheduledLayoutTransitionRequest = nil
                    strongSelf.requestLayout(currentRequestTransition)
                }
            }
        })
        self.setNeedsLayout()
    }
    
    private func presentDocumentSelection(field: SecureIdParsedRequestedFormField) {
        guard let state = self.state, case let .form(form) = state, let verificationState = form.verificationState, case let .verified(context) = verificationState, let encryptedFormData = form.encryptedFormData, let formData = form.formData else {
            return
        }
        let updatedValues: ([SecureIdValueKey], [SecureIdValueWithContext]) -> Void = { [weak self] touchedKeys, updatedValues in
            guard let strongSelf = self else {
                return
            }
            strongSelf.interaction.updateState { state in
                guard let formData = form.formData, case let .form(form) = state else {
                    return state
                }
                var values = formData.values.filter { value in
                    return !touchedKeys.contains(value.value.key)
                }
                values.append(contentsOf: updatedValues)
            return .form(SecureIdAuthControllerFormState(encryptedFormData: form.encryptedFormData, formData: SecureIdForm(peerId: formData.peerId, requestedFields: formData.requestedFields, values: values), verificationState: form.verificationState))
            }
        }
        
        switch field {
            case let .identity(personalDetails, document, selfie, translations):
                if let document = document {
                    var hasValueType: SecureIdRequestedIdentityDocument?
                    switch document {
                        case let .just(type):
                            if let value = findValue(formData.values, key: type.valueKey)?.1 {
                                switch value {
                                    case .passport:
                                        hasValueType = .passport
                                    case .internalPassport:
                                        hasValueType = .internalPassport
                                    case .idCard:
                                        hasValueType = .idCard
                                    case .driversLicense:
                                        hasValueType = .driversLicense
                                    default:
                                        break
                                }
                            }
                        case let .oneOf(types):
                            for type in types {
                                if let value = findValue(formData.values, key: type.valueKey)?.1 {
                                    switch value {
                                        case .passport:
                                            hasValueType = .passport
                                        case .internalPassport:
                                            hasValueType = .internalPassport
                                        case .idCard:
                                            hasValueType = .idCard
                                        case .driversLicense:
                                            hasValueType = .driversLicense
                                        default:
                                            break
                                    }
                                }
                            }
                    }
                    if let hasValueType = hasValueType {
                        self.interaction.present(SecureIdDocumentFormController(account: self.account, context: context, requestedData: .identity(details: personalDetails, document: hasValueType, selfie: selfie, translations: translations), primaryLanguageByCountry: encryptedFormData.primaryLanguageByCountry, values: formData.values, updatedValues: { values in
                            var keys: [SecureIdValueKey] = []
                            if personalDetails != nil {
                                keys.append(.personalDetails)
                            }
                            keys.append(hasValueType.valueKey)
                            updatedValues(keys, values)
                        }), nil)
                        return
                    }
                } else if personalDetails != nil {
                    self.interaction.present(SecureIdDocumentFormController(account: self.account, context: context, requestedData: .identity(details: personalDetails, document: nil, selfie: selfie, translations: translations), primaryLanguageByCountry: encryptedFormData.primaryLanguageByCountry, values: formData.values, updatedValues: { values in
                        updatedValues([.personalDetails], values)
                    }), nil)
                    return
                }
            case let .address(addressDetails, document, translation):
                if let document = document {
                    var hasValueType: SecureIdRequestedAddressDocument?
                    switch document {
                        case let .just(type):
                            if let value = findValue(formData.values, key: type.valueKey)?.1 {
                                switch value {
                                    case .rentalAgreement:
                                        hasValueType = .rentalAgreement
                                    case .bankStatement:
                                        hasValueType = .bankStatement
                                    case .passportRegistration:
                                        hasValueType = .passportRegistration
                                    case .temporaryRegistration:
                                        hasValueType = .temporaryRegistration
                                    case .utilityBill:
                                        hasValueType = .utilityBill
                                    
                                    default:
                                        break
                                }
                            }
                        case let .oneOf(types):
                            for type in types {
                                if let value = findValue(formData.values, key: type.valueKey)?.1 {
                                    switch value {
                                        case .rentalAgreement:
                                            hasValueType = .rentalAgreement
                                        case .bankStatement:
                                            hasValueType = .bankStatement
                                        case .passportRegistration:
                                            hasValueType = .passportRegistration
                                        case .temporaryRegistration:
                                            hasValueType = .temporaryRegistration
                                        case .utilityBill:
                                            hasValueType = .utilityBill
                                        
                                        default:
                                            break
                                    }
                                }
                        }
                    }
                    if let hasValueType = hasValueType {
                        self.interaction.present(SecureIdDocumentFormController(account: self.account, context: context, requestedData: .address(details: addressDetails, document: hasValueType, translations: translation), primaryLanguageByCountry: encryptedFormData.primaryLanguageByCountry, values: formData.values, updatedValues: { values in
                            var keys: [SecureIdValueKey] = []
                            if addressDetails {
                                keys.append(.address)
                            }
                            keys.append(hasValueType.valueKey)
                            updatedValues(keys, values)
                        }), nil)
                        return
                    }
                } else if addressDetails {
                    self.interaction.present(SecureIdDocumentFormController(account: self.account, context: context, requestedData: .address(details: addressDetails, document: nil, translations: false), primaryLanguageByCountry: encryptedFormData.primaryLanguageByCountry, values: formData.values, updatedValues: { values in
                        updatedValues([.personalDetails], values)
                    }), nil)
                    return
                }
            default:
                break
        }
        
        let controller = SecureIdDocumentTypeSelectionController(theme: self.presentationData.theme, strings: self.presentationData.strings, field: field, currentValues: formData.values, completion: { [weak self] requestedData in
            guard let strongSelf = self, let state = strongSelf.state, let verificationState = state.verificationState, case let .verified(context) = verificationState, let formData = form.formData else {
                return
            }

            strongSelf.interaction.present(SecureIdDocumentFormController(account: strongSelf.account, context: context, requestedData: requestedData, primaryLanguageByCountry: encryptedFormData.primaryLanguageByCountry, values: formData.values, updatedValues: { values in
                var keys: [SecureIdValueKey] = []
                switch requestedData {
                    case let .identity(details, document, _, _):
                        if details != nil {
                            keys.append(.personalDetails)
                        }
                        if let document = document {
                            keys.append(document.valueKey)
                        }
                    case let .address(details, document, _):
                        if details {
                            keys.append(.address)
                        }
                        if let document = document {
                            keys.append(document.valueKey)
                        }
                }
                updatedValues(keys, values)
            }), nil)
        })
        self.interaction.present(controller, nil)
    }
    
    private func presentPlaintextSelection(type: SecureIdPlaintextFormType) {
        guard let state = self.state, case let .form(form) = state, let verificationState = form.verificationState, case let .verified(context) = verificationState else {
            return
        }
        
        var immediatelyAvailableValue: SecureIdValue?
        switch type {
            case .phone:
                if let peer = form.encryptedFormData?.accountPeer as? TelegramUser, let phone = peer.phone, !phone.isEmpty {
                    immediatelyAvailableValue = .phone(SecureIdPhoneValue(phone: phone))
                }
            default:
                break
        }
        self.interaction.present(SecureIdPlaintextFormController(account: self.account, context: context, type: type, immediatelyAvailableValue: immediatelyAvailableValue, updatedValue: { [weak self] valueWithContext in
            if let strongSelf = self {
                strongSelf.interaction.updateState { state in
                    if case let .form(form) = state, let formData = form.formData {
                        var values = formData.values
                        switch type {
                            case .phone:
                                while let index = findValue(values, key: .phone)?.0 {
                                    values.remove(at: index)
                                }
                            case .email:
                                while let index = findValue(values, key: .email)?.0 {
                                    values.remove(at: index)
                                }
                        }
                        if let valueWithContext = valueWithContext {
                            values.append(valueWithContext)
                        }
                        return .form(SecureIdAuthControllerFormState(encryptedFormData: form.encryptedFormData, formData: SecureIdForm(peerId: formData.peerId, requestedFields: formData.requestedFields, values: values), verificationState: form.verificationState))
                    }
                    return state
                }
            }
        }), nil)
    }
    
    private func openListField(_ field: SecureIdAuthListContentField) {
        guard let state = self.state, case let .list(list) = state, let verificationState = list.verificationState, case let .verified(context) = verificationState else {
            return
        }
        guard let values = list.values else {
            return
        }
        
        let updatedValues: (SecureIdValueKey) -> ([SecureIdValueWithContext]) -> Void = { valueKey in
            return { [weak self] updatedValues in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.interaction.updateState { state in
                    guard case var .list(list) = state, var values = list.values else {
                        return state
                    }
                    
                    values = values.filter({ value in
                        return value.value.key != valueKey
                    })
                    
                    values.append(contentsOf: updatedValues)
                    
                    list.values = values
                    return .list(list)
                }
            }
        }
        
        let openAction: (SecureIdValueKey) -> Void = { [weak self] field in
            guard let strongSelf = self, let state = strongSelf.state, case let .list(list) = state else {
                return
            }
            let primaryLanguageByCountry = list.primaryLanguageByCountry ?? [:]
            switch field {
                case .personalDetails:
                    strongSelf.interaction.present(SecureIdDocumentFormController(account: strongSelf.account, context: context, requestedData: .identity(details: ParsedRequestedPersonalDetails(nativeNames: true), document: nil, selfie: false, translations: false), primaryLanguageByCountry: primaryLanguageByCountry, values: values, updatedValues: updatedValues(field)), nil)
                case .passport:
                    strongSelf.interaction.present(SecureIdDocumentFormController(account: strongSelf.account, context: context, requestedData: .identity(details: nil, document: .passport, selfie: true, translations: true), primaryLanguageByCountry: primaryLanguageByCountry, values: values, updatedValues: updatedValues(field)), nil)
                case .internalPassport:
                    strongSelf.interaction.present(SecureIdDocumentFormController(account: strongSelf.account, context: context, requestedData: .identity(details: nil, document: .internalPassport, selfie: true, translations: true), primaryLanguageByCountry: primaryLanguageByCountry, values: values, updatedValues: updatedValues(field)), nil)
                case .driversLicense:
                    strongSelf.interaction.present(SecureIdDocumentFormController(account: strongSelf.account, context: context, requestedData: .identity(details: nil, document: .driversLicense, selfie: true, translations: true), primaryLanguageByCountry: primaryLanguageByCountry, values: values, updatedValues: updatedValues(field)), nil)
                case .idCard:
                    strongSelf.interaction.present(SecureIdDocumentFormController(account: strongSelf.account, context: context, requestedData: .identity(details: nil, document: .idCard, selfie: true, translations: true), primaryLanguageByCountry: primaryLanguageByCountry, values: values, updatedValues: updatedValues(field)), nil)
                case .passportRegistration:
                    strongSelf.interaction.present(SecureIdDocumentFormController(account: strongSelf.account, context: context, requestedData: .address(details: false, document: .passportRegistration, translations: true), primaryLanguageByCountry: primaryLanguageByCountry, values: values, updatedValues: updatedValues(field)), nil)
                case .temporaryRegistration:
                    strongSelf.interaction.present(SecureIdDocumentFormController(account: strongSelf.account, context: context, requestedData: .address(details: false, document: .temporaryRegistration, translations: true), primaryLanguageByCountry: primaryLanguageByCountry, values: values, updatedValues: updatedValues(field)), nil)
                case .address:
                    strongSelf.interaction.present(SecureIdDocumentFormController(account: strongSelf.account, context: context, requestedData: .address(details: true, document: nil, translations: true), primaryLanguageByCountry: primaryLanguageByCountry, values: values, updatedValues: updatedValues(field)), nil)
                case .utilityBill:
                    strongSelf.interaction.present(SecureIdDocumentFormController(account: strongSelf.account, context: context, requestedData: .address(details: false, document: .utilityBill, translations: true), primaryLanguageByCountry: primaryLanguageByCountry, values: values, updatedValues: updatedValues(field)), nil)
                case .bankStatement:
                    strongSelf.interaction.present(SecureIdDocumentFormController(account: strongSelf.account, context: context, requestedData: .address(details: false, document: .bankStatement, translations: true), primaryLanguageByCountry: primaryLanguageByCountry, values: values, updatedValues: updatedValues(field)), nil)
                case .rentalAgreement:
                    strongSelf.interaction.present(SecureIdDocumentFormController(account: strongSelf.account, context: context, requestedData: .address(details: false, document: .rentalAgreement, translations: true), primaryLanguageByCountry: primaryLanguageByCountry, values: values, updatedValues: updatedValues(field)), nil)
                case .phone:
                    break
                case .email:
                    break
            }
        }
        
        switch field {
            case .identity, .address:
                let keys: [(SecureIdValueKey, String, String)]
                let strings = self.presentationData.strings
                if case .identity = field {
                    keys = [
                        (.personalDetails, strings.Passport_Identity_AddPersonalDetails, strings.Passport_Identity_EditPersonalDetails),
                        (.passport, strings.Passport_Identity_AddPassport, strings.Passport_Identity_EditPassport),
                        (.idCard, strings.Passport_Identity_AddIdentityCard, strings.Passport_Identity_EditIdentityCard),
                        (.driversLicense, strings.Passport_Identity_AddDriversLicense, strings.Passport_Identity_EditDriversLicense),
                        (.internalPassport, strings.Passport_Identity_AddInternalPassport, strings.Passport_Identity_EditInternalPassport),
                    ]
                } else {
                    keys = [
                        (.address, strings.Passport_Address_AddResidentialAddress, strings.Passport_Address_EditResidentialAddress), (.utilityBill, strings.Passport_Address_AddUtilityBill, strings.Passport_Address_EditUtilityBill),
                        (.bankStatement, strings.Passport_Address_AddBankStatement, strings.Passport_Address_EditBankStatement),
                        (.rentalAgreement, strings.Passport_Address_AddRentalAgreement, strings.Passport_Address_EditRentalAgreement),
                        (.passportRegistration, strings.Passport_Address_AddPassportRegistration, strings.Passport_Address_EditPassportRegistration),
                        (.temporaryRegistration, strings.Passport_Address_AddTemporaryRegistration, strings.Passport_Address_EditTemporaryRegistration)
                    ]
                }
                
                let controller = ActionSheetController(presentationTheme: self.presentationData.theme)
                let dismissAction: () -> Void = { [weak controller] in
                    controller?.dismissAnimated()
                }
                var items: [ActionSheetItem] = []
                for (key, add, edit) in keys {
                    items.append(ActionSheetButtonItem(title: findValue(values, key: key) != nil ? edit : add, action: {
                        dismissAction()
                        openAction(key)
                    }))
                }
                controller.setItemGroups([
                    ActionSheetItemGroup(items: items),
                    ActionSheetItemGroup(items: [ActionSheetButtonItem(title: self.presentationData.strings.Common_Cancel, action: { dismissAction() })])
                ])
                self.view.endEditing(true)
                self.interaction.present(controller, nil)
            case .phone:
                var immediatelyAvailableValue: SecureIdValue?
                self.interaction.present(SecureIdPlaintextFormController(account: self.account, context: context, type: .phone, immediatelyAvailableValue: immediatelyAvailableValue, updatedValue: { value in
                    updatedValues(.phone)(value.flatMap({ [$0] }) ?? [])
                }), nil)
            case .email:
                self.interaction.present(SecureIdPlaintextFormController(account: self.account, context: context, type: .email, immediatelyAvailableValue: nil, updatedValue: { value in
                    updatedValues(.email)(value.flatMap({ [$0] }) ?? [])
                }), nil)
        }
    }
    
    private func deleteAllValues() {
        let controller = ActionSheetController(presentationTheme: self.presentationData.theme)
        let dismissAction: () -> Void = { [weak controller] in
            controller?.dismissAnimated()
        }
        let items: [ActionSheetItem] = [
            ActionSheetTextItem(title: self.presentationData.strings.Passport_DeletePassportConfirmation),
            ActionSheetButtonItem(title: self.presentationData.strings.Common_Delete, color: .destructive, enabled: true, action: { [weak self] in
                dismissAction()
                self?.interaction.deleteAll()
            })
        ]
        controller.setItemGroups([
            ActionSheetItemGroup(items: items),
            ActionSheetItemGroup(items: [ActionSheetButtonItem(title: self.presentationData.strings.Common_Cancel, action: { dismissAction() })])
            ])
        self.view.endEditing(true)
        self.interaction.present(controller, nil)
    }
}
