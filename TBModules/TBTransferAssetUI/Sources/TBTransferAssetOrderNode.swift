
import UIKit
import Postbox
import Display
import AccountContext
import SwiftSignalKit
import AsyncDisplayKit
import TelegramCore
import TelegramPresentationData
import AvatarNode
import SDWebImage
import TBWalletCore
import TBLanguage
import Web3swift
import Web3swiftCore
import ProgressHUD

struct TBTransferAssetOrder {
    public var fromAddress: String = ""
    public var toAddress: String = ""
    
    public var network: String = ""
    public var icon: String = ""
    public var decimals: Int = 0
    public var symbol: String = ""
    public var address: String?
    public var balance: String = ""
    public var amount: String = ""
    public var price: String = ""
    public var chainId: String = ""
    public var currencyId: String = ""

}

class AssetOrderNameNode: ASDisplayNode {
    private let context: AccountContext
    private let order: TBTransferAssetOrder
    private let fromNode: ASTextNode
    private let fromAddressNode: ASTextNode
    private let fromBalanceNode: ASTextNode
    let fromAvatarNode: UIImageView
    
    private let lineNode: ASDisplayNode
    
    private let toNode: ASTextNode
    private let toAddressNode: ASTextNode
    let toAvatarNode: UIImageView
    
    init(context: AccountContext, order: TBTransferAssetOrder) {
        self.context = context
        self.order = order
        
        self.fromNode = ASTextNode()
        self.fromAddressNode = ASTextNode()
        self.fromBalanceNode = ASTextNode()
        self.fromAvatarNode = UIImageView()
        
        self.lineNode = ASDisplayNode()
        
        self.toNode = ASTextNode()
        self.toAddressNode = ASTextNode()
        self.toAvatarNode = UIImageView()
        super.init()
    }
    
    override func didLoad() {
        super.didLoad()
        self.addSubnode(self.fromNode)
        self.addSubnode(self.fromAddressNode)
        self.addSubnode(self.fromBalanceNode)
        self.fromAvatarNode.backgroundColor = UIColor(hexString: "#FF02ABFF")!
        self.fromAvatarNode.layer.cornerRadius = 18
        self.fromAvatarNode.image = UIImage(named: "Wallet/line_wallet")
        self.fromAvatarNode.layer.masksToBounds = true
        self.view.addSubview(self.fromAvatarNode)
        
        self.lineNode.backgroundColor = UIColor(hexString: "#FFDCDDE0")
        self.addSubnode(self.lineNode)
        
        self.addSubnode(self.toNode)
        self.addSubnode(self.toAddressNode)
        self.toAvatarNode.backgroundColor = UIColor(hexString: "#FF02ABFF")!
        self.toAvatarNode.layer.cornerRadius = 18
        self.toAvatarNode.contentMode = .center
        self.toAvatarNode.image = UIImage(named: "Wallet/line_wallet")
        self.toAvatarNode.layer.masksToBounds = true
        self.view.addSubview(self.toAvatarNode)
        
        self.fromNode.attributedText = NSAttributedString(string: "From:", font: Font.medium(16), textColor: UIColor(hexString: "#FF1A1A1D")!)
        self.fromAddressNode.attributedText = NSAttributedString(string: self.order.fromAddress.simpleAddress(), font: Font.regular(15), textColor: UIColor(hexString: "#FF56565C")!, paragraphAlignment: .right)
        self.fromBalanceNode.attributedText = NSAttributedString(string: ": \(self.order.balance)\(self.order.symbol)", font: Font.regular(15), textColor: UIColor(hexString: "#FF56565C")!, paragraphAlignment: .right)
        
        self.toNode.attributedText = NSAttributedString(string: "To:", font: Font.medium(16), textColor: UIColor(hexString: "#FF1A1A1D")!)
        self.toAddressNode.attributedText = NSAttributedString(string: self.order.toAddress.simpleAddress(), font: Font.regular(15), textColor: UIColor(hexString: "#FF56565C")!, paragraphAlignment: .right)
    }
    
    func update(size: CGSize, transition: ContainedViewLayoutTransition) {
        transition.updateFrame(node: self.fromNode, frame: CGRect(x: 16, y: 21, width: 50, height: 23))
        let fromAddressSize = self.fromAddressNode.updateLayout(CGSize(width: size.width - 71 - 60, height: 22))
        transition.updateFrame(node: self.fromAddressNode, frame: CGRect(x: size.width - fromAddressSize.width - 60, y: 11, width: fromAddressSize.width, height: 22))
        let fromBalanceSize = self.fromBalanceNode.updateLayout(CGSize(width: size.width - 71 - 60, height: 22))
        transition.updateFrame(node: self.fromBalanceNode, frame: CGRect(x: size.width - fromBalanceSize.width - 60, y: 37, width: fromBalanceSize.width, height: 22))
        transition.updateFrame(view: self.fromAvatarNode, frame: CGRect(x: size.width - 16 - 36, y: 14, width: 36, height: 36))
        
        transition.updateFrame(node: self.lineNode, frame: CGRect(x: 0, y: 64, width: size.width, height: 1))
        
        transition.updateFrame(node: self.toNode, frame: CGRect(x: 16, y: 85, width: 50, height: 23))
        let toAddressSize = self.toAddressNode.updateLayout(CGSize(width: size.width - 71 - 60, height: 22))
        transition.updateFrame(node: self.toAddressNode, frame: CGRect(x: size.width - toAddressSize.width - 60, y: 85, width: toAddressSize.width, height: 22))
        transition.updateFrame(view: self.toAvatarNode, frame: CGRect(x: size.width - 16 - 36, y: 78, width: 36, height: 36))
    }
}

class AssetOrderAmountNode: ASDisplayNode {
    private let context: AccountContext
    private let order: TBTransferAssetOrder
    private let titleNode: ASTextNode
    private let amountNode: ASTextNode
    private let priceNode: ASTextNode
    
    init(context: AccountContext, order: TBTransferAssetOrder) {
        self.context = context
        self.order = order
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
        self.titleNode.attributedText = NSAttributedString(string: "Amount", font: Font.medium(16), textColor: UIColor(hexString: "#FF1A1A1D")!)
        self.amountNode.attributedText = NSAttributedString(string: "\(self.order.amount) \(self.order.symbol)", font: Font.regular(16), textColor: UIColor(hexString: "#FF1A1A1D")!, paragraphAlignment: .right)
        self.priceNode.attributedText = NSAttributedString(string: "$\(self.order.price)", font: Font.regular(14), textColor: UIColor(hexString: "#FFABABAF")!, paragraphAlignment: .right)
    }
    
    func update(size: CGSize = CGSize(width: UIScreen.main.bounds.width - 40, height: 43), transition: ContainedViewLayoutTransition) {
        transition.updateFrame(node: self.titleNode, frame: CGRect(x: 0, y: 0, width: 70, height: 20))
        let amountSize = self.amountNode.updateLayout(CGSize(width: size.width - 75, height: 20))
        transition.updateFrame(node: self.amountNode, frame: CGRect(x: size.width - amountSize.width, y: 0, width: amountSize.width, height: 20))
        let priceSize = self.priceNode.updateLayout(CGSize(width: size.width - 75, height: 20))
        transition.updateFrame(node: self.priceNode, frame: CGRect(x: size.width - priceSize.width, y: 23, width: priceSize.width, height: 20))
    }
}

class AssetOrderTotalNode: ASDisplayNode {
    private let context: AccountContext
    private let order: TBTransferAssetOrder
    private let titleNode: ASTextNode
    private let iconNode: UIImageView
    private let amountNode: ASTextNode
    private let priceNode: ASTextNode
    
    
    init(context: AccountContext, order: TBTransferAssetOrder) {
        self.context = context
        self.order = order
        self.titleNode = ASTextNode()
        self.iconNode = UIImageView()
        self.amountNode = ASTextNode()
        self.priceNode = ASTextNode()
        super.init()
    }
    
    override func didLoad() {
        super.didLoad()
        self.addSubnode(self.titleNode)
        self.iconNode.contentMode = .scaleAspectFit
        self.view.addSubview(self.iconNode)
        self.addSubnode(self.amountNode)
        self.addSubnode(self.priceNode)
        self.titleNode.attributedText = NSAttributedString(string: "Total:", font: Font.medium(16), textColor: UIColor(hexString: "#FF1A1A1D")!)
        self.amountNode.attributedText = NSAttributedString(string: "\(self.order.amount)", font: Font.regular(24), textColor: UIColor(hexString: "#FF02ABFF")!, paragraphAlignment: .right)
        self.priceNode.attributedText = NSAttributedString(string: "$\(self.order.price)", font: Font.regular(14), textColor: UIColor(hexString: "#FFABABAF")!, paragraphAlignment: .right)
        self.iconNode.sd_setImage(with: URL(string: self.order.icon))
    }
    
    func update(size: CGSize = CGSize(width: UIScreen.main.bounds.width - 40, height: 43), transition: ContainedViewLayoutTransition) {
        transition.updateFrame(node: self.titleNode, frame: CGRect(x: 0, y: 17, width: 70, height: 20))
        let amountSize = self.amountNode.updateLayout(CGSize(width: size.width - 75 - 23, height: .greatestFiniteMagnitude))
        transition.updateFrame(view: self.iconNode, frame: CGRect(x: size.width - amountSize.width - 23, y: 17, width: 20, height: 20))
        transition.updateFrame(node: self.amountNode, frame: CGRect(x: size.width - amountSize.width, y: 12, width: amountSize.width, height: 30))
        let priceSize = self.priceNode.updateLayout(CGSize(width: size.width - 75, height: 20))
        transition.updateFrame(node: self.priceNode, frame: CGRect(x: size.width - priceSize.width, y: 41, width: priceSize.width, height: 20))
    }
}


class TBTransferAssetOrderNode: ASDisplayNode {
    private let context: AccountContext
    private let from: TBWallet
    private let toPeerId: PeerId?
    private let order: TBTransferAssetOrder
    
    private let previousStepNode: ASButtonNode
    private let closeButtonNode: ASButtonNode
    private let avatarNode: ASImageNode
    private let nameNode: ASTextNode
    
    private let orderNameNode: AssetOrderNameNode
    private let amountNode: AssetOrderAmountNode
    private let totalNode: AssetOrderTotalNode
    
    private let alertNode: ASTextNode
    private let sureButtonNode: ASButtonNode
    private let sureButtonLayer: CAGradientLayer
    
    var previousStepEvent: (() -> Void)?
    var closeEvent: (() -> Void)?
    var transferAssetSuccessHandle: ((String) -> Void)?
    
    init(context: AccountContext, from: TBWallet, toPeerId: PeerId?, order: TBTransferAssetOrder) {
        self.context = context
        self.from = from
        self.toPeerId = toPeerId
        self.order = order
        
        self.previousStepNode = ASButtonNode()
        self.closeButtonNode = ASButtonNode()
        self.avatarNode = ASImageNode()
        self.nameNode = ASTextNode()
        
        self.orderNameNode = AssetOrderNameNode(context: context, order: order)
        self.amountNode = AssetOrderAmountNode(context: context, order: order)
        self.totalNode = AssetOrderTotalNode(context: context, order: order)
        
        self.alertNode = ASTextNode()
        self.sureButtonNode = ASButtonNode()
        self.sureButtonLayer = CAGradientLayer()
        
        super.init()
    }
    
    
    override func didLoad() {
        super.didLoad()
        self.previousStepNode.setTitle(TBLanguage.sharedInstance.localizable(TBLankey.chat_transfer_back), with: Font.regular(17), with: UIColor(hexString: "#FF007AFF")!, for: .normal)
        self.previousStepNode.addTarget(self, action: #selector(previousButtonClickEvent(sender:)), forControlEvents: .touchUpInside)
        self.addSubnode(self.previousStepNode)
        self.closeButtonNode.setImage(UIImage(named: "Nav/nav_close_icon"), for: .normal)
        self.closeButtonNode.addTarget(self, action: #selector(closeButtonClickEvent(sender:)), forControlEvents: .touchUpInside)
        self.addSubnode(self.closeButtonNode)
        self.avatarNode.backgroundColor = UIColor(hexString: "#FF02ABFF")!
        self.avatarNode.cornerRadius = 32
        self.avatarNode.image = UIImage(named: "Wallet/line_wallet")
        self.addSubnode(self.avatarNode)
        self.addSubnode(self.nameNode)
        
        self.orderNameNode.cornerRadius = 8
        self.orderNameNode.borderWidth = 1
        self.orderNameNode.borderColor = UIColor(hexString: "#FFDCDDE0")!.cgColor
        self.addSubnode(self.orderNameNode)
        self.addSubnode(self.amountNode)
        self.addSubnode(self.totalNode)
        
        self.alertNode.attributedText = NSAttributedString(string: TBLanguage.sharedInstance.localizable(TBLankey.chat_transfer_tips), font: Font.regular(14), textColor: UIColor(hexString: "#FFFF4550")!, paragraphAlignment: .center)
        self.addSubnode(self.alertNode)
        self.sureButtonNode.cornerRadius = 24
        
        self.sureButtonNode.setTitle(TBLanguage.sharedInstance.localizable(TBLankey.chat_transfer_confirm), with: Font.medium(15), with: UIColor.white, for: .normal)
        self.sureButtonNode.addTarget(self, action: #selector(nextButtonClickEvent(sender:)), forControlEvents: .touchUpInside)
        self.addSubnode(self.sureButtonNode)
        self.sureButtonLayer.cornerRadius = 24
        self.sureButtonLayer.startPoint = CGPoint(x: 0, y: 0)
        self.sureButtonLayer.endPoint = CGPoint(x: 1, y: 0)
        self.sureButtonLayer.colors = [UIColor(hexString: "#FF01B4FF")!.cgColor, UIColor(hexString: "#FF8836DF")!.cgColor]
        self.sureButtonLayer.locations = [0.0, 1.0]
        self.sureButtonNode.layer.insertSublayer(self.sureButtonLayer, below: self.sureButtonNode.titleNode.layer)
        
        let _ = (self.context.account.viewTracker.peerView(self.context.account.peerId, updateData: true)
                 |> deliverOnMainQueue).start { [weak self] peerView in
            let user = peerView.peers[peerView.peerId] as? TelegramUser
            self?.updateAvatarBy(user, isFrom: true)
        }
        if let _ = self.toPeerId {
            let _ = (self.context.account.viewTracker.peerView(self.toPeerId!, updateData: true)
                     |> deliverOnMainQueue).start { [weak self] peerView in
                let user = peerView.peers[peerView.peerId] as? TelegramUser
                self?.updateNameBy(user)
                self?.updateAvatarBy(user, isFrom: false)
            }
        }
    }
    
    
    func updatePresentationData(_ presentationData: PresentationData) {
        
    }
    
    
    func update(size: CGSize, transition: ContainedViewLayoutTransition = .immediate) {
        transition.updateFrame(node: self.previousStepNode, frame: CGRect(x: 10 , y: 17, width: 60, height: 40))
        transition.updateFrame(node: self.closeButtonNode, frame: CGRect(x: size.width - 50 , y: 17, width: 40, height: 40))
        transition.updateFrame(node: self.avatarNode, frame: CGRect(x: (size.width - 64) / 2, y: 70, width: 64, height: 64))
        transition.updateFrame(node: self.nameNode, frame: CGRect(x: 0, y: 140, width: size.width, height: 22))
        
        transition.updateFrame(node: self.orderNameNode, frame: CGRect(x: 20, y: 186.0, width: size.width - 40, height: 128))
        self.orderNameNode.update(size: CGSize(width: size.width - 40, height: 128), transition: transition)
        transition.updateFrame(node: self.amountNode, frame: CGRect(x: 20, y: 342, width: size.width - 40, height: 43))
        self.amountNode.update(size: CGSize(width: size.width - 40, height: 43), transition: transition)
        transition.updateFrame(node: self.totalNode, frame: CGRect(x: 20, y: 402, width: size.width - 40, height: 73))
        self.totalNode.update(size: CGSize(width: size.width - 40, height: 73), transition: transition)
        let alertSize = self.alertNode.updateLayout(CGSize(width: size.width - 48, height: .greatestFiniteMagnitude))
        transition.updateFrame(node: self.alertNode, frame: CGRect(x: 24, y: size.height - 114 - alertSize.height, width: size.width - 48, height: alertSize.height))
        transition.updateFrame(node: self.sureButtonNode, frame: CGRect(x: 24, y: size.height - 98, width: size.width - 48, height: 48))
        transition.updateFrame(layer: self.sureButtonLayer, frame: CGRect(x: 0, y: 0, width: size.width - 48, height: 48))
    }
    
    
    private func updateNameBy(_ user: TelegramUser?) {
        guard let user = user else { return }
        let name: String = {
            if let name = user.username {
                return name
            }
            var text = ""
            if let firstName = user.firstName {
                text.append("\(firstName) ")
            }
            if let lastName = user.lastName {
                text.append("\(lastName)")
            }
            return text
        }()
        let formatString = TBLanguage.sharedInstance.localizable(TBLankey.chat_transfer_towhotransfer)
        let transtext =  String(format: formatString,name )
        self.nameNode.attributedText = NSAttributedString(string: transtext, font: Font.bold(18), textColor: UIColor(hexString: "#FF1A1A1D")!, paragraphAlignment: .center)
    }
    
    private func updateAvatarBy(_ user: TelegramUser?, isFrom: Bool) {
        guard let user = user else { return }
        let peer = EnginePeer(user)
        if let signal = peerAvatarImage(account: self.context.account, peerReference: PeerReference(peer._asPeer()), authorOfMessage: nil, representation: peer.smallProfileImage, displayDimensions: CGSize(width: 40,height: 40)) {
            let _ = signal.start {[weak self] a in
                self?.updateAvaterImage(image: a?.0, isFrom: isFrom)
            }
        }else {
            self.updateAvaterImage(image: nil, isFrom: isFrom)
        }
    }
    
    func updateAvaterImage(image: UIImage?, isFrom: Bool) {
        DispatchQueue.main.async {
            if isFrom {
                self.orderNameNode.fromAvatarNode.image = image
            } else {
                self.avatarNode.image = image
                self.orderNameNode.toAvatarNode.image = image
            }
        }
    }
    
    @objc func previousButtonClickEvent(sender: UIButton) {
        self.previousStepEvent?()
    }
    
    @objc func closeButtonClickEvent(sender: UIButton) {
        self.closeEvent?()
    }
    
    @objc func nextButtonClickEvent(sender: UIButton) {
        
        switch self.from {
        case .connect(let connect):
            self.transferFromWalletConnect(connect: connect)
        case .mine(let myWallet):
            self.transferFromMyWallet(myWallet: myWallet)
        }
    }
    
    
    private func transferFromWalletConnect(connect: TBWalletConnect) {
        var chainType: String = ""
        switch self.order.network.uppercased() {
        case "ETHEREUM":
            chainType = ETHChain
        case "POLYGON":
            chainType = PolygonChain
        case "THUNDERCORE":
            chainType = TTChain
        case "OASIS":
            chainType = OasisChain
        default:
            chainType = ""
        }
        let value = NSDecimalNumber(string: self.order.amount.decimalString()).multiplying(by: NSDecimalNumber(decimal: pow(10, self.order.decimals))).toBase(16)
        connect.TBWallet_SendTransaction(from: self.order.fromAddress, to: self.order.toAddress, chainType: chainType, value: value, contractAddress: self.order.address ?? "") {[weak self] hash in
            guard let strongSelf = self else { return }
            strongSelf.sendRedPack(hash: hash)
        }
    }
    
    
    private func transferFromMyWallet(myWallet: TBMyWalletModel) {
        guard let chainType = TBWalletTransactionChain.transfer(from: self.order.network) else { return }
        let chainInfo = getChainParam(type: chainType.rawValue)
        ProgressHUD.show("")
        Task {
            let res = await TBMyWallet.transaction(toAddress: self.order.toAddress, chainInfo: chainInfo, account: myWallet, password: "",value: self.order.amount.decimalString())
            
            if let hash = res.hash {
                debugPrint("[TB myWallet hash]: \(hash)")
                self.sendRedPack(hash: hash)
                await ProgressHUD.showSucceed("")
            }else if let err = res.error {
                await ProgressHUD.showFailed(":\(err.localizedDescription)")
                print("[TB myWallet error]: \(err)")
            }
        }
    }
    
    
    private func sendRedPack(hash: String) {
        if hash.count > 0 {
            if let toP = self.toPeerId {
                let redPack = TBRedPackModel(header: "$$", fromTgId: "\(self.context.account.peerId.id.description)", toTgId: toP.id.description, symbol: self.order.symbol, transHash: hash, fromAddress: self.order.fromAddress, toAddress: self.order.toAddress, count: self.order.amount, gassFee: "0", total: self.order.price, price: self.order.price, chainId: NSDecimalNumber(string: self.order.chainId).toBase(16))
                let str = tb_encode_redPack_message(modelToDecode: redPack)
                let _ = TBTransferAssetInteractor.updateTransfer(payment_tg_user_id: "\(self.context.account.peerId.id.description)", payment_account: self.order.fromAddress, receipt_tg_user_id: toP.id.description, receipt_account: self.order.toAddress, chain_id: self.order.chainId, chain_name: self.order.network, amount: self.order.amount, currency_id: self.order.currencyId, currency_name: self.order.symbol, tx_hash: hash).start()
                DispatchQueue.main.async {
                    self.transferAssetSuccessHandle?(str)
                }
            } else {
                DispatchQueue.main.async {
                    self.closeEvent?()
                }
            }
        } else {
            
        }
    }
    
}

