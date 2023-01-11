import UIKit
import SwiftSignalKit
import AsyncDisplayKit
import Display
import TelegramCore
import TelegramPresentationData
import AccountContext
import SegementSlide
import TBWeb3Core
import TBWalletCore
import TBDisplay
import Postbox
import TBNetwork
import HandyJSON
import AvatarNode
import ProgressHUD
import SDWebImage
import TBLanguage
import TBAccount

public class TBMyWebController: ViewController {
    
    public let context: AccountContext
    private var presentationData: PresentationData
    private let presentationDataValue = Promise<PresentationData>()
    private var presentationDataDisposable: Disposable?
    private let segmentVC: TBMyWebSegmentController
    private let nav: WebPageNavNode
    private let peerId: PeerId?
    private let isMe: Bool
    private var connect: TBWalletConnect?
    
    private var web3Config: TBWeb3ConfigEntry? {
        didSet {
            guard let relConfig = web3Config, relConfig.chainType.count > 0 else {
                self.currentNetwork = nil
                return
            }
            if let network = self.currentNetwork, relConfig.chainType.contains(network) {
                
            } else {
                self.currentNetwork = relConfig.chainType.first
            }
        }
    }
    
    private var currentNetwork: TBWeb3ConfigEntry.Chain? {
        didSet {
            self.segmentVC.headerNode.updateNetwork(currentNetwork)
            self.nav.updateNetwork(currentNetwork)
            if currentNetwork != oldValue {
                self.networkPromise.set(.single(currentNetwork))
            }
        }
    }
    
    private let addressPromise: Promise<String?>
    private let networkPromise: Promise<TBWeb3ConfigEntry.Chain?>
    
    public init(context: AccountContext, peerId: PeerId? = nil, address: String? = nil, isMe: Bool = true) {
        self.context = context
        
        self.presentationData = (context.sharedContext.currentPresentationData.with { $0 })
        self.presentationDataValue.set(.single(self.presentationData))
        
        self.segmentVC = TBMyWebSegmentController(context: context, presentationData: presentationData, isMe:  isMe)
        self.nav = WebPageNavNode(context: context, presentationData: presentationData)
        self.nav.backgroundColor = UIColor.white
        self.nav.alpha = 0.0
        self.addressPromise = Promise()
        self.networkPromise = Promise()
        self.peerId = isMe ? context.account.peerId : peerId
        self.isMe = isMe
        
        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData))
        self.navigationBar?.isHidden = true
        
        let _ = (TBWeb3Config.shared.configSignal |> deliverOnMainQueue).start(next: {[weak self] config in
            guard let strongSelf = self else { return }
            strongSelf.web3Config = config
        })
        
        if !isMe {
            self.addressPromise.set(.single(address))
        } else {
            let _ = TBWalletConnectManager.shared.availabelConnectionsSignal.start(next: {[weak self] connect in
                guard let strongSelf = self else { return }
                strongSelf.connect = connect.first
                strongSelf.addressPromise.set(.single(connect.first?.getAccountId()))
            })
        }
        
        let _ = (self.addressPromise.get() |> deliverOnMainQueue).start(next: {[weak self] address in
            guard let strongSelf = self else { return }
            strongSelf.segmentVC.headerNode.updateAddress(address)
        })
        
        let _ = (combineLatest(self.addressPromise.get(),
                               self.networkPromise.get())
                 |> deliverOnMainQueue).start(next: {[weak self] address, chain in
            guard let strongSelf = self else { return }
            strongSelf.segmentVC.updateConfig(chain: chain, address: address)
        })
        
        let _ = (self.addressPromise.get() |> mapToSignal({ address -> Signal<[TBWalletInfo], NoError>  in
            return MyWebInteractor.fetchWalletInfo(address: address ?? "")
        })).start(next: {[weak self] infos in
            guard let strongSelf = self else { return }
            let pId = strongSelf.peerId?.id.description
            var info: TBWalletInfo? = infos.first
            if let p = pId, let v = infos.filter({ $0.tg_user_id == p }).first {
                info = v
            }
            strongSelf.segmentVC.headerNode.updateWalletInfo(info: info)
            if let imgUrl = info?.nft_contract_image, imgUrl.isEmpty == false {
                strongSelf.nav.updateAvatarByUrl(imgUrl)
                strongSelf.updateUserInfo(onlyName: true)
            } else {
                strongSelf.updateUserInfo(onlyName: false)
            }
        })
    }
    
    func updateUserInfo(onlyName: Bool) {
        if let peerId = self.peerId {
            let _ = (self.context.account.viewTracker.peerView(peerId, updateData: true)
                     |> deliverOnMainQueue).start { [weak self] peerView in
                guard let strongSelf = self else { return }
                let user = peerView.peers[peerView.peerId] as? TelegramUser
                let name = strongSelf.userName(user: user)
                if onlyName {
                    strongSelf.segmentVC.headerNode.updateUserName(name)
                } else {
                    strongSelf.segmentVC.headerNode.updateUserName(name)
                    strongSelf.updateAvatarBy(user)
                }
            }
        }
    }
    
    func userName(user: TelegramUser?) -> String? {
        guard let user = user else { return nil }
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
        return name.isEmpty ? nil : name
    }
    
    func updateAvatarBy(_ user: TelegramUser?) {
        if let user = user {
            let peer = EnginePeer(user)
            if let signal = peerAvatarImage(account: self.context.account, peerReference: PeerReference(peer._asPeer()), authorOfMessage: nil, representation: peer.smallProfileImage, displayDimensions: CGSize(width: 40,height: 40)) {
                let _ = signal.start {[weak self] a in
                    self?.updateAvaterImage(image: a?.0)
                }
            }else {
                self.updateAvaterImage(image: nil)
            }
        } else {
            self.updateAvaterImage(image: nil)
        }
    }
    
    func updateAvaterImage(image: UIImage?) {
        DispatchQueue.main.async {
            self.segmentVC.headerNode.updateAvatarByImage(image)
            self.nav.updateAvatarByImage(image)
        }
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.presentationDataDisposable?.dispose()
    }
    
    public override func displayNodeDidLoad() {
        super.displayNodeDidLoad()
        self.addChild(self.segmentVC)
        self.view.addSubview(self.segmentVC.view)
        self.segmentVC.didMove(toParent: self)
        self.displayNode.addSubnode(self.nav)
        self.segmentVC.headerNode.networkEvent = { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.segmentVC.headerNode.endEdit()
            strongSelf.popNetwork()
        }
        
        self.segmentVC.headerNode.closeEvent = { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.segmentVC.headerNode.endEdit()
            strongSelf.navigationController?.popViewController(animated: true)
        }
        
        self.segmentVC.headerNode.avatarSettingEvent = { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.segmentVC.headerNode.endEdit()
        }
        
        self.segmentVC.headerNode.walletChangeEvent = { [weak self] address in
            guard let strongSelf = self else { return }
            strongSelf.segmentVC.headerNode.endEdit()
            if strongSelf.isMe {
                let popVc = TBPopController(context: strongSelf.context, canCloseByTouches: true)
                let node = TBWalletPopNode()
                let size = node.updateSegment(address: address.simpleAddress())
                node.cornerRadius = 12
                node.backgroundColor = UIColor.white
                node.closeEvent = {[weak popVc] in
                    popVc?.dismiss(animated: true)
                }
                node.selectedSegmentEvent = {[weak popVc, weak self] segemnt in
                    guard let strongSelf = self else { return }
                    strongSelf.dealWith(action: segemnt.action, address: address)
                    popVc?.dismiss(animated: true)
                }
                let screenSize = UIScreen.main.bounds.size
                popVc.setContentNode(node, frame: CGRect(origin: CGPoint(x: (screenSize.width - size.width) / 2, y: (screenSize.height - size.height) / 2), size: size))
                popVc.pop(from: strongSelf, transition: .immediate)
                DispatchQueue.main.async {
                    node.updateLayout(size: size)
                    node.updateData()
                }
            } else {
                strongSelf.dealWith(action: .copy, address: address)
            }
        }
        
        self.segmentVC.headerNode.searchNode.checkAddressEvent = { [weak self] text in
            guard let strongSelf = self else { return }
            let vc = strongSelf.context.sharedContext.makeMyWebPageController(context: strongSelf.context, peerId: nil, address: text, isMe: false)
            strongSelf.navigationController?.pushViewController(vc, animated: true)
        }
        
        self.segmentVC.headPercent = { [weak self] percent in
            guard let strongSelf = self else { return }
            strongSelf.nav.alpha = percent
        }
        
        self.segmentVC.nftVc.nftAvatarSelected = { [weak self] item in
            guard let strongSelf = self else { return }
            strongSelf.present(standardTextAlertController(theme: AlertControllerTheme(presentationData: strongSelf.presentationData), title: nil, text: TBLanguage.sharedInstance.localizable(TBLankey.wallet_home_use_nft_avatar), actions: [TextAlertAction(type: .genericAction, title: TBLanguage.sharedInstance.localizable(TBLankey.dialog_clean_tv_cancel), action: {
                
            }), TextAlertAction(type: .defaultAction, title: TBLanguage.sharedInstance.localizable(TBLankey.translate_dialog_close), action: {[weak self] in
                guard let strongSelf = self else { return }
                strongSelf.updateAvatar(item: item)
            })]), in: .window(.root))
        }
        
        self.nav.networkEvent = { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.segmentVC.headerNode.endEdit()
            strongSelf.popNetwork()
        }
        
        self.nav.closeEvent = { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.segmentVC.headerNode.endEdit()
            strongSelf.navigationController?.popViewController(animated: true)
        }
    }
    
    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        let y = 0.0
        self.segmentVC.view.frame = CGRect(origin:CGPoint(x: 0, y: y), size: CGSize(width: layout.size.width, height: layout.size.height - y))
        self.nav.frame = CGRect(x: 0, y: y, width: layout.size.width, height: 100)
        self.nav.update(size: CGSize(width: layout.size.width, height: 100), transition: transition)
    }
        
    func popNetwork() {
        guard let config = self.web3Config,
            let currentChain = self.currentNetwork,
            let index = config.chainType.firstIndex(of: currentChain) else { return }
        let popVc = TBPopController(context: self.context, canCloseByTouches: true)
        let node = TBSegmentNode()
        let size = node.updateSegment(title: "Networks", items: config.chainType, selectedIndex: index)
        node.cornerRadius = 12
        node.backgroundColor = UIColor.white
        node.closeEvent = {[weak popVc] in
            popVc?.dismiss(animated: true)
        }
        node.selectedSegmentEvent = {[weak popVc, weak self] chain in
            self?.currentNetwork = chain as? TBWeb3ConfigEntry.Chain
            popVc?.dismiss(animated: true)
        }
        let screenSize = UIScreen.main.bounds.size
        popVc.setContentNode(node, frame: CGRect(origin: CGPoint(x: (screenSize.width - size.width) / 2, y: (screenSize.height - size.height) / 2), size: size))
        popVc.pop(from: self, transition: .immediate)
        DispatchQueue.main.async {
            node.updateLayout(size: size)
            node.updateData()
        }
    }
    
    func dealWith(action: WalletAction, address: String) {
        switch action {
        case .copy:
            if !address.isEmpty {
                UIPasteboard.general.string = address
                ProgressHUD.showSucceed(TBLanguage.sharedInstance.localizable(TBLankey.wallet_home_copy_address))
            }
        case .disConnect:
            if let c = self.connect {
                self.navigationController?.popViewController(animated: true)
                TBWalletConnectManager.shared.disconnect(connect: c)
            }
        case .view:
            if let network = self.currentNetwork {
                switch network.getChainType() {
                case .ETH:
                    self.jumpToChat(by: "https://etherscan.io/address/" + address)
                case .OS:
                    self.jumpToChat(by: "https://explorer.emerald.oasis.dev/" + address)
                case .TT:
                    self.jumpToChat(by: "https://viewblock.io/thundercore/address/" + address)
                case .Polygon:
                    self.jumpToChat(by: "https://polygonscan.com/address/" + address)
                case .unkonw:
                    break
                }
            }
        case .change:
            TBWalletConnectManager.shared.connectToPlatform(platform: .metaMask)
            break
        }
    }
    
    func jumpToChat(by urlStr: String) {
        if let url = URL(string: urlStr) {
            let vc = TBWebviewController(context: self.context, webUrl: url)
            self.push(vc)
        }
    }
    
    func updateAvatar(item: TBNFTItem) {
        if let url = URL(string: item.nftContractImage()) {
            ProgressHUD.show(TBLanguage.sharedInstance.localizable(TBLankey.setting_Downloading_original_image_please_wait))
            SDWebImageDownloader.shared.downloadImage(with: url) {[weak self] image, _, error, _ in
                guard let strongSelf = self else { return }
                if let image = image {
                    let settingId = Date().timeIntervalSince1970
                    let nftSettingItem = NFTSettingItem(image: image, config: item, settingId: settingId)
                    TBAccount.shared.nftSettingPromise.set(.single(nftSettingItem))
                    strongSelf.updateAvaterImage(image: image)
                    ProgressHUD.dismiss()
                }else if let error = error {
                    ProgressHUD.showError("\(error.localizedDescription)")
                }
            }
        }
    }
}

private class MyWebInteractor {
    
    class func fetchWalletInfo(address: String) -> Signal<[TBWalletInfo], NoError> {
        return Signal { subscriber in
            TBNetwork.request(api: "/user/wallet/info",
                              method: .post,
                              paramsFillter: ["wallet_address" : address, "wallet_type" : "metamask"],
                              successHandle: { data, message in

                if let arr = data as? [Any], let infos = JSONDeserializer<TBWalletInfo>.deserializeModelArrayFrom(array: arr) as? [TBWalletInfo] {
                    subscriber.putNext(infos)
                } else {
                    subscriber.putNext([])
                }
                subscriber.putCompletion()
            }, failHandle: { code, message in
                subscriber.putNext([])
                subscriber.putCompletion()
            })
            return EmptyDisposable
        }
    }
}


struct TBWalletInfo: HandyJSON {
    var id: String = ""
    var chain_id: String = ""
    var nft_price: String = ""
    var nft_token_standard: String = ""
    var tg_user_id: String = ""
    var nft_photo_id: String = ""
    var nft_contract: String = ""
    var nft_chain_id: String = ""
    var nft_name: String = ""
    var nft_contract_image: String = ""
    var nft_token_id: String = ""
}
