import Foundation
import Display
import SwiftSignalKit
import Postbox
import TelegramCore

private final class DataPrivacyControllerArguments {
    let account: Account
    let clearPaymentInfo: () -> Void
    let updateSecretChatLinkPreviews: (Bool) -> Void
    let deleteContacts: () -> Void
    let updateSyncContacts: (Bool) -> Void
    let updateSuggestFrequentContacts: (Bool) -> Void
    let deleteCloudDrafts: () -> Void
    
    init(account: Account, clearPaymentInfo: @escaping () -> Void, updateSecretChatLinkPreviews: @escaping (Bool) -> Void, deleteContacts: @escaping () -> Void, updateSyncContacts: @escaping (Bool) -> Void, updateSuggestFrequentContacts: @escaping (Bool) -> Void, deleteCloudDrafts: @escaping () -> Void) {
        self.account = account
        self.clearPaymentInfo = clearPaymentInfo
        self.updateSecretChatLinkPreviews = updateSecretChatLinkPreviews
        self.deleteContacts = deleteContacts
        self.updateSyncContacts = updateSyncContacts
        self.updateSuggestFrequentContacts = updateSuggestFrequentContacts
        self.deleteCloudDrafts = deleteCloudDrafts
    }
}

private enum PrivacyAndSecuritySection: Int32 {
    case contacts
    case frequentContacts
    case chats
    case payments
    case secretChats
}

private enum PrivacyAndSecurityEntry: ItemListNodeEntry {
    case contactsHeader(PresentationTheme, String)
    case deleteContacts(PresentationTheme, String, Bool)
    case syncContacts(PresentationTheme, String, Bool)
    case syncContactsInfo(PresentationTheme, String)
    
    case frequentContacts(PresentationTheme, String, Bool)
    case frequentContactsInfo(PresentationTheme, String)
    
    case chatsHeader(PresentationTheme, String)
    case deleteCloudDrafts(PresentationTheme, String, Bool)
    
    case paymentHeader(PresentationTheme, String)
    case clearPaymentInfo(PresentationTheme, String, Bool)
    case paymentInfo(PresentationTheme, String)
    
    case secretChatLinkPreviewsHeader(PresentationTheme, String)
    case secretChatLinkPreviews(PresentationTheme, String, Bool)
    case secretChatLinkPreviewsInfo(PresentationTheme, String)
    
    var section: ItemListSectionId {
        switch self {
        case .contactsHeader, .deleteContacts, .syncContacts, .syncContactsInfo:
                return PrivacyAndSecuritySection.contacts.rawValue
            case .frequentContacts, .frequentContactsInfo:
                return PrivacyAndSecuritySection.frequentContacts.rawValue
            case .chatsHeader, .deleteCloudDrafts:
                return PrivacyAndSecuritySection.chats.rawValue
            case .paymentHeader, .clearPaymentInfo, .paymentInfo:
                return PrivacyAndSecuritySection.payments.rawValue
        case .secretChatLinkPreviewsHeader, .secretChatLinkPreviews, .secretChatLinkPreviewsInfo:
                return PrivacyAndSecuritySection.secretChats.rawValue
        
        }
    }
    
    var stableId: Int32 {
        switch self {
            case .contactsHeader:
                return 0
            case .deleteContacts:
                return 1
            case .syncContacts:
                return 2
            case .syncContactsInfo:
                return 3
            
            case .frequentContacts:
                return 4
            case .frequentContactsInfo:
                return 5
            
            case .chatsHeader:
                return 6
            case .deleteCloudDrafts:
                return 7
            
            case .paymentHeader:
                return 8
            case .clearPaymentInfo:
                return 9
            case .paymentInfo:
                return 10
            
            case .secretChatLinkPreviewsHeader:
                return 11
            case .secretChatLinkPreviews:
                return 12
            case .secretChatLinkPreviewsInfo:
                return 13
        }
    }
    
    static func ==(lhs: PrivacyAndSecurityEntry, rhs: PrivacyAndSecurityEntry) -> Bool {
        switch lhs {
            case let .contactsHeader(lhsTheme, lhsText):
                if case let .contactsHeader(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .deleteContacts(lhsTheme, lhsText, lhsEnabled):
                if case let .deleteContacts(rhsTheme, rhsText, rhsEnabled) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsEnabled == rhsEnabled {
                    return true
                } else {
                    return false
                }
            case let .syncContacts(lhsTheme, lhsText, lhsEnabled):
                if case let .syncContacts(rhsTheme, rhsText, rhsEnabled) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsEnabled == rhsEnabled {
                    return true
                } else {
                    return false
                }
            case let .syncContactsInfo(lhsTheme, lhsText):
                if case let .syncContactsInfo(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .frequentContacts(lhsTheme, lhsText, lhsEnabled):
                if case let .frequentContacts(rhsTheme, rhsText, rhsEnabled) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsEnabled == rhsEnabled {
                    return true
                } else {
                    return false
                }
            case let .frequentContactsInfo(lhsTheme, lhsText):
                if case let .frequentContactsInfo(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .chatsHeader(lhsTheme, lhsText):
                if case let .chatsHeader(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .deleteCloudDrafts(lhsTheme, lhsText, lhsEnabled):
                if case let .deleteCloudDrafts(rhsTheme, rhsText, rhsEnabled) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsEnabled == rhsEnabled {
                    return true
                } else {
                    return false
                }
            case let .paymentHeader(lhsTheme, lhsText):
                if case let .paymentHeader(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .clearPaymentInfo(lhsTheme, lhsText, lhsEnabled):
                if case let .clearPaymentInfo(rhsTheme, rhsText, rhsEnabled) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsEnabled == rhsEnabled {
                    return true
                } else {
                    return false
                }
            case let .paymentInfo(lhsTheme, lhsText):
                if case let .paymentInfo(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .secretChatLinkPreviewsHeader(lhsTheme, lhsText):
                if case let .secretChatLinkPreviewsHeader(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .secretChatLinkPreviews(lhsTheme, lhsText, lhsEnabled):
                if case let .secretChatLinkPreviews(rhsTheme, rhsText, rhsEnabled) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsEnabled == rhsEnabled {
                    return true
                } else {
                    return false
                }
            case let .secretChatLinkPreviewsInfo(lhsTheme, lhsText):
                if case let .secretChatLinkPreviewsInfo(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
        }
    }
    
    static func <(lhs: PrivacyAndSecurityEntry, rhs: PrivacyAndSecurityEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(_ arguments: DataPrivacyControllerArguments) -> ListViewItem {
        switch self {
            case let .contactsHeader(theme, text):
                return ItemListSectionHeaderItem(theme: theme, text: text, sectionId: self.section)
            case let .deleteContacts(theme, text, value):
                return ItemListActionItem(theme: theme, title: text, kind: value ? .generic : .disabled, alignment: .natural, sectionId: self.section, style: .blocks, action: {
                    arguments.deleteContacts()
                })
            case let .syncContacts(theme, text, value):
                return ItemListSwitchItem(theme: theme, title: text, value: value, sectionId: self.section, style: .blocks, updated: { updatedValue in
                    arguments.updateSyncContacts(updatedValue)
                })
            case let .syncContactsInfo(theme, text):
                return ItemListTextItem(theme: theme, text: .plain(text), sectionId: self.section)
            case let .frequentContacts(theme, text, value):
                return ItemListSwitchItem(theme: theme, title: text, value: value, enableInteractiveChanges: !value, sectionId: self.section, style: .blocks, updated: { updatedValue in
                    arguments.updateSuggestFrequentContacts(updatedValue)
                })
            case let .frequentContactsInfo(theme, text):
                return ItemListTextItem(theme: theme, text: .plain(text), sectionId: self.section)
            case let .chatsHeader(theme, text):
                return ItemListSectionHeaderItem(theme: theme, text: text, sectionId: self.section)
            case let .deleteCloudDrafts(theme, text, value):
                return ItemListActionItem(theme: theme, title: text, kind: value ? .generic : .disabled, alignment: .natural, sectionId: self.section, style: .blocks, action: {
                    arguments.deleteCloudDrafts()
                })
            case let .paymentHeader(theme, text):
                return ItemListSectionHeaderItem(theme: theme, text: text, sectionId: self.section)
            case let .clearPaymentInfo(theme, text, enabled):
                return ItemListActionItem(theme: theme, title: text, kind: enabled ? .generic : .disabled, alignment: .natural, sectionId: self.section, style: .blocks, action: {
                    arguments.clearPaymentInfo()
                })
            case let .paymentInfo(theme, text):
                return ItemListTextItem(theme: theme, text: .plain(text), sectionId: self.section)
            case let .secretChatLinkPreviewsHeader(theme, text):
                return ItemListSectionHeaderItem(theme: theme, text: text, sectionId: self.section)
            case let .secretChatLinkPreviews(theme, text, value):
                return ItemListSwitchItem(theme: theme, title: text, value: value, sectionId: self.section, style: .blocks, updated: { updatedValue in
                    arguments.updateSecretChatLinkPreviews(updatedValue)
                })
            case let .secretChatLinkPreviewsInfo(theme, text):
                return ItemListTextItem(theme: theme, text: .plain(text), sectionId: self.section)
        }
    }
}

private struct DataPrivacyControllerState: Equatable {
    var clearingPaymentInfo: Bool = false
    var deletingContacts: Bool = false
    var updatedSuggestFrequentContacts: Bool? = nil
    var deletingCloudDrafts: Bool = false
}

private func dataPrivacyControllerEntries(presentationData: PresentationData, state: DataPrivacyControllerState, secretChatLinkPreviews: Bool?, synchronizeDeviceContacts: Bool, frequentContacts: Bool) -> [PrivacyAndSecurityEntry] {
    var entries: [PrivacyAndSecurityEntry] = []
    
    entries.append(.contactsHeader(presentationData.theme, presentationData.strings.PrivacySettings_Contacts))
    entries.append(.deleteContacts(presentationData.theme, presentationData.strings.PrivacySettings_DeleteContacts, !state.deletingContacts))
    entries.append(.syncContacts(presentationData.theme, presentationData.strings.PrivacySettings_SyncContacts, synchronizeDeviceContacts))
    entries.append(.syncContactsInfo(presentationData.theme, presentationData.strings.PrivacySettings_SyncContactsInfo))
    
    entries.append(.frequentContacts(presentationData.theme, presentationData.strings.PrivacySettings_SuggestFrequentContacts, frequentContacts))
    entries.append(.frequentContactsInfo(presentationData.theme, presentationData.strings.PrivacySettings_SuggestFrequentContactsInfo))
    
    entries.append(.chatsHeader(presentationData.theme, presentationData.strings.Privacy_ChatsTitle))
    entries.append(.deleteCloudDrafts(presentationData.theme, presentationData.strings.Privacy_DeleteDrafts, !state.deletingCloudDrafts))
    entries.append(.paymentHeader(presentationData.theme, presentationData.strings.Privacy_PaymentsTitle))
    entries.append(.clearPaymentInfo(presentationData.theme, presentationData.strings.Privacy_PaymentsClearInfo, !state.clearingPaymentInfo))
    entries.append(.paymentInfo(presentationData.theme, presentationData.strings.Privacy_PaymentsClearInfoHelp))
    
   entries.append(.secretChatLinkPreviewsHeader(presentationData.theme, presentationData.strings.PrivacySettings_SecretChats))
    entries.append(.secretChatLinkPreviews(presentationData.theme, presentationData.strings.PrivacySettings_LinkPreviews, secretChatLinkPreviews ?? true))
    entries.append(.secretChatLinkPreviewsInfo(presentationData.theme, presentationData.strings.PrivacySettings_LinkPreviewsInfo))
    
    return entries
}

public func dataPrivacyController(account: Account) -> ViewController {
    let statePromise = ValuePromise(DataPrivacyControllerState(), ignoreRepeated: true)
    let stateValue = Atomic(value: DataPrivacyControllerState())
    let updateState: ((DataPrivacyControllerState) -> DataPrivacyControllerState) -> Void = { f in
        statePromise.set(stateValue.modify { f($0) })
    }
    
    var pushControllerImpl: ((ViewController) -> Void)?
    var pushControllerInstantImpl: ((ViewController) -> Void)?
    var presentControllerImpl: ((ViewController) -> Void)?
    
    let actionsDisposable = DisposableSet()
    
    let currentInfoDisposable = MetaDisposable()
    actionsDisposable.add(currentInfoDisposable)
    
    let clearPaymentInfoDisposable = MetaDisposable()
    actionsDisposable.add(clearPaymentInfoDisposable)
    
    let arguments = DataPrivacyControllerArguments(account: account, clearPaymentInfo: {
        let presentationData = account.telegramApplicationContext.currentPresentationData.with { $0 }
        let controller = ActionSheetController(presentationTheme: presentationData.theme)
        let dismissAction: () -> Void = { [weak controller] in
            controller?.dismissAnimated()
        }
        controller.setItemGroups([
            ActionSheetItemGroup(items: [
                ActionSheetButtonItem(title: presentationData.strings.Privacy_PaymentsClearInfo, color: .destructive, action: {
                    var clear = false
                    updateState { state in
                        var state = state
                        if !state.clearingPaymentInfo {
                            clear = true
                            state.clearingPaymentInfo = true
                        }
                        return state
                    }
                    if clear {
                        clearPaymentInfoDisposable.set((clearBotPaymentInfo(network: account.network)
                            |> deliverOnMainQueue).start(completed: {
                                updateState { state in
                                    var state = state
                                    state.clearingPaymentInfo = false
                                    return state
                                }
                                presentControllerImpl?(OverlayStatusController(theme: account.telegramApplicationContext.currentPresentationData.with({ $0 }).theme, type: .success))
                            }))
                    }
                    dismissAction()
                })
                ]),
            ActionSheetItemGroup(items: [ActionSheetButtonItem(title: presentationData.strings.Common_Cancel, action: { dismissAction() })])
            ])
        presentControllerImpl?(controller)
    }, updateSecretChatLinkPreviews: { value in
        let _ = ApplicationSpecificNotice.setSecretChatLinkPreviews(postbox: account.postbox, value: value).start()
    }, deleteContacts: {
        var canBegin = false
        updateState { state in
            if !state.deletingContacts {
                canBegin = true
            }
            return state
        }
        if canBegin {
            let presentationData = account.telegramApplicationContext.currentPresentationData.with { $0 }
            presentControllerImpl?(standardTextAlertController(theme: AlertControllerTheme(presentationTheme: presentationData.theme), title: nil, text: "This will remove your contacts from the Telegram servers.", actions: [TextAlertAction(type: .genericAction, title: presentationData.strings.Common_OK, action: {
                var begin = false
                updateState { state in
                    var state = state
                    if !state.deletingContacts {
                        state.deletingContacts = true
                        begin = true
                    }
                    return state
                }
                
                if !begin {
                    return
                }
                
                let _ = updateContactSynchronizationSettingsInteractively(postbox: account.postbox, { settings in
                    var settings = settings
                    settings.synchronizeDeviceContacts = false
                    return settings
                })
                
                actionsDisposable.add((deleteAllContacts(postbox: account.postbox, network: account.network)
                    |> deliverOnMainQueue).start(completed: {
                        updateState { state in
                            var state = state
                            state.deletingContacts = false
                            return state
                        }
                        let presentationData = account.telegramApplicationContext.currentPresentationData.with { $0 }
                        presentControllerImpl?(standardTextAlertController(theme: AlertControllerTheme(presentationTheme: presentationData.theme), title: nil, text: presentationData.strings.PrivacySettings_DeleteContactsSuccess, actions: [TextAlertAction(type: .defaultAction, title: presentationData.strings.Common_OK, action: {})]))
                    }))
            }), TextAlertAction(type: .defaultAction, title: presentationData.strings.Common_Cancel, action: {})]))
        }
    }, updateSyncContacts: { value in
        let _ = updateContactSynchronizationSettingsInteractively(postbox: account.postbox, { settings in
            var settings = settings
            settings.synchronizeDeviceContacts = value
            return settings
        }).start()
    }, updateSuggestFrequentContacts: { value in
        let apply: () -> Void = {
            updateState { state in
                var state = state
                state.updatedSuggestFrequentContacts = value
                return state
            }
            let _ = updateRecentPeersEnabled(postbox: account.postbox, network: account.network, enabled: value).start()
        }
        if !value {
            let presentationData = account.telegramApplicationContext.currentPresentationData.with { $0 }
            presentControllerImpl?(standardTextAlertController(theme: AlertControllerTheme(presentationTheme: presentationData.theme), title: nil, text: presentationData.strings.PrivacySettings_SuggestFrequentContactsDisableNotice, actions: [TextAlertAction(type: .genericAction, title: presentationData.strings.Common_Cancel, action: {}), TextAlertAction(type: .defaultAction, title: presentationData.strings.Common_OK, action: {
                apply()
            })]))
        } else {
            apply()
        }
    }, deleteCloudDrafts: {
        let presentationData = account.telegramApplicationContext.currentPresentationData.with { $0 }
        let controller = ActionSheetController(presentationTheme: presentationData.theme)
        let dismissAction: () -> Void = { [weak controller] in
            controller?.dismissAnimated()
        }
        controller.setItemGroups([
            ActionSheetItemGroup(items: [
                ActionSheetButtonItem(title: presentationData.strings.Privacy_DeleteDrafts, color: .destructive, action: {
                    var clear = false
                    updateState { state in
                        var state = state
                        if !state.deletingCloudDrafts {
                            clear = true
                            state.deletingCloudDrafts = true
                        }
                        return state
                    }
                    if clear {
                        clearPaymentInfoDisposable.set((clearCloudDraftsInteractively(postbox: account.postbox, network: account.network)
                            |> deliverOnMainQueue).start(completed: {
                                updateState { state in
                                    var state = state
                                    state.deletingCloudDrafts = false
                                    return state
                                }
                                presentControllerImpl?(OverlayStatusController(theme: account.telegramApplicationContext.currentPresentationData.with({ $0 }).theme, type: .success))
                            }))
                    }
                    dismissAction()
                })
                ]),
            ActionSheetItemGroup(items: [ActionSheetButtonItem(title: presentationData.strings.Common_Cancel, action: { dismissAction() })])
            ])
        presentControllerImpl?(controller)
    })
    
    let previousState = Atomic<DataPrivacyControllerState?>(value: nil)
    
    let preferencesKey = PostboxViewKey.preferences(keys: Set([ApplicationSpecificPreferencesKeys.contactSynchronizationSettings]))
    
    actionsDisposable.add(managedUpdatedRecentPeers(postbox: account.postbox, network: account.network).start())
    
    let signal = combineLatest((account.applicationContext as! TelegramApplicationContext).presentationData, statePromise.get() |> deliverOnMainQueue, account.postbox.combinedView(keys: [.noticeEntry(ApplicationSpecificNotice.secretChatLinkPreviewsKey()), preferencesKey]), recentPeers(account: account))
        |> map { presentationData, state, combined, recentPeers -> (ItemListControllerState, (ItemListNodeState<PrivacyAndSecurityEntry>, PrivacyAndSecurityEntry.ItemGenerationArguments)) in
            let secretChatLinkPreviews = (combined.views[.noticeEntry(ApplicationSpecificNotice.secretChatLinkPreviewsKey())] as? NoticeEntryView)?.value.flatMap({ ApplicationSpecificNotice.getSecretChatLinkPreviews($0) })
            
            let synchronizeDeviceContacts: Bool = ((combined.views[preferencesKey] as? PreferencesView)?.values[ApplicationSpecificPreferencesKeys.contactSynchronizationSettings] as? ContactSynchronizationSettings)?.synchronizeDeviceContacts ?? true
            
            let suggestRecentPeers: Bool
            if let updatedSuggestFrequentContacts = state.updatedSuggestFrequentContacts {
                suggestRecentPeers = updatedSuggestFrequentContacts
            } else {
                switch recentPeers {
                case .peers:
                    suggestRecentPeers = true
                case .disabled:
                    suggestRecentPeers = false
                }
            }
            
            let rightNavigationButton: ItemListNavigationButton? = nil
            
            let controllerState = ItemListControllerState(theme: presentationData.theme, title: .text(presentationData.strings.PrivateDataSettings_Title), leftNavigationButton: nil, rightNavigationButton: rightNavigationButton, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back), animateChanges: false)
            
            let previousStateValue = previousState.swap(state)
            let animateChanges = false
            
            let listState = ItemListNodeState(entries: dataPrivacyControllerEntries(presentationData: presentationData, state: state, secretChatLinkPreviews: secretChatLinkPreviews, synchronizeDeviceContacts: synchronizeDeviceContacts, frequentContacts: suggestRecentPeers), style: .blocks, animateChanges: animateChanges)
            
            return (controllerState, (listState, arguments))
        } |> afterDisposed {
            actionsDisposable.dispose()
    }
    
    let controller = ItemListController(account: account, state: signal)
    pushControllerImpl = { [weak controller] c in
        (controller?.navigationController as? NavigationController)?.pushViewController(c)
    }
    pushControllerInstantImpl = { [weak controller] c in
        (controller?.navigationController as? NavigationController)?.pushViewController(c, animated: false)
    }
    presentControllerImpl = { [weak controller] c in
        controller?.present(c, in: .window(.root), with: ViewControllerPresentationArguments(presentationAnimation: .modalSheet))
    }
    
    return controller
}
