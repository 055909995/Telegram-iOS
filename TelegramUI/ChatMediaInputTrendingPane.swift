import Foundation
import AsyncDisplayKit
import Display
import Postbox
import TelegramCore
import SwiftSignalKit

final class TrendingPaneInteraction {
    let installPack: (ItemCollectionInfo) -> Void
    let openPack: (ItemCollectionInfo) -> Void
    
    init(installPack: @escaping (ItemCollectionInfo) -> Void, openPack: @escaping (ItemCollectionInfo) -> Void) {
        self.installPack = installPack
        self.openPack = openPack
    }
}

private final class TrendingPaneEntry: Identifiable, Comparable {
    let index: Int
    let info: StickerPackCollectionInfo
    let topItems: [StickerPackItem]
    let installed: Bool
    let unread: Bool
    
    init(index: Int, info: StickerPackCollectionInfo, topItems: [StickerPackItem], installed: Bool, unread: Bool) {
        self.index = index
        self.info = info
        self.topItems = topItems
        self.installed = installed
        self.unread = unread
    }
    
    var stableId: ItemCollectionId {
        return self.info.id
    }
    
    static func ==(lhs: TrendingPaneEntry, rhs: TrendingPaneEntry) -> Bool {
        if lhs.index != rhs.index {
            return false
        }
        if lhs.info != rhs.info {
            return false
        }
        if lhs.topItems != rhs.topItems {
            return false
        }
        if lhs.installed != rhs.installed {
            return false
        }
        return true
    }
    
    static func <(lhs: TrendingPaneEntry, rhs: TrendingPaneEntry) -> Bool {
        return lhs.index < rhs.index
    }
    
    func item(account: Account, theme: PresentationTheme, strings: PresentationStrings, interaction: TrendingPaneInteraction) -> ListViewItem {
        return MediaInputPaneTrendingItem(account: account, theme: theme, strings: strings, interaction: interaction, info: self.info, topItems: self.topItems, installed: self.installed, unread: self.unread)
    }
}

private struct TrendingPaneTransition {
    let deletions: [ListViewDeleteItem]
    let insertions: [ListViewInsertItem]
    let updates: [ListViewUpdateItem]
    let initial: Bool
}

private func preparedTransition(from fromEntries: [TrendingPaneEntry], to toEntries: [TrendingPaneEntry], account: Account, theme: PresentationTheme, strings: PresentationStrings, interaction: TrendingPaneInteraction, initial: Bool) -> TrendingPaneTransition {
    let (deleteIndices, indicesAndItems, updateIndices) = mergeListsStableWithUpdates(leftList: fromEntries, rightList: toEntries)
    
    let deletions = deleteIndices.map { ListViewDeleteItem(index: $0, directionHint: nil) }
    let insertions = indicesAndItems.map { ListViewInsertItem(index: $0.0, previousIndex: $0.2, item: $0.1.item(account: account, theme: theme, strings: strings, interaction: interaction), directionHint: nil) }
    let updates = updateIndices.map { ListViewUpdateItem(index: $0.0, previousIndex: $0.2, item: $0.1.item(account: account, theme: theme, strings: strings, interaction: interaction), directionHint: nil) }
    
    return TrendingPaneTransition(deletions: deletions, insertions: insertions, updates: updates, initial: initial)
}

private func trendingPaneEntries(trendingEntries: [FeaturedStickerPackItem], installedPacks: Set<ItemCollectionId>) -> [TrendingPaneEntry] {
    var result: [TrendingPaneEntry] = []
    var index = 0
    for item in trendingEntries {
        result.append(TrendingPaneEntry(index: index, info: item.info, topItems: item.topItems, installed: installedPacks.contains(item.info.id), unread: item.unread))
        index += 1
    }
    return result
}

final class ChatMediaInputTrendingPane: ChatMediaInputPane {
    private let account: Account
    private let controllerInteraction: ChatControllerInteraction
    
    private let listNode: ListView
    
    private var enqueuedTransitions: [TrendingPaneTransition] = []
    private var validLayout: (CGSize, CGFloat)?
    
    private var disposable: Disposable?
    private var isActivated = false
    
    init(account: Account, controllerInteraction: ChatControllerInteraction) {
        self.account = account
        self.controllerInteraction = controllerInteraction
        
        self.listNode = ListView()
        
        super.init()
        
        self.addSubnode(self.listNode)
    }
    
    deinit {
        self.disposable?.dispose()
    }
    
    func activate() {
        if self.isActivated {
            return
        }
        self.isActivated = true
        
        let presentationData = self.account.telegramApplicationContext.currentPresentationData.with { $0 }
        
        let interaction = TrendingPaneInteraction(installPack: { [weak self] info in
            if let strongSelf = self, let info = info as? StickerPackCollectionInfo {
                let _ = (loadedStickerPack(postbox: strongSelf.account.postbox, network: strongSelf.account.network, reference: .id(id: info.id.id, accessHash: info.accessHash))
                |> mapToSignal { result -> Signal<Void, NoError> in
                    switch result {
                        case let .result(info, items, installed):
                            if installed {
                                return .complete()
                            } else {
                                return addStickerPackInteractively(postbox: strongSelf.account.postbox, info: info, items: items)
                            }
                        case .fetching:
                            break
                        case .none:
                            break
                    }
                    return .complete()
                }).start()
            }
        }, openPack: { [weak self] info in
            if let strongSelf = self, let info = info as? StickerPackCollectionInfo {
                strongSelf.controllerInteraction.presentController(StickerPackPreviewController(account: strongSelf.account, stickerPack: .id(id: info.id.id, accessHash: info.accessHash)), ViewControllerPresentationArguments(presentationAnimation: .modalSheet))
            }
        })
        
        let previousEntries = Atomic<[TrendingPaneEntry]?>(value: nil)
        let account = self.account
        self.disposable = (combineLatest(account.viewTracker.featuredStickerPacks(), account.postbox.combinedView(keys: [.itemCollectionInfos(namespaces: [Namespaces.ItemCollection.CloudStickerPacks])]))
            |> map { trendingEntries, view -> TrendingPaneTransition in
                var installedPacks = Set<ItemCollectionId>()
                if let stickerPacksView = view.views[.itemCollectionInfos(namespaces: [Namespaces.ItemCollection.CloudStickerPacks])] as? ItemCollectionInfosView {
                    if let packsEntries = stickerPacksView.entriesByNamespace[Namespaces.ItemCollection.CloudStickerPacks] {
                        for entry in packsEntries {
                            installedPacks.insert(entry.id)
                        }
                    }
                }
                let entries = trendingPaneEntries(trendingEntries: trendingEntries, installedPacks: installedPacks)
                let previous = previousEntries.swap(entries)
                
                return preparedTransition(from: previous ?? [], to: entries, account: account, theme: presentationData.theme, strings: presentationData.strings, interaction: interaction, initial: previous == nil)
            }
            |> deliverOnMainQueue).start(next: { [weak self] transition in
                self?.enqueueTransition(transition)
            })
    }
    
    override func updateLayout(size: CGSize, topInset: CGFloat, bottomInset: CGFloat, transition: ContainedViewLayoutTransition) {
        let hadValidLayout = self.validLayout != nil
        self.validLayout = (size, bottomInset)
        
        transition.updateFrame(node: self.listNode, frame: CGRect(origin: CGPoint(), size: size))
        
        var duration: Double = 0.0
        var listViewCurve: ListViewAnimationCurve = .Default
        switch transition {
            case .immediate:
                break
            case let .animated(animationDuration, animationCurve):
                duration = animationDuration
                switch animationCurve {
                    case .easeInOut:
                        listViewCurve = .Default
                    case .spring:
                        listViewCurve = .Spring(duration: duration)
                }
        }
        
        self.listNode.transaction(deleteIndices: [], insertIndicesAndItems: [], updateIndicesAndItems: [], options: [.Synchronous], scrollToItem: nil, updateSizeAndInsets: ListViewUpdateSizeAndInsets(size: size, insets: UIEdgeInsets(top: topInset, left: 0.0, bottom: bottomInset, right: 0.0), duration: duration, curve: listViewCurve), stationaryItemRange: nil, updateOpaqueState: nil, completion: { _ in })
        
        if !hadValidLayout {
            while !self.enqueuedTransitions.isEmpty {
                self.dequeueTransition()
            }
        }
    }
    
    private func enqueueTransition(_ transition: TrendingPaneTransition) {
        enqueuedTransitions.append(transition)
        
        if self.validLayout != nil {
            while !self.enqueuedTransitions.isEmpty {
                self.dequeueTransition()
            }
        }
    }
    
    override func willEnterHierarchy() {
        super.willEnterHierarchy()
        
        self.activate()
    }
    
    private func dequeueTransition() {
        if let transition = self.enqueuedTransitions.first {
            self.enqueuedTransitions.remove(at: 0)
            
            let options = ListViewDeleteAndInsertOptions()
            if transition.initial {
                //options.insert(.Synchronous)
                //options.insert(.LowLatency)
            } else {
                //options.insert(.AnimateTopItemPosition)
                //options.insert(.AnimateCrossfade)
            }
            
            self.listNode.transaction(deleteIndices: transition.deletions, insertIndicesAndItems: transition.insertions, updateIndicesAndItems: transition.updates, options: options, updateSizeAndInsets: nil, updateOpaqueState: nil, completion: { [weak self] _ in
            })
        }
    }
}
