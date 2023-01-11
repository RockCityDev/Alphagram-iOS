
import UIKit
import Display
import TBWalletCore
import AccountContext
import AsyncDisplayKit
import TelegramPresentationData
import TBWeb3Core
import SwiftSignalKit
import TBLanguage

class AssetOrderStatusNode: ASDisplayNode {
    private let context: AccountContext
    private let titleNode: ASTextNode
    private let amountNode: ASTextNode
    private let priceNode: ASTextNode
    
    init(context: AccountContext) {
        self.context = context
        self.titleNode = ASTextNode()
        self.amountNode = ASTextNode()
        self.priceNode = ASTextNode()
        super.init()
    }
    
    override func didLoad() {
        super.didLoad()
        self.addSubnode(self.titleNode)
        self.addSubnode(self.amountNode)
        self.addSubnode(self.priceNode)
    }
    
    func update(size: CGSize = CGSize(width: UIScreen.main.bounds.width - 40, height: 43), transition: ContainedViewLayoutTransition) {
        self.titleNode.attributedText = NSAttributedString(string:TBLanguage.sharedInstance.localizable(TBLankey.transfer_detatils_dialog_status), font: Font.regular(14), textColor: UIColor(hexString: "#FF56565C")!)
        transition.updateFrame(node: self.titleNode, frame: CGRect(x: 0, y: 0, width: 70, height: 20))
        
        let title = TBLanguage.sharedInstance.localizable(TBLankey.transfer_detatils_dialog_status1)
        let color = UIColor(hexString: "#FF21C131")!
        self.amountNode.attributedText = NSAttributedString(string: title, font: Font.bold(16), textColor: color)
        let amountSize = self.amountNode.updateLayout(CGSize(width: 90, height: 20))
        transition.updateFrame(node: self.amountNode, frame: CGRect(x: 0, y: 29, width: amountSize.width, height: 20))
        
        self.priceNode.attributedText = NSAttributedString(string: "", font: Font.regular(14), textColor: UIColor(hexString: "#FF56565C")!, paragraphAlignment: .right)
        let priceSize = self.priceNode.updateLayout(CGSize(width: size.width - 75, height: 20))
        transition.updateFrame(node: self.priceNode, frame: CGRect(x: size.width - priceSize.width, y: 23, width: priceSize.width, height: 20))
    }
}

class TAssetOrderAddressNode: ASDisplayNode {
    private let context: AccountContext
    private let redPack: TBRedPackModel
    
    private let fromNode: ASTextNode
    private let fromAddressNode: ASTextNode
    
    private let lineNode: ASDisplayNode
    
    private let toNode: ASTextNode
    private let toAddressNode: ASTextNode
    
    init(context: AccountContext, redPack: TBRedPackModel) {
        self.context = context
        self.redPack = redPack
        
        self.fromNode = ASTextNode()
        self.fromAddressNode = ASTextNode()
        
        self.lineNode = ASDisplayNode()
        
        self.toNode = ASTextNode()
        self.toAddressNode = ASTextNode()
        super.init()
    }
    
    override func didLoad() {
        super.didLoad()
        self.addSubnode(self.fromNode)
        self.addSubnode(self.fromAddressNode)
        
        self.lineNode.backgroundColor = UIColor.white
        self.addSubnode(self.lineNode)
        
        self.addSubnode(self.toNode)
        self.addSubnode(self.toAddressNode)
    }
    
    func update(size: CGSize, transition: ContainedViewLayoutTransition) {
        transition.updateFrame(node: self.fromNode, frame: CGRect(x: 16, y: 12, width: 50, height: 23))
        self.fromNode.attributedText = NSAttributedString(string: "from", font: Font.regular(15), textColor: UIColor(hexString: "#FFABABAF")!)
        self.fromAddressNode.attributedText = NSAttributedString(string: self.redPack.fromAddress!.simpleAddress(), font: Font.regular(15), textColor: UIColor(hexString: "#FF56565C")!, paragraphAlignment: .right)
        let fromAddressSize = self.fromAddressNode.updateLayout(CGSize(width: size.width - 71 - 12, height: 22))
        transition.updateFrame(node: self.fromAddressNode, frame: CGRect(x: size.width - fromAddressSize.width - 12, y: 12, width: fromAddressSize.width, height: 22))
        
        transition.updateFrame(node: self.lineNode, frame: CGRect(x: 0, y: 46, width: size.width, height: 1))
        
        self.toNode.attributedText = NSAttributedString(string: "to", font: Font.regular(15), textColor: UIColor(hexString: "FFABABAF")!)
        transition.updateFrame(node: self.toNode, frame: CGRect(x: 16, y: 58, width: 50, height: 23))
        self.toAddressNode.attributedText = NSAttributedString(string: self.redPack.toAddress!.simpleAddress(), font: Font.regular(15), textColor: UIColor(hexString: "#FF56565C")!, paragraphAlignment: .right)
        let toAddressSize = self.toAddressNode.updateLayout(CGSize(width: size.width - 71 - 12, height: 22))
        transition.updateFrame(node: self.toAddressNode, frame: CGRect(x: size.width - toAddressSize.width - 12, y: 58, width: toAddressSize.width, height: 22))
    }
}

class TAssetTotalNode: ASDisplayNode {
    private let context: AccountContext
    private let redPack: TBRedPackModel
    
    private let titleNode: ASTextNode
    private let amountNode: ASTextNode
    private let priceNode: ASTextNode
    
    init(context: AccountContext, redPack: TBRedPackModel) {
        self.context = context
        self.redPack = redPack
        
        self.titleNode = ASTextNode()
        self.amountNode = ASTextNode()
        self.priceNode = ASTextNode()
        super.init()
    }
    
    override func didLoad() {
        super.didLoad()
        self.addSubnode(self.titleNode)
        self.addSubnode(self.amountNode)
        self.addSubnode(self.priceNode)
        self.titleNode.attributedText = NSAttributedString(string: TBLanguage.sharedInstance.localizable(TBLankey.transfer_detatils_dialog_totalnum), font: Font.regular(14), textColor: UIColor(hexString: "#FF56565C")!)
    }
    
    func update(size: CGSize = CGSize(width: UIScreen.main.bounds.width - 40, height: 43), transition: ContainedViewLayoutTransition) {
        transition.updateFrame(node: self.titleNode, frame: CGRect(x: 0, y: 0, width: 200, height: 20))
        
        self.amountNode.attributedText = NSAttributedString(string: "\(self.redPack.count!) \(self.redPack.symbol!)", font: Font.regular(15), textColor: UIColor(hexString: "#FF828283")!, paragraphAlignment: .right)
        let amountSize = self.amountNode.updateLayout(CGSize(width: size.width - 75, height: 20))
        transition.updateFrame(node: self.amountNode, frame: CGRect(x: size.width - amountSize.width, y: 0, width: amountSize.width, height: 20))
        
        self.priceNode.attributedText = NSAttributedString(string: "$\(self.redPack.price!)", font: Font.regular(15), textColor: UIColor(hexString: "#FF828283")!, paragraphAlignment: .right)
        let priceSize = self.priceNode.updateLayout(CGSize(width: size.width - 75, height: 20))
        transition.updateFrame(node: self.priceNode, frame: CGRect(x: size.width - priceSize.width, y: 23, width: priceSize.width, height: 20))
    }
}

class TAssetSBUINode: ASDisplayNode {
    private let context: AccountContext
    private let redPack: TBRedPackModel
    private let titleNode: ASTextNode
    private let priceNode: ASTextNode
    
    init(context: AccountContext, redPack: TBRedPackModel) {
        self.context = context
        self.redPack = redPack
        self.titleNode = ASTextNode()
        self.priceNode = ASTextNode()
        super.init()
    }
    
    override func didLoad() {
        super.didLoad()
        self.addSubnode(self.titleNode)
        self.addSubnode(self.priceNode)
        self.titleNode.attributedText = NSAttributedString(string: TBLanguage.sharedInstance.localizable(TBLankey.transfer_detatils_dialog_num), font: Font.regular(14), textColor: UIColor(hexString: "#FF56565C")!)
    }
    
    func update(size: CGSize = CGSize(width: UIScreen.main.bounds.width - 40, height: 43), transition: ContainedViewLayoutTransition) {
        transition.updateFrame(node: self.titleNode, frame: CGRect(x: 0, y: 13, width: 70, height: 20))
        
        self.priceNode.attributedText = NSAttributedString(string: "\(self.redPack.count!) \(self.redPack.symbol!)", font: Font.regular(15), textColor: UIColor(hexString: "#FF828283")!, paragraphAlignment: .right)
        let priceSize = self.priceNode.updateLayout(CGSize(width: size.width - 75, height: 20))
        transition.updateFrame(node: self.priceNode, frame: CGRect(x: size.width - priceSize.width, y: 13, width: priceSize.width, height: 20))
    }
}

public class TAssetOrderDetailNode: ASDisplayNode {
    
    private let context: AccountContext
    private let redPack: TBRedPackModel
    
    private let preWidth: CGFloat
    private let titleNode: ASTextNode
    private let closeNode: ASButtonNode
    
    private let statusNode: AssetOrderStatusNode
    private let addressNode: TAssetOrderAddressNode
    private let amountNode: TAssetSBUINode
    private let totalNode: TAssetTotalNode
    
    private let buttonNode: ASButtonNode
    
    public var closeEvent: (()->())?
    public var buttonClickEvent: ((URL)->())?
    
    public init(context: AccountContext, redPack: TBRedPackModel, preWidth: CGFloat = UIScreen.main.bounds.width - 70) {
        self.context = context
        self.redPack = redPack
        
        self.preWidth = preWidth
        self.titleNode = ASTextNode()
        self.closeNode = ASButtonNode()
        
        self.statusNode = AssetOrderStatusNode(context: context)
        self.addressNode = TAssetOrderAddressNode(context: context, redPack: redPack)
        self.amountNode = TAssetSBUINode(context: context, redPack: redPack)
        self.totalNode = TAssetTotalNode(context: context, redPack: redPack)
        
        self.buttonNode = ASButtonNode()
        super.init()
    }
    
    public override func didLoad() {
        super.didLoad()
        self.addSubnode(self.titleNode)
        self.buttonNode.addTarget(self, action: #selector(bottomButtonClick(sender:)), forControlEvents: .touchUpInside)
        
        self.addSubnode(self.statusNode)
        self.addressNode.cornerRadius = 8
        self.addressNode.backgroundColor = UIColor(hexString: "#FFF7F8F9")!
        self.addSubnode(self.addressNode)
        self.addSubnode(self.amountNode)
        self.addSubnode(self.totalNode)
        
        self.addSubnode(self.buttonNode)
        self.closeNode.addTarget(self, action: #selector(closeButtonClick(sender:)), forControlEvents: .touchUpInside)
        self.closeNode.setImage(UIImage(named: "Nav/nav_close_icon"), for: .normal)
        self.addSubnode(self.closeNode)
        
        

        
        
        self.titleNode.attributedText = NSAttributedString(string: TBLanguage.sharedInstance.localizable(TBLankey.transfer_detatils_dialog_title), font: Font.bold(18), textColor: UIColor.black)
        if let chainId = self.redPack.chainId {
        let _ = (TBWeb3Config.shared.configSignal |> deliverOnMainQueue).start(next: { [weak self] config in
                if let strongSelf = self,
                   let cf = config,
                   let name = cf.chainType.filter({ NSDecimalNumber(string: "\($0.id)").toBase(16) == chainId}).first?.name {
                    let scan = name
                    let formatString = TBLanguage.sharedInstance.localizable(TBLankey.transfer_detatils_dialog_goto_etherscan)
                    let scanerText = NSString(format: formatString as NSString, scan)
                    strongSelf.buttonNode.setTitle(scanerText as String, with: Font.regular(14), with: UIColor(hexString: "#FF02ABFF")!, for: .normal)
                }
            })
        }
    }
    
    public func updateLayout(size: CGSize, transition: ContainedViewLayoutTransition = .immediate) {
        transition.updateFrame(node: self.titleNode, frame: CGRect(x: 20, y: 30, width: size.width - 40, height: 22))
        transition.updateFrame(node: self.statusNode, frame: CGRect(x: 20, y: 74, width: size.width - 40, height: 56))
        self.statusNode.update(size: CGSize(width: size.width - 40, height: 56), transition: transition)
        transition.updateFrame(node: self.addressNode, frame: CGRect(x: 20, y: 142, width: size.width - 40, height: 93))
        self.addressNode.update(size: CGSize(width: size.width - 40, height: 93), transition: transition)
        transition.updateFrame(node: self.amountNode, frame: CGRect(x: 20, y: 242, width: size.width - 40, height: 46))
        self.amountNode.update(size: CGSize(width: size.width - 40, height: 46), transition: transition)
        transition.updateFrame(node: self.totalNode, frame: CGRect(x: 20, y: 302, width: size.width - 40, height: 59))
        self.totalNode.update(size: CGSize(width: size.width - 40, height: 59), transition: transition)
        transition.updateFrame(node: self.buttonNode, frame: CGRect(x: 20, y: size.height - 48, width: size.width - 40, height: 36))
        transition.updateFrame(node: self.closeNode, frame: CGRect(x: size.width - 44, y: 22, width: 36, height: 36))
    }
    
    @objc func closeButtonClick(sender: UIButton) {
        self.closeEvent?()
    }
    
    @objc func bottomButtonClick(sender: UIButton) {
        if let chainId = self.redPack.chainId {
        let _ = (TBWeb3Config.shared.configSignal |> deliverOnMainQueue).start(next: { [weak self] config in
                if let strongSelf = self,
                   let cf = config,
                   let url = cf.chainType.filter({ NSDecimalNumber(string: "\($0.id)").toBase(16) == chainId}).first?.explorer_url,
                    let url = URL(string: url + "/tx/" + (strongSelf.redPack.transHash ?? "")){
                    strongSelf.buttonClickEvent?(url)
                }
            })
        }
    }
}
