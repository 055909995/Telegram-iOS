import Foundation
import Postbox
import SwiftSignalKit

enum GalleryHiddenMediaId: Hashable {
    case chat(MessageId, Media)
    
    static func ==(lhs: GalleryHiddenMediaId, rhs: GalleryHiddenMediaId) -> Bool {
        switch lhs {
            case let .chat(lhsMessageId, lhsMedia):
                if case let .chat(rhsMessageId, rhsMedia) = rhs, lhsMessageId == rhsMessageId, lhsMedia.isEqual(to: rhsMedia) {
                        return true
                    } else {
                        return false
                    }
        }
    }
    
    var hashValue: Int {
        switch self {
            case let .chat(messageId, _):
                return messageId.hashValue
        }
    }
}

private final class GalleryHiddenMediaContext {
    private var ids = Set<Int32>()
    
    func add(id: Int32) {
        self.ids.insert(id)
    }
    
    func remove(id: Int32) {
        self.ids.remove(id)
    }
    
    var isEmpty: Bool {
        return self.ids.isEmpty
    }
}

final class GalleryHiddenMediaManager {
    private var nextId: Int32 = 0
    private var contexts: [GalleryHiddenMediaId: GalleryHiddenMediaContext] = [:]
    
    private var sourcesDisposables = Bag<Disposable>()
    private var subscribers = Bag<(Set<GalleryHiddenMediaId>) -> Void>()
    
    func hiddenIds() -> Signal<Set<GalleryHiddenMediaId>, NoError> {
        return Signal { [weak self] subscriber in
            let disposable = MetaDisposable()
            Queue.mainQueue().async {
                if let strongSelf = self {
                    subscriber.putNext(Set(strongSelf.contexts.keys))
                    let index = strongSelf.subscribers.add({ next in
                        subscriber.putNext(next)
                    })
                    disposable.set(ActionDisposable {
                        Queue.mainQueue().async {
                            if let strongSelf = self {
                                strongSelf.subscribers.remove(index)
                            }
                        }
                    })
                }
            }
            return disposable
        }
    }
    
    private func withContext(id: GalleryHiddenMediaId, _ f: (GalleryHiddenMediaContext) -> Void) {
        let context: GalleryHiddenMediaContext
        if let current = self.contexts[id] {
            context = current
        } else {
            context = GalleryHiddenMediaContext()
            self.contexts[id] = context
        }
        
        let wasEmpty = context.isEmpty
        
        f(context)
        
        if context.isEmpty {
            self.contexts.removeValue(forKey: id)
        }
        
        if context.isEmpty != wasEmpty {
            let allIds = Set(self.contexts.keys)
            for subscriber in self.subscribers.copyItems() {
                subscriber(allIds)
            }
        }
    }
    
    func addSource(_ signal: Signal<GalleryHiddenMediaId?, NoError>) -> Int {
        var state: (GalleryHiddenMediaId, Int32)?
        let index = self.sourcesDisposables.add((signal |> deliverOnMainQueue).start(next: { [weak self] id in
            if let strongSelf = self {
                if id != state?.0 {
                    if let (previousId, previousIndex) = state {
                        strongSelf.removeHiddenMedia(id: previousId, index: previousIndex)
                        state = nil
                    }
                    if let id = id {
                        state = (id, strongSelf.addHiddenMedia(id: id))
                    }
                }
            }
        }))
        return index
    }
    
    func removeSource(_ index: Int) {
        if let disposable = self.sourcesDisposables.get(index) {
            self.sourcesDisposables.remove(index)
            disposable.dispose()
        }
    }
    
    private func addHiddenMedia(id: GalleryHiddenMediaId) -> Int32 {
        let itemId = self.nextId
        self.nextId += 1
        self.withContext(id: id, { context in
            context.add(id: itemId)
        })
        return itemId
    }
    
    private func removeHiddenMedia(id: GalleryHiddenMediaId, index: Int32) {
        self.withContext(id: id, { context in
            context.remove(id: index)
        })
    }
}
