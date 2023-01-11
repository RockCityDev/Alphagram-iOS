import UIKit
import SegementSlide
import JXSegmentedView
import Display
import AccountContext
import AsyncDisplayKit
import TelegramPresentationData
import TBBusinessNetwork
import TBAccount
import TBWalletCore
import HandyJSON
import SwiftSignalKit
import SDWebImage
import MJRefresh
import TBWalletUI
import ProgressHUD
import TBLanguage
import TBWeb3Core

private var dataSourceKey: Void?
    
extension JXSegmentedView: SegementSlideSwitcherDelegate {
    
    public var ssDataSource: SegementSlideSwitcherDataSource? {
        get {
            let weakBox = objc_getAssociatedObject(self, &dataSourceKey) as? SegementSlideSwitcherDataSourceWeakBox
            return weakBox?.unbox
        }
        set {
            objc_setAssociatedObject(self, &dataSourceKey, SegementSlideSwitcherDataSourceWeakBox(newValue), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    public var ssDefaultSelectedIndex: Int? {
        get {
            return defaultSelectedIndex
        }
        set {
            defaultSelectedIndex = newValue ?? 0
        }
    }
    
    public var ssSelectedIndex: Int? {
        return self.selectedIndex
    }
    
    public var ssScrollView: UIScrollView {
        return self.collectionView
    }

    public func selectItem(at index: Int, animated: Bool) {
        self.selectItemAt(index: index)
    }
    
}

private class TBJXSegmentedView: JXSegmentedView {
    
    private let line = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.line.backgroundColor = UIColor(hexString: "#FFE6E6E6")!
        self.insertSubview(self.line, aboveSubview: self.collectionView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        self.line.frame = CGRect(x: 0, y: self.bounds.maxY - 1, width: self.bounds.width, height: 1)
    }
}

final class TBMyWebSegmentController: SegementSlideViewController {
    
    private let context: AccountContext
    private var presentationData: PresentationData
    private let isMe: Bool
    
    private let segmentedView = TBJXSegmentedView()
    let headerNode: WebPageHeaderNode
    
    private let tokenVc = TokenController()
    let nftVc = NFTController()
    private let acticityVc = ActivityController()
    
    private lazy var segmentedDataSource: JXSegmentedNumberDataSource = {
        let dataSource = JXSegmentedNumberDataSource()
        dataSource.titleSelectedColor = .white
        dataSource.isTitleColorGradientEnabled = true
        dataSource.isItemSpacingAverageEnabled = true
        dataSource.isSelectedAnimable = true
        dataSource.isTitleMaskEnabled = true
        return dataSource
    }()
    
    enum ControllerType {
        case token
        case nft
        case activity
    }
    
    typealias ControllerCup = (type: ControllerType, name: String)
    private lazy var subControllers: [ControllerCup] = {
        let token = TBLanguage.sharedInstance.localizable(TBLankey.wallet_home_act_bar_tokenid)
        let NFT = TBLanguage.sharedInstance.localizable(TBLankey.wallet_home_act_bar_nft)
        let Activity = TBLanguage.sharedInstance.localizable(TBLankey.wallet_home_act_bar_transactionhistory)
        return [ControllerCup(.token, token), ControllerCup(.nft, NFT), ControllerCup(.activity, Activity)]
    }()
    
    var headPercent: ((CGFloat) -> ())?
    
    init(context: AccountContext, presentationData: PresentationData, isMe: Bool) {
        self.context = context
        self.presentationData = presentationData
        self.isMe = isMe
        self.headerNode = WebPageHeaderNode(context: context, presentationData: presentationData, isMe: isMe)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.red
        self.defaultSelectedIndex = 0
        self.reloadData()
        self.tokenVc.balanceUsdChange = { balanceUsd in
            self.headerNode.moneyNode.updateValue( "US$" + balanceUsd)
        }
    }
    
    
    public override func segementSlideSwitcherView() -> SegementSlideSwitcherDelegate {
        let indicator = JXSegmentedIndicatorBackgroundView()
        indicator.indicatorPosition = .bottom
        indicator.indicatorHeight = 3.0
        indicator.indicatorWidthIncrement = 0
        indicator.indicatorColor = UIColor(hexString: "#FF4B5BFF")!
        self.segmentedView.indicators = [indicator]
        self.segmentedView.delegate = self
        self.segmentedView.ssDataSource = self
        self.segmentedView.contentEdgeInsetLeft = 30
        self.segmentedView.contentEdgeInsetRight = 30
        return self.segmentedView
    }
    
    override func setupSwitcher() {
        super.setupSwitcher()
        self.segmentedDataSource.titles = self.titlesInSwitcher
        self.segmentedDataSource.numbers = self.badgesInSwitcher
        self.segmentedView.dataSource = self.segmentedDataSource
        self.segmentedView.contentScrollView = self.contentView.scrollView
    }
    
    var switcherViewHeight: CGFloat {
        return 48
    }
    
    var titlesInSwitcher: [String] {
        return self.subControllers.map({$0.name})
    }
    
    var badgesInSwitcher: [Int] {
        return [0, 0, 0]
    }
    
    
    override var bouncesType: BouncesType {
        return .child
    }
    
    
    override func segementSlideHeaderView() -> UIView? {
        let headerView = self.headerNode.view
        headerView.translatesAutoresizingMaskIntoConstraints = false
        let height = isMe ? 311.0 : 355.0
        headerView.heightAnchor.constraint(equalToConstant: height).isActive = true
        return headerView
    }
    
    
    override func segementSlideContentViewController(at index: Int) -> SegementSlideContentScrollViewDelegate? {
        if index > self.subControllers.count { return nil }
        let controller = self.subControllers[index]
        switch controller.type {
        case .token:
            return self.tokenVc
        case .nft:
            return self.nftVc
        case .activity:
            return self.acticityVc
        }
    }
    
    
    override var headerStickyHeightOffset: CGFloat {
        return 100
    }
    
    
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView, isParent: Bool) {
        super.scrollViewDidScroll(scrollView, isParent: isParent)
        self.headerNode.endEdit()
        guard isParent && self.headerStickyHeight > 0 else {
            return
        }
        let offset = scrollView.contentOffset.y
        var percent: CGFloat = 0
        if offset <= self.headerStickyHeight - self.headerStickyHeightOffset {
            percent = 0
        } else if offset >= self.headerStickyHeight {
            percent = 1
        } else {
            if self.headerStickyHeightOffset != 0 {
                percent = 1 - (self.headerStickyHeight - offset) / self.headerStickyHeightOffset
            }
        }
        self.headPercent?(percent)
    }
    
    func updateConfig(chain: TBWeb3ConfigEntry.Chain?, address: String?) {
        self.tokenVc.updateConfig(chain: chain, address: address)
        self.nftVc.updateConfig(chain: chain, address: address)
        self.acticityVc.updateConfig(chain: chain, address: address)
    }
}

extension TBMyWebSegmentController: SegementSlideSwitcherDataSource {
    
    public var height: CGFloat {
        return self.switcherViewHeight
    }
    
    public var titles: [String] {
        return self.titlesInSwitcher
    }
    
}

extension TBMyWebSegmentController: JXSegmentedViewDelegate {
    
    public func segmentedView(_ segmentedView: JXSegmentedView, didClickSelectedItemAt index: Int) {
        self.contentView.selectItem(at: index, animated: true)
    }
    
}

