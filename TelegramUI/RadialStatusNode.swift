import Foundation
import AsyncDisplayKit

enum RadialStatusNodeState: Equatable {
    case none
    case download(UIColor)
    case play(UIColor)
    case pause(UIColor)
    case progress(color: UIColor, value: CGFloat?, cancelEnabled: Bool)
    case check(UIColor)
    case customIcon(UIImage)
    case secretTimeout(color: UIColor, icon: UIImage?, beginTime: Double, timeout: Double)
    
    static func ==(lhs: RadialStatusNodeState, rhs: RadialStatusNodeState) -> Bool {
        switch lhs {
            case .none:
                if case .none = rhs {
                    return true
                } else {
                    return false
                }
            case let .download(lhsColor):
                if case let .download(rhsColor) = rhs, lhsColor.isEqual(rhsColor) {
                    return true
                } else {
                    return false
                }
            case let .play(lhsColor):
                if case let .play(rhsColor) = rhs, lhsColor.isEqual(rhsColor) {
                    return true
                } else {
                    return false
                }
            case let .pause(lhsColor):
                if case let .pause(rhsColor) = rhs, lhsColor.isEqual(rhsColor) {
                    return true
                } else {
                    return false
                }
            case let .progress(lhsColor, lhsValue, lhsCancelEnabled):
                if case let .progress(rhsColor, rhsValue, rhsCancelEnabled) = rhs, lhsColor.isEqual(rhsColor), lhsValue == rhsValue, lhsCancelEnabled == rhsCancelEnabled {
                    return true
                } else {
                    return false
                }
            case let .check(lhsColor):
                if case let .check(rhsColor) = rhs, lhsColor.isEqual(rhsColor) {
                    return true
                } else {
                    return false
                }
            case let .customIcon(lhsImage):
                if case let .customIcon(rhsImage) = rhs, lhsImage === rhsImage {
                    return true
                } else {
                    return false
                }
            case let .secretTimeout(lhsColor, lhsIcon, lhsBeginTime, lhsTimeout):
                if case let .secretTimeout(rhsColor, rhsIcon, rhsBeginTime, rhsTimeout) = rhs, lhsColor.isEqual(rhsColor), lhsIcon === rhsIcon, lhsBeginTime.isEqual(to: rhsBeginTime), lhsTimeout.isEqual(to: rhsTimeout) {
                    return true
                } else {
                    return false
                }
        }
    }
    
    func backgroundColor(color: UIColor) -> UIColor? {
        switch self {
            case .none:
                return nil
            default:
                return color
        }
    }
    
    func contentNode(current: RadialStatusContentNode?) -> RadialStatusContentNode? {
        switch self {
            case .none:
                return nil
            case let .download(color):
                return RadialStatusIconContentNode(icon: .download(color))
            case let .play(color):
                return RadialStatusIconContentNode(icon: .play(color))
            case let .pause(color):
                return RadialStatusIconContentNode(icon: .pause(color))
            case let .customIcon(image):
                return RadialStatusIconContentNode(icon: .custom(image))
            case let .check(color):
                return RadialCheckContentNode(color: color)
            case let .progress(color, value, cancelEnabled):
                if let current = current as? RadialProgressContentNode, current.displayCancel == cancelEnabled {
                    if !current.color.isEqual(color) {
                        current.color = color
                    }
                    current.progress = value
                    return current
                } else {
                    let node = RadialProgressContentNode(color: color, displayCancel: cancelEnabled)
                    node.progress = value
                    return node
                }
        case let .secretTimeout(color, icon, beginTime, timeout):
            return RadialStatusSecretTimeoutContentNode(color: color, beginTime: beginTime, timeout: timeout, icon: icon)
        }
    }
}

final class RadialStatusNode: ASControlNode {
    private var backgroundNodeColor: UIColor
    
    private(set) var state: RadialStatusNodeState = .none
    
    private var backgroundNode: RadialStatusBackgroundNode?
    private var contentNode: RadialStatusContentNode?
    private var nextContentNode: RadialStatusContentNode?
    
    init(backgroundNodeColor: UIColor) {
        self.backgroundNodeColor = backgroundNodeColor
        
        super.init()
    }
    
    func transitionToState(_ state: RadialStatusNodeState, animated: Bool = true, completion: @escaping () -> Void) {
        if self.state != state {
            self.state = state
            
            let contentNode = state.contentNode(current: self.contentNode)
            if contentNode !== self.contentNode {
                self.transitionToContentNode(contentNode, backgroundColor: state.backgroundColor(color: self.backgroundNodeColor), animated: animated, completion: completion)
            } else {
                self.transitionToBackgroundColor(state.backgroundColor(color: self.backgroundNodeColor), animated: animated, completion: completion)
            }
        } else {
            completion()
        }
    }
    
    private func transitionToContentNode(_ node: RadialStatusContentNode?, backgroundColor: UIColor?, animated: Bool, completion: @escaping () -> Void) {
        if let contentNode = self.contentNode {
            self.nextContentNode = node
            contentNode.enqueueReadyForTransition { [weak contentNode, weak self] in
                if let strongSelf = self, let contentNode = contentNode, strongSelf.contentNode === contentNode {
                    if animated {
                        strongSelf.contentNode = strongSelf.nextContentNode
                        contentNode.animateOut { [weak contentNode] in
                            if let strongSelf = self, let contentNode = contentNode {
                                if contentNode !== strongSelf.contentNode {
                                    contentNode.removeFromSupernode()
                                }
                            }
                        }
                        if let contentNode = strongSelf.contentNode {
                            strongSelf.addSubnode(contentNode)
                            contentNode.frame = strongSelf.bounds
                            if strongSelf.isNodeLoaded {
                                contentNode.layout()
                                contentNode.animateIn()
                            }
                        }
                        strongSelf.transitionToBackgroundColor(backgroundColor, animated: animated, completion: completion)
                    } else {
                        contentNode.removeFromSupernode()
                        strongSelf.contentNode = strongSelf.nextContentNode
                        if let contentNode = strongSelf.contentNode {
                            strongSelf.addSubnode(contentNode)
                            contentNode.frame = strongSelf.bounds
                            if strongSelf.isNodeLoaded {
                                contentNode.layout()
                            }
                        }
                        strongSelf.transitionToBackgroundColor(backgroundColor, animated: animated, completion: completion)
                    }
                }
            }
        } else {
            self.contentNode = node
            if let contentNode = self.contentNode {
                contentNode.frame = self.bounds
                self.addSubnode(contentNode)
            }
            self.transitionToBackgroundColor(backgroundColor, animated: animated, completion: completion)
        }
    }
    
    private func transitionToBackgroundColor(_ color: UIColor?, animated: Bool, completion: @escaping () -> Void) {
        let currentColor = self.backgroundNode?.color
        
        var updated = false
        if let color = color, let currentColor = currentColor {
            updated = !color.isEqual(currentColor)
        } else if (currentColor != nil) != (color != nil) {
            updated = true
        }
        
        if updated {
            if let color = color {
                if let backgroundNode = self.backgroundNode {
                    backgroundNode.color = color
                    completion()
                } else {
                    let backgroundNode = RadialStatusBackgroundNode(color: color)
                    backgroundNode.frame = self.bounds
                    self.backgroundNode = backgroundNode
                    self.insertSubnode(backgroundNode, at: 0)
                    completion()
                }
            } else if let backgroundNode = self.backgroundNode {
                self.backgroundNode = nil
                if animated {
                    backgroundNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.15, removeOnCompletion: false, completion: { [weak backgroundNode] _ in
                        backgroundNode?.removeFromSupernode()
                        completion()
                    })
                } else {
                    backgroundNode.removeFromSupernode()
                    completion()
                }
            }
        } else {
            completion()
        }
    }
    
    override func layout() {
        self.backgroundNode?.frame = self.bounds
        if let contentNode = self.contentNode {
            contentNode.frame = self.bounds
        }
    }
}
