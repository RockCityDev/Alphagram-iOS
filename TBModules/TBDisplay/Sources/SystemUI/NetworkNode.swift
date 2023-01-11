import Foundation
import UIKit
import Display
import AccountContext
import AsyncDisplayKit
import TelegramPresentationData


public struct UnClearNetworkItem: NetworkItem {
    public func getIconName() -> String {
        return ""
    }
    
    public func getTitle() -> String {
        return "    "
    }
    
    public func getArrowName() -> String? {
        return nil
    }
    
    public init() {}
}

public protocol NetworkItem {
    func getIconName() -> String
    func getTitle() -> String
    func getArrowName() -> String?
}

public extension NetworkItem {
    func getArrowName() -> String? {
        return "TBWallet/arrow"
    }
}

public struct NetworkNodeConfig {
    let iconWidth: CGFloat
    let titleFont: UIFont
    let titleColor: UIColor
    let arrowWidth: CGFloat
    let margin: CGFloat
    let space: CGFloat
    
    public init(iconWidth: CGFloat = 24,
                titleFont: UIFont = Font.medium(15),
                titleColor: UIColor = UIColor(hexString: "#FF56565C")!,
                arrowWidth: CGFloat = 16,
                margin: CGFloat = 19,
                space: CGFloat = 5) {
        self.iconWidth = iconWidth
        self.titleFont = titleFont
        self.titleColor = titleColor
        self.arrowWidth = arrowWidth
        self.margin = margin
        self.space = space
    }
}



public final class NetworkNode: ASDisplayNode {

    private let context: AccountContext
    private var presentationData: PresentationData
    
    private let config: NetworkNodeConfig
    
    private let iconNode: UIImageView
    private let nameNode: ASTextNode
    private let arrowNode: ASImageNode
    
    public var titleClickEvent: (()->())?
    
    public init(context: AccountContext, presentationData: PresentationData, config: NetworkNodeConfig = NetworkNodeConfig()) {
        self.context = context
        self.presentationData = presentationData
        self.config = config
        
        self.iconNode = UIImageView()
        self.nameNode = ASTextNode()
        self.arrowNode = ASImageNode()
        
        super.init()
    }
    
    public override func didLoad() {
        super.didLoad()
        self.iconNode.layer.cornerRadius = self.config.iconWidth / 2
        self.iconNode.layer.masksToBounds = true
        self.iconNode.contentMode = .scaleAspectFit
        self.view.addSubview(self.iconNode)
        self.addSubnode(self.nameNode)
        self.addSubnode(self.arrowNode)
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapClickEvent(tap:)))
        self.view.addGestureRecognizer(tap)
    }
    
    public func updateNetwork(_ network: NetworkItem) -> CGFloat {
        if let url = URL(string: network.getIconName()) {
            self.iconNode.sd_setImage(with: url)
        } else {
            self.iconNode.image = nil
        }
        self.nameNode.attributedText = NSAttributedString(string: network.getTitle(), font: self.config.titleFont, textColor: self.config.titleColor, paragraphAlignment: .left)
        let size = self.nameNode.updateLayout(CGSize(width: 200.0, height: .greatestFiniteMagnitude))
        if let arrow = network.getArrowName() {
            self.arrowNode.image = UIImage(named: arrow)
        }
        return self.config.margin + self.config.iconWidth + self.config.space + size.width + self.config.space + self.config.arrowWidth + self.config.margin
    }
    
    public func update(size: CGSize, transition: ContainedViewLayoutTransition) {
        self.iconNode.frame = CGRect(x: self.config.margin, y: (size.height - self.config.iconWidth) / 2.0, width: self.config.iconWidth, height: self.config.iconWidth)
        let nameSize = self.nameNode.updateLayout(CGSize(width: 200.0, height: .greatestFiniteMagnitude))
        self.nameNode.frame = CGRect(x: self.config.margin + self.config.iconWidth + self.config.space, y: (size.height - nameSize.height) / 2.0, width: size.width - 2 * (self.config.margin + self.config.space) - self.config.iconWidth - self.config.arrowWidth, height: nameSize.height)
        self.arrowNode.frame = CGRect(x: size.width - self.config.margin - self.config.arrowWidth, y: (size.height - self.config.arrowWidth) / 2.0, width: self.config.arrowWidth, height: self.config.arrowWidth)
    }
    
    @objc func tapClickEvent(tap: UITapGestureRecognizer) {
        self.titleClickEvent?()
    }
}
