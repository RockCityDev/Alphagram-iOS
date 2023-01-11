






import UIKit
import SnapKit
import TBWeb3Core
import Display
import AccountContext
import AsyncDisplayKit
import TelegramPresentationData

private protocol TitleItem {
    func getTitle() -> String
    func getArrowName() -> String?
}

private extension TitleItem {
    func getArrowName() -> String? {
        return "TBWallet/LineArrow"
    }
}

private class TitleNode: ASDisplayNode {
    
    private let titleFont: CGFloat
    private let arrowWidth: CGFloat
    private let margin: CGFloat
    private let space: CGFloat
    
    private let nameNode: ASTextNode
    private let arrowNode: ASImageNode
    
    var titleClickEvent: (()->())?
    
    init(titleFont: CGFloat = 15, arrowWidth: CGFloat = 16, margin: CGFloat = 0, space: CGFloat = 5) {
        self.titleFont = titleFont
        self.arrowWidth = arrowWidth
        self.margin = margin
        self.space = space
        
        self.nameNode = ASTextNode()
        self.arrowNode = ASImageNode()
        
        super.init()
    }
    
    override func didLoad() {
        super.didLoad()
        self.addSubnode(self.nameNode)
        self.addSubnode(self.arrowNode)
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapClickEvent(tap:)))
        self.view.addGestureRecognizer(tap)
    }
    
    func updateNetwork(_ network: TitleItem) -> CGFloat {
        self.nameNode.attributedText = NSAttributedString(string: network.getTitle(), font: Font.medium(self.titleFont), textColor: UIColor(hexString: "#FF828282")!, paragraphAlignment: .left)
        let size = self.nameNode.updateLayout(CGSize(width: 200.0, height: .greatestFiniteMagnitude))
        if let arrow = network.getArrowName() {
            self.arrowNode.image = UIImage(named: arrow)
        }
        return self.margin + size.width + self.space + self.arrowWidth + self.margin
    }
    
    func update(size: CGSize, transition: ContainedViewLayoutTransition) {
        self.nameNode.frame = CGRect(x: self.margin, y: (size.height - 20) / 2.0 + 2, width: size.width - 2 * self.margin - self.space - self.arrowWidth, height: 20)
        self.arrowNode.frame = CGRect(x: size.width - self.margin - self.arrowWidth, y: (size.height - self.arrowWidth) / 2.0, width: self.arrowWidth, height: self.arrowWidth)
    }
    
    @objc func tapClickEvent(tap: UITapGestureRecognizer) {
        self.titleClickEvent?()
    }
}

public class TBCurrencyCommunityRecommendConnectWallletCell: UICollectionViewCell {
    
    private let titleLabel: TitleNode
    private let addButtonNode: ASButtonNode
    
    var connectClickEvent: (()->())?
    var addNewGroupEvent: (()->())?
    
    struct Title: TitleItem {
        func getTitle() -> String {
            return "Wallet Disconnect"
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override init(frame: CGRect) {
        self.titleLabel = TitleNode()
        self.addButtonNode = ASButtonNode()
        super.init(frame: frame)
        self.contentView.backgroundColor = .white
        self.contentView.addSubnode(self.titleLabel)
        self.addButtonNode.setImage(UIImage(named: "TBWallet/NewGroup"), for: .normal)
        self.addButtonNode.frame = CGRect(x: UIScreen.main.bounds.width - 48, y: 6, width: 44, height: 44)
        self.contentView.addSubnode(self.addButtonNode)
        self.addButtonNode.addTarget(self, action: #selector(addButtonClick(button:)), forControlEvents: .touchUpInside)
        self.titleLabel.titleClickEvent = { [weak self] in
            self?.connectClickEvent?()
        }
    }
    
    func reloadCell() {
        let title = Title()
        let width = self.titleLabel.updateNetwork(title)
        self.titleLabel.frame = CGRect(x: 12, y: 14, width: width, height: 28)
        self.titleLabel.update(size: CGSize(width: width, height: 28), transition: .immediate)
    }
    
    @objc func addButtonClick(button: UIButton) {
        self.addNewGroupEvent?()
    }
}

