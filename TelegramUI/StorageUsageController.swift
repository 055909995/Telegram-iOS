import Foundation
import Display
import SwiftSignalKit
import Postbox
import TelegramCore

private final class StorageUsageControllerArguments {
    let account: Account
    let updateKeepMedia: () -> Void
    let openClearAll: () -> Void
    let openPeerMedia: (PeerId) -> Void
    
    init(account: Account, updateKeepMedia: @escaping () -> Void, openClearAll: @escaping () -> Void, openPeerMedia: @escaping (PeerId) -> Void) {
        self.account = account
        self.updateKeepMedia = updateKeepMedia
        self.openClearAll = openClearAll
        self.openPeerMedia = openPeerMedia
    }
}

private enum StorageUsageSection: Int32 {
    case keepMedia
    case all
    case peers
}

private enum StorageUsageEntry: ItemListNodeEntry {
    case keepMedia(PresentationTheme, String, String)
    case keepMediaInfo(PresentationTheme, String)
    
    case collecting(PresentationTheme, String)
    
    case clearAll(PresentationTheme, String, String, Bool)
    
    case peersHeader(PresentationTheme, String)
    case peer(Int32, PresentationTheme, PresentationStrings, Peer, String)
    
    var section: ItemListSectionId {
        switch self {
            case .keepMedia, .keepMediaInfo:
                return StorageUsageSection.keepMedia.rawValue
            case .collecting, .clearAll:
                return StorageUsageSection.all.rawValue
            case .peersHeader, .peer:
                return StorageUsageSection.peers.rawValue
        }
    }
    
    var stableId: Int32 {
        switch self {
            case .keepMedia:
                return 0
            case .keepMediaInfo:
                return 1
            case .collecting:
                return 2
            case .clearAll:
                return 3
            case .peersHeader:
                return 4
            case let .peer(index, _, _, _, _):
                return 5 + index
        }
    }
    
    static func ==(lhs: StorageUsageEntry, rhs: StorageUsageEntry) -> Bool {
        switch lhs {
            case let .keepMedia(lhsTheme, lhsText, lhsValue):
                if case let .keepMedia(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .keepMediaInfo(lhsTheme, lhsText):
                if case let .keepMediaInfo(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .collecting(lhsTheme, lhsText):
                if case let .collecting(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .clearAll(lhsTheme, lhsText, lhsValue, lhsEnabled):
                if case let .clearAll(rhsTheme, rhsText, rhsValue, rhsEnabled) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue, lhsEnabled == rhsEnabled {
                    return true
                } else {
                    return false
                }
            case let .peersHeader(lhsTheme, lhsText):
                if case let .peersHeader(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .peer(lhsIndex, lhsTheme, lhsStrings, lhsPeer, lhsValue):
                if case let .peer(rhsIndex, rhsTheme, rhsStrings, rhsPeer, rhsValue) = rhs {
                    if lhsIndex != rhsIndex {
                        return false
                    }
                    if lhsTheme !== rhsTheme {
                        return false
                    }
                    if lhsStrings !== rhsStrings {
                        return false
                    }
                    if !arePeersEqual(lhsPeer, rhsPeer) {
                        return false
                    }
                    if lhsValue != rhsValue {
                        return false
                    }
                    return true
                } else {
                    return false
                }
        }
    }
    
    static func <(lhs: StorageUsageEntry, rhs: StorageUsageEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(_ arguments: StorageUsageControllerArguments) -> ListViewItem {
        switch self {
            case let .keepMedia(theme, text, value):
                return ItemListDisclosureItem(theme: theme, title: text, label: value, sectionId: self.section, style: .blocks, action: {
                    arguments.updateKeepMedia()
                })
            case let .keepMediaInfo(theme, text):
                return ItemListTextItem(theme: theme, text: .markdown(text), sectionId: self.section)
            case let .collecting(theme, text):
                return CalculatingCacheSizeItem(theme: theme, title: text, sectionId: self.section, style: .blocks)
            case let .peersHeader(theme, text):
                return ItemListSectionHeaderItem(theme: theme, text: text, sectionId: self.section)
            case let .clearAll(theme, text, value, enabled):
                return ItemListDisclosureItem(theme: theme, icon: nil, title: text, kind: enabled ? .generic : .disabled, label: value, sectionId: self.section, style: .blocks, disclosureStyle: .arrow, action: {
                    arguments.openClearAll()
                })
            case let .peer(_, theme, strings, peer, value):
                return ItemListPeerItem(theme: theme, strings: strings, account: arguments.account, peer: peer, aliasHandling: .threatSelfAsSaved, presence: nil, text: .none, label: .disclosure(value), editing: ItemListPeerItemEditing(editable: false, editing: false, revealed: false), switchValue: nil, enabled: true, sectionId: self.section, action: {
                    arguments.openPeerMedia(peer.id)
                }, setPeerIdWithRevealedOptions: { previousId, id in
                    
                }, removePeer: { _ in
                    
                })
        }
    }
}

private func stringForKeepMediaTimeout(strings: PresentationStrings, timeout: Int32) -> String {
    if timeout > 1 * 31 * 24 * 60 * 60 {
        return strings.MessageTimer_Forever
    } else {
        return timeIntervalString(strings: strings, value: timeout)
    }
}

private func storageUsageControllerEntries(presentationData: PresentationData, cacheSettings: CacheStorageSettings, cacheStats: CacheUsageStatsResult?) -> [StorageUsageEntry] {
    var entries: [StorageUsageEntry] = []
    
    entries.append(.keepMedia(presentationData.theme, presentationData.strings.Cache_KeepMedia, stringForKeepMediaTimeout(strings: presentationData.strings, timeout: cacheSettings.defaultCacheStorageTimeout)))
    entries.append(.keepMediaInfo(presentationData.theme, presentationData.strings.Cache_Help))
    
    var addedHeader = false
    
    if let cacheStats = cacheStats, case let .result(stats) = cacheStats {
        var peerSizes: Int64 = 0
        var statsByPeerId: [(PeerId, Int64)] = []
        for (peerId, categories) in stats.media {
            var combinedSize: Int64 = 0
            for (_, media) in categories {
                for (_, size) in media {
                    combinedSize += size
                }
            }
            statsByPeerId.append((peerId, combinedSize))
            peerSizes += combinedSize
        }
        
        let totalSize = Int(peerSizes + stats.otherSize + stats.cacheSize + stats.tempSize)
        
        entries.append(.clearAll(presentationData.theme, presentationData.strings.Cache_ClearCache, totalSize > 0 ? dataSizeString(totalSize) : presentationData.strings.Cache_ClearEmpty, totalSize > 0))
        
        var index: Int32 = 0
        for (peerId, size) in statsByPeerId.sorted(by: { $0.1 > $1.1 }) {
            if size >= 32 * 1024 {
                if let peer = stats.peers[peerId] {
                    if !addedHeader {
                        addedHeader = true
                        entries.append(.peersHeader(presentationData.theme, presentationData.strings.Cache_ByPeerHeader))
                    }
                    entries.append(.peer(index, presentationData.theme, presentationData.strings, peer, dataSizeString(Int(size))))
                    index += 1
                }
            }
        }
    } else {
        entries.append(.collecting(presentationData.theme, presentationData.strings.Cache_Indexing))
    }
    
    return entries
}

private func stringForCategory(strings: PresentationStrings, category: PeerCacheUsageCategory) -> String {
    switch category {
        case .image:
            return strings.Cache_Photos
        case .video:
            return strings.Cache_Videos
        case .audio:
            return strings.Cache_Music
        case .file:
            return strings.Cache_Files
    }
}

func storageUsageController(account: Account) -> ViewController {
    let cacheSettingsPromise = Promise<CacheStorageSettings>()
    cacheSettingsPromise.set(account.postbox.preferencesView(keys: [PreferencesKeys.cacheStorageSettings])
        |> map { view -> CacheStorageSettings in
            let cacheSettings: CacheStorageSettings
            if let value = view.values[PreferencesKeys.cacheStorageSettings] as? CacheStorageSettings {
                cacheSettings = value
            } else {
                cacheSettings = CacheStorageSettings.defaultSettings
            }
            
            return cacheSettings
        })
    
    var presentControllerImpl: ((ViewController) -> Void)?
    
    let statsPromise = Promise<CacheUsageStatsResult?>()
    statsPromise.set(.single(nil) |> then(collectCacheUsageStats(account: account) |> map(Optional.init)))
    
    let actionDisposables = DisposableSet()
    
    let clearDisposable = MetaDisposable()
    actionDisposables.add(clearDisposable)
    
    let arguments = StorageUsageControllerArguments(account: account, updateKeepMedia: {
        let presentationData = account.telegramApplicationContext.currentPresentationData.with { $0 }
        let controller = ActionSheetController(presentationTheme: presentationData.theme)
        let dismissAction: () -> Void = { [weak controller] in
            controller?.dismissAnimated()
        }
        let timeoutAction: (Int32) -> Void = { timeout in
            let _ = updateCacheStorageSettingsInteractively(postbox: account.postbox, { current in
                return current.withUpdatedDefaultCacheStorageTimeout(timeout)
            }).start()
        }
        let values: [Int32] = [
            7 * 24 * 60 * 60,
            1 * 31 * 24 * 60 * 60,
            Int32.max
        ]
        let timeoutItems: [ActionSheetItem] = values.map { value in
            return ActionSheetButtonItem(title: stringForKeepMediaTimeout(strings: presentationData.strings, timeout: value), action: {
                dismissAction()
                timeoutAction(value)
            })
        }
        controller.setItemGroups([
            ActionSheetItemGroup(items: timeoutItems),
            ActionSheetItemGroup(items: [ActionSheetButtonItem(title: presentationData.strings.Common_Cancel, action: { dismissAction() })])
        ])
        presentControllerImpl?(controller)
    }, openClearAll: {
        let _ = (statsPromise.get() |> take(1) |> deliverOnMainQueue).start(next: { [weak statsPromise] result in
            if let result = result, case let .result(stats) = result {
                let presentationData = account.telegramApplicationContext.currentPresentationData.with { $0 }
                let controller = ActionSheetController(presentationTheme: presentationData.theme)
                let dismissAction: () -> Void = { [weak controller] in
                    controller?.dismissAnimated()
                }
                
                var sizeIndex: [PeerCacheUsageCategory: (Bool, Int64)] = [:]
                var otherSize: (Bool, Int64) = (true, 0)
                
                for (_, categories) in stats.media {
                    for (category, media) in categories {
                        var combinedSize: Int64 = 0
                        for (_, size) in media {
                            combinedSize += size
                        }
                        if combinedSize != 0 {
                            sizeIndex[category] = (true, (sizeIndex[category]?.1 ?? 0) + combinedSize)
                        }
                    }
                }
                
                if stats.cacheSize + stats.otherSize + stats.tempSize > 10 * 1024 {
                    otherSize = (true, stats.cacheSize + stats.otherSize + stats.tempSize)
                }
                
                var itemIndex = 0
                
                let updateTotalSize: () -> Void = { [weak controller] in
                    controller?.updateItem(groupIndex: 0, itemIndex: itemIndex, { item in
                        let title: String
                        var filteredSize = sizeIndex.values.reduce(0, { $0 + ($1.0 ? $1.1 : 0) })
                        
                        if otherSize.0 {
                            filteredSize += otherSize.1
                        }
                        
                        if filteredSize == 0 {
                            title = presentationData.strings.Cache_ClearNone
                        } else {
                            title = presentationData.strings.Cache_Clear("\(dataSizeString(Int(filteredSize)))").0
                        }
                        
                        if let item = item as? ActionSheetButtonItem {
                            return ActionSheetButtonItem(title: title, color: filteredSize != 0 ? .accent : .disabled, enabled: filteredSize != 0, action: item.action)
                        }
                        return item
                    })
                }
                
                let toggleCheck: (PeerCacheUsageCategory?, Int) -> Void = { [weak controller] category, itemIndex in
                    if let category = category {
                        if let (value, size) = sizeIndex[category] {
                            sizeIndex[category] = (!value, size)
                        }
                    } else {
                        otherSize = (!otherSize.0, otherSize.1)
                    }
                    controller?.updateItem(groupIndex: 0, itemIndex: itemIndex, { item in
                        if let item = item as? ActionSheetCheckboxItem {
                            return ActionSheetCheckboxItem(title: item.title, label: item.label, value: !item.value, action: item.action)
                        }
                        return item
                    })
                    updateTotalSize()
                }
                var items: [ActionSheetItem] = []
                
                let validCategories: [PeerCacheUsageCategory] = [.image, .video, .audio, .file]
                
                var totalSize: Int64 = 0
                
                for categoryId in validCategories {
                    if let (_, size) = sizeIndex[categoryId] {
                        let categorySize: Int64 = size
                        totalSize += categorySize
                        let index = itemIndex
                        items.append(ActionSheetCheckboxItem(title: stringForCategory(strings: presentationData.strings, category: categoryId), label: dataSizeString(Int(categorySize)), value: true, action: { value in
                            toggleCheck(categoryId, index)
                        }))
                        itemIndex += 1
                    }
                }
                
                if otherSize.1 != 0 {
                    let index = itemIndex
                    items.append(ActionSheetCheckboxItem(title: presentationData.strings.Localization_LanguageOther, label: dataSizeString(Int(otherSize.1)), value: true, action: { value in
                        toggleCheck(nil, index)
                    }))
                    itemIndex += 1
                }
                
                if !items.isEmpty {
                    items.append(ActionSheetButtonItem(title: presentationData.strings.Cache_Clear("\(dataSizeString(Int(totalSize)))").0, action: {
                        if let statsPromise = statsPromise {
                            let clearCategories = sizeIndex.keys.filter({ sizeIndex[$0]!.0 })
                            
                            var clearMediaIds = Set<MediaId>()
                            
                            var media = stats.media
                            for (peerId, categories) in stats.media {
                                var categories = categories
                                for category in clearCategories {
                                    if let contents = categories[category] {
                                        for (mediaId, _) in contents {
                                            clearMediaIds.insert(mediaId)
                                        }
                                    }
                                    categories.removeValue(forKey: category)
                                }
                                
                                media[peerId] = categories
                            }
                            
                            var clearResourceIds = Set<WrappedMediaResourceId>()
                            for id in clearMediaIds {
                                if let ids = stats.mediaResourceIds[id] {
                                    for resourceId in ids {
                                        clearResourceIds.insert(WrappedMediaResourceId(resourceId))
                                    }
                                }
                            }
                            
                            var updatedOtherPaths = stats.otherPaths
                            var updatedOtherSize = stats.otherSize
                            var updatedCacheSize = stats.cacheSize
                            var updatedTempPaths = stats.tempPaths
                            var updatedTempSize = stats.tempSize
                            
                            var signal: Signal<Void, NoError> = clearCachedMediaResources(account: account, mediaResourceIds: clearResourceIds)
                            if otherSize.0 {
                                let removeTempFiles: Signal<Void, NoError> = Signal { subscriber in
                                    let fileManager = FileManager.default
                                    for path in stats.tempPaths {
                                        let _ = try? fileManager.removeItem(atPath: path)
                                    }
                                    
                                    subscriber.putCompletion()
                                    return EmptyDisposable
                                } |> runOn(Queue.concurrentDefaultQueue())
                                signal = signal |> then(account.postbox.mediaBox.removeOtherCachedResources(paths: stats.otherPaths)) |> then(removeTempFiles)
                            }
                            
                            if otherSize.0 {
                                updatedOtherPaths = []
                                updatedOtherSize = 0
                                updatedCacheSize = 0
                                updatedTempPaths = []
                                updatedTempSize = 0
                            }
                            
                            statsPromise.set(.single(.result(CacheUsageStats(media: media, mediaResourceIds: stats.mediaResourceIds, peers: stats.peers, otherSize: updatedOtherSize, otherPaths: updatedOtherPaths, cacheSize: updatedCacheSize, tempPaths: updatedTempPaths, tempSize: updatedTempSize))))
                            
                            clearDisposable.set(signal.start())
                        }
                        
                        dismissAction()
                    }))
                    
                    controller.setItemGroups([
                        ActionSheetItemGroup(items: items),
                        ActionSheetItemGroup(items: [ActionSheetButtonItem(title: presentationData.strings.Common_Cancel, action: { dismissAction() })])
                        ])
                    presentControllerImpl?(controller)
                }
            }
        })
    }, openPeerMedia: { peerId in
        let _ = (statsPromise.get() |> take(1) |> deliverOnMainQueue).start(next: { [weak statsPromise] result in
            if let result = result, case let .result(stats) = result {
                if let categories = stats.media[peerId] {
                    let presentationData = account.telegramApplicationContext.currentPresentationData.with { $0 }
                    let controller = ActionSheetController(presentationTheme: presentationData.theme)
                    let dismissAction: () -> Void = { [weak controller] in
                        controller?.dismissAnimated()
                    }
                    
                    var sizeIndex: [PeerCacheUsageCategory: (Bool, Int64)] = [:]
                    
                    var itemIndex = 0
                    
                    let updateTotalSize: () -> Void = { [weak controller] in
                        controller?.updateItem(groupIndex: 0, itemIndex: itemIndex, { item in
                            let title: String
                            let filteredSize = sizeIndex.values.reduce(0, { $0 + ($1.0 ? $1.1 : 0) })
                            
                            if filteredSize == 0 {
                                title = presentationData.strings.Cache_ClearNone
                            } else {
                                title = presentationData.strings.Cache_Clear("\(dataSizeString(Int(filteredSize)))").0
                            }
                            
                            if let item = item as? ActionSheetButtonItem {
                                return ActionSheetButtonItem(title: title, color: filteredSize != 0 ? .accent : .disabled, enabled: filteredSize != 0, action: item.action)
                            }
                            return item
                        })
                    }
                    
                    let toggleCheck: (PeerCacheUsageCategory, Int) -> Void = { [weak controller] category, itemIndex in
                        if let (value, size) = sizeIndex[category] {
                            sizeIndex[category] = (!value, size)
                        }
                        controller?.updateItem(groupIndex: 0, itemIndex: itemIndex, { item in
                            if let item = item as? ActionSheetCheckboxItem {
                                return ActionSheetCheckboxItem(title: item.title, label: item.label, value: !item.value, action: item.action)
                            }
                            return item
                        })
                        updateTotalSize()
                    }
                    var items: [ActionSheetItem] = []
                    
                    let validCategories: [PeerCacheUsageCategory] = [.image, .video, .audio, .file]

                    var totalSize: Int64 = 0
                    
                    for categoryId in validCategories {
                        if let media = categories[categoryId] {
                            var categorySize: Int64 = 0
                            for (_, size) in media {
                                categorySize += size
                            }
                            sizeIndex[categoryId] = (true, categorySize)
                            totalSize += categorySize
                            let index = itemIndex
                            items.append(ActionSheetCheckboxItem(title: stringForCategory(strings: presentationData.strings, category: categoryId), label: dataSizeString(Int(categorySize)), value: true, action: { value in
                                toggleCheck(categoryId, index)
                            }))
                            itemIndex += 1
                        }
                    }
                    
                    if !items.isEmpty {
                        items.append(ActionSheetButtonItem(title: presentationData.strings.Cache_Clear("\(dataSizeString(Int(totalSize)))").0, action: {
                            if let statsPromise = statsPromise {
                                var clearCategories = sizeIndex.keys.filter({ sizeIndex[$0]!.0 })
                                //var clearSize: Int64 = 0
                                
                                var clearMediaIds = Set<MediaId>()
                                
                                var media = stats.media
                                if var categories = media[peerId] {
                                    for category in clearCategories {
                                        if let contents = categories[category] {
                                            for (mediaId, size) in contents {
                                                clearMediaIds.insert(mediaId)
                                                //clearSize += size
                                            }
                                        }
                                        categories.removeValue(forKey: category)
                                    }
                                    
                                    media[peerId] = categories
                                }
                                
                                var clearResourceIds = Set<WrappedMediaResourceId>()
                                for id in clearMediaIds {
                                    if let ids = stats.mediaResourceIds[id] {
                                        for resourceId in ids {
                                            clearResourceIds.insert(WrappedMediaResourceId(resourceId))
                                        }
                                    }
                                }
                                
                                statsPromise.set(.single(.result(CacheUsageStats(media: media, mediaResourceIds: stats.mediaResourceIds, peers: stats.peers, otherSize: stats.otherSize, otherPaths: stats.otherPaths, cacheSize: stats.cacheSize, tempPaths: stats.tempPaths, tempSize: stats.tempSize))))
                                
                                clearDisposable.set(clearCachedMediaResources(account: account, mediaResourceIds: clearResourceIds).start())
                            }
                            
                            dismissAction()
                        }))
                        
                        controller.setItemGroups([
                            ActionSheetItemGroup(items: items),
                            ActionSheetItemGroup(items: [ActionSheetButtonItem(title: presentationData.strings.Common_Cancel, action: { dismissAction() })])
                        ])
                        presentControllerImpl?(controller)
                    }
                }
            }
        })
    })
    
    let signal = combineLatest((account.applicationContext as! TelegramApplicationContext).presentationData, cacheSettingsPromise.get(), statsPromise.get()) |> deliverOnMainQueue
        |> map { presentationData, cacheSettings, cacheStats -> (ItemListControllerState, (ItemListNodeState<StorageUsageEntry>, StorageUsageEntry.ItemGenerationArguments)) in
            
            let controllerState = ItemListControllerState(theme: presentationData.theme, title: .text(presentationData.strings.Cache_Title), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back), animateChanges: false)
            let listState = ItemListNodeState(entries: storageUsageControllerEntries(presentationData: presentationData, cacheSettings: cacheSettings, cacheStats: cacheStats), style: .blocks, emptyStateItem: nil, animateChanges: false)
            
            return (controllerState, (listState, arguments))
        } |> afterDisposed {
            actionDisposables.dispose()
        }
    
    let controller = ItemListController(account: account, state: signal)
    presentControllerImpl = { [weak controller] c in
        controller?.present(c, in: .window(.root), with: ViewControllerPresentationArguments(presentationAnimation: .modalSheet))
    }
    
    return controller
}
