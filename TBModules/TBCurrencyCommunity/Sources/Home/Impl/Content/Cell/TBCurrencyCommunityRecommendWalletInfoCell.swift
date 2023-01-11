






import UIKit
import SnapKit
import TBWeb3Core
import TBWalletCore
import Display
import AccountContext
import AsyncDisplayKit
import TelegramPresentationData
import ProgressHUD


private protocol TitleItem {
    func getIconName() -> String
    func getTitle() -> String
    func getArrowName() -> String?
}

private extension TitleItem {
    
    func getIconName() -> String {
        return "TBWallet/MetaMask"
    }
    
    func getArrowName() -> String? {
        return "TBWallet/line_copy"
    }
}

private class TitleNode: ASDisplayNode {
    
    private let iconWidth: CGFloat
    private let titleFont: CGFloat
    private let arrowWidth: CGFloat
    private let margin: CGFloat
    private let space: CGFloat
    
    private let iconNode: UIImageView
    private let nameNode: ASTextNode
    private let arrowNode: ASImageNode
    
    var titleClickEvent: (()->())?
    
    init(iconWidth: CGFloat = 24, titleFont: CGFloat = 15, arrowWidth: CGFloat = 16, margin: CGFloat = 7, space: CGFloat = 5) {
        self.iconWidth = iconWidth
        self.titleFont = titleFont
        self.arrowWidth = arrowWidth
        self.margin = margin
        self.space = space
        
        self.iconNode = UIImageView()
        self.nameNode = ASTextNode()
        self.arrowNode = ASImageNode()
        
        super.init()
    }
    
    override func didLoad() {
        super.didLoad()
        self.iconNode.layer.cornerRadius = self.iconWidth / 2
        self.iconNode.layer.masksToBounds = true
        self.iconNode.contentMode = .scaleAspectFit
        self.view.addSubview(self.iconNode)
        self.addSubnode(self.nameNode)
        self.addSubnode(self.arrowNode)
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapClickEvent(tap:)))
        self.view.addGestureRecognizer(tap)
    }
    
    func updateNetwork(_ network: TitleItem) -> CGFloat {
        self.iconNode.image = UIImage(named: network.getIconName())
        self.nameNode.attributedText = NSAttributedString(string: network.getTitle(), font: Font.medium(self.titleFont), textColor: UIColor(hexString: "#FF56565C")!, paragraphAlignment: .left)
        let size = self.nameNode.updateLayout(CGSize(width: 200.0, height: .greatestFiniteMagnitude))
        if let arrow = network.getArrowName() {
            self.arrowNode.image = UIImage(named: arrow)
        }
        return self.margin + self.iconWidth + self.space + size.width + self.space + self.arrowWidth + self.margin
    }
    
    func update(size: CGSize, transition: ContainedViewLayoutTransition) {
        self.iconNode.frame = CGRect(x: self.margin, y: (size.height - self.iconWidth) / 2.0, width: self.iconWidth, height: self.iconWidth)
        self.nameNode.frame = CGRect(x: self.margin + self.iconWidth + self.space, y: (size.height - 20) / 2.0 + 2, width: size.width - 2 * (self.margin + self.space) - self.iconWidth - self.arrowWidth, height: 20)
        self.arrowNode.frame = CGRect(x: size.width - self.margin - self.arrowWidth, y: (size.height - self.arrowWidth) / 2.0, width: self.arrowWidth, height: self.arrowWidth)
    }
    
    @objc func tapClickEvent(tap: UITapGestureRecognizer) {
        self.titleClickEvent?()
    }
}

public class TBCurrencyCommunityRecommendWalletInfoCell:UICollectionViewCell {
    
    private struct Network: TitleItem {
        
        let title: String
        
        func getTitle() -> String {
            return self.title
        }
        
    }
    
    private let titleLabel: TitleNode
    private let addButtonNode: ASButtonNode
    var addNewGroupEvent: (()->())?
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override init(frame: CGRect) {
        self.titleLabel = TitleNode()
        self.addButtonNode = ASButtonNode()
        super.init(frame: frame)
        self.contentView.backgroundColor = .white
        
        self.titleLabel.backgroundColor = UIColor(hexString: "#0D4B5BFF")
        self.titleLabel.cornerRadius = 14
        self.contentView.addSubnode(self.titleLabel)
        
        self.addButtonNode.setImage(UIImage(named: "TBWallet/NewGroup"), for: .normal)
        self.addButtonNode.frame = CGRect(x: UIScreen.main.bounds.width - 48, y: 6, width: 44, height: 44)
        self.contentView.addSubnode(self.addButtonNode)
        self.addButtonNode.addTarget(self, action: #selector(addButtonClick(button:)), forControlEvents: .touchUpInside)
    }
    
    func reloadCell(walletConnect: TBWalletConnect) {
        let address = walletConnect.getAccountId()
        let title = address.isEmpty ? "********" : address
        let network = Network(title: title.simpleAddress())
        let width = self.titleLabel.updateNetwork(network)
        self.titleLabel.frame = CGRect(x: 12, y: 14, width: width, height: 28)
        self.titleLabel.update(size: CGSize(width: width, height: 28), transition: .immediate)
        self.titleLabel.titleClickEvent = {
            if !address.isEmpty {
                UIPasteboard.general.string = address
                ProgressHUD.showSucceed("")
            }
        }
    }
    
    @objc func addButtonClick(button: UIButton) {
        self.addNewGroupEvent?()
    }
}

