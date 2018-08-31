import Foundation
import Display
import SafariServices
import TelegramCore
import Postbox
import SwiftSignalKit

public func openExternalUrl(account: Account, url: String, presentationData: PresentationData, applicationContext: TelegramApplicationContext, navigationController: NavigationController?, dismissInput: @escaping () -> Void) {
    if url.lowercased().hasPrefix("tel:") {
        applicationContext.applicationBindings.openUrl(url)
        return
    }
    
    var parsedUrlValue: URL?
    if let parsed = URL(string: url) {
        parsedUrlValue = parsed
    } else if let encoded = (url as NSString).addingPercentEscapes(using: String.Encoding.utf8.rawValue), let parsed = URL(string: encoded) {
        parsedUrlValue = parsed
    }
    
    if let parsedUrlValue = parsedUrlValue, parsedUrlValue.scheme == "mailto" {
        applicationContext.applicationBindings.openUrl(url)
        return
    }
    
    if let parsed = parsedUrlValue, parsed.scheme == nil {
        parsedUrlValue = URL(string: "https://" + parsed.absoluteString)
    }
    if let parsed = parsedUrlValue, parsed.host == nil, let scheme = parsed.scheme, !scheme.isEmpty {
        parsedUrlValue = URL(string: "https://" + parsed.absoluteString)
    }
    
    guard let parsedUrl = parsedUrlValue else {
        return
    }
    
    if let host = parsedUrl.host?.lowercased() {
        if host == "itunes.apple.com" {
            if applicationContext.applicationBindings.canOpenUrl(parsedUrl.absoluteString) {
                applicationContext.applicationBindings.openUrl(url)
                return
            }
        }
        if host == "twitter.com" || host == "mobile.twitter.com" {
            if applicationContext.applicationBindings.canOpenUrl("twitter://status") {
                applicationContext.applicationBindings.openUrl(url)
                return
            }
        } else if host == "instagram.com" {
            if applicationContext.applicationBindings.canOpenUrl("instagram://photo") {
                applicationContext.applicationBindings.openUrl(url)
                return
            }
        }
    }
    
    let continueHandling: () -> Void = {
        if parsedUrl.scheme == "tg", let query = parsedUrl.query {
            var convertedUrl: String?
            if parsedUrl.host == "localpeer" {
                 if let components = URLComponents(string: "/?" + query) {
                    var peerId: PeerId?
                    if let queryItems = components.queryItems {
                        for queryItem in queryItems {
                            if let value = queryItem.value {
                                if queryItem.name == "id", let intValue = Int64(value) {
                                    peerId = PeerId(intValue)
                                }
                            }
                        }
                    }
                    if let peerId = peerId, let navigationController = navigationController {
                        navigateToChatController(navigationController: navigationController, account: account, chatLocation: .peer(peerId))
                    }
                }
            } else if parsedUrl.host == "join" {
                if let components = URLComponents(string: "/?" + query) {
                    var invite: String?
                    if let queryItems = components.queryItems {
                        for queryItem in queryItems {
                            if let value = queryItem.value {
                                if queryItem.name == "invite" {
                                    invite = value
                                }
                            }
                        }
                    }
                    if let invite = invite {
                        convertedUrl = "https://t.me/joinchat/\(invite)"
                    }
                }
            } else if parsedUrl.host == "addstickers" {
                if let components = URLComponents(string: "/?" + query) {
                    var set: String?
                    if let queryItems = components.queryItems {
                        for queryItem in queryItems {
                            if let value = queryItem.value {
                                if queryItem.name == "set" {
                                    set = value
                                }
                            }
                        }
                    }
                    if let set = set {
                        convertedUrl = "https://t.me/addstickers/\(set)"
                    }
                }
            } else if parsedUrl.host == "msg_url" {
                if let components = URLComponents(string: "/?" + query) {
                    var shareUrl: String?
                    var shareText: String?
                    if let queryItems = components.queryItems {
                        for queryItem in queryItems {
                            if let value = queryItem.value {
                                if queryItem.name == "url" {
                                    shareUrl = value
                                } else if queryItem.name == "text" {
                                    shareText = value
                                }
                            }
                        }
                    }
                    if let shareUrl = shareUrl {
                        let controller = PeerSelectionController(account: account)
                        controller.peerSelected = { [weak controller] peerId in
                            if let strongController = controller {
                                strongController.dismiss()
                                
                                let textInputState: ChatTextInputState
                                if let shareText = shareText, !shareText.isEmpty {
                                    let urlString = NSMutableAttributedString(string: "\(shareUrl)\n")
                                    let textString = NSAttributedString(string: "\(shareText)")
                                    let selectionRange: Range<Int> = urlString.length ..< (urlString.length + textString.length)
                                    urlString.append(textString)
                                    textInputState = ChatTextInputState(inputText: urlString, selectionRange: selectionRange)
                                } else {
                                    textInputState = ChatTextInputState(inputText: NSAttributedString(string: "\(shareUrl)"))
                                }
                                
                                let _ = (account.postbox.transaction({ transaction -> Void in
                                    transaction.updatePeerChatInterfaceState(peerId, update: { currentState in
                                        if let currentState = currentState as? ChatInterfaceState {
                                            return currentState.withUpdatedComposeInputState(textInputState)
                                        } else {
                                            return ChatInterfaceState().withUpdatedComposeInputState(textInputState)
                                        }
                                    })
                                })
                                |> deliverOnMainQueue).start(completed: {
                                    navigationController?.pushViewController(ChatController(account: account, chatLocation: .peer(peerId), messageId: nil))
                                })
                            }
                        }
                        if let navigationController = navigationController {
                            (navigationController.viewControllers.last as? ViewController)?.present(controller, in: .window(.root), with: ViewControllerPresentationArguments(presentationAnimation: ViewControllerPresentationAnimation.modalSheet))
                        }
                    }
                }
            } else if parsedUrl.host == "socks" || parsedUrl.host == "proxy" {
                if let components = URLComponents(string: "/?" + query) {
                    var server: String?
                    var port: String?
                    var user: String?
                    var pass: String?
                    var secret: String?
                    if let queryItems = components.queryItems {
                        for queryItem in queryItems {
                            if let value = queryItem.value {
                                if queryItem.name == "server" || queryItem.name == "proxy" {
                                    server = value
                                } else if queryItem.name == "port" {
                                    port = value
                                } else if queryItem.name == "user" {
                                    user = value
                                } else if queryItem.name == "pass" {
                                    pass = value
                                } else if queryItem.name == "secret" {
                                    secret = value
                                }
                            }
                        }
                    }
                    
                    if let server = server, !server.isEmpty, let port = port, let _ = Int32(port) {
                        var result = "https://t.me/proxy?proxy=\(server)&port=\(port)"
                        if let user = user {
                            result += "&user=\((user as NSString).addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryValueAllowed) ?? "")"
                            if let pass = pass {
                                result += "&pass=\((pass as NSString).addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryValueAllowed) ?? "")"
                            }
                        }
                        if let secret = secret {
                            result += "&secret=\((secret as NSString).addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryValueAllowed) ?? "")"
                        }
                        convertedUrl = result
                    }
                }
            } else if parsedUrl.host == "passport" || parsedUrl.host == "resolve" {
                if let components = URLComponents(string: "/?" + query) {
                    var domain: String?
                    var botId: Int32?
                    var scope: String?
                    var publicKey: String?
                    var opaquePayload = Data()
                    var opaqueNonce = Data()
                    if let queryItems = components.queryItems {
                        for queryItem in queryItems {
                            if let value = queryItem.value {
                                if queryItem.name == "domain" {
                                    domain = value
                                } else if queryItem.name == "bot_id" {
                                    botId = Int32(value)
                                } else if queryItem.name == "scope" {
                                    scope = value
                                } else if queryItem.name == "public_key" {
                                    publicKey = value
                                } else if queryItem.name == "payload" {
                                    if let data = value.data(using: .utf8) {
                                        opaquePayload = data
                                    }
                                } else if queryItem.name == "nonce" {
                                    if let data = value.data(using: .utf8) {
                                        opaqueNonce = data
                                    }
                                }
                            }
                        }
                    }
                    
                    let valid: Bool
                    if parsedUrl.host == "resolve" {
                        if domain == "telegrampassport" {
                            valid = true
                        } else {
                            valid = false
                        }
                    } else {
                        valid = true
                    }
                    
                    if valid && GlobalExperimentalSettings.enablePassport {
                        if let botId = botId, let scope = scope, let publicKey = publicKey {
                            if scope.hasPrefix("{") && scope.hasSuffix("}") {
                                opaquePayload = Data()
                                if opaqueNonce.isEmpty {
                                    return
                                }
                            } else if opaquePayload.isEmpty {
                                return
                            }
                            let controller = SecureIdAuthController(account: account, mode: .form(peerId: PeerId(namespace: Namespaces.Peer.CloudUser, id: botId), scope: scope, publicKey: publicKey, opaquePayload: opaquePayload, opaqueNonce: opaqueNonce))
                            
                            if let navigationController = navigationController {
                                navigationController.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
                                
                                navigationController.view.window?.endEditing(true)
                                (navigationController.viewControllers.last as? ViewController)?.present(controller, in: .window(.root), with: nil)
                            }
                        }
                        return
                    }
                }
            }
            
            if parsedUrl.host == "resolve" {
                if let components = URLComponents(string: "/?" + query) {
                    var domain: String?
                    var start: String?
                    var startGroup: String?
                    var game: String?
                    var post: String?
                    if let queryItems = components.queryItems {
                        for queryItem in queryItems {
                            if let value = queryItem.value {
                                if queryItem.name == "domain" {
                                    domain = value
                                } else if queryItem.name == "start" {
                                    start = value
                                } else if queryItem.name == "startgroup" {
                                    startGroup = value
                                } else if queryItem.name == "game" {
                                    game = value
                                } else if queryItem.name == "post" {
                                    post = value
                                }
                            }
                        }
                    }
                    
                    if let domain = domain {
                        var result = "https://t.me/\(domain)"
                        if let post = post, let postValue = Int(post) {
                            result += "/\(postValue)"
                        }
                        if let start = start {
                            result += "?start=\(start)"
                        } else if let startGroup = startGroup {
                            result += "?startgroup=\(startGroup)"
                        } else if let game = game {
                            result += "?game=\(game)"
                        }
                        convertedUrl = result
                    }
                }
            }
            
            if let convertedUrl = convertedUrl {
                let _ = (resolveUrl(account: account, url: convertedUrl)
                |> deliverOnMainQueue).start(next: { resolved in
                    if case let .externalUrl(value) = resolved {
                        applicationContext.applicationBindings.openUrl(value)
                    } else {
                        openResolvedUrl(resolved, account: account, navigationController: navigationController, openPeer: { peerId, navigation in
                            switch navigation {
                                case .info:
                                    let _ = (account.postbox.loadedPeerWithId(peerId)
                                    |> deliverOnMainQueue).start(next: { peer in
                                        if let infoController = peerInfoController(account: account, peer: peer) {
                                            if let navigationController = navigationController {
                                                navigationController.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
                                            }
                                            navigationController?.pushViewController(infoController)
                                        }
                                    })
                                case .chat:
                                    if let navigationController = navigationController {
                                        navigationController.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
                                        navigateToChatController(navigationController: navigationController, account: account, chatLocation: .peer(peerId))
                                    }
                                case .withBotStartPayload:
                                    if let navigationController = navigationController {
                                        navigationController.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
                                        navigateToChatController(navigationController: navigationController, account: account, chatLocation: .peer(peerId))
                                    }
                            }
                        }, present: { c, a in
                            if let navigationController = navigationController {
                                navigationController.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
                                (navigationController.viewControllers.last as? ViewController)?.present(c, in: .window(.root), with: a)
                            }
                        }, dismissInput: {
                            dismissInput()
                        })
                    }
                })
            }
            return
        }
        
        if parsedUrl.scheme == "http" || parsedUrl.scheme == "https" {
            if #available(iOSApplicationExtension 9.0, *) {
                if let window = navigationController?.view.window {
                    let controller = SFSafariViewController(url: parsedUrl)
                    if #available(iOSApplicationExtension 10.0, *) {
                        controller.preferredBarTintColor = presentationData.theme.rootController.navigationBar.backgroundColor
                        controller.preferredControlTintColor = presentationData.theme.rootController.navigationBar.accentTextColor
                    }
                    window.rootViewController?.present(controller, animated: true)
                } else {
                    applicationContext.applicationBindings.openUrl(parsedUrl.absoluteString)
                }
            } else {
                applicationContext.applicationBindings.openUrl(url)
            }
        } else {
            applicationContext.applicationBindings.openUrl(url)
        }
    }
    
    if parsedUrl.scheme == "http" || parsedUrl.scheme == "https" {
        applicationContext.applicationBindings.openUniversalUrl(url, TelegramApplicationOpenUrlCompletion(completion: { success in
            if !success {
                continueHandling()
            }
        }))
    } else {
        continueHandling()
    }
}
