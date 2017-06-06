import Foundation
import Display
import SwiftSignalKit
import Postbox
import TelegramCore

private final class ChannelAdminControllerArguments {
    let account: Account
    let toggleRight: (TelegramChannelAdminRightsFlags, TelegramChannelAdminRightsFlags) -> Void
    let dismissAdmin: () -> Void
    
    init(account: Account, toggleRight: @escaping (TelegramChannelAdminRightsFlags, TelegramChannelAdminRightsFlags) -> Void, dismissAdmin: @escaping () -> Void) {
        self.account = account
        self.toggleRight = toggleRight
        self.dismissAdmin = dismissAdmin
    }
}

private enum ChannelAdminSection: Int32 {
    case info
    case rights
    case dismiss
}

private enum ChannelAdminEntryStableId: Hashable {
    case info
    case right(TelegramChannelAdminRightsFlags)
    case dismiss
    
    var hashValue: Int {
        switch self {
            case .info:
                return 0
            case .dismiss:
                return 1
            case let .right(flags):
                return flags.rawValue.hashValue
        }
    }
    
    static func ==(lhs: ChannelAdminEntryStableId, rhs: ChannelAdminEntryStableId) -> Bool {
        switch lhs {
            case .info:
                if case .info = rhs {
                    return true
                } else {
                    return false
                }
            case let right(flags):
                if case .right(flags) = rhs {
                    return true
                } else {
                    return false
                }
            case .dismiss:
                if case .dismiss = rhs {
                    return true
                } else {
                    return false
                }
        }
    }
}

private enum ChannelAdminEntry: ItemListNodeEntry {
    case info(PresentationTheme, PresentationStrings, Peer, TelegramUserPresence?)
    case rightItem(PresentationTheme, Int, String, TelegramChannelAdminRightsFlags, TelegramChannelAdminRightsFlags, Bool, Bool)
    case dismiss(PresentationTheme, String)
    
    var section: ItemListSectionId {
        switch self {
            case .info:
                return ChannelAdminSection.info.rawValue
            case .rightItem:
                return ChannelAdminSection.rights.rawValue
            case .dismiss:
                return ChannelAdminSection.dismiss.rawValue
        }
    }
    
    var stableId: ChannelAdminEntryStableId {
        switch self {
            case .info:
                return .info
            case let .rightItem(_, _, _, right, _, _, _):
                return .right(right)
            case .dismiss:
                return .dismiss
        }
    }
    
    static func ==(lhs: ChannelAdminEntry, rhs: ChannelAdminEntry) -> Bool {
        switch lhs {
            case let .info(lhsTheme, lhsStrings, lhsPeer, lhsPresence):
                if case let .info(rhsTheme, rhsStrings, rhsPeer, rhsPresence) = rhs {
                    if lhsTheme !== rhsTheme {
                        return false
                    }
                    if lhsStrings !== rhsStrings {
                        return false
                    }
                    if !arePeersEqual(lhsPeer, rhsPeer) {
                        return false
                    }
                    if lhsPresence != rhsPresence {
                        return false
                    }
                    
                    return true
                } else {
                    return false
                }
            case let .rightItem(lhsTheme, lhsIndex, lhsText, lhsRight, lhsFlags, lhsValue, lhsEnabled):
                if case let .rightItem(rhsTheme, rhsIndex, rhsText, rhsRight, rhsFlags, rhsValue, rhsEnabled) = rhs {
                    if lhsTheme !== rhsTheme {
                        return false
                    }
                    if lhsIndex != rhsIndex {
                        return false
                    }
                    if lhsText != rhsText {
                        return false
                    }
                    if lhsRight != rhsRight {
                        return false
                    }
                    if lhsFlags != rhsFlags {
                        return false
                    }
                    if lhsValue != rhsValue {
                        return false
                    }
                    if lhsEnabled != rhsEnabled {
                        return false
                    }
                    return true
                } else {
                    return false
                }
            case let .dismiss(lhsTheme, lhsText):
                if case let .dismiss(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
        }
    }
    
    static func <(lhs: ChannelAdminEntry, rhs: ChannelAdminEntry) -> Bool {
        switch lhs {
            case .info:
                switch rhs {
                    case .info:
                        return false
                    default:
                        return true
                }
            case let .rightItem(_, lhsIndex, _, _, _, _, _):
                switch rhs {
                    case .info:
                        return false
                    case let .rightItem(_, rhsIndex, _, _, _, _, _):
                        return lhsIndex < rhsIndex
                    default:
                        return true
                }
            case .dismiss:
                return false
        }
    }
    
    func item(_ arguments: ChannelAdminControllerArguments) -> ListViewItem {
        switch self {
            case let .info(theme, strings, peer, presence):
                return ItemListAvatarAndNameInfoItem(account: arguments.account, theme: theme, strings: strings, peer: peer, presence: presence, cachedData: nil, state: ItemListAvatarAndNameInfoItemState(), sectionId: self.section, style: .blocks(withTopInset: true), editingNameUpdated: { _ in
                }, avatarTapped: {
                })
            case let .rightItem(theme, _, text, right, flags, value, enabled):
                return ItemListSwitchItem(theme: theme, title: text, value: value, enabled: enabled, sectionId: self.section, style: .blocks, updated: { _ in
                    arguments.toggleRight(right, flags)
                })
            case let .dismiss(theme, text):
                return ItemListActionItem(theme: theme, title: text, kind: .destructive, alignment: .natural, sectionId: self.section, style: .blocks, action: {
                    arguments.dismissAdmin()
                }, tag: nil)
        }
    }
}

private struct ChannelAdminControllerState: Equatable {
    let updatedFlags: TelegramChannelAdminRightsFlags?
    let updating: Bool
    
    init(updatedFlags: TelegramChannelAdminRightsFlags? = nil, updating: Bool = false) {
        self.updatedFlags = updatedFlags
        self.updating = updating
    }
    
    static func ==(lhs: ChannelAdminControllerState, rhs: ChannelAdminControllerState) -> Bool {
        if lhs.updatedFlags != rhs.updatedFlags {
            return false
        }
        if lhs.updating != rhs.updating {
            return false
        }
        return true
    }
    
    func withUpdatedUpdatedFlags(_ updatedFlags: TelegramChannelAdminRightsFlags?) -> ChannelAdminControllerState {
        return ChannelAdminControllerState(updatedFlags: updatedFlags, updating: self.updating)
    }
    
    func withUpdatedUpdating(_ updating: Bool) -> ChannelAdminControllerState {
        return ChannelAdminControllerState(updatedFlags: self.updatedFlags, updating: updating)
    }
}

private func stringForRight(strings: PresentationStrings, right: TelegramChannelAdminRightsFlags, isGroup: Bool) -> String {
    if right.contains(.canChangeInfo) {
        return isGroup ? strings.Group_EditAdmin_PermissionChangeInfo : strings.Channel_EditAdmin_PermissionChangeInfo
    } else if right.contains(.canPostMessages) {
        return strings.Channel_EditAdmin_PermissionPostMessages
    } else if right.contains(.canEditMessages) {
        return strings.Channel_EditAdmin_PermissionEditMessages
    } else if right.contains(.canDeleteMessages) {
        return strings.Channel_EditAdmin_PermissionDeleteMessages
    } else if right.contains(.canBanUsers) {
        return strings.Channel_EditAdmin_PermissionBanUsers
    } else if right.contains(.canInviteUsers) {
        return strings.Channel_EditAdmin_PermissionInviteUsers
    } else if right.contains(.canChangeInviteLink) {
        return strings.Channel_EditAdmin_PermissionChangeInviteLink
    } else if right.contains(.canPinMessages) {
        return strings.Channel_EditAdmin_PermissionPinMessages
    } else if right.contains(.canAddAdmins) {
        return strings.Channel_EditAdmin_PermissionAddAdmins
    } else {
        return ""
    }
}

private func rightDependencies(_ right: TelegramChannelAdminRightsFlags) -> [TelegramChannelAdminRightsFlags] {
    if right.contains(.canChangeInfo) {
        return []
    } else if right.contains(.canPostMessages) {
        return []
    } else if right.contains(.canEditMessages) {
        return []
    } else if right.contains(.canDeleteMessages) {
        return []
    } else if right.contains(.canBanUsers) {
        return []
    } else if right.contains(.canInviteUsers) {
        return []
    } else if right.contains(.canChangeInviteLink) {
        return [.canInviteUsers]
    } else if right.contains(.canPinMessages) {
        return []
    } else if right.contains(.canAddAdmins) {
        return []
    } else {
        return []
    }
}

private func canEditAdminRights(accountPeerId: PeerId, channelView: PeerView, initialParticipant: ChannelParticipant?) -> Bool {
    if let channel = channelView.peers[channelView.peerId] as? TelegramChannel {
        if channel.flags.contains(.isCreator) {
            return true
        } else if let initialParticipant = initialParticipant {
            switch initialParticipant {
                case .creator:
                    return false
                case let .member(_, _, adminInfo, _):
                    if let adminInfo = adminInfo {
                        return adminInfo.canBeEditedByAccountPeer || adminInfo.promotedBy == accountPeerId
                    } else {
                        return false
                    }
            }
        } else {
            return channel.hasAdminRights(.canAddAdmins)
        }
    } else {
        return false
    }
}

private func channelAdminControllerEntries(presentationData: PresentationData, state: ChannelAdminControllerState, accountPeerId: PeerId, channelView: PeerView, adminView: PeerView, initialParticipant: ChannelParticipant?) -> [ChannelAdminEntry] {
    var entries: [ChannelAdminEntry] = []
    
    if let channel = channelView.peers[channelView.peerId] as? TelegramChannel, let admin = adminView.peers[adminView.peerId] {
        entries.append(.info(presentationData.theme, presentationData.strings, admin, adminView.peerPresences[admin.id] as? TelegramUserPresence))
        
        let isGroup: Bool
        let maskRightsFlags: TelegramChannelAdminRightsFlags
        let rightsOrder: [TelegramChannelAdminRightsFlags]
        
        switch channel.info {
            case .broadcast:
                isGroup = false
                maskRightsFlags = .broadcastSpecific
                rightsOrder = [
                    .canChangeInfo,
                    .canPostMessages,
                    .canEditMessages,
                    .canDeleteMessages,
                    .canAddAdmins
                ]
            case .group:
                isGroup = true
                maskRightsFlags = .groupSpecific
                rightsOrder = [
                    .canChangeInfo,
                    .canDeleteMessages,
                    .canBanUsers,
                    .canInviteUsers,
                    .canChangeInviteLink,
                    .canPinMessages,
                    .canAddAdmins
                ]
        }
        
        if canEditAdminRights(accountPeerId: accountPeerId, channelView: channelView, initialParticipant: initialParticipant) {
            let accountUserRightsFlags: TelegramChannelAdminRightsFlags
            if channel.flags.contains(.isCreator) {
                accountUserRightsFlags = maskRightsFlags
            } else if let adminRights = channel.adminRights {
                accountUserRightsFlags = maskRightsFlags.intersection(adminRights.flags)
            } else {
                accountUserRightsFlags = []
            }
            
            let currentRightsFlags: TelegramChannelAdminRightsFlags
            if let updatedFlags = state.updatedFlags {
                currentRightsFlags = updatedFlags
            } else if let initialParticipant = initialParticipant, case let .member(_, _, maybeAdminRights, _) = initialParticipant, let adminRights = maybeAdminRights {
                currentRightsFlags = adminRights.rights.flags
            } else {
                currentRightsFlags = accountUserRightsFlags.subtracting(.canAddAdmins)
            }
            
            var index = 0
            for right in rightsOrder {
                if accountUserRightsFlags.contains(right) {
                    entries.append(.rightItem(presentationData.theme, index, stringForRight(strings: presentationData.strings, right: right, isGroup: isGroup), right, currentRightsFlags, currentRightsFlags.contains(right), !state.updating))
                    index += 1
                }
            }
        
            if let initialParticipant = initialParticipant {
                var canDismiss = false
                if channel.flags.contains(.isCreator) {
                    canDismiss = true
                } else {
                    switch initialParticipant {
                        case .creator:
                            break
                        case let .member(_, _, adminInfo, _):
                            if let adminInfo = adminInfo {
                                if adminInfo.promotedBy == accountPeerId || adminInfo.canBeEditedByAccountPeer {
                                    canDismiss = true
                                }
                            }
                    }
                }
                if canDismiss {
                    entries.append(.dismiss(presentationData.theme, presentationData.strings.Channel_Moderator_AccessLevelRevoke))
                }
            }
        } else if let initialParticipant = initialParticipant, case let .member(_, _, maybeAdminInfo, _) = initialParticipant, let adminInfo = maybeAdminInfo {
            var index = 0
            for right in rightsOrder {
                entries.append(.rightItem(presentationData.theme, index, stringForRight(strings: presentationData.strings, right: right, isGroup: isGroup), right, adminInfo.rights.flags, adminInfo.rights.flags.contains(right), false))
                index += 1
            }
        }
    }
    
    return entries
}

public func channelAdminController(account: Account, peerId: PeerId, adminId: PeerId, initialParticipant: ChannelParticipant?, updated: @escaping (TelegramChannelAdminRights) -> Void) -> ViewController {
    let statePromise = ValuePromise(ChannelAdminControllerState(), ignoreRepeated: true)
    let stateValue = Atomic(value: ChannelAdminControllerState())
    let updateState: ((ChannelAdminControllerState) -> ChannelAdminControllerState) -> Void = { f in
        statePromise.set(stateValue.modify { f($0) })
    }
    
    let actionsDisposable = DisposableSet()
    
    let updateRightsDisposable = MetaDisposable()
    actionsDisposable.add(updateRightsDisposable)
    
    var dismissImpl: (() -> Void)?
    
    let arguments = ChannelAdminControllerArguments(account: account, toggleRight: { right, flags in
        updateState { current in
            var updated = flags
            if flags.contains(right) {
                updated.remove(right)
            } else {
                updated.insert(right)
            }
            return current.withUpdatedUpdatedFlags(updated)
        }
    }, dismissAdmin: {
        updateState { current in
            return current.withUpdatedUpdating(true)
        }
        updateRightsDisposable.set((updatePeerAdminRights(account: account, peerId: peerId, adminId: adminId, rights: TelegramChannelAdminRights(flags: [])) |> deliverOnMainQueue).start(error: { _ in
            
        }, completed: {
            updated(TelegramChannelAdminRights(flags: []))
            dismissImpl?()
        }))
    })
    
    let combinedView = account.postbox.combinedView(keys: [.peer(peerId: peerId), .peer(peerId: adminId)])
    
    let signal = combineLatest((account.applicationContext as! TelegramApplicationContext).presentationData, statePromise.get(), combinedView)
        |> deliverOnMainQueue
        |> map { presentationData, state, combinedView -> (ItemListControllerState, (ItemListNodeState<ChannelAdminEntry>, ChannelAdminEntry.ItemGenerationArguments)) in
            let channelView = combinedView.views[.peer(peerId: peerId)] as! PeerView
            let adminView = combinedView.views[.peer(peerId: adminId)] as! PeerView
            let canEdit = canEditAdminRights(accountPeerId: account.peerId, channelView: channelView, initialParticipant: initialParticipant)
            
            let leftNavigationButton: ItemListNavigationButton
            if canEdit {
                leftNavigationButton = ItemListNavigationButton(title: presentationData.strings.Common_Cancel, style: .regular, enabled: true, action: {
                    dismissImpl?()
                })
            } else {
                leftNavigationButton = ItemListNavigationButton(title: presentationData.strings.Common_Done, style: .bold, enabled: true, action: {
                    dismissImpl?()
                })
            }
            
            var rightNavigationButton: ItemListNavigationButton?
            if state.updating {
                rightNavigationButton = ItemListNavigationButton(title: "", style: .activity, enabled: true, action: {})
            } else if canEdit {
                rightNavigationButton = ItemListNavigationButton(title: presentationData.strings.Common_Done, style: .bold, enabled: true, action: {
                    var updateFlags: TelegramChannelAdminRightsFlags?
                    updateState { current in
                        updateFlags = current.updatedFlags
                        if let _ = updateFlags {
                            return current.withUpdatedUpdating(true)
                        } else {
                            return current
                        }
                    }
                    if let updateFlags = updateFlags {
                        updateRightsDisposable.set((updatePeerAdminRights(account: account, peerId: peerId, adminId: adminId, rights: TelegramChannelAdminRights(flags: updateFlags)) |> deliverOnMainQueue).start(error: { _ in
                            
                        }, completed: {
                            updated(TelegramChannelAdminRights(flags: updateFlags))
                            dismissImpl?()
                        }))
                    }
                })
            }
            
            let controllerState = ItemListControllerState(theme: presentationData.theme, title: .text(presentationData.strings.Channel_Management_LabelEditor), leftNavigationButton: leftNavigationButton, rightNavigationButton: rightNavigationButton, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back), animateChanges: false)
            
            let listState = ItemListNodeState(entries: channelAdminControllerEntries(presentationData: presentationData, state: state, accountPeerId: account.peerId, channelView: channelView, adminView: adminView, initialParticipant: initialParticipant), style: .blocks, emptyStateItem: nil, animateChanges: true)
            
            return (controllerState, (listState, arguments))
        } |> afterDisposed {
            actionsDisposable.dispose()
    }
    
    let controller = ItemListController(account: account, state: signal)
    dismissImpl = { [weak controller] in
        controller?.dismiss()
    }
    return controller
}
