import Foundation
import AsyncDisplayKit

public class ActionSheetTextItem: ActionSheetItem {
    public let title: String
    
    public init(title: String) {
        self.title = title
    }
    
    public func node() -> ActionSheetItemNode {
        let node = ActionSheetTextNode()
        node.setItem(self)
        return node
    }
    
    public func updateNode(_ node: ActionSheetItemNode) {
        guard let node = node as? ActionSheetTextNode else {
            assertionFailure()
            return
        }
        
        node.setItem(self)
    }
}

public class ActionSheetTextNode: ActionSheetItemNode {
    public static let defaultFont: UIFont = Font.regular(13.0)
    
    private var item: ActionSheetTextItem?
    
    private let label: ASTextNode
    
    override public init() {
        self.label = ASTextNode()
        self.label.isLayerBacked = true
        self.label.maximumNumberOfLines = 1
        self.label.displaysAsynchronously = false
        self.label.truncationMode = .byTruncatingTail
        
        super.init()
        
        self.label.isUserInteractionEnabled = false
        self.addSubnode(self.label)
    }
    
    func setItem(_ item: ActionSheetTextItem) {
        self.item = item
        
        let textColor = UIColor(rgb: 0x7c7c7c)
        
        self.label.attributedText = NSAttributedString(string: item.title, font: ActionSheetTextNode.defaultFont, textColor: textColor)
        
        self.setNeedsLayout()
    }
    
    public override func calculateSizeThatFits(_ constrainedSize: CGSize) -> CGSize {
        return CGSize(width: constrainedSize.width, height: 57.0)
    }
    
    public override func layout() {
        super.layout()
        
        let size = self.bounds.size
        
        let labelSize = self.label.measure(CGSize(width: max(1.0, size.width - 20.0), height: size.height))
        self.label.frame = CGRect(origin: CGPoint(x: floorToScreenPixels((size.width - labelSize.width) / 2.0), y: floorToScreenPixels((size.height - labelSize.height) / 2.0)), size: labelSize)
    }
}
