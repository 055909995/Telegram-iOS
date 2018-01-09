import Foundation
import Display
import SwiftSignalKit
import Postbox
import TelegramCore

private final class DebugAccountsControllerArguments {
    let account: Account
    let presentController: (ViewController, ViewControllerPresentationArguments) -> Void
    
    let switchAccount: (AccountRecordId) -> Void
    let loginNewAccount: () -> Void
    
    init(account: Account, presentController: @escaping (ViewController, ViewControllerPresentationArguments) -> Void, switchAccount: @escaping (AccountRecordId) -> Void, loginNewAccount: @escaping () -> Void) {
        self.account = account
        self.presentController = presentController
        self.switchAccount = switchAccount
        self.loginNewAccount = loginNewAccount
    }
}

private enum DebugAccountsControllerSection: Int32 {
    case accounts
    case actions
}

private enum DebugAccountsControllerEntry: ItemListNodeEntry {
    case record(PresentationTheme, AccountRecord, Bool)
    case loginNewAccount(PresentationTheme)
    
    var section: ItemListSectionId {
        switch self {
            case .record:
                return DebugAccountsControllerSection.accounts.rawValue
            case .loginNewAccount:
                return DebugAccountsControllerSection.actions.rawValue
        }
    }
    
    var stableId: Int64 {
        switch self {
            case let .record(_, record, _):
                return record.id.int64
            case .loginNewAccount:
                return Int64.max
        }
    }
    
    static func ==(lhs: DebugAccountsControllerEntry, rhs: DebugAccountsControllerEntry) -> Bool {
        switch lhs {
            case let .record(lhsTheme, lhsRecord, lhsCurrent):
                if case let .record(rhsTheme, rhsRecord, rhsCurrent) = rhs, lhsTheme === rhsTheme, lhsRecord == rhsRecord, lhsCurrent == rhsCurrent {
                    return true
                } else {
                    return false
                }
            case let .loginNewAccount(lhsTheme):
                if case let .loginNewAccount(rhsTheme) = rhs, lhsTheme === rhsTheme {
                    return true
                } else {
                    return false
                }
        }
    }
    
    static func <(lhs: DebugAccountsControllerEntry, rhs: DebugAccountsControllerEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(_ arguments: DebugAccountsControllerArguments) -> ListViewItem {
        switch self {
            case let .record(theme, record, current):
                return ItemListCheckboxItem(theme: theme, title: "\(UInt64(bitPattern: record.id.int64))", checked: current, zeroSeparatorInsets: false, sectionId: self.section, action: {
                    arguments.switchAccount(record.id)
                })
            case let .loginNewAccount(theme):
                return ItemListActionItem(theme: theme, title: "Login to another account", kind: .generic, alignment: .natural, sectionId: self.section, style: .blocks, action: {
                    arguments.loginNewAccount()
                })
        }
    }
}

private func debugAccountsControllerEntries(view: AccountRecordsView, presentationData: PresentationData) -> [DebugAccountsControllerEntry] {
    var entries: [DebugAccountsControllerEntry] = []
    
    for entry in view.records.sorted(by: {
        $0.id < $1.id
    }) {
        entries.append(.record(presentationData.theme, entry, entry.id == view.currentRecord?.id))
    }
    
    entries.append(.loginNewAccount(presentationData.theme))
    
    return entries
}

public func debugAccountsController(account: Account, accountManager: AccountManager) -> ViewController {
    var presentControllerImpl: ((ViewController, ViewControllerPresentationArguments?) -> Void)?
    
    let arguments = DebugAccountsControllerArguments(account: account, presentController: { controller, arguments in
        presentControllerImpl?(controller, arguments)
    }, switchAccount: { id in
        let _ = accountManager.modify({ modifier -> Void in
            modifier.setCurrentId(id)
        }).start()
    }, loginNewAccount: {
        let _ = accountManager.modify({ modifier -> Void in
            let id = modifier.createRecord([])
            modifier.setCurrentId(id)
        }).start()
    })
    
    let signal = combineLatest((account.applicationContext as! TelegramApplicationContext).presentationData, accountManager.accountRecords())
        |> map { presentationData, view -> (ItemListControllerState, (ItemListNodeState<DebugAccountsControllerEntry>, DebugAccountsControllerEntry.ItemGenerationArguments)) in
            let controllerState = ItemListControllerState(theme: presentationData.theme, title: .text("Accounts"), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
            let listState = ItemListNodeState(entries: debugAccountsControllerEntries(view: view, presentationData: presentationData), style: .blocks)
            
            return (controllerState, (listState, arguments))
    }
    
    let controller = ItemListController(account: account, state: signal)
    presentControllerImpl = { [weak controller] c, a in
        controller?.present(c, in: .window(.root), with: a)
    }
    return controller
}
