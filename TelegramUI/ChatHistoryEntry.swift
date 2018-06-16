import Postbox
import TelegramCore

public enum ChatHistoryMessageSelection: Equatable {
    case none
    case selectable(selected: Bool)
    
    public static func ==(lhs: ChatHistoryMessageSelection, rhs: ChatHistoryMessageSelection) -> Bool {
        switch lhs {
            case .none:
                if case .none = rhs {
                    return true
                } else {
                    return false
                }
            case let .selectable(selected):
                if case .selectable(selected) = rhs {
                    return true
                } else {
                    return false
                }
        }
    }
}

enum ChatHistoryEntry: Identifiable, Comparable {
    case HoleEntry(MessageHistoryHole, PresentationTheme, PresentationStrings)
    case MessageEntry(Message, ChatPresentationData, Bool, MessageHistoryEntryMonthLocation?, ChatHistoryMessageSelection, Bool)
    case MessageGroupEntry(MessageGroupInfo, [(Message, Bool, ChatHistoryMessageSelection, Bool)], ChatPresentationData)
    case UnreadEntry(MessageIndex, PresentationTheme, PresentationStrings)
    case ChatInfoEntry(String, PresentationTheme, PresentationStrings)
    case EmptyChatInfoEntry(PresentationTheme, PresentationStrings, MessageTags?)
    case SearchEntry(PresentationTheme, PresentationStrings)
    
    var stableId: UInt64 {
        switch self {
            case let .HoleEntry(hole, _, _):
                return UInt64(hole.stableId) | ((UInt64(1) << 40))
            case let .MessageEntry(message, _, _, _, _, _):
                return UInt64(message.stableId) | ((UInt64(2) << 40))
            case let .MessageGroupEntry(groupInfo, _, _):
                return UInt64(groupInfo.stableId) | ((UInt64(2) << 40))
            case .UnreadEntry:
                return UInt64(3) << 40
            case .ChatInfoEntry:
                return UInt64(4) << 40
            case .EmptyChatInfoEntry:
                return UInt64(5) << 40
            case .SearchEntry:
                return UInt64(6) << 40
        }
    }
    
    var index: MessageIndex {
        switch self {
            case let .HoleEntry(hole, _, _):
                return hole.maxIndex
            case let .MessageEntry(message, _, _, _, _, _):
                return MessageIndex(message)
            case let .MessageGroupEntry(_, messages, _):
                return MessageIndex(messages[messages.count - 1].0)
            case let .UnreadEntry(index, _, _):
                return index
            case .ChatInfoEntry:
                return MessageIndex.absoluteLowerBound()
            case .EmptyChatInfoEntry:
                return MessageIndex.absoluteLowerBound()
            case .SearchEntry:
                return MessageIndex.absoluteLowerBound()
        }
    }

    static func ==(lhs: ChatHistoryEntry, rhs: ChatHistoryEntry) -> Bool {
        switch lhs {
            case let .HoleEntry(lhsHole, lhsTheme, lhsStrings):
                if case let .HoleEntry(rhsHole, rhsTheme, rhsStrings) = rhs, lhsHole == rhsHole, lhsTheme === rhsTheme, lhsStrings === rhsStrings {
                    return true
                } else {
                    return false
                }
            case let .MessageEntry(lhsMessage, lhsPresentationData, lhsRead, _, lhsSelection, lhsIsAdmin):
                switch rhs {
                    case let .MessageEntry(rhsMessage, rhsPresentationData, rhsRead, _, rhsSelection, rhsIsAdmin) where MessageIndex(lhsMessage) == MessageIndex(rhsMessage) && lhsMessage.flags == rhsMessage.flags && lhsRead == rhsRead:
                        if lhsPresentationData !== rhsPresentationData {
                            return false
                        }
                        if lhsMessage.stableVersion != rhsMessage.stableVersion {
                            return false
                        }
                        if lhsMessage.media.count != rhsMessage.media.count {
                            return false
                        }
                        for i in 0 ..< lhsMessage.media.count {
                            if !lhsMessage.media[i].isEqual(rhsMessage.media[i]) {
                                return false
                            }
                        }
                        if lhsMessage.associatedMessages.count != rhsMessage.associatedMessages.count {
                            return false
                        }
                        if !lhsMessage.associatedMessages.isEmpty {
                            for (id, message) in lhsMessage.associatedMessages {
                                if let otherMessage = rhsMessage.associatedMessages[id] {
                                    if otherMessage.stableVersion != message.stableVersion {
                                        return false
                                    }
                                }
                            }
                        }
                        if lhsSelection != rhsSelection {
                            return false
                        }
                        if lhsIsAdmin != rhsIsAdmin {
                            return false
                        }
                        return true
                    default:
                        return false
                }
            case let .MessageGroupEntry(lhsGroupInfo, lhsMessages, lhsPresentationData):
                if case let .MessageGroupEntry(rhsGroupInfo, rhsMessages, rhsPresentationData) = rhs, lhsGroupInfo == rhsGroupInfo, lhsPresentationData === rhsPresentationData, lhsMessages.count == rhsMessages.count {
                    for i in 0 ..< lhsMessages.count {
                        let (lhsMessage, lhsRead, lhsSelection, lhsIsAdmin) = lhsMessages[i]
                        let (rhsMessage, rhsRead, rhsSelection, rhsIsAdmin) = rhsMessages[i]
                        
                        if lhsMessage.id != rhsMessage.id {
                            return false
                        }
                        if lhsMessage.timestamp != rhsMessage.timestamp {
                            return false
                        }
                        if lhsMessage.flags != rhsMessage.flags {
                            return false
                        }
                        if lhsRead != rhsRead {
                            return false
                        }
                        if lhsSelection != rhsSelection {
                            return false
                        }
                        if lhsPresentationData !== rhsPresentationData {
                            return false
                        }
                        if lhsMessage.stableVersion != rhsMessage.stableVersion {
                            return false
                        }
                        if lhsMessage.media.count != rhsMessage.media.count {
                            return false
                        }
                        for i in 0 ..< lhsMessage.media.count {
                            if !lhsMessage.media[i].isEqual(rhsMessage.media[i]) {
                                return false
                            }
                        }
                        if lhsMessage.associatedMessages.count != rhsMessage.associatedMessages.count {
                            return false
                        }
                        if !lhsMessage.associatedMessages.isEmpty {
                            for (id, message) in lhsMessage.associatedMessages {
                                if let otherMessage = rhsMessage.associatedMessages[id] {
                                    if otherMessage.stableVersion != message.stableVersion {
                                        return false
                                    }
                                }
                            }
                        }
                        if lhsIsAdmin != rhsIsAdmin {
                            return false
                        }
                    }
                    
                    return true
                } else {
                    return false
                }
            case let .UnreadEntry(lhsIndex, lhsTheme, lhsStrings):
                if case let .UnreadEntry(rhsIndex, rhsTheme, rhsStrings) = rhs, lhsIndex == rhsIndex, lhsTheme === rhsTheme, lhsStrings === rhsStrings {
                    return true
                } else {
                    return false
                }
            case let .ChatInfoEntry(lhsText, lhsTheme, lhsStrings):
                if case let .ChatInfoEntry(rhsText, rhsTheme, rhsStrings) = rhs, lhsText == rhsText, lhsTheme === rhsTheme, lhsStrings === rhsStrings {
                    return true
                } else {
                    return false
                }
            case let .EmptyChatInfoEntry(lhsTheme, lhsStrings, lhsTagMask):
                if case let .EmptyChatInfoEntry(rhsTheme, rhsStrings, rhsTagMask) = rhs, lhsTheme === rhsTheme, lhsStrings === rhsStrings, lhsTagMask == rhsTagMask {
                    return true
                } else {
                    return false
                }
            case let .SearchEntry(lhsTheme, lhsStrings):
                if case let .SearchEntry(rhsTheme, rhsStrings) = rhs, lhsTheme === rhsTheme, lhsStrings === rhsStrings {
                    return true
                } else {
                    return false
                }
        }
    }
    
    static func <(lhs: ChatHistoryEntry, rhs: ChatHistoryEntry) -> Bool {
        let lhsIndex = lhs.index
        let rhsIndex = rhs.index
        if lhsIndex == rhsIndex {
            return lhs.stableId < rhs.stableId
        } else {
            return lhsIndex < rhsIndex
        }
    }
}
