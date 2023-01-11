
import UIKit
import Postbox
import SwiftSignalKit
import AsyncDisplayKit
import Display
import TelegramCore
import TelegramPresentationData
import AccountContext
import SegementSlide
import HandyJSON
import TBWeb3Core
import MJRefresh
import TBWalletCore
import ProgressHUD
import TBAccount
import TBTrack


private enum Section: Equatable {
    case chain
    case wallet
    case item
    static func == (lhs: Section, rhs: Section) -> Bool {
        if lhs.sectionId() == rhs.sectionId() {
            return true
        }else{
            return false
        }
    }
    
    func sectionId() -> Int64 {
        switch self {
        case .chain:
            return 1
        case .wallet:
            return 2
        case .item:
            return 3
        }
    }
    
    func sectionInset() -> UIEdgeInsets {
        switch self {
        case .chain:
            return .zero
        case .wallet:
            return .zero
        case .item:
            return UIEdgeInsets(top: 0, left: 12, bottom: 12, right: 12)
        }
    }
    
    func minimumLineSpacing() -> CGFloat {
        switch self {
        case .chain:
            return 0
        case .wallet:
            return 0
        case .item:
            return 12
        }
    }
    
    func minimumInteritemSpacing() -> CGFloat {
        switch self {
        case .chain:
            return 0
        case .wallet:
            return 0
        case .item:
            return 12
        }
    }
}


private enum Item {
    case chainInfo(TBWeb3ConfigEntry.Chain)
    case walletInfo(TBWalletConnect)
    case connectWallet
    case item(TBWeb3GroupListEntry.Item, TBWeb3ConfigEntry)
    case grayLine
    func cellClass() -> AnyClass {
        switch self {
        case .chainInfo:
            return TBCurrencyCommunityRecommendChainInfoCell.self
        case .walletInfo:
            return TBCurrencyCommunityRecommendWalletInfoCell.self
        case .connectWallet:
            return TBCurrencyCommunityRecommendConnectWallletCell.self
        case .item:
            return TBCurrencyCommunityRecommendItemCell.self
        case .grayLine:
            return UICollectionViewCell.self
        }
    }
    
    func section() -> Section {
        switch self {
        case .chainInfo:
            return .chain
        case .walletInfo, .connectWallet, .grayLine:
            return .wallet
        case .item:
            return .item
        }
    }
    
    func size(viewSize:CGSize = UIScreen.main.bounds.size) -> CGSize {
        let itemWidth = viewSize.width - self.section().sectionInset().left - self.section().sectionInset().right
        switch self {
        case .chainInfo:
            return CGSize(width: itemWidth , height: 198)
        case .walletInfo:
            return CGSize(width: itemWidth, height: 58)
        case .connectWallet:
            return CGSize(width: itemWidth, height: 58)
        case .item:
            return CGSize(width: itemWidth, height: 168)
        case .grayLine:
            return CGSize(width: itemWidth, height: 10)
        }
    }
    
}


private struct State: Equatable {
    var configEntry: TBWeb3ConfigEntry
    var chain: TBWeb3ConfigEntry.Chain
    var walletConnect: TBWalletConnect?
    var groupItems:[TBWeb3GroupListEntry.Item]
    
    static func == (lhs: State, rhs: State) -> Bool {
        if lhs.chain != rhs.chain {
            return false
        }
        
        if lhs.walletConnect != rhs.walletConnect {
            return false
        }
        
        if !lhs.groupItems.elementsEqual(rhs.groupItems) {
            return false
        }
        return true
    }
    
}


extension State {
    
     func addGroupItems(items: [TBWeb3GroupListEntry.Item]) -> State {
        var state = self
        var items = state.groupItems
        items.append(contentsOf: items)
        items = items.compactMap{$0}
        state.groupItems = items
        return state
    }
    
     func refreshGroupItems(items: [TBWeb3GroupListEntry.Item]) -> State {
        var state = self
        state.groupItems = items
        return state
    }
    
    mutating func updateWalletConnect(connect: TBWalletConnect?) -> State {
        self.walletConnect = connect
        return self
    }
    
}


private typealias DataMap = [Section : [Item]]


extension DataMap {
    fileprivate func validSortKeys() -> [Section] {
        let map = self.compactMapValues { $0.isEmpty ? nil : $0}
        return map.keys.sorted{$0.sectionId() < $1.sectionId()}
    }
}

class TBCurrencyCommunityContentController: UIViewController,SegementSlideContentScrollViewDelegate  {
    let context: AccountContext
    let topLine = UIView()
    let collectionView: UICollectionView
    let coinId: String?
    private var dataMap = DataMap()
    private var presentationData: PresentationData
    private let presentationDataValue = Promise<PresentationData>()
    private var presentationDataDisposable: Disposable?
    private weak var currencyHomeController: TBCurrencyCommunityHomeController? {
        if let homeController = self.parent?.parent as? TBCurrencyCommunityHomeController {
            return homeController
        }
        return nil
    }
    func _parentViewController() -> TBCurrencyCommunityHomeController {
        return self.parent?.parent as! TBCurrencyCommunityHomeController
    }

    private let statePromise: ValuePromise<State>
    private let stateValue: Atomic<State>
    private let updateState: ((State) -> State) -> Void
    private var stateDisposable: Disposable?
    private var coinUnitPrice = Promise(initializeOnFirstAccess: .single(CurrencyPrice()))
    
    private var page: Int = 1
    
    
    
    init(context: AccountContext, config: TBWeb3ConfigEntry, chain: TBWeb3ConfigEntry.Chain) {
        self.context = context
        self.presentationData = (context.sharedContext.currentPresentationData.with { $0 })
        self.presentationDataValue.set(.single(self.presentationData))

        let layout = UICollectionViewFlowLayout()
        self.collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        self.coinId = chain.currency.filter({$0.id == chain.main_currency_id}).first?.coin_id
    
        let initialState = State(configEntry: config, chain: chain, walletConnect: TBWalletConnectManager.shared.getAllAvailabelConnecttions().first, groupItems: [TBWeb3GroupListEntry.Item]())
        let statePromise = ValuePromise(initialState, ignoreRepeated: true)
        let stateValue = Atomic(value: initialState)
        let updateState: ((State) -> State) -> Void = { f in
            statePromise.set(stateValue.modify { f($0) })
        }

        self.statePromise = statePromise
        self.stateValue = stateValue
        self.updateState = updateState
        
        super.init(nibName: nil, bundle: nil)
        
        let _ = TBWalletConnectManager.shared.availabelConnectionsSignal.start(next: {[weak self] connect in
            guard let strongSelf = self else { return }
            strongSelf.updateState{ current in
                var state = current
                return state.updateWalletConnect(connect: connect.first)
            }
        })
        
        let _ = (context.sharedContext.presentationData |> deliverOnMainQueue).start(next: { [weak self] data in
            guard let strongSelf = self else { return }
            strongSelf.presentationData = data
            strongSelf.presentationDataValue.set(.single(data))
            strongSelf.updateThemeStrings()
        })
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        self.topLine.backgroundColor = UIColor(hexString: "#1A000000")
        self.view.addSubview(self.topLine)
        self.view.addSubview(self.collectionView)
        self.collectionView.contentInsetAdjustmentBehavior = .never
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.backgroundColor = .white
        self.collectionView.alwaysBounceVertical = true
        self.collectionView.register(TBCurrencyCommunityRecommendItemCell.self, forCellWithReuseIdentifier: NSStringFromClass(TBCurrencyCommunityRecommendItemCell.self))
        self.collectionView.register(TBCurrencyCommunityRecommendChainInfoCell.self, forCellWithReuseIdentifier: NSStringFromClass(TBCurrencyCommunityRecommendChainInfoCell.self))
        self.collectionView.register(TBCurrencyCommunityRecommendWalletInfoCell.self, forCellWithReuseIdentifier: NSStringFromClass(TBCurrencyCommunityRecommendWalletInfoCell.self))
        self.collectionView.register(TBCurrencyCommunityRecommendConnectWallletCell.self, forCellWithReuseIdentifier: NSStringFromClass(TBCurrencyCommunityRecommendConnectWallletCell.self))
        self.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: NSStringFromClass(UICollectionViewCell.self))
        
        self.topLine.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(1)
        }
        
        self.collectionView.snp.makeConstraints { make in
            make.bottom.leading.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(1)
        }
        
        self.collectionView.mj_header = MJRefreshNormalHeader(refreshingTarget: self, refreshingAction: #selector(self.refreshpPage))
        
        let mj_footer = MJRefreshAutoNormalFooter(refreshingBlock: { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.page += 1
            strongSelf.fetchhpPage(by: strongSelf.page)
        })
        mj_footer.setTitle("", for: .noMoreData)
        mj_footer.setTitle("", for: .idle)
        self.collectionView.mj_footer = mj_footer
        
        self.refreshpPage()
        
        self.stateDisposable = self.statePromise.get().start(next: {[weak self] state in
            if let strongSelf = self {
                strongSelf.dataMap = TBCurrencyCommunityContentController.creatDataMap(state: state)
                strongSelf.collectionView.reloadData()
            }
        })
    }
    
    func updateThemeStrings() {
        self.collectionView.reloadData()
    }
    
    func updateCoinPrice() {
        if let coinId = self.coinId  {
           let _ = TBHomeInteractor.fetchCurrencyPrice(by: coinId).start(next: {[weak self] price in
               self?.coinUnitPrice.set(.single(price))
            })
        }
    }
    
    @objc func refreshpPage() {
        self.updateCoinPrice()
        self.page = 1
        self.fetchhpPage(by: self.page)
    }
    
    func fetchhpPage(by page: Int) {
        debugPrint("====\(page), controller:")
        let state = self.stateValue.with{$0}
        let _ = TBWeb3GroupListInteractor().web3GroupListSignal(chain_id: String(state.chain.id), page: page).start(next: { [weak self] listEntry in
            guard let strongSelf = self else { return }
            strongSelf.collectionView.mj_header?.endRefreshing()
            strongSelf.collectionView.mj_footer?.endRefreshing()
            if let listEntry = listEntry, listEntry.data.count > 0 {
                if page == 1 {
                    strongSelf.updateState{ current in
                        return current.refreshGroupItems(items: listEntry.data)
                    }
                } else {
                    strongSelf.updateState{ current in
                        return current.addGroupItems(items: listEntry.data)
                    }
                }
            } else {
                strongSelf.page = max(strongSelf.page - 1, 1)
            }
        })
    }
    
    func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition){
        
    }
    
    @objc var scrollView: UIScrollView {
        return self.collectionView
    }
    
    deinit {
        self.presentationDataDisposable?.dispose()
        self.stateDisposable?.dispose()
    }
    
    func addNewGroup() {
        TBTrack.track(TBTrackEvent.Asset.group_home_group_create_click.rawValue)
        let chain = self.stateValue.with({$0.chain})
        self.context.sharedContext.tb_flyStartNav(type: .newGroup(chainName: chain.name, chainId: String(chain.id)), accountContext: self.context)
    }
}


extension TBCurrencyCommunityContentController {
    private static func creatDataMap(state: State) -> DataMap {
        var ret = DataMap()
        let chainItems: [Item] = [.chainInfo(state.chain)]
        
        var walletItems = [Item]()
        walletItems.append(.grayLine)
        if let c = state.walletConnect {
            walletItems.append(.walletInfo(c))
        }else{
            walletItems.append(.connectWallet)
        }
        ret[.chain] = chainItems
        ret[.wallet] = walletItems
        if !state.groupItems.isEmpty {
            var items = [Item]()
            for item in state.groupItems {
                items.append(.item(item, state.configEntry))
            }
            ret[.item] = items
        }
        ret = ret.compactMapValues{$0.isEmpty ? nil : $0}
        return ret
    }
}


extension TBCurrencyCommunityContentController: UICollectionViewDataSource {
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.sectionCount()
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.safeItems(at: section).count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if let item = self.safeItem(at: indexPath) {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(item.cellClass()), for: indexPath)
            switch item {
            case .chainInfo(let chain):
                if let cell = cell as? TBCurrencyCommunityRecommendChainInfoCell {
                    cell.reloadCellByChain(by: chain, coinPriceSignal: self.coinUnitPrice.get())
                    cell.buttonItemEvent = { [weak self] button in
                        guard let strongSelf = self, let nav = strongSelf.navigationController as? NavigationController else { return }
                        strongSelf.context.sharedContext.openExternalUrl(context: strongSelf.context, urlContext: .generic, url: button.link, forceExternal: false, presentationData: strongSelf.context.sharedContext.currentPresentationData.with { $0 }, navigationController: nav, dismissInput: {})
                    }
                }
            case .walletInfo(let walletConnect):
                if let cell:TBCurrencyCommunityRecommendWalletInfoCell = cell as? TBCurrencyCommunityRecommendWalletInfoCell {
                    cell.reloadCell(walletConnect: walletConnect)
                    cell.addNewGroupEvent = { [weak self] in
                        self?.addNewGroup()
                    }
                }
            case .connectWallet:
                if let cell:TBCurrencyCommunityRecommendConnectWallletCell = cell as? TBCurrencyCommunityRecommendConnectWallletCell {
                    cell.reloadCell()
                    cell.connectClickEvent = {
                        TBWalletConnectManager.shared.connectToPlatform(platform: .metaMask)
                    }
                    cell.addNewGroupEvent = { [weak self] in
                        self?.addNewGroup()
                    }
                }
            case .item(let entry, let config):
                if let cell:TBCurrencyCommunityRecommendItemCell = cell as? TBCurrencyCommunityRecommendItemCell {
                    cell.reloadCell(item: entry, config: config)
                }
            case .grayLine:
                cell.contentView.backgroundColor = UIColor(rgb: 0xF2F2F2)
            }
            return cell
        }else{
            return collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(UICollectionViewCell.self), for: indexPath)
        }
    }
    
}


extension TBCurrencyCommunityContentController {
    
    private func safeItem(at indexPath: IndexPath) -> Item? {
        return self.safeItem(section: indexPath.section, row: indexPath.row)
    }
    
    private func sectionCount() -> Int {
        return self.dataMap.validSortKeys().count
    }
    
    private func safeSectionKey(at section: Int) -> Section? {
        let sections = self.dataMap.validSortKeys()
        if sections.count > section {
            return sections[section]
        }
        return nil
    }
    
    private func safeItems(at section: Int) -> [Item] {
        if let key = self.safeSectionKey(at: section), let ret = self.dataMap[key] {
            return ret
        }
        return [Item]()
    }
    
    private func safeItem(section: Int, row: Int) -> Item? {
        let items = self.safeItems(at: section)
        if items.count > row {
            return items[row]
        }
        return nil
    }
    
}


extension TBCurrencyCommunityContentController: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let item = self.safeItem(at: indexPath) {
            switch item {
            case .chainInfo(let chain):
                debugPrint("\(chain)")
            case .walletInfo(let tBWalletConnect):
                debugPrint("\(tBWalletConnect)")
                break
            case .connectWallet:
                break
            case .item(let item, _):
                TBTrack.track(TBTrackEvent.Asset.group_home_group_join_click.rawValue)
                if let controller = self.currencyHomeController {
                    let params = TBJoinGroupParams(context: self.context,
                                                   groupId: item.id,
                                                   tgGroupId: item.abs_tg_group_id(),
                                                   walletAddress: self.stateValue.with({$0.walletConnect?.getAccountId()}),
                                                   inViewController: controller)
                    self.context.sharedContext.tb_tryJoinGroup(params: params)
                }
            case .grayLine:
                break
            }
        }
    }
}




extension TBCurrencyCommunityContentController : UICollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if let item = self.safeItem(at: indexPath) {
            return item.size()
        }
        return .zero
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if let section = self.safeSectionKey(at: section) {
            return section.minimumLineSpacing()
        }
        return 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        if let section = self.safeSectionKey(at: section) {
            return section.minimumInteritemSpacing()
        }
        return 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if let section = self.safeSectionKey(at: section) {
            return section.sectionInset()
        }
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return .zero
    }
    
}








