
import UIKit
import Display
import AccountContext
import AsyncDisplayKit
import TelegramPresentationData
import TBLanguage

enum AGToolItemType {
    case qr
    case filter
    case invite
    case group
}

enum AGToolsType {
    case group
    case media
    case quotation
}

struct AGTool {
    let type: AGToolsType
    let icon: String
    let name: String
    let url: String
}

fileprivate func toolItems(itemTypes: [AGToolItemType]) -> [TBToolItem<AGToolItemType>] {
    var rel = [TBToolItem<AGToolItemType>]()
    for itemType in itemTypes {
        let d: TBToolItem<AGToolItemType>
        switch itemType {
        case .qr:
            d = TBToolItem<AGToolItemType>(type: .qr, title: TBLanguage.sharedInstance.localizable(TBLankey.commontools_scan_qrcode),iconName: "Tools/icon_qrcode_good_tools",color: UIColor(hexString: "#FF4B5BFF"))
        case .invite:
            d = TBToolItem<AGToolItemType>(type: .invite, title: TBLanguage.sharedInstance.localizable(TBLankey.commontools_add_friend),iconName: "Tools/icon_invite_friends_good_tools",color: UIColor(hexString: "#FF4B5BFF"))
        case .filter:
            d = TBToolItem<AGToolItemType>(type: .filter, title: TBLanguage.sharedInstance.localizable(TBLankey.view_home_message_folder),iconName: "Tools/icon_message_goroup_good_tools",color: UIColor(hexString: "#FF4B5BFF"))
        case .group:
            d = TBToolItem<AGToolItemType>(type: .group, title: TBLanguage.sharedInstance.localizable(TBLankey.commontools_official_channel),iconName: "Tools/official Group",color: UIColor(hexString: "#FF4B5BFF"))
        }
        rel.append(d)
    }
    return rel
}

fileprivate func groupIools() -> [AGTool] {
    let alphagram = AGTool(type: .group, icon: "Tools/Alpha", name: "alphagram", url: "https://t.me/alphagramgroup")
    let Solana = AGTool(type: .group, icon: "Tools/Solana", name: "Solana", url: "https://t.me/solana")
    let Binance = AGTool(type: .group, icon: "Tools/binan", name: "Binance", url: "https://t.me/BinanceExchange")
    let OKX = AGTool(type: .group, icon: "Tools/OKx", name: "OKX", url: "https://t.me/OKXOfficial_English")
    let FTX = AGTool(type: .group, icon: "Tools/Ftx", name: "FTX", url: "https://t.me/FTX_Official")
    let STEPN = AGTool(type: .group, icon: "Tools/Stepn", name: "STEPN", url: "https://t.me/STEPNofficial")
    let ThunderCore = AGTool(type: .group, icon: "Tools/Tt", name: "ThunderCore", url: "https://t.me/thunder_official")
    let Oasis = AGTool(type: .group, icon: "Tools/Oasis", name: "Oasis", url: "https://t.me/oasisprotocolcommunity")
    let Tron = AGTool(type: .group, icon: "Tools/Tron", name: "Tron", url: "https://t.me/tronnetworkEN")
    let AxieInfinity = AGTool(type: .group, icon: "Tools/Axie", name: "Axie Infinity", url: "https://t.me/axieinfinity")
    let Aptos = AGTool(type: .group, icon: "Tools/aptos", name: "Aptos", url: "https://t.me/aptos_official")
    let Polygon = AGTool(type: .group, icon: "Tools/polygon", name: "Polygon", url: "https://t.me/polygonofficial")
    return [alphagram, Solana, Binance, OKX, FTX, STEPN, ThunderCore, Oasis, Tron, AxieInfinity, Aptos, Polygon]
}

fileprivate func mediaTools() -> [AGTool] {
    let a16z = AGTool(type: .media, icon: "Tools/a16z", name: "a16z", url: "https://a16z.com/")
    let CoinDesk = AGTool(type: .media, icon: "Tools/CoinDesk", name: "CoinDesk", url: "https://www.coindesk.com/")
    let PlayToEarn = AGTool(type: .media, icon: "Tools/playtoearn", name: "Play to Earn Online", url: "https://www.playtoearn.online/")
    let CryptoCoins = AGTool(type: .media, icon: "Tools/CryptoCoinsNews", name: "CryptoCoins.News", url: "https://cryptocoin.news/")
    return [a16z, CoinDesk, PlayToEarn, CryptoCoins]
}

fileprivate func quotationTools() -> [AGTool] {
    let CoinMarketCap = AGTool(type: .quotation, icon: "Tools/Coinmarketcap", name: "CoinMarketCap", url: "https://coinmarketcap.com/")
    let Dune = AGTool(type: .quotation, icon: "Tools/dune", name: "Dune", url: "https://dune.com/browse/dashboards")
    let CryptoRank = AGTool(type: .quotation, icon: "Tools/cryptorank", name: "CryptoRank", url: "https://cryptorank.io/")
    let Nansen = AGTool(type: .quotation, icon: "Tools/nansen", name: "Nansen", url: "https://pro.nansen.ai/multichain/eth")
    return [CoinMarketCap, Dune, CryptoRank, Nansen]
}

fileprivate func toolItems(by type: AGToolsType) -> [TBToolItem<AGTool>] {
    var rel = [TBToolItem<AGTool>]()
    let tools: [AGTool] = {
        switch type {
        case .group:
            return groupIools()
        case .media:
            return mediaTools()
        case .quotation:
            return quotationTools()
        }
    }()
    for tool in tools {
        let toolItem = TBToolItem<AGTool>(type: tool, title: tool.name, iconName: tool.icon, color: nil, url: tool.url)
        rel.append(toolItem)
    }
    return rel
}

class HeaderReusableView: UICollectionReusableView {
    
    private let titleNode: ASTextNode
    
    override init(frame: CGRect) {
        self.titleNode = ASTextNode()
        super.init(frame: frame)
        self.setUpUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setUpUI() {
        self.addSubnode(self.titleNode)
        self.titleNode.frame = CGRect(x: 24, y: 12, width: 300, height: 22)
    }
    
    func updateTitle(title: String) {
        self.titleNode.attributedText = NSAttributedString(string: title, font: Font.medium(16), textColor: UIColor.black, paragraphAlignment: .left)
    }
    
}

let itemSize = CGSize(width: (UIScreen.main.bounds.width - 50 - 4 * 3) / 4, height: 96)
class AGGroupToolItemCell<T>: UICollectionViewCell {
    
    lazy var itemNode: AGToolItemNode<T> = {
        let theme = TBItemNodeTheme(itemsize: itemSize, bgSize: CGSize(width: 52, height: 52), imageSize: CGSize(width: 52, height: 52))
        return AGToolItemNode<T>(itemTheme: theme, isCycle: true)
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.itemNode.isUserInteractionEnabled = false
        self.itemNode.frame = CGRect(origin: .zero, size: itemSize)
        self.addSubnode(self.itemNode)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


fileprivate class SectionZeroNode: ASDisplayNode {
    
    private let context: AccountContext
    private var presentationData: PresentationData
    
    
    private let contentNode: ASDisplayNode
    let cacheValueNode: ASTextNode
    let cacheSubNode: ASTextNode
    private let cleanButtonNode: ASButtonNode
    
    private var tools = [TBToolItem<AGToolItemType>]()
    private var items = [AGToolItemNode<AGToolItemType>]()
    
    private let cleanCacheEvent: () -> Void
    
    var toolClickEvent: ((AGToolItemType) -> Void)?
    var cacheValueAttr: NSAttributedString?

    init(context: AccountContext, presentationData: PresentationData, cleanCacheEvent: @escaping () -> Void) {
        self.context = context
        self.presentationData = presentationData
        self.cleanCacheEvent = cleanCacheEvent
        
        self.contentNode = ASDisplayNode()
        self.cacheValueNode = ASTextNode()
        self.cacheSubNode = ASTextNode()
        self.cleanButtonNode = ASButtonNode()
        super.init()
    }

    override func didLoad() {
        let size = CGSize(width: UIScreen.main.bounds.width, height: 260)
        
        self.contentNode.backgroundColor = UIColor(hexString: "#FFF7F8F9")
        self.contentNode.cornerRadius = 16
        self.addSubnode(self.contentNode)
        self.contentNode.frame = CGRect(x: 20, y: 8, width: size.width - 40, height: 107)

        if let attr = self.cacheValueAttr {
            self.cacheValueNode.attributedText = attr
        } else {
            self.cacheValueNode.attributedText = NSAttributedString(string: "--", font: Font.medium(33), textColor: UIColor.black, paragraphAlignment: .left)
        }
        self.contentNode.addSubnode(self.cacheValueNode)
        self.cacheValueNode.frame = CGRect(x: 12, y: 20, width: size.width / 1.7, height: 33)

        
        self.contentNode.addSubnode(self.cacheSubNode)
        self.cacheSubNode.frame = CGRect(x: 12, y: 65, width: 140, height: 15)

        self.cleanButtonNode.backgroundColor = UIColor(hexString: "#FF4B5BFF")
        self.cleanButtonNode.cornerRadius = 19
        self.contentNode.addSubnode(self.cleanButtonNode)
        self.cleanButtonNode.addTarget(self, action: #selector(cleanCacheevent), forControlEvents: .touchUpInside)
        self.cleanButtonNode.frame = CGRect(x: size.width - 157, y: 37, width: 100, height: 38)
        self.resetTools()
    }

    @objc func cleanCacheevent() {
        self.cleanCacheEvent()
    }
    
    func resetTools() {
        let size = CGSize(width: UIScreen.main.bounds.width, height: 260)
        
        self.tools = toolItems(itemTypes: [.qr, .filter, .invite, .group])
        for node in self.items {
            node.removeFromSupernode()
        }
        self.items.removeAll()
        let itemSize = CGSize(width: (size.width - 50 - 18 * 3) / 4, height: 100)
        let theme = TBItemNodeTheme(itemsize: itemSize, bgSize: CGSize(width: 52, height: 52), imageSize: CGSize(width: 30, height: 30))
        let themeSpecail = TBItemNodeTheme(itemsize: itemSize, bgSize: CGSize(width: 52, height: 52), imageSize: CGSize(width: 52, height: 52))
        for (index, tool) in self.tools.enumerated() {
            let toolNode: AGToolItemNode<AGToolItemType> = {
                if tool.type == .group {
                    return AGToolItemNode<AGToolItemType>(itemTheme: themeSpecail, isOfficial: false)
                } else {
                    return AGToolItemNode<AGToolItemType>(itemTheme: theme, isOfficial: false)
                }
            }()
            toolNode.updateNodeBy(tool)
            toolNode.clickEvent = {[weak self] type in
                self?.toolClickEvent?(type)
            }
            toolNode.frame = CGRect(x: 25 + (itemSize.width + 18) * CGFloat(index) , y: 139, width: itemSize.width, height: itemSize.height)
            self.addSubnode(toolNode)
            self.items.append(toolNode)
        }
    }
    
    func updateThemeAndStrings() {
        self.resetTools()
        self.cacheSubNode.attributedText = NSAttributedString(string: TBLanguage.sharedInstance.localizable(TBLankey.commontools_local_cache_size_tips), font: Font.regular(13), textColor: UIColor(hexString: "#56565C")!, paragraphAlignment: .left)
        self.cleanButtonNode.setTitle(TBLanguage.sharedInstance.localizable(TBLankey.commontools_oneclick_cleanup), with: Font.medium(13), with: UIColor.white, for: .normal)
    }
}

class AGToolsCenterControllerNode: ASDisplayNode {

    private let context: AccountContext
    private var presentationData: PresentationData

    private let collectionView: UICollectionView

    private let sectionZeroNode: SectionZeroNode
    
    private let groupToolItems: [TBToolItem<AGTool>]
    private let mediaToolItems: [TBToolItem<AGTool>]
    private let quotationToolItems: [TBToolItem<AGTool>]

    var toolClickEvent: ((AGToolItemType) -> Void)?
    var cleanCacheEvent: (()->Void)?
    var groupToolsClickEvent: ((AGTool) -> Void)?

    init(context: AccountContext, presentationData: PresentationData, cleanCacheEvent: @escaping () -> Void) {
        self.context = context
        self.presentationData = presentationData
        let layout = UICollectionViewFlowLayout()
        self.collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        self.cleanCacheEvent = cleanCacheEvent
        
        self.sectionZeroNode = SectionZeroNode(context: context, presentationData: presentationData, cleanCacheEvent: cleanCacheEvent)
        self.groupToolItems = toolItems(by: .group)
        self.mediaToolItems = toolItems(by: .media)
        self.quotationToolItems = toolItems(by: .quotation)
        
        super.init()
    }

    override func didLoad() {
        super.didLoad()
        
        self.collectionView.contentInsetAdjustmentBehavior = .never
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.backgroundColor = .white
        self.view.addSubview(self.collectionView)
        self.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "xx")
        self.collectionView.register(AGGroupToolItemCell<AGTool>.self, forCellWithReuseIdentifier: "group")
        self.collectionView.register(HeaderReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "header")
        self.collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "footer")
        
        self.sectionZeroNode.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 260)
        self.sectionZeroNode.toolClickEvent = { [weak self] a in
            self?.toolClickEvent?(a)
        }
    }

    func updateThemeAndStrings() {
        self.collectionView.reloadData()
        self.sectionZeroNode.updateThemeAndStrings()
    }
    
    func update(layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        let topHeight = (layout.statusBarHeight ?? 20) + layout.safeInsets.top
        let bottomHeight = layout.intrinsicInsets.bottom
        transition.updateFrame(view: self.collectionView, frame:  CGRect(x: 0, y: topHeight, width: layout.size.width, height: layout.size.height - topHeight - bottomHeight))
    }

    func updateCacheTotal(_ total: Int64) {
        let text = dataSizeString(total, formatting: DataSizeStringFormatting(presentationData: self.presentationData))
        let textArr = text.components(separatedBy: " ")
        let preText = textArr.first ?? ""
        var sufText = ""
        if textArr.count >= 2 {
            sufText = textArr.last!
        }
        if preText.count == 0 {
            return
        }
        let attr = NSMutableAttributedString(string: text, font: Font.medium(33), textColor: UIColor.black, paragraphAlignment: .left)
        if sufText.count > 0 {
            let range = NSRange(location: preText.count + 1, length: sufText.count)
            attr.addAttribute(.font, value: Font.regular(14), range: range)
            attr.addAttribute(.foregroundColor, value: UIColor(hexString: "#56565CFF")!, range: range)
        }
        self.sectionZeroNode.cacheValueAttr = attr
        self.sectionZeroNode.cacheValueNode.attributedText = attr
    }
}

extension AGToolsCenterControllerNode: UICollectionViewDelegate {
 
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            self.groupToolsClickEvent?(self.groupToolItems[indexPath.row].type)
        }
        if indexPath.section == 2 {
            self.groupToolsClickEvent?(self.mediaToolItems[indexPath.row].type)
        }
        if indexPath.section == 3 {
            self.groupToolsClickEvent?(self.quotationToolItems[indexPath.row].type)
        }
    }
}

extension AGToolsCenterControllerNode: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 4
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 1:
            return self.groupToolItems.count
        case 2:
            return self.mediaToolItems.count
        case 3:
            return self.quotationToolItems.count
        default:
            return 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "xx", for: indexPath)
            cell.addSubview(self.sectionZeroNode.view)
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "group", for: indexPath)  as! AGGroupToolItemCell<AGTool>
            if indexPath.section == 1 {
                cell.itemNode.updateNodeBy(self.groupToolItems[indexPath.row])
            } else if indexPath.section == 2 {
                cell.itemNode.updateNodeBy(self.mediaToolItems[indexPath.row])
            } else if indexPath.section == 3 {
                cell.itemNode.updateNodeBy(self.quotationToolItems[indexPath.row])
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "header", for: indexPath) as! HeaderReusableView
            header.backgroundColor = UIColor.white
            switch indexPath.section {
            case 0:
                header.updateTitle(title: TBLanguage.sharedInstance.localizable(TBLankey.ac_title_storage_clean))
            case 1:
                header.updateTitle(title: TBLanguage.sharedInstance.localizable(TBLankey.commontools_group_recommend))
            case 2:
                header.updateTitle(title: TBLanguage.sharedInstance.localizable(TBLankey.hot_header_media))
            default:
                header.updateTitle(title: TBLanguage.sharedInstance.localizable(TBLankey.hot_header_information))
            }
            return header
        default:
            let footer = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "footer", for: indexPath)
            footer.backgroundColor = indexPath.section == 3 ? UIColor.white : UIColor(hexString: "#FFF7F8F9")!
            return footer
        }
    }
}

extension AGToolsCenterControllerNode: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = UIScreen.main.bounds.width
        if indexPath.section == 0 {
            return CGSize(width: width, height: 260)
        } else {
            return CGSize(width: (width - 4 * 3 - 18) / 4, height: 96)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 16.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 4.0
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 8, left: 9, bottom: 0, right: 9)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: 46)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: 12)
    }
}

