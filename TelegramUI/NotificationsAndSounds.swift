import Foundation
import Display
import SwiftSignalKit
import Postbox
import TelegramCore

private final class NotificationsAndSoundsArguments {
    let account: Account
    let presentController: (ViewController, ViewControllerPresentationArguments) -> Void
    let soundSelectionDisposable: MetaDisposable
    
    let updateMessageAlerts: (Bool) -> Void
    let updateMessagePreviews: (Bool) -> Void
    let updateMessageSound: (PeerMessageSound) -> Void
    
    let updateGroupAlerts: (Bool) -> Void
    let updateGroupPreviews: (Bool) -> Void
    let updateGroupSound: (PeerMessageSound) -> Void
    
    let updateInAppSounds: (Bool) -> Void
    let updateInAppVibration: (Bool) -> Void
    let updateInAppPreviews: (Bool) -> Void
    
    let updateTotalUnreadCountStyle: (Bool) -> Void
    
    let resetNotifications: () -> Void
    
    init(account: Account, presentController: @escaping (ViewController, ViewControllerPresentationArguments) -> Void, soundSelectionDisposable: MetaDisposable, updateMessageAlerts: @escaping (Bool) -> Void, updateMessagePreviews: @escaping (Bool) -> Void, updateMessageSound: @escaping (PeerMessageSound) -> Void, updateGroupAlerts: @escaping (Bool) -> Void, updateGroupPreviews: @escaping (Bool) -> Void, updateGroupSound: @escaping (PeerMessageSound) -> Void, updateInAppSounds: @escaping (Bool) -> Void, updateInAppVibration: @escaping (Bool) -> Void, updateInAppPreviews: @escaping (Bool) -> Void, updateTotalUnreadCountStyle: @escaping (Bool) -> Void, resetNotifications: @escaping () -> Void) {
        self.account = account
        self.presentController = presentController
        self.soundSelectionDisposable = soundSelectionDisposable
        self.updateMessageAlerts = updateMessageAlerts
        self.updateMessagePreviews = updateMessagePreviews
        self.updateMessageSound = updateMessageSound
        self.updateGroupAlerts = updateGroupAlerts
        self.updateGroupPreviews = updateGroupPreviews
        self.updateGroupSound = updateGroupSound
        self.updateInAppSounds = updateInAppSounds
        self.updateInAppVibration = updateInAppVibration
        self.updateInAppPreviews = updateInAppPreviews
        self.updateTotalUnreadCountStyle = updateTotalUnreadCountStyle
        self.resetNotifications = resetNotifications
    }
}

private enum NotificationsAndSoundsSection: Int32 {
    case messages
    case groups
    case inApp
    case unreadCountStyle
    case reset
}

private enum NotificationsAndSoundsEntry: ItemListNodeEntry {
    case messageHeader(PresentationTheme, String)
    case messageAlerts(PresentationTheme, String, Bool)
    case messagePreviews(PresentationTheme, String, Bool)
    case messageSound(PresentationTheme, String, String, PeerMessageSound)
    case messageNotice(PresentationTheme, String)
    
    case groupHeader(PresentationTheme, String)
    case groupAlerts(PresentationTheme, String, Bool)
    case groupPreviews(PresentationTheme, String, Bool)
    case groupSound(PresentationTheme, String, String, PeerMessageSound)
    case groupNotice(PresentationTheme, String)
    
    case inAppHeader(PresentationTheme, String)
    case inAppSounds(PresentationTheme, String, Bool)
    case inAppVibrate(PresentationTheme, String, Bool)
    case inAppPreviews(PresentationTheme, String, Bool)
    
    case unreadCountStyle(PresentationTheme, String, Bool)
    
    case reset(PresentationTheme, String)
    case resetNotice(PresentationTheme, String)
    
    var section: ItemListSectionId {
        switch self {
            case .messageHeader, .messageAlerts, .messagePreviews, .messageSound, .messageNotice:
                return NotificationsAndSoundsSection.messages.rawValue
            case .groupHeader, .groupAlerts, .groupPreviews, .groupSound, .groupNotice:
                return NotificationsAndSoundsSection.groups.rawValue
            case .inAppHeader, .inAppSounds, .inAppVibrate, .inAppPreviews:
                return NotificationsAndSoundsSection.inApp.rawValue
            case .unreadCountStyle:
                return NotificationsAndSoundsSection.unreadCountStyle.rawValue
            case .reset, .resetNotice:
                return NotificationsAndSoundsSection.reset.rawValue
        }
    }
    
    var stableId: Int32 {
        switch self {
            case .messageHeader:
                return 0
            case .messageAlerts:
                return 1
            case .messagePreviews:
                return 2
            case .messageSound:
                return 3
            case .messageNotice:
                return 4
            case .groupHeader:
                return 5
            case .groupAlerts:
                return 6
            case .groupPreviews:
                return 7
            case .groupSound:
                return 8
            case .groupNotice:
                return 9
            case .inAppHeader:
                return 10
            case .inAppSounds:
                return 11
            case .inAppVibrate:
                return 12
            case .inAppPreviews:
                return 13
            case .unreadCountStyle:
                return 14
            case .reset:
                return 15
            case .resetNotice:
                return 16
        }
    }
    
    static func ==(lhs: NotificationsAndSoundsEntry, rhs: NotificationsAndSoundsEntry) -> Bool {
        switch lhs {
            case let .messageHeader(lhsTheme, lhsText):
                if case let .messageHeader(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .messageAlerts(lhsTheme, lhsText, lhsValue):
                if case let .messageAlerts(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .messagePreviews(lhsTheme, lhsText, lhsValue):
                if case let .messagePreviews(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .messageSound(lhsTheme, lhsText, lhsValue, lhsSound):
                if case let .messageSound(rhsTheme, rhsText, rhsValue, rhsSound) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue, lhsSound == rhsSound {
                    return true
                } else {
                    return false
                }
            case let .messageNotice(lhsTheme, lhsText):
                if case let .messageNotice(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .groupHeader(lhsTheme, lhsText):
                if case let .groupHeader(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .groupAlerts(lhsTheme, lhsText, lhsValue):
                if case let .groupAlerts(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .groupPreviews(lhsTheme, lhsText, lhsValue):
                if case let .groupPreviews(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .groupSound(lhsTheme, lhsText, lhsValue, lhsSound):
                if case let .groupSound(rhsTheme, rhsText, rhsValue, rhsSound) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue, lhsSound == rhsSound {
                    return true
                } else {
                    return false
                }
            case let .groupNotice(lhsTheme, lhsText):
                if case let .groupNotice(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .inAppHeader(lhsTheme, lhsText):
                if case let .inAppHeader(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .inAppSounds(lhsTheme, lhsText, lhsValue):
                if case let .inAppSounds(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .inAppVibrate(lhsTheme, lhsText, lhsValue):
                if case let .inAppVibrate(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .inAppPreviews(lhsTheme, lhsText, lhsValue):
                if case let .inAppPreviews(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .unreadCountStyle(lhsTheme, lhsText, lhsValue):
                if case let .unreadCountStyle(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .reset(lhsTheme, lhsText):
                if case let .reset(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .resetNotice(lhsTheme, lhsText):
                if case let .resetNotice(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
        }
    }
    
    static func <(lhs: NotificationsAndSoundsEntry, rhs: NotificationsAndSoundsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(_ arguments: NotificationsAndSoundsArguments) -> ListViewItem {
        switch self {
            case let .messageHeader(theme, text):
                return ItemListSectionHeaderItem(theme: theme, text: text, sectionId: self.section)
            case let .messageAlerts(theme, text, value):
                return ItemListSwitchItem(theme: theme, title: text, value: value, sectionId: self.section, style: .blocks, updated: { updatedValue in
                    arguments.updateMessageAlerts(updatedValue)
                })
            case let .messagePreviews(theme, text, value):
                return ItemListSwitchItem(theme: theme, title: text, value: value, sectionId: self.section, style: .blocks, updated: { updatedValue in
                    arguments.updateMessagePreviews(updatedValue)
                })
            case let .messageSound(theme, text, value, sound):
                return ItemListDisclosureItem(theme: theme, title: text, label: value, sectionId: self.section, style: .blocks, action: {
                    let controller = notificationSoundSelectionController(account: arguments.account, isModal: true, currentSound: sound, defaultSound: nil, completion: { [weak arguments] value in
                        arguments?.updateMessageSound(value)
                    })
                    arguments.presentController(controller, ViewControllerPresentationArguments(presentationAnimation: .modalSheet))
                })
            case let .messageNotice(theme, text):
                return ItemListTextItem(theme: theme, text: .plain(text), sectionId: self.section)
            case let .groupHeader(theme, text):
                return ItemListSectionHeaderItem(theme: theme, text: text, sectionId: self.section)
            case let .groupAlerts(theme, text, value):
                return ItemListSwitchItem(theme: theme, title: text, value: value, sectionId: self.section, style: .blocks, updated: { updatedValue in
                    arguments.updateGroupAlerts(updatedValue)
                })
            case let .groupPreviews(theme, text, value):
                return ItemListSwitchItem(theme: theme, title: text, value: value, sectionId: self.section, style: .blocks, updated: { updatedValue in
                    arguments.updateGroupPreviews(updatedValue)
                })
            case let .groupSound(theme, text, value, sound):
                return ItemListDisclosureItem(theme: theme, title: text, label: value, sectionId: self.section, style: .blocks, action: {
                    let controller = notificationSoundSelectionController(account: arguments.account, isModal: true, currentSound: sound, defaultSound: nil, completion: { [weak arguments] value in
                        arguments?.updateGroupSound(value)
                    })
                    arguments.presentController(controller, ViewControllerPresentationArguments(presentationAnimation: .modalSheet))
                })
            case let .groupNotice(theme, text):
                return ItemListTextItem(theme: theme, text: .plain(text), sectionId: self.section)
            case let .inAppHeader(theme, text):
                return ItemListSectionHeaderItem(theme: theme, text: text, sectionId: self.section)
            case let .inAppSounds(theme, text, value):
                return ItemListSwitchItem(theme: theme, title: text, value: value, sectionId: self.section, style: .blocks, updated: { updatedValue in
                    arguments.updateInAppSounds(updatedValue)
                })
            case let .inAppVibrate(theme, text, value):
                return ItemListSwitchItem(theme: theme, title: text, value: value, sectionId: self.section, style: .blocks, updated: { updatedValue in
                    arguments.updateInAppVibration(updatedValue)
                })
            case let .inAppPreviews(theme, text, value):
                return ItemListSwitchItem(theme: theme, title: text, value: value, sectionId: self.section, style: .blocks, updated: { updatedValue in
                    arguments.updateInAppPreviews(updatedValue)
                })
            case let .unreadCountStyle(theme, text, value):
                return ItemListSwitchItem(theme: theme, title: text, value: value, sectionId: self.section, style: .blocks, updated: { updatedValue in
                    arguments.updateTotalUnreadCountStyle(updatedValue)
                })
            case let .reset(theme, text):
                return ItemListActionItem(theme: theme, title: text, kind: .destructive, alignment: .natural, sectionId: self.section, style: .blocks, action: {
                    arguments.resetNotifications()
                })
            case let .resetNotice(theme, text):
                return ItemListTextItem(theme: theme, text: .plain(text), sectionId: self.section)
        }
    }
}

private func filteredGlobalSound(_ sound: PeerMessageSound) -> PeerMessageSound {
    if case .default = sound {
        return .bundledModern(id: 0)
    } else {
        return sound
    }
}

private func notificationsAndSoundsEntries(globalSettings: GlobalNotificationSettingsSet, inAppSettings: InAppNotificationSettings, presentationData: PresentationData) -> [NotificationsAndSoundsEntry] {
    var entries: [NotificationsAndSoundsEntry] = []
    
    entries.append(.messageHeader(presentationData.theme, presentationData.strings.Notifications_MessageNotifications))
    entries.append(.messageAlerts(presentationData.theme, presentationData.strings.Notifications_MessageNotificationsAlert, globalSettings.privateChats.enabled))
    entries.append(.messagePreviews(presentationData.theme, presentationData.strings.Notifications_MessageNotificationsPreview, globalSettings.privateChats.displayPreviews))
    entries.append(.messageSound(presentationData.theme, presentationData.strings.Notifications_MessageNotificationsSound, localizedPeerNotificationSoundString(strings: presentationData.strings, sound: filteredGlobalSound(globalSettings.privateChats.sound)), filteredGlobalSound(globalSettings.privateChats.sound)))
    entries.append(.messageNotice(presentationData.theme, presentationData.strings.Notifications_MessageNotificationsHelp))
    
    entries.append(.groupHeader(presentationData.theme, presentationData.strings.Notifications_GroupNotifications))
    entries.append(.groupAlerts(presentationData.theme, presentationData.strings.Notifications_MessageNotificationsAlert, globalSettings.groupChats.enabled))
    entries.append(.groupPreviews(presentationData.theme, presentationData.strings.Notifications_MessageNotificationsPreview, globalSettings.groupChats.displayPreviews))
    entries.append(.groupSound(presentationData.theme, presentationData.strings.Notifications_MessageNotificationsSound, localizedPeerNotificationSoundString(strings: presentationData.strings, sound: filteredGlobalSound(globalSettings.groupChats.sound)), filteredGlobalSound(globalSettings.groupChats.sound)))
    entries.append(.groupNotice(presentationData.theme, presentationData.strings.Notifications_GroupNotificationsHelp))
    
    entries.append(.inAppHeader(presentationData.theme, presentationData.strings.Notifications_InAppNotifications))
    entries.append(.inAppSounds(presentationData.theme, presentationData.strings.Notifications_InAppNotificationsSounds, inAppSettings.playSounds))
    entries.append(.inAppVibrate(presentationData.theme, presentationData.strings.Notifications_InAppNotificationsVibrate, inAppSettings.vibrate))
    entries.append(.inAppPreviews(presentationData.theme, presentationData.strings.Notifications_InAppNotificationsPreview, inAppSettings.displayPreviews))
    
    entries.append(.unreadCountStyle(presentationData.theme, "Include muted chats", inAppSettings.totalUnreadCountDisplayStyle == .raw))
    
    entries.append(.reset(presentationData.theme, presentationData.strings.Notifications_ResetAllNotifications))
    entries.append(.resetNotice(presentationData.theme, presentationData.strings.Notifications_ResetAllNotificationsHelp))
    
    return entries
}

public func notificationsAndSoundsController(account: Account) -> ViewController {
    var presentControllerImpl: ((ViewController, ViewControllerPresentationArguments?) -> Void)?
    
    let arguments = NotificationsAndSoundsArguments(account: account, presentController: { controller, arguments in
        presentControllerImpl?(controller, arguments)
    }, soundSelectionDisposable: MetaDisposable(), updateMessageAlerts: { value in
        let _ = updateGlobalNotificationSettingsInteractively(postbox: account.postbox, { settings in
            return settings.withUpdatedPrivateChats {
                return $0.withUpdatedEnabled(value)
            }
        }).start()
    }, updateMessagePreviews: { value in
        let _ = updateGlobalNotificationSettingsInteractively(postbox: account.postbox, { settings in
            return settings.withUpdatedPrivateChats {
                return $0.withUpdatedDisplayPreviews(value)
            }
        }).start()
    }, updateMessageSound: { value in
        let _ = updateGlobalNotificationSettingsInteractively(postbox: account.postbox, { settings in
            return settings.withUpdatedPrivateChats {
                return $0.withUpdatedSound(value)
            }
        }).start()
    }, updateGroupAlerts: { value in
        let _ = updateGlobalNotificationSettingsInteractively(postbox: account.postbox, { settings in
            return settings.withUpdatedGroupChats {
                return $0.withUpdatedEnabled(value)
            }
        }).start()
    }, updateGroupPreviews: { value in
        let _ = updateGlobalNotificationSettingsInteractively(postbox: account.postbox, { settings in
            return settings.withUpdatedGroupChats {
                return $0.withUpdatedDisplayPreviews(value)
            }
        }).start()
    }, updateGroupSound: {value in
        let _ = updateGlobalNotificationSettingsInteractively(postbox: account.postbox, { settings in
            return settings.withUpdatedGroupChats {
                return $0.withUpdatedSound(value)
            }
        }).start()
    }, updateInAppSounds: { value in
        let _ = updateInAppNotificationSettingsInteractively(postbox: account.postbox, { settings in
            return settings.withUpdatedPlaySounds(value)
        }).start()
    }, updateInAppVibration: { value in
        let _ = updateInAppNotificationSettingsInteractively(postbox: account.postbox, { settings in
            return settings.withUpdatedVibrate(value)
        }).start()
    }, updateInAppPreviews: { value in
        let _ = updateInAppNotificationSettingsInteractively(postbox: account.postbox, { settings in
            return settings.withUpdatedDisplayPreviews(value)
        }).start()
    }, updateTotalUnreadCountStyle: { value in
        let _ = updateInAppNotificationSettingsInteractively(postbox: account.postbox, { settings in
            return settings.withUpdatedTotalUnreadCountDisplayStyle(value ? .raw : .filtered)
        }).start()
    }, resetNotifications: {
        let presentationData = account.telegramApplicationContext.currentPresentationData.with { $0 }
        let actionSheet = ActionSheetController(presentationTheme: presentationData.theme)
        actionSheet.setItemGroups([ActionSheetItemGroup(items: [
            ActionSheetButtonItem(title: presentationData.strings.Notifications_Reset, color: .destructive, action: { [weak actionSheet] in
                actionSheet?.dismissAnimated()
                
                let modifyPeers = account.postbox.modify { modifier -> Void in
                    modifier.resetAllPeerNotificationSettings(TelegramPeerNotificationSettings.defaultSettings)
                }
                let updateGlobal = updateGlobalNotificationSettingsInteractively(postbox: account.postbox, { _ in
                    return GlobalNotificationSettingsSet.defaultSettings
                })
                let reset = resetPeerNotificationSettings(network: account.network)
                let signal = combineLatest(modifyPeers, updateGlobal, reset)
                let _ = signal.start()
            })
        ]), ActionSheetItemGroup(items: [
            ActionSheetButtonItem(title: presentationData.strings.Common_Cancel, color: .accent, action: { [weak actionSheet] in
                actionSheet?.dismissAnimated()
            })
        ])])
        presentControllerImpl?(actionSheet, nil)
    })
    
    let preferences = account.postbox.preferencesView(keys: [PreferencesKeys.globalNotifications, ApplicationSpecificPreferencesKeys.inAppNotificationSettings])
    
    let signal = combineLatest((account.applicationContext as! TelegramApplicationContext).presentationData, preferences)
        |> map { presentationData, view -> (ItemListControllerState, (ItemListNodeState<NotificationsAndSoundsEntry>, NotificationsAndSoundsEntry.ItemGenerationArguments)) in
            
            let viewSettings: GlobalNotificationSettingsSet
            if let settings = view.values[PreferencesKeys.globalNotifications] as? GlobalNotificationSettings {
                viewSettings = settings.effective
            } else {
                viewSettings = GlobalNotificationSettingsSet.defaultSettings
            }
            
            let inAppSettings: InAppNotificationSettings
            if let settings = view.values[ApplicationSpecificPreferencesKeys.inAppNotificationSettings] as? InAppNotificationSettings {
                inAppSettings = settings
            } else {
                inAppSettings = InAppNotificationSettings.defaultSettings
            }
            
            let controllerState = ItemListControllerState(theme: presentationData.theme, title: .text(presentationData.strings.Notifications_Title), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
            let listState = ItemListNodeState(entries: notificationsAndSoundsEntries(globalSettings: viewSettings, inAppSettings: inAppSettings, presentationData: presentationData), style: .blocks)
            
            return (controllerState, (listState, arguments))
    }
    
    let controller = ItemListController(account: account, state: signal)
    presentControllerImpl = { [weak controller] c, a in
        controller?.present(c, in: .window(.root), with: a)
    }
    return controller
}
