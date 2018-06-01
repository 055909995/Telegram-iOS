import Foundation
#if os(macOS)
    import PostboxMac
    import SwiftSignalKitMac
    import MtProtoKitMac
#else
    import Postbox
    import SwiftSignalKit
    import MtProtoKitDynamic
#endif

public enum AuthorizationCodeRequestError {
    case invalidPhoneNumber
    case limitExceeded
    case generic
    case phoneLimitExceeded
    case phoneBanned
}

public func sendAuthorizationCode(account: UnauthorizedAccount, phoneNumber: String, apiId: Int32, apiHash: String) -> Signal<UnauthorizedAccount, AuthorizationCodeRequestError> {
    let sendCode = Api.functions.auth.sendCode(flags: 0, phoneNumber: phoneNumber, currentNumber: nil, apiId: apiId, apiHash: apiHash)
    
    let codeAndAccount = account.network.request(sendCode, automaticFloodWait: false)
        |> map { result in
            return (result, account)
        } |> `catch` { error -> Signal<(Api.auth.SentCode, UnauthorizedAccount), MTRpcError> in
            switch (error.errorDescription ?? "") {
                case Regex("(PHONE_|USER_|NETWORK_)MIGRATE_(\\d+)"):
                    let range = error.errorDescription.range(of: "MIGRATE_")!
                    let updatedMasterDatacenterId = Int32(error.errorDescription[range.upperBound ..< error.errorDescription.endIndex])!
                    let updatedAccount = account.changedMasterDatacenterId(updatedMasterDatacenterId)
                    return updatedAccount
                        |> mapToSignalPromotingError { updatedAccount -> Signal<(Api.auth.SentCode, UnauthorizedAccount), MTRpcError> in
                            return updatedAccount.network.request(sendCode, automaticFloodWait: false)
                            |> map { sentCode in
                                return (sentCode, updatedAccount)
                            }
                    }
            case _:
                return .fail(error)
            }
        }
        |> mapError { error -> AuthorizationCodeRequestError in
            if error.errorDescription.hasPrefix("FLOOD_WAIT") {
                return .limitExceeded
            } else if error.errorDescription == "PHONE_NUMBER_INVALID" {
                return .invalidPhoneNumber
            } else if error.errorDescription == "PHONE_NUMBER_FLOOD" {
                return .phoneLimitExceeded
            } else if error.errorDescription == "PHONE_NUMBER_BANNED" {
                return .phoneBanned
            } else {
                return .generic
            }
        }
    
    return codeAndAccount
        |> mapToSignal { (sentCode, account) -> Signal<UnauthorizedAccount, AuthorizationCodeRequestError> in
            return account.postbox.modify { modifier -> UnauthorizedAccount in
                switch sentCode {
                    case let .sentCode(_, type, phoneCodeHash, nextType, timeout, termsOfService):
                        var parsedNextType: AuthorizationCodeNextType?
                        if let nextType = nextType {
                            parsedNextType = AuthorizationCodeNextType(apiType: nextType)
                        }
                    
                        modifier.setState(UnauthorizedAccountState(masterDatacenterId: account.masterDatacenterId, contents: .confirmationCodeEntry(number: phoneNumber, type: SentAuthorizationCodeType(apiType: type), hash: phoneCodeHash, timeout: timeout, nextType: parsedNextType, termsOfService: termsOfService.flatMap(UnauthorizedAccountTermsOfService.init(apiTermsOfService:)))))
                }
                return account
            } |> mapError { _ -> AuthorizationCodeRequestError in return .generic }
        }
}

public func resendAuthorizationCode(account: UnauthorizedAccount) -> Signal<Void, AuthorizationCodeRequestError> {
    return account.postbox.modify { modifier -> Signal<Void, AuthorizationCodeRequestError> in
        if let state = modifier.getState() as? UnauthorizedAccountState {
            switch state.contents {
                case let .confirmationCodeEntry(number, _, hash, _, nextType, _):
                    if nextType != nil {
                        return account.network.request(Api.functions.auth.resendCode(phoneNumber: number, phoneCodeHash: hash), automaticFloodWait: false)
                            |> mapError { error -> AuthorizationCodeRequestError in
                                if error.errorDescription.hasPrefix("FLOOD_WAIT") {
                                    return .limitExceeded
                                } else if error.errorDescription == "PHONE_NUMBER_INVALID" {
                                    return .invalidPhoneNumber
                                } else if error.errorDescription == "PHONE_NUMBER_FLOOD" {
                                    return .phoneLimitExceeded
                                } else if error.errorDescription == "PHONE_NUMBER_BANNED" {
                                    return .phoneBanned
                                } else {
                                    return .generic
                                }
                            }
                            |> mapToSignal { sentCode -> Signal<Void, AuthorizationCodeRequestError> in
                                return account.postbox.modify { modifier -> Void in
                                    switch sentCode {
                                        case let .sentCode(_, type, phoneCodeHash, nextType, timeout, termsOfService):
                                            
                                                var parsedNextType: AuthorizationCodeNextType?
                                                if let nextType = nextType {
                                                    parsedNextType = AuthorizationCodeNextType(apiType: nextType)
                                                }
                                                
                                                modifier.setState(UnauthorizedAccountState(masterDatacenterId: account.masterDatacenterId, contents: .confirmationCodeEntry(number: number, type: SentAuthorizationCodeType(apiType: type), hash: phoneCodeHash, timeout: timeout, nextType: parsedNextType, termsOfService: termsOfService.flatMap(UnauthorizedAccountTermsOfService.init(apiTermsOfService:)))))
                                        
                                    }
                                } |> mapError { _ -> AuthorizationCodeRequestError in return .generic }
                            }
                    } else {
                        return .fail(.generic)
                    }
                default:
                    return .complete()
            }
        } else {
            return .fail(.generic)
        }
    }
    |> mapError { _ -> AuthorizationCodeRequestError in
        return .generic
    }
    |> switchToLatest
}

public enum AuthorizationCodeVerificationError {
    case invalidCode
    case limitExceeded
    case generic
}

private enum AuthorizationCodeResult {
    case authorization(Api.auth.Authorization)
    case password(hint: String)
    case signUp
}

public func authorizeWithCode(account: UnauthorizedAccount, code: String) -> Signal<Void, AuthorizationCodeVerificationError> {
    return account.postbox.modify { modifier -> Signal<Void, AuthorizationCodeVerificationError> in
        if let state = modifier.getState() as? UnauthorizedAccountState {
            switch state.contents {
                case let .confirmationCodeEntry(number, _, hash, _, _, _):
                    return account.network.request(Api.functions.auth.signIn(phoneNumber: number, phoneCodeHash: hash, phoneCode: code), automaticFloodWait: false) |> map { authorization in
                            return .authorization(authorization)
                        } |> `catch` { error -> Signal<AuthorizationCodeResult, AuthorizationCodeVerificationError> in
                            switch (error.errorCode, error.errorDescription ?? "") {
                                case (401, "SESSION_PASSWORD_NEEDED"):
                                    return account.network.request(Api.functions.account.getPassword(), automaticFloodWait: false)
                                        |> mapError { error -> AuthorizationCodeVerificationError in
                                            if error.errorDescription.hasPrefix("FLOOD_WAIT") {
                                                return .limitExceeded
                                            } else {
                                                return .generic
                                            }
                                        }
                                        |> mapToSignal { result -> Signal<AuthorizationCodeResult, AuthorizationCodeVerificationError> in
                                            switch result {
                                                case .noPassword:
                                                    return .fail(.generic)
                                                case let .password(_, _, hint, _, _):
                                                    return .single(.password(hint: hint))
                                            }
                                        }
                                case let (_, errorDescription):
                                    if errorDescription.hasPrefix("FLOOD_WAIT") {
                                        return .fail(.limitExceeded)
                                    } else if errorDescription == "PHONE_CODE_INVALID" {
                                        return .fail(.invalidCode)
                                    } else if errorDescription == "PHONE_NUMBER_UNOCCUPIED" {
                                        return .single(.signUp)
                                    } else {
                                        return .fail(.generic)
                                    }
                            }
                        }
                        |> mapToSignal { result -> Signal<Void, AuthorizationCodeVerificationError> in
                            return account.postbox.modify { modifier -> Void in
                                switch result {
                                    case .signUp:
                                        modifier.setState(UnauthorizedAccountState(masterDatacenterId: account.masterDatacenterId, contents: .signUp(number: number, codeHash: hash, code: code, firstName: "", lastName: "")))
                                    case let .password(hint):
                                        modifier.setState(UnauthorizedAccountState(masterDatacenterId: account.masterDatacenterId, contents: .passwordEntry(hint: hint, number: number, code: code)))
                                    case let .authorization(authorization):
                                        switch authorization {
                                            case let .authorization(_, _, user):
                                                let user = TelegramUser(user: user)
                                                let state = AuthorizedAccountState(masterDatacenterId: account.masterDatacenterId, peerId: user.id, state: nil)
                                                /*modifier.updatePeersInternal([user], update: { current, peer -> Peer? in
                                                    return peer
                                                })*/
                                                modifier.setState(state)
                                        }
                                }
                            } |> mapError { _ -> AuthorizationCodeVerificationError in
                                    return .generic
                            }
                        }
                default:
                    return .fail(.generic)
            }
        } else {
            return .fail(.generic)
        }
    }
    |> mapError { _ -> AuthorizationCodeVerificationError in
        return .generic
    }
    |> switchToLatest
}

public enum AuthorizationPasswordVerificationError {
    case limitExceeded
    case invalidPassword
    case generic
}

public func authorizeWithPassword(account: UnauthorizedAccount, password: String) -> Signal<Void, AuthorizationPasswordVerificationError> {
    return verifyPassword(account, password: password)
        |> `catch` { error -> Signal<Api.auth.Authorization, AuthorizationPasswordVerificationError> in
            if error.errorDescription.hasPrefix("FLOOD_WAIT") {
                return .fail(.limitExceeded)
            } else if error.errorDescription == "PASSWORD_HASH_INVALID" {
                return .fail(.invalidPassword)
            } else {
                return .fail(.generic)
            }
        }
        |> mapToSignal { result -> Signal<Void, AuthorizationPasswordVerificationError> in
            return account.postbox.modify { modifier -> Void in
                switch result {
                    case let .authorization(_, _, user):
                        let user = TelegramUser(user: user)
                        let state = AuthorizedAccountState(masterDatacenterId: account.masterDatacenterId, peerId: user.id, state: nil)
                        /*modifier.updatePeersInternal([user], update: { current, peer -> Peer? in
                            return peer
                        })*/
                        modifier.setState(state)
                    }
            }
            |> mapError { _ -> AuthorizationPasswordVerificationError in
                return .generic
            }
        }
}

public enum PasswordRecoveryRequestError {
    case limitExceeded
    case generic
}

public enum PasswordRecoveryOption {
    case none
    case email(pattern: String)
}

public func requestPasswordRecovery(account: UnauthorizedAccount) -> Signal<PasswordRecoveryOption, PasswordRecoveryRequestError> {
    return account.network.request(Api.functions.auth.requestPasswordRecovery())
        |> map(Optional.init)
        |> `catch` { error -> Signal<Api.auth.PasswordRecovery?, PasswordRecoveryRequestError> in
            if error.errorDescription.hasPrefix("FLOOD_WAIT") {
                return .fail(.limitExceeded)
            } else if error.errorDescription.hasPrefix("PASSWORD_RECOVERY_NA") {
                return .single(nil)
            } else {
                return .fail(.generic)
            }
        }
        |> map { result -> PasswordRecoveryOption in
            if let result = result {
                switch result {
                    case let .passwordRecovery(emailPattern):
                        return .email(pattern: emailPattern)
                }
            } else {
                return .none
            }
        }
}

public enum PasswordRecoveryError {
    case invalidCode
    case limitExceeded
    case expired
}

public func performPasswordRecovery(account: UnauthorizedAccount, code: String) -> Signal<Void, PasswordRecoveryError> {
    return account.network.request(Api.functions.auth.recoverPassword(code: code))
    |> mapError { error -> PasswordRecoveryError in
        if error.errorDescription.hasPrefix("FLOOD_WAIT") {
            return .limitExceeded
        } else if error.errorDescription.hasPrefix("PASSWORD_RECOVERY_EXPIRED") {
            return .expired
        } else {
            return .invalidCode
        }
    }
    |> mapToSignal { result -> Signal<Void, PasswordRecoveryError> in
        return account.postbox.modify { modifier -> Void in
            switch result {
                case let .authorization(_, _, user):
                    let user = TelegramUser(user: user)
                    let state = AuthorizedAccountState(masterDatacenterId: account.masterDatacenterId, peerId: user.id, state: nil)
                    /*modifier.updatePeersInternal([user], update: { current, peer -> Peer? in
                     return peer
                     })*/
                    modifier.setState(state)
            }
        } |> mapError { _ in return PasswordRecoveryError.expired }
    }
}

public enum AccountResetError {
    case generic
}

public func performAccountReset(account: UnauthorizedAccount) -> Signal<Void, AccountResetError> {
    return account.network.request(Api.functions.account.deleteAccount(reason: ""))
        |> map { _ -> Int32? in return nil }
        |> `catch` { error -> Signal<Int32?, AccountResetError> in
            if error.errorDescription.hasPrefix("2FA_CONFIRM_WAIT_") {
                let timeout = String(error.errorDescription[error.errorDescription.index(error.errorDescription.startIndex, offsetBy: "2FA_CONFIRM_WAIT_".count)...])
                if let value = Int32(timeout) {
                    return .single(value)
                } else {
                    return .fail(.generic)
                }
            } else {
                return .fail(.generic)
            }
        }
        |> mapToSignal { timeout -> Signal<Void, AccountResetError> in
            return account.postbox.modify { modifier -> Void in
                if let state = modifier.getState() as? UnauthorizedAccountState, case let .passwordEntry(_, number, _) = state.contents {
                    if let timeout = timeout {
                        let timestamp = Int32(CFAbsoluteTimeGetCurrent() + NSTimeIntervalSince1970)
                        modifier.setState(UnauthorizedAccountState(masterDatacenterId: state.masterDatacenterId, contents: .awaitingAccountReset(protectedUntil: timestamp + timeout, number: number)))
                    } else {
                        modifier.setState(UnauthorizedAccountState(masterDatacenterId: state.masterDatacenterId, contents: .empty))
                    }
                }
            } |> mapError { _ in return AccountResetError.generic }
        }
}

public enum SignUpError {
    case generic
    case limitExceeded
    case codeExpired
    case invalidFirstName
    case invalidLastName
}

public func signUpWithName(account: UnauthorizedAccount, firstName: String, lastName: String) -> Signal<Void, SignUpError> {
    return account.postbox.modify { modifier -> Signal<Void, SignUpError> in
        if let state = modifier.getState() as? UnauthorizedAccountState, case let .signUp(number, codeHash, code, _, _) = state.contents {
            return account.network.request(Api.functions.auth.signUp(phoneNumber: number, phoneCodeHash: codeHash, phoneCode: code, firstName: firstName, lastName: lastName))
                |> mapError { error -> SignUpError in
                    if error.errorDescription.hasPrefix("FLOOD_WAIT") {
                        return .limitExceeded
                    } else if error.errorDescription == "PHONE_CODE_EXPIRED" {
                        return .codeExpired
                    } else if error.errorDescription == "FIRSTNAME_INVALID" {
                        return .invalidFirstName
                    } else if error.errorDescription == "LASTNAME_INVALID" {
                        return .invalidLastName
                    } else {
                        return .generic
                    }
                }
                |> mapToSignal { result -> Signal<Void, SignUpError> in
                    return account.postbox.modify { modifier -> Void in
                        switch result {
                            case let .authorization(_, _, user):
                                let user = TelegramUser(user: user)
                                let state = AuthorizedAccountState(masterDatacenterId: account.masterDatacenterId, peerId: user.id, state: nil)
                                modifier.setState(state)
                        }
                    } |> mapError { _ -> SignUpError in return .generic }
                }
        } else {
            return .fail(.generic)
        }
    } |> mapError { _ -> SignUpError in return .generic } |> switchToLatest
}

public enum AuthorizationStateReset {
    case empty
}

public func resetAuthorizationState(account: UnauthorizedAccount, to value: AuthorizationStateReset) -> Signal<Void, NoError> {
    return account.postbox.modify { modifier -> Void in
        if let state = modifier.getState() as? UnauthorizedAccountState {
            modifier.setState(UnauthorizedAccountState(masterDatacenterId: state.masterDatacenterId, contents: .empty))
        }
    }
}
