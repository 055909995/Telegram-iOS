import Foundation
#if os(macOS)
import SwiftSignalKitMac
#else
import SwiftSignalKit
#endif

public struct DeepLinkInfo {
    public let message: String
    public let entities: [MessageTextEntity]
    public let updateApp: Bool
}

public func getDeepLinkInfo(network: Network, path: String) -> Signal<DeepLinkInfo?, Void> {
    return network.request(Api.functions.help.getDeepLinkInfo(path: path)) |> retryRequest |> map { value -> DeepLinkInfo? in
        switch value {
        case .deepLinkInfoEmpty:
            return nil
        case let .deepLinkInfo(flags, message, entities):
            return DeepLinkInfo(message: message, entities: entities != nil ? messageTextEntitiesFromApiEntities(entities!) : [], updateApp: (flags & (1 << 0)) != 0)
        }
    }
}
