import Foundation
import AsyncDisplayKit
import Display
import TelegramCore
import Postbox
import SwiftSignalKit
import CoreTelephony

private func cleanPhoneNumber(_ text: String?) -> String {
    var cleanNumber = ""
    if let text = text {
        for c in text {
            if c >= "0" && c <= "9" {
                cleanNumber += String(c)
            }
        }
    }
    return cleanNumber
}

final class SecureIdPlaintextFormParams {
    fileprivate let openCountrySelection: () -> Void
    fileprivate let updateTextField: (SecureIdPlaintextFormTextField, String) -> Void
    fileprivate let usePhone: (String) -> Void
    
    fileprivate init(openCountrySelection: @escaping () -> Void, updateTextField: @escaping (SecureIdPlaintextFormTextField, String) -> Void, usePhone: @escaping (String) -> Void) {
        self.openCountrySelection = openCountrySelection
        self.updateTextField = updateTextField
        self.usePhone = usePhone
    }
}

private struct PhoneInputState {
    var countryCode: String
    var number: String
    var countryId: String
    
    func isEqual(to: PhoneInputState) -> Bool {
        if self.countryCode != to.countryCode {
            return false
        }
        if self.number != to.number {
            return false
        }
        if self.countryId != to.countryId {
            return false
        }
        return true
    }
}

private struct PhoneVerifyState {
    let phone: String
    let payload: SecureIdPreparePhoneVerificationPayload
    var code: String
    
    func isEqual(to: PhoneVerifyState) -> Bool {
        if self.code != to.code {
            return false
        }
        return true
    }
}

private enum SecureIdPlaintextFormPhoneState {
    case input(PhoneInputState)
    case verify(PhoneVerifyState)
    
    func isEqual(to: SecureIdPlaintextFormPhoneState) -> Bool {
        switch self {
            case let .input(lhsInput):
                if case let .input(rhsInput) = to, lhsInput.isEqual(to: rhsInput) {
                    return true
                } else {
                    return false
                }
            case let .verify(lhsInput):
                if case let .verify(rhsInput) = to, lhsInput.isEqual(to: rhsInput) {
                    return true
                } else {
                    return false
                }
        }
    }
    
    func isComplete() -> Bool {
        switch self {
            case let .input(input):
                if input.countryCode.isEmpty {
                    return false
                }
                if input.number.isEmpty {
                    return false
                }
                return true
            case let .verify(verify):
                if verify.code.isEmpty {
                    return false
                }
                return true
        }
    }
}

private struct EmailInputState {
    var email: String
    
    func isEqual(to: EmailInputState) -> Bool {
        if self.email != to.email {
            return false
        }
        return true
    }
}

private struct EmailVerifyState {
    let email: String
    let payload: SecureIdPrepareEmailVerificationPayload
    var code: String
    
    func isEqual(to: EmailVerifyState) -> Bool {
        if self.code != to.code {
            return false
        }
        return true
    }
}

private enum SecureIdPlaintextFormEmailState {
    case input(EmailInputState)
    case verify(EmailVerifyState)
    
    func isEqual(to: SecureIdPlaintextFormEmailState) -> Bool {
        switch self {
            case let .input(lhsInput):
                if case let .input(rhsInput) = to, lhsInput.isEqual(to: rhsInput) {
                    return true
                } else {
                    return false
                }
            case let .verify(lhsInput):
                if case let .verify(rhsInput) = to, lhsInput.isEqual(to: rhsInput) {
                    return true
                } else {
                    return false
                }
        }
    }
    
    func isComplete() -> Bool {
        switch self {
            case let .input(input):
                if input.email.isEmpty {
                    return false
                }
                return true
            case let .verify(verify):
                if verify.code.isEmpty {
                    return false
                }
                return true
        }
    }
}

private enum SecureIdPlaintextFormTextField {
    case countryCode
    case number
    case code
    case email
}

private enum SecureIdPlaintextFormDataState {
    case phone(SecureIdPlaintextFormPhoneState)
    case email(SecureIdPlaintextFormEmailState)
    
    mutating func updateTextField(type: SecureIdPlaintextFormTextField, value: String) {
        switch self {
            case let .phone(phone):
                switch phone {
                    case var .input(input):
                        switch type {
                            case .countryCode:
                                input.countryCode = value
                            case .number:
                                input.number = value
                            default:
                                break
                        }
                        self = .phone(.input(input))
                    case var .verify(verify):
                        switch type {
                            case .code:
                                verify.code = value
                            default:
                                break
                        }
                        self = .phone(.verify(verify))
                }
            case let .email(email):
                switch email {
                    case var .input(input):
                        switch type {
                            case .email:
                                input.email = value
                            default:
                                break
                        }
                        self = .email(.input(input))
                    case var .verify(verify):
                        switch type {
                            case .code:
                                verify.code = value
                            default:
                                break
                        }
                        self = .email(.verify(verify))
                }
        }
    }
    
    func isEqual(to: SecureIdPlaintextFormDataState) -> Bool {
        switch self {
            case let .phone(lhsValue):
                if case let .phone(rhsValue) = to, lhsValue.isEqual(to: rhsValue) {
                    return true
                } else {
                    return false
                }
            case let .email(lhsValue):
                if case let .email(rhsValue) = to, lhsValue.isEqual(to: rhsValue) {
                    return true
                } else {
                    return false
                }
        }
    }
}

private enum SecureIdPlaintextFormActionState {
    case none
    case saving
    case deleting
}

enum SecureIdPlaintextFormInputState {
    case nextAvailable
    case nextNotAvailable
    case saveAvailable
    case saveNotAvailable
    case inProgress
}

struct SecureIdPlaintextFormInnerState: FormControllerInnerState {
    fileprivate let previousValue: SecureIdValue?
    fileprivate var data: SecureIdPlaintextFormDataState
    fileprivate var actionState: SecureIdPlaintextFormActionState
    
    func isEqual(to: SecureIdPlaintextFormInnerState) -> Bool {
        if !self.data.isEqual(to: to.data) {
            return false
        }
        if self.actionState != to.actionState {
            return false
        }
        return true
    }
    
    func entries() -> [FormControllerItemEntry<SecureIdPlaintextFormEntry>] {
        switch self.data {
        case let .phone(phone):
            var result: [FormControllerItemEntry<SecureIdPlaintextFormEntry>] = []
            switch phone {
                case let .input(input):
                    result.append(.spacer)
                    
                    if let value = self.previousValue, case let .phone(phone) = value {
                        result.append(.entry(SecureIdPlaintextFormEntry.immediatelyAvailablePhone(phone.phone)))
                        result.append(.entry(SecureIdPlaintextFormEntry.immediatelyAvailablePhoneInfo))
                        result.append(.spacer)
                    }
                    
                    result.append(.entry(SecureIdPlaintextFormEntry.numberInput(countryCode: input.countryCode, number: input.number)))
                    result.append(.entry(SecureIdPlaintextFormEntry.numberInputInfo))
                case let .verify(verify):
                    result.append(.spacer)
                    result.append(.entry(SecureIdPlaintextFormEntry.numberCode(verify.code)))
                    result.append(.entry(SecureIdPlaintextFormEntry.numberVerifyInfo))
            }
            return result
        case let .email(email):
            var result: [FormControllerItemEntry<SecureIdPlaintextFormEntry>] = []
            switch email {
                case let .input(input):
                    result.append(.spacer)
                    result.append(.entry(SecureIdPlaintextFormEntry.emailAddress(input.email)))
                    result.append(.entry(SecureIdPlaintextFormEntry.numberInputInfo))
                case let .verify(verify):
                    result.append(.spacer)
                    result.append(.entry(SecureIdPlaintextFormEntry.numberCode(verify.code)))
                    result.append(.entry(SecureIdPlaintextFormEntry.emailVerifyInfo))
            }
            return result
        }
    }
    
    func actionInputState() -> SecureIdPlaintextFormInputState {
        switch self.actionState {
            case .deleting, .saving:
                return .inProgress
            default:
                break
        }
        
        switch self.data {
            case let .phone(phone):
                switch phone {
                    case .input:
                        if !phone.isComplete() {
                            return .nextNotAvailable
                        } else {
                            return .nextAvailable
                        }
                    case .verify:
                        if !phone.isComplete() {
                            return .saveNotAvailable
                        } else {
                            return .saveAvailable
                        }
                }
            case let .email(email):
                switch email {
                    case .input:
                        if !email.isComplete() {
                            return .nextNotAvailable
                        } else {
                            return .nextAvailable
                        }
                    case .verify:
                        if !email.isComplete() {
                            return .saveNotAvailable
                        } else {
                            return .saveAvailable
                        }
            }
        }
    }
}

extension SecureIdPlaintextFormInnerState {
    init(type: SecureIdPlaintextFormType, immediatelyAvailableValue: SecureIdValue?) {
        switch type {
            case .phone:
                var countryId: String? = nil
                let networkInfo = CTTelephonyNetworkInfo()
                if let carrier = networkInfo.subscriberCellularProvider {
                    countryId = carrier.isoCountryCode
                }
                
                if countryId == nil {
                    countryId = (Locale.current as NSLocale).object(forKey: .countryCode) as? String
                }
                
                var countryCodeAndId: (Int32, String) = (1, "US")
                
                if let countryId = countryId {
                    let normalizedId = countryId.uppercased()
                    for (code, idAndName) in countryCodeToIdAndName {
                        if idAndName.0 == normalizedId {
                            countryCodeAndId = (Int32(code), idAndName.0.uppercased())
                            break
                        }
                    }
                }
                
                self.init(previousValue: immediatelyAvailableValue, data: .phone(.input(PhoneInputState(countryCode: "+\(countryCodeAndId.0)", number: "", countryId: countryCodeAndId.1))), actionState: .none)
            case .email:
                self.init(previousValue: immediatelyAvailableValue, data: .email(.input(EmailInputState(email: ""))), actionState: .none)
        }
    }
}

enum SecureIdPlaintextFormEntryId: Hashable {
    case immediatelyAvailablePhone
    case immediatelyAvailablePhoneInfo
    case numberInput
    case numberInputInfo
    case numberCode
    case numberVerifyInfo
    case emailVerifyInfo
    case emailAddress
    case emailCode
}

enum SecureIdPlaintextFormEntry: FormControllerEntry {
    case immediatelyAvailablePhone(String)
    case immediatelyAvailablePhoneInfo
    
    case numberInput(countryCode: String, number: String)
    case numberInputInfo
    case numberCode(String)
    case numberVerifyInfo
    case emailAddress(String)
    case emailCode(String)
    case emailVerifyInfo
    
    var stableId: SecureIdPlaintextFormEntryId {
        switch self {
            case .immediatelyAvailablePhone:
                return .immediatelyAvailablePhone
            case .immediatelyAvailablePhoneInfo:
                return .immediatelyAvailablePhoneInfo
            case .numberInput:
                return .numberInput
            case .numberInputInfo:
                return .numberInputInfo
            case .numberCode:
                return .numberCode
            case .numberVerifyInfo:
                return .numberVerifyInfo
            case .emailAddress:
                return .emailAddress
            case .emailCode:
                return .emailCode
            case .emailVerifyInfo:
                return .emailVerifyInfo
        }
    }
    
    func isEqual(to: SecureIdPlaintextFormEntry) -> Bool {
        switch self {
            case let .immediatelyAvailablePhone(value):
                if case .immediatelyAvailablePhone(value) = to {
                    return true
                } else {
                    return false
                }
            case .immediatelyAvailablePhoneInfo:
                if case .immediatelyAvailablePhoneInfo = to {
                    return true
                } else {
                    return false
                }
            case let .numberInput(countryCode, number):
                if case .numberInput(countryCode, number) = to {
                    return true
                } else {
                    return false
                }
            case .numberInputInfo:
                if case .numberInputInfo = to {
                    return true
                } else {
                    return false
                }
            case let .numberCode(code):
                if case .numberCode(code) = to {
                    return true
                } else {
                    return false
                }
            case .numberVerifyInfo:
                if case .numberVerifyInfo = to {
                    return true
                } else {
                    return false
                }
            case .emailVerifyInfo:
                if case .emailVerifyInfo = to {
                    return true
                } else {
                    return false
                }
            case let .emailAddress(code):
                if case .emailAddress(code) = to {
                    return true
                } else {
                    return false
                }
            case let .emailCode(code):
                if case .emailCode(code) = to {
                    return true
                } else {
                    return false
                }
        }
    }
    
    func item(params: SecureIdPlaintextFormParams, strings: PresentationStrings) -> FormControllerItem {
        switch self {
            case let .immediatelyAvailablePhone(value):
                return FormControllerActionItem(type: .accent, title: formatPhoneNumber(value), activated: {
                    params.usePhone(value)
                })
            case .immediatelyAvailablePhoneInfo:
                return FormControllerTextItem(text: strings.Passport_Phone_UseTelegramNumberHelp)
            case let .numberInput(countryCode, number):
                var countryName = ""
                if let codeNumber = Int(countryCode), let codeId = AuthorizationSequenceCountrySelectionController.lookupCountryIdByCode(codeNumber) {
                    countryName = AuthorizationSequenceCountrySelectionController.lookupCountryNameById(codeId, strings: strings) ?? ""
                }
                return SecureIdValueFormPhoneItem(countryCode: countryCode, number: number, countryName: countryName, openCountrySelection: {
                    params.openCountrySelection()
                }, updateCountryCode: { value in
                    params.updateTextField(.countryCode, value)
                }, updateNumber: { value in
                    params.updateTextField(.number, value)
                })
            case .numberInputInfo:
                return FormControllerTextItem(text: strings.Passport_Phone_Help)
            case let .numberCode(code):
                return FormControllerTextInputItem(title: strings.ChangePhoneNumberCode_CodePlaceholder, text: code, placeholder: strings.ChangePhoneNumberCode_CodePlaceholder, textUpdated: { value in
                    params.updateTextField(.code, value)
                })
            case .numberVerifyInfo:
                return FormControllerTextItem(text: strings.ChangePhoneNumberCode_Help)
            case let .emailAddress(address):
                return FormControllerTextInputItem(title: strings.TwoStepAuth_Email, text: address, placeholder: strings.TwoStepAuth_Email, textUpdated: { value in
                    params.updateTextField(.email, value)
                })
            case let .emailCode(code):
                return FormControllerTextInputItem(title: strings.TwoStepAuth_RecoveryCode, text: code, placeholder: strings.TwoStepAuth_RecoveryCode, textUpdated: { value in
                    params.updateTextField(.code, value)
                })
            case .emailVerifyInfo:
                return FormControllerTextItem(text: strings.TwoStepAuth_EmailSent)
        }
    }
}

struct SecureIdPlaintextFormControllerNodeInitParams {
    let account: Account
    let context: SecureIdAccessContext
}

final class SecureIdPlaintextFormControllerNode: FormControllerNode<SecureIdPlaintextFormControllerNodeInitParams, SecureIdPlaintextFormInnerState> {
    private var _itemParams: SecureIdPlaintextFormParams?
    override var itemParams: SecureIdPlaintextFormParams {
        return self._itemParams!
    }
    
    private var theme: PresentationTheme
    private var strings: PresentationStrings
    
    private let account: Account
    private let context: SecureIdAccessContext
    
    var actionInputStateUpdated: ((SecureIdPlaintextFormInputState) -> Void)?
    var completedWithValue: ((SecureIdValueWithContext?) -> Void)?
    var dismiss: (() -> Void)?
    
    private let actionDisposable = MetaDisposable()
    
    required init(initParams: SecureIdPlaintextFormControllerNodeInitParams, theme: PresentationTheme, strings: PresentationStrings) {
        self.theme = theme
        self.strings = strings
        self.account = initParams.account
        self.context = initParams.context
        
        super.init(initParams: initParams, theme: theme, strings: strings)
        
        self._itemParams = SecureIdPlaintextFormParams(openCountrySelection: { [weak self] in
            guard let strongSelf = self else {
                return
            }
            let controller = AuthorizationSequenceCountrySelectionController(strings: strings, theme: AuthorizationSequenceCountrySelectionTheme(presentationTheme: strongSelf.theme), displayCodes: false)
            controller.completeWithCountryCode = { _, id in
                if let strongSelf = self, var innerState = strongSelf.innerState {
                    innerState.data.updateTextField(type: .countryCode, value: "+\(id)")
                    strongSelf.updateInnerState(transition: .immediate, with: innerState)
                }
            }
            strongSelf.view.endEditing(true)
            strongSelf.present(controller, ViewControllerPresentationArguments(presentationAnimation: .modalSheet))
        }, updateTextField: { [weak self] type, value in
            guard let strongSelf = self else {
                return
            }
            guard var innerState = strongSelf.innerState else {
                return
            }
            innerState.data.updateTextField(type: type, value: value)
            strongSelf.updateInnerState(transition: .immediate, with: innerState)
        }, usePhone: { [weak self] value in
            self?.savePhone(value)
        })
    }
    
    deinit {
        self.actionDisposable.dispose()
    }
    
    override func updateInnerState(transition: ContainedViewLayoutTransition, with innerState: SecureIdPlaintextFormInnerState) {
        let previousActionInputState = self.innerState?.actionInputState()
        super.updateInnerState(transition: transition, with: innerState)
        
        let actionInputState = innerState.actionInputState()
        if previousActionInputState != actionInputState {
            self.actionInputStateUpdated?(actionInputState)
        }
    }
    
    func save() {
        guard var innerState = self.innerState else {
            return
        }
        guard case .none = innerState.actionState else {
            return
        }
        
        switch innerState.data {
            case let .phone(phone):
                switch phone {
                    case let .input(input):
                        self.savePhone(input.countryCode + input.number)
                        return
                    case let .verify(verify):
                        guard case .saveAvailable = innerState.actionInputState() else {
                            return
                        }
                        innerState.actionState = .saving
                        self.updateInnerState(transition: .immediate, with: innerState)
                        
                        self.actionDisposable.set((secureIdCommitPhoneVerification(postbox: self.account.postbox, network: self.account.network, context: self.context, payload: verify.payload, code: verify.code)
                        |> deliverOnMainQueue).start(next: { [weak self] result in
                            if let strongSelf = self {
                                guard var innerState = strongSelf.innerState else {
                                    return
                                }
                                guard case .saving = innerState.actionState else {
                                    return
                                }
                                
                                strongSelf.completedWithValue?(result)
                            }
                        }, error: { [weak self] error in
                            if let strongSelf = self {
                                guard var innerState = strongSelf.innerState else {
                                    return
                                }
                                guard case .saving = innerState.actionState else {
                                    return
                                }
                                innerState.actionState = .none
                                strongSelf.updateInnerState(transition: .immediate, with: innerState)
                                let errorText: String
                                switch error {
                                    case .generic:
                                        errorText = strongSelf.strings.Login_UnknownError
                                    case .flood:
                                        errorText = strongSelf.strings.Login_CodeFloodError
                                    case .invalid:
                                        errorText = strongSelf.strings.Login_InvalidCodeError
                                }
                                strongSelf.present(standardTextAlertController(theme: AlertControllerTheme(presentationTheme: strongSelf.theme), title: nil, text: errorText, actions: [TextAlertAction(type: .defaultAction, title: strongSelf.strings.Common_OK, action: {})]), nil)
                            }
                        }))
                        
                        return
                }
            case let .email(email):
                switch email {
                    case let .input(input):
                        guard case .nextAvailable = innerState.actionInputState() else {
                            return
                        }
                        innerState.actionState = .saving
                        self.updateInnerState(transition: .immediate, with: innerState)
                        
                        self.actionDisposable.set((secureIdPrepareEmailVerification(network: self.account.network, value: SecureIdEmailValue(email: input.email))
                            |> deliverOnMainQueue).start(next: { [weak self] result in
                                if let strongSelf = self {
                                    guard var innerState = strongSelf.innerState else {
                                        return
                                    }
                                    guard case .saving = innerState.actionState else {
                                        return
                                    }
                                    innerState.actionState = .none
                                    innerState.data = .email(.verify(EmailVerifyState(email: input.email, payload: result, code: "")))
                                    strongSelf.updateInnerState(transition: .immediate, with: innerState)
                                }
                            }, error: { [weak self] error in
                                if let strongSelf = self {
                                    guard var innerState = strongSelf.innerState else {
                                        return
                                    }
                                    guard case .saving = innerState.actionState else {
                                        return
                                    }
                                    innerState.actionState = .none
                                    strongSelf.updateInnerState(transition: .immediate, with: innerState)
                                    let errorText: String
                                    switch error {
                                        case .generic:
                                            errorText = strongSelf.strings.Login_UnknownError
                                        case .flood:
                                            errorText = strongSelf.strings.Login_CodeFloodError
                                    }
                                    strongSelf.present(standardTextAlertController(theme: AlertControllerTheme(presentationTheme: strongSelf.theme), title: nil, text: errorText, actions: [TextAlertAction(type: .defaultAction, title: strongSelf.strings.Common_OK, action: {})]), nil)
                                }
                            }))
                        return
                    case let .verify(verify):
                        guard case .saveAvailable = innerState.actionInputState() else {
                            return
                        }
                        innerState.actionState = .saving
                        self.updateInnerState(transition: .immediate, with: innerState)
                        
                        self.actionDisposable.set((secureIdCommitEmailVerification(postbox: self.account.postbox, network: self.account.network, context: self.context, payload: verify.payload, code: verify.code)
                        |> deliverOnMainQueue).start(next: { [weak self] result in
                            if let strongSelf = self {
                                guard var innerState = strongSelf.innerState else {
                                    return
                                }
                                guard case .saving = innerState.actionState else {
                                    return
                                }
                                
                                strongSelf.completedWithValue?(result)
                            }
                        }, error: { [weak self] error in
                            if let strongSelf = self {
                                guard var innerState = strongSelf.innerState else {
                                    return
                                }
                                guard case .saving = innerState.actionState else {
                                    return
                                }
                                innerState.actionState = .none
                                strongSelf.updateInnerState(transition: .immediate, with: innerState)
                                let errorText: String
                                switch error {
                                    case .generic:
                                        errorText = strongSelf.strings.Login_UnknownError
                                    case .flood:
                                        errorText = strongSelf.strings.Login_CodeFloodError
                                    case .invalid:
                                        errorText = strongSelf.strings.Login_InvalidCodeError
                                }
                                strongSelf.present(standardTextAlertController(theme: AlertControllerTheme(presentationTheme: strongSelf.theme), title: nil, text: errorText, actions: [TextAlertAction(type: .defaultAction, title: strongSelf.strings.Common_OK, action: {})]), nil)
                            }
                        }))
                        
                        return
                }
        }
    }
    
    private func savePhone(_ value: String) {
        guard var innerState = self.innerState else {
            return
        }
        guard case .none = innerState.actionState else {
            return
        }
        innerState.actionState = .saving
        let inputPhone = cleanPhoneNumber(value)
        self.updateInnerState(transition: .immediate, with: innerState)
        
        self.actionDisposable.set((secureIdPreparePhoneVerification(network: self.account.network, value: SecureIdPhoneValue(phone: inputPhone))
            |> deliverOnMainQueue).start(next: { [weak self] result in
                if let strongSelf = self {
                    guard var innerState = strongSelf.innerState else {
                        return
                    }
                    guard case .saving = innerState.actionState else {
                        return
                    }
                    innerState.actionState = .none
                    innerState.data = .phone(.verify(PhoneVerifyState(phone: inputPhone, payload: result, code: "")))
                    strongSelf.updateInnerState(transition: .immediate, with: innerState)
                }
                }, error: { [weak self] error in
                    if let strongSelf = self {
                        guard var innerState = strongSelf.innerState else {
                            return
                        }
                        guard case .saving = innerState.actionState else {
                            return
                        }
                        innerState.actionState = .none
                        strongSelf.updateInnerState(transition: .immediate, with: innerState)
                        let errorText: String
                        switch error {
                        case .generic:
                            errorText = strongSelf.strings.Login_UnknownError
                        case .flood:
                            errorText = strongSelf.strings.Login_CodeFloodError
                        }
                        strongSelf.present(standardTextAlertController(theme: AlertControllerTheme(presentationTheme: strongSelf.theme), title: nil, text: errorText, actions: [TextAlertAction(type: .defaultAction, title: strongSelf.strings.Common_OK, action: {})]), nil)
                    }
            }))
    }
    
    func deleteValue() {
        guard var innerState = self.innerState, let previousValue = innerState.previousValue else {
            return
        }
        guard case .none = innerState.actionState else {
            return
        }
        
        innerState.actionState = .deleting
        self.updateInnerState(transition: .immediate, with: innerState)
        
        self.actionDisposable.set((deleteSecureIdValues(network: self.account.network, keys: Set([previousValue.key]))
        |> deliverOnMainQueue).start(next: { [weak self] result in
            if let strongSelf = self {
                strongSelf.completedWithValue?(nil)
            }
        }, error: { [weak self] error in
            if let strongSelf = self {
                guard var innerState = strongSelf.innerState else {
                    return
                }
                guard case .deleting = innerState.actionState else {
                    return
                }
                innerState.actionState = .none
                strongSelf.updateInnerState(transition: .immediate, with: innerState)
            }
        }))
    }
}

