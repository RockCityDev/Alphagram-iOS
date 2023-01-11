import UIKit
import UIKit
import AsyncDisplayKit
import Display
import TelegramPresentationData

struct TBToolItem<T> {
    let backgrounndColor: UIColor?
    let iconName: String
    let title: String
    let url: String?
    let type: T

    init(type: T,title: String, iconName: String , color: UIColor?, url: String? = nil) {
        self.type = type
        self.title = title
        self.iconName = iconName
        self.backgrounndColor = color
        self.url = url
    }
}

struct TBItemNodeTheme {

    private let _itemSize: CGSize
    public var itemSize: CGSize {
        get {
            return self._itemSize
        }
    }

    private let _bgSize: CGSize
    public var bgSize: CGSize {
        get {
            return self._bgSize
        }
    }
    
    private let _imageSize: CGSize
    public var imageSize: CGSize {
        get {
            return self._imageSize
        }
    }

    private let _iconFont: CGFloat
    public var iconFont: CGFloat {
        get {
            return self._iconFont
        }
    }

    init(itemsize: CGSize = CGSize(width: 60, height: 60),
         bgSize: CGSize = CGSize(width: 52, height: 52),
         imageSize: CGSize = CGSize(width: 20, height: 20),
         iconFont: CGFloat = 13.0 ) {
        self._itemSize = itemsize
        self._bgSize = bgSize
        self._imageSize = imageSize
        self._iconFont = iconFont
    }
}


final class AGToolItemNode<T>: ASDisplayNode {

    private let backgroundNode: ASDisplayNode
    private let officialNode: ASImageNode
    private let imageNode: ASImageNode
    private let titleNode: ASTextNode
    private let badgeContainerNode: ASDisplayNode
    private let badgeTextNode: ImmediateTextNode
    private let badgeBackgroundActiveNode: ASImageNode
    private let badgeBackgroundInactiveNode: ASImageNode
    private let itemTheme: TBItemNodeTheme
    private let isOfficial: Bool
    private let isCycle: Bool
    private var toolItem: TBToolItem<T>?
    var clickEvent: ((T) -> Void)?

    init(itemTheme: TBItemNodeTheme = TBItemNodeTheme(), isOfficial: Bool = false , isCycle: Bool = false) {
        self.itemTheme = itemTheme
        self.isOfficial = isOfficial
        self.isCycle = isCycle

        self.backgroundNode = ASDisplayNode()
        self.officialNode = ASImageNode()
        self.imageNode = ASImageNode()
        if self.isCycle {
            self.imageNode.cornerRadius = itemTheme.imageSize.height / 2.0
            self.imageNode.clipsToBounds = true
        }
        self.titleNode = ASTextNode()
        self.titleNode.maximumNumberOfLines = 2
        self.badgeContainerNode = ASDisplayNode()

        self.badgeTextNode = ImmediateTextNode()
        self.badgeTextNode.displaysAsynchronously = false

        self.badgeBackgroundActiveNode = ASImageNode()
        self.badgeBackgroundActiveNode.displaysAsynchronously = false
        self.badgeBackgroundActiveNode.displayWithoutProcessing = true

        self.badgeBackgroundInactiveNode = ASImageNode()
        self.badgeBackgroundInactiveNode.displaysAsynchronously = false
        self.badgeBackgroundInactiveNode.displayWithoutProcessing = true

        super.init()
    }

    override public func didLoad() {
        super.didLoad()
        self.backgroundNode.cornerRadius = self.itemTheme.bgSize.height / 2.0
        self.backgroundNode.frame = CGRect(x: (self.itemTheme.itemSize.width - self.itemTheme.bgSize.width) / 2.0, y: 0, width: self.itemTheme.bgSize.width, height: self.itemTheme.bgSize.height)
        self.addSubnode(backgroundNode)

        let width = min(self.itemTheme.bgSize.width, self.itemTheme.bgSize.height)
        self.officialNode.frame = CGRect(x: (self.itemTheme.bgSize.width - width) / 2.0, y: (self.itemTheme.bgSize.height - width) / 2.0, width: width, height: width)
        self.backgroundNode.addSubnode(self.officialNode)
        self.officialNode.image = UIImage(named: "Tools/btn_official_group_good_tools_chinese")
        self.officialNode.isHidden = !self.isOfficial

        self.imageNode.frame = CGRect(x: (self.itemTheme.bgSize.width - self.itemTheme.imageSize.width) / 2.0, y: (self.itemTheme.bgSize.height - self.itemTheme.imageSize.height) / 2.0, width: self.itemTheme.imageSize.width, height: self.itemTheme.imageSize.height)
        self.backgroundNode.addSubnode(self.imageNode)
        self.titleNode.frame = CGRect(x: 0, y: self.itemTheme.bgSize.height + 8, width: self.itemTheme.itemSize.width, height: self.itemTheme.iconFont * 3.0)
        self.addSubnode(self.titleNode)
        self.badgeContainerNode.addSubnode(self.badgeBackgroundInactiveNode)
        self.badgeContainerNode.addSubnode(self.badgeBackgroundActiveNode)
        self.badgeContainerNode.addSubnode(self.badgeTextNode)
        self.addSubnode(self.badgeContainerNode)

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapClick(tap:)))
        self.view.addGestureRecognizer(tap)
    }

    @objc func tapClick(tap: UITapGestureRecognizer) {
        if let item = self.toolItem, let f = self.clickEvent {
            f(item.type)
        }
    }

    func updateNodeBy(_ item: TBToolItem<T>) {
        self.toolItem = item
        self.backgroundNode.backgroundColor = item.backgrounndColor
        self.imageNode.image = UIImage(named: item.iconName)
        self.titleNode.attributedText = NSAttributedString(string: item.title, font: Font.medium(self.itemTheme.iconFont), textColor: UIColor(hexString: "#56565C")!, paragraphAlignment: .center)
    }

    func updateBadge(_ count: Int, unreadHasUnmuted: Bool = false, selectionFraction: CGFloat = 1.0) {
        let transition = ContainedViewLayoutTransition.animated(duration: 0.23, curve: .easeInOut)
        self.badgeContainerNode.alpha = count > 0 ? 1.0 : 0.0
        self.badgeBackgroundActiveNode.image = generateStretchableFilledCircleImage(diameter: 18.0, color: UIColor(rgb: 0xFF5F5F))
        self.badgeBackgroundInactiveNode.image = generateStretchableFilledCircleImage(diameter: 18.0, color: UIColor(rgb: 0xFF5F5F))
        if count > 0 {
            let text = count > 999 ? "999+" : "\(count)"
            self.badgeTextNode.attributedText = NSAttributedString(string: text, font: Font.regular(14.0), textColor: UIColor.white)
            let badgeSelectionFraction: CGFloat = unreadHasUnmuted ? 1.0 : selectionFraction

            let badgeSelectionAlpha: CGFloat = badgeSelectionFraction
            transition.updateAlpha(node: self.badgeBackgroundActiveNode, alpha: badgeSelectionAlpha * badgeSelectionAlpha)
            self.badgeBackgroundInactiveNode.alpha = 1.0
            let badgeSize = self.badgeTextNode.updateLayout(CGSize(width: 200.0, height: .greatestFiniteMagnitude))
            let badgeInset: CGFloat = 4.0
            let badgeWidth = max(18.0, badgeSize.width + badgeInset * 2.0)
            let badgeBackgroundFrame = CGRect(origin: CGPoint(x: self.backgroundNode.frame.maxX - badgeWidth / 2.0, y: -2), size: CGSize(width: badgeWidth, height: 18.0))
            self.badgeContainerNode.frame = badgeBackgroundFrame
            self.badgeBackgroundActiveNode.frame = CGRect(origin: CGPoint(), size: badgeBackgroundFrame.size)
            self.badgeBackgroundInactiveNode.frame = CGRect(origin: CGPoint(), size: badgeBackgroundFrame.size)
            self.badgeTextNode.frame = CGRect(origin: CGPoint(x: floorToScreenPixels((badgeBackgroundFrame.width - badgeSize.width) / 2.0), y: floor((badgeBackgroundFrame.height - badgeSize.height) / 2.0)), size: badgeSize)
        }
    }
}
