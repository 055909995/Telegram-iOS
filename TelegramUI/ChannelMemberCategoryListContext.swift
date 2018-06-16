import Foundation
import TelegramCore
import Postbox
import SwiftSignalKit

private let initialBatchSize: Int32 = 32
private let emptyTimeout: Double = 2.0 * 60.0
private let headUpdateTimeout: Double = 30.0
private let requestBatchSize: Int32 = 32

enum ChannelMemberListLoadingState: Equatable {
    case loading
    case ready(hasMore: Bool)
}

private extension ChannelParticipant {
    var adminInfo: ChannelParticipantAdminInfo? {
        switch self {
            case .creator:
                return nil
            case let .member(_, _, adminInfo, _):
                return adminInfo
        }
    }
    
    var banInfo: ChannelParticipantBannedInfo? {
        switch self {
            case .creator:
                return nil
            case let .member(_, _, _, banInfo):
                return banInfo
        }
    }
}

struct ChannelMemberListState {
    let list: [RenderedChannelParticipant]
    let loadingState: ChannelMemberListLoadingState

    func withUpdatedList(_ list: [RenderedChannelParticipant]) -> ChannelMemberListState {
        return ChannelMemberListState(list: list, loadingState: self.loadingState)
    }
    
    func withUpdatedLoadingState(_ loadingState: ChannelMemberListLoadingState) -> ChannelMemberListState {
        return ChannelMemberListState(list: self.list, loadingState: loadingState)
    }
}

enum ChannelMemberListCategory {
    case recent
    case recentSearch(String)
    case admins
    case restricted
    case banned
}

private protocol ChannelMemberCategoryListContext {
    var listStateValue: ChannelMemberListState { get }
    var listState: Signal<ChannelMemberListState, NoError> { get }
    func loadMore()
    func reset()
    func replayUpdates(_ updates: [(ChannelParticipant?, RenderedChannelParticipant?)])
    func forceUpdateHead()
}

private func isParticipantMember(_ participant: ChannelParticipant) -> Bool {
    if let banInfo = participant.banInfo {
        return !banInfo.rights.flags.contains(.banReadMessages) && banInfo.isMember
    } else {
        return true
    }
}

private final class ChannelMemberSingleCategoryListContext: ChannelMemberCategoryListContext {
    private let postbox: Postbox
    private let network: Network
    private let peerId: PeerId
    private let category: ChannelMemberListCategory
    
    var listStateValue: ChannelMemberListState {
        didSet {
            self.listStatePromise.set(.single(self.listStateValue))
            if case .admins = self.category, case .ready = self.listStateValue.loadingState {
                let ids: Set<PeerId> = Set(self.listStateValue.list.map { $0.peer.id })
                let previousIds: Set<PeerId> = Set(oldValue.list.map { $0.peer.id })
                if ids != previousIds {
                    let _ = updateCachedChannelAdminIds(postbox: self.postbox, peerId: self.peerId, ids: ids).start()
                }
            }
        }
    }
    private var listStatePromise: Promise<ChannelMemberListState>
    var listState: Signal<ChannelMemberListState, NoError> {
        return self.listStatePromise.get()
    }
    
    private let loadingDisposable = MetaDisposable()
    private let headUpdateDisposable = MetaDisposable()
    
    private var headUpdateTimer: SwiftSignalKit.Timer?
    
    init(postbox: Postbox, network: Network, peerId: PeerId, category: ChannelMemberListCategory) {
        self.postbox = postbox
        self.network = network
        self.peerId = peerId
        self.category = category
        
        self.listStateValue = ChannelMemberListState(list: [], loadingState: .ready(hasMore: true))
        self.listStatePromise = Promise(self.listStateValue)
        self.loadMore()
    }
    
    deinit {
        self.loadingDisposable.dispose()
        self.headUpdateDisposable.dispose()
        self.headUpdateTimer?.invalidate()
    }
    
    func loadMore() {
        guard case .ready(true) = self.listStateValue.loadingState else {
            return
        }
        
        let loadCount: Int32
        if case .ready(true) = self.listStateValue.loadingState, self.listStateValue.list.isEmpty {
            loadCount = initialBatchSize
        } else {
            loadCount = requestBatchSize
        }
        
        self.listStateValue = self.listStateValue.withUpdatedLoadingState(.loading)
        
        self.loadingDisposable.set((self.loadMoreSignal(count: loadCount)
        |> deliverOnMainQueue).start(next: { [weak self] members in
            self?.appendMembersAndFinishLoading(members)
        }))
    }
    
    func reset() {
        if case .loading = self.listStateValue.loadingState, self.listStateValue.list.isEmpty {
        } else {
            var list = self.listStateValue.list
            var loadingState: ChannelMemberListLoadingState = .ready(hasMore: false)
            if list.count > Int(initialBatchSize) {
                list.removeSubrange(Int(initialBatchSize) ..< list.count)
                loadingState = .ready(hasMore: true)
            }
            
            self.loadingDisposable.set(nil)
            self.listStateValue = self.listStateValue.withUpdatedLoadingState(loadingState).withUpdatedList(list)
        }
    }
    
    private func loadSignal(offset: Int32, count: Int32, hash: Int32) -> Signal<[RenderedChannelParticipant]?, NoError> {
        let requestCategory: ChannelMembersCategory
        switch self.category {
            case .recent:
                requestCategory = .recent(.all)
            case let .recentSearch(query):
                requestCategory = .recent(.search(query))
            case .admins:
                requestCategory = .admins
            case .restricted:
                requestCategory = .restricted(.all)
            case .banned:
                requestCategory = .banned(.all)
        }
        return channelMembers(postbox: self.postbox, network: self.network, peerId: self.peerId, category: requestCategory, offset: offset, limit: count, hash: hash)
    }
    
    private func loadMoreSignal(count: Int32) -> Signal<[RenderedChannelParticipant], NoError> {
        return self.loadSignal(offset: Int32(self.listStateValue.list.count), count: count, hash: 0)
        |> map { value -> [RenderedChannelParticipant] in
            return value ?? []
        }
    }
    
    private func updateHeadMembers(_ headMembers: [RenderedChannelParticipant]?) {
        if let headMembers = headMembers {
            var existingIds = Set<PeerId>()
            var list = headMembers
            for member in list {
                existingIds.insert(member.peer.id)
            }
            for member in self.listStateValue.list {
                if !existingIds.contains(member.peer.id) {
                    list.append(member)
                }
            }
            self.loadingDisposable.set(nil)
            self.listStateValue = self.listStateValue.withUpdatedList(list)
            if case .loading = self.listStateValue.loadingState {
                self.loadMore()
            }
        }
        
        self.headUpdateTimer?.invalidate()
        self.headUpdateTimer = nil
        self.checkUpdateHead()
    }
    
    private func appendMembersAndFinishLoading(_ members: [RenderedChannelParticipant]) {
        var firstLoad = false
        if case .loading = self.listStateValue.loadingState, self.listStateValue.list.isEmpty {
            firstLoad = true
        }
        var existingIds = Set<PeerId>()
        var list = self.listStateValue.list
        for member in list {
            existingIds.insert(member.peer.id)
        }
        for member in members {
            if !existingIds.contains(member.peer.id) {
                list.append(member)
            }
        }
        self.listStateValue = self.listStateValue.withUpdatedList(list).withUpdatedLoadingState(.ready(hasMore: members.count >= requestBatchSize))
        if firstLoad {
            self.checkUpdateHead()
        }
    }
    
    func forceUpdateHead() {
        self.headUpdateTimer = nil
        self.checkUpdateHead()
    }
    
    private func checkUpdateHead() {
        if self.listStateValue.list.isEmpty {
            return
        }
        
        if self.headUpdateTimer == nil {
            let headUpdateTimer = SwiftSignalKit.Timer(timeout: headUpdateTimeout, repeat: false, completion: { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                
                var hash: UInt32 = 0
                
                for i in 0 ..< min(strongSelf.listStateValue.list.count, Int(initialBatchSize)) {
                    let peerId = strongSelf.listStateValue.list[i].peer.id
                    hash = (hash &* 20261) &+ UInt32(peerId.id)
                }
                hash = hash % 0x7FFFFFFF
                strongSelf.headUpdateDisposable.set((strongSelf.loadSignal(offset: 0, count: initialBatchSize, hash: Int32(bitPattern: hash))
                |> deliverOnMainQueue).start(next: { members in
                    self?.updateHeadMembers(members)
                }))
            }, queue: Queue.mainQueue())
            self.headUpdateTimer = headUpdateTimer
            headUpdateTimer.start()
        }
    }
    
    fileprivate func replayUpdates(_ updates: [(ChannelParticipant?, RenderedChannelParticipant?)]) {
        var list = self.listStateValue.list
        var updatedList = false
        for (maybePrevious, updated) in updates {
            var previous: ChannelParticipant? = maybePrevious
            if let participantId = maybePrevious?.peerId ?? updated?.peer.id {
                inner: for participant in list {
                    if participant.peer.id == participantId {
                        previous = participant.participant
                        break inner
                    }
                }
            }
            switch self.category {
                case .admins:
                    if let updated = updated, let _ = updated.participant.adminInfo {
                        var found = false
                        loop: for i in 0 ..< list.count {
                            if list[i].peer.id == updated.peer.id {
                                list[i] = updated
                                found = true
                                updatedList = true
                                break loop
                            }
                        }
                        if !found {
                            list.insert(updated, at: 0)
                            updatedList = true
                        }
                    } else if let previous = previous, let _ = previous.adminInfo {
                        loop: for i in 0 ..< list.count {
                            if list[i].peer.id == previous.peerId {
                                list.remove(at: i)
                                updatedList = true
                                break loop
                            }
                        }
                    }
                case .restricted:
                    if let updated = updated, let banInfo = updated.participant.banInfo, !banInfo.rights.flags.isEmpty && !banInfo.rights.flags.contains(.banReadMessages) {
                        var found = false
                        loop: for i in 0 ..< list.count {
                            if list[i].peer.id == updated.peer.id {
                                list[i] = updated
                                found = true
                                updatedList = true
                                break loop
                            }
                        }
                        if !found {
                            list.insert(updated, at: 0)
                            updatedList = true
                        }
                    } else if let previous = previous, let banInfo = previous.banInfo, !banInfo.rights.flags.isEmpty && !banInfo.rights.flags.contains(.banReadMessages) {
                        loop: for i in 0 ..< list.count {
                            if list[i].peer.id == previous.peerId {
                                list.remove(at: i)
                                updatedList = true
                                break loop
                            }
                        }
                    }
                case .banned:
                    if let updated = updated, let banInfo = updated.participant.banInfo, banInfo.rights.flags.contains(.banReadMessages) {
                        var found = false
                        loop: for i in 0 ..< list.count {
                            if list[i].peer.id == updated.peer.id {
                                list[i] = updated
                                found = true
                                updatedList = true
                                break loop
                            }
                        }
                        if !found {
                            list.insert(updated, at: 0)
                            updatedList = true
                        }
                    } else if let previous = previous, let banInfo = previous.banInfo, banInfo.rights.flags.contains(.banReadMessages) {
                        loop: for i in 0 ..< list.count {
                            if list[i].peer.id == previous.peerId {
                                list.remove(at: i)
                                updatedList = true
                                break loop
                            }
                        }
                    }
                case .recent:
                    if let updated = updated, isParticipantMember(updated.participant) {
                        var found = false
                        loop: for i in 0 ..< list.count {
                            if list[i].peer.id == updated.peer.id {
                                list[i] = updated
                                found = true
                                updatedList = true
                                break loop
                            }
                        }
                        if !found {
                            list.insert(updated, at: 0)
                            updatedList = true
                        }
                    } else if let previous = previous, isParticipantMember(previous) {
                        loop: for i in 0 ..< list.count {
                            if list[i].peer.id == previous.peerId {
                                list.remove(at: i)
                                updatedList = true
                                break loop
                            }
                        }
                    }
                case let .recentSearch(query):
                    break
                default:
                    break
            }
        }
        if updatedList {
            self.listStateValue = self.listStateValue.withUpdatedList(list)
        }
    }
}

private final class ChannelMemberMultiCategoryListContext: ChannelMemberCategoryListContext {
    private var contexts: [ChannelMemberSingleCategoryListContext] = []
    
    var listStateValue: ChannelMemberListState {
        return ChannelMemberMultiCategoryListContext.reduceListStates(self.contexts.map { $0.listStateValue })
    }
    
    private static func reduceListStates(_ listStates: [ChannelMemberListState]) -> ChannelMemberListState {
        var allReady = true
        for listState in listStates {
            if case .loading = listState.loadingState, listState.list.isEmpty {
                allReady = false
                break
            }
        }
        if !allReady {
            return ChannelMemberListState(list: [], loadingState: .loading)
        }
        
        var list: [RenderedChannelParticipant] = []
        var existingIds = Set<PeerId>()
        var loadingState: ChannelMemberListLoadingState = .ready(hasMore: false)
        loop: for i in 0 ..< listStates.count {
            for item in listStates[i].list {
                if !existingIds.contains(item.peer.id) {
                    existingIds.insert(item.peer.id)
                    list.append(item)
                }
            }
            switch listStates[i].loadingState {
                case .loading:
                    loadingState = .loading
                    break loop
                case let .ready(hasMore):
                    if hasMore {
                        loadingState = .ready(hasMore: true)
                        break loop
                    }
            }
        }
        return ChannelMemberListState(list: list, loadingState: loadingState)
    }
    
    var listState: Signal<ChannelMemberListState, NoError> {
        let signals: [Signal<ChannelMemberListState, NoError>] = self.contexts.map { context in
            return context.listState
        }
        return combineLatest(signals) |> map { listStates -> ChannelMemberListState in
            return ChannelMemberMultiCategoryListContext.reduceListStates(listStates)
        }
    }
    
    init(postbox: Postbox, network: Network, peerId: PeerId, categories: [ChannelMemberListCategory]) {
        self.contexts = categories.map { category in
            return ChannelMemberSingleCategoryListContext(postbox: postbox, network: network, peerId: peerId, category: category)
        }
    }
    
    func loadMore() {
        loop: for context in self.contexts {
            switch context.listStateValue.loadingState {
                case .loading:
                    break loop
                case let .ready(hasMore):
                    if hasMore {
                        context.loadMore()
                    }
            }
        }
    }
    
    func reset() {
        for context in self.contexts {
            context.reset()
        }
    }
    
    func forceUpdateHead() {
        for context in self.contexts {
            context.forceUpdateHead()
        }
    }
    
    func replayUpdates(_ updates: [(ChannelParticipant?, RenderedChannelParticipant?)]) {
        for context in self.contexts {
            context.replayUpdates(updates)
        }
    }
}

struct PeerChannelMemberCategoryControl {
    fileprivate let key: PeerChannelMemberContextKey
}

private final class PeerChannelMemberContextWithSubscribers {
    let context: ChannelMemberCategoryListContext
    private let subscribers = Bag<(ChannelMemberListState) -> Void>()
    private let disposable = MetaDisposable()
    private let becameEmpty: () -> Void
    
    private var emptyTimer: SwiftSignalKit.Timer?
    
    init(context: ChannelMemberCategoryListContext, becameEmpty: @escaping () -> Void) {
        self.context = context
        self.becameEmpty = becameEmpty
        self.disposable.set((context.listState
        |> deliverOnMainQueue).start(next: { [weak self] value in
            if let strongSelf = self {
                for f in strongSelf.subscribers.copyItems() {
                    f(value)
                }
            }
        }))
    }
    
    deinit {
        self.disposable.dispose()
        self.emptyTimer?.invalidate()
    }
    
    private func resetAndBeginEmptyTimer() {
        self.context.reset()
        self.emptyTimer?.invalidate()
        let emptyTimer = SwiftSignalKit.Timer(timeout: emptyTimeout, repeat: false, completion: { [weak self] in
            if let strongSelf = self {
                if strongSelf.subscribers.isEmpty {
                    strongSelf.becameEmpty()
                }
            }
        }, queue: Queue.mainQueue())
        self.emptyTimer = emptyTimer
        emptyTimer.start()
    }
    
    func subscribe(updated: @escaping (ChannelMemberListState) -> Void) -> Disposable {
        let wasEmpty = self.subscribers.isEmpty
        let index = self.subscribers.add(updated)
        updated(self.context.listStateValue)
        if wasEmpty {
            self.emptyTimer?.invalidate()
            self.context.forceUpdateHead()
        }
        return ActionDisposable { [weak self] in
            Queue.mainQueue().async {
                if let strongSelf = self {
                    strongSelf.subscribers.remove(index)
                    if strongSelf.subscribers.isEmpty {
                        strongSelf.resetAndBeginEmptyTimer()
                    }
                }
            }
        }
    }
}

final class PeerChannelMemberCategoriesContext {
    private let postbox: Postbox
    private let network: Network
    private let peerId: PeerId
    private var becameEmpty: (Bool) -> Void
    
    private var contexts: [PeerChannelMemberContextKey: PeerChannelMemberContextWithSubscribers] = [:]
    
    init(postbox: Postbox, network: Network, peerId: PeerId, becameEmpty: @escaping (Bool) -> Void) {
        self.postbox = postbox
        self.network = network
        self.peerId = peerId
        self.becameEmpty = becameEmpty
    }
    
    func getContext(key: PeerChannelMemberContextKey, updated: @escaping (ChannelMemberListState) -> Void) -> (Disposable, PeerChannelMemberCategoryControl) {
        assert(Queue.mainQueue().isCurrent())
        if let current = self.contexts[key] {
            return (current.subscribe(updated: updated), PeerChannelMemberCategoryControl(key: key))
        }
        let context: ChannelMemberCategoryListContext
        switch key {
            case .recent, .recentSearch, .admins:
                let mappedCategory: ChannelMemberListCategory
                switch key {
                    case .recent:
                        mappedCategory = .recent
                    case let .recentSearch(query):
                        mappedCategory = .recentSearch(query)
                    case .admins:
                        mappedCategory = .admins
                    default:
                        mappedCategory = .recent
                }
                context = ChannelMemberSingleCategoryListContext(postbox: self.postbox, network: self.network, peerId: self.peerId, category: mappedCategory)
            case .restrictedAndBanned:
                context = ChannelMemberMultiCategoryListContext(postbox: self.postbox, network: self.network, peerId: self.peerId, categories: [.restricted, .banned])
        }
        let contextWithSubscribers = PeerChannelMemberContextWithSubscribers(context: context, becameEmpty: { [weak self] in
            assert(Queue.mainQueue().isCurrent())
            if let strongSelf = self {
                strongSelf.contexts.removeValue(forKey: key)
            }
        })
        self.contexts[key] = contextWithSubscribers
        return (contextWithSubscribers.subscribe(updated: updated), PeerChannelMemberCategoryControl(key: key))
    }
    
    func loadMore(_ control: PeerChannelMemberCategoryControl) {
        assert(Queue.mainQueue().isCurrent())
        if let context = self.contexts[control.key] {
            context.context.loadMore()
        }
    }
    
    func replayUpdates(_ updates: [(ChannelParticipant?, RenderedChannelParticipant?)]) {
        for (_, context) in self.contexts {
            context.context.replayUpdates(updates)
        }
    }
}
