import Foundation
import AsyncDisplayKit
import Display
import Postbox
import TelegramCore
import SwiftSignalKit

final class InstantPagePlayableVideoNode: ASDisplayNode, InstantPageNode {
    private let account: Account
    let media: InstantPageMedia
    private let interactive: Bool
    private let openMedia: (InstantPageMedia) -> Void
    
    private let videoNode: UniversalVideoNode
    
    private var currentSize: CGSize?
    
    private var fetchedDisposable = MetaDisposable()
    
    private var localIsVisible = false
    
    init(account: Account, webPage: TelegramMediaWebpage, media: InstantPageMedia, interactive: Bool, openMedia: @escaping  (InstantPageMedia) -> Void) {
        self.account = account
        self.media = media
        self.interactive = interactive
        self.openMedia = openMedia
        
        self.videoNode = UniversalVideoNode(postbox: account.postbox, audioSession: account.telegramApplicationContext.mediaManager.audioSession, manager: account.telegramApplicationContext.mediaManager.universalVideoManager, decoration: GalleryVideoDecoration(), content: NativeVideoContent(id: .instantPage(webPage.webpageId, media.media.id!), fileReference: .webPage(webPage: WebpageReference(webPage), media: media.media as! TelegramMediaFile), loopVideo: true, enableSound: false, fetchAutomatically: true), priority: .embedded, autoplay: true)
        
        super.init()
        
        self.addSubnode(self.videoNode)
        
        if let file = media.media as? TelegramMediaFile {
            self.fetchedDisposable.set(fetchedMediaResource(postbox: account.postbox, reference: AnyMediaReference.webPage(webPage: WebpageReference(webPage), media: file).resourceReference(file.resource)).start())
        }
    }
    
    deinit {
        self.fetchedDisposable.dispose()
    }
    
    override func didLoad() {
        super.didLoad()
        
        if self.interactive {
            self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tapGesture(_:))))
        }
    }
    
    func updateIsVisible(_ isVisible: Bool) {
        if self.localIsVisible != isVisible {
            self.localIsVisible = isVisible
            
            self.videoNode.canAttachContent = isVisible
        }
    }
    
    func update(strings: PresentationStrings, theme: InstantPageTheme) {
    }
    
    override func layout() {
        super.layout()
        
        let size = self.bounds.size
        
        if self.currentSize != size {
            self.currentSize = size
            
            self.videoNode.frame = CGRect(origin: CGPoint(), size: size)
            self.videoNode.updateLayout(size: size, transition: .immediate)
        }
    }
    
    func transitionNode(media: InstantPageMedia) -> (ASDisplayNode, () -> UIView?)? {
        if media == self.media {
            let videoNode = self.videoNode
            return (self.videoNode, { [weak videoNode] in
                return videoNode?.view.snapshotContentTree(unhide: true)
            })
        } else {
            return nil
        }
    }
    
    func updateHiddenMedia(media: InstantPageMedia?) {
        self.videoNode.isHidden = self.media == media
    }
    
    @objc func tapGesture(_ recognizer: UITapGestureRecognizer) {
        if case .ended = recognizer.state {
            self.openMedia(self.media)
        }
    }
}
