import AsyncDisplayKit
import Display
import TelegramPresentationData
import QuartzCore

final class PeerInfoScreenTBDisclosureItem: PeerInfoScreenItem {
    enum Label {
        case none
        case text(String, Bool)
        case badge(String, UIColor)
        
        
        var text: String {
            switch self {
            case .none:
                return ""
            case let .text(text, _), let .badge(text, _):
                return text
            }
        }
        
        var hasSubBack: Bool {
            switch self {
            case .none, .badge:
                return false
            case let .text(text, hasBack):
                return hasBack && !text.isEmpty
            }
        }
        
        var badgeColor: UIColor? {
            switch self {
            case .none, .text:
                return nil
            case let .badge(_, color):
                return color
            }
        }
    }
    
    let id: AnyHashable
    let label: Label
    let text: String
    let icon: UIImage?
    let action: (() -> Void)?
    
    init(id: AnyHashable, label: Label = .none, text: String, icon: UIImage? = nil, action: (() -> Void)?) {
        self.id = id
        self.label = label
        self.text = text
        self.icon = icon
        self.action = action
    }
    
    func node() -> PeerInfoScreenItemNode {
        return PeerInfoScreenDisclosureItemNode()
    }
}

private final class PeerInfoScreenDisclosureItemNode: PeerInfoScreenItemNode {
    private let selectionNode: PeerInfoScreenSelectableBackgroundNode
    private let maskNode: ASImageNode
    private let iconNode: ASImageNode
    private let labelBadgeNode: ASImageNode
    private let labelNode: ImmediateTextNode
    private let textNode: ImmediateTextNode
    private let arrowNode: ASImageNode
    private let subBackNode: ASDisplayNode
    private let subBackGradientLayer: CAGradientLayer
    private let bottomSeparatorNode: ASDisplayNode
    private let activateArea: AccessibilityAreaNode
    
    private var item: PeerInfoScreenTBDisclosureItem?
    
    override init() {
        var bringToFrontForHighlightImpl: (() -> Void)?
        self.selectionNode = PeerInfoScreenSelectableBackgroundNode(bringToFrontForHighlight: { bringToFrontForHighlightImpl?() })
        
        self.maskNode = ASImageNode()
        self.maskNode.isUserInteractionEnabled = false
        
        self.iconNode = ASImageNode()
        self.iconNode.isLayerBacked = true
        self.iconNode.displaysAsynchronously = false
        
        self.labelBadgeNode = ASImageNode()
        self.labelBadgeNode.displayWithoutProcessing = true
        self.labelBadgeNode.displaysAsynchronously = false
        self.labelBadgeNode.isLayerBacked = true
        
        self.labelNode = ImmediateTextNode()
        self.labelNode.displaysAsynchronously = false
        self.labelNode.isUserInteractionEnabled = false
        
        self.textNode = ImmediateTextNode()
        self.textNode.displaysAsynchronously = false
        self.textNode.isUserInteractionEnabled = false
        
        self.arrowNode = ASImageNode()
        self.arrowNode.isLayerBacked = true
        self.arrowNode.displaysAsynchronously = false
        self.arrowNode.displayWithoutProcessing = true
        self.arrowNode.isUserInteractionEnabled = false
        
        self.subBackNode = ASDisplayNode()
        self.subBackNode.backgroundColor = .gray
        self.subBackNode.layer.cornerRadius = 15
        self.subBackNode.clipsToBounds = true
        self.subBackNode.isUserInteractionEnabled = false
        
        self.subBackGradientLayer = CAGradientLayer()
        self.subBackGradientLayer.startPoint = CGPoint(x: 0, y: 0)
        self.subBackGradientLayer.endPoint = CGPoint(x: 1, y: 0)
        self.subBackGradientLayer.colors = [UIColor(rgb: 0x01B4FF).cgColor, UIColor(rgb: 0x8836DF).cgColor]
        self.subBackGradientLayer.locations = [0.0, 1.0]
    
        self.bottomSeparatorNode = ASDisplayNode()
        self.bottomSeparatorNode.isLayerBacked = true
        
        self.activateArea = AccessibilityAreaNode()
        
        super.init()
        
        bringToFrontForHighlightImpl = { [weak self] in
            self?.bringToFrontForHighlight?()
        }
        
        self.addSubnode(self.bottomSeparatorNode)
        self.addSubnode(self.selectionNode)
        self.addSubnode(self.maskNode)
        self.addSubnode(self.subBackNode)
        self.addSubnode(self.labelNode)
        self.addSubnode(self.textNode)
        self.addSubnode(self.arrowNode)
        self.addSubnode(self.activateArea)
    }
    
    override func didLoad() {
        super.didLoad()
        self.subBackNode.onDidLoad { node in
            node.view.layer.insertSublayer(self.subBackGradientLayer, at: 0)
        }
    }
    
    override func update(width: CGFloat, safeInsets: UIEdgeInsets, presentationData: PresentationData, item: PeerInfoScreenItem, topItem: PeerInfoScreenItem?, bottomItem: PeerInfoScreenItem?, hasCorners: Bool, transition: ContainedViewLayoutTransition) -> CGFloat {
        guard let item = item as? PeerInfoScreenTBDisclosureItem else {
            return 10.0
        }
        
        let previousItem = self.item
        self.item = item
        
        self.selectionNode.pressed = item.action
        
        let sideInset: CGFloat = 16.0 + safeInsets.left
        let leftInset = (item.icon == nil ? sideInset : sideInset + 29.0 + 16.0)
        let rightInset = sideInset + 18.0
        let separatorInset = item.icon == nil ? sideInset : leftInset - 1.0
        let titleFont = Font.regular(presentationData.listsFontSize.itemListBaseFontSize)
        
        self.bottomSeparatorNode.backgroundColor = presentationData.theme.list.itemBlocksSeparatorColor
        
        let textColorValue: UIColor = presentationData.theme.list.itemPrimaryTextColor
        var labelColorValue: UIColor
        var labelFont: UIFont
        if case .badge = item.label {
            labelColorValue = presentationData.theme.list.itemCheckColors.foregroundColor
            labelFont = Font.regular(15.0)
        } else {
            labelColorValue = presentationData.theme.list.itemSecondaryTextColor
            labelFont = titleFont
            if item.label.hasSubBack {
                labelColorValue = .white
                labelFont = UIFont.systemFont(ofSize: 11, weight: .medium)
            }
        }
        
        self.labelNode.attributedText = NSAttributedString(string: item.label.text, font: labelFont, textColor: labelColorValue)
        
        self.textNode.maximumNumberOfLines = 1
        self.textNode.attributedText = NSAttributedString(string: item.text, font: titleFont, textColor: textColorValue)
        
        let textSize = self.textNode.updateLayout(CGSize(width: width - (leftInset + rightInset), height: .greatestFiniteMagnitude))
        let labelSize = self.labelNode.updateLayout(CGSize(width: width - textSize.width - (leftInset + rightInset), height: .greatestFiniteMagnitude))
        
        let textFrame = CGRect(origin: CGPoint(x: leftInset, y: 12.0), size: textSize)
        
        let height = textSize.height + 24.0
        
        if let icon = item.icon {
            if self.iconNode.supernode == nil {
                self.addSubnode(self.iconNode)
            }
            self.iconNode.image = icon
            let iconFrame = CGRect(origin: CGPoint(x: sideInset, y: floorToScreenPixels((height - icon.size.height) / 2.0)), size: icon.size)
            transition.updateFrame(node: self.iconNode, frame: iconFrame)
        } else if self.iconNode.supernode != nil {
            self.iconNode.image = nil
            self.iconNode.removeFromSupernode()
        }
        
        var arrowFrame = CGRect.zero
        if let arrowImage = PresentationResourcesItemList.disclosureArrowImage(presentationData.theme) {
            if item.label.hasSubBack {
                self.arrowNode.image = generateTintedImage(image: arrowImage, color: .white)
            }else{
                self.arrowNode.image = arrowImage
            }
            arrowFrame = CGRect(origin: CGPoint(x: width - 7.0 - arrowImage.size.width - safeInsets.right, y: floorToScreenPixels((height - arrowImage.size.height) / 2.0)), size: arrowImage.size)
            transition.updateFrame(node: self.arrowNode, frame: arrowFrame)
        }
        
        let badgeDiameter: CGFloat = 20.0
        if case let .badge(text, badgeColor) = item.label, !text.isEmpty {
            if previousItem?.label.badgeColor != badgeColor {
                self.labelBadgeNode.image = generateStretchableFilledCircleImage(diameter: badgeDiameter, color: badgeColor)
            }
            if self.labelBadgeNode.supernode == nil {
                self.insertSubnode(self.labelBadgeNode, belowSubnode: self.labelNode)
            }
        } else {
            self.labelBadgeNode.removeFromSupernode()
        }
        
        let badgeWidth = max(badgeDiameter, labelSize.width + 10.0)
        let labelFrame: CGRect
        if case .badge = item.label {
            labelFrame = CGRect(origin: CGPoint(x: width - rightInset - badgeWidth + (badgeWidth - labelSize.width) / 2.0, y: floor((height - labelSize.height) / 2.0)), size: labelSize)
        } else {
            labelFrame = CGRect(origin: CGPoint(x: width - rightInset - labelSize.width, y: floor((height - labelSize.height) / 2.0)), size: labelSize)
        }
        
        let labelBadgeNodeFrame = CGRect(origin: CGPoint(x: width - rightInset - badgeWidth, y: labelFrame.minY - 1.0), size: CGSize(width: badgeWidth, height: badgeDiameter))
        
        
        let subBackFrame:CGRect
        if item.label.hasSubBack {
            let subBackWidth = ((arrowFrame.maxX + 3) - labelFrame.center.x) * 2.0
            let subBackHeight = 30.0
            subBackFrame = CGRect(x: labelFrame.center.x - subBackWidth / 2.0 , y: (height - subBackHeight) / 2.0, width: subBackWidth, height: subBackHeight)
        }else{
            subBackFrame = CGRect.zero
        }
        transition.updateFrame(node: self.subBackNode, frame: subBackFrame)
        self.subBackGradientLayer.frame = CGRect(origin: .zero, size: subBackFrame.size)
        
        
        self.activateArea.accessibilityLabel = item.text
        self.activateArea.accessibilityValue = item.label.text
        
        transition.updateFrame(node: self.labelBadgeNode, frame: labelBadgeNodeFrame)
        if self.labelNode.bounds.size != labelFrame.size {
            self.labelNode.frame = labelFrame
        } else {
            transition.updateFrame(node: self.labelNode, frame: labelFrame)
        }
        transition.updateFrame(node: self.textNode, frame: textFrame)
        
        let hasCorners = hasCorners && (topItem == nil || bottomItem == nil)
        let hasTopCorners = hasCorners && topItem == nil
        let hasBottomCorners = hasCorners && bottomItem == nil
        
        self.maskNode.image = hasCorners ? PresentationResourcesItemList.cornersImage(presentationData.theme, top: hasTopCorners, bottom: hasBottomCorners) : nil
        self.maskNode.frame = CGRect(origin: CGPoint(x: safeInsets.left, y: 0.0), size: CGSize(width: width - safeInsets.left - safeInsets.right, height: height))
        self.bottomSeparatorNode.isHidden = hasBottomCorners
        
        let highlightNodeOffset: CGFloat = topItem == nil ? 0.0 : UIScreenPixel
        self.selectionNode.update(size: CGSize(width: width, height: height + highlightNodeOffset), theme: presentationData.theme, transition: transition)
        transition.updateFrame(node: self.selectionNode, frame: CGRect(origin: CGPoint(x: 0.0, y: -highlightNodeOffset), size: CGSize(width: width, height: height + highlightNodeOffset)))
        
        transition.updateFrame(node: self.bottomSeparatorNode, frame: CGRect(origin: CGPoint(x: separatorInset, y: height - UIScreenPixel), size: CGSize(width: width - separatorInset, height: UIScreenPixel)))
        transition.updateAlpha(node: self.bottomSeparatorNode, alpha: bottomItem == nil ? 0.0 : 1.0)
        
        self.activateArea.frame = CGRect(origin: CGPoint(x: safeInsets.left, y: 0.0), size: CGSize(width: width - safeInsets.left - safeInsets.right, height: height))
        
        return height
    }
}
