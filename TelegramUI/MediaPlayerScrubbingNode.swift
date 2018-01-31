import Foundation
import AsyncDisplayKit
import Display
import SwiftSignalKit

enum MediaPlayerScrubbingNodeCap {
    case square
    case round
}

private func generateHandleBackground(color: UIColor) -> UIImage? {
    return generateImage(CGSize(width: 2.0, height: 4.0), contextGenerator: { size, context in
        context.clear(CGRect(origin: CGPoint(), size: size))
        context.setFillColor(color.cgColor)
        context.fillEllipse(in: CGRect(origin: CGPoint(), size: CGSize(width: 1.5, height: 1.5)))
        context.fillEllipse(in: CGRect(origin: CGPoint(x: 0.0, y: size.height - 1.5), size: CGSize(width: 1.5, height: 1.5)))
        context.fill(CGRect(origin: CGPoint(x: 0.0, y: 1.5 / 2.0), size: CGSize(width: 1.5, height: size.height - 1.5)))
    })?.stretchableImage(withLeftCapWidth: 0, topCapHeight: 2)
}

private final class MediaPlayerScrubbingNodeButton: ASDisplayNode {
    var beginScrubbing: (() -> Void)?
    var endScrubbing: ((Bool) -> Void)?
    var updateScrubbing: ((CGFloat) -> Void)?
    
    private var scrubbingStartLocation: CGPoint?
    
    override func didLoad() {
        super.didLoad()
        
        self.view.disablesInteractiveTransitionGestureRecognizer = true
        self.view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(self.panGesture(_:))))
    }
    
    @objc func panGesture(_ recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
            case .began:
                self.scrubbingStartLocation = recognizer.location(in: self.view)
                self.beginScrubbing?()
            case .changed:
                let location = recognizer.location(in: self.view)
                if let scrubbingStartLocation = self.scrubbingStartLocation {
                    let delta = location.x - scrubbingStartLocation.x
                    self.updateScrubbing?(delta / self.bounds.size.width)
                }
            case .ended, .cancelled:
                let location = recognizer.location(in: self.view)
                if let scrubbingStartLocation = self.scrubbingStartLocation {
                    self.scrubbingStartLocation = nil
                    let delta = location.x - scrubbingStartLocation.x
                    self.updateScrubbing?(delta / self.bounds.size.width)
                    self.endScrubbing?(recognizer.state == .ended)
                }
            default:
                break
        }
    }
}

private final class MediaPlayerScrubbingForegroundNode: ASDisplayNode {
    var onEnterHierarchy: (() -> Void)?
    
    override func willEnterHierarchy() {
        super.willEnterHierarchy()
        
        self.onEnterHierarchy?()
    }
}

enum MediaPlayerScrubbingNodeHandle {
    case none
    case line
    case circle
}

enum MediaPlayerScrubbingNodeContent {
    case standard(lineHeight: CGFloat, lineCap: MediaPlayerScrubbingNodeCap, scrubberHandle: MediaPlayerScrubbingNodeHandle, backgroundColor: UIColor, foregroundColor: UIColor)
    case custom(backgroundNode: ASDisplayNode, foregroundContentNode: ASDisplayNode)
}

private final class StandardMediaPlayerScrubbingNodeContentNode {
    let lineHeight: CGFloat
    let lineCap: MediaPlayerScrubbingNodeCap
    let backgroundNode: ASImageNode
    let foregroundContentNode: ASImageNode
    let foregroundNode: MediaPlayerScrubbingForegroundNode
    let handleNode: ASDisplayNode?
    let handleNodeContainer: MediaPlayerScrubbingNodeButton?
    
    init(lineHeight: CGFloat, lineCap: MediaPlayerScrubbingNodeCap, backgroundNode: ASImageNode, foregroundContentNode: ASImageNode, foregroundNode: MediaPlayerScrubbingForegroundNode, handleNode: ASDisplayNode?, handleNodeContainer: MediaPlayerScrubbingNodeButton?) {
        self.lineHeight = lineHeight
        self.lineCap = lineCap
        self.backgroundNode = backgroundNode
        self.foregroundContentNode = foregroundContentNode
        self.foregroundNode = foregroundNode
        self.handleNode = handleNode
        self.handleNodeContainer = handleNodeContainer
    }
}

private final class CustomMediaPlayerScrubbingNodeContentNode {
    let backgroundNode: ASDisplayNode
    let foregroundContentNode: ASDisplayNode
    let foregroundNode: MediaPlayerScrubbingForegroundNode
    let handleNodeContainer: MediaPlayerScrubbingNodeButton?
    
    init(backgroundNode: ASDisplayNode, foregroundContentNode: ASDisplayNode, foregroundNode: MediaPlayerScrubbingForegroundNode, handleNodeContainer: MediaPlayerScrubbingNodeButton?) {
        self.backgroundNode = backgroundNode
        self.foregroundContentNode = foregroundContentNode
        self.foregroundNode = foregroundNode
        self.handleNodeContainer = handleNodeContainer
    }
}

private enum MediaPlayerScrubbingNodeContentNodes {
    case standard(StandardMediaPlayerScrubbingNodeContentNode)
    case custom(CustomMediaPlayerScrubbingNodeContentNode)
}

final class MediaPlayerScrubbingNode: ASDisplayNode {
    private let contentNodes: MediaPlayerScrubbingNodeContentNodes
    
    private var playbackStatusValue: MediaPlayerPlaybackStatus?
    private var scrubbingBeginTimestamp: Double?
    private var scrubbingTimestamp: Double?
    
    var playbackStatusUpdated: ((MediaPlayerPlaybackStatus?) -> Void)?
    var playerStatusUpdated: ((MediaPlayerStatus?) -> Void)?
    var seek: ((Double) -> Void)?
    
    var ignoreSeekId: Int?
    
    private var _statusValue: MediaPlayerStatus?
    private var statusValue: MediaPlayerStatus? {
        get {
            return self._statusValue
        } set(value) {
            if value != self._statusValue {
                if let value = value, value.seekId == self.ignoreSeekId {
                } else {
                    self._statusValue = value
                    self.updateProgress()
                    
                    let playbackStatus = value?.status
                    if self.playbackStatusValue != playbackStatus {
                        self.playbackStatusValue = playbackStatus
                        if let playbackStatusUpdated = self.playbackStatusUpdated {
                            playbackStatusUpdated(playbackStatus)
                        }
                    }
                    
                    self.playerStatusUpdated?(value)
                }
            }
        }
    }
    
    private var statusDisposable: Disposable?
    private var statusValuePromise = Promise<MediaPlayerStatus?>()
    
    var status: Signal<MediaPlayerStatus, NoError>? {
        didSet {
            if let status = self.status {
                self.statusValuePromise.set(status |> map { $0 })
            } else {
                self.statusValuePromise.set(.single(nil))
            }
        }
    }
    
    init(content: MediaPlayerScrubbingNodeContent) {
        switch content {
            case let .standard(lineHeight, lineCap, scrubberHandle, backgroundColor, foregroundColor):
                let backgroundNode = ASImageNode()
                backgroundNode.isLayerBacked = true
                backgroundNode.displaysAsynchronously = false
                backgroundNode.displayWithoutProcessing = true
                
                let foregroundContentNode = ASImageNode()
                foregroundContentNode.isLayerBacked = true
                foregroundContentNode.displaysAsynchronously = false
                foregroundContentNode.displayWithoutProcessing = true
                
                switch lineCap {
                    case .round:
                        backgroundNode.image = generateStretchableFilledCircleImage(diameter: lineHeight, color: backgroundColor)
                        foregroundContentNode.image = generateStretchableFilledCircleImage(diameter: lineHeight, color: foregroundColor)
                    case .square:
                        backgroundNode.backgroundColor = backgroundColor
                        foregroundContentNode.backgroundColor = foregroundColor
                }
                
                let foregroundNode = MediaPlayerScrubbingForegroundNode()
                foregroundNode.isLayerBacked = true
                foregroundNode.clipsToBounds = true
                
                var handleNodeImpl: ASImageNode?
                var handleNodeContainerImpl: MediaPlayerScrubbingNodeButton?
                
                switch scrubberHandle {
                    case .none:
                        break
                    case .line:
                        let handleNode = ASImageNode()
                        handleNode.image = generateHandleBackground(color: foregroundColor)
                        handleNode.isLayerBacked = true
                        handleNodeImpl = handleNode
                        
                        let handleNodeContainer = MediaPlayerScrubbingNodeButton()
                        handleNodeContainer.addSubnode(handleNode)
                        handleNodeContainerImpl = handleNodeContainer
                    case .circle:
                        let handleNode = ASImageNode()
                        handleNode.image = generateFilledCircleImage(diameter: 7.0, color: foregroundColor)
                        handleNode.isLayerBacked = true
                        handleNodeImpl = handleNode
                        
                        let handleNodeContainer = MediaPlayerScrubbingNodeButton()
                        handleNodeContainer.addSubnode(handleNode)
                        handleNodeContainerImpl = handleNodeContainer
                }
                
                self.contentNodes = .standard(StandardMediaPlayerScrubbingNodeContentNode(lineHeight: lineHeight, lineCap: lineCap, backgroundNode: backgroundNode, foregroundContentNode: foregroundContentNode, foregroundNode: foregroundNode, handleNode: handleNodeImpl, handleNodeContainer: handleNodeContainerImpl))
            case let .custom(backgroundNode, foregroundContentNode):
                let foregroundNode = MediaPlayerScrubbingForegroundNode()
                foregroundNode.isLayerBacked = true
                foregroundNode.clipsToBounds = true
                
                let handleNodeContainer = MediaPlayerScrubbingNodeButton()
                
                self.contentNodes = .custom(CustomMediaPlayerScrubbingNodeContentNode(backgroundNode: backgroundNode, foregroundContentNode: foregroundContentNode, foregroundNode: foregroundNode, handleNodeContainer: handleNodeContainer))
        }
        
        super.init()
        
        switch self.contentNodes {
            case let .standard(node):
                self.addSubnode(node.backgroundNode)
                node.foregroundNode.addSubnode(node.foregroundContentNode)
                self.addSubnode(node.foregroundNode)
                
                if let handleNodeContainer = node.handleNodeContainer {
                    self.addSubnode(handleNodeContainer)
                    handleNodeContainer.beginScrubbing = { [weak self] in
                        if let strongSelf = self {
                            if let statusValue = strongSelf.statusValue, Double(0.0).isLess(than: statusValue.duration) {
                                strongSelf.scrubbingBeginTimestamp = statusValue.timestamp
                                strongSelf.scrubbingTimestamp = statusValue.timestamp
                                strongSelf.updateProgress()
                            }
                        }
                    }
                    handleNodeContainer.updateScrubbing = { [weak self] addedFraction in
                        if let strongSelf = self {
                            if let statusValue = strongSelf.statusValue, let scrubbingBeginTimestamp = strongSelf.scrubbingBeginTimestamp, Double(0.0).isLess(than: statusValue.duration) {
                                strongSelf.scrubbingTimestamp = scrubbingBeginTimestamp + statusValue.duration * Double(addedFraction)
                                strongSelf.updateProgress()
                            }
                        }
                    }
                    handleNodeContainer.endScrubbing = { [weak self] apply in
                        if let strongSelf = self {
                            strongSelf.scrubbingBeginTimestamp = nil
                            let scrubbingTimestamp = strongSelf.scrubbingTimestamp
                            strongSelf.scrubbingTimestamp = nil
                            if let scrubbingTimestamp = scrubbingTimestamp, apply {
                                if let statusValue = strongSelf.statusValue {
                                    strongSelf.ignoreSeekId = statusValue.seekId
                                }
                                strongSelf.seek?(scrubbingTimestamp)
                            }
                            strongSelf.updateProgress()
                        }
                    }
                }
                
                node.foregroundNode.onEnterHierarchy = { [weak self] in
                    self?.updateProgress()
                }
            case let .custom(node):
                self.addSubnode(node.backgroundNode)
                node.foregroundNode.addSubnode(node.foregroundContentNode)
                self.addSubnode(node.foregroundNode)
                
                if let handleNodeContainer = node.handleNodeContainer {
                    self.addSubnode(handleNodeContainer)
                    handleNodeContainer.beginScrubbing = { [weak self] in
                        if let strongSelf = self {
                            if let statusValue = strongSelf.statusValue, Double(0.0).isLess(than: statusValue.duration) {
                                strongSelf.scrubbingBeginTimestamp = statusValue.timestamp
                                strongSelf.scrubbingTimestamp = statusValue.timestamp
                                strongSelf.updateProgress()
                            }
                        }
                    }
                    handleNodeContainer.updateScrubbing = { [weak self] addedFraction in
                        if let strongSelf = self {
                            if let statusValue = strongSelf.statusValue, let scrubbingBeginTimestamp = strongSelf.scrubbingBeginTimestamp, Double(0.0).isLess(than: statusValue.duration) {
                                strongSelf.scrubbingTimestamp = scrubbingBeginTimestamp + statusValue.duration * Double(addedFraction)
                                strongSelf.updateProgress()
                            }
                        }
                    }
                    handleNodeContainer.endScrubbing = { [weak self] apply in
                        if let strongSelf = self {
                            strongSelf.scrubbingBeginTimestamp = nil
                            let scrubbingTimestamp = strongSelf.scrubbingTimestamp
                            strongSelf.scrubbingTimestamp = nil
                            if let scrubbingTimestamp = scrubbingTimestamp, apply {
                                strongSelf.seek?(scrubbingTimestamp)
                            }
                            strongSelf.updateProgress()
                        }
                    }
                }
                
                node.foregroundNode.onEnterHierarchy = { [weak self] in
                    self?.updateProgress()
                }
        }
        
        self.statusDisposable = (self.statusValuePromise.get()
            |> deliverOnMainQueue).start(next: { [weak self] status in
                if let strongSelf = self {
                    strongSelf.statusValue = status
                }
            })
    }
    
    deinit {
        self.statusDisposable?.dispose()
    }
    
    override var frame: CGRect {
        didSet {
            if self.frame.size != oldValue.size {
                self.updateProgress()
            }
        }
    }
    
    func updateColors(backgroundColor: UIColor, foregroundColor: UIColor) {
        switch self.contentNodes {
            case let .standard(node):
                switch node.lineCap {
                    case .round:
                        node.backgroundNode.image = generateStretchableFilledCircleImage(diameter: node.lineHeight, color: backgroundColor)
                        node.foregroundContentNode.image = generateStretchableFilledCircleImage(diameter: node.lineHeight, color: foregroundColor)
                    case .square:
                        node.backgroundNode.backgroundColor = backgroundColor
                        node.foregroundContentNode.backgroundColor = foregroundColor
                }
                if let handleNode = node.handleNode as? ASImageNode {
                    handleNode.image = generateHandleBackground(color: foregroundColor)
                }
            case .custom:
                break
        }
    }
    
    private func preparedAnimation(keyPath: String, from: NSValue, to: NSValue, duration: Double, beginTime: Double?, offset: Double, speed: Float, repeatForever: Bool = false) -> CAAnimation {
        let animation = CABasicAnimation(keyPath: keyPath)
        animation.fromValue = from
        animation.toValue = to
        animation.duration = duration
        animation.fillMode = kCAFillModeBoth
        animation.speed = speed
        animation.timeOffset = offset
        animation.isAdditive = false
        if let beginTime = beginTime {
            animation.beginTime = beginTime
        }
        return animation
    }
    
    private func updateProgress() {
        let bounds = self.bounds
        
        switch self.contentNodes {
            case let .standard(node):
                node.foregroundNode.layer.removeAnimation(forKey: "playback-bounds")
                node.foregroundNode.layer.removeAnimation(forKey: "playback-position")
                if let handleNodeContainer = node.handleNodeContainer {
                    handleNodeContainer.layer.removeAnimation(forKey: "playback-bounds")
                }
                
                let backgroundFrame = CGRect(origin: CGPoint(x: 0.0, y: floor((bounds.size.height - node.lineHeight) / 2.0)), size: CGSize(width: bounds.size.width, height: node.lineHeight))
                node.backgroundNode.frame = backgroundFrame
                node.foregroundContentNode.frame = CGRect(origin: CGPoint(), size: CGSize(width: backgroundFrame.size.width, height: backgroundFrame.size.height))
                
                
                if let handleNode = node.handleNode {
                    var handleSize: CGSize = CGSize(width: 2.0, height: bounds.size.height)
                    
                    if let handleNode = handleNode as? ASImageNode, let image = handleNode.image, image.size.width.isEqual(to: 7.0) {
                        handleSize = image.size
                    }
                    handleNode.frame = CGRect(origin: CGPoint(x: 0.0, y: floor((bounds.size.height - handleSize.height) / 2.0)), size: handleSize)
                    handleNode.layer.removeAnimation(forKey: "playback-position")
                }
                
                if let handleNodeContainer = node.handleNodeContainer {
                    handleNodeContainer.frame = bounds
                }
                
                var initialBuffering = false
                var timestampAndDuration: (timestamp: Double, duration: Double)?
                if let statusValue = self.statusValue {
                    if case .buffering(true, _) = statusValue.status {
                        initialBuffering = true
                    } else if Double(0.0).isLess(than: statusValue.duration) {
                        if let scrubbingTimestamp = self.scrubbingTimestamp {
                            timestampAndDuration = (max(0.0, min(scrubbingTimestamp, statusValue.duration)), statusValue.duration)
                        } else {
                            timestampAndDuration = (statusValue.timestamp, statusValue.duration)
                        }
                    }
                }
                
                if let (timestamp, duration) = timestampAndDuration {
                    let progress = CGFloat(timestamp / duration)
                    if let _ = scrubbingTimestamp {
                        let fromRect = CGRect(origin: backgroundFrame.origin, size: CGSize(width: 0.0, height: backgroundFrame.size.height))
                        let toRect = CGRect(origin: backgroundFrame.origin, size: CGSize(width: backgroundFrame.size.width, height: backgroundFrame.size.height))
                        
                        let fromBounds = CGRect(origin: CGPoint(), size: fromRect.size)
                        let toBounds = CGRect(origin: CGPoint(), size: toRect.size)
                        
                        node.foregroundNode.frame = toRect
                        node.foregroundNode.layer.add(self.preparedAnimation(keyPath: "bounds", from: NSValue(cgRect: fromBounds), to: NSValue(cgRect: toBounds), duration: duration, beginTime: nil, offset: timestamp, speed: 0.0), forKey: "playback-bounds")
                        node.foregroundNode.layer.add(self.preparedAnimation(keyPath: "position", from: NSValue(cgPoint: CGPoint(x: fromRect.midX, y: fromRect.midY)), to: NSValue(cgPoint: CGPoint(x: toRect.midX, y: toRect.midY)), duration: duration, beginTime: nil, offset: timestamp, speed: 0.0), forKey: "playback-position")
                        
                        if let handleNodeContainer = node.handleNodeContainer {
                            let fromBounds = bounds
                            let toBounds = bounds.offsetBy(dx: -bounds.size.width, dy: 0.0)
                            
                            handleNodeContainer.isHidden = false
                            handleNodeContainer.layer.add(self.preparedAnimation(keyPath: "bounds", from: NSValue(cgRect: fromBounds), to: NSValue(cgRect: toBounds), duration: duration, beginTime: nil, offset: timestamp, speed: 0.0), forKey: "playback-bounds")
                        }
                        
                        if let handleNode = node.handleNode {
                            let fromPosition = handleNode.position
                            let toPosition = CGPoint(x: fromPosition.x - 1.0, y: fromPosition.y)
                            handleNode.layer.add(self.preparedAnimation(keyPath: "position", from: NSValue(cgPoint: fromPosition), to: NSValue(cgPoint: toPosition), duration: duration / Double(bounds.size.width), beginTime: nil, offset: timestamp, speed: 0.0, repeatForever: true), forKey: "playback-position")
                        }
                    } else if let statusValue = self.statusValue, !progress.isNaN && progress.isFinite {
                        if statusValue.generationTimestamp.isZero {
                            let fromRect = CGRect(origin: backgroundFrame.origin, size: CGSize(width: 0.0, height: backgroundFrame.size.height))
                            let toRect = CGRect(origin: backgroundFrame.origin, size: CGSize(width: backgroundFrame.size.width, height: backgroundFrame.size.height))
                            
                            let fromBounds = CGRect(origin: CGPoint(), size: fromRect.size)
                            let toBounds = CGRect(origin: CGPoint(), size: toRect.size)
                            
                            node.foregroundNode.frame = toRect
                            node.foregroundNode.layer.add(self.preparedAnimation(keyPath: "bounds", from: NSValue(cgRect: fromBounds), to: NSValue(cgRect: toBounds), duration: duration, beginTime: nil, offset: timestamp, speed: 0.0), forKey: "playback-bounds")
                            node.foregroundNode.layer.add(self.preparedAnimation(keyPath: "position", from: NSValue(cgPoint: CGPoint(x: fromRect.midX, y: fromRect.midY)), to: NSValue(cgPoint: CGPoint(x: toRect.midX, y: toRect.midY)), duration: duration, beginTime: nil, offset: timestamp, speed: 0.0), forKey: "playback-position")
                            
                            if let handleNodeContainer = node.handleNodeContainer {
                                let fromBounds = bounds
                                let toBounds = bounds.offsetBy(dx: -bounds.size.width, dy: 0.0)
                                
                                handleNodeContainer.isHidden = false
                                handleNodeContainer.layer.add(self.preparedAnimation(keyPath: "bounds", from: NSValue(cgRect: fromBounds), to: NSValue(cgRect: toBounds), duration: duration, beginTime: nil, offset: timestamp, speed: 0.0), forKey: "playback-bounds")
                            }
                            
                            if let handleNode = node.handleNode {
                                let fromPosition = handleNode.position
                                let toPosition = CGPoint(x: fromPosition.x - 1.0, y: fromPosition.y)
                                handleNode.layer.add(self.preparedAnimation(keyPath: "position", from: NSValue(cgPoint: fromPosition), to: NSValue(cgPoint: toPosition), duration: duration / Double(bounds.size.width), beginTime: nil, offset: timestamp, speed: 0.0, repeatForever: true), forKey: "playback-position")
                            }
                        } else {
                            let fromRect = CGRect(origin: backgroundFrame.origin, size: CGSize(width: 0.0, height: backgroundFrame.size.height))
                            let toRect = CGRect(origin: backgroundFrame.origin, size: CGSize(width: backgroundFrame.size.width, height: backgroundFrame.size.height))
                            
                            let fromBounds = CGRect(origin: CGPoint(), size: fromRect.size)
                            let toBounds = CGRect(origin: CGPoint(), size: toRect.size)
                            
                            node.foregroundNode.frame = toRect
                            node.foregroundNode.layer.add(self.preparedAnimation(keyPath: "bounds", from: NSValue(cgRect: fromBounds), to: NSValue(cgRect: toBounds), duration: duration, beginTime: statusValue.generationTimestamp, offset: timestamp, speed: statusValue.status == .playing ? 1.0 : 0.0), forKey: "playback-bounds")
                            node.foregroundNode.layer.add(self.preparedAnimation(keyPath: "position", from: NSValue(cgPoint: CGPoint(x: fromRect.midX, y: fromRect.midY)), to: NSValue(cgPoint: CGPoint(x: toRect.midX, y: toRect.midY)), duration: duration, beginTime: statusValue.generationTimestamp, offset: timestamp, speed: statusValue.status == .playing ? 1.0 : 0.0), forKey: "playback-position")
                            
                            if let handleNodeContainer = node.handleNodeContainer {
                                let fromBounds = bounds
                                let toBounds = bounds.offsetBy(dx: -bounds.size.width, dy: 0.0)
                                
                                handleNodeContainer.isHidden = false
                                handleNodeContainer.layer.add(self.preparedAnimation(keyPath: "bounds", from: NSValue(cgRect: fromBounds), to: NSValue(cgRect: toBounds), duration: statusValue.duration, beginTime: statusValue.generationTimestamp, offset: statusValue.timestamp, speed: statusValue.status == .playing ? 1.0 : 0.0), forKey: "playback-bounds")
                            }
                            
                            if let handleNode = node.handleNode {
                                let fromPosition = handleNode.position
                                let toPosition = CGPoint(x: fromPosition.x - 1.0, y: fromPosition.y)
                                handleNode.layer.add(self.preparedAnimation(keyPath: "position", from: NSValue(cgPoint: fromPosition), to: NSValue(cgPoint: toPosition), duration: duration / Double(bounds.size.width), beginTime: statusValue.generationTimestamp, offset: timestamp, speed: statusValue.status == .playing ? 1.0 : 0.0, repeatForever: true), forKey: "playback-position")
                            }
                        }
                    } else {
                        node.handleNodeContainer?.isHidden = true
                        node.foregroundNode.frame = CGRect(origin: backgroundFrame.origin, size: CGSize(width: 0.0, height: backgroundFrame.size.height))
                    }
                } else {
                    node.foregroundNode.frame = CGRect(origin: backgroundFrame.origin, size: CGSize(width: 0.0, height: backgroundFrame.size.height))
                    node.handleNodeContainer?.isHidden = true
                }
            
                if initialBuffering {
                    
                } else {
                    
                }
            case let .custom(node):
                if let handleNodeContainer = node.handleNodeContainer {
                    handleNodeContainer.frame = bounds
                }
                
                node.foregroundNode.layer.removeAnimation(forKey: "playback-bounds")
                node.foregroundNode.layer.removeAnimation(forKey: "playback-position")
                
                let backgroundFrame = CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: CGSize(width: bounds.size.width, height: bounds.size.height))
                node.backgroundNode.frame = backgroundFrame
                node.foregroundContentNode.frame = CGRect(origin: CGPoint(), size: CGSize(width: backgroundFrame.size.width, height: backgroundFrame.size.height))
                
                let timestampAndDuration: (timestamp: Double, duration: Double)?
                if let statusValue = self.statusValue, Double(0.0).isLess(than: statusValue.duration) {
                    if let scrubbingTimestamp = self.scrubbingTimestamp {
                        timestampAndDuration = (max(0.0, min(scrubbingTimestamp, statusValue.duration)), statusValue.duration)
                    } else {
                        timestampAndDuration = (statusValue.timestamp, statusValue.duration)
                    }
                } else {
                    timestampAndDuration = nil
                }
                
                if let (timestamp, duration) = timestampAndDuration {
                    let progress = CGFloat(timestamp / duration)
                    if let _ = scrubbingTimestamp {
                        let fromRect = CGRect(origin: backgroundFrame.origin, size: CGSize(width: 0.0, height: backgroundFrame.size.height))
                        let toRect = CGRect(origin: backgroundFrame.origin, size: CGSize(width: backgroundFrame.size.width, height: backgroundFrame.size.height))
                        
                        let fromBounds = CGRect(origin: CGPoint(), size: fromRect.size)
                        let toBounds = CGRect(origin: CGPoint(), size: toRect.size)
                        
                        node.foregroundNode.frame = toRect
                        node.foregroundNode.layer.add(self.preparedAnimation(keyPath: "bounds", from: NSValue(cgRect: fromBounds), to: NSValue(cgRect: toBounds), duration: duration, beginTime: nil, offset: timestamp, speed: 0.0), forKey: "playback-bounds")
                        node.foregroundNode.layer.add(self.preparedAnimation(keyPath: "position", from: NSValue(cgPoint: CGPoint(x: fromRect.midX, y: fromRect.midY)), to: NSValue(cgPoint: CGPoint(x: toRect.midX, y: toRect.midY)), duration: duration, beginTime: nil, offset: timestamp, speed: 0.0), forKey: "playback-position")
                    } else if let statusValue = self.statusValue, !progress.isNaN && progress.isFinite {
                        if statusValue.generationTimestamp.isZero {
                            let fromRect = CGRect(origin: backgroundFrame.origin, size: CGSize(width: 0.0, height: backgroundFrame.size.height))
                            let toRect = CGRect(origin: backgroundFrame.origin, size: CGSize(width: backgroundFrame.size.width, height: backgroundFrame.size.height))
                            
                            let fromBounds = CGRect(origin: CGPoint(), size: fromRect.size)
                            let toBounds = CGRect(origin: CGPoint(), size: toRect.size)
                            
                            node.foregroundNode.frame = toRect
                            node.foregroundNode.layer.add(self.preparedAnimation(keyPath: "bounds", from: NSValue(cgRect: fromBounds), to: NSValue(cgRect: toBounds), duration: duration, beginTime: nil, offset: timestamp, speed: 0.0), forKey: "playback-bounds")
                            node.foregroundNode.layer.add(self.preparedAnimation(keyPath: "position", from: NSValue(cgPoint: CGPoint(x: fromRect.midX, y: fromRect.midY)), to: NSValue(cgPoint: CGPoint(x: toRect.midX, y: toRect.midY)), duration: duration, beginTime: nil, offset: timestamp, speed: 0.0), forKey: "playback-position")
                        } else {
                            let fromRect = CGRect(origin: backgroundFrame.origin, size: CGSize(width: 0.0, height: backgroundFrame.size.height))
                            let toRect = CGRect(origin: backgroundFrame.origin, size: CGSize(width: backgroundFrame.size.width, height: backgroundFrame.size.height))
                            
                            let fromBounds = CGRect(origin: CGPoint(), size: fromRect.size)
                            let toBounds = CGRect(origin: CGPoint(), size: toRect.size)
                            
                            node.foregroundNode.frame = toRect
                            node.foregroundNode.layer.add(self.preparedAnimation(keyPath: "bounds", from: NSValue(cgRect: fromBounds), to: NSValue(cgRect: toBounds), duration: duration, beginTime: statusValue.generationTimestamp, offset: timestamp, speed: statusValue.status == .playing ? 1.0 : 0.0), forKey: "playback-bounds")
                            node.foregroundNode.layer.add(self.preparedAnimation(keyPath: "position", from: NSValue(cgPoint: CGPoint(x: fromRect.midX, y: fromRect.midY)), to: NSValue(cgPoint: CGPoint(x: toRect.midX, y: toRect.midY)), duration: duration, beginTime: statusValue.generationTimestamp, offset: timestamp, speed: statusValue.status == .playing ? 1.0 : 0.0), forKey: "playback-position")
                        }
                    } else {
                        node.foregroundNode.frame = CGRect(origin: backgroundFrame.origin, size: CGSize(width: 0.0, height: backgroundFrame.size.height))
                    }
                } else {
                    node.foregroundNode.frame = CGRect(origin: backgroundFrame.origin, size: CGSize(width: 0.0, height: backgroundFrame.size.height))
                }
        }
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if self.bounds.contains(point) {
            switch self.contentNodes {
                case let .standard(node):
                    return node.handleNodeContainer?.view
                case let .custom(node):
                    return node.handleNodeContainer?.view
            }
            return super.hitTest(point, with: event)
        } else {
            return nil
        }
    }
}
