import Foundation
import Postbox
import TelegramCore

struct SecureIdEncryptedFormData {
    let form: EncryptedSecureIdForm
    let accountPeer: Peer
    let servicePeer: Peer
}

enum SecureIdAuthPasswordChallengeState {
    case none
    case checking
    case invalid
}

enum SecureIdAuthControllerVerificationState: Equatable {
    case noChallenge
    case passwordChallenge(String, SecureIdAuthPasswordChallengeState)
    case verified(SecureIdAccessContext)
    
    static func ==(lhs: SecureIdAuthControllerVerificationState, rhs: SecureIdAuthControllerVerificationState) -> Bool {
        switch lhs {
            case .noChallenge:
                if case .noChallenge = rhs {
                    return true
                } else {
                    return false
                }
            case let .passwordChallenge(hint, state):
                if case .passwordChallenge(hint, state) = rhs {
                    return true
                } else {
                    return false
                }
            case .verified:
                if case .verified = rhs {
                    return true
                } else {
                    return false
                }
        }
    }
}

struct SecureIdAuthControllerFormState: Equatable {
    var encryptedFormData: SecureIdEncryptedFormData?
    var formData: SecureIdForm?
    var verificationState: SecureIdAuthControllerVerificationState?
    
    static func ==(lhs: SecureIdAuthControllerFormState, rhs: SecureIdAuthControllerFormState) -> Bool {
        if (lhs.formData != nil) != (rhs.formData != nil) {
            return false
        }
        
        if (lhs.encryptedFormData != nil) != (rhs.encryptedFormData != nil) {
            return false
        }
        
        if let lhsFormData = lhs.formData, let rhsFormData = rhs.formData {
            if lhsFormData != rhsFormData {
                return false
            }
        } else if (lhs.formData != nil) != (rhs.formData != nil) {
            return false
        }
        
        if lhs.verificationState != rhs.verificationState {
            return false
        }
        
        return true
    }
}

struct SecureIdAuthControllerListState: Equatable {
    var verificationState: SecureIdAuthControllerVerificationState?
    var encryptedValues: EncryptedAllSecureIdValues?
    var values: [SecureIdValueWithContext]?
    
    static func ==(lhs: SecureIdAuthControllerListState, rhs: SecureIdAuthControllerListState) -> Bool {
        if lhs.verificationState != rhs.verificationState {
            return false
        }
        if (lhs.encryptedValues != nil) != (rhs.encryptedValues != nil) {
            return false
        }
        if lhs.values != rhs.values {
            return false
        }
        return true
    }
}

enum SecureIdAuthControllerState: Equatable {
    case form(SecureIdAuthControllerFormState)
    case list(SecureIdAuthControllerListState)
    
    var verificationState: SecureIdAuthControllerVerificationState? {
        get {
            switch self {
                case let .form(form):
                    return form.verificationState
                case let .list(list):
                    return list.verificationState
            }
        } set(value) {
            switch self {
                case var .form(form):
                    form.verificationState = value
                    self = .form(form)
                case var .list(list):
                    list.verificationState = value
                    self = .list(list)
            }
        }
    }
}
