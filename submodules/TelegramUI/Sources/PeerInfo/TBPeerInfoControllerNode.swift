
import UIKit
import Display
import AccountContext
import AsyncDisplayKit
import SwiftSignalKit
import TelegramPresentationData
import SwiftUI
import TelegramCore
import Postbox
import AvatarNode
import TBLanguage
import TBDisplay
import TBAccount
import TBWeb3Core

public struct InfoItem {
    
    public enum InfoType {
        case message
        case voice
        case secret
        case addFriend
        case mainPage
    }
    
    let type: InfoType
    let title: String
    let imageName: String
}


class PeerIDNode: ASDisplayNode {
    
    private let idNode: ASImageNode
    private let idTextNode: ASTextNode
    private let rightNode: ASImageNode
    var peerId: String = ""
    override init() {
        self.idNode = ASImageNode()
        self.idTextNode = ASTextNode()
        self.rightNode = ASImageNode()
        
        super.init()
    }
    
    
    override func didLoad() {
        super.didLoad()
        self.idNode.image = UIImage(named: "Peer Info/icon_id_group_profile")
        self.addSubnode(self.idNode)
        
        self.addSubnode(self.idTextNode)
        
        self.rightNode.image = UIImage(named: "Peer Info/icon_arrow_tg_profile_id")
        self.addSubnode(self.rightNode)
    }
    
    
    func update(size: CGSize) {
        self.idNode.frame = CGRect(x: 6.0, y: (size.height - 20) / 2.0, width: 20, height: 20)
        self.idTextNode.frame = CGRect(x: 30.0, y: 6, width: size.width - 60, height: 20)
        self.rightNode.frame = CGRect(x: size.width - 26, y: (size.height - 20) / 2.0, width: 20, height: 20)
    }
    
    func updateIdText(_ text: String) -> CGSize {
        self.peerId = text
        self.idTextNode.attributedText = NSAttributedString(string: text, font: Font.medium(14), textColor: UIColor(hexString: "#FF1A1A1D")!, paragraphAlignment: .center)
        var size = self.idTextNode.updateLayout(CGSize(width: 200, height: CGFloat.greatestFiniteMagnitude))
        size.width += 60
        return size
    }
}

fileprivate func infoItemsBy(types: [InfoItem.InfoType]) -> [InfoItem] {
    var infoItems = [InfoItem]()
    for type in types {
        switch type {
        case .message:
            let message = InfoItem(type: .message, title: TBLanguage.sharedInstance.localizable(TBLankey.user_personal_message), imageName: "Peer Info/icon_message_tg_profile")
            infoItems.append(message)
        case .voice:
            let voice = InfoItem(type: .voice, title: TBLanguage.sharedInstance.localizable(TBLankey.user_personal_voice), imageName: "Peer Info/icon_voice_tg_profile")
            infoItems.append(voice)
        case .secret:
            let secret = InfoItem(type: .secret, title: TBLanguage.sharedInstance.localizable(TBLankey.user_personal_secret_chat), imageName: "Peer Info/icon_private_tg_profile")
            infoItems.append(secret)
        case .addFriend:
            let addFriend = InfoItem(type: .addFriend, title: TBLanguage.sharedInstance.localizable(TBLankey.user_personal_add_friend), imageName: "Peer Info/icon_add_friend_tg_profile")
            infoItems.append(addFriend)
        case .mainPage:
            let mainPage = InfoItem(type: .mainPage, title: TBLanguage.sharedInstance.localizable(TBLankey.user_personal_main_page), imageName: "Peer Info/icon_main_page_tg_profile")
            infoItems.append(mainPage)
        }
    }
    return infoItems
}

class TBInfoItemNode: ASDisplayNode {
    
    private let infoItem: InfoItem
    private let iconBgNode: ASDisplayNode
    private let iconNode: ASImageNode
    private let titleNode: ASTextNode
    var infoItemClick: ((InfoItem.InfoType) -> ())?
    
    init(_ item: InfoItem) {
        self.infoItem = item
        self.iconBgNode = ASDisplayNode()
        self.iconNode = ASImageNode()
        self.titleNode = ASTextNode()
        super.init()
    }
    
    
    override func didLoad() {
        super.didLoad()
        self.iconBgNode.backgroundColor = UIColor(hexString: "#FFF0F0F0")
        self.iconBgNode.cornerRadius = 23
        self.addSubnode(self.iconBgNode)
        self.iconNode.image = UIImage(named: self.infoItem.imageName)
        self.addSubnode(self.iconNode)
        self.titleNode.attributedText = NSAttributedString(string: self.infoItem.title, font: Font.medium(11), textColor: UIColor(hexString: "#FF56565C")!, paragraphAlignment: .center)
        self.addSubnode(self.titleNode)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapEvent(tap:)))
        self.view.addGestureRecognizer(tap)
    }
    
    func updateNodeSize(_ size: CGSize, transition: ContainedViewLayoutTransition) {
        transition.updateFrame(node: self.iconBgNode, frame: CGRect(x: (size.width - 46) / 2.0, y: 0, width: 46, height: 46))
        transition.updateFrame(node: self.iconNode, frame: CGRect(x: self.iconBgNode.frame.minX + 8, y: self.iconBgNode.frame.minY + 8, width: 30, height: 30))
        transition.updateFrame(node: self.titleNode, frame: CGRect(x: 0, y: self.iconBgNode.frame.maxY + 6, width: size.width, height: 16))
    }
    
    @objc func tapEvent(tap: UITapGestureRecognizer) {
        self.infoItemClick?(self.infoItem.type)
    }
}

class TBInfoWalletNode: ASDisplayNode {
    private let context: AccountContext
    private var presentationData: PresentationData
    private let infoBgNode: ASDisplayNode
    private let nameNode: ASTextNode
    private let walletTextNode: ASTextNode
    private let walletInfobuttonNode: ASButtonNode
    private let networkIconNode: UIImageView
    private let networkNameNode: ASTextNode
    private let addressNode: ASTextNode
    private let copyBottonNode: ASButtonNode
    private let checkBottonNode: ASTextNode
    private let checkIconNode: ASButtonNode
    private let transferButtonView: TBButtonView
    private var address: String?
    private var walletInfoUrl: String?
    
    var transferEvent: ((String) -> (Void))?
    var addressTouchEvent: ((String) -> (Void))?
    var walletInfoTouchEvent: ((String) -> (Void))?
    var checkWalletTouchEvent: ((String) -> (Void))?
    
    init(context: AccountContext, presentationData: PresentationData) {
        self.context = context
        self.presentationData = presentationData
        self.infoBgNode = ASDisplayNode()
        
        self.nameNode = ASTextNode()
        self.walletTextNode = ASTextNode()
        self.walletInfobuttonNode = ASButtonNode()
        
        self.networkIconNode = UIImageView()
        self.networkNameNode = ASTextNode()
        
        self.addressNode = ASTextNode()
        self.copyBottonNode = ASButtonNode()
        
        self.checkBottonNode = ASTextNode()
        self.checkIconNode = ASButtonNode()
        
        let config = TBBottonViewNormalConfig(gradientColors: [UIColor(hexString: "#FF3954D5")!.cgColor, UIColor(hexString: "#FF8836DF")!.cgColor], borderWidth: 0, borderColor: UIColor.clear.cgColor, borderRadius: 0, enbale: true, alpha: 1, iconSize: CGSize(width: 26, height: 26), titleFont: Font.medium(13), buttonType: .titleRight)
        self.transferButtonView = TBButtonView(config: config)
        super.init()
    }
    
    
    override func didLoad() {
        super.didLoad()
        self.infoBgNode.cornerRadius = 10
        self.infoBgNode.borderWidth = 1
        self.infoBgNode.borderColor = UIColor(hexString: "#FF3954D5")!.cgColor
        self.addSubnode(self.infoBgNode)
        
        self.infoBgNode.addSubnode(self.nameNode)
        self.walletTextNode.attributedText = NSAttributedString(string: "", font: Font.regular(15.0), textColor: UIColor(hexString: "#FF1A1A1D")!)
        self.infoBgNode.addSubnode(self.walletTextNode)
        self.walletInfobuttonNode.setImage(UIImage(named: "TBPeerInfo/filled_ faq_Icon"), for: .normal)
        self.infoBgNode.addSubnode(self.walletInfobuttonNode)
        self.walletInfobuttonNode.addTarget(self, action: #selector(self.infoWalletEvent), forControlEvents: .touchUpInside)
        
        self.networkIconNode.contentMode = .scaleAspectFit
        self.infoBgNode.view.addSubview(self.networkIconNode)
        self.infoBgNode.addSubnode(self.networkNameNode)
        
        self.infoBgNode.addSubnode(self.addressNode)
        self.copyBottonNode.setImage(UIImage(named: "TBPeerInfo/icon_copy_address_wallet"), for: .normal)
        self.infoBgNode.addSubnode(self.copyBottonNode)
        self.copyBottonNode.addTarget(self, action: #selector(copyEvent(button:)), forControlEvents: .touchUpInside)
        
        self.checkBottonNode.attributedText = NSAttributedString(string: "", font: Font.medium(13), textColor: UIColor(hexString: "#FF56565C")!)
        self.infoBgNode.addSubnode(self.checkBottonNode)
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.checkEvent))
        self.checkBottonNode.view.addGestureRecognizer(tap)
        self.checkIconNode.setImage(UIImage(named: "TBPeerInfo/Icons_info_arrow_right"), for: .normal)
        self.infoBgNode.addSubnode(self.checkIconNode)
        self.checkIconNode.addTarget(self, action: #selector(self.checkEvent), forControlEvents: .touchUpInside)
        
        self.transferButtonView.contentView.icon.image = UIImage(named: "TBPeerInfo/icon_message_transfer_good_tools_white")
        self.transferButtonView.contentView.titleLabel.text = ""
        self.transferButtonView.contentView.titleLabel.textColor = UIColor.white
        self.view.addSubview(self.transferButtonView)
        self.transferButtonView.tapBlock = {[weak self] in
            guard let strongSelf = self, let address = strongSelf.address else { return }
            strongSelf.transferEvent?(address)
        }
        let wallet_way = TBAccount.shared.systemCheckData.wallet_way
        self.walletInfobuttonNode.isHidden = wallet_way.isEmpty
        
    }
    
    func updateName(name: String) {
        self.nameNode.attributedText = NSAttributedString(string: name, font: Font.medium(20.0), textColor: UIColor(hexString: "#FF1A1A1D")!)
        let size = self.nameNode.updateLayout(CGSize(width: 110.0, height: .greatestFiniteMagnitude))
        let nameFrame = CGRect(x: 14, y: 8, width: size.width, height: 23)
        self.nameNode.frame = nameFrame
        let walletSize = self.walletTextNode.updateLayout(CGSize(width: 200.0, height: .greatestFiniteMagnitude))
        let walletTextFrame = CGRect(x: nameFrame.maxX + 4, y: 12, width: walletSize.width, height: 17)
        self.walletTextNode.frame = walletTextFrame
        self.walletInfobuttonNode.frame = CGRect(x: walletTextFrame.maxX, y: 11, width: 20, height: 20)
    }
    
    func updateNetwork(network: NetworkInfo) {
        let width = UIScreen.main.bounds.size.width - 32
        self.networkNameNode.attributedText = NSAttributedString(string: network.chain_name, font: Font.medium(13.0), textColor: UIColor(hexString: "#FF1A1A1D")!)
        let size = self.networkNameNode.updateLayout(CGSize(width: 200.0, height: .greatestFiniteMagnitude))
        let nameFrame = CGRect(x: width - 14 - size.width, y: 12, width: size.width, height: 18)
        self.networkNameNode.frame = nameFrame
        self.networkIconNode.sd_setImage(with: URL(string: network.chain_icon))
        self.networkIconNode.frame = CGRect(x: nameFrame.minX - 26, y: 9, width: 20, height: 20)
        if let address = network.wallet_info.first?.wallet_address {
            self.address = address
            self.addressNode.attributedText = NSAttributedString(string: address.simpleAddress(), font: Font.regular(13.0), textColor: UIColor(hexString: "#FF56565C")!)
            let addressSize = self.addressNode.updateLayout(CGSize(width: 110.0, height: .greatestFiniteMagnitude))
            let addressFrame = CGRect(x: 14, y: 47, width: addressSize.width, height: 18)
            self.addressNode.frame = addressFrame
            self.copyBottonNode.frame = CGRect(x: addressFrame.maxX, y: 46, width: 20, height: 20)
        }
    }
    
    func update(size: CGSize, transition: ContainedViewLayoutTransition) {
        self.infoBgNode.frame = CGRect(x: 0, y: 0, width: size.width, height: 84)
        self.transferButtonView.frame = CGRect(x: 0, y: 74, width: size.width, height: 40)
        self.checkIconNode.frame = CGRect(x: size.width - 29, y: 46, width: 20, height: 20)
        let iconSize = self.checkBottonNode.updateLayout(CGSize(width: 220.0, height: .greatestFiniteMagnitude))
        self.checkBottonNode.frame = CGRect(x: size.width - iconSize.width - 29, y: 48, width: iconSize.width, height: 18)
    }
    
    @objc func copyEvent(button: UIButton) {
        if let address = self.address {
            self.addressTouchEvent?(address)
        }
    }
    
    @objc func checkEvent() {
        if let address = self.address {
            self.checkWalletTouchEvent?(address)
        }
    }
    
    @objc func infoWalletEvent() {
        if let url = self.walletInfoUrl {
            self.walletInfoTouchEvent?(url)
        }
    }
}


class TBInfoButtonsNode: ASDisplayNode {
    private let context: AccountContext
    private var presentationData: PresentationData
    private let toolsScrollNode: ASScrollNode
    
    typealias ItemConfig = (type: InfoItem.InfoType, itemNode: TBInfoItemNode, frame: CGRect)
    private var itemNodes = [ItemConfig]()
    var infoItemClickEvent:((InfoItem.InfoType)->())?
    
    init(context: AccountContext, presentationData: PresentationData) {
        self.context = context
        self.presentationData = presentationData
        self.toolsScrollNode = ASScrollNode()
        super.init()
        self.backgroundColor = .white
    }
    
    
    override func didLoad() {
        super.didLoad()
        let width = UIScreen.main.bounds.size.width
        self.toolsScrollNode.frame = CGRect(x: 16, y: 23, width: width - 32, height: 70)
        self.addSubnode(self.toolsScrollNode)
        
        let types: [InfoItem.InfoType] = [.message, .voice, .secret, .addFriend, .mainPage]
        let itemWidth: CGFloat = 50
        let minSpace: CGFloat = 10
        let space = max(((width - 32.0) - CGFloat(types.count) * itemWidth) / CGFloat(types.count - 1), minSpace)
        let contentWidth = max(itemWidth * CGFloat(types.count) + space * CGFloat(types.count - 1), width - 32)
        self.toolsScrollNode.view.contentSize = CGSize(width:  contentWidth, height: 70)
        self.toolsScrollNode.view.showsHorizontalScrollIndicator = false
        self.toolsScrollNode.view.showsVerticalScrollIndicator = false
        let infoItems = infoItemsBy(types: types)
        for (index, item) in infoItems.enumerated() {
            let itemNode = TBInfoItemNode(item)
            let frame = CGRect(x: CGFloat(index) * (itemWidth + space), y: 0, width: itemWidth, height: 70)
            self.toolsScrollNode.addSubnode(itemNode)
            self.itemNodes.append(ItemConfig(item.type, itemNode, frame))
            itemNode.infoItemClick = {[weak self] infoType in
                self?.infoItemClickEvent?(infoType)
            }
        }
    }
    
    func update(layout: CGSize, transition: ContainedViewLayoutTransition) {
        for item in self.itemNodes {
            transition.updateFrame(node: item.itemNode, frame: item.frame)
            item.itemNode.updateNodeSize(item.frame.size, transition: transition)
        }
    }
}


class TBPeerInfoMessageNode: ASDisplayNode {
    
    private let context: AccountContext
    private var presentationData: PresentationData
    private let messageBgNode: ASDisplayNode
    private let messageNode: ASTextNode
    private let messageArrowNode: ASImageNode
    private let lastMessageNode: ASTextNode
    private let lineNode: ASDisplayNode
    
    var messageInGroupEvent: (()->())?
    
    init(context: AccountContext, presentationData: PresentationData) {
        self.context = context
        self.presentationData = presentationData
        self.messageBgNode = ASDisplayNode()
        self.messageNode = ASTextNode()
        self.messageArrowNode = ASImageNode()
        self.lastMessageNode = ASTextNode()
        self.lineNode = ASDisplayNode()
        super.init()
        self.backgroundColor = .white
    }
    
    
    override func didLoad() {
        super.didLoad()
        let width = UIScreen.main.bounds.size.width
        self.messageBgNode.backgroundColor = UIColor(hexString: "#FFF0F5FF")
        self.messageBgNode.cornerRadius = 8
        self.messageBgNode.frame = CGRect(x: 16, y: 0, width: width - 32, height: 40)
        self.addSubnode(self.messageBgNode)
        self.messageBgNode.addSubnode(self.messageNode)
        self.messageArrowNode.image = UIImage(named: "Peer Info/icon_arrow_right_tg_rpofile_message")
        self.messageBgNode.addSubnode(self.messageArrowNode)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(messageInGroupClick(tap:)))
        self.messageNode.view.addGestureRecognizer(tap)
        
        self.addSubnode(self.lastMessageNode)
        self.lineNode.backgroundColor = UIColor(hexString: "#FFE6E6E6")
        self.addSubnode(self.lineNode)
    }
    
    func updateMessageInfo(totalCount: Int32, timestamp: String) {
        let title = String(format: TBLanguage.sharedInstance.localizable(TBLankey.user_personal_msg_num), totalCount)
        self.messageNode.attributedText = NSAttributedString(string: title, font: Font.medium(13), textColor: UIColor(hexString: "#FF02ABFF")!)
        let baseWidth = UIScreen.main.bounds.width
        let totalCountMaxWidth = baseWidth - 32
        let totalCountWidth = self.messageNode.updateLayout(CGSize(width: totalCountMaxWidth, height: .greatestFiniteMagnitude)).width
        let messageFrame = CGRect(x: (totalCountMaxWidth + 32 - totalCountWidth - 32) / 2.0, y: 13, width: totalCountWidth, height: 16)
        self.messageNode.frame = messageFrame
        self.messageArrowNode.frame = CGRect(x: messageFrame.maxX + 11, y: 10, width: 20, height: 20)
        
        let lastMessageTitle = TBLanguage.sharedInstance.localizable(TBLankey.user_personal_last_msg_date) + "" + timestamp
        self.lastMessageNode.attributedText = NSAttributedString(string: lastMessageTitle, font: Font.medium(10), textColor: UIColor(hexString: "#FF868686")!)
        let dateWidth = self.lastMessageNode.updateLayout(CGSize(width: baseWidth, height: .greatestFiniteMagnitude)).width
        self.lastMessageNode.frame = CGRect(x: (baseWidth - dateWidth) / 2.0, y: 45, width: dateWidth, height: 14)
        self.lineNode.frame = CGRect(x: 0, y: infoMessageHeight - 1, width: baseWidth, height: 1)
    }
    
    @objc func messageInGroupClick(tap: UITapGestureRecognizer) {
        self.messageInGroupEvent?()
    }
    
}

enum InfoType: Equatable {
    case normal
    case wallet(info: NetworkInfo)
    
    static func == (lhs: InfoType, rhs: InfoType) -> Bool {
        switch lhs {
        case .normal:
            if case .normal = rhs {
                return true
            } else {
                return false
            }
        case let .wallet(lInfo):
            if case let .wallet(rInfo) = rhs {
                return lInfo == rInfo
            } else {
                return false
            }
        }
    }
}

class TBPeerInfoNode: ASDisplayNode {

    private let context: AccountContext
    private var presentationData: PresentationData
    
    private let lineNode: ASDisplayNode
    private let topImageNode: ASImageNode
    private let closebtnNode: ASButtonNode
    private let bottomContainNode: ASDisplayNode
    private let avatarBgNode: ASDisplayNode
    private let avatarNode: ASImageNode
    private let peerIdNode: PeerIDNode
    private let nameNode: ASTextNode
    let walletNode: TBInfoWalletNode
    private let sectionLineNode: ASDisplayNode
    
    let infoTypePromise: ValuePromise<InfoType>
    
    var closeEventHandle: (()->())?
    var peerIdClickEvent: ((String)->())?
    
    init(context: AccountContext, presentationData: PresentationData, peerId: PeerId) {
        self.context = context
        self.presentationData = presentationData
        
        self.lineNode = ASDisplayNode()
        self.topImageNode = ASImageNode()
        self.closebtnNode = ASButtonNode()
        self.bottomContainNode = ASDisplayNode()
        self.avatarBgNode = ASDisplayNode()
        self.avatarNode = ASImageNode()
        self.infoTypePromise = ValuePromise(.normal, ignoreRepeated: true)
        self.peerIdNode = PeerIDNode()
        self.nameNode = ASTextNode()
        self.walletNode = TBInfoWalletNode(context: context, presentationData: presentationData)
        self.sectionLineNode = ASDisplayNode()
        
        super.init()
        
        let _ = (TBPeerInfoInteractor.fetchNetworkInfo(by: peerId.id.description) |> deliverOnMainQueue).start(next: { [weak self] info in
            self?.infoTypePromise.set(.wallet(info: info))
        })
    }

    
    override func didLoad() {
        super.didLoad()
        let width = UIScreen.main.bounds.size.width
        self.lineNode.backgroundColor = UIColor.white
        self.lineNode.cornerRadius = 4
        self.addSubnode(self.lineNode)
        
        self.topImageNode.image = UIImage(named: "Peer Info/image_background_mask_profile")
        self.addSubnode(self.topImageNode)
        
        self.closebtnNode.cornerRadius = 15
        self.closebtnNode.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.7)
        self.closebtnNode.setImage(UIImage(named: "Peer Info/icon_close_tg_rpofile_bg"), for: .normal)
        self.closebtnNode.addTarget(self, action: #selector(closeEvent(btn:)), forControlEvents: .touchUpInside)
        self.addSubnode(self.closebtnNode)
        
        self.bottomContainNode.backgroundColor = UIColor.white
        self.addSubnode(self.bottomContainNode)
        
        self.avatarBgNode.cornerRadius = 46
        self.avatarBgNode.borderColor = UIColor(hexString: "#FF2585E6")!.cgColor
        self.avatarBgNode.borderWidth = 0.5
        self.avatarBgNode.backgroundColor = UIColor.white
        self.addSubnode(self.avatarBgNode)
        
        self.avatarNode.image = UIImage(named:"Chat/nav/image_default_avatar_tittle_bar")
        self.avatarBgNode.addSubnode(self.avatarNode)
        
        self.peerIdNode.backgroundColor = UIColor(hexString: "#FFF0F5FF")
        self.peerIdNode.cornerRadius = 15
        self.bottomContainNode.addSubnode(self.peerIdNode)
        
        
        self.bottomContainNode.addSubnode(self.nameNode)
        
        self.walletNode.backgroundColor = UIColor.white
        self.walletNode.cornerRadius = 10
        self.walletNode.clipsToBounds = true
        self.bottomContainNode.addSubnode(self.walletNode)
        
        self.sectionLineNode.backgroundColor = UIColor(hexString: "#FFF2F2F2")
        self.bottomContainNode.addSubnode(self.sectionLineNode)
        
        let tap1 = UITapGestureRecognizer(target: self, action: #selector(peerIdNodeClickEvent(tap:)))
        self.peerIdNode.view.addGestureRecognizer(tap1)

        let lineNode = ASDisplayNode()
        lineNode.backgroundColor = UIColor(hexString: "#FFE6E6E6")
        lineNode.frame = CGRect(x: 0, y: 273, width: width, height: 1)
        self.bottomContainNode.addSubnode(lineNode)
        
        let _ = (self.infoTypePromise.get() |> deliverOnMainQueue).start(next: {[weak self] type in
            guard let strongSelf = self else { return }
            switch type {
            case .normal:
                strongSelf.walletNode.isHidden = true
                strongSelf.nameNode.isHidden = false
            case let .wallet(info):
                strongSelf.walletNode.isHidden = false
                strongSelf.nameNode.isHidden = true
                strongSelf.walletNode.updateNetwork(network: info)
            }
        })
    }
    
    func update(size: CGSize, transition: ContainedViewLayoutTransition) {
        let width = size.width
        self.lineNode.frame = CGRect(x: (width - 50) / 2.0 , y: 0, width: 50, height: 5)
        self.topImageNode.frame = CGRect(x: 0, y: 11, width: width, height: 70)
        self.closebtnNode.frame = CGRect(x: width - 45, y: 26, width: 30, height: 30)
        self.bottomContainNode.frame = CGRect(x: 0, y: 81, width: width, height: size.height - 81)
        self.avatarBgNode.frame = CGRect(x: 20, y: 35, width: 92, height: 92)
        self.avatarNode.frame = CGRect(x: 4, y: 4, width: 84, height: 84)
        self.nameNode.frame = CGRect(x: 16, y: 58, width: width - 32, height: 23)
        self.walletNode.frame = CGRect(x: 16, y: 71, width: width - 32, height: 114)
        self.sectionLineNode.frame = CGRect(x: 0, y: size.height - 81 -  10, width: width, height: 10)
        DispatchQueue.main.async {
            self.walletNode.update(size: CGSize(width: width - 32, height: 114), transition: transition)
        }
    }
    
    func updateID(_ text: String) {
        let size = self.peerIdNode.updateIdText(text)
        self.peerIdNode.frame = CGRect(x: (UIScreen.main.bounds.width - size.width) / 2.0, y: 10, width: size.width, height: 30)
        self.peerIdNode.update(size: CGSize(width: size.width, height: 30))
        self.peerIdNode.isHidden = text.count == 0
    }
    
    func updateDataBy(_ peer: TelegramUser) {
        self.updateNameBy(peer)
        self.updateAvatarBy(peer)
        if let name = peer.username {
            self.updateID("@\(name)")
        } else {
            self.updateID("")
        }
    }
    
    private func updateAvatarBy(_ peer: TelegramUser) {
        func update(_ image: UIImage?) {
            if let image = image {
                self.avatarNode.image = image
            }
        }
        
        let peer = EnginePeer(peer)
        if let signal = peerAvatarImage(account: self.context.account, peerReference: PeerReference(peer._asPeer()), authorOfMessage: nil, representation: peer.smallProfileImage, displayDimensions: CGSize(width: 84,height: 84)) {
            let _ = signal.start(next:  { a in
                update(a?.0)
            })
        }else {
            update(nil)
        }
    }
    
    private func updateNameBy(_ user: TelegramUser) {
        var text = ""
        if let firstName = user.firstName {
            text.append("\(firstName) ")
        }
        if let lastName = user.lastName {
            text.append("\(lastName)")
        }
        if text.count == 0, let name = user.username {
            text.append(name)
        }
        if text.count == 0 {
            text = "er"
        }
        self.nameNode.attributedText = NSAttributedString(string: text, font: Font.medium(20), textColor: UIColor(hexString: "#FF1A1A1D")!, paragraphAlignment: .left)
        self.walletNode.updateName(name: text)
    }
    
    @objc func closeEvent(btn: UIButton) {
        self.closeEventHandle?()
    }
    
    @objc func peerIdNodeClickEvent(tap: UITapGestureRecognizer) {
        self.peerIdClickEvent?(self.peerIdNode.peerId)
    }
}

class TBPeerInfoPersonalDescriptionNode: ASDisplayNode {
    
    private let context: AccountContext
    private var presentationData: PresentationData
    
    private let titleNode: ASTextNode
    private let descriptionNode: ASTextNode
    private let foldButtonNode: ASButtonNode
    
    private let _rowHeightPromise: ValuePromise<CGFloat>
    var rowHeightPromise: ValuePromise<CGFloat> {
        get {
            return self._rowHeightPromise
        }
    }
    private let descriptionPromise: ValuePromise<String?>
    private var _isOpen: Bool = false
    private let foldEventPromise: ValuePromise<Bool>
    
    private var disposable: Disposable?
    
    init(context: AccountContext, presentationData: PresentationData) {
        self.context = context
        self.presentationData = presentationData
        
        self.titleNode = ASTextNode()
        self.descriptionNode = ASTextNode()
        self.foldButtonNode = ASButtonNode()
        
        self._rowHeightPromise = ValuePromise<CGFloat>(0, ignoreRepeated: true)
        self.descriptionPromise = ValuePromise<String?>(nil, ignoreRepeated: true)
        self.foldEventPromise = ValuePromise<Bool>(false, ignoreRepeated: true)
        
        
        
        super.init()
        self.disposable = (combineLatest(queue: .mainQueue(), self.foldEventPromise.get(), self.descriptionPromise.get()) |> deliverOnMainQueue).start(next: {[weak self] isOpen, desc in
            guard let strongSelf = self else { return }
            let title = isOpen ? TBLanguage.sharedInstance.localizable(TBLankey.fg_textview_expand) : TBLanguage.sharedInstance.localizable(TBLankey.fg_textview_collapse)
            strongSelf.foldButtonNode.setTitle(title, with: Font.medium(13), with: UIColor(hexString: "#FF868686")!, for: .normal)
            if let des = desc, des.count > 0 {
                let numberOfLines = isOpen ? 0 : 1
                strongSelf.descriptionNode.maximumNumberOfLines = numberOfLines
                strongSelf.descriptionNode.attributedText = NSAttributedString(string: des, font: Font.regular(14), textColor: UIColor(hexString: "#FF1A1A1D")!, paragraphAlignment: .left)
                let size = strongSelf.descriptionNode.updateLayout(CGSize(width: UIScreen.main.bounds.width - 32, height: .greatestFiniteMagnitude))
                strongSelf.descriptionNode.frame = CGRect(x: 16, y: 40, width: UIScreen.main.bounds.width - 32, height: size.height)
                strongSelf._rowHeightPromise.set(size.height + 40 + 12)
                return
            }
            strongSelf._rowHeightPromise.set(0)
        })
    }
    
    deinit {
        self.disposable?.dispose()
    }
    
    
    override func didLoad() {
        super.didLoad()
        self.backgroundColor = UIColor.white
        self.titleNode.attributedText = NSAttributedString(string: TBLanguage.sharedInstance.localizable(TBLankey.user_personal_introduction), font: Font.medium(13), textColor: UIColor(hexString: "#FF868686")!)
        self.addSubnode(self.titleNode)
        self.addSubnode(self.descriptionNode)
        self.addSubnode(self.foldButtonNode)
        self.foldButtonNode.addTarget(self, action: #selector(foldButtonEvent(btn:)), forControlEvents: .touchUpInside)
    }
    
    
    func updatePresentationData(_ presentationData: PresentationData) {
        
    }
    
    
    func update(size: CGSize, transition: ContainedViewLayoutTransition) {
        transition.updateFrame(node: self.titleNode, frame: CGRect(x: 16, y: 12, width: size.width - 32, height: 18))
        transition.updateFrame(node: self.foldButtonNode, frame: CGRect(x: size.width - 60, y: 1, width: 44, height: 44))
    }
    
    func updateDescription(_ desc: String?) {
        self.descriptionPromise.set(desc)
    }
    
    @objc func foldButtonEvent(btn: UIButton) {
        self._isOpen = !self._isOpen
        self.foldEventPromise.set(self._isOpen)
    }
}


class TBPeerInfoLastOnlineTimeNode: ASDisplayNode {
    
    private let context: AccountContext
    private var presentationData: PresentationData
    
    private let titleNode: ASTextNode
    private let timeNode: ASTextNode
    
    init(context: AccountContext, presentationData: PresentationData) {
        self.context = context
        self.presentationData = presentationData
        
        self.titleNode = ASTextNode()
        self.timeNode = ASTextNode()
        super.init()
    }
    
    
    override func didLoad() {
        super.didLoad()
        self.backgroundColor = UIColor.white
        self.titleNode.attributedText = NSAttributedString(string: TBLanguage.sharedInstance.localizable(TBLankey.user_personal_online_time), font: Font.medium(13), textColor: UIColor(hexString: "#FF868686")!)
        self.addSubnode(self.titleNode)
        self.addSubnode(self.timeNode)
    }
    
    
    func updatePresentationData(_ presentationData: PresentationData) {
        
    }
    
    
    func update(size: CGSize, transition: ContainedViewLayoutTransition) {
        transition.updateFrame(node: self.titleNode, frame: CGRect(x: 16, y: 12, width: size.width - 32, height: 18))
        transition.updateFrame(node: self.timeNode, frame: CGRect(x: 16, y: self.titleNode.frame.maxY + 10, width: size.width - 32, height: 15))
    }
    
    func updateLastOnlineTime(_ time: String) {
        self.timeNode.attributedText = NSAttributedString(string: time, font: Font.regular(14), textColor: UIColor(hexString: "#FF1A1A1D")!)
    }
}

class TBPeerInfoCommonGroupItemNode: ASDisplayNode {
    private let context: AccountContext
    private var presentationData: PresentationData
    private let peerId: PeerId
    private let group: Peer
    
    private let avatarNode: ASImageNode
    private let titleV: ASTextNode
    private let tagsV: ASTextNode
    
    var commonGroupClickEvent: ((Peer)->())?
    
    init(context: AccountContext, presentationData: PresentationData, peerId: PeerId, group: Peer) {
        self.context = context
        self.presentationData = presentationData
        self.peerId = peerId
        self.group = group
        
        self.avatarNode = ASImageNode()
        self.titleV = ASTextNode()
        self.tagsV = ASTextNode()
        
        super.init()
        
        let _ = (context.account.viewTracker.peerView(group.id, updateData: true) |> deliverOnMainQueue).start(next:  {[weak self] peerView in
            let user = peerView.peers[group.id]
            self?.updateAvatarAndMembersBy(user)
            var members = 0
            if let group = user as? TelegramGroup {
                members = group.participantCount
            }
            if let _ = user as? TelegramChannel, let cacheData = peerView.cachedData as? CachedChannelData {
                members = Int(cacheData.participantsSummary.memberCount ?? 0)
            }
            self?.updateOnlineMembersBy(members)
        })
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapEvent(tap:)))
        self.view.addGestureRecognizer(tap)
    }
    
    
    
    override func didLoad() {
        super.didLoad()
        
        self.avatarNode.frame = CGRect(x: 16, y: 8, width: 40, height: 40)
        self.addSubnode(self.avatarNode)
        
        let width = UIScreen.main.bounds.width
        self.titleV.frame = CGRect(x: 98, y: 11, width: width - 98 - 16, height: 16)
        var title = ""
        if let group = self.group as? TelegramGroup {
            title = group.title
        }
        if let channel = self.group as? TelegramChannel {
            title = channel.title
        }
        self.titleV.attributedText = NSAttributedString(string: title, font: Font.medium(14), textColor: UIColor(hexString: "#FF141B33")!, paragraphAlignment: .left)
        self.addSubnode(self.titleV)
        
        self.tagsV.frame = CGRect(x: 98, y: 31, width: width - 98 - 16, height: 14)
        self.addSubnode(self.tagsV)
    }
    
    private func updateAvatarAndMembersBy(_ user: Peer?) {
        guard let user = user else { return }
        
        func update(_ image: UIImage?) {
            if let image = image {
                self.avatarNode.image = image
            } else {
                self.avatarNode.image = UIImage(named:"Chat/nav/image_default_avatar_tittle_bar")
            }
        }
        
        let peer = EnginePeer(user)
        if let signal = peerAvatarImage(account: self.context.account, peerReference: PeerReference(user), authorOfMessage: nil, representation: peer.smallProfileImage, displayDimensions: CGSize(width: 40,height: 40)) {
            let _ = signal.start(next: { a in
                update(a?.0)
            })
        }else {
            update(nil)
        }
    }
    
    private func updateOnlineMembersBy(_ count: Int) {
        
        func update(onlineCount: Int32) {
            let text: String = {
                if onlineCount > 0 {
                    return "\(count) members · \(onlineCount) online"
                } else {
                    return "\(count) members"
                }
            }()
            let attrText = NSMutableAttributedString(string: text, font: Font.regular(12), textColor: UIColor(hexString: "#FF13CB5D")!, paragraphAlignment: .left)
            let range = NSRange(location: 0, length: "\(count) members".count)
            attrText.addAttributes([.foregroundColor : UIColor(hexString: "#FF141B33")!], range: range)
            self.tagsV.attributedText = attrText
        }
        
        if count > 0 && count < 50 {
            let _ = (context.peerChannelMemberCategoriesContextsManager.recentOnlineSmall(engine: context.engine, postbox: context.account.postbox, network: context.account.network, accountPeerId: context.account.peerId, peerId: group.id) |> deliverOnMainQueue).start(next: { onlineCount in
                update(onlineCount: onlineCount)
            })
        } else if count > 50 {
            let _ = (context.peerChannelMemberCategoriesContextsManager.recentOnline(account: context.account, accountPeerId: context.account.peerId, peerId: group.id) |> deliverOnMainQueue).start(next: { onlineCount in
                update(onlineCount: onlineCount)
            })
        }
    }
    
    @objc func tapEvent(tap: UITapGestureRecognizer) {
        self.commonGroupClickEvent?(self.group)
    }
}

class TBPeerInfoCommonGroupsNode: ASDisplayNode {
    
    private let context: AccountContext
    private var presentationData: PresentationData
    private let peerId: PeerId
    private let titleNode: ASTextNode
    private let _rowHeightPromise: ValuePromise<CGFloat>
    private var items = [(TelegramGroup, TBPeerInfoCommonGroupItemNode)]()
    var rowHeightPromise: ValuePromise<CGFloat> {
        get {
            return self._rowHeightPromise
        }
    }
    var commonGroupClickEvent: ((Peer)->())?
    
    init(context: AccountContext, presentationData: PresentationData, peerId: PeerId) {
        self.context = context
        self.presentationData = presentationData
        self.peerId = peerId
        self.titleNode = ASTextNode()
        self._rowHeightPromise = ValuePromise<CGFloat>(0, ignoreRepeated: true)
        super.init()
    }
    
    
    override func didLoad() {
        super.didLoad()
        self.backgroundColor = UIColor.white
        self.titleNode.attributedText = NSAttributedString(string: TBLanguage.sharedInstance.localizable(TBLankey.user_personal_common_group), font: Font.medium(13), textColor: UIColor(hexString: "#FF868686")!)
        self.addSubnode(self.titleNode)
    }
    
    
    func updatePresentationData(_ presentationData: PresentationData) {
        
    }
    
    
    func update(size: CGSize, transition: ContainedViewLayoutTransition) {
        transition.updateFrame(node: self.titleNode, frame: CGRect(x: 16, y: 12, width: size.width - 32, height: 18))
    }
    
    func updateCommonGroup(_ groups: [Peer]) {
        for item in self.items {
            item.1.removeFromSupernode()
        }
        self.items.removeAll()
        let count = groups.count
        let height = CGFloat(max(0, count - 1) * 8) + CGFloat(count) * 56 + (count > 0 ? 37 + 8 : 0)
        self._rowHeightPromise.set(height)
        for (index, group) in groups.enumerated() {
            let node = TBPeerInfoCommonGroupItemNode(context: self.context, presentationData: self.presentationData, peerId: self.peerId, group: group)
            node.frame = CGRect(x: 0, y: 37.0 + (56.0 + 8.0) * CGFloat(index), width: UIScreen.main.bounds.width, height: 56.0)
            self.addSubnode(node)
            node.commonGroupClickEvent = { [weak self] peer in
                self?.commonGroupClickEvent?(peer)
            }
        }
    }
}

fileprivate let maxScale: CGFloat = 0.9
fileprivate let infoHeaderNormalHeight: CGFloat = 200.0
fileprivate let infoHeaderWalletHeight: CGFloat = 299.0
fileprivate var infoHeaderHeight: CGFloat = infoHeaderNormalHeight
fileprivate let infoButtonsHeight: CGFloat = 117.0
fileprivate let infoMessageHeight: CGFloat = 72.0
fileprivate func infoTopHeight() -> CGFloat {
    return infoHeaderHeight + infoButtonsHeight + infoMessageHeight
}

fileprivate func minHeight() -> CGFloat {
    return infoTopHeight() + 1 + 66
}

class TBPeerInfoControllerContainNode: ASDisplayNode {
    private let context: AccountContext
    private var presentationData: PresentationData
    
    private let rootScrollView: UIScrollView
    let infoNode: TBPeerInfoNode
    private let buttonsNode: TBInfoButtonsNode
    private let messageInfoNode: TBPeerInfoMessageNode
    private let containScrollView: UIScrollView
    private let descriptionNode: TBPeerInfoPersonalDescriptionNode
    private let lastTimeNode: TBPeerInfoLastOnlineTimeNode
    private let commonGroupNode: TBPeerInfoCommonGroupsNode
    
    private var disposible: Disposable?
    typealias ScrollOffset = (originY: CGFloat, rootOrigin: CGPoint, containOffset: CGFloat)
    private var beganScrollOffset: ScrollOffset?
    
    let containHeightPromise: ValuePromise<CGFloat>
    private var isInitailHeight = true
    
    var callBackEvent: (() -> Void)?
    var infoItemClickEvent:((InfoItem.InfoType)->())?
    var commonGroupClickEvent: ((Peer)->())?
    var messageInGroupEvent: (()->())?
    var peerIdClickEvent: ((String)->())?
    
    init(context: AccountContext, presentationData: PresentationData, peerId: PeerId, screenData: Signal<PeerInfoScreenData, NoError>) {
        self.context = context
        self.presentationData = presentationData
        
        self.rootScrollView = UIScrollView()
        self.infoNode = TBPeerInfoNode(context: context, presentationData: presentationData, peerId: peerId)
        self.buttonsNode = TBInfoButtonsNode(context: context, presentationData: presentationData)
        self.messageInfoNode = TBPeerInfoMessageNode(context: context, presentationData: presentationData)
        self.containScrollView = UIScrollView()
        self.descriptionNode = TBPeerInfoPersonalDescriptionNode(context: context, presentationData: presentationData)
        self.lastTimeNode = TBPeerInfoLastOnlineTimeNode(context: context, presentationData: presentationData)
        self.commonGroupNode = TBPeerInfoCommonGroupsNode(context: context, presentationData: presentationData, peerId: peerId)
        self.containHeightPromise = ValuePromise<CGFloat>(minHeight())
        
        super.init()
        
        self.disposible = screenData.start(next: {[weak self] screenData in
            guard let strongSelf = self else { return }
            if let a = screenData.chatPeer as? TelegramUser {
                strongSelf.infoNode.updateDataBy(a)
            }
            if let cachedData = screenData.cachedData as? CachedUserData {
                strongSelf.descriptionNode.updateDescription(cachedData.about)
            } else {
                strongSelf.descriptionNode.updateDescription(nil)
            }
            strongSelf.lastTimeNode.updateLastOnlineTime(screenData.status?.text ?? "")
        })
        
        self.commonGroupNode.commonGroupClickEvent = { [weak self] peer in
            self?.commonGroupClickEvent?(peer)
        }
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(panEvent(pan:)))
        pan.delegate = self
        self.rootScrollView.addGestureRecognizer(pan)
    }
    
    deinit {
        self.disposible?.dispose()
    }
    
    
    override func didLoad() {
        super.didLoad()
        
        if #available(iOS 11.0, *) {
            self.rootScrollView.contentInsetAdjustmentBehavior = .never
            self.containScrollView.contentInsetAdjustmentBehavior = .never
        }
        
        self.rootScrollView.isScrollEnabled = false
        self.view.addSubview(self.rootScrollView)
        
        self.infoNode.closeEventHandle = { [weak self] in
            self?.callBackEvent?()
        }
        
        self.infoNode.peerIdClickEvent = {[weak self] peerId in
            self?.peerIdClickEvent?(peerId)
        }
        self.rootScrollView.addSubnode(self.infoNode)
        
        self.buttonsNode.infoItemClickEvent = { [weak self] type in
            self?.infoItemClickEvent?(type)
        }
        self.rootScrollView.addSubnode(self.buttonsNode)
        
        self.messageInfoNode.messageInGroupEvent = {[weak self] in
            self?.messageInGroupEvent?()
        }
        self.rootScrollView.addSubnode(self.messageInfoNode)
        
        self.containScrollView.backgroundColor = UIColor(hexString: "#FFE6E6E6")
        self.containScrollView.bounces = false
        self.rootScrollView.addSubview(self.containScrollView)
        
        self.containScrollView.addSubnode(self.descriptionNode)
        self.containScrollView.addSubnode(self.lastTimeNode)
        self.containScrollView.addSubnode(self.commonGroupNode)
        
        let _ = (combineLatest(queue: .mainQueue(),
                               self.infoNode.infoTypePromise.get(),
                       self.descriptionNode.rowHeightPromise.get(),
                       self.commonGroupNode.rowHeightPromise.get())
         |> deliverOnMainQueue).start(next: {[weak self] infoType, descHeight, commonGroupHeight in
            guard let strongSelf = self else { return }
            let transition = ContainedViewLayoutTransition.immediate
            let width = UIScreen.main.bounds.width
            switch infoType {
            case .normal:
                infoHeaderHeight = infoHeaderNormalHeight
            case .wallet:
                infoHeaderHeight = infoHeaderWalletHeight
            }
            strongSelf.descriptionNode.isHidden = descHeight == 0
            transition.updateFrame(node: strongSelf.descriptionNode, frame: CGRect(x: 0, y: 0, width: width, height: descHeight))
            
            transition.updateFrame(node: strongSelf.lastTimeNode, frame: CGRect(x: 0, y: descHeight + (descHeight == 0 ? 0 : 1), width: width, height: 66))
            
            strongSelf.commonGroupNode.isHidden = commonGroupHeight == 0
            transition.updateFrame(node: strongSelf.commonGroupNode, frame: CGRect(x: 0, y: strongSelf.lastTimeNode.frame.maxY + 1, width: width, height: commonGroupHeight))
            
            strongSelf.containScrollView.contentSize = CGSize(width: width, height: strongSelf.lastTimeNode.frame.maxY + 1 + commonGroupHeight)
            let containHeight = min(strongSelf.lastTimeNode.frame.maxY + 1 + commonGroupHeight + infoTopHeight(), UIScreen.main.bounds.height * maxScale)
            strongSelf.containHeightPromise.set(containHeight)
        })
    }
    
    func update(size: CGSize, transition: ContainedViewLayoutTransition) {

        let rootOriginY: CGFloat = {
            if self.isInitailHeight {
                return size.height - infoTopHeight()
            } else {
                return self.rootScrollView.frame.minY
            }
        }()
        
        transition.updateFrame(view: self.rootScrollView, frame: CGRect(x: 0, y: rootOriginY, width: size.width, height: size.height))
        self.rootScrollView.contentSize = CGSize(width: size.width, height: size.height)
        
        transition.updateFrame(node: self.infoNode, frame: CGRect(x: 0, y: 0, width: size.width, height: infoHeaderHeight))
        transition.updateFrame(node: self.buttonsNode, frame: CGRect(x: 0, y: self.infoNode.frame.maxY, width: size.width, height: infoButtonsHeight))
        
        transition.updateFrame(node: self.messageInfoNode, frame: CGRect(x: 0, y: self.buttonsNode.frame.maxY, width: size.width, height: infoMessageHeight))
        
        transition.updateFrame(view: self.containScrollView, frame: CGRect(x: 0, y: self.messageInfoNode.frame.maxY, width: size.width, height: size.height - infoTopHeight()))
        
        DispatchQueue.main.async {
            self.infoNode.update(size: CGSize(width: size.width, height: infoHeaderHeight), transition: transition)
            self.buttonsNode.update(layout: size, transition: transition)
            self.descriptionNode.update(size: size, transition: transition)
            self.lastTimeNode.update(size: size, transition: transition)
            self.commonGroupNode.update(size: size, transition: transition)
        }
    }
    
    @objc func panEvent(pan: UIPanGestureRecognizer) {
        self.isInitailHeight = false
        
        switch pan.state {
        case .began:
            self.beganScrollOffset = ScrollOffset(pan.location(in: self.view).y, self.rootScrollView.frame.origin, self.containScrollView.contentOffset.y)
        case .changed:
            let scrollHeight = pan.location(in: self.view).y - self.beganScrollOffset!.originY
            let isScrollUp = pan.translation(in: self.containScrollView).y < 0
            let isOnContainView = pan.location(in: self.rootScrollView).y > 344
            let maxContanHeight = self.containScrollView.contentSize.height - self.containScrollView.frame.height
            if isOnContainView {
                var needScroolRoot = false
                if self.containScrollView.contentOffset.y <= 0 && !isScrollUp {
                    self.containScrollView.contentOffset = CGPoint.zero
                    needScroolRoot = true
                }
                if self.containScrollView.contentOffset.y >= maxContanHeight && isScrollUp {
                    self.containScrollView.contentOffset = CGPoint(x: 0, y: maxContanHeight)
                    needScroolRoot = true
                }
                if needScroolRoot {
                    self.containScrollView.isScrollEnabled = false
                    let containHasScrolHeight = self.beganScrollOffset!.containOffset - self.containScrollView.contentOffset.y
                    let tempH = scrollHeight - containHasScrolHeight
                    var tempFrame = self.rootScrollView.frame
                    tempFrame.origin.y = max(self.beganScrollOffset!.rootOrigin.y + tempH, 0)
                    self.rootScrollView.frame = tempFrame
                }
            } else {
                if isScrollUp && self.rootScrollView.frame.origin.y <= 0 {
                    return
                }
                var tempFrame = self.rootScrollView.frame
                tempFrame.origin.y = max(self.beganScrollOffset!.rootOrigin.y + scrollHeight, 0)
                self.rootScrollView.frame = tempFrame
            }
        case .ended:
            self.containScrollView.isScrollEnabled = true
            let transition = ContainedViewLayoutTransition.animated(duration: 0.2, curve: .linear)
            var frame = self.rootScrollView.frame
            let originPoint = self.beganScrollOffset!.rootOrigin
            if frame.minY > (self.rootScrollView.frame.height - minHeight()) + 150 {
                self.callBackEvent?()
                return
            }
            let offset = frame.origin.y - originPoint.y
            if offset >= 0 {
                if offset > 20 {
                    frame.origin.y = self.rootScrollView.frame.height - minHeight()
                } else {
                    frame.origin.y = 0
                }
            } else {
                if offset < -20 {
                    frame.origin.y = 0
                } else {
                    frame.origin.y = self.rootScrollView.frame.height - minHeight()
                }
            }
            





            transition.updateFrame(view: self.rootScrollView, frame: frame)
            self.beganScrollOffset = nil
        default:
            break
        }
    }
    
    func updateMessageInfo(totalCount: Int32, timestamp: String) {
        self.messageInfoNode.updateMessageInfo(totalCount: totalCount, timestamp: timestamp)
    }
    
    func updateCommonGroup(_ groups: [Peer]) {
        self.commonGroupNode.updateCommonGroup(groups)
    }
}

extension TBPeerInfoControllerContainNode: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        return true
    }
}

class TBPeerInfoControllerNode: ASDisplayNode {
    
    private let context: AccountContext
    private var presentationData: PresentationData
    
    private let layoutPromise: ValuePromise<ContainerViewLayout?>

    let containNode: TBPeerInfoControllerContainNode
    
    init(context: AccountContext, presentationData: PresentationData, peerId: PeerId, screenData: Signal<PeerInfoScreenData, NoError>) {
        self.context = context
        self.presentationData = presentationData
        self.containNode = TBPeerInfoControllerContainNode(context: context, presentationData: presentationData, peerId: peerId, screenData: screenData)
        self.layoutPromise = ValuePromise(nil, ignoreRepeated: true)
        super.init()
        self.backgroundColor = UIColor(red: 178.0 / 255.0, green: 178.0 / 255.0, blue: 178.0 / 255.0, alpha: 0.6)
    }
    
    
    override func didLoad() {
        super.didLoad()
        self.addSubnode(self.containNode)
        let _ = (combineLatest(queue: .mainQueue(),
                               self.layoutPromise.get(),
                               self.containNode.containHeightPromise.get())
            |> deliverOnMainQueue).start(next: {[weak self] layout, containHeight in
            guard let strongSelf = self else { return }
            if let layout = layout {
                let transition = ContainedViewLayoutTransition.animated(duration: 0.2, curve: .easeInOut)
                transition.updateFrame(node: strongSelf.containNode, frame: CGRect(x: 0, y: layout.size.height - containHeight, width: layout.size.width, height: containHeight))
                strongSelf.containNode.update(size: CGSize(width: layout.size.width, height: containHeight), transition: transition)
            }
        })
    }
    
    func updatePresentationData(_ presentationData: PresentationData) {
        
    }
    
    func update(layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        self.layoutPromise.set(layout)
    }
    
}
