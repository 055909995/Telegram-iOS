import Foundation
import AsyncDisplayKit
import Display
import TelegramCore
import Postbox
import SwiftSignalKit

final class SettingsThemeWallpaperNode: ASDisplayNode {
    private var wallpaper: TelegramWallpaper?
    
    let buttonNode = HighlightTrackingButtonNode()
    let backgroundNode = ASDisplayNode()
    let imageNode = TransformImageNode()
    
    var pressed: (() -> Void)?
    
    override init() {
        self.imageNode.contentAnimations = [.subsequentUpdates]
        super.init()
        
        self.addSubnode(self.backgroundNode)
        self.addSubnode(self.imageNode)
        self.addSubnode(self.buttonNode)
        
        self.buttonNode.addTarget(self, action: #selector(self.buttonPressed), forControlEvents: .touchUpInside)
    }
    
    func setWallpaper(account: Account, wallpaper: TelegramWallpaper, size: CGSize) {
        self.buttonNode.frame = CGRect(origin: CGPoint(), size: size)
        self.backgroundNode.frame = CGRect(origin: CGPoint(), size: size)
        self.imageNode.frame = CGRect(origin: CGPoint(), size: size)
        
        if self.wallpaper != wallpaper {
            self.wallpaper = wallpaper
            switch wallpaper {
                case .builtin:
                    self.imageNode.isHidden = false
                    self.backgroundNode.isHidden = true
                    self.imageNode.setSignal(settingsBuiltinWallpaperImage(account: account))
                    let apply = self.imageNode.asyncLayout()(TransformImageArguments(corners: ImageCorners(), imageSize: CGSize(), boundingSize: size, intrinsicInsets: UIEdgeInsets()))
                    apply()
                case let .color(color):
                    self.imageNode.isHidden = true
                    self.backgroundNode.isHidden = false
                    self.backgroundNode.backgroundColor = UIColor(rgb: UInt32(bitPattern: color))
                case let .image(representations):
                    self.imageNode.isHidden = false
                    self.backgroundNode.isHidden = true
                    self.imageNode.setSignal(chatAvatarGalleryPhoto(account: account, representations: representations, autoFetchFullSize: true))
                    let apply = self.imageNode.asyncLayout()(TransformImageArguments(corners: ImageCorners(), imageSize: largestImageRepresentation(representations)!.dimensions.aspectFilled(size), boundingSize: size, intrinsicInsets: UIEdgeInsets()))
                    apply()
            }
        } else if let wallpaper = self.wallpaper {
            switch wallpaper {
                case .builtin:
                    let apply = self.imageNode.asyncLayout()(TransformImageArguments(corners: ImageCorners(), imageSize: CGSize(), boundingSize: size, intrinsicInsets: UIEdgeInsets()))
                    apply()
                case .color:
                    break
                case let .image(representations):
                    let apply = self.imageNode.asyncLayout()(TransformImageArguments(corners: ImageCorners(), imageSize: largestImageRepresentation(representations)!.dimensions.aspectFilled(size), boundingSize: size, intrinsicInsets: UIEdgeInsets()))
                    apply()
            }
        }
    }
    
    @objc func buttonPressed() {
        self.pressed?()
    }
}
