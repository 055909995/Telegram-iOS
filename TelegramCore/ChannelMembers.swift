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

public enum ChannelMembersCategoryFilter {
    case all
    case search(String)
}

public enum ChannelMembersCategory {
    case recent(ChannelMembersCategoryFilter)
    case admins
    case restricted(ChannelMembersCategoryFilter)
    case banned(ChannelMembersCategoryFilter)
}

public func channelMembers(postbox: Postbox, network: Network, peerId: PeerId, category: ChannelMembersCategory = .recent(.all), offset: Int32 = 0, limit: Int32 = 64) -> Signal<[RenderedChannelParticipant], NoError> {
    return postbox.modify { modifier -> Signal<[RenderedChannelParticipant], NoError> in
        if let peer = modifier.getPeer(peerId), let inputChannel = apiInputChannel(peer) {
            let apiFilter: Api.ChannelParticipantsFilter
            switch category {
                case let .recent(filter):
                    switch filter {
                        case .all:
                            apiFilter = .channelParticipantsRecent
                        case let .search(query):
                            apiFilter = .channelParticipantsSearch(q: query)
                    }
                case .admins:
                    apiFilter = .channelParticipantsAdmins
                case let .restricted(filter):
                    switch filter {
                        case .all:
                            apiFilter = .channelParticipantsBanned(q: "")
                        case let .search(query):
                            apiFilter = .channelParticipantsBanned(q: query)
                    }
                case let .banned(filter):
                    switch filter {
                        case .all:
                            apiFilter = .channelParticipantsKicked(q: "")
                        case let .search(query):
                            apiFilter = .channelParticipantsKicked(q: query)
                    }
            }
            return network.request(Api.functions.channels.getParticipants(channel: inputChannel, filter: apiFilter, offset: offset, limit: limit, hash: 0))
                |> retryRequest
                |> mapToSignal { result -> Signal<[RenderedChannelParticipant], NoError> in
                    return postbox.modify { modifier -> [RenderedChannelParticipant] in
                        var items: [RenderedChannelParticipant] = []
                        switch result {
                            case let .channelParticipants(_, participants, users):
                                var peers: [PeerId: Peer] = [:]
                                var presences: [PeerId: PeerPresence] = [:]
                                for user in users {
                                    let peer = TelegramUser(user: user)
                                    peers[peer.id] = peer
                                    if let presence = TelegramUserPresence(apiUser: user) {
                                        presences[peer.id] = presence
                                    }
                                }
                                updatePeers(modifier: modifier, peers: Array(peers.values), update: { _, updated in
                                    return updated
                                })
                                modifier.updatePeerPresences(presences)
                                
                                for participant in CachedChannelParticipants(apiParticipants: participants).participants {
                                    if let peer = peers[participant.peerId] {
                                        items.append(RenderedChannelParticipant(participant: participant, peer: peer, peers: peers, presences: presences))
                                    }
                                    
                                }
                            case .channelParticipantsNotModified:
                                break
                        }
                        return items
                    }
            }
        } else {
            return .single([])
        }
    } |> switchToLatest
}
