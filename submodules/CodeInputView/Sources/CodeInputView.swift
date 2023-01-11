import Foundation
import UIKit
import AsyncDisplayKit
import Display
import SwiftSignalKit
import PhoneNumberFormat

public final class CodeInputView: ASDisplayNode, UITextFieldDelegate {
    public struct Theme: Equatable {
        public var inactiveBorder: UInt32
        public var activeBorder: UInt32
        public var succeedBorder: UInt32
        public var failedBorder: UInt32
        public var foreground: UInt32
        public var isDark: Bool
        
        public init(
            inactiveBorder: UInt32,
            activeBorder: UInt32,
            succeedBorder: UInt32,
            failedBorder: UInt32,
            foreground: UInt32,
            isDark: Bool
        ) {
            self.inactiveBorder = inactiveBorder
            self.activeBorder = activeBorder
            self.succeedBorder = succeedBorder
            self.failedBorder = failedBorder
            self.foreground = foreground
            self.isDark = isDark
        }
    }
    
    private final class ItemView: ASDisplayNode {
        private let backgroundView: UIView
        private let textNode: ImmediateTextNode
        
        private var borderColorValue: UInt32?
        
        private var text: String = ""
        
        override init() {
            self.backgroundView = UIView()
            self.textNode = ImmediateTextNode()
            
            super.init()
            
            self.addSubnode(self.textNode)
            self.view.addSubview(self.backgroundView)
            
            self.clipsToBounds = true
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func didLoad() {
            super.didLoad()
            
            self.textNode.layer.anchorPoint = CGPoint(x: 0.5, y: 1.0)
        }
        
        func update(borderColor: UInt32, isHighlighted: Bool) {
            if self.borderColorValue != borderColor {
                self.borderColorValue = borderColor
                
                let previousColor = self.backgroundView.layer.borderColor
                self.backgroundView.layer.borderColor = UIColor(argb: borderColor).cgColor
                self.backgroundView.layer.borderWidth = 1.0 + UIScreenPixel
                if let previousColor = previousColor {
                    self.backgroundView.layer.animate(from: previousColor, to: UIColor(argb: borderColor).cgColor, keyPath: "borderColor", timingFunction: CAMediaTimingFunctionName.linear.rawValue, duration: 0.15)
                }
            }
        }
        
        func update(textColor: UInt32, text: String, size: CGSize, fontSize: CGFloat, animated: Bool, delay: Double? = nil) {
            let previousText = self.text
            self.text = text
            
            if animated && previousText.isEmpty != text.isEmpty {
                if !text.isEmpty {
                    self.textNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.25)
                    self.textNode.layer.animateSpring(from: NSValue(cgPoint: CGPoint(x: 0.0, y: size.height * 0.35)), to: NSValue(cgPoint: CGPoint()), keyPath: "position", duration: 0.4, damping: 70.0, additive: true)
                    self.textNode.layer.animateScaleY(from: 0.01, to: 1.0, duration: 0.25)
                } else {
                    if let copyView = self.textNode.view.snapshotContentTree() {
                        self.view.insertSubview(copyView, at: 0)
                        copyView.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.2, delay: delay ?? 0.0, removeOnCompletion: false, completion: { [weak copyView] _ in
                            copyView?.removeFromSuperview()
                        })
                        copyView.layer.animatePosition(from: CGPoint(), to: CGPoint(x: 0.0, y: size.height / 2.0), duration: 0.2, delay: delay ?? 0.0, removeOnCompletion: false, additive: true)
                    }
                }
            }
            
            self.backgroundView.layer.cornerRadius = size.height == 28.0 ? 12.0 : 15.0
            if #available(iOS 13.0, *) {
                self.backgroundView.layer.cornerCurve = .continuous
            }
            
            if #available(iOS 13.0, *) {
                self.textNode.attributedText = NSAttributedString(string: text, font: UIFont.monospacedSystemFont(ofSize: fontSize, weight: .regular), textColor: UIColor(argb: textColor))
            } else {
                self.textNode.attributedText = NSAttributedString(string: text, font: Font.monospace(fontSize), textColor: UIColor(argb: textColor))
            }
            let textSize = self.textNode.updateLayout(size)
            self.textNode.frame = CGRect(origin: CGPoint(x: floorToScreenPixels((size.width - textSize.width) / 2.0), y: floorToScreenPixels((size.height - textSize.height) / 2.0)), size: textSize)
            
            self.backgroundView.frame = CGRect(origin: CGPoint(), size: size)
        }
    }
    
    private let prefixLabel: ImmediateTextNode
    public let textField: UITextField
    
    private var focusIndex: Int? = 0
    private var itemViews: [ItemView] = []
    
    public var updated: (() -> Void)?
    
    private var theme: Theme?
    private var count: Int?
    private var prefix: String = ""
    private var compact = false
    
    private var textValue: String = ""
    public var text: String {
        get {
            return self.textValue
        } set(value) {
            self.textValue = value
            self.textField.text = value
        }
    }
    
    override public init() {
        self.prefixLabel = ImmediateTextNode()
        self.textField = UITextField()
        
        if #available(iOSApplicationExtension 10.0, iOS 10.0, *) {
            self.textField.keyboardType = .asciiCapableNumberPad
        } else {
            self.textField.keyboardType = .numberPad
        }
        if #available(iOSApplicationExtension 12.0, iOS 12.0, *) {
            self.textField.textContentType = .oneTimeCode
        }
        self.textField.returnKeyType = .done
        self.textField.disableAutomaticKeyboardHandling = [.forward, .backward]
        
        super.init()
        
        self.addSubnode(self.prefixLabel)
        self.view.addSubview(self.textField)
        
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tapGesture(_:))))
        self.textField.delegate = self
        self.textField.addTarget(self, action: #selector(self.textFieldChanged(_:)), for: .editingChanged)
    }
    
    required public init?(coder: NSCoder) {
        preconditionFailure()
    }
    
    @objc private func tapGesture(_ recognizer: UITapGestureRecognizer) {
        if case .ended = recognizer.state {
            self.textField.becomeFirstResponder()
        }
    }
    
    private var isSucceed = false
    private var isFailed = false
    private var isResetting = false
    public func animateError() {
        self.isFailed = true
        self.updateItemViews(animated: true)
        Queue.mainQueue().after(0.85, {
            self.textValue = ""
            self.isResetting = true
            self.updateItemViews(animated: true)
            self.isResetting = false
            self.textField.text = ""
            self.isFailed = false
            self.updateItemViews(animated: true)
        })
    }
    
    public func animateSuccess() {
        self.isSucceed = true
        self.updateItemViews(animated: true)
    }
    
    @objc func textFieldChanged(_ textField: UITextField) {
        self.textValue = textField.text ?? ""
        self.updateItemViews(animated: true)
        self.updated?()
    }
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let count = self.count else {
            return false
        }
        
        guard !self.isFailed else {
            return false
        }
        
        var text = textField.text ?? ""
        guard let stringRange = Range(range, in: text) else {
            return false
        }
        text.replaceSubrange(stringRange, with: string)
        
        if !text.allSatisfy({ $0.isNumber && $0.isASCII }) {
            return false
        }
        
        if text.count > count {
            return false
        }
        
        return true
    }
    
    private func currentCaretIndex() -> Int? {
        if let selectedTextRange = self.textField.selectedTextRange {
            let index = self.textField.offset(from: self.textField.beginningOfDocument, to: selectedTextRange.end)
            return index
        } else {
            return nil
        }
    }
    
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        self.focusIndex = self.currentCaretIndex()
        self.updateItemViews(animated: true)
    }
    
    public func textFieldDidEndEditing(_ textField: UITextField) {
        self.focusIndex = textField.text?.count ?? 0
        self.updateItemViews(animated: true)
    }
    
    public func textFieldDidChangeSelection(_ textField: UITextField) {
        self.focusIndex = self.currentCaretIndex()
        self.updateItemViews(animated: true)
    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return false
    }
    
    private func updateItemViews(animated: Bool) {
        guard let theme = self.theme else {
            return
        }
        
        var delay: Double = 0.0
        for i in 0 ..< self.itemViews.count {
            let itemView = self.itemViews[i]
            let itemSize = itemView.bounds.size
            
            let fontSize: CGFloat
            if self.prefix.isEmpty {
                let height: CGFloat = self.compact ? 44.0 : 51.0
                fontSize = floor(13.0 * height / 28.0)
            } else {
                let height: CGFloat = 28.0
                fontSize = floor(21.0 * height / 28.0)
            }
            
            let borderColor: UInt32
            if self.isSucceed {
                borderColor = theme.succeedBorder
            } else if self.isFailed {
                borderColor = theme.failedBorder
            } else {
                borderColor = self.focusIndex == i ? theme.activeBorder : theme.inactiveBorder
            }
            
            itemView.update(borderColor: borderColor, isHighlighted: self.focusIndex == i)
            let itemText: String
            if i < self.textValue.count {
                itemText = String(self.textValue[self.textValue.index(self.textValue.startIndex, offsetBy: i)])
            } else {
                itemText = ""
            }
            itemView.update(textColor: theme.foreground, text: itemText, size: itemSize, fontSize: fontSize, animated: animated, delay: delay)
            if self.isResetting {
                delay += 0.05
            }
        }
    }
    
    public func update(theme: Theme, prefix: String, count: Int, width: CGFloat, compact: Bool) -> CGSize {
        self.theme = theme
        self.count = count
        self.prefix = prefix
        self.compact = compact
        
        if theme.isDark {
            self.textField.keyboardAppearance = .dark
        } else {
            self.textField.keyboardAppearance = .light
        }
        
        let fontSize: CGFloat
        let height: CGFloat
        if prefix.isEmpty {
            height = compact ? 44.0 : 51.0
            fontSize = floor(13.0 * height / 28.0)
        } else {
            height = 28.0
            fontSize = floor(21.0 * height / 28.0)
        }
        
        if #available(iOS 13.0, *) {
            self.prefixLabel.attributedText = NSAttributedString(string: prefix, font: UIFont.monospacedSystemFont(ofSize: 21.0, weight: .regular), textColor: UIColor(argb: theme.foreground))
        } else {
            self.prefixLabel.attributedText = NSAttributedString(string: prefix, font: Font.monospace(21.0), textColor: UIColor(argb: theme.foreground))
        }
        let prefixSize = self.prefixLabel.updateLayout(CGSize(width: width, height: 100.0))
        let prefixSpacing: CGFloat = prefix.isEmpty ? 0.0 : 8.0
        
        let itemSize = CGSize(width: floor(24.0 * height / 28.0), height: height)
        let itemSpacing: CGFloat = prefix.isEmpty ? 15.0 : 5.0
        let itemsWidth: CGFloat = itemSize.width * CGFloat(count) + itemSpacing * CGFloat(count - 1)
        
        let contentWidth: CGFloat = prefixSize.width + prefixSpacing + itemsWidth
        let contentOriginX: CGFloat = floor((width - contentWidth) / 2.0)
        
        self.prefixLabel.frame = CGRect(origin: CGPoint(x: contentOriginX, y: floorToScreenPixels((height - prefixSize.height) / 2.0)), size: prefixSize)
        
        for i in 0 ..< count {
            let itemView: ItemView
            if self.itemViews.count > i {
                itemView = self.itemViews[i]
            } else {
                itemView = ItemView()
                self.itemViews.append(itemView)
                self.addSubnode(itemView)
            }
            
            let borderColor: UInt32
            if self.isSucceed {
                borderColor = theme.succeedBorder
            } else if self.isFailed {
                borderColor = theme.failedBorder
            } else {
                borderColor = self.focusIndex == i ? theme.activeBorder : theme.inactiveBorder
            }
            
            itemView.update(borderColor: borderColor, isHighlighted: self.focusIndex == i)
            let itemText: String
            if i < self.textValue.count {
                itemText = String(self.textValue[self.textValue.index(self.textValue.startIndex, offsetBy: i)])
            } else {
                itemText = ""
            }
            itemView.update(textColor: theme.foreground, text: itemText, size: itemSize, fontSize: fontSize, animated: false)
            itemView.frame = CGRect(origin: CGPoint(x: contentOriginX + prefixSize.width + prefixSpacing + CGFloat(i) * (itemSize.width + itemSpacing), y: 0.0), size: itemSize)
        }
        if self.itemViews.count > count {
            for i in count ..< self.itemViews.count {
                self.itemViews[i].removeFromSupernode()
            }
            self.itemViews.removeSubrange(count...)
        }
        
        return CGSize(width: width, height: height)
    }
    
    public override func becomeFirstResponder() -> Bool {
        return self.textField.becomeFirstResponder()
    }
    
    public override func canBecomeFirstResponder() -> Bool {
        return self.textField.canBecomeFirstResponder
    }
    
    public override func resignFirstResponder() -> Bool {
        return self.textField.resignFirstResponder()
    }
    
    public override func canResignFirstResponder() -> Bool {
        return self.textField.canResignFirstResponder
    }
    
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if self.bounds.contains(point) {
            return self.view
        } else {
            return nil
        }
    }
}
