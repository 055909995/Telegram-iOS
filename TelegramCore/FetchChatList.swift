import Foundation
#if os(macOS)
    import PostboxMac
    import SwiftSignalKitMac
    import MtProtoKitMac
#else
    import Postbox
    import SwiftSignalKit
    import MtProtoKitDynamic
#endif

enum FetchChatListLocation {
    case general
    case group(PeerGroupId)
}

struct ParsedDialogs {
    let itemIds: [PinnedItemId]
    let peers: [Peer]
    let peerPresences: [PeerId: PeerPresence]
    
    let notificationSettings: [PeerId: PeerNotificationSettings]
    let readStates: [PeerId: [MessageId.Namespace: PeerReadState]]
    let mentionTagSummaries: [PeerId: MessageHistoryTagNamespaceSummary]
    let chatStates: [PeerId: PeerChatState]
    
    let storeMessages: [StoreMessage]
    
    let lowerNonPinnedIndex: MessageIndex?
    let referencedFeeds: [PeerGroupId]
}

private func extractDialogsData(dialogs: Api.messages.Dialogs) -> (apiDialogs: [Api.Dialog], apiMessages: [Api.Message], apiChats: [Api.Chat], apiUsers: [Api.User], apiIsAtLowestBoundary: Bool) {
    switch dialogs {
        case let .dialogs(dialogs, messages, chats, users):
            return (dialogs, messages, chats, users, true)
        case let .dialogsSlice(_, dialogs, messages, chats, users):
            return (dialogs, messages, chats, users, false)
    }
}

private func extractDialogsData(peerDialogs: Api.messages.PeerDialogs) -> (apiDialogs: [Api.Dialog], apiMessages: [Api.Message], apiChats: [Api.Chat], apiUsers: [Api.User], apiIsAtLowestBoundary: Bool) {
    switch peerDialogs {
        case let .peerDialogs(dialogs, messages, chats, users, _):
            return (dialogs, messages, chats, users, false)
    }
}

private func parseDialogs(apiDialogs: [Api.Dialog], apiMessages: [Api.Message], apiChats: [Api.Chat], apiUsers: [Api.User], apiIsAtLowestBoundary: Bool) -> ParsedDialogs {
    var notificationSettings: [PeerId: PeerNotificationSettings] = [:]
    var readStates: [PeerId: [MessageId.Namespace: PeerReadState]] = [:]
    var mentionTagSummaries: [PeerId: MessageHistoryTagNamespaceSummary] = [:]
    var chatStates: [PeerId: PeerChatState] = [:]
    
    var storeMessages: [StoreMessage] = []
    var nonPinnedDialogsTopMessageIds = Set<MessageId>()
    
    var referencedFeeds = Set<PeerGroupId>()
    var itemIds: [PinnedItemId] = []
    
    for dialog in apiDialogs {
        let apiPeer: Api.Peer
        let apiReadInboxMaxId: Int32
        let apiReadOutboxMaxId: Int32
        let apiTopMessage: Int32
        let apiUnreadCount: Int32
        let apiMarkedUnread: Bool
        let apiUnreadMentionsCount: Int32
        var apiChannelPts: Int32?
        let apiNotificationSettings: Api.PeerNotifySettings
        switch dialog {
            case let .dialog(flags, peer, topMessage, readInboxMaxId, readOutboxMaxId, unreadCount, unreadMentionsCount, peerNotificationSettings, pts, _):
                itemIds.append(.peer(peer.peerId))
                apiPeer = peer
                apiTopMessage = topMessage
                apiReadInboxMaxId = readInboxMaxId
                apiReadOutboxMaxId = readOutboxMaxId
                apiUnreadCount = unreadCount
                apiMarkedUnread = (flags & (1 << 3)) != 0
                apiUnreadMentionsCount = unreadMentionsCount
                apiNotificationSettings = peerNotificationSettings
                apiChannelPts = pts
                let isPinned = (flags & (1 << 2)) != 0
                if !isPinned {
                    nonPinnedDialogsTopMessageIds.insert(MessageId(peerId: peer.peerId, namespace: Namespaces.Message.Cloud, id: topMessage))
                }
                let peerId: PeerId
                switch apiPeer {
                    case let .peerUser(userId):
                        peerId = PeerId(namespace: Namespaces.Peer.CloudUser, id: userId)
                    case let .peerChat(chatId):
                        peerId = PeerId(namespace: Namespaces.Peer.CloudGroup, id: chatId)
                    case let .peerChannel(channelId):
                        peerId = PeerId(namespace: Namespaces.Peer.CloudChannel, id: channelId)
                }
                
                if readStates[peerId] == nil {
                    readStates[peerId] = [:]
                }
                readStates[peerId]![Namespaces.Message.Cloud] = .idBased(maxIncomingReadId: apiReadInboxMaxId, maxOutgoingReadId: apiReadOutboxMaxId, maxKnownId: apiTopMessage, count: apiUnreadCount, markedUnread: apiMarkedUnread)
                
                if apiTopMessage != 0 {
                    mentionTagSummaries[peerId] = MessageHistoryTagNamespaceSummary(version: 1, count: apiUnreadMentionsCount, range: MessageHistoryTagNamespaceCountValidityRange(maxId: apiTopMessage))
                }
                
                if let apiChannelPts = apiChannelPts {
                    chatStates[peerId] = ChannelState(pts: apiChannelPts, invalidatedPts: nil)
                }
                
                notificationSettings[peerId] = TelegramPeerNotificationSettings(apiSettings: apiNotificationSettings)
            /*feed*/
            /*case let .dialogFeed(_, _, _, feedId, _, _, _, _):
                itemIds.append(.group(PeerGroupId(rawValue: feedId)))
                referencedFeeds.insert(PeerGroupId(rawValue: feedId))*/
        }
    }
    
    var lowerNonPinnedIndex: MessageIndex?
    
    for message in apiMessages {
        if let storeMessage = StoreMessage(apiMessage: message) {
            var updatedStoreMessage = storeMessage
            if case let .Id(id) = storeMessage.id {
                if let channelState = chatStates[id.peerId] as? ChannelState {
                    var updatedAttributes = storeMessage.attributes
                    updatedAttributes.append(ChannelMessageStateVersionAttribute(pts: channelState.pts))
                    updatedStoreMessage = updatedStoreMessage.withUpdatedAttributes(updatedAttributes)
                }
                
                if !apiIsAtLowestBoundary, nonPinnedDialogsTopMessageIds.contains(id) {
                    let index = MessageIndex(id: id, timestamp: storeMessage.timestamp)
                    if lowerNonPinnedIndex == nil || lowerNonPinnedIndex! > index {
                        lowerNonPinnedIndex = index
                    }
                }
            }
            storeMessages.append(updatedStoreMessage)
        }
    }
    
    var peers: [Peer] = []
    var peerPresences: [PeerId: PeerPresence] = [:]
    for chat in apiChats {
        if let groupOrChannel = parseTelegramGroupOrChannel(chat: chat) {
            peers.append(groupOrChannel)
        }
    }
    for user in apiUsers {
        let telegramUser = TelegramUser(user: user)
        peers.append(telegramUser)
        if let presence = TelegramUserPresence(apiUser: user) {
            peerPresences[telegramUser.id] = presence
        }
    }
    
    return ParsedDialogs(
        itemIds: itemIds,
        peers: peers,
        peerPresences: peerPresences,
    
        notificationSettings: notificationSettings,
        readStates: readStates,
        mentionTagSummaries: mentionTagSummaries,
        chatStates: chatStates,
    
        storeMessages: storeMessages,
    
        lowerNonPinnedIndex: lowerNonPinnedIndex,
        referencedFeeds: Array(referencedFeeds)
    )
}

struct FetchedChatList {
    let peers: [Peer]
    let peerPresences: [PeerId: PeerPresence]
    let notificationSettings: [PeerId: PeerNotificationSettings]
    let readStates: [PeerId: [MessageId.Namespace: PeerReadState]]
    let mentionTagSummaries: [PeerId: MessageHistoryTagNamespaceSummary]
    let chatStates: [PeerId: PeerChatState]
    let storeMessages: [StoreMessage]
    
    let lowerNonPinnedIndex: MessageIndex?
    
    let pinnedItemIds: [PinnedItemId]?
    let feeds: [(PeerGroupId, MessageIndex?)]
}

func fetchChatList(postbox: Postbox, network: Network, location: FetchChatListLocation, upperBound: MessageIndex) -> Signal<FetchedChatList, NoError> {
    let offset: Signal<(Int32, Int32, Api.InputPeer), NoError>
    if upperBound.id.peerId.namespace == Namespaces.Peer.Empty {
        offset = single((0, 0, Api.InputPeer.inputPeerEmpty), NoError.self)
    } else {
        offset = postbox.loadedPeerWithId(upperBound.id.peerId)
            |> take(1)
            |> map { peer in
                return (upperBound.timestamp, upperBound.id.id + 1, apiInputPeer(peer) ?? .inputPeerEmpty)
        }
    }
    
    return offset
    |> mapToSignal { (timestamp, id, peer) -> Signal<FetchedChatList, NoError> in
        let additionalPinnedChats: Signal<Api.messages.PeerDialogs?, NoError>
        if case .general = location, case .inputPeerEmpty = peer, timestamp == 0 {
            additionalPinnedChats = network.request(Api.functions.messages.getPinnedDialogs())
                |> retryRequest
                |> map { Optional($0) }
        } else {
            additionalPinnedChats = .single(nil)
        }
        
        var flags: Int32 = 0
        var requestFeedId: Int32?
        
        switch location {
            case .general:
                break
            case let .group(groupId):
                /*feed*/
                /*requestFeedId = groupId.rawValue
                flags |= 1 << 1*/
                break
        }
        let requestChats = network.request(Api.functions.messages.getDialogs(flags: flags/*feed*//*, feedId: requestFeedId*/, offsetDate: timestamp, offsetId: id, offsetPeer: peer, limit: 100))
            |> retryRequest
        
        return combineLatest(requestChats, additionalPinnedChats)
        |> mapToSignal { remoteChats, pinnedChats -> Signal<FetchedChatList, NoError> in
            let extractedRemoteDialogs = extractDialogsData(dialogs: remoteChats)
            let parsedRemoteChats = parseDialogs(apiDialogs: extractedRemoteDialogs.apiDialogs, apiMessages: extractedRemoteDialogs.apiMessages, apiChats: extractedRemoteDialogs.apiChats, apiUsers: extractedRemoteDialogs.apiUsers, apiIsAtLowestBoundary: extractedRemoteDialogs.apiIsAtLowestBoundary)
            var parsedPinnedChats: ParsedDialogs?
            if let pinnedChats = pinnedChats {
                let extractedPinnedChats = extractDialogsData(peerDialogs: pinnedChats)
                parsedPinnedChats = parseDialogs(apiDialogs: extractedPinnedChats.apiDialogs, apiMessages: extractedPinnedChats.apiMessages, apiChats: extractedPinnedChats.apiChats, apiUsers: extractedPinnedChats.apiUsers, apiIsAtLowestBoundary: extractedPinnedChats.apiIsAtLowestBoundary)
            }
            
            var combinedReferencedFeeds = Set<PeerGroupId>()
            combinedReferencedFeeds.formUnion(parsedRemoteChats.referencedFeeds)
            if let parsedPinnedChats = parsedPinnedChats {
                combinedReferencedFeeds.formUnion(parsedPinnedChats.referencedFeeds)
            }
            
            var feedSignals: [Signal<(PeerGroupId, ParsedDialogs), NoError>] = []
            if case .general = location {
                /*feed*/
                /*for groupId in combinedReferencedFeeds {
                    let flags: Int32 = 1 << 1
                    let requestFeed = network.request(Api.functions.messages.getDialogs(flags: flags, feedId: groupId.rawValue, offsetDate: 0, offsetId: 0, offsetPeer: .inputPeerEmpty, limit: 4))
                        |> retryRequest
                        |> map { result -> (PeerGroupId, ParsedDialogs) in
                            let extractedData = extractDialogsData(dialogs: result)
                            let parsedChats = parseDialogs(apiDialogs: extractedData.apiDialogs, apiMessages: extractedData.apiMessages, apiChats: extractedData.apiChats, apiUsers: extractedData.apiUsers, apiIsAtLowestBoundary: extractedData.apiIsAtLowestBoundary)
                            return (groupId, parsedChats)
                        }
                    feedSignals.append(requestFeed)
                }*/
            }
            
            return combineLatest(feedSignals)
            |> map { feeds -> FetchedChatList in
                var peers: [Peer] = []
                var peerPresences: [PeerId: PeerPresence] = [:]
                var notificationSettings: [PeerId: PeerNotificationSettings] = [:]
                var readStates: [PeerId: [MessageId.Namespace: PeerReadState]] = [:]
                var mentionTagSummaries: [PeerId: MessageHistoryTagNamespaceSummary] = [:]
                var chatStates: [PeerId: PeerChatState] = [:]
                var storeMessages: [StoreMessage] = []
                
                peers.append(contentsOf: parsedRemoteChats.peers)
                peerPresences.merge(parsedRemoteChats.peerPresences, uniquingKeysWith: { _, updated in updated })
                notificationSettings.merge(parsedRemoteChats.notificationSettings, uniquingKeysWith: { _, updated in updated })
                readStates.merge(parsedRemoteChats.readStates, uniquingKeysWith: { _, updated in updated })
                mentionTagSummaries.merge(parsedRemoteChats.mentionTagSummaries, uniquingKeysWith: { _, updated in updated })
                chatStates.merge(parsedRemoteChats.chatStates, uniquingKeysWith: { _, updated in updated })
                storeMessages.append(contentsOf: parsedRemoteChats.storeMessages)
                
                if let parsedPinnedChats = parsedPinnedChats {
                    peers.append(contentsOf: parsedPinnedChats.peers)
                    peerPresences.merge(parsedPinnedChats.peerPresences, uniquingKeysWith: { _, updated in updated })
                    notificationSettings.merge(parsedPinnedChats.notificationSettings, uniquingKeysWith: { _, updated in updated })
                    readStates.merge(parsedPinnedChats.readStates, uniquingKeysWith: { _, updated in updated })
                    mentionTagSummaries.merge(parsedPinnedChats.mentionTagSummaries, uniquingKeysWith: { _, updated in updated })
                    chatStates.merge(parsedPinnedChats.chatStates, uniquingKeysWith: { _, updated in updated })
                    storeMessages.append(contentsOf: parsedPinnedChats.storeMessages)
                }
                
                for (_, feedChats) in feeds {
                    peers.append(contentsOf: feedChats.peers)
                    peerPresences.merge(feedChats.peerPresences, uniquingKeysWith: { _, updated in updated })
                    notificationSettings.merge(feedChats.notificationSettings, uniquingKeysWith: { _, updated in updated })
                    readStates.merge(feedChats.readStates, uniquingKeysWith: { _, updated in updated })
                    mentionTagSummaries.merge(feedChats.mentionTagSummaries, uniquingKeysWith: { _, updated in updated })
                    chatStates.merge(feedChats.chatStates, uniquingKeysWith: { _, updated in updated })
                    storeMessages.append(contentsOf: feedChats.storeMessages)
                }
                
                return FetchedChatList(
                    peers: peers,
                    peerPresences: peerPresences,
                    notificationSettings: notificationSettings,
                    readStates: readStates,
                	mentionTagSummaries: mentionTagSummaries,
                	chatStates: chatStates,
                	storeMessages: storeMessages,
                
                	lowerNonPinnedIndex: parsedRemoteChats.lowerNonPinnedIndex,
                
                    pinnedItemIds: parsedPinnedChats.flatMap { $0.itemIds },
                    feeds: feeds.map { ($0.0, $0.1.lowerNonPinnedIndex) }
                )
            }
        }
    }
}
