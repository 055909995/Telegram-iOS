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

public enum AddPeerMemberError {
    case generic
}

public func addPeerMember(account: Account, peerId: PeerId, memberId: PeerId) -> Signal<Void, AddPeerMemberError> {
    return account.postbox.transaction { transaction -> Signal<Void, AddPeerMemberError> in
        if let peer = transaction.getPeer(peerId), let memberPeer = transaction.getPeer(memberId), let inputUser = apiInputUser(memberPeer) {
            if let group = peer as? TelegramGroup {
                return account.network.request(Api.functions.messages.addChatUser(chatId: group.id.id, userId: inputUser, fwdLimit: 100))
                    |> mapError { error -> AddPeerMemberError in
                        return .generic
                    }
                    |> mapToSignal { result -> Signal<Void, AddPeerMemberError> in
                        account.stateManager.addUpdates(result)
                        return account.postbox.transaction { transaction -> Void in
                            if let message = result.messages.first, let timestamp = message.timestamp {
                                transaction.updatePeerCachedData(peerIds: Set([peerId]), update: { _, cachedData -> CachedPeerData? in
                                    if let cachedData = cachedData as? CachedGroupData, let participants = cachedData.participants {
                                        var updatedParticipants = participants.participants
                                        var found = false
                                        for participant in participants.participants {
                                            if participant.peerId == memberId {
                                                found = true
                                                break
                                            }
                                        }
                                        if !found {
                                            updatedParticipants.append(.member(id: memberId, invitedBy: account.peerId, invitedAt: timestamp))
                                        }
                                        return cachedData.withUpdatedParticipants(CachedGroupParticipants(participants: updatedParticipants, version: participants.version))
                                    } else {
                                        return cachedData
                                    }
                                })
                            }
                        } |> mapError { _ -> AddPeerMemberError in return .generic }
                    }
            } else if let channel = peer as? TelegramChannel, let inputChannel = apiInputChannel(channel) {
                return account.network.request(Api.functions.channels.inviteToChannel(channel: inputChannel, users: [inputUser]))
                    |> mapError { error -> AddPeerMemberError in
                        return .generic
                    }
                    |> mapToSignal { result -> Signal<Void, AddPeerMemberError> in
                        account.stateManager.addUpdates(result)
                        return account.postbox.transaction { transaction -> Void in
                            transaction.updatePeerCachedData(peerIds: Set([peerId]), update: { _, cachedData -> CachedPeerData? in
                                if let cachedData = cachedData as? CachedChannelData, let participants = cachedData.topParticipants {
                                    var updatedParticipants = participants.participants
                                    var found = false
                                    for participant in participants.participants {
                                        if participant.peerId == memberId {
                                            found = true
                                            break
                                        }
                                    }
                                    let timestamp = Int32(CFAbsoluteTimeGetCurrent() + NSTimeIntervalSince1970)
                                    if !found {
                                        updatedParticipants.insert(.member(id: memberId, invitedAt: timestamp, adminInfo: nil, banInfo: nil), at: 0)
                                    }
                                    var updatedMemberCount: Int32?
                                    if let memberCount = cachedData.participantsSummary.memberCount {
                                        updatedMemberCount = memberCount + 1
                                    }
                                    return cachedData.withUpdatedTopParticipants(CachedChannelParticipants(participants: updatedParticipants)).withUpdatedParticipantsSummary(cachedData.participantsSummary.withUpdatedMemberCount(updatedMemberCount))
                                } else {
                                    return cachedData
                                }
                            })
                        } |> mapError { _ -> AddPeerMemberError in return .generic }
                }
            } else {
                return .fail(.generic)
            }
        } else {
            return .fail(.generic)
        }
    } |> mapError { _ -> AddPeerMemberError in return .generic } |> switchToLatest
}

public enum AddChannelMemberError {
    case generic
}

public func addChannelMember(account: Account, peerId: PeerId, memberId: PeerId) -> Signal<(ChannelParticipant?, RenderedChannelParticipant), AddChannelMemberError> {
    return fetchChannelParticipant(account: account, peerId: peerId, participantId: memberId)
    |> mapError { error -> AddChannelMemberError in
        return .generic
    }
    |> mapToSignal { currentParticipant -> Signal<(ChannelParticipant?, RenderedChannelParticipant), AddChannelMemberError> in
        return account.postbox.transaction { transaction -> Signal<(ChannelParticipant?, RenderedChannelParticipant), AddChannelMemberError> in
            if let peer = transaction.getPeer(peerId), let memberPeer = transaction.getPeer(memberId), let inputUser = apiInputUser(memberPeer) {
                if let channel = peer as? TelegramChannel, let inputChannel = apiInputChannel(channel) {
                    let updatedParticipant: ChannelParticipant
                    if let currentParticipant = currentParticipant, case let .member(_, invitedAt, adminInfo, banInfo) = currentParticipant {
                        updatedParticipant = ChannelParticipant.member(id: memberId, invitedAt: invitedAt, adminInfo: adminInfo, banInfo: nil)
                    } else {
                        updatedParticipant = ChannelParticipant.member(id: memberId, invitedAt: Int32(Date().timeIntervalSince1970), adminInfo: nil, banInfo: nil)
                    }
                    return account.network.request(Api.functions.channels.inviteToChannel(channel: inputChannel, users: [inputUser]))
                    |> map { [$0] }
                    |> `catch` { error -> Signal<[Api.Updates], AddChannelMemberError> in
                        return .fail(.generic)
                    }
                    |> mapToSignal { result -> Signal<(ChannelParticipant?, RenderedChannelParticipant), AddChannelMemberError> in
                        for updates in result {
                            account.stateManager.addUpdates(updates)
                        }
                        return account.postbox.transaction { transaction -> (ChannelParticipant?, RenderedChannelParticipant) in
                            transaction.updatePeerCachedData(peerIds: Set([peerId]), update: { _, cachedData -> CachedPeerData? in
                                if let cachedData = cachedData as? CachedChannelData, let memberCount = cachedData.participantsSummary.memberCount, let kickedCount = cachedData.participantsSummary.kickedCount {
                                    var updatedMemberCount = memberCount
                                    var updatedKickedCount = kickedCount
                                    var wasMember = false
                                    var wasBanned = false
                                    if let currentParticipant = currentParticipant {
                                        switch currentParticipant {
                                            case .creator:
                                                break
                                            case let .member(_, _, _, banInfo):
                                                if let banInfo = banInfo {
                                                    wasBanned = true
                                                    wasMember = !banInfo.rights.flags.contains(.banReadMessages)
                                                } else {
                                                    wasMember = true
                                                }
                                        }
                                    }
                                    if !wasMember {
                                        updatedMemberCount = updatedMemberCount + 1
                                    }
                                    if wasBanned {
                                        updatedKickedCount = max(0, updatedKickedCount - 1)
                                    }
                                    
                                    return cachedData.withUpdatedParticipantsSummary(cachedData.participantsSummary.withUpdatedMemberCount(updatedMemberCount).withUpdatedKickedCount(updatedKickedCount))
                                } else {
                                    return cachedData
                                }
                            })
                            var peers: [PeerId: Peer] = [:]
                            var presences: [PeerId: PeerPresence] = [:]
                            peers[memberPeer.id] = memberPeer
                            if let presence = transaction.getPeerPresence(peerId: memberPeer.id) {
                                presences[memberPeer.id] = presence
                            }
                            if case let .member(_, _, maybeAdminInfo, maybeBannedInfo) = updatedParticipant {
                                if let adminInfo = maybeAdminInfo {
                                    if let peer = transaction.getPeer(adminInfo.promotedBy) {
                                        peers[peer.id] = peer
                                    }
                                }
                            }
                            return (currentParticipant, RenderedChannelParticipant(participant: updatedParticipant, peer: memberPeer, peers: peers, presences: presences))
                            }
                            |> mapError { _ -> AddChannelMemberError in return .generic }
                    }
                } else {
                    return .fail(.generic)
                }
            } else {
                return .fail(.generic)
            }
        }
        |> mapError { _ -> AddChannelMemberError in return .generic }
        |> switchToLatest
    }
}

public func addChannelMembers(account: Account, peerId: PeerId, memberIds: [PeerId]) -> Signal<Void, NoError> {
    return account.postbox.transaction { transaction -> Signal<Void, NoError> in
        var memberPeerIds: [PeerId:Peer] = [:]
        var inputUsers: [Api.InputUser] = []
        for memberId in memberIds {
            if let peer = transaction.getPeer(memberId) {
                memberPeerIds[peerId] = peer
                if let inputUser = apiInputUser(peer) {
                    inputUsers.append(inputUser)
                }
            }
        }
        
        if let peer = transaction.getPeer(peerId), let channel = peer as? TelegramChannel, let inputChannel = apiInputChannel(channel) {
            return account.network.request(Api.functions.channels.inviteToChannel(channel: inputChannel, users: inputUsers))
            |> retryRequest
            |> mapToSignal { result -> Signal<Void, NoError> in
                account.stateManager.addUpdates(result)
                account.viewTracker.forceUpdateCachedPeerData(peerId: peerId)
                return .complete()
            }
        } else {
            return .complete()
        }
    }
    |> switchToLatest
}
