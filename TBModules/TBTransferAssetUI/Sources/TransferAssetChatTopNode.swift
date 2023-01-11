
import UIKit
import Display
import Postbox
import SDWebImage
import AccountContext
import AsyncDisplayKit
import SwiftSignalKit
import TelegramPresentationData
import TBWeb3Core

public class TransferAssetChatTopNode: ASDisplayNode {
    private let context: AccountContext
    private let peerId: PeerId
    private let blurredNode: ASDisplayNode
    private let scrollNode: ASScrollNode

    public var networkSelectedEvent: ((TBWeb3ConfigEntry.Chain)->())?
    public var toNetworkInfo: NetworkInfo?
    public init(context: AccountContext, peerId: PeerId) {
        self.context = context
        self.peerId = peerId
        self.blurredNode = ASDisplayNode()
        self.scrollNode = ASScrollNode()
        super.init()
        let networkInfo = TBTransferAssetInteractor.fetchNetworkInfo(by: peerId.id.description) |> `catch` { _ -> Signal<NetworkInfo, NoError> in
            return .single(NetworkInfo())
        }
        let _ = combineLatest(networkInfo,
                              TBWeb3Config.shared.configSignal).start(next: {[weak self] info, config  in
            if let config = config, info.tg_user_id.count > 0, info.is_bind_wallet > 0 {
                self?.updateFilterItems(by: info, config: config)
            }
        })
        let presentationData = (context.sharedContext.currentPresentationData.with { $0 })
        self.blurredNode.backgroundColor = presentationData.theme.rootController.navigationBar.blurredBackgroundColor
        self.isHidden = true
    }
    
    
    public override func didLoad() {
        super.didLoad()
        self.blurredNode.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44)
        self.addSubnode(self.blurredNode)
        self.scrollNode.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44)
        self.scrollNode.scrollableDirections = [.left, .right]
        self.scrollNode.view.showsVerticalScrollIndicator = false
        self.scrollNode.view.showsHorizontalScrollIndicator = false
        self.addSubnode(self.scrollNode)
    }
    
    
    func updatePresentationData(_ presentationData: PresentationData) {
        
    }
    
    
    func update(layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        
    }

    typealias NetworkFilter = (chain: TBWeb3ConfigEntry.Chain, node: ChatTitleNode, frame: CGRect, margin: CGFloat)
    
    private var filters = [NetworkFilter]()
    func updateFilterItems(by networkInfo: NetworkInfo, config: TBWeb3ConfigEntry) {
        self.toNetworkInfo = networkInfo
        for filter in self.filters {
            filter.node.removeFromSupernode()
        }
        self.filters = [NetworkFilter]()
        var chains = [TBWeb3ConfigEntry.Chain]()
        for chain in networkInfo.chain_record {
            let id = chain.chain_id
            if let chain = config.chainType.filter({$0.id == id}).first {
                chains.append(chain)
            }
        }
        if chains.count < 1 { return }
        self.isHidden = chains.count < 1
        let margin: CGFloat = 16
        let space: CGFloat = 8
        let screenWidth = UIScreen.main.bounds.width
        let preItemWidth: CGFloat
        switch chains.count {
        case 1:
            preItemWidth = screenWidth - 2 * margin
        case 2:
            preItemWidth = (screenWidth - 2 * margin - space) / 2.0
        case 3:
            preItemWidth = (screenWidth - 3 * margin - 2 * space) / 2.0
        default:
            preItemWidth = 110
        }
        var nextNodeStartX: CGFloat = margin
        for item in chains {
            let node = ChatTitleNode(context: self.context)
            node.tapEventHandle = {[weak self] in
                self?.networkSelectedEvent?(item)
            }
            let width = node.updateNetwork(item.name, icon: item.icon)
            let itemWidth = max(preItemWidth, width + 24)
            self.filters.append(NetworkFilter(item , node, CGRect(x: nextNodeStartX, y: 9, width: itemWidth, height: 28), (itemWidth - width) / 2))
            nextNodeStartX += (itemWidth + space)
        }
        let gWidth = nextNodeStartX - space + margin
        self.scrollNode.view.contentSize = CGSize(width: gWidth, height: 44)
        let transition = ContainedViewLayoutTransition.animated(duration: 0.22, curve: .easeInOut)
        for filter in self.filters {
            self.scrollNode.addSubnode(filter.node)
            transition.updateFrame(node: filter.node, frame: filter.frame)
            filter.node.update(size: filter.frame.size, margin: filter.margin, transition: transition)
        }
    }
}

class ChatTitleNode: ASDisplayNode {
    
    private let context: AccountContext
    private let iconWidth: CGFloat
    private let space: CGFloat
    
    private let iconNode: UIImageView
    private let nameNode: ASTextNode
    
    var tapEventHandle: (()->())?
    
    init(context: AccountContext, iconWidth: CGFloat = 20, space: CGFloat = 4) {
        self.context = context
        self.iconWidth = iconWidth
        self.space = space
        
        self.iconNode = UIImageView()
        self.nameNode = ASTextNode()
        
        super.init()
        self.backgroundColor = UIColor(hexString: "#0A000000")
    }
    
    override func didLoad() {
        super.didLoad()
        self.cornerRadius = 14
        self.iconNode.contentMode = .scaleAspectFit
        self.view.addSubview(self.iconNode)
        self.addSubnode(self.nameNode)
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapEvent(tap:)))
        self.view.addGestureRecognizer(tap)
    }
    
    func updateNetwork(_ title: String, icon: String) -> CGFloat {
        if let url = URL(string: icon) {
            self.iconNode.sd_setImage(with: url)
        }
        self.nameNode.attributedText = NSAttributedString(string: title, font: Font.regular(13), textColor: UIColor(hexString: "#FF787878")!, paragraphAlignment: .left)
        let size = self.nameNode.updateLayout(CGSize(width: 200.0, height: .greatestFiniteMagnitude))
        return self.iconWidth + self.space + size.width
    }
    
    func update(size: CGSize, margin: CGFloat, transition: ContainedViewLayoutTransition) {
        self.iconNode.frame = CGRect(x: margin, y: (size.height - self.iconWidth) / 2.0, width: self.iconWidth, height: self.iconWidth)
        self.nameNode.frame = CGRect(x: margin + self.iconWidth + self.space, y: (size.height - 17) / 2.0, width: size.width - 2 * margin - self.space - self.iconWidth, height: 15)
    }
    
    @objc func tapEvent(tap: UITapGestureRecognizer) {
        self.tapEventHandle?()
    }
    
}
