import Foundation

private final class InternalPeerReadStates {
    var namespaces: [MessageId.Namespace: PeerReadState]
    
    init(namespaces: [MessageId.Namespace: PeerReadState]) {
        self.namespaces = namespaces
    }
}

final class MessageHistoryReadStateTable: Table {
    private var cachedPeerReadStates: [PeerId: InternalPeerReadStates?] = [:]
    private var updatedPeerIds = Set<PeerId>()
    
    private let sharedKey = ValueBoxKey(length: 8)
    
    private func key(id: PeerId) -> ValueBoxKey {
        self.sharedKey.setInt64(0, value: id.toInt64())
        return self.sharedKey
    }
    
    override init(valueBox: ValueBox, tableId: Int32) {
        super.init(valueBox: valueBox, tableId: tableId)
    }

    private func get(id: PeerId) -> InternalPeerReadStates? {
        if let states = self.cachedPeerReadStates[id] {
            return states
        } else {
            if let value = self.valueBox.get(self.tableId, key: self.key(id)) {
                var count: Int32 = 0
                value.read(&count, offset: 0, length: 4)
                var stateByNamespace: [MessageId.Namespace: PeerReadState] = [:]
                for _ in 0 ..< count {
                    var namespaceId: Int32 = 0
                    var maxReadId: Int32 = 0
                    var maxKnownId: Int32 = 0
                    var count: Int32 = 0
                    value.read(&namespaceId, offset: 0, length: 4)
                    value.read(&maxReadId, offset: 0, length: 4)
                    value.read(&maxKnownId, offset: 0, length: 4)
                    value.read(&count, offset: 0, length: 4)
                    let state = PeerReadState(maxReadId: maxReadId, maxKnownId: maxKnownId, count: count)
                    stateByNamespace[namespaceId] = state
                }
                let states = InternalPeerReadStates(namespaces: stateByNamespace)
                self.cachedPeerReadStates[id] = states
                return states
            } else {
                self.cachedPeerReadStates[id] = nil
                return nil
            }
        }
    }
    
    func getCombinedState(peerId: PeerId) -> CombinedPeerReadState? {
        if let states = self.get(peerId) {
            return CombinedPeerReadState(states: states.namespaces.map({$0}))
        }
        return nil
    }
    
    func resetStates(peerId: PeerId, namespaces: [MessageId.Namespace: PeerReadState]) -> CombinedPeerReadState? {
        self.updatedPeerIds.insert(peerId)
        
        if let states = self.get(peerId) {
            var updated = false
            for (namespace, state) in namespaces {
                if states.namespaces[namespace] == nil || states.namespaces[namespace]! != state {
                    updated = true
                }
                states.namespaces[namespace] = state
            }
            if updated {
                self.updatedPeerIds.insert(peerId)
                return CombinedPeerReadState(states: states.namespaces.map({$0}))
            } else {
                return nil
            }
        } else {
            self.updatedPeerIds.insert(peerId)
            let states = InternalPeerReadStates(namespaces: namespaces)
            self.cachedPeerReadStates[peerId] = states
            return CombinedPeerReadState(states: states.namespaces.map({$0}))
        }
    }
    
    func addIncomingMessages(peerId: PeerId, ids: [MessageId]) -> (CombinedPeerReadState?, Bool) {
        var idsByNamespace: [MessageId.Namespace: [MessageId.Id]] = [:]
        for id in ids {
            if idsByNamespace[id.namespace] != nil {
                idsByNamespace[id.namespace]!.append(id.id)
            } else {
                idsByNamespace[id.namespace] = [id.id]
            }
        }
        
        if let states = self.get(peerId) {
            var updated = false
            var invalidated = false
            for (namespace, ids) in idsByNamespace {
                if let currentState = states.namespaces[namespace] {
                    var addedUnreadCount: Int32 = 0
                    var maxIncomingId: Int32 = 0
                    for id in ids {
                        if id > currentState.maxKnownId {
                            addedUnreadCount += 1
                            maxIncomingId = max(id, maxIncomingId)
                        }
                    }
                    
                    if addedUnreadCount != 0 {
                        states.namespaces[namespace] = PeerReadState(maxReadId: currentState.maxReadId, maxKnownId: currentState.maxKnownId, count: currentState.count + addedUnreadCount)
                        updated = true
                    }
                }
            }
            
            if updated {
                self.updatedPeerIds.insert(peerId)
            }
            
            return (updated ? CombinedPeerReadState(states: states.namespaces.map({$0})) : nil, invalidated)
        } else {
            return (nil, true)
        }
        
        return (nil, false)
    }
    
    func deleteMessages(peerId: PeerId, ids: [MessageId], incomingStatsInIds: (PeerId, MessageId.Namespace, [MessageId.Id]) -> (Int, Bool)) -> (CombinedPeerReadState?, Bool) {
        var idsByNamespace: [MessageId.Namespace: [MessageId.Id]] = [:]
        for id in ids {
            if idsByNamespace[id.namespace] != nil {
                idsByNamespace[id.namespace]!.append(id.id)
            } else {
                idsByNamespace[id.namespace] = [id.id]
            }
        }
        
        if let states = self.get(peerId) {
            var updated = false
            var invalidate = false
            for (namespace, ids) in idsByNamespace {
                if let currentState = states.namespaces[namespace] {
                    var unreadIds: [MessageId.Id] = []
                    for id in ids {
                        if id > currentState.maxReadId {
                            unreadIds.append(id)
                        }
                    }
                    
                    let (knownCount, holes) = incomingStatsInIds(peerId, namespace, unreadIds)
                    if holes {
                        invalidate = true
                    }
                    
                    states.namespaces[namespace] = PeerReadState(maxReadId: currentState.maxReadId, maxKnownId: currentState.maxKnownId, count: currentState.count - knownCount)
                    updated = true
                } else {
                    invalidate = true
                }
            }
            
            if updated {
                self.updatedPeerIds.insert(peerId)
            }
            
            return (updated ? CombinedPeerReadState(states: states.namespaces.map({$0})) : nil, invalidate)
        } else {
            return (nil, true)
        }
        
        return (nil, false)
    }
    
    func applyMaxReadId(peerId: PeerId, namespace: MessageId.Namespace, maxReadId: MessageId.Id, maxKnownId: MessageId.Id, incomingStatsInRange: (MessageId.Id, MessageId.Id) -> (count: Int, holes: Bool)) -> (CombinedPeerReadState?, Bool) {
        if let states = self.get(peerId), state = states.namespaces[namespace] {
            if state.maxReadId < maxReadId {
                let (deltaCount, holes) = incomingStatsInRange(state.maxReadId + 1, maxReadId)
                
                states.namespaces[namespace] = PeerReadState(maxReadId: maxReadId, maxKnownId: max(state.maxKnownId, maxReadId), count: state.count - Int32(deltaCount))
                self.updatedPeerIds.insert(peerId)
                return (CombinedPeerReadState(states: states.namespaces.map({$0})), holes)
            }
        } else {
            return (nil, true)
        }
        
        return (nil, false)
    }
    
    func clearUnreadLocally(peerId: PeerId, topId: (PeerId, MessageId.Namespace) -> MessageId.Id?) -> CombinedPeerReadState? {
        if let states = self.get(peerId) {
            var updatedNamespaces: [MessageId.Namespace: PeerReadState] = [:]
            var updated = false
            for (namespace, state) in states.namespaces {
                if let topMessageId = topId(peerId, namespace) {
                    let updatedState = PeerReadState(maxReadId: topMessageId, maxKnownId: topMessageId, count: 0)
                    if updatedState != state {
                        updated = true
                    }
                    updatedNamespaces[namespace] = updatedState
                } else {
                    let updatedState = PeerReadState(maxReadId: state.maxReadId, maxKnownId: state.maxKnownId, count: 0)
                    updated = true
                }
            }
            if updated {
                self.updatedPeerIds.insert(peerId)
                return CombinedPeerReadState(states: states.namespaces.map({$0}))
            }
        }
        
        return nil
    }
    
    override func beforeCommit() {
        let sharedBuffer = WriteBuffer()
        for id in self.updatedPeerIds {
            if let wrappedStates = self.cachedPeerReadStates[id], states = wrappedStates {
                sharedBuffer.reset()
                var count: Int32 = Int32(states.namespaces.count)
                sharedBuffer.write(&count, offset: 0, length: 4)
                for (namespace, state) in states.namespaces {
                    var namespaceId: Int32 = namespace
                    var maxReadId: Int32 = state.maxReadId
                    var maxKnownId: Int32 = state.maxKnownId
                    var count: Int32 = state.count
                    sharedBuffer.write(&namespaceId, offset: 0, length: 4)
                    sharedBuffer.write(&maxReadId, offset: 0, length: 4)
                    sharedBuffer.write(&maxKnownId, offset: 0, length: 4)
                    sharedBuffer.write(&count, offset: 0, length: 4)
                }
                self.valueBox.set(self.tableId, key: self.key(id), value: sharedBuffer)
            } else {
                self.valueBox.remove(self.tableId, key: self.key(id))
            }
        }
        self.updatedPeerIds.removeAll()
    }
}
