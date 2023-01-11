import AsyncDisplayKit
import Display
import TelegramPresentationData
import QuartzCore

final class TBPeerInfoScreenButtonItem: PeerInfoScreenItem {
    enum Label {
        case text(String, UIFont, UIColor, UIColor)
        
        var text: String {
            switch self {
            case let .text(text, _, _,_):
                return text
            }
        }
        
        var textFont: UIFont {
            switch self {
            case let .text(_, font,_, _):
                return font
            }
        }
        
        var textColor: UIColor {
            switch self {
            case let .text(_, _,color, _):
                return color
            }
        }
        
        var bgColor: UIColor {
            switch self {
            case let .text(_, _, _, color):
                return color
            }
        }
    }
    let id: AnyHashable
    let label: Label
    let action: (() -> Void)?
    
    init(id: AnyHashable, label: Label, action: (() -> Void)?) {
        self.id = id
        self.label = label
        self.action = action
    }
    
    func node() -> PeerInfoScreenItemNode {
        return TBPeerInfoScreenButtonItemNode()
    }
}

private final class TBPeerInfoScreenButtonItemNode: PeerInfoScreenItemNode {
    private let selectionNode: PeerInfoScreenSelectableBackgroundNode
    private let maskNode: ASImageNode
    private let bgNode: ASDisplayNode
    private let textNode: ImmediateTextNode
    private let bottomSeparatorNode: ASDisplayNode
    private let activateArea: AccessibilityAreaNode
    
    private var item: TBPeerInfoScreenButtonItem?
    
    override init() {
        var bringToFrontForHighlightImpl: (() -> Void)?
        self.selectionNode = PeerInfoScreenSelectableBackgroundNode(bringToFrontForHighlight: { bringToFrontForHighlightImpl?() })
        
        self.maskNode = ASImageNode()
        self.maskNode.isUserInteractionEnabled = false
        
        self.bgNode = ASDisplayNode()
        self.bgNode.backgroundColor = .red
        self.bgNode.isUserInteractionEnabled = false
        
        self.textNode = ImmediateTextNode()
        self.textNode.displaysAsynchronously = false
        self.textNode.isUserInteractionEnabled = false
    
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
        self.addSubnode(self.bgNode)
        self.addSubnode(self.textNode)
        self.addSubnode(self.activateArea)
    }
    
    override func didLoad() {
        super.didLoad()
    }
    
    override func update(width: CGFloat, safeInsets: UIEdgeInsets, presentationData: PresentationData, item: PeerInfoScreenItem, topItem: PeerInfoScreenItem?, bottomItem: PeerInfoScreenItem?, hasCorners: Bool, transition: ContainedViewLayoutTransition) -> CGFloat {
        guard let item = item as? TBPeerInfoScreenButtonItem else {
            return 10.0
        }
        
        let previousItem = self.item
        self.item = item
        
        self.selectionNode.pressed = item.action
        
        let sideInset: CGFloat = 0 + safeInsets.left
        let leftInset = sideInset
        let rightInset = sideInset + safeInsets.right
        let separatorInset = sideInset
        
        self.bottomSeparatorNode.backgroundColor = presentationData.theme.list.itemBlocksSeparatorColor
        
        self.bgNode.backgroundColor = item.label.bgColor
        self.textNode.attributedText = NSAttributedString(string: item.label.text, font: item.label.textFont, textColor: item.label.textColor)

        let textSize = self.textNode.updateLayout(CGSize(width: width - (leftInset + rightInset), height: .greatestFiniteMagnitude))
        let textFrame = CGRect(origin: CGPoint(x: (width - (leftInset + rightInset) - textSize.width)/2.0, y: 12.0), size: textSize)
        
        let height = textSize.height + 24.0
        
        let bgSize = CGSize(width: width - (leftInset + rightInset), height: height)
        let bgFrame = CGRect(origin: CGPoint(x: leftInset, y: 0), size: bgSize)

        self.activateArea.accessibilityLabel = item.label.text
        self.activateArea.accessibilityValue = ""
        self.bgNode.backgroundColor = item.label.bgColor
        self.bgNode.cornerRadius = 11
        
        transition.updateFrame(node: self.textNode, frame: textFrame)
        transition.updateFrame(node: self.bgNode, frame: bgFrame)
        
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
