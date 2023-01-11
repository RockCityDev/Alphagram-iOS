import UIKit
import Postbox
import SwiftSignalKit
import AsyncDisplayKit
import Display
import TelegramCore
import TelegramPresentationData
import AccountContext
import SnapKit
import TBWeb3Core
import TBWalletCore
import TBDisplay
import SDWebImage
import TBLanguage


private enum Section: Equatable {
    case title
    case des
    case tag
    case price
    static func == (lhs: Section, rhs: Section) -> Bool {
        if lhs.sectionId() == rhs.sectionId() {
            return true
        }else{
            return false
        }
    }
    
    func sectionId() -> Int64 {
        switch self {
        case .title:
            return 1
        case .des:
            return 2
        case .tag:
            return 3
        case .price:
            return 4
        }
    }
    
    func sectionInset() -> UIEdgeInsets {
        switch self {
        case .title:
            return UIEdgeInsets(top: 64, left: 16, bottom: 0, right: 16)
        case .des:
            return UIEdgeInsets(top: 12, left: 16, bottom: 0, right: 16)
        case .tag:
            return UIEdgeInsets(top: 16, left: 0, bottom: 0, right: 0)
        case .price:
            return UIEdgeInsets(top: 16, left: 16, bottom: 0, right: 16)
        }
    }
    
    func minimumLineSpacing() -> CGFloat {
        switch self {
        case .title:
            return 0
        case .des:
            return 0
        case .tag:
            return 0
        case .price:
            return 0
        }
    }
    
    func minimumInteritemSpacing() -> CGFloat {
        switch self {
        case .title:
            return 0
        case .des:
            return 0
        case .tag:
            return 0
        case .price:
            return 0
        }
    }
}


private enum Item {
    case title(TBWeb3GroupInfoEntry)
    case des(TBWeb3GroupInfoEntry)
    case tag(TBWeb3GroupInfoEntry, TBItemListLabelsContentLayoutConfig)
    case price(TBWeb3GroupInfoEntry, TBWeb3ConfigEntry)
    
    func cellClass() -> AnyClass {
        switch self {
        case .title:
            return TBVipGroupInfoTitleCell.self
        case .des:
            return TBVipGroupInfoDescCell.self
        case .tag:
            return TBVipGroupInfoTagCell.self
        case .price:
            return TBVipGroupInfoPriceCell.self
        }
    }
    
    func section() -> Section {
        switch self {
        case .title:
            return .title
        case .des:
            return .des
        case .tag:
            return .tag
        case .price:
            return .price
        }
    }
    
    func size(viewSize:CGSize = UIScreen.main.bounds.size) -> CGSize {
        let itemWidth = viewSize.width - self.section().sectionInset().left - self.section().sectionInset().right
        switch self {
        case .title(let groupInfo):
            let titleHeight = groupInfo.title.tb_heightForComment(fontSize: 18, width: itemWidth)
            return CGSize(width: itemWidth, height: titleHeight + 25)
        case .des(let groupInfo):
            let descHeight = groupInfo.description.tb_heightForComment(fontSize: 14, width: itemWidth)
            return CGSize(width: itemWidth, height: descHeight)
        case .tag(let groupInfo, let layoutConfig):
            let tagHeight =  layoutConfig.contentSize(items: groupInfo.tags, maxWidth: itemWidth).height
            return CGSize(width: itemWidth, height: 1 + 12 + 19 + tagHeight)
        case .price:
            return CGSize(width: itemWidth, height: 19 + 26)
        }
    }
    
}


private struct State: Equatable {
    var groupInfo: TBWeb3GroupInfoEntry
    var config: TBWeb3ConfigEntry
    var tagsLayoutConfig: TBItemListLabelsContentLayoutConfig
    var walletConnect:TBWalletConnect
    static func == (lhs: State, rhs: State) -> Bool {
        if lhs.groupInfo != rhs.groupInfo {
            return false
        }
        if lhs.walletConnect != rhs.walletConnect {
            return false
        }
        return true
    }
}


extension State {
    
}


private typealias DataMap = [Section : [Item]]


extension DataMap {
    fileprivate func validSortKeys() -> [Section] {
        let map = self.compactMapValues { $0.isEmpty ? nil : $0}
        return map.keys.sorted{$0.sectionId() < $1.sectionId()}
    }
}

private class BottomButtonView: UIView {
    
    private let groupInfo: TBWeb3GroupInfoEntry
    
    private let titleLabel: UILabel
    
    fileprivate var tapBlock:((TBWeb3GroupInfoEntry) -> Void)?
    
    public init(groupInfo:TBWeb3GroupInfoEntry) {
        self.groupInfo = groupInfo
        self.titleLabel = UILabel()
        self.titleLabel.textColor = UIColor(rgb: 0xFFFFFF)
        self.titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        let payText = TBLanguage.sharedInstance.localizable(TBLankey.create_group_paytojoin_group)
        let condText = TBLanguage.sharedInstance.localizable(TBLankey.create_group_conditionjoin_group)
        self.titleLabel.text = self.groupInfo.transferJoinType() == .payLimit ? payText : condText
        super.init(frame: .zero)
        
        
        self.backgroundColor = UIColor(rgb: 0x8836DF)
        
        self.addSubview(self.titleLabel)
        self.titleLabel.snp.makeConstraints { make in
            make.center.equalTo(self)
        }
        
        self.isUserInteractionEnabled = true
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tapAction)))
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = self.frame.height / 2.0
        self.clipsToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func tapAction() {
        self.tapBlock?(self.groupInfo)
    }
}

class TBVipGroupInfoImplController: UIViewController {
    let context: AccountContext
    private var presentationData: PresentationData
    private let presentationDataValue = Promise<PresentationData>()
    private var presentationDataDisposable: Disposable?
    func _parentViewController() -> TBVipGroupInfoViewController {
        return self.parent as! TBVipGroupInfoViewController
    }
    
    let closeButton: UIButton
    let avatar: UIImageView
    let collectionView: UICollectionView
    private var dataMap = DataMap()
    private let bottomView: BottomButtonView
    private let statePromise: ValuePromise<State>
    private let stateValue: Atomic<State>
    private let updateState: ((State) -> State) -> Void
    private var stateDisposable: Disposable?
    
    init(context: AccountContext,
         configEntry:TBWeb3ConfigEntry,
         groupInfo:TBWeb3GroupInfoEntry,
         walletConnect:TBWalletConnect) {
        self.context = context
        self.presentationData = (context.sharedContext.currentPresentationData.with { $0 })
        self.presentationDataValue.set(.single(self.presentationData))
        
        self.closeButton = UIButton(type: .custom)
        let image = UIImage(named: "Nav/nav_close_icon")
        image?.withTintColor(UIColor.white, renderingMode: .alwaysTemplate)
        self.closeButton.tintColor = .white
        self.closeButton.setImage(image, for: .normal)
        
        self.avatar = UIImageView()
        self.avatar.contentMode = .scaleAspectFill
        self.avatar.layer.cornerRadius = 94 / 2.0
        self.avatar.layer.borderColor = UIColor(rgb: 0xFFFFFF).cgColor
        self.avatar.layer.borderWidth = 4
        self.avatar.clipsToBounds = true
        
        let layout = UICollectionViewFlowLayout()
        self.collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        let initialState = State(
            groupInfo: groupInfo,
            config: configEntry,
            tagsLayoutConfig: TBItemListLabelsContentLayoutConfig(
                minimumLineSpacing: 6,
                minimumInteritemSpacing: 6,
                insetForSection: UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16),
                viewType: .text,
                font: .systemFont(ofSize: 12, weight: .regular),
                itemInset: UIEdgeInsets(top: 7, left: 10, bottom: 7, right: 10)
            ),
            walletConnect: walletConnect
        )
        let statePromise = ValuePromise(initialState, ignoreRepeated: true)
        let stateValue = Atomic(value: initialState)
        let updateState: ((State) -> State) -> Void = { f in
            statePromise.set(stateValue.modify { f($0) })
        }

        self.statePromise = statePromise
        self.stateValue = stateValue
        self.updateState = updateState
        
        self.bottomView = BottomButtonView(groupInfo: groupInfo)

        super.init(nibName: nil, bundle: nil)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor(rgb: 0x4B5BFF)
        
        self.closeButton.addTarget(self, action: #selector(self.tapClose), for: .touchUpInside)
        
        self.collectionView.contentInsetAdjustmentBehavior = .never
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.backgroundColor = .white
        self.collectionView.alwaysBounceVertical = true
        self.collectionView.register(TBVipGroupInfoTitleCell.self, forCellWithReuseIdentifier: NSStringFromClass(TBVipGroupInfoTitleCell.self))
        self.collectionView.register(TBVipGroupInfoDescCell.self, forCellWithReuseIdentifier: NSStringFromClass(TBVipGroupInfoDescCell.self))
        self.collectionView.register(TBVipGroupInfoTagCell.self, forCellWithReuseIdentifier: NSStringFromClass(TBVipGroupInfoTagCell.self))
        self.collectionView.register(TBVipGroupInfoPriceCell.self, forCellWithReuseIdentifier: NSStringFromClass(TBVipGroupInfoPriceCell.self))
        self.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: NSStringFromClass(UICollectionViewCell.self))
        
        self.bottomView.tapBlock = {[weak self] groupInfo in
            if let strongSelf = self {
                let state = strongSelf.stateValue.with{$0}
                let orderVC = TBVipGroupOrderViewController(
                    context: strongSelf.context,
                    configEntry: state.config,
                    groupInfo: state.groupInfo,
                    walletConnect: state.walletConnect)
                strongSelf.navigationController?.pushViewController(orderVC, animated: true)
                debugPrint("/")
            }
        }
        
        self.view.addSubview(self.closeButton)
        self.view.addSubview(self.collectionView)
        self.view.addSubview(self.avatar)
        self.view.addSubview(self.bottomView)
        
        self.closeButton.snp.makeConstraints { make in
            make.top.equalTo(15)
            make.trailing.equalTo(-15)
            make.width.height.equalTo(30)
        }
        
        self.avatar.snp.makeConstraints { make in
            make.top.equalTo(32)
            make.leading.equalTo(16)
            make.width.height.equalTo(94)
        }
        self.bottomView.snp.makeConstraints { make in
            make.bottom.equalTo(-12)
            make.centerX.equalTo(self.view)
            make.leading.equalTo(16)
            make.height.equalTo(46)
        }
        self.collectionView.snp.makeConstraints { make in
            make.top.equalTo(70)
            make.leading.trailing.equalTo(self.view)
            make.bottom.equalTo(self.view)
        }
        
        self.stateDisposable = self.statePromise.get().start(next: { [weak self] state in
            if let strongSelf = self {
                strongSelf.reloadView(state: state)
            }
        })
    }
    
    func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition){
        self.bottomView.snp.updateConstraints{ make in
            make.bottom.equalTo(-(12 + layout.intrinsicInsets.bottom))
        }
    }
    
    @objc func tapClose() {
        self._parentViewController().dismiss(animated: true)
    }
    
    private func reloadView(state: State) {
        self.dataMap = TBVipGroupInfoImplController.creatDataMap(state: state)
        self.collectionView.reloadData()
        self.avatar.sd_setImage(with: URL(string: state.groupInfo.avatar), placeholderImage: UIImage(named: "TBWallet/avatar"))
    }
    
    deinit {
        self.presentationDataDisposable?.dispose()
        self.stateDisposable?.dispose()
    }

}


extension TBVipGroupInfoImplController {
    private static func creatDataMap(state: State) -> DataMap {
        var ret = DataMap()
        
        var titleSectionList = [Item]()
        titleSectionList.append(.title(state.groupInfo))
    
        var descSectionList = [Item]()
        if !state.groupInfo.description.isEmpty {
            descSectionList.append(.des(state.groupInfo))
        }
      
        var tagSectionList = [Item]()
        if !state.groupInfo.tags.isEmpty {
            tagSectionList.append(.tag(state.groupInfo, state.tagsLayoutConfig))
        }
        
        var priceSectionList = [Item]()
        priceSectionList.append(.price(state.groupInfo, state.config))
        
        ret[.title] = titleSectionList
        ret[.des] = descSectionList
        ret[.tag] = tagSectionList
        ret[.price] = priceSectionList
        ret = ret.compactMapValues{$0.isEmpty ? nil : $0}
        return ret
    }
}


extension TBVipGroupInfoImplController: UICollectionViewDataSource {
    
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
            case .title(let groupInfo):
                if let cell = cell as? TBVipGroupInfoTitleCell {
                    cell.reloadCell(item: groupInfo)
                }
            case .des(let groupInfo):
                if let cell = cell as? TBVipGroupInfoDescCell {
                    cell.reloadCell(item: groupInfo)
                }
            case .tag(let groupInfo, let tagLayoutConfig):
                if let cell = cell as? TBVipGroupInfoTagCell {
                    cell.reloadCell(item: groupInfo, tagsConfig: tagLayoutConfig)
                }
            case .price(let groupInfo, let config):
                if let cell = cell as? TBVipGroupInfoPriceCell {
                    cell.reloadCell(item: groupInfo, config: config, limitType: .payLimit)
                }
            }
            return cell
        }else{
            return collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(UICollectionViewCell.self), for: indexPath)
        }
    }
    
}


extension TBVipGroupInfoImplController {
    
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


extension TBVipGroupInfoImplController: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let item = self.safeItem(at: indexPath) {
            switch item {
            case .title:
                break
            case .des:
                break
            case .tag:
                break
            case .price:
                break
            }
        }
    }
}


extension TBVipGroupInfoImplController : UICollectionViewDelegateFlowLayout {
    
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









