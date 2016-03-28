import Foundation

public struct MediaId: Hashable, CustomStringConvertible {
    public typealias Namespace = Int32
    public typealias Id = Int64
    
    let namespace: Namespace
    let id: Id
    
    public var hashValue: Int {
        get {
            return Int((self.id & 0x7fffffff) ^ ((self.id >> 32) & 0x7fffffff))
        }
    }
    
    public var description: String {
        get {
            return "\(namespace):\(id)"
        }
    }
    
    public init(namespace: Namespace, id: Id) {
        self.namespace = namespace
        self.id = id
    }
    
    public init(_ buffer: ReadBuffer) {
        var namespace: Int32 = 0
        var id: Int64 = 0
        
        memcpy(&namespace, buffer.memory + buffer.offset, 4)
        self.namespace = namespace
        memcpy(&id, buffer.memory + (buffer.offset + 4), 8)
        self.id = id
        buffer.offset += 12
    }
    
    public func encodeToBuffer(buffer: WriteBuffer) {
        var namespace = self.namespace
        var id = self.id
        buffer.write(&namespace, offset: 0, length: 4);
        buffer.write(&id, offset: 0, length: 8);
    }
    
    public static func encodeArrayToBuffer(array: [MediaId], buffer: WriteBuffer) {
        var length: Int32 = Int32(array.count)
        buffer.write(&length, offset: 0, length: 4)
        for id in array {
            id.encodeToBuffer(buffer)
        }
    }
    
    public static func decodeArrayFromBuffer(buffer: ReadBuffer) -> [MediaId] {
        var length: Int32 = 0
        memcpy(&length, buffer.memory, 4)
        buffer.offset += 4
        var i = 0
        var array: [MediaId] = []
        while i < Int(length) {
            array.append(MediaId(buffer))
            i += 1
        }
        return array
    }
}

public func ==(lhs: MediaId, rhs: MediaId) -> Bool {
    return lhs.id == rhs.id && lhs.namespace == rhs.namespace
}

public protocol Media: Coding {
    var id: MediaId? { get }
    var peerIds: [PeerId] { get }
    
    func isEqual(other: Media) -> Bool
}
