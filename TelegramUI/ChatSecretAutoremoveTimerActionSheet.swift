import Foundation
import Display
import AsyncDisplayKit
import UIKit
import SwiftSignalKit
import Photos

final class ChatSecretAutoremoveTimerActionSheetController: ActionSheetController {
    private let theme: PresentationTheme
    private let strings: PresentationStrings
    
    private let _ready = Promise<Bool>()
    override var ready: Promise<Bool> {
        return self._ready
    }
    
    init(theme: PresentationTheme, strings: PresentationStrings, currentValue: Int32, applyValue: @escaping (Int32) -> Void) {
        self.theme = theme
        self.strings = strings
        
        super.init(theme: ActionSheetControllerTheme(presentationTheme: theme))
        
        self._ready.set(.single(true))
        
        var updatedValue = currentValue
        self.setItemGroups([
            ActionSheetItemGroup(items: [
                AutoremoveTimeoutSelectorItem(strings: strings, currentValue: currentValue, valueChanged: { value in
                    updatedValue = value
                }),
                ActionSheetButtonItem(title: strings.Wallpaper_Set, action: { [weak self] in
                    self?.dismissAnimated()
                    applyValue(updatedValue)
                })
            ]),
            ActionSheetItemGroup(items: [
                ActionSheetButtonItem(title: strings.Common_Cancel, action: { [weak self] in
                    self?.dismissAnimated()
                }),
            ])
        ])
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class AutoremoveTimeoutSelectorItem: ActionSheetItem {
    let strings: PresentationStrings
    
    let currentValue: Int32
    let valueChanged: (Int32) -> Void
    
    init(strings: PresentationStrings, currentValue: Int32, valueChanged: @escaping (Int32) -> Void) {
        self.strings = strings
        self.currentValue = currentValue
        self.valueChanged = valueChanged
    }
    
    func node(theme: ActionSheetControllerTheme) -> ActionSheetItemNode {
        return AutoremoveTimeoutSelectorItemNode(theme: theme, strings: self.strings, currentValue: self.currentValue, valueChanged: self.valueChanged)
    }
    
    func updateNode(_ node: ActionSheetItemNode) {
    }
}

private let timeoutValues: [Int32] = [
    0,
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    12,
    13,
    14,
    15,
    30,
    1 * 60,
    1 * 60 * 60,
    24 * 60 * 60,
    7 * 24 * 60 * 60
]

private final class AutoremoveTimeoutSelectorItemNode: ActionSheetItemNode, UIPickerViewDelegate, UIPickerViewDataSource {
    private let theme: ActionSheetControllerTheme
    private let strings: PresentationStrings
    
    private let valueChanged: (Int32) -> Void
    private let pickerView: UIPickerView
    
    init(theme: ActionSheetControllerTheme, strings: PresentationStrings, currentValue: Int32, valueChanged: @escaping (Int32) -> Void) {
        self.theme = theme
        self.strings = strings
        self.valueChanged = valueChanged
        
        self.pickerView = UIPickerView()
        
        super.init(theme: theme)
        
        self.pickerView.delegate = self
        self.pickerView.dataSource = self
        self.view.addSubview(self.pickerView)
        
        self.pickerView.reloadAllComponents()
        var index: Int = 0
        for i in 0 ..< timeoutValues.count {
            if currentValue <= timeoutValues[i] {
                index = i
                break
            }
        }
        self.pickerView.selectRow(index, inComponent: 0, animated: false)
    }
    
    override func calculateSizeThatFits(_ constrainedSize: CGSize) -> CGSize {
        return CGSize(width: constrainedSize.width, height: 157.0)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return timeoutValues.count
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        if timeoutValues[row] == 0 {
            return NSAttributedString(string: self.strings.Profile_MessageLifetimeForever, font: Font.medium(15.0), textColor: self.theme.primaryTextColor)
        } else {
            return NSAttributedString(string: timeIntervalString(strings: self.strings, value: timeoutValues[row]), font: Font.medium(15.0), textColor: self.theme.primaryTextColor)
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.valueChanged(timeoutValues[row])
    }
    
    override func layout() {
        super.layout()
        
        self.pickerView.frame = CGRect(origin: CGPoint(), size: CGSize(width: self.bounds.size.width, height: 180.0))
    }
}
