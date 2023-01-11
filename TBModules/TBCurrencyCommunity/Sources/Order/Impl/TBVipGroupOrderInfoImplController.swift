
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

enum LocalPayStatus:Int, Equatable {
    case waitPay
    case paying
    case paySuccess
    case fail
}

private enum Section: Equatable {
    case groupInfo
    case payStatus
    case account
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
        case .groupInfo:
            return 1
        case .payStatus:
            return 2
        case .account:
            return 3
        case .price:
            return 4
        }
    }
    
    func sectionInset() -> UIEdgeInsets {
        
        switch self {
        case .groupInfo:
            return UIEdgeInsets(top: 16, left: 20, bottom: 0, right: 20)
        case .payStatus:
            return UIEdgeInsets(top: 12, left: 20, bottom: 0, right: 20)
        case .account:
            return UIEdgeInsets(top: 12, left: 20, bottom: 0, right: 20)
        case .price:
            return UIEdgeInsets(top: 12, left: 20, bottom: 0, right: 20)
        }
    }
    
    func minimumLineSpacing() -> CGFloat {
        switch self {
        case .groupInfo:
            return 0
        case .payStatus:
            return 0
        case .account:
            return 1
        case .price:
            return 0
        }
    }
    
    func minimumInteritemSpacing() -> CGFloat {
        switch self {
        case .groupInfo:
            return 0
        case .payStatus:
            return 0
        case .account:
            return 1
        case .price:
            return 0
        }
    }
}


private enum Item {
    case groupInfo(TBWeb3GroupInfoEntry)
    case payStatus(TBWeb3GroupInfoEntry, LocalPayStatus)
    case account(TBWeb3GroupInfoEntry, String, String)
    case price(TBWeb3GroupInfoEntry, TBWeb3ConfigEntry)
    
    func cellClass() -> AnyClass {
        
        switch self {
        case .groupInfo:
            return TBVipGroupOrderInfoGroupCell.self
        case .payStatus:
            return TBVipGroupOrderInfoPayStateCell.self
        case .account:
            return TBVipGroupOrderInfoAccountCell.self
        case .price:
            return TBVipGroupOrderInfoPriceCell.self
        }
    }
    
    func section() -> Section {
        switch self {
        case .groupInfo:
            return .groupInfo
        case .payStatus:
            return .payStatus
        case .account:
            return .account
        case .price:
            return .price
        }
    }
    
    func size(viewSize:CGSize = UIScreen.main.bounds.size) -> CGSize {
        let itemWidth = viewSize.width - self.section().sectionInset().left - self.section().sectionInset().right
        switch self {
        case .groupInfo:
            return CGSize(width: itemWidth, height: 88)
        case .payStatus:
            return CGSize(width: itemWidth, height: 20 + 36)
        case .account:
            return CGSize(width: itemWidth, height: 46)
        case .price:
            return CGSize(width: itemWidth, height: 73)
        }
    }
    
}


private struct State: Equatable {
    var groupInfo: TBWeb3GroupInfoEntry
    var config: TBWeb3ConfigEntry
    var tagsLayoutConfig: TBItemListLabelsContentLayoutConfig
    var walletConnect:TBWalletConnect
    var payStatus:LocalPayStatus
    static func == (lhs: State, rhs: State) -> Bool {
        if lhs.groupInfo != rhs.groupInfo {
            return false
        }
        if lhs.walletConnect != rhs.walletConnect {
            return false
        }
        if lhs.payStatus != rhs.payStatus {
            return false
        }
        return true
    }
}


extension State {
    
    func updatePayStatus(_ newStatus: LocalPayStatus) -> State {
        var ret = self
        ret.payStatus = newStatus
        return ret
    }
}


private typealias DataMap = [Section : [Item]]


extension DataMap {
    fileprivate func validSortKeys() -> [Section] {
        let map = self.compactMapValues { $0.isEmpty ? nil : $0}
        return map.keys.sorted{$0.sectionId() < $1.sectionId()}
    }
}

fileprivate class BottomButtonView: UIView {
    
    struct Config {
        let gradientColors: [CGColor]
        let borderWidth: CGFloat
        let borderColor:CGColor
        let enbale: Bool
        let alpha: CGFloat
    }
    
    enum VType: Int, Equatable {
        case confirmPay
        case paying
        case cancel
        case continuePay
        case paySuccess
        case contact
        
        static func transfromTop(from payStatus: LocalPayStatus) -> VType?{
            switch payStatus {
            case .waitPay:
                return .confirmPay
            case .paying:
                return .paying
            case .paySuccess:
                return .paySuccess
            case .fail:
                return .continuePay
            }
        }
        
        func transfrom() -> Config{
            switch self {
            case .confirmPay, .continuePay:
                return Config(
                    gradientColors: [UIColor(rgb: 0x01B4FF).cgColor, UIColor(rgb: 0x8836DF).cgColor],
                    borderWidth: 0,
                    borderColor: UIColor.clear.cgColor,
                    enbale: true,
                    alpha: 1)
            case .paying:
                return Config(
                    gradientColors: [UIColor(rgb: 0x01B4FF).cgColor, UIColor(rgb: 0x8836DF).cgColor],
                    borderWidth: 0,
                    borderColor: UIColor.clear.cgColor,
                    enbale: false,
                    alpha: 0.5)
            case .cancel, .contact:
                return Config(
                    gradientColors: [UIColor.white.cgColor, UIColor.white.cgColor],
                    borderWidth: 1,
                    borderColor: UIColor(rgb: 0x01B4FF).cgColor,
                    enbale: true,
                    alpha: 1)
            case .paySuccess:
                return Config(
                    gradientColors: [UIColor(rgb: 0x44D320).cgColor, UIColor(rgb: 0x44D320).cgColor],
                    borderWidth: 0,
                    borderColor: UIColor.clear.cgColor,
                    enbale: true,
                    alpha: 1)
            }
        }
        
        
        static func transfromBottom(from payStatus: LocalPayStatus) -> VType? {
            switch payStatus {
            case .waitPay:
                return .cancel
            case .paying:
                return .cancel
            case .paySuccess:
                return nil
            case .fail:
                return .contact
            }
        }
    }
    
    class Content: UIView {
        
        var type: VType
        let stackView: UIStackView
        let icon: UIImageView
        let activityView: UIActivityIndicatorView
        let titleLabel: UILabel
        
        init(type:VType = .confirmPay) {
            self.type = type
            
            self.stackView = UIStackView()
            self.stackView.alignment = .center
            self.stackView.spacing = 8
            self.stackView.axis = .horizontal
            
            
            self.icon = UIImageView(image: UIImage(bundleImageName: "Settings/wallet/tb_ic_duihao_white"))
            self.icon.frame = CGRect(origin: .zero, size: CGSize(width: 12, height: 12))
            
            self.activityView = UIActivityIndicatorView(style: .medium)
            
            self.titleLabel = UILabel()
            self.titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
            
            super.init(frame: .zero)
            
            self.addSubview(self.stackView)
            
            self.stackView.snp.makeConstraints { make in
                make.edges.equalTo(self)
            }
            self.reload(type: self.type)
        }
        
        func reload(type:VType) {
            self.type = type
            for view in self.stackView.arrangedSubviews {
                view.removeFromSuperview()
            }
            self.activityView.stopAnimating()
            switch self.type {
            case .confirmPay:
                self.stackView.addArrangedSubview(self.titleLabel)
                self.titleLabel.text = TBLanguage.sharedInstance.localizable(TBLankey.group_pay_confirm_pay_confirm)
                self.titleLabel.textColor = .white
            case .cancel:
                self.stackView.addArrangedSubview(self.titleLabel)
                self.titleLabel.text = TBLanguage.sharedInstance.localizable(TBLankey.group_pay_confirm_pay_cancel)
                self.titleLabel.textColor = UIColor(rgb: 0x4B5BFF)
            case .paying:
                self.stackView.addArrangedSubview(self.activityView)
                self.stackView.addArrangedSubview(self.titleLabel)
                self.titleLabel.text = TBLanguage.sharedInstance.localizable(TBLankey.group_pay_confirm_paying)
                self.titleLabel.textColor = .white
                self.activityView.startAnimating()
            case .continuePay:
                self.stackView.addArrangedSubview(self.titleLabel)
                self.titleLabel.text = TBLanguage.sharedInstance.localizable(TBLankey.group_pay_confirm_pay_continue)
                self.titleLabel.textColor = .white
            case .paySuccess:
                self.stackView.addArrangedSubview(self.icon)
                self.stackView.addArrangedSubview(self.titleLabel)
                self.titleLabel.text = TBLanguage.sharedInstance.localizable(TBLankey.group_pay_confirm_pay_success)
                self.titleLabel.textColor = .white
            case .contact:
                self.stackView.addArrangedSubview(self.titleLabel)
                self.titleLabel.text = TBLanguage.sharedInstance.localizable(TBLankey.group_pay_confirm_pay_on)
                self.titleLabel.textColor = UIColor(rgb: 0x4B5BFF)
            }
            
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    var type: VType
    let gradientLayer: CAGradientLayer
    let contentView: Content
    var tapBlock:((VType) -> Void)?
    
    init(type:VType = .confirmPay) {
        self.type = type
        self.gradientLayer = CAGradientLayer()
        self.gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        self.gradientLayer.endPoint = CGPoint(x: 1, y: 0)
        self.gradientLayer.locations = [0,1]
        
        self.contentView = Content(type: self.type)
        
        super.init(frame: .zero)
        
        self.isUserInteractionEnabled = true
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tapAction)))
        
        self.layer.insertSublayer(self.gradientLayer, at: 0)
        self.addSubview(self.contentView)
        self.contentView.snp.makeConstraints { make in
            make.center.equalTo(self)
        }
        
        self.reload(with: self.type)
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = self.frame.height / 2.0
        self.clipsToBounds = true
        self.gradientLayer.frame = self.bounds
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func reload(with type:VType) {
        self.type = type
        self.contentView.reload(type: self.type)
        let config = self.type.transfrom()
        self.gradientLayer.colors = config.gradientColors
        self.layer.borderColor = config.borderColor
        self.layer.borderWidth = config.borderWidth
        self.isUserInteractionEnabled = config.enbale
        self.alpha = config.alpha
        
    }
    
    @objc func tapAction() {
        self.tapBlock?(self.type)
    }
}


class TBVipGroupOrderInfoImplController: UIViewController {
    
    let context: AccountContext
    private var presentationData: PresentationData
    private let presentationDataValue = Promise<PresentationData>()
    private var presentationDataDisposable: Disposable?
    func _parentViewController() -> TBVipGroupOrderViewController {
        return self.parent as! TBVipGroupOrderViewController
    }
    
    private let titleLabel: UILabel
    private let closeButton: UIButton
    private let collectionView: UICollectionView
    private var dataMap = DataMap()
    private let bottomView1: BottomButtonView
    private let bottomView2: BottomButtonView
    
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
        
        self.titleLabel = UILabel()
        self.titleLabel.numberOfLines = 0
        self.titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        self.titleLabel.textColor = .black
        self.titleLabel.text = TBLanguage.sharedInstance.localizable(TBLankey.group_pay_confirm_title)
        
        self.closeButton = UIButton(type: .custom)
        self.closeButton.setImage(UIImage(bundleImageName: "Settings/wallet/tb_ic_close_black"), for: .normal)
        
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
            walletConnect: walletConnect,
            payStatus: .waitPay
        )
        let statePromise = ValuePromise(initialState, ignoreRepeated: true)
        let stateValue = Atomic(value: initialState)
        let updateState: ((State) -> State) -> Void = { f in
            statePromise.set(stateValue.modify { f($0) })
        }
        
        self.statePromise = statePromise
        self.stateValue = stateValue
        self.updateState = updateState
        
        self.bottomView1 = BottomButtonView(type: .confirmPay)
        self.bottomView2 = BottomButtonView(type: .cancel)
        
        super.init(nibName: nil, bundle: nil)
        
        
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        
        self.closeButton.addTarget(self, action: #selector(self.closeAction), for: .touchUpInside)
        
        self.bottomView1.tapBlock = {[weak self] type in
            self?.tapBottomButton(type: type)
        }
        
        self.bottomView2.tapBlock = {[weak self] type in
            self?.tapBottomButton(type: type)
        }
        
        self.collectionView.contentInsetAdjustmentBehavior = .never
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.backgroundColor = .white
        self.collectionView.alwaysBounceVertical = true
        self.collectionView.register(TBVipGroupOrderInfoGroupCell.self, forCellWithReuseIdentifier: NSStringFromClass(TBVipGroupOrderInfoGroupCell.self))
        self.collectionView.register(TBVipGroupOrderInfoPayStateCell.self, forCellWithReuseIdentifier: NSStringFromClass(TBVipGroupOrderInfoPayStateCell.self))
        self.collectionView.register(TBVipGroupOrderInfoAccountCell.self, forCellWithReuseIdentifier: NSStringFromClass(TBVipGroupOrderInfoAccountCell.self))
        self.collectionView.register(TBVipGroupOrderInfoPriceCell.self, forCellWithReuseIdentifier: NSStringFromClass(TBVipGroupOrderInfoPriceCell.self))
        self.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: NSStringFromClass(UICollectionViewCell.self))
        
        self.view.addSubview(self.titleLabel)
        self.view.addSubview(self.closeButton)
        
        self.view.addSubview(self.collectionView)
        self.view.addSubview(self.bottomView1)
        self.view.addSubview(self.bottomView2)
        
        self.titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(20)
            make.top.equalTo(30)
            make.height.equalTo(42)
        }
        
        self.closeButton.snp.makeConstraints { make in
            make.centerY.equalTo(self.titleLabel)
            make.trailing.equalTo(-20)
            make.width.height.equalTo(24)
        }
        
        self.collectionView.snp.makeConstraints { make in
            make.top.equalTo(self.titleLabel.snp.bottom)
            make.leading.trailing.bottom.equalTo(0)
        }
        
        self.bottomView1.snp.makeConstraints { make in
            make.bottom.equalTo(-(78 + 34))
            make.centerX.equalTo(self.view)
            make.leading.equalTo(16)
            make.height.equalTo(46)
        }
        
        self.bottomView2.snp.makeConstraints { make in
            make.top.equalTo(self.bottomView1.snp.bottom).offset(16)
            make.centerX.equalTo(self.view)
            make.leading.equalTo(16)
            make.height.equalTo(46)
        }
        
        self.stateDisposable = self.statePromise.get().start(next: { [weak self] state in
            if let strongSelf = self {
                strongSelf.reloadView(state: state)
            }
        })
        
    }
    
    func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition){
        
    }
    
    private func tapBottomButton(type: BottomButtonView.VType) {
        switch type {
        case .confirmPay:
            debugPrint("")
            self.payOrder { [weak self] localStatus in
                self?.updateState{current in
                    return current.updatePayStatus(localStatus)
                }
            }
        case .paying:
            break
        case .cancel:
            self.closeAction()
        case .continuePay:
            debugPrint("")
            self.payOrder { [weak self] localStatus in
                self?.updateState{current in
                    return current.updatePayStatus(localStatus)
                }
            }
        case .paySuccess:
            break
        case .contact:
            if let nav = self._parentViewController().navigationController as? NavigationController {
                self.context.sharedContext.openResolvedUrl(ResolvedUrl.externalUrl("https://t.me/alphagramgroup"), context: self.context, urlContext: .generic, navigationController: nav, forceExternal: false, openPeer: { peerId, navigation in
                    
                }, sendFile: nil, sendSticker: nil, requestMessageActionUrlAuth: nil, joinVoiceChat: nil, present: { vc, a in
                    
                }, dismissInput: {[weak self] in
                    self?.view.window?.endEditing(true)
                }, contentContext: nil)
            }
            
            debugPrint("")
        }
    }
    
    
    private func payOrder(callBack:@escaping (LocalPayStatus)->Void) {
        
        
        let state = self.stateValue.with{$0}
        callBack(.paying)
        
        
        self.sendTransaction(groupInfo: state.groupInfo, walletConnect: state.walletConnect, config: state.config) {[weak self] hash in
            Queue.mainQueue().async { [weak self] in
                if hash.isEmpty { 
                    callBack(.fail)
                }else{ 
                    if let strongSelf = self {
                        
                        let controller = TBVipGroupOrderPayAuthViewController(context: strongSelf.context)
                        strongSelf._parentViewController().present(controller, in: .window(.root))
                        
                        let _ = TBWeb3GroupOrderInteractor().web3OrderPostSignal_(tx_hash: hash, group_id: String(state.groupInfo.id), payment_account: state.walletConnect.getAccountId()).start(
                            next: { [weak self, weak controller] order in 
                                callBack(.paySuccess)
                                
                                self?.cycleOrderResult(tx_hash: order.tx_hash) { [weak controller] _ in
                                    
                                    controller?.dismiss(animated: false)
                                    
                                }
                            },
                            error: { [weak controller] _ in 
                                controller?.dismiss(animated: false)
                                callBack(.fail)
                            })
                    }
                }
            }
        }
        
        
        
        
        
    }
    
    private func sendTransaction(groupInfo:TBWeb3GroupInfoEntry,
                                 walletConnect: TBWalletConnect,
                                 config: TBWeb3ConfigEntry,
                                 callBack:@escaping (String)->Void) {
        let chainType = TBWalletTransactionChain.transfer(from: Int(groupInfo.chain_id))?.rawValue
        let amountToWei = groupInfo.amount_to_wei
        let value = NSDecimalNumber(string: amountToWei.decimalString()).toBase(16)
        walletConnect.TBWallet_SendTransaction(from: walletConnect.getAccountId(), to: groupInfo.receipt_account, chainType: chainType ?? "", value: value, contractAddress: groupInfo.contract_address) { hash in
            callBack(hash)
        }
        
    }
    
    private func cycleOrderResult(tx_hash:String, callBack:@escaping (LocalPayStatus)->Void) {
        let _ = TBWeb3GroupOrderInteractor().cycleRequestOrderResultSignal(tx_hash: tx_hash).start(next: {[weak self] data in
            
            let inviteUrl = data.ship.url
            
            if !inviteUrl.isEmpty {
                
                if let strongSelf = self, let nav = strongSelf._parentViewController().navigationController as? NavigationController {
                    strongSelf.context.sharedContext.openResolvedUrl(ResolvedUrl.externalUrl( inviteUrl), context: strongSelf.context, urlContext: .generic, navigationController: nav, forceExternal: false, openPeer: { peerId, navigation in
                        
                    }, sendFile: nil, sendSticker: nil, requestMessageActionUrlAuth: nil, joinVoiceChat: nil, present: { vc, a in
                        
                    }, dismissInput: {[weak self] in
                        self?.view.window?.endEditing(true)
                    }, contentContext: nil)
                }
                callBack(.paySuccess)
            }else {
                callBack(.fail)
            }
        }, error: {error in
            callBack(.fail)
        })
    }
    
    @objc func closeAction() {
        self._parentViewController().dismiss(animated: true)
    }
    
    private func reloadView(state: State) {
        self.dataMap = TBVipGroupOrderInfoImplController.creatDataMap(state: state)
        self.collectionView.reloadData()
        
        if let topViewType = BottomButtonView.VType.transfromTop(from: state.payStatus){
            self.bottomView1.isHidden = false
            self.bottomView1.reload(with: topViewType)
        }else{
            self.bottomView1.isHidden = true
        }
        if let bottomViewType = BottomButtonView.VType.transfromBottom(from: state.payStatus){
            self.bottomView2.isHidden = false
            self.bottomView2.reload(with: bottomViewType)
        }else{
            self.bottomView2.isHidden = true
        }
    }
    
    deinit {
        self.presentationDataDisposable?.dispose()
        self.stateDisposable?.dispose()
    }
    
}


extension TBVipGroupOrderInfoImplController {
    private static func creatDataMap(state: State) -> DataMap {
        var ret = DataMap()
        
        var groupSectionList = [Item]()
        groupSectionList.append(.groupInfo(state.groupInfo))
        
        var payStatusSectionList = [Item]()
        payStatusSectionList.append(.payStatus(state.groupInfo, state.payStatus))
        
        var accountSectionList = [Item]()
        accountSectionList.append(.account(state.groupInfo, state.walletConnect.getAccountId(), "from"))
        accountSectionList.append(.account(state.groupInfo, state.groupInfo.receipt_account, "to"))
        
        var priceSectionList = [Item]()
        priceSectionList.append(.price(state.groupInfo, state.config))
        
        ret[.groupInfo] = groupSectionList
        ret[.payStatus] = payStatusSectionList
        ret[.account] = accountSectionList
        ret[.price] = priceSectionList
        
        ret = ret.compactMapValues{$0.isEmpty ? nil : $0}
        return ret
    }
}


extension TBVipGroupOrderInfoImplController: UICollectionViewDataSource {
    
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
            case .groupInfo(let groupInfo):
                if let cell = cell as? TBVipGroupOrderInfoGroupCell {
                    cell.reloadCell(item: groupInfo)
                }
            case .payStatus(let groupInfo, let payStatus):
                if let cell = cell as? TBVipGroupOrderInfoPayStateCell {
                    cell.reloadCell(item: groupInfo, payStatus: payStatus)
                }
            case .account(let groupInfo, let account, let title):
                if let cell = cell as? TBVipGroupOrderInfoAccountCell {
                    cell.reloadCell(item: groupInfo, title: title, account: account)
                }
            case .price(let groupInfo, let config):
                if let cell = cell as? TBVipGroupOrderInfoPriceCell {
                    cell.reloadCell(item: groupInfo, config: config)
                }
            }
            return cell
        }else{
            return collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(UICollectionViewCell.self), for: indexPath)
        }
    }
    
}


extension TBVipGroupOrderInfoImplController {
    
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


extension TBVipGroupOrderInfoImplController: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let item = self.safeItem(at: indexPath) {
            switch item {
            case .groupInfo:
                break
            case .payStatus:
                break
            case .account:
                break
            case .price:
                break
            }
        }
    }
}


extension TBVipGroupOrderInfoImplController : UICollectionViewDelegateFlowLayout {
    
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










