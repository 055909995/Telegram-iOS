import Foundation
import Display
import AsyncDisplayKit
import WebKit
import TelegramCore
import Postbox
import SwiftSignalKit

private class WeakGameScriptMessageHandler: NSObject, WKScriptMessageHandler {
    private let f: (WKScriptMessage) -> ()
    
    init(_ f: @escaping (WKScriptMessage) -> ()) {
        self.f = f
        
        super.init()
    }
    
    func userContentController(_ controller: WKUserContentController, didReceive scriptMessage: WKScriptMessage) {
        self.f(scriptMessage)
    }
}

final class GameControllerNode: ViewControllerTracingNode {
    private var webView: WKWebView?
    
    private let account: Account
    var presentationData: PresentationData
    private let present: (ViewController, Any?) -> Void
    private let message: Message
    
    init(account: Account, presentationData: PresentationData, url: String, present: @escaping (ViewController, Any?) -> Void, message: Message) {
        self.account = account
        self.presentationData = presentationData
        self.present = present
        self.message = message
        
        super.init()
        
        self.backgroundColor = .white
        
        let js = "var TelegramWebviewProxyProto = function() {}; " +
            "TelegramWebviewProxyProto.prototype.postEvent = function(eventName, eventData) { " +
            "window.webkit.messageHandlers.performAction.postMessage({'eventName': eventName, 'eventData': eventData}); " +
            "}; " +
        "var TelegramWebviewProxy = new TelegramWebviewProxyProto();"
        
        let configuration = WKWebViewConfiguration()
        let userController = WKUserContentController()
        
        let userScript = WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        userController.addUserScript(userScript)
        
        userController.add(WeakGameScriptMessageHandler { [weak self] message in
            if let strongSelf = self {
                strongSelf.handleScriptMessage(message)
            }
        }, name: "performAction")
        
        configuration.userContentController = userController
        let webView = WKWebView(frame: CGRect(), configuration: configuration)
        if #available(iOSApplicationExtension 9.0, *) {
            webView.allowsLinkPreview = false
        }
        self.webView = webView

        self.view.addSubview(webView)
        
        if let parsedUrl = URL(string: url) {
            webView.load(URLRequest(url: parsedUrl))
        }
    }
    
    func containerLayoutUpdated(_ layout: ContainerViewLayout, navigationBarHeight: CGFloat, transition: ContainedViewLayoutTransition) {
        if let webView = self.webView {
            webView.frame = CGRect(origin: CGPoint(x: 0.0, y: navigationBarHeight), size: CGSize(width: layout.size.width, height: max(1.0, layout.size.height - navigationBarHeight)))
        }
    }
    
    func animateIn() {
        self.layer.animatePosition(from: CGPoint(x: self.layer.position.x, y: self.layer.position.y + self.layer.bounds.size.height), to: self.layer.position, duration: 0.5, timingFunction: kCAMediaTimingFunctionSpring)
    }
    
    func animateOut(completion: (() -> Void)? = nil) {
        self.layer.animatePosition(from: self.layer.position, to: CGPoint(x: self.layer.position.x, y: self.layer.position.y + self.layer.bounds.size.height), duration: 0.2, timingFunction: kCAMediaTimingFunctionEaseInEaseOut, removeOnCompletion: false, completion: { _ in
            completion?()
        })
    }
    
    private func shareData() -> (Peer, String)? {
        var botPeer: Peer?
        var gameName: String?
        for media in self.message.media {
            if let game = media as? TelegramMediaGame {
                inner: for attribute in self.message.attributes {
                    if let attribute = attribute as? InlineBotMessageAttribute, let peerId = attribute.peerId {
                        botPeer = self.message.peers[peerId]
                        break inner
                    }
                }
                if botPeer == nil {
                    botPeer = self.message.author
                }
                
                gameName = game.name
            }
        }
        if let botPeer = botPeer, let gameName = gameName {
            return (botPeer, gameName)
        }
        
        return nil
    }
    
    private func handleScriptMessage(_ message: WKScriptMessage) {
        guard let body = message.body as? [String: Any] else {
            return
        }
        
        guard let eventName = body["eventName"] as? String else {
            return
        }
        
        if eventName == "share_game" || eventName == "share_score" {
            if let (botPeer, gameName) = self.shareData(), let addressName = botPeer.addressName, !addressName.isEmpty, !gameName.isEmpty {
                if eventName == "share_score" {
                    self.present(ShareController(account: self.account, subject: .fromExternal({ [weak self] peerIds, text in
                        if let strongSelf = self {
                            let signals = peerIds.map { forwardGameWithScore(account: strongSelf.account, messageId: strongSelf.message.id, to: $0) }
                            return .single(.preparing) |> then(combineLatest(signals)
                                |> mapToSignal { _ -> Signal<ShareControllerExternalStatus, NoError> in return .complete() }) |> then(.single(.done))
                        } else {
                            return .single(.done)
                        }
                    }), saveToCameraRoll: false, showInChat: nil, externalShare: false, immediateExternalShare: false), nil)
                } else {
                    self.shareWithoutScore()
                }
            }
        }
    }
    
    func shareWithoutScore() {
        if let (botPeer, gameName) = self.shareData(), let addressName = botPeer.addressName, !addressName.isEmpty, !gameName.isEmpty {
            let url = "https://t.me/\(addressName)?game=\(gameName)"
            self.present(ShareController(account: self.account, subject: .url(url), saveToCameraRoll: false, showInChat: nil, externalShare: true), nil)
        }
    }
}
