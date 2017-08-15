import Foundation
import AsyncDisplayKit
import Display
import TelegramCore

private let countryButtonBackground = generateImage(CGSize(width: 45.0, height: 44.0 + 6.0), rotatedContext: { size, context in
    let arrowSize: CGFloat = 6.0
    let lineWidth = UIScreenPixel
    
    context.clear(CGRect(origin: CGPoint(), size: size))
    context.setFillColor(UIColor.white.cgColor)
    context.fill(CGRect(origin: CGPoint(), size: CGSize(width: size.width, height: size.height - arrowSize)))
    context.move(to: CGPoint(x: size.width, y: size.height - arrowSize))
    context.addLine(to: CGPoint(x: size.width - 1.0, y: size.height - arrowSize))
    context.addLine(to: CGPoint(x: size.width - 1.0 - arrowSize, y: size.height))
    context.addLine(to: CGPoint(x: size.width - 1.0 - arrowSize - arrowSize, y: size.height - arrowSize))
    context.closePath()
    context.fillPath()
    
    context.setStrokeColor(UIColor(rgb: 0xbcbbc1).cgColor)
    context.setLineWidth(lineWidth)
    
    context.move(to: CGPoint(x: size.width, y: size.height - arrowSize - lineWidth / 2.0))
    context.addLine(to: CGPoint(x: size.width - 1.0, y: size.height - arrowSize - lineWidth / 2.0))
    context.addLine(to: CGPoint(x: size.width - 1.0 - arrowSize, y: size.height - lineWidth / 2.0))
    context.addLine(to: CGPoint(x: size.width - 1.0 - arrowSize - arrowSize, y: size.height - arrowSize - lineWidth / 2.0))
    context.addLine(to: CGPoint(x: 15.0, y: size.height - arrowSize - lineWidth / 2.0))
    context.strokePath()
    
    context.move(to: CGPoint(x: 0.0, y: lineWidth / 2.0))
    context.addLine(to: CGPoint(x: size.width, y: lineWidth / 2.0))
    context.strokePath()
})?.stretchableImage(withLeftCapWidth: 46, topCapHeight: 1)

private let countryButtonHighlightedBackground = generateImage(CGSize(width: 45.0, height: 44.0 + 6.0), rotatedContext: { size, context in
    let arrowSize: CGFloat = 6.0
    context.clear(CGRect(origin: CGPoint(), size: size))
    context.setFillColor(UIColor(rgb: 0xbcbbc1).cgColor)
    context.fill(CGRect(origin: CGPoint(), size: CGSize(width: size.width, height: size.height - arrowSize)))
    context.move(to: CGPoint(x: size.width, y: size.height - arrowSize))
    context.addLine(to: CGPoint(x: size.width - 1.0, y: size.height - arrowSize))
    context.addLine(to: CGPoint(x: size.width - 1.0 - arrowSize, y: size.height))
    context.addLine(to: CGPoint(x: size.width - 1.0 - arrowSize - arrowSize, y: size.height - arrowSize))
    context.closePath()
    context.fillPath()
})?.stretchableImage(withLeftCapWidth: 46, topCapHeight: 2)

private let phoneInputBackground = generateImage(CGSize(width: 60.0, height: 44.0), rotatedContext: { size, context in
    let lineWidth = UIScreenPixel
    context.clear(CGRect(origin: CGPoint(), size: size))
    context.setFillColor(UIColor.white.cgColor)
    context.fill(CGRect(origin: CGPoint(), size: size))
    context.setStrokeColor(UIColor(rgb: 0xbcbbc1).cgColor)
    context.setLineWidth(lineWidth)
    context.move(to: CGPoint(x: 0.0, y: size.height - lineWidth / 2.0))
    context.addLine(to: CGPoint(x: size.width, y: size.height - lineWidth / 2.0))
    context.strokePath()
    context.move(to: CGPoint(x: size.width - 2.0 + lineWidth / 2.0, y: size.height - lineWidth / 2.0))
    context.addLine(to: CGPoint(x: size.width - 2.0 + lineWidth / 2.0, y: 0.0))
    context.strokePath()
})?.stretchableImage(withLeftCapWidth: 61, topCapHeight: 2)

final class ChangePhoneNumberControllerNode: ASDisplayNode {
    private let titleNode: ASTextNode
    private let noticeNode: ASTextNode
    private let countryButton: ASButtonNode
    private let phoneBackground: ASImageNode
    private let phoneInputNode: PhoneInputNode
    
    var currentNumber: String {
        return self.phoneInputNode.number
    }
    
    var codeAndNumber: (Int32?, String) {
        get {
            return self.phoneInputNode.codeAndNumber
        } set(value) {
            self.phoneInputNode.codeAndNumber = value
        }
    }
    
    var selectCountryCode: (() -> Void)?
    
    var inProgress: Bool = false {
        didSet {
            self.phoneInputNode.enableEditing = !self.inProgress
            self.phoneInputNode.alpha = self.inProgress ? 0.6 : 1.0
            self.countryButton.isEnabled = !self.inProgress
        }
    }
    
    var presentationData: PresentationData
    
    init(presentationData: PresentationData) {
        self.presentationData = presentationData
        
        self.titleNode = ASTextNode()
        self.titleNode.isLayerBacked = true
        self.titleNode.displaysAsynchronously = false
        self.titleNode.attributedText = NSAttributedString(string: self.presentationData.strings.ChangePhoneNumberNumber_NewNumber, font: Font.regular(14.0), textColor: self.presentationData.theme.list.sectionHeaderTextColor)
        
        self.noticeNode = ASTextNode()
        self.noticeNode.isLayerBacked = true
        self.noticeNode.displaysAsynchronously = false
        self.noticeNode.attributedText = NSAttributedString(string: self.presentationData.strings.ChangePhoneNumberNumber_Help, font: Font.regular(14.0), textColor: self.presentationData.theme.list.freeTextColor)
        
        self.countryButton = ASButtonNode()
        self.countryButton.setBackgroundImage(countryButtonBackground, for: [])
        self.countryButton.setBackgroundImage(countryButtonHighlightedBackground, for: .highlighted)
        
        self.phoneBackground = ASImageNode()
        self.phoneBackground.image = phoneInputBackground
        self.phoneBackground.displaysAsynchronously = false
        self.phoneBackground.displayWithoutProcessing = true
        self.phoneBackground.isLayerBacked = true
        
        self.phoneInputNode = PhoneInputNode(fontSize: 17.0)
        
        super.init()
        
        self.setViewBlock({
            return UITracingLayerView()
        })
        
        self.backgroundColor = self.presentationData.theme.list.blocksBackgroundColor
        
        self.addSubnode(self.titleNode)
        self.addSubnode(self.noticeNode)
        self.addSubnode(self.phoneBackground)
        self.addSubnode(self.countryButton)
        self.addSubnode(self.phoneInputNode)
        
        self.countryButton.contentEdgeInsets = UIEdgeInsets(top: 0.0, left: 15.0, bottom: 4.0, right: 0.0)
        self.countryButton.contentHorizontalAlignment = .left
        
        self.phoneInputNode.numberField.textField.attributedPlaceholder = NSAttributedString(string: self.presentationData.strings.Login_PhonePlaceholder, font: Font.regular(17.0), textColor: self.presentationData.theme.list.itemPlaceholderTextColor)
        
        self.countryButton.addTarget(self, action: #selector(self.countryPressed), forControlEvents: .touchUpInside)
        
        self.phoneInputNode.countryCodeUpdated = { [weak self] code in
            if let strongSelf = self {
                if let code = Int(code), let countryName = countryCodeToName[code] {
                    strongSelf.countryButton.setTitle(countryName, with: Font.regular(17.0), with: .black, for: [])
                } else {
                    strongSelf.countryButton.setTitle(strongSelf.presentationData.strings.Login_CountryCode, with: Font.regular(17.0), with: .black, for: [])
                }
            }
        }
        
        self.phoneInputNode.number = "+1"
    }
    
    func containerLayoutUpdated(_ layout: ContainerViewLayout, navigationBarHeight: CGFloat, transition: ContainedViewLayoutTransition) {
        let insets = layout.insets(options: [.statusBar, .input])
        
        let countryButtonHeight: CGFloat = 44.0
        let inputFieldsHeight: CGFloat = 44.0
        
        let titleSize = self.titleNode.measure(CGSize(width: layout.size.width - 28.0, height: CGFloat.greatestFiniteMagnitude))
        let noticeSize = self.noticeNode.measure(CGSize(width: layout.size.width - 28.0, height: CGFloat.greatestFiniteMagnitude))
        
        let navigationHeight: CGFloat = 97.0 + insets.top + navigationBarHeight
        
        let inputHeight = countryButtonHeight + inputFieldsHeight
        
        transition.updateFrame(node: self.titleNode, frame: CGRect(origin: CGPoint(x: 15.0, y: navigationHeight - titleSize.height - 8.0), size: titleSize))
        
        transition.updateFrame(node: self.countryButton, frame: CGRect(origin: CGPoint(x: 0.0, y: navigationHeight), size: CGSize(width: layout.size.width, height: 44.0 + 6.0)))
        transition.updateFrame(node: self.phoneBackground, frame: CGRect(origin: CGPoint(x: 0.0, y: navigationHeight + 44.0), size: CGSize(width: layout.size.width, height: 44.0)))
        
        let countryCodeFrame = CGRect(origin: CGPoint(x: 9.0, y: navigationHeight + 44.0 + 1.0), size: CGSize(width: 45.0, height: 44.0))
        let numberFrame = CGRect(origin: CGPoint(x: 70.0, y: navigationHeight + 44.0 + 1.0), size: CGSize(width: layout.size.width - 70.0 - 8.0, height: 44.0))
        
        let phoneInputFrame = countryCodeFrame.union(numberFrame)
        
        transition.updateFrame(node: self.phoneInputNode, frame: phoneInputFrame)
        transition.updateFrame(node: self.phoneInputNode.countryCodeField, frame: countryCodeFrame.offsetBy(dx: -phoneInputFrame.minX, dy: -phoneInputFrame.minY))
        transition.updateFrame(node: self.phoneInputNode.numberField, frame: numberFrame.offsetBy(dx: -phoneInputFrame.minX, dy: -phoneInputFrame.minY))
        
        transition.updateFrame(node: self.noticeNode, frame: CGRect(origin: CGPoint(x: 15.0, y: navigationHeight + inputHeight + 8.0), size: noticeSize))
    }
    
    func activateInput() {
        self.phoneInputNode.numberField.textField.becomeFirstResponder()
    }
    
    func animateError() {
        self.phoneInputNode.countryCodeField.layer.addShakeAnimation()
        self.phoneInputNode.numberField.layer.addShakeAnimation()
    }
    
    @objc func countryPressed() {
        self.selectCountryCode?()
    }
    
}
