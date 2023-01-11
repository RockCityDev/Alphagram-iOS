
import UIKit
import Display
import AccountContext
import AsyncDisplayKit
import TelegramPresentationData
import TBLanguage
import TBDisplay

enum TBToolItemType {
    
    enum Official {
        case group
        case chineseGroup
        case englishGroup
        case channel
    }
    
    case qr
    case transferAsset
    case invite
    case filter
    case source
    case group
    case chanal
    case official(type: Official)
}

fileprivate func toolItems(itemTypes: [TBToolItemType]) -> [TBToolItem<TBToolItemType>] {
    var rel = [TBToolItem<TBToolItemType>]()
    for itemType in itemTypes {
        let d: TBToolItem<TBToolItemType>
        switch itemType {
        case .qr:
            d = TBToolItem<TBToolItemType>(type: .qr, title: TBLanguage.sharedInstance.localizable(TBLankey.commontools_scan_qrcode),iconName: "Tools/icon_qrcode_good_tools",color: UIColor(hexString: "#46BDFE"))
        case .transferAsset:
            d = TBToolItem<TBToolItemType>(type: .transferAsset, title: TBLanguage.sharedInstance.localizable(TBLankey.transfer_activity_title),iconName: "Tools/alphagram_1-3_Index_alpha_trade",color: UIColor(hexString: "#FF3954D5"))
        case .invite:
            d = TBToolItem<TBToolItemType>(type: .invite, title: TBLanguage.sharedInstance.localizable(TBLankey.commontools_add_friend),iconName: "Tools/icon_invite_friends_good_tools",color: UIColor(hexString: "#3402FD"))
        case .filter:
            d = TBToolItem<TBToolItemType>(type: .filter, title: TBLanguage.sharedInstance.localizable(TBLankey.view_home_message_folder),iconName: "Tools/icon_message_goroup_good_tools",color: UIColor(hexString: "#AB61D9"))
        case .source:
            d = TBToolItem<TBToolItemType>(type: .source, title: TBLanguage.sharedInstance.localizable(TBLankey.commontools_resource_navigation),iconName: "Tools/icon_resource_good_tools",color: UIColor(hexString: "#43ABFD"))
        case .group:
            d = TBToolItem<TBToolItemType>(type: .group, title: TBLanguage.sharedInstance.localizable(TBLankey.commontools_group_recommend),iconName: "Tools/icon_groups_recommend_good_tools",color: UIColor(hexString: "#2F57D6"))
        case let .official(type):
            switch type {
            case .channel:
                d = TBToolItem<TBToolItemType>(type: .official(type: .channel), title:"Official Channel",iconName: "",color: UIColor.lightGray)
            case .group:
                d = TBToolItem<TBToolItemType>(type: .official(type: .group), title: "Official Group", iconName: "",color: UIColor.lightGray)
            case .chineseGroup:
                d = TBToolItem<TBToolItemType>(type: .official(type: .chineseGroup), title: TBLanguage.sharedInstance.localizable(TBLankey.commontools_official_group_ch),iconName: "Tools/icon_official_group_good_tools",color: UIColor.lightGray)
            case .englishGroup:
                d = TBToolItem<TBToolItemType>(type: .official(type: .englishGroup), title: TBLanguage.sharedInstance.localizable(TBLankey.commontools_official_group_ex),iconName: "Tools/icon_official_channel_good_tools",color: UIColor.lightGray)
            }
        case .chanal:
            d = TBToolItem<TBToolItemType>(type: .chanal, title: TBLanguage.sharedInstance.localizable(TBLankey.commontools_channel_recommend),iconName: "Tools/icon_channels_recommend_good_tools",color: UIColor(hexString: "#9100FF"))
        }
        rel.append(d)
    }
    return rel
}

fileprivate class TBCacheNode: ASDisplayNode {
    private let titleNode: ASTextNode
    private let contentNode: ASDisplayNode
    let cacheValueNode: ASTextNode
    private let cacheSubNode: ASTextNode
    private let cleanButtonNode: ASButtonNode
    private let cleanCacheEvent: () -> Void
    
    init(cleanCacheEvent: @escaping () -> Void) {
        self.cleanCacheEvent = cleanCacheEvent
        self.titleNode = ASTextNode()
        self.contentNode = ASDisplayNode()
        self.cacheValueNode = ASTextNode()
        self.cacheSubNode = ASTextNode()
        self.cleanButtonNode = ASButtonNode()
        super.init()
    }
    
    override func didLoad() {
        self.titleNode.attributedText = NSAttributedString(string: TBLanguage.sharedInstance.localizable(TBLankey.ac_title_storage_clean), font: Font.medium(16), textColor: UIColor.black, paragraphAlignment: .left)
        self.addSubnode(self.titleNode)
        
        self.contentNode.backgroundColor = UIColor(hexString: "#F7F8F9")
        self.contentNode.cornerRadius = 12
        self.addSubnode(self.contentNode)
        
        self.cacheValueNode.attributedText = NSAttributedString(string: "--", font: Font.medium(33), textColor: UIColor.black, paragraphAlignment: .left)
        self.contentNode.addSubnode(self.cacheValueNode)
        
        self.cacheSubNode.attributedText = NSAttributedString(string: TBLanguage.sharedInstance.localizable(TBLankey.commontools_local_cache_size_tips), font: Font.regular(13), textColor: UIColor(hexString: "#56565C")!, paragraphAlignment: .left)
        self.contentNode.addSubnode(self.cacheSubNode)
        
        self.cleanButtonNode.setTitle(TBLanguage.sharedInstance.localizable(TBLankey.commontools_oneclick_cleanup), with: Font.medium(13), with: UIColor.white, for: .normal)
        self.cleanButtonNode.backgroundColor = UIColor(hexString: "#FF4B5CF8")
        self.cleanButtonNode.cornerRadius = 19
        self.contentNode.addSubnode(self.cleanButtonNode)
        self.cleanButtonNode.addTarget(self, action: #selector(cleanCacheevent), forControlEvents: .touchUpInside)
    }
    
    func update(layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        transition.updateFrame(node: self.titleNode, frame: CGRect(x: 0, y: 22, width: 100, height: 22))
        transition.updateFrame(node: self.contentNode, frame: CGRect(x: 0, y: 54, width: layout.size.width, height: layout.size.height - 54))
        transition.updateFrame(node: self.cacheValueNode, frame: CGRect(x: 12, y: 20, width: layout.size.width / 1.7, height: 33))
        transition.updateFrame(node: self.cacheSubNode, frame: CGRect(x: 12, y: 65, width: 140, height: 15))
        transition.updateFrame(node: self.cleanButtonNode, frame: CGRect(x: layout.size.width - 144, y: 37, width: 127, height: 38))
    }
    
    @objc func cleanCacheevent() {
        self.cleanCacheEvent()
    }
}

class TBToolsCenterControllerNode: ASDisplayNode {

    private let context: AccountContext
    private var presentationData: PresentationData
    
    private let scrollNode: ASScrollNode
    private let cacheNode: TBCacheNode
    
    private let tools: [TBToolItem<TBToolItemType>]
    private var items = [TBToolItemNode<TBToolItemType>]()
    
    var toolClickEvent: ((TBToolItemType) -> Void)?
    var cleanCacheEvent: (()->Void)?
    
    init(context: AccountContext, presentationData: PresentationData, cleanCacheEvent: @escaping () -> Void) {
        self.context = context
        self.presentationData = presentationData
        self.scrollNode = ASScrollNode()
        self.cacheNode = TBCacheNode(cleanCacheEvent: cleanCacheEvent)
        self.tools = toolItems(itemTypes: [.qr, .transferAsset, .invite, .filter, .official(type: .group), .official(type: .channel)])
        super.init()
        
    }
    
    override func didLoad() {
        super.didLoad()
        self.scrollNode.scrollableDirections = [.up, .down]
        self.scrollNode.view.showsVerticalScrollIndicator = false
        self.scrollNode.view.showsHorizontalScrollIndicator = false
        self.addSubnode(self.scrollNode)
        self.scrollNode.addSubnode(self.cacheNode)
        if #available(iOS 11.0, *) {
            self.scrollNode.view.contentInsetAdjustmentBehavior = .never
        }
        let theme = TBItemNodeTheme(itemsize: CGSize(width: 70, height: 80), bgSize: CGSize(width: 57, height: 57), imageSize: CGSize(width: 30, height: 30))
        for tool in self.tools {
            let isOfficial: Bool = {
                switch tool.type {
                case .official(_):
                    return true
                default:
                    return false
                }
            }()
            let toolNode = TBToolItemNode<TBToolItemType>(theme: self.presentationData.theme, itemTheme: theme, isOfficial: isOfficial)
            toolNode.updateNodeBy(tool)
            toolNode.clickEvent = {[weak self] type in
                self?.toolClickEvent?(type)
            }
            self.scrollNode.addSubnode(toolNode)
            self.items.append(toolNode)
        }
    }
    
    func update(layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        var tempLayout = layout
        tempLayout.size = CGSize(width: layout.size.width - 48, height: 166)
        self.cacheNode.update(layout: tempLayout, transition: transition)
        
        let lineCount = ceil(Float(self.items.count) / 3.0)
        let y = (layout.statusBarHeight ?? 20) + 44
        self.scrollNode.frame = CGRect(x: 0, y: y, width: layout.size.width, height: layout.size.height - y)
        self.scrollNode.view.contentSize = CGSize(width: layout.size.width, height: CGFloat(166 + lineCount * (35 + 80)))
        transition.updateFrame(node: self.cacheNode, frame: CGRect(x: 24, y: 0, width: tempLayout.size.width, height: 166))
        
        let padding = (layout.size.width - 84 - 210) / 2.0
        for (index, item) in self.items.enumerated() {
            let x = 42 + CGFloat((index) % 3) * (padding + 70.0)
            let y = 166 + 35 + CGFloat(floor(Float(index) / 3.0)) * (35 + 80)
            transition.updateFrame(node: item, frame: CGRect(x: x, y: y, width: 70, height: 80))
        }
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
            attr.addAttribute(.foregroundColor, value: UIColor(hexString: "#FF56565C")!, range: range)
        }
        self.cacheNode.cacheValueNode.attributedText = attr
    }
}
