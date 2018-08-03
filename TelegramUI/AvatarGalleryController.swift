import Foundation
import Display
import QuickLook
import Postbox
import SwiftSignalKit
import AsyncDisplayKit
import TelegramCore

enum AvatarGalleryEntry: Equatable {
    case topImage([TelegramMediaImageRepresentation], GalleryItemIndexData?)
    case image(TelegramMediaImage, GalleryItemIndexData?)
    
    var representations: [TelegramMediaImageRepresentation] {
        switch self {
            case let .topImage(representations, _):
                return representations
            case let .image(image, _):
                return image.representations
        }
    }
    
    var indexData: GalleryItemIndexData? {
        switch self {
            case let .topImage(_, indexData):
                return indexData
            case let .image(_, indexData):
                return indexData
        }
    }
    
    static func ==(lhs: AvatarGalleryEntry, rhs: AvatarGalleryEntry) -> Bool {
        switch lhs {
            case let .topImage(lhsRepresentations, lhsIndexData):
                if case let .topImage(rhsRepresentations, rhsIndexData) = rhs, lhsRepresentations == rhsRepresentations, lhsIndexData == rhsIndexData {
                    return true
                } else {
                    return false
                }
            case let .image(lhsImage, lhsIndexData):
                if case let .image(rhsImage, rhsIndexData) = rhs, lhsImage.isEqual(rhsImage), lhsIndexData == rhsIndexData {
                    return true
                } else {
                    return false
                }
        }
    }
}

final class AvatarGalleryControllerPresentationArguments {
    let animated: Bool
    let transitionArguments: (AvatarGalleryEntry) -> GalleryTransitionArguments?
    
    init(animated: Bool = true, transitionArguments: @escaping (AvatarGalleryEntry) -> GalleryTransitionArguments?) {
        self.animated = animated
        self.transitionArguments = transitionArguments
    }
}

private func initialAvatarGalleryEntries(peer: Peer) -> [AvatarGalleryEntry]{
    var initialEntries: [AvatarGalleryEntry] = []
    if let user = peer as? TelegramUser, !user.photo.isEmpty {
        initialEntries.append(.topImage(user.photo, nil))
    } else if let group = peer as? TelegramGroup {
        initialEntries.append(.topImage(group.photo, nil))
    } else if let channel = peer as? TelegramChannel {
        initialEntries.append(.topImage(channel.photo, nil))
    }
    return initialEntries
}

func fetchedAvatarGalleryEntries(account: Account, peer: Peer) -> Signal<[AvatarGalleryEntry], NoError> {
    return requestPeerPhotos(account: account, peerId: peer.id) |> map { photos -> [AvatarGalleryEntry] in
        var result: [AvatarGalleryEntry] = []
        let initialEntries = initialAvatarGalleryEntries(peer: peer)
        if photos.isEmpty {
            result = initialEntries
        } else {
            var index: Int32 = 0
            for photo in photos {
                let indexData = GalleryItemIndexData(position: index, totalCount: Int32(photos.count))
                if result.isEmpty, let first = initialEntries.first {
                    let image = TelegramMediaImage(imageId: photo.image.imageId, representations: first.representations, reference: photo.reference, partialReference: nil)
                    result.append(.image(image, indexData))
                } else {
                    result.append(.image(photo.image, indexData))
                }
                index += 1
            }
        }
        return result
    }
}

class AvatarGalleryController: ViewController {
    private var galleryNode: GalleryControllerNode {
        return self.displayNode as! GalleryControllerNode
    }
    
    private let account: Account
    private let peer: Peer
    
    private var presentationData: PresentationData
    
    private let _ready = Promise<Bool>()
    override var ready: Promise<Bool> {
        return self._ready
    }
    private var didSetReady = false
    
    private var adjustedForInitialPreviewingLayout = false
    
    private let disposable = MetaDisposable()
    
    private var entries: [AvatarGalleryEntry] = []
    private var centralEntryIndex: Int?
    
    private let centralItemTitle = Promise<String>()
    private let centralItemTitleView = Promise<UIView?>()
    private let centralItemNavigationStyle = Promise<GalleryItemNodeNavigationStyle>()
    private let centralItemFooterContentNode = Promise<GalleryFooterContentNode?>()
    private let centralItemAttributesDisposable = DisposableSet();
    
    private let _hiddenMedia = Promise<AvatarGalleryEntry?>(nil)
    var hiddenMedia: Signal<AvatarGalleryEntry?, NoError> {
        return self._hiddenMedia.get()
    }
    
    private let replaceRootController: (ViewController, ValuePromise<Bool>?) -> Void
    
    init(account: Account, peer: Peer, remoteEntries: Promise<[AvatarGalleryEntry]>? = nil, replaceRootController: @escaping (ViewController, ValuePromise<Bool>?) -> Void, synchronousLoad: Bool = false) {
        self.account = account
        self.peer = peer
        self.presentationData = account.telegramApplicationContext.currentPresentationData.with { $0 }
        self.replaceRootController = replaceRootController
        
        super.init(navigationBarPresentationData: NavigationBarPresentationData(theme: GalleryController.darkNavigationTheme, strings: NavigationBarStrings(presentationStrings: self.presentationData.strings)))
        
        let backItem = UIBarButtonItem(backButtonAppearanceWithTitle: self.presentationData.strings.Common_Back, target: self, action: #selector(self.donePressed))
        self.navigationItem.leftBarButtonItem = backItem
        
        self.statusBar.statusBarStyle = .White
        
        let remoteEntriesSignal: Signal<[AvatarGalleryEntry], NoError>
        if let remoteEntries = remoteEntries {
            remoteEntriesSignal = remoteEntries.get()
        } else {
            remoteEntriesSignal = fetchedAvatarGalleryEntries(account: account, peer: peer)
        }
        
        let entriesSignal: Signal<[AvatarGalleryEntry], NoError> = .single(initialAvatarGalleryEntries(peer: peer)) |> then(remoteEntriesSignal)
        
        let presentationData = self.presentationData
        
        let semaphore: DispatchSemaphore?
        if synchronousLoad {
            semaphore = DispatchSemaphore(value: 0)
        } else {
            semaphore = nil
        }
        
        let syncResult = Atomic<(Bool, (() -> Void)?)>(value: (false, nil))
        
        self.disposable.set(entriesSignal.start(next: { [weak self] entries in
            let f: () -> Void = {
                if let strongSelf = self {
                    strongSelf.entries = entries
                    strongSelf.centralEntryIndex = 0
                    if strongSelf.isViewLoaded {
                        strongSelf.galleryNode.pager.replaceItems(strongSelf.entries.map({ entry in PeerAvatarImageGalleryItem(account: account, peer: peer, strings: presentationData.strings, entry: entry, delete: strongSelf.peer.id == strongSelf.account.peerId ? {
                            self?.deleteEntry(entry)
                            } : nil) }), centralItemIndex: 0, keepFirst: true)
                        
                        let ready = strongSelf.galleryNode.pager.ready() |> timeout(2.0, queue: Queue.mainQueue(), alternate: .single(Void())) |> afterNext { [weak strongSelf] _ in
                            strongSelf?.didSetReady = true
                        }
                        strongSelf._ready.set(ready |> map { true })
                    }
                }
            }
            
            var process = false
            let _ = syncResult.modify { processed, _ in
                if !processed {
                    return (processed, f)
                }
                process = true
                return (true, nil)
            }
            semaphore?.signal()
            if process {
                Queue.mainQueue().async {
                    f()
                }
            }
        }))
        
        if let semaphore = semaphore {
            let _ = semaphore.wait(timeout: DispatchTime.now() + 1.0)
        }
        
        var syncResultApply: (() -> Void)?
        let _ = syncResult.modify { processed, f in
            syncResultApply = f
            return (true, nil)
        }
        
        syncResultApply?()
        
        self.centralItemAttributesDisposable.add(self.centralItemTitle.get().start(next: { [weak self] title in
            if let strongSelf = self {
                strongSelf.navigationItem.setTitle(title, animated: strongSelf.navigationItem.title?.isEmpty ?? true)
            }
        }))
        
        self.centralItemAttributesDisposable.add(self.centralItemTitleView.get().start(next: { [weak self] titleView in
            self?.navigationItem.titleView = titleView
        }))
        
        self.centralItemAttributesDisposable.add(self.centralItemFooterContentNode.get().start(next: { [weak self] footerContentNode in
            self?.galleryNode.updatePresentationState({
                $0.withUpdatedFooterContentNode(footerContentNode)
            }, transition: .immediate)
        }))
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.disposable.dispose()
        self.centralItemAttributesDisposable.dispose()
    }
    
    @objc func donePressed() {
        self.dismiss(forceAway: false)
    }
    
    private func dismiss(forceAway: Bool) {
        var animatedOutNode = true
        var animatedOutInterface = false
        
        let completion = { [weak self] in
            if animatedOutNode && animatedOutInterface {
                self?._hiddenMedia.set(.single(nil))
                self?.presentingViewController?.dismiss(animated: false, completion: nil)
            }
        }
        
        if let centralItemNode = self.galleryNode.pager.centralItemNode(), let presentationArguments = self.presentationArguments as? AvatarGalleryControllerPresentationArguments {
            if !self.entries.isEmpty {
                if centralItemNode.index == 0, let transitionArguments = presentationArguments.transitionArguments(self.entries[centralItemNode.index]), !forceAway {
                    animatedOutNode = false
                    centralItemNode.animateOut(to: transitionArguments.transitionNode, addToTransitionSurface: transitionArguments.addToTransitionSurface, completion: {
                        animatedOutNode = true
                        completion()
                    })
                }
            }
        }
        
        self.galleryNode.animateOut(animateContent: animatedOutNode, completion: {
            animatedOutInterface = true
            completion()
        })
    }
    
    override func loadDisplayNode() {
        let controllerInteraction = GalleryControllerInteraction(presentController: { [weak self] controller, arguments in
            if let strongSelf = self {
                strongSelf.present(controller, in: .window(.root), with: arguments)
            }
        }, dismissController: { [weak self] in
            self?.dismiss(forceAway: true)
        }, replaceRootController: { [weak self] controller, ready in
            if let strongSelf = self {
                strongSelf.replaceRootController(controller, ready)
            }
        })
        self.displayNode = GalleryControllerNode(controllerInteraction: controllerInteraction)
        self.displayNodeDidLoad()
        
        self.galleryNode.statusBar = self.statusBar
        self.galleryNode.navigationBar = self.navigationBar
        
        self.galleryNode.transitionDataForCentralItem = { [weak self] in
            if let strongSelf = self {
                if let centralItemNode = strongSelf.galleryNode.pager.centralItemNode(), let presentationArguments = strongSelf.presentationArguments as? AvatarGalleryControllerPresentationArguments {
                    if centralItemNode.index != 0 {
                        return nil
                    }
                    if let transitionArguments = presentationArguments.transitionArguments(strongSelf.entries[centralItemNode.index]) {
                        return (transitionArguments.transitionNode, transitionArguments.addToTransitionSurface)
                    }
                }
            }
            return nil
        }
        self.galleryNode.dismiss = { [weak self] in
            self?._hiddenMedia.set(.single(nil))
            self?.presentingViewController?.dismiss(animated: false, completion: nil)
        }
        
        let presentationData = self.presentationData
        self.galleryNode.pager.replaceItems(self.entries.map({ entry in PeerAvatarImageGalleryItem(account: self.account, peer: peer, strings: presentationData.strings, entry: entry, delete: self.peer.id == self.account.peerId ? { [weak self] in
            self?.deleteEntry(entry)
            } : nil) }), centralItemIndex: self.centralEntryIndex)
        
        self.galleryNode.pager.centralItemIndexUpdated = { [weak self] index in
            if let strongSelf = self {
                var hiddenItem: AvatarGalleryEntry?
                if let index = index {
                    hiddenItem = strongSelf.entries[index]
                    
                    if let node = strongSelf.galleryNode.pager.centralItemNode() {
                        strongSelf.centralItemTitle.set(node.title())
                        strongSelf.centralItemTitleView.set(node.titleView())
                        strongSelf.centralItemNavigationStyle.set(node.navigationStyle())
                        strongSelf.centralItemFooterContentNode.set(node.footerContent())
                    }
                }
                if strongSelf.didSetReady {
                    strongSelf._hiddenMedia.set(.single(hiddenItem))
                }
            }
        }
        
        let ready = self.galleryNode.pager.ready() |> timeout(2.0, queue: Queue.mainQueue(), alternate: .single(Void())) |> afterNext { [weak self] _ in
            self?.didSetReady = true
        }
        self._ready.set(ready |> map { true })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        var nodeAnimatesItself = false
        
        if let centralItemNode = self.galleryNode.pager.centralItemNode(), let presentationArguments = self.presentationArguments as? AvatarGalleryControllerPresentationArguments {
            self.centralItemTitle.set(centralItemNode.title())
            self.centralItemTitleView.set(centralItemNode.titleView())
            self.centralItemNavigationStyle.set(centralItemNode.navigationStyle())
            self.centralItemFooterContentNode.set(centralItemNode.footerContent())
            
            if let transitionArguments = presentationArguments.transitionArguments(self.entries[centralItemNode.index]) {
                nodeAnimatesItself = true
                if presentationArguments.animated {
                    centralItemNode.animateIn(from: transitionArguments.transitionNode, addToTransitionSurface: transitionArguments.addToTransitionSurface)
                }
                
                self._hiddenMedia.set(.single(self.entries[centralItemNode.index]))
            }
        }
        
        if !self.isPresentedInPreviewingContext() {
            self.galleryNode.setControlsHidden(false, animated: false)
            if let presentationArguments = self.presentationArguments as? AvatarGalleryControllerPresentationArguments {
                if presentationArguments.animated {
                    self.galleryNode.animateIn(animateContent: !nodeAnimatesItself)
                }
            }
        }
    }
    
    override func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        
        self.galleryNode.frame = CGRect(origin: CGPoint(), size: layout.size)
        self.galleryNode.containerLayoutUpdated(layout, navigationBarHeight: self.navigationHeight, transition: transition)
        
        if !self.adjustedForInitialPreviewingLayout && self.isPresentedInPreviewingContext() {
            self.adjustedForInitialPreviewingLayout = true
            self.galleryNode.setControlsHidden(true, animated: false)
            if let centralItemNode = self.galleryNode.pager.centralItemNode(), let itemSize = centralItemNode.contentSize() {
                self.preferredContentSize = itemSize.aspectFitted(self.view.bounds.size)
                self.containerLayoutUpdated(ContainerViewLayout(size: self.preferredContentSize, metrics: LayoutMetrics(), intrinsicInsets: UIEdgeInsets(), safeInsets: UIEdgeInsets(), statusBarHeight: nil, inputHeight: nil, standardInputHeight: 216.0, inputHeightIsInteractivellyChanging: false), transition: .immediate)
                centralItemNode.activateAsInitial()
            }
        }
    }
    
    private func deleteEntry(_ entry: AvatarGalleryEntry) {
        switch entry {
            case .topImage:
                break
            case let .image(image, _):
                if let reference = image.reference {
                    let _ = removeAccountPhoto(network: self.account.network, reference: reference).start()
                }
                if entry == self.entries.first {
                    self.dismiss(forceAway: true)
                } else {
                    if let index = self.entries.index(of: entry) {
                        self.entries.remove(at: index)
                        self.galleryNode.pager.transaction(GalleryPagerTransaction(deleteItems: [index], insertItems: [], updateItems: [], focusOnItem: index - 1))
                    }
                }
        }
    }
}
