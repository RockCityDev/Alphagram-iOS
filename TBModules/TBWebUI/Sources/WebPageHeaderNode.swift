
import UIKit
import Display
import AccountContext
import AsyncDisplayKit
import TelegramPresentationData
import SnapKit
import TBWeb3Core
import SDWebImage
import TBDisplay
import TelegramCore
import AvatarNode
import TBLanguage


private class WebNetworkNode: ASDisplayNode {
    private let context: AccountContext
    private var presentationData: PresentationData
    
    private let iconNode: UIImageView
    private let nameNode: ASTextNode
    private let arrowNode: UIImageView
    
    init(context: AccountContext, presentationData: PresentationData) {
        self.context = context
        self.presentationData = presentationData
        self.iconNode = UIImageView()
        self.nameNode = ASTextNode()
        self.arrowNode = UIImageView()
        super.init()
    }
    
    override func didLoad() {
        super.didLoad()
        self.iconNode.layer.cornerRadius = 12
        self.iconNode.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        self.view.addSubview(self.iconNode)
        
        self.addSubnode(self.nameNode)
        self.view.addSubview(self.arrowNode)
    }
    
    func updateNetwork(_ network: NetworkItem, themeColor: UIColor = UIColor.white) {
        let iconImage = network.getIconName()
        if !iconImage.isEmpty {
            if iconImage.hasPrefix("http") {
                self.iconNode.sd_setImage(with: URL(string: iconImage))
            } else {
                self.iconNode.image = UIImage(named: iconImage)
            }
        }
        self.nameNode.attributedText = NSAttributedString(string: network.getTitle(), font: Font.medium(15), textColor: themeColor, paragraphAlignment: .left)
        let size = self.nameNode.updateLayout(CGSize(width: 200.0, height: .greatestFiniteMagnitude))
        self.nameNode.frame = CGRect(x: 33, y: 4, width: size.width, height: 20)
        if let arrowName = network.getArrowName() {
            self.arrowNode.isHidden = false
            let image = UIImage(bundleImageName: arrowName)
            image?.withTintColor(themeColor, renderingMode: .alwaysTemplate)
            self.arrowNode.tintColor = themeColor
            self.arrowNode.image = image
        } else {
            self.arrowNode.isHidden = true
        }
        self.arrowNode.frame = CGRect(x: 33 + size.width + 9, y: 4, width: 16, height: 16)
    }
    
}

class NetworkInfoNode: ASDisplayNode {
    private let context: AccountContext
    private var presentationData: PresentationData
    
    private let addressTNode: ASTextNode
    private let addressNode: ASTextNode
    
    private let idTNode: ASTextNode
    private let idNode: ASTextNode
    
    private let networkTNode: ASTextNode
    private let networkNode: ASTextNode
    
    private let currencyTNode: ASTextNode
    private let currencyNode: ASTextNode
    
    init(context: AccountContext, presentationData: PresentationData) {
        self.context = context
        self.presentationData = presentationData
        
        self.addressTNode = ASTextNode()
        self.addressNode = ASTextNode()
        
        self.idTNode = ASTextNode()
        self.idNode = ASTextNode()
        
        self.networkTNode = ASTextNode()
        self.networkNode = ASTextNode()
        
        self.currencyTNode = ASTextNode()
        self.currencyNode = ASTextNode()
        super.init()
    }
    
    override func didLoad() {
        super.didLoad()
        let width = UIScreen.main.bounds.width
        let eachW = (width - 72) / 2
        self.addressTNode.attributedText = NSAttributedString(string: TBLanguage.sharedInstance.localizable(TBLankey.wallet_home_act_contract_address_title), font: Font.medium(13), textColor: UIColor(hexString: "#FF868686")!, paragraphAlignment: .left)
        self.addressTNode.frame = CGRect(x: 24, y: 0, width: eachW, height: 18)
        self.addSubnode(self.addressTNode)
        self.addressNode.frame = CGRect(x: 24, y: 20, width: eachW, height: 18)
        self.addSubnode(self.addressNode)
        
        self.idTNode.attributedText = NSAttributedString(string: TBLanguage.sharedInstance.localizable(TBLankey.wallet_home_act_token_id_title), font: Font.medium(13), textColor: UIColor(hexString: "#FF868686")!, paragraphAlignment: .left)
        self.idTNode.frame = CGRect(x: width / 2 - 12, y: 0, width: eachW, height: 18)
        self.addSubnode(self.idTNode)
        self.idNode.frame = CGRect(x: width / 2 - 12, y: 20, width: eachW, height: 18)
        self.addSubnode(self.idNode)
        
        self.networkTNode.attributedText = NSAttributedString(string: TBLanguage.sharedInstance.localizable(TBLankey.wallet_home_act_blockchain_title), font: Font.medium(13), textColor: UIColor(hexString: "#FF868686")!, paragraphAlignment: .left)
        self.networkTNode.frame = CGRect(x: 24, y: 54, width: eachW, height: 18)
        self.addSubnode(self.networkTNode)
        self.networkNode.frame = CGRect(x: 24, y: 74, width: eachW, height: 18)
        self.addSubnode(self.networkNode)
        
        self.currencyTNode.attributedText = NSAttributedString(string: TBLanguage.sharedInstance.localizable(TBLankey.wallet_home_act_token_standard_title), font: Font.medium(13), textColor: UIColor(hexString: "#FF868686")!, paragraphAlignment: .left)
        self.currencyTNode.frame = CGRect(x: width / 2 - 12, y: 54, width: eachW, height: 18)
        self.addSubnode(self.currencyTNode)
        self.currencyNode.frame = CGRect(x: width / 2 - 12, y: 74, width: eachW, height: 18)
        self.addSubnode(self.currencyNode)
    }
    
    func updateWalletInfo(info: TBWalletInfo?) {
        let contract: String = {
            if let a = info?.nft_contract, !a.isEmpty {
                return a
            } else {
                return "???"
            }
        }()
        self.addressNode.attributedText = NSAttributedString(string: contract.simpleAddress(), font: Font.medium(13), textColor: UIColor(hexString: "#FF4B5BFF")!, paragraphAlignment: .left)
        
        let tokenId: String = {
            if let a = info?.nft_token_id, !a.isEmpty {
                return a
            } else {
                return "???"
            }
        }()
        self.idNode.attributedText = NSAttributedString(string: tokenId, font: Font.medium(13), textColor: UIColor(hexString: "#FF56565C")!, paragraphAlignment: .left)
    
        let network: String = {
            if let a = getNetworkName(id: info?.nft_chain_id ?? ""), !a.isEmpty {
                return a
            } else {
                return "???"
            }
        }()
        self.networkNode.attributedText = NSAttributedString(string: network, font: Font.medium(13), textColor: UIColor(hexString: "#FF56565C")!, paragraphAlignment: .left)
        
        let nftTokenStandard: String = {
            if let a = info?.nft_token_standard, !a.isEmpty {
                return a
            } else {
                return "???"
            }
        }()
        self.currencyNode.attributedText = NSAttributedString(string: nftTokenStandard, font: Font.medium(13), textColor: UIColor(hexString: "#FF56565C")!, paragraphAlignment: .left)
    }
}


class NFTSettingNode: ASDisplayNode {
    private let context: AccountContext
    private var presentationData: PresentationData
    private let iconNode: ASImageNode
    private let nameNode: ASTextNode
    
    init(context: AccountContext, presentationData: PresentationData) {
        self.context = context
        self.presentationData = presentationData
        self.iconNode = ASImageNode()
        self.nameNode = ASTextNode()
        super.init()
    }
    
    override func didLoad() {
        super.didLoad()
        self.backgroundColor = UIColor(hexString: "#33FFFFFF")
        self.cornerRadius = 11
        
        self.nameNode.attributedText = NSAttributedString(string: " NFT ", font: Font.medium(11), textColor: UIColor.white, paragraphAlignment: .left)
        self.addSubnode(self.nameNode)
        
        self.iconNode.image = UIImage(named: "TBWebPage/icon_nft_photo")
        self.addSubnode(self.iconNode)
        
        self.nameNode.frame = CGRect(x: 10, y: 5, width: 80, height: 16)
        self.iconNode.frame = CGRect(x: 90, y: 3, width: 16, height: 16)
    }
}


class WalletInfoNode: ASDisplayNode {
    private let context: AccountContext
    private var presentationData: PresentationData
    
    private let iconNode: ASImageNode
    private let nameNode: UILabel
    let turnNode: ASImageNode
    var address: String?
    
    init(context: AccountContext, presentationData: PresentationData) {
        self.context = context
        self.presentationData = presentationData
        self.iconNode = ASImageNode()
        self.nameNode = UILabel()
        self.turnNode = ASImageNode()
        super.init()
    }
    
    override func didLoad() {
        super.didLoad()
        
        self.backgroundColor = UIColor(hexString: "#FFF0F5FF")
        self.cornerRadius = 15
        
        self.iconNode.image = UIImage(named: "TBWebPage/icon_metamask_address")
        self.addSubnode(self.iconNode)
        
        self.nameNode.textColor = UIColor(hexString: "#FF1A1A1D")
        self.nameNode.font = Font.medium(14)
        self.nameNode.lineBreakMode = .byTruncatingMiddle
        self.nameNode.textAlignment = .center
        self.view.addSubview(self.nameNode)
        
        self.addSubnode(self.turnNode)
        
        self.iconNode.frame = CGRect(x: 12, y: 3, width: 24, height: 24)
        self.nameNode.frame = CGRect(x: 40, y: 4, width: 95, height: 20)
        self.turnNode.frame = CGRect(x: 136, y: 5, width: 20, height: 20)
    }
    
    func updateAddress(_ address: String?) {
        self.address = address
        self.nameNode.text = address?.simpleAddress()
    }
    
}


class MoneyNode: ASDisplayNode {
    private let context: AccountContext
    private var presentationData: PresentationData
    private let iconNode: ASImageNode
    private let valueNode: ASTextNode
    
    init(context: AccountContext, presentationData: PresentationData) {
        self.context = context
        self.presentationData = presentationData
        self.iconNode = ASImageNode()
        self.valueNode = ASTextNode()
        super.init()
    }
    
    override func didLoad() {
        super.didLoad()
        self.addSubnode(self.valueNode)
        self.iconNode.image = UIImage(named: "")
        self.addSubnode(self.iconNode)
        
        self.valueNode.frame = CGRect(x: 0, y: 0, width: 120, height: 24)
        self.iconNode.frame = CGRect(x: 125, y: 0, width: 24, height: 24)
    }
    
    func updateValue(_ value: String) {
        self.valueNode.attributedText = NSAttributedString(string: value, font: Font.medium(20), textColor: UIColor(hexString: "#FF000000")!, paragraphAlignment: .left)
        let size = self.valueNode.updateLayout(CGSize(width: 300.0, height: .greatestFiniteMagnitude))
        self.valueNode.frame = CGRect(x: 0, y: 0, width: size.width, height: 24)
        self.iconNode.frame = CGRect(x: size.width + 9, y: 0, width: 24, height: 24)
    }
}


class SearchNode: ASDisplayNode {
    private let context: AccountContext
    private var presentationData: PresentationData
    private let searchIconNode: ASImageNode
    private let searchTextNode: UITextField
    private let queryBtnNode: UIButton
    var checkAddressEvent: ((String) -> ())?
    init(context: AccountContext, presentationData: PresentationData) {
        self.context = context
        self.presentationData = presentationData
        self.searchIconNode = ASImageNode()
        self.searchTextNode = UITextField()
        self.queryBtnNode = UIButton()
        super.init()
    }
    
    override func didLoad() {
        super.didLoad()
        
        self.cornerRadius = 7.0
        self.borderWidth = 1
        self.borderColor = UIColor(hexString: "#FFEEEEEE")!.cgColor
        
        self.searchIconNode.image = UIImage(named: "Share/SearchBarSearchIcon")
        self.searchIconNode.contentMode = .scaleToFill
        self.addSubnode(self.searchIconNode)
        
        self.searchTextNode.clearButtonMode = .always
        self.searchTextNode.placeholder = TBLanguage.sharedInstance.localizable(TBLankey.wallet_home_input)
        self.searchTextNode.font = Font.medium(13)
        self.searchTextNode.returnKeyType = .done
        self.searchTextNode.delegate = self
        self.view.addSubview(self.searchTextNode)
        
        let text = TBLanguage.sharedInstance.localizable(TBLankey.wallet_home_btn)
        self.queryBtnNode.setTitle(text, for: .normal)
        self.queryBtnNode.titleLabel?.font = Font.medium(13)
        self.queryBtnNode.setTitleColor(UIColor(hexString: "#FFABABAF"), for: .normal)
        self.view.addSubview(self.queryBtnNode)
        self.queryBtnNode.addTarget(self, action: #selector(checkClick(btn:)), for: .touchUpInside)
        
        let width = UIScreen.main.bounds.width - 32
        self.searchIconNode.frame = CGRect(x: 16, y: 9, width: 22, height: 22)
        self.searchTextNode.frame = CGRect(x: 54, y: 0, width: width - 54 - 60, height: 40)
        self.queryBtnNode.frame = CGRect(x: width - 60, y: 0, width: 60, height: 40)
    }
    
    func endEdit() {
        self.searchTextNode.resignFirstResponder()
    }
    
    @objc func checkClick(btn: UIButton) {
        self.endEdit()
        if let text = self.searchTextNode.text, text.isEmpty == false {
            self.checkAddressEvent?(text)
        }
    }
}

extension SearchNode: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if let text = textField.text, text.isEmpty == false, textField == self.searchTextNode {
            self.checkAddressEvent?(text)
        }
        return true
    }
}


class WebPageHeaderNode: ASDisplayNode {
    private let context: AccountContext
    private var presentationData: PresentationData
    private let isMe: Bool
    
    private let topBgNode: ASDisplayNode
    private let gradientLayer: CAGradientLayer
    
    private let networkNode: WebNetworkNode

    private let closeButton: UIButton
    
    private let avatarBgNode: ASDisplayNode
    private let avatarNode: UIImageView
    
    private let walletInfoNode: WalletInfoNode
    
    private let tgUserIdNode: ASTextNode
    let moneyNode: MoneyNode
    let searchNode: SearchNode
    let networkInfoNode: NetworkInfoNode
    var networkEvent: (() -> ())?
    var closeEvent: (() -> ())?
    var avatarSettingEvent: (() -> ())?
    var walletChangeEvent: ((String) -> ())?
    
    init(context: AccountContext, presentationData: PresentationData, isMe: Bool = true) {
        self.context = context
        self.presentationData = presentationData
        self.isMe = isMe
        
        self.topBgNode = ASDisplayNode()
        self.gradientLayer = CAGradientLayer()
        self.networkNode = WebNetworkNode(context: context, presentationData: presentationData)

        self.closeButton = UIButton(type: .custom)
        
        self.avatarBgNode = ASDisplayNode()
        self.avatarNode = UIImageView()
        
        self.walletInfoNode = WalletInfoNode(context: context, presentationData: presentationData)
        self.tgUserIdNode = ASTextNode()
        self.moneyNode = MoneyNode(context: context, presentationData: presentationData)
        self.searchNode = SearchNode(context: context, presentationData: presentationData)
        self.networkInfoNode = NetworkInfoNode(context: context, presentationData: presentationData)
        super.init()
    }
    
    override func didLoad() {
        super.didLoad()
        self.topBgNode.backgroundColor = UIColor.blue
        self.addSubnode(self.topBgNode)
        
        self.gradientLayer.startPoint = CGPoint(x: 0, y: 0.58)
        self.gradientLayer.endPoint = CGPoint(x: 1, y: 0.57)
        self.gradientLayer.colors = [UIColor(hexString: "#FF5351FF")!.cgColor , UIColor(hexString: "#FF8F00FF")!.cgColor]
        self.gradientLayer.locations = [0, 1.0]
        self.topBgNode.layer.addSublayer(self.gradientLayer)
        
        self.addSubnode(self.networkNode)
        let networkTap = UITapGestureRecognizer(target: self, action: #selector(networkTapClick(tap:)))
        self.networkNode.view.addGestureRecognizer(networkTap)
        



        
        let image = UIImage(named: "Nav/nav_close_icon")
        image?.withTintColor(UIColor.white, renderingMode: .alwaysTemplate)
        self.closeButton.tintColor = .white
        self.closeButton.setImage(image, for: .normal)
        self.closeButton.layer.cornerRadius = 17
        self.closeButton.backgroundColor = UIColor(hexString: "#66000000")
        self.view.addSubview(self.closeButton)
        self.closeButton.addTarget(self, action: #selector(closeClick(button:)), for: .touchUpInside)
        
        self.avatarBgNode.cornerRadius = 50
        self.avatarBgNode.borderColor = UIColor(hexString: "#FF6AABFD")!.cgColor
        self.avatarBgNode.borderWidth = 0.5
        self.avatarBgNode.backgroundColor = UIColor.white
        self.addSubnode(self.avatarBgNode)
        
        self.avatarNode.contentMode = .scaleAspectFit
        self.avatarNode.layer.cornerRadius = 46
        self.avatarNode.layer.masksToBounds = true
        self.avatarBgNode.view.addSubview(self.avatarNode)
        if self.isMe {
            self.walletInfoNode.turnNode.image = UIImage(named: "TBWebPage/icon_change_address_wallet")
        } else {
            self.walletInfoNode.turnNode.image = UIImage(named: "TBWallet/line_copy")
        }
        self.addSubnode(self.walletInfoNode)
        let walletTap = UITapGestureRecognizer(target: self, action: #selector(walletChangeClick(tap:)))
        self.walletInfoNode.view.addGestureRecognizer(walletTap)
        self.addSubnode(self.tgUserIdNode)
        
        self.addSubnode(self.moneyNode)
        
        
        let width = UIScreen.main.bounds.width
        let topBgHeight = 140.0
        self.topBgNode.frame = CGRect(x: 0, y: 0, width: width, height: topBgHeight)
        self.gradientLayer.frame = CGRect(x: 0, y: 0, width: width, height: topBgHeight)
        self.networkNode.frame = CGRect(x: 16, y: 48, width: 300, height: 24)

        self.closeButton.frame = CGRect(x: width - 16 - 34, y: 46, width: 34, height: 34)
        self.avatarBgNode.frame = CGRect(x: 16, y: 90, width: 100, height: 100)
        self.avatarNode.frame = CGRect(x: 4, y: 4, width: 92, height: 92)
        self.walletInfoNode.frame = CGRect(x: width - 162 - 16, y: topBgHeight + 10, width: 162, height: 30)
        self.tgUserIdNode.frame = CGRect(x: 24, y: topBgHeight + 60, width: 300, height: 16)
        self.moneyNode.frame = CGRect(x: 24, y: topBgHeight + 80, width: width - 48, height: 24)
        
        if isMe {
            self.searchNode.frame = CGRect(x: 16, y: topBgHeight + 119, width: width - 32, height: 40)
            self.addSubnode(self.searchNode)
        } else {
            self.networkInfoNode.frame = CGRect(x: 0, y: topBgHeight + 119, width: width, height: 92)
            self.addSubnode(self.networkInfoNode)
        }
        
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let networkRect = CGRectInset(self.networkNode.frame, 0, -5)

        if CGRectContainsPoint(networkRect, point) {
            return self.networkNode.view
        }



        return super.hitTest(point, with: event)
    }
    
    func endEdit() {
        self.searchNode.endEdit()
    }
    
    func updateNetwork(_ network: TBWeb3ConfigEntry.Chain?) {
        if let network = network {
            self.networkNode.isHidden = false
            self.networkNode.updateNetwork(network)
        } else {
            self.networkNode.isHidden = true
        }
    }
    
    func updateAddress(_ address: String?) {
        self.walletInfoNode.updateAddress(address)
        self.walletInfoNode.isHidden = address == nil
    }
    
    func updateWalletInfo(info: TBWalletInfo?) {
        if let url = info?.nft_contract_image, !url.isEmpty {
            self.avatarNode.sd_setImage(with: URL(string: url), placeholderImage: UIImage(named:"TBWebPage/avatar_nft"))
        } else {
            self.avatarNode.image = UIImage(named:"TBWebPage/avatar_nft")
        }
        self.networkInfoNode.updateWalletInfo(info: info)
    }
    
    func updateAvatarByImage(_ img: UIImage?) {
        if let img = img {
            self.avatarNode.image = img
        } else {
            self.avatarNode.image = UIImage(named:"TBWebPage/avatar_nft")
        }
    }
    
    func updateUserName(_ name: String?) {
        if let name = name {
            self.tgUserIdNode.isHidden = false
            self.tgUserIdNode.attributedText = NSAttributedString(string: "@" + name, font: Font.medium(13), textColor: UIColor(hexString: "#FF56565C")!, paragraphAlignment: .left)
        } else {
            self.tgUserIdNode.isHidden = true
        }
    }
    
    @objc func networkTapClick(tap: UITapGestureRecognizer) {
        self.networkEvent?()
    }
    
    @objc func closeClick(button: UIButton) {
        self.closeEvent?()
    }
    
    @objc func avatarSettingClick(tap: UITapGestureRecognizer) {
        self.avatarSettingEvent?()
    }
    
    @objc func walletChangeClick(tap: UITapGestureRecognizer) {
        if let address = self.walletInfoNode.address {
            self.walletChangeEvent?(address)
        }
    }
    
}


class WebPageNavNode: ASDisplayNode {
    private let context: AccountContext
    private var presentationData: PresentationData
    
    private let networkNode: WebNetworkNode
    private let avatarNode: UIImageView
    private let closeButton: UIButton
    
    var networkEvent: (() -> ())?
    var closeEvent: (() -> ())?
    
    init(context: AccountContext, presentationData: PresentationData) {
        self.context = context
        self.presentationData = presentationData
        self.networkNode = WebNetworkNode(context: context, presentationData: presentationData)
        self.closeButton = UIButton(type: .custom)
        self.avatarNode = UIImageView()
        super.init()
    }
    
    
    override func didLoad() {
        super.didLoad()
        
        self.addSubnode(self.networkNode)
        let networkTap = UITapGestureRecognizer(target: self, action: #selector(networkTapClick(tap:)))
        self.networkNode.view.addGestureRecognizer(networkTap)
        
        self.avatarNode.layer.cornerRadius = 20
        self.avatarNode.layer.masksToBounds = true
        self.avatarNode.contentMode = .scaleAspectFill
        self.view.addSubview(self.avatarNode)
        
        let image = UIImage(named: "Nav/nav_close_icon")
        image?.withTintColor(UIColor.black, renderingMode: .alwaysTemplate)
        self.closeButton.tintColor = .black
        self.closeButton.setImage(image, for: .normal)
        self.view.addSubview(self.closeButton)
        self.closeButton.addTarget(self, action: #selector(closeClick(button:)), for: .touchUpInside)
    }
    
    func update(size: CGSize, transition: ContainedViewLayoutTransition) {
        let width = size.width
        self.networkNode.frame = CGRect(x: 16, y: 48, width: 300, height: 24)
        self.closeButton.frame = CGRect(x: width - 16 - 34, y: 46, width: 34, height: 34)
        self.avatarNode.frame = CGRect(x: width / 2.0 - 20, y: 42, width: 40, height: 40)
    }
    
    func updateNetwork(_ network: TBWeb3ConfigEntry.Chain?) {
        if let network = network {
            self.networkNode.isHidden = false
            self.networkNode.updateNetwork(network, themeColor: UIColor.black)
        } else {
            self.networkNode.isHidden = true
        }
    }
    
    func updateAvatarByImage(_ img: UIImage?) {
        if let img = img {
            self.avatarNode.image = img
        } else {
            self.avatarNode.image = UIImage(named:"TBWebPage/avatar_nft")
        }
    }
    
    func updateAvatarByUrl(_ url: String) {
        self.avatarNode.sd_setImage(with: URL(string: url), placeholderImage: UIImage(named:"TBWebPage/avatar_nft"))
    }
    
    @objc func networkTapClick(tap: UITapGestureRecognizer) {
        self.networkEvent?()
    }
    
    @objc func closeClick(button: UIButton) {
        self.closeEvent?()
    }
    
}
