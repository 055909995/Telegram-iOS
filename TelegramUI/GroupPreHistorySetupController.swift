import Foundation
import Display
import SwiftSignalKit
import Postbox
import TelegramCore

private final class GroupPreHistorySetupArguments {
    let toggle: (Bool) -> Void
    
    init(toggle: @escaping (Bool) -> Void) {
        self.toggle = toggle
    }
}

private enum GroupPreHistorySetupSection: Int32 {
    case info
}

private enum GroupPreHistorySetupEntry: ItemListNodeEntry {
    case header(PresentationTheme, String)
    case visible(PresentationTheme, String, Bool)
    case hidden(PresentationTheme, String, Bool)
    case info(PresentationTheme, String)
    
    var section: ItemListSectionId {
        return GroupPreHistorySetupSection.info.rawValue
    }
    
    var stableId: Int32 {
        switch self {
            case .header:
                return 0
            case .visible:
                return 1
            case .hidden:
                return 2
            case .info:
                return 3
        }
    }
    
    static func ==(lhs: GroupPreHistorySetupEntry, rhs: GroupPreHistorySetupEntry) -> Bool {
        switch lhs {
            case let .header(lhsTheme, lhsText):
                if case let .header(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .visible(lhsTheme, lhsText, lhsValue):
                if case let .visible(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .hidden(lhsTheme, lhsText, lhsValue):
                if case let .hidden(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .info(lhsTheme, lhsText):
                if case let .info(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
        }
    }
    
    static func <(lhs: GroupPreHistorySetupEntry, rhs: GroupPreHistorySetupEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(_ arguments: GroupPreHistorySetupArguments) -> ListViewItem {
        switch self {
            case let .header(theme, text):
                return ItemListSectionHeaderItem(theme: theme, text: text, sectionId: self.section)
            case let .visible(theme, text, value):
                return ItemListCheckboxItem(theme: theme, title: text, style: .left, checked: value, zeroSeparatorInsets: false, sectionId: self.section, action: {
                    arguments.toggle(true)
                })
            case let .hidden(theme, text, value):
                return ItemListCheckboxItem(theme: theme, title: text, style: .left, checked: value, zeroSeparatorInsets: false, sectionId: self.section, action: {
                    arguments.toggle(false)
                })
            case let .info(theme, text):
                return ItemListTextItem(theme: theme, text: .markdown(text), sectionId: self.section)
        }
    }
}

private struct GroupPreHistorySetupState: Equatable {
    var changedValue: Bool?
    var applyingSetting: Bool = false
}

private func groupPreHistorySetupEntries(presentationData: PresentationData, defaultValue: Bool, state: GroupPreHistorySetupState) -> [GroupPreHistorySetupEntry] {
    var entries: [GroupPreHistorySetupEntry] = []
    let value = state.changedValue ?? defaultValue
    entries.append(.header(presentationData.theme, presentationData.strings.Group_Setup_HistoryHeader))
    entries.append(.visible(presentationData.theme, presentationData.strings.Group_Setup_HistoryVisible, value))
    entries.append(.hidden(presentationData.theme, presentationData.strings.Group_Setup_HistoryHidden, !value))
    entries.append(.info(presentationData.theme, value ? presentationData.strings.Group_Setup_HistoryVisibleHelp : presentationData.strings.Group_Setup_HistoryHiddenHelp))
    
    return entries
}

public func groupPreHistorySetupController(account: Account, peerId: PeerId) -> ViewController {
    let statePromise = ValuePromise(GroupPreHistorySetupState(), ignoreRepeated: true)
    let stateValue = Atomic(value: GroupPreHistorySetupState())
    let updateState: ((GroupPreHistorySetupState) -> GroupPreHistorySetupState) -> Void = { f in
        statePromise.set(stateValue.modify { f($0) })
    }
    
    var dismissImpl: (() -> Void)?
    
    let actionsDisposable = DisposableSet()
    
    let applyDisposable = MetaDisposable()
    actionsDisposable.add(applyDisposable)
    
    let arguments = GroupPreHistorySetupArguments(toggle: { value in
        updateState { state in
            var state = state
            state.changedValue = value
            return state
        }
    })
    
    let signal = combineLatest((account.applicationContext as! TelegramApplicationContext).presentationData, statePromise.get(), account.viewTracker.peerView(peerId))
        |> deliverOnMainQueue
        |> map { presentationData, state, view -> (ItemListControllerState, (ItemListNodeState<GroupPreHistorySetupEntry>, GroupPreHistorySetupEntry.ItemGenerationArguments)) in
            let defaultValue: Bool = (view.cachedData as? CachedChannelData)?.flags.contains(.preHistoryEnabled) ?? false
            let leftNavigationButton = ItemListNavigationButton(content: .text(presentationData.strings.Common_Cancel), style: .regular, enabled: true, action: {
                dismissImpl?()
            })
            var rightNavigationButton: ItemListNavigationButton?
            if state.applyingSetting {
                rightNavigationButton = ItemListNavigationButton(content: .none, style: .activity, enabled: true, action: {})
            } else {
                rightNavigationButton = ItemListNavigationButton(content: .text(presentationData.strings.Common_Done), style: .bold, enabled: true, action: {
                    var value: Bool?
                    updateState { state in
                        var state = state
                        state.applyingSetting = true
                        value = state.changedValue
                        return state
                    }
                    if let value = value, value != defaultValue {
                        applyDisposable.set((updateChannelHistoryAvailabilitySettingsInteractively(postbox: account.postbox, network: account.network, accountStateManager: account.stateManager, peerId: peerId, historyAvailableForNewMembers: value)
                        |> deliverOnMainQueue).start(completed: {
                            dismissImpl?()
                        }))
                    } else {
                        dismissImpl?()
                    }
                })
            }
            
            let controllerState = ItemListControllerState(theme: presentationData.theme, title: .text(presentationData.strings.Group_Setup_HistoryTitle), leftNavigationButton: leftNavigationButton, rightNavigationButton: rightNavigationButton, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
            let listState = ItemListNodeState(entries: groupPreHistorySetupEntries(presentationData: presentationData, defaultValue: defaultValue, state: state), style: .blocks)
            
            return (controllerState, (listState, arguments))
        }
        |> afterDisposed {
            actionsDisposable.dispose()
    }
    
    let controller = ItemListController(account: account, state: signal)
    dismissImpl = { [weak controller] in
        controller?.view.endEditing(true)
        controller?.dismiss()
    }
    return controller
}
