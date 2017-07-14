import Foundation
import Display
import SwiftSignalKit
import Postbox
import TelegramCore

private enum NetworkUsageControllerSection {
    case cellular
    case wifi
}

private final class NetworkUsageStatsControllerArguments {
    let resetStatistics: (NetworkUsageControllerSection) -> Void
    
    init(resetStatistics: @escaping (NetworkUsageControllerSection) -> Void) {
        self.resetStatistics = resetStatistics
    }
}

private enum NetworkUsageStatsSection: Int32 {
    case messages
    case image
    case video
    case audio
    case file
    case call
    case total
    case reset
}

private enum NetworkUsageStatsEntry: ItemListNodeEntry {
    case messagesHeader(PresentationTheme, String)
    case messagesSent(PresentationTheme, String, String)
    case messagesReceived(PresentationTheme, String, String)
    
    case imageHeader(PresentationTheme, String)
    case imageSent(PresentationTheme, String, String)
    case imageReceived(PresentationTheme, String, String)
    
    case videoHeader(PresentationTheme, String)
    case videoSent(PresentationTheme, String, String)
    case videoReceived(PresentationTheme, String, String)
    
    case audioHeader(PresentationTheme, String)
    case audioSent(PresentationTheme, String, String)
    case audioReceived(PresentationTheme, String, String)
    
    case fileHeader(PresentationTheme, String)
    case fileSent(PresentationTheme, String, String)
    case fileReceived(PresentationTheme, String, String)
    
    case callHeader(PresentationTheme, String)
    case callSent(PresentationTheme, String, String)
    case callReceived(PresentationTheme, String, String)
    
    case reset(PresentationTheme, NetworkUsageControllerSection, String)
    case resetTimestamp(PresentationTheme, String)
    
    var section: ItemListSectionId {
        switch self {
            case .messagesHeader, .messagesSent, .messagesReceived:
                return NetworkUsageStatsSection.messages.rawValue
            case .imageHeader, .imageSent, .imageReceived:
                return NetworkUsageStatsSection.image.rawValue
            case .videoHeader, .videoSent, .videoReceived:
                return NetworkUsageStatsSection.video.rawValue
            case .audioHeader, .audioSent, .audioReceived:
                return NetworkUsageStatsSection.audio.rawValue
            case .fileHeader, .fileSent, .fileReceived:
                return NetworkUsageStatsSection.file.rawValue
            case .callHeader, .callSent, .callReceived:
                return NetworkUsageStatsSection.call.rawValue
            case .reset, .resetTimestamp:
                return NetworkUsageStatsSection.reset.rawValue
        }
    }
    
    var stableId: Int32 {
        switch self {
            case .messagesHeader:
                return 0
            case .messagesSent:
                return 1
            case .messagesReceived:
                return 2
            case .imageHeader:
                return 3
            case .imageSent:
                return 4
            case .imageReceived:
                return 5
            case .videoHeader:
                return 6
            case .videoSent:
                return 7
            case .videoReceived:
                return 8
            case .audioHeader:
                return 9
            case .audioSent:
                return 10
            case .audioReceived:
                return 11
            case .fileHeader:
                return 12
            case .fileSent:
                return 13
            case .fileReceived:
                return 14
            case .callHeader:
                return 15
            case .callSent:
                return 16
            case .callReceived:
                return 17
            case .reset:
                return 18
            case .resetTimestamp:
                return 19
        }
    }
    
    static func ==(lhs: NetworkUsageStatsEntry, rhs: NetworkUsageStatsEntry) -> Bool {
        switch lhs {
            case let .messagesHeader(lhsTheme, lhsText):
                if case let .messagesHeader(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .messagesSent(lhsTheme, lhsText, lhsValue):
                if case let .messagesSent(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .messagesReceived(lhsTheme, lhsText, lhsValue):
                if case let .messagesReceived(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .imageHeader(lhsTheme, lhsText):
                if case let .imageHeader(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .imageSent(lhsTheme, lhsText, lhsValue):
                if case let .imageSent(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .imageReceived(lhsTheme, lhsText, lhsValue):
                if case let .imageReceived(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .videoHeader(lhsTheme, lhsText):
                if case let .videoHeader(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .videoSent(lhsTheme, lhsText, lhsValue):
                if case let .videoSent(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .videoReceived(lhsTheme, lhsText, lhsValue):
                if case let .videoReceived(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .audioHeader(lhsTheme, lhsText):
                if case let .audioHeader(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .audioSent(lhsTheme, lhsText, lhsValue):
                if case let .audioSent(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .audioReceived(lhsTheme, lhsText, lhsValue):
                if case let .audioReceived(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .fileHeader(lhsTheme, lhsText):
                if case let .fileHeader(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .fileSent(lhsTheme, lhsText, lhsValue):
                if case let .fileSent(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .fileReceived(lhsTheme, lhsText, lhsValue):
                if case let .fileReceived(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .callHeader(lhsTheme, lhsText):
                if case let .callHeader(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .callSent(lhsTheme, lhsText, lhsValue):
                if case let .callSent(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .callReceived(lhsTheme, lhsText, lhsValue):
                if case let .callReceived(rhsTheme, rhsText, rhsValue) = rhs, lhsTheme === rhsTheme, lhsText == rhsText, lhsValue == rhsValue {
                    return true
                } else {
                    return false
                }
            case let .reset(lhsTheme, lhsSection, lhsText):
                if case let .reset(rhsTheme, rhsSection, rhsText) = rhs, lhsTheme === rhsTheme, lhsSection == rhsSection, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
            case let .resetTimestamp(lhsTheme, lhsText):
                if case let .resetTimestamp(rhsTheme, rhsText) = rhs, lhsTheme === rhsTheme, lhsText == rhsText {
                    return true
                } else {
                    return false
                }
        }
    }
    
    static func <(lhs: NetworkUsageStatsEntry, rhs: NetworkUsageStatsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(_ arguments: NetworkUsageStatsControllerArguments) -> ListViewItem {
        switch self {
            case let .messagesHeader(theme, text):
                return ItemListSectionHeaderItem(theme: theme, text: text, sectionId: self.section)
            case let .messagesSent(theme, text, value):
                return ItemListDisclosureItem(theme: theme, title: text, label: value, sectionId: self.section, style: .blocks, disclosureStyle: .none , action: nil)
            case let .messagesReceived(theme, text, value):
                return ItemListDisclosureItem(theme: theme, title: text, label: value, sectionId: self.section, style: .blocks, disclosureStyle: .none , action: nil)
            case let .imageHeader(theme, text):
                return ItemListSectionHeaderItem(theme: theme, text: text, sectionId: self.section)
            case let .imageSent(theme, text, value):
                return ItemListDisclosureItem(theme: theme, title: text, label: value, sectionId: self.section, style: .blocks, disclosureStyle: .none , action: nil)
            case let .imageReceived(theme, text, value):
                return ItemListDisclosureItem(theme: theme, title: text, label: value, sectionId: self.section, style: .blocks, disclosureStyle: .none , action: nil)
            case let .videoHeader(theme, text):
                return ItemListSectionHeaderItem(theme: theme, text: text, sectionId: self.section)
            case let .videoSent(theme, text, value):
                return ItemListDisclosureItem(theme: theme, title: text, label: value, sectionId: self.section, style: .blocks, disclosureStyle: .none , action: nil)
            case let .videoReceived(theme, text, value):
                return ItemListDisclosureItem(theme: theme, title: text, label: value, sectionId: self.section, style: .blocks, disclosureStyle: .none , action: nil)
            case let .audioHeader(theme, text):
                return ItemListSectionHeaderItem(theme: theme, text: text, sectionId: self.section)
            case let .audioSent(theme, text, value):
                return ItemListDisclosureItem(theme: theme, title: text, label: value, sectionId: self.section, style: .blocks, disclosureStyle: .none , action: nil)
            case let .audioReceived(theme, text, value):
                return ItemListDisclosureItem(theme: theme, title: text, label: value, sectionId: self.section, style: .blocks, disclosureStyle: .none , action: nil)
            case let .fileHeader(theme, text):
                return ItemListSectionHeaderItem(theme: theme, text: text, sectionId: self.section)
            case let .fileSent(theme, text, value):
                return ItemListDisclosureItem(theme: theme, title: text, label: value, sectionId: self.section, style: .blocks, disclosureStyle: .none , action: nil)
            case let .fileReceived(theme, text, value):
                return ItemListDisclosureItem(theme: theme, title: text, label: value, sectionId: self.section, style: .blocks, disclosureStyle: .none , action: nil)
            case let .callHeader(theme, text):
                return ItemListSectionHeaderItem(theme: theme, text: text, sectionId: self.section)
            case let .callSent(theme, text, value):
                return ItemListDisclosureItem(theme: theme, title: text, label: value, sectionId: self.section, style: .blocks, disclosureStyle: .none , action: nil)
            case let .callReceived(theme, text, value):
                return ItemListDisclosureItem(theme: theme, title: text, label: value, sectionId: self.section, style: .blocks, disclosureStyle: .none , action: nil)
            case let .reset(theme, section, text):
                return ItemListActionItem(theme: theme, title: text, kind: .generic, alignment: .natural, sectionId: self.section, style: .blocks, action: {
                    arguments.resetStatistics(section)
                })
            case let .resetTimestamp(theme, text):
                return ItemListTextItem(theme: theme, text: .plain(text), sectionId: self.section)
        }
    }
}

private func networkUsageStatsControllerEntries(presentationData: PresentationData, section: NetworkUsageControllerSection, stats: NetworkUsageStats) -> [NetworkUsageStatsEntry] {
    var entries: [NetworkUsageStatsEntry] = []
    
    switch section {
        case .cellular:
            entries.append(.messagesHeader(presentationData.theme, "MESSAGES"))
            entries.append(.messagesSent(presentationData.theme, "Bytes Sent", dataSizeString(Int(stats.generic.cellular.outgoing))))
            entries.append(.messagesReceived(presentationData.theme, "Bytes Received", dataSizeString(Int(stats.generic.cellular.incoming))))
            
            entries.append(.imageHeader(presentationData.theme, "PHOTOS"))
            entries.append(.imageSent(presentationData.theme, "Bytes Sent", dataSizeString(Int(stats.image.cellular.outgoing))))
            entries.append(.imageReceived(presentationData.theme, "Bytes Received", dataSizeString(Int(stats.image.cellular.incoming))))
            
            entries.append(.videoHeader(presentationData.theme, "VIDEOS"))
            entries.append(.videoSent(presentationData.theme, "Bytes Sent", dataSizeString(Int(stats.video.cellular.outgoing))))
            entries.append(.videoReceived(presentationData.theme, "Bytes Received", dataSizeString(Int(stats.video.cellular.incoming))))
            
            entries.append(.audioHeader(presentationData.theme, "AUDIO"))
            entries.append(.audioSent(presentationData.theme, "Bytes Sent", dataSizeString(Int(stats.audio.cellular.outgoing))))
            entries.append(.audioReceived(presentationData.theme, "Bytes Received", dataSizeString(Int(stats.audio.cellular.incoming))))
            
            entries.append(.fileHeader(presentationData.theme, "DOCUMENTS"))
            entries.append(.fileSent(presentationData.theme, "Bytes Sent", dataSizeString(Int(stats.file.cellular.outgoing))))
            entries.append(.fileReceived(presentationData.theme, "Bytes Received", dataSizeString(Int(stats.file.cellular.incoming))))
            
            entries.append(.callHeader(presentationData.theme, "CALLS"))
            entries.append(.callSent(presentationData.theme, "Bytes Sent", dataSizeString(0)))
            entries.append(.callReceived(presentationData.theme, "Bytes Received", dataSizeString(0)))
            
            entries.append(.reset(presentationData.theme, section, "Reset Statistics"))
        
            if stats.resetCellularTimestamp != 0 {
                let formatter = DateFormatter()
                formatter.dateFormat = "E, d MMM yyyy HH:mm"
                let dateStringPlain = formatter.string(from: Date(timeIntervalSince1970: Double(stats.resetCellularTimestamp)))
                
                entries.append(.resetTimestamp(presentationData.theme, "Cellular usage since \(dateStringPlain)"))
            }
        case .wifi:
            entries.append(.messagesHeader(presentationData.theme, "MESSAGES"))
            entries.append(.messagesSent(presentationData.theme, "Bytes Sent", dataSizeString(Int(stats.generic.wifi.outgoing))))
            entries.append(.messagesReceived(presentationData.theme, "Bytes Received", dataSizeString(Int(stats.generic.wifi.incoming))))
            
            entries.append(.imageHeader(presentationData.theme, "PHOTOS"))
            entries.append(.imageSent(presentationData.theme, "Bytes Sent", dataSizeString(Int(stats.image.wifi.outgoing))))
            entries.append(.imageReceived(presentationData.theme, "Bytes Received", dataSizeString(Int(stats.image.wifi.incoming))))
            
            entries.append(.videoHeader(presentationData.theme, "VIDEOS"))
            entries.append(.videoSent(presentationData.theme, "Bytes Sent", dataSizeString(Int(stats.video.wifi.outgoing))))
            entries.append(.videoReceived(presentationData.theme, "Bytes Received", dataSizeString(Int(stats.video.wifi.incoming))))
            
            entries.append(.audioHeader(presentationData.theme, "AUDIO"))
            entries.append(.audioSent(presentationData.theme, "Bytes Sent", dataSizeString(Int(stats.audio.wifi.outgoing))))
            entries.append(.audioReceived(presentationData.theme, "Bytes Received", dataSizeString(Int(stats.audio.wifi.incoming))))
            
            entries.append(.fileHeader(presentationData.theme, "DOCUMENTS"))
            entries.append(.fileSent(presentationData.theme, "Bytes Sent", dataSizeString(Int(stats.file.wifi.outgoing))))
            entries.append(.fileReceived(presentationData.theme, "Bytes Received", dataSizeString(Int(stats.file.wifi.incoming))))
            
            entries.append(.callHeader(presentationData.theme, "CALLS"))
            entries.append(.callSent(presentationData.theme, "Bytes Sent", dataSizeString(0)))
            entries.append(.callReceived(presentationData.theme, "Bytes Received", dataSizeString(0)))
            
            entries.append(.reset(presentationData.theme, section, "Reset Statistics"))
            if stats.resetWifiTimestamp != 0 {
                let formatter = DateFormatter()
                formatter.dateFormat = "E, d MMM yyyy HH:mm"
                let dateStringPlain = formatter.string(from: Date(timeIntervalSince1970: Double(stats.resetWifiTimestamp)))
                
                entries.append(.resetTimestamp(presentationData.theme, "Wifi usage since \(dateStringPlain)"))
            }
    }
    
    return entries
}

func networkUsageStatsController(account: Account) -> ViewController {
    let section = ValuePromise<NetworkUsageControllerSection>(.cellular)
    let stats = Promise<NetworkUsageStats>()
    stats.set(accountNetworkUsageStats(account: account, reset: []))
    
    var presentControllerImpl: ((ViewController) -> Void)?
    
    let arguments = NetworkUsageStatsControllerArguments(resetStatistics: { [weak stats] section in
        let controller = ActionSheetController()
        let dismissAction: () -> Void = { [weak controller] in
            controller?.dismissAnimated()
        }
        controller.setItemGroups([
            ActionSheetItemGroup(items: [
                ActionSheetButtonItem(title: "Reset Statistics", color: .destructive, action: {
                    dismissAction()
                    
                    let reset: ResetNetworkUsageStats
                    switch section {
                        case .wifi:
                            reset = .wifi
                        case .cellular:
                            reset = .cellular
                    }
                    stats?.set(accountNetworkUsageStats(account: account, reset: reset))
                }),
            ]),
            ActionSheetItemGroup(items: [ActionSheetButtonItem(title: "Cancel", action: { dismissAction() })])
        ])
        presentControllerImpl?(controller)
    })
    
    let signal = combineLatest((account.applicationContext as! TelegramApplicationContext).presentationData, section.get(), stats.get()) |> deliverOnMainQueue
        |> map { presentationData, section, stats -> (ItemListControllerState, (ItemListNodeState<NetworkUsageStatsEntry>, NetworkUsageStatsEntry.ItemGenerationArguments)) in
            
            let controllerState = ItemListControllerState(theme: presentationData.theme, title: .sectionControl(["Cellular", "Wifi"], 0), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: "Back"), animateChanges: false)
            let listState = ItemListNodeState(entries: networkUsageStatsControllerEntries(presentationData: presentationData, section: section, stats: stats), style: .blocks, emptyStateItem: nil, animateChanges: false)
            
            return (controllerState, (listState, arguments))
    }
    
    let controller = ItemListController(account: account, state: signal)
    controller.titleControlValueChanged = { [weak section] index in
        section?.set(index == 0 ? .cellular : .wifi)
    }
    
    presentControllerImpl = { [weak controller] c in
        controller?.present(c, in: .window(.root), with: ViewControllerPresentationArguments(presentationAnimation: .modalSheet))
    }
    
    return controller
}
