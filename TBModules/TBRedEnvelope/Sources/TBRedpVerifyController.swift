
import Foundation
import UIKit
import Postbox
import SwiftSignalKit
import AsyncDisplayKit
import Display
import TelegramCore
import TelegramPresentationData
import AccountContext
import AvatarNode
import TBWalletCore

class TBRedpVerifyController: ViewController {
    
    public let context: AccountContext
    private var presentationData: PresentationData
    private let presentationDataValue = Promise<PresentationData>()
    private var presentationDataDisposable: Disposable?
    
    private let asset: VerifyAsset
    private let result: CreateResult
    private let peerId: PeerId
    
    private var verifyNode: TBRedpVerifyControllerNode {
        return super.displayNode as! TBRedpVerifyControllerNode
    }
    
    public init(context: AccountContext, peerId: PeerId, asset: VerifyAsset, result: CreateResult) {
        self.context = context
        self.peerId = peerId
        
        self.asset = asset
        self.result = result
        
        self.presentationData = (context.sharedContext.currentPresentationData.with { $0 })
        self.presentationDataValue.set(.single(self.presentationData))
        
        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData))
        
        self.displayNavigationBar = false
        
        let _ = context.account.viewTracker.peerView(context.account.peerId).start(next: {[weak self] peerView in
            let user = peerView.peers[peerView.peerId] as? TelegramUser
            self?.updateNameBy(user)
            self?.updateAvatarBy(user)
        })
        
        let _ = (TBRedEnvelopeInteractor.fetchRedEnvelopeStatusForceOnline(secret_num: self.result.secret_num) |> retry(5, maxDelay: 3600, onQueue: .mainQueue())).start(next: {[weak self] status in
            guard let strongSelf = self else { return }
            let model = TBTransferAssetModel(fromTgId: status.tg_user_id, secretKey: status.secret_num)
            let encodeStr = tb_encode_message_transferAsset(modelToDecode: model)
            let message = EnqueueMessage.message(text: encodeStr, attributes: [], inlineStickers: [:], mediaReference: nil, replyToMessageId: nil, localGroupingKey: nil, correlationId: nil, bubbleUpEmojiOrStickersets: [])
            let _ = enqueueMessages(account: strongSelf.context.account, peerId: strongSelf.peerId, messages: [message]).start()
            if let nav = strongSelf.navigationController {
                for vc in nav.viewControllers.reversed() {
                    if let _ = vc as? ChatController {
                        nav.popToViewController(vc, animated: true)
                        return
                    }
                }
            }
        })
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.presentationDataDisposable?.dispose()
    }
    
     override public func loadDisplayNode() {
         self.displayNode = TBRedpVerifyControllerNode(context: self.context, asset: self.asset)
     
         self.displayNodeDidLoad()
     }
    
    public override func displayNodeDidLoad() {
        super.displayNodeDidLoad()
        self.verifyNode.navNode.closeEvent = {[weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
    }
    
    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        self.verifyNode.update(layout: layout, transition: transition)
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
        self.verifyNode.updateTransferName(name: name.count > 0 ? name : "***" )
    }
    
    private func updateAvatarBy(_ user: TelegramUser?) {
        guard let user = user else { return }
        let peer = EnginePeer(user)
        if let signal = peerAvatarImage(account: self.context.account, peerReference: PeerReference(peer._asPeer()), authorOfMessage: nil, representation: peer.smallProfileImage, displayDimensions: CGSize(width: 24,height: 24)) {
            let _ = signal.start {[weak self] a in
                self?.verifyNode.updateTransferAvatar(avatar: a?.0)
            }
        }else {
            self.verifyNode.updateTransferAvatar(avatar: nil)
        }
    }
}

class RedEnvelopeVerifyNavNode: ASDisplayNode {
    private let context: AccountContext
    
    private let titleNode: ASTextNode
    private let closeNode: ASButtonNode
    
    var closeEvent: (()->())?
    
    init(context: AccountContext) {
        self.context = context
        
        self.titleNode = ASTextNode()
        self.closeNode = ASButtonNode()
        
        super.init()
    }
    
    override func didLoad() {
        super.didLoad()
        
        self.titleNode.attributedText = NSAttributedString(string: "", font: Font.bold(20), textColor: UIColor(hexString: "#FF1A1A1D")!)
        self.addSubnode(self.titleNode)
        
        self.closeNode.addTarget(self, action: #selector(closeButtonClick(sender:)), forControlEvents: .touchUpInside)
        self.closeNode.setImage(UIImage(named: "Nav/nav_close_icon"), for: .normal)
        self.addSubnode(self.closeNode)
    }
    
    func update(size: CGSize, transition: ContainedViewLayoutTransition) {
        let titleSize = self.titleNode.updateLayout(CGSize(width: 200.0, height: .greatestFiniteMagnitude))
        transition.updateFrame(node: self.titleNode, frame: CGRect(x: 16, y: size.height - (14 + titleSize.height), width: titleSize.width, height: titleSize.height))
        transition.updateFrame(node: self.closeNode, frame: CGRect(x: size.width - 44, y: size.height - 46, width: 36, height: 36))
    }
    
    @objc func closeButtonClick(sender: UIButton) {
        self.closeEvent?()
    }
}

struct VerifyAsset {
    let tokensCount: String
    let symbol: String
    let price: String
}

class TBRedpVerifyControllerNode: ASDisplayNode {
    private let context: AccountContext
    
    private let asset: VerifyAsset
    
    let navNode: RedEnvelopeVerifyNavNode
    private let lineNode: ASDisplayNode
    private let backgroundNode: ASImageNode
    private let avatarNode: ASImageNode
    private let fromNameNode: ASTextNode
    private let tokensNode: ASTextNode
    private let priceNode: ASTextNode
    
    private let alertTitleNode: ASTextNode
    private let alertSubNode: ASTextNode
    private let alertFootNode: ASTextNode
    
    init(context: AccountContext, asset: VerifyAsset) {
        self.context = context
        self.asset = asset
        
        self.navNode = RedEnvelopeVerifyNavNode(context: context)
        self.lineNode = ASDisplayNode()
        
        self.backgroundNode = ASImageNode()
        self.avatarNode = ASImageNode()
        self.fromNameNode = ASTextNode()
        self.tokensNode = ASTextNode()
        self.priceNode = ASTextNode()
        
        self.alertTitleNode = ASTextNode()
        self.alertSubNode = ASTextNode()
        self.alertFootNode = ASTextNode()
        
        super.init()
        self.backgroundColor = UIColor.white
    }
    
    override func didLoad() {
        super.didLoad()
        self.addSubnode(self.navNode)
        
        self.lineNode.backgroundColor = UIColor(hexString: "#FFE6E6E6")
        self.addSubnode(lineNode)
        
        self.backgroundNode.image = UIImage(named: "TBRedEnvelope/red_bg_img")
        self.addSubnode(self.backgroundNode)
        self.backgroundNode.addSubnode(self.avatarNode)
        self.backgroundNode.addSubnode(self.fromNameNode)
        
        self.tokensNode.attributedText = NSAttributedString(string: self.asset.tokensCount + " " + self.asset.symbol, font: Font.bold(36), textColor: UIColor(hexString: "#FFF9EED2")!, paragraphAlignment: .center)
        self.backgroundNode.addSubnode(self.tokensNode)
        self.priceNode.attributedText = NSAttributedString(string: "$" + self.asset.price, font: Font.regular(14), textColor: UIColor(hexString: "#FFFFBBAC")!, paragraphAlignment: .center)
        self.backgroundNode.addSubnode(self.priceNode)
        
        self.alertTitleNode.attributedText = NSAttributedString(string: "...", font: Font.bold(20), textColor: UIColor(hexString: "#FF333333")!, paragraphAlignment: .center)
        self.addSubnode(self.alertTitleNode)
        self.alertSubNode.attributedText = NSAttributedString(string: "\n", font: Font.regular(15), textColor: UIColor(hexString: "#FF4F4F4F")!, paragraphAlignment: .center)
        self.addSubnode(self.alertSubNode)
        self.alertFootNode.attributedText = NSAttributedString(string: "24", font: Font.regular(14), textColor: UIColor(hexString: "#FF868686")!, paragraphAlignment: .center)
        self.addSubnode(self.alertFootNode)
    }
    
    func updateTransferName(name: String) {
        self.fromNameNode.attributedText = NSAttributedString(string: "from: " + name, font: Font.regular(14), textColor: UIColor(hexString: "#FFFFFFFF")!)
    }
    
    func updateTransferAvatar(avatar: UIImage?) {
        if let a = avatar {
            self.avatarNode.image = a
        } else {
            self.avatarNode.image = UIImage(named: "Wallet/line_wallet")
        }
    }
    
    func update(layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        let navHeight = (layout.statusBarHeight ?? 20.0) + 44
        let bottomHeight = layout.intrinsicInsets.bottom
        transition.updateFrame(node: self.navNode, frame: CGRect(x: 0, y: 0, width: layout.size.width, height: navHeight))
        self.navNode.update(size: CGSize(width: layout.size.width, height: navHeight), transition: transition)
        
        transition.updateFrame(node: self.lineNode, frame: CGRect(x: 0, y: navHeight, width: layout.size.width, height: 1))
        
        transition.updateFrame(node: self.backgroundNode, frame: CGRect(x: 16, y: navHeight + 18, width: layout.size.width - 32, height: 175))
        transition.updateFrame(node: self.avatarNode, frame: CGRect(x: 14, y: 12, width: 24, height: 24))
        transition.updateFrame(node: self.fromNameNode, frame: CGRect(x: 40, y: 14, width: layout.size.width - 32 - 53, height: 20))
        transition.updateFrame(node: self.tokensNode, frame: CGRect(x: 12, y: 63, width: layout.size.width - 32 - 24, height: 42))
        transition.updateFrame(node: self.priceNode, frame: CGRect(x: 12, y: 107, width: layout.size.width - 32 - 24, height: 20))
        
        transition.updateFrame(node: self.alertTitleNode, frame: CGRect(x: 16, y: navHeight + 245, width: layout.size.width - 32, height: 24))
        transition.updateFrame(node: self.alertSubNode, frame: CGRect(x: 16, y: navHeight + 277, width: layout.size.width - 32, height: 44))
        transition.updateFrame(node: self.alertFootNode, frame: CGRect(x: 16, y: layout.size.height - bottomHeight - 36, width: layout.size.width - 32, height: 16))
    }
}

