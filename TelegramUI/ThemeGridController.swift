import Foundation
import Display
import AsyncDisplayKit
import Postbox
import TelegramCore
import SwiftSignalKit

final class ThemeGridController: ViewController {
    private var controllerNode: ThemeGridControllerNode {
        return self.displayNode as! ThemeGridControllerNode
    }
    
    private let _ready = Promise<Bool>()
    override var ready: Promise<Bool> {
        return self._ready
    }
    
    private let account: Account
    
    private var presentationData: PresentationData
    private var presentationDataDisposable: Disposable?
    
    init(account: Account) {
        self.account = account
        self.presentationData = account.telegramApplicationContext.currentPresentationData.with { $0 }
        
        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData))
        
        self.title = self.presentationData.strings.Wallpaper_Title
        self.statusBar.statusBarStyle = self.presentationData.theme.rootController.statusBar.style.style
        
        self.scrollToTop = { [weak self] in
            self?.controllerNode.scrollToTop()
        }
        
        self.presentationDataDisposable = (account.telegramApplicationContext.presentationData
            |> deliverOnMainQueue).start(next: { [weak self] presentationData in
                if let strongSelf = self {
                    let previousTheme = strongSelf.presentationData.theme
                    let previousStrings = strongSelf.presentationData.strings
                    
                    strongSelf.presentationData = presentationData
                    
                    if previousTheme !== presentationData.theme || previousStrings !== presentationData.strings {
                        strongSelf.updateThemeAndStrings()
                    }
                }
            })
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.presentationDataDisposable?.dispose()
    }
    
    private func updateThemeAndStrings() {
        self.title = self.presentationData.strings.Wallpaper_Title
        
        self.statusBar.statusBarStyle = self.presentationData.theme.rootController.statusBar.style.style
        self.navigationBar?.updatePresentationData(NavigationBarPresentationData(presentationData: self.presentationData))
        
        if self.isNodeLoaded {
            self.controllerNode.updatePresentationData(self.presentationData)
        }
    }
    
    override func loadDisplayNode() {
        self.displayNode = ThemeGridControllerNode(account: self.account, presentationData: self.presentationData, present: { [weak self] controller, arguments in
            self?.present(controller, in: .window(.root), with: arguments)
        }, selectCustomWallpaper: { [weak self] in
            if let strongSelf = self {
                strongSelf.present(legacyImagePicker(theme: strongSelf.presentationData.theme, completion: { image in
                    if let strongSelf = self, let image = image {
                        strongSelf.present(legacyWallpaperEditor(theme: strongSelf.presentationData.theme, image: image, completion: { image in
                            if let image = image {
                                self?.applyCustomWallpaperImage(image)
                            }
                        }), in: .window(.root))
                    }
                }), in: .window(.root))
            }
        })
        self._ready.set(self.controllerNode.ready.get())
        
        self.displayNodeDidLoad()
    }
    
    private func applyCustomWallpaperImage(_ image: UIImage) {
        guard let data = UIImageJPEGRepresentation(image, 0.8) else {
            return
        }
        
        let resource = LocalFileMediaResource(fileId: arc4random64())
        self.account.postbox.mediaBox.storeResourceData(resource.id, data: data)
        
        let wallpaper: TelegramWallpaper = .image([TelegramMediaImageRepresentation(dimensions: image.size, resource: resource)])
        let _ = (updatePresentationThemeSettingsInteractively(postbox: self.account.postbox, { current in
            if case .color(0x000000) = wallpaper {
                return PresentationThemeSettings(chatWallpaper: wallpaper, theme: current.theme, fontSize: .regular)
            }
            
            return PresentationThemeSettings(chatWallpaper: wallpaper, theme: current.theme, fontSize: current.fontSize)
        }) |> deliverOnMainQueue).start(completed: { [weak self] in
            let _ = (self?.navigationController as? NavigationController)?.popViewController(animated: true)
        })
    }
    
    override func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        
        self.controllerNode.containerLayoutUpdated(layout, navigationBarHeight: self.navigationHeight, transition: transition)
    }
}
