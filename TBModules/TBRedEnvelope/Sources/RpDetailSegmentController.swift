import UIKit
import SegementSlide
import JXSegmentedView
import Display
import Postbox
import TelegramCore
import AvatarNode
import AccountContext
import AsyncDisplayKit
import TelegramPresentationData
import TBBusinessNetwork
import TBAccount
import TBWalletCore
import HandyJSON
import SwiftSignalKit
import SDWebImage
import ProgressHUD
import TBLanguage
import TBWeb3Core
import SnapKit

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

final class RpDetailSegmentController: SegementSlideViewController {
    
    private let context: AccountContext
    private let rpDetail: RedEnvelopeDetail
    
    private let segmentedView = TBJXSegmentedView()
    let headerNode: HeaderNode
    
    let recordVc: RecordController
    let activityVc: ActivityController
    
    private let record: RecordItem?
    private let pageType: RPPageType
    private var layout: ContainerViewLayout?
    
    private lazy var segmentedDataSource: JXSegmentedTitleDataSource = {
        let dataSource = JXSegmentedTitleDataSource()
        dataSource.titleSelectedColor = UIColor(hexString: "#FF2F80ED")!
        dataSource.titleNormalFont = Font.bold(14)
        dataSource.itemSpacing = 36
        dataSource.isItemSpacingAverageEnabled = false
        dataSource.isTitleColorGradientEnabled = true
        return dataSource
    }()
    
    init(context: AccountContext, rpDetail: RedEnvelopeDetail) {
        self.context = context
        self.rpDetail = rpDetail
        self.headerNode = HeaderNode(context: context, rpDetail: rpDetail)
        self.recordVc = RecordController(context: context, rpDetail: rpDetail)
        self.activityVc = ActivityController(context: context)
        self.record = self.rpDetail.record.filter({$0.tg_user_id == context.account.peerId.id.description}).first
        self.pageType = self.rpDetail.getPageType(with: context.account.peerId.id.description)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.red
        self.defaultSelectedIndex = 0
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
        self.segmentedView.contentEdgeInsetLeft = 16
        self.segmentedView.contentEdgeInsetRight = 16
        return self.segmentedView
    }
    
    override func setupSwitcher() {
        super.setupSwitcher()
        self.segmentedDataSource.titles = self.titlesInSwitcher
        self.segmentedView.dataSource = self.segmentedDataSource
        self.segmentedView.contentScrollView = self.contentView.scrollView
    }
    
    var switcherViewHeight: CGFloat {
        return 48
    }
    
    var titlesInSwitcher: [String] {
        return ["", ""]
    }
    
    var badgesInSwitcher: [Int] {
        return [0, 0]
    }
    
    override var bouncesType: BouncesType {
        return .child
    }
    
    override func segementSlideHeaderView() -> UIView? {
        let headerView = self.headerNode.view
        headerView.translatesAutoresizingMaskIntoConstraints = false
        if let statusBarHeight = self.layout?.statusBarHeight {
            let height = (self.pageType == .unReceived ? 112.0 : 253.0 + 24) + 44.0 + statusBarHeight
            headerView.heightAnchor.constraint(equalToConstant: height).isActive = true
        } else {
            headerView.heightAnchor.constraint(equalToConstant: 0).isActive = true
        }
        return headerView
    }
    
    override func segementSlideContentViewController(at index: Int) -> SegementSlideContentScrollViewDelegate? {
        return index == 0 ? self.recordVc : self.activityVc
    }
    
    override var headerStickyHeightOffset: CGFloat {
        return self.headerNode.view.bounds.height
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView, isParent: Bool) {
        super.scrollViewDidScroll(scrollView, isParent: isParent)
    }
    
    func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        if self.layout == nil {
            self.layout = layout
            self.reloadData()
        }
        self.headerNode.update(layout: layout, transition: transition)
    }
}

extension RpDetailSegmentController: SegementSlideSwitcherDataSource {
    
    public var height: CGFloat {
        return self.switcherViewHeight
    }
    
    public var titles: [String] {
        return self.titlesInSwitcher
    }
    
}

extension RpDetailSegmentController: JXSegmentedViewDelegate {
    
    public func segmentedView(_ segmentedView: JXSegmentedView, didClickSelectedItemAt index: Int) {
        self.contentView.selectItem(at: index, animated: true)
    }
    
}

class HeaderNode: ASDisplayNode {
    
    private let context: AccountContext
    
    private let bgImageNode: ASImageNode
    private let backButton: UIButton
    private let avatarNode: ASImageNode
    private let nameNode: ASTextNode
    private let rpNode: ASTextNode
    private let statusNode: ASTextNode
    
    private let rpDetail: RedEnvelopeDetail
    private let record: RecordItem?
    private let pageType: RPPageType
    
    var backEvent: (() -> ())?
    init(context: AccountContext, rpDetail: RedEnvelopeDetail) {
        self.context = context
        
        self.bgImageNode = ASImageNode()
        self.backButton = UIButton()
        self.avatarNode = ASImageNode()
        self.nameNode = ASTextNode()
        self.rpNode = ASTextNode()
        self.statusNode = ASTextNode()
        
        self.rpDetail = rpDetail
        self.record = rpDetail.record.filter({$0.tg_user_id == context.account.peerId.id.description}).first
        self.pageType = rpDetail.getPageType(with: context.account.peerId.id.description)
        super.init()
        
        let peerId = PeerId(namespace: Namespaces.Peer.CloudUser, id: PeerId.Id._internalFromInt64Value(NSDecimalNumber(string: self.rpDetail.tg_user_id.decimalString()).int64Value))
        let _ = context.account.viewTracker.peerView(peerId).start(next: {[weak self] peerView in
            let user = peerView.peers[peerView.peerId] as? TelegramUser
            self?.updateNameBy(user)
            self?.updateAvatarBy(user)
        })
    }
    
    override func didLoad() {
        super.didLoad()
        
        let imageName = self.pageType == .unReceived ? "TBRedEnvelope/rp_detail_top_img_small" : "TBRedEnvelope/rp_detail_top_img_big"
        self.bgImageNode.image = UIImage(named: imageName)
        self.addSubnode(self.bgImageNode)
        
        self.backButton.setImage(UIImage(named: "Settings/wallet/tb_ic_back_white"), for: .normal)
        self.view.addSubview(self.backButton)
        self.backButton.addTarget(self, action: #selector(self.closeButtonClick), for: .touchUpInside)
        
        self.avatarNode.cornerRadius = 16
        self.avatarNode.borderWidth = 1
        self.avatarNode.borderColor = UIColor.white.cgColor
        self.avatarNode.backgroundColor = UIColor.lightGray
        self.addSubnode(self.avatarNode)
        
        self.addSubnode(self.nameNode)
        self.addSubnode(self.rpNode)
        self.addSubnode(self.statusNode)
        
        let isSender = self.context.account.peerId.id.description == self.rpDetail.tg_user_id
        let isGroup = self.rpDetail.source == 1
        if isGroup {
            switch self.pageType {
            case .waitOnline:
                let text = (self.record?.amount ?? "") + " \(self.rpDetail.currency_name)"
                self.rpNode.attributedText = NSAttributedString(string: text, font: Font.bold(42), textColor: UIColor(hexString: "#FFFFD4AC")!, paragraphAlignment: .center)
                self.rpNode.isHidden = false
                self.statusNode.attributedText = NSAttributedString(string: "...", font: Font.regular(14), textColor: UIColor(hexString: "#C4FFFFFF")!, paragraphAlignment: .center)
                self.statusNode.isHidden = false
            case .onlineSuccess:
                let text = (self.record?.amount ?? "") + " \(self.rpDetail.currency_name)"
                self.rpNode.attributedText = NSAttributedString(string: text, font: Font.bold(42), textColor: UIColor(hexString: "#FFFFD4AC")!, paragraphAlignment: .center)
                self.rpNode.isHidden = false
                
                self.statusNode.attributedText = NSAttributedString(string: self.record?.usd_amount ?? "", font: Font.regular(14), textColor: UIColor(hexString: "#C4FFFFFF")!, paragraphAlignment: .center)
                self.statusNode.isHidden = false
            case .overTime:
                self.rpNode.attributedText = NSAttributedString(string: "", font: Font.bold(24), textColor: .white, paragraphAlignment: .center)
                self.rpNode.isHidden = false
                let text = isSender ? "" : ""
                self.statusNode.attributedText = NSAttributedString(string: text, font: Font.regular(14), textColor: UIColor(hexString: "#C4FFFFFF")!, paragraphAlignment: .center)
                self.statusNode.isHidden = false
            case .empty:
                self.rpNode.attributedText = NSAttributedString(string: "", font: Font.bold(24), textColor: .white, paragraphAlignment: .center)
                self.rpNode.isHidden = false
                let text = isSender ? " " : ""
                self.statusNode.attributedText = NSAttributedString(string: text, font: Font.regular(14), textColor: UIColor(hexString: "#C4FFFFFF")!, paragraphAlignment: .center)
                self.statusNode.isHidden = false
            case .unReceived:
                self.rpNode.isHidden = true
                self.statusNode.isHidden = true
            }
        } else {
            switch self.pageType {
            case .waitOnline:
                if isSender {
                    self.rpNode.attributedText = NSAttributedString(string: "", font: Font.bold(24), textColor: .white, paragraphAlignment: .center)
                    self.rpNode.isHidden = false
                    self.statusNode.isHidden = true
                } else {
                    let text = (self.record?.amount ?? "") + " \(self.rpDetail.currency_name)"
                    self.rpNode.attributedText = NSAttributedString(string: text, font: Font.bold(42), textColor: UIColor(hexString: "#FFFFD4AC")!, paragraphAlignment: .center)
                    self.rpNode.isHidden = false
                    self.statusNode.attributedText = NSAttributedString(string: "...", font: Font.regular(14), textColor: UIColor(hexString: "#C4FFFFFF")!, paragraphAlignment: .center)
                    self.statusNode.isHidden = false
                }
            case .onlineSuccess, .empty:
                if isSender {
                    self.rpNode.attributedText = NSAttributedString(string: "", font: Font.bold(24), textColor: .white, paragraphAlignment: .center)
                    self.rpNode.isHidden = false
                    self.statusNode.isHidden = true
                } else {
                    let text = (self.record?.amount ?? "") + " \(self.rpDetail.currency_name)"
                    self.rpNode.attributedText = NSAttributedString(string: text, font: Font.bold(42), textColor: UIColor(hexString: "#FFFFD4AC")!, paragraphAlignment: .center)
                    self.rpNode.isHidden = false
                    
                    self.statusNode.attributedText = NSAttributedString(string: self.record?.usd_amount ?? "", font: Font.regular(14), textColor: UIColor(hexString: "#C4FFFFFF")!, paragraphAlignment: .center)
                    self.statusNode.isHidden = false
                }
            case .overTime:
                let rpText = isSender ? "" : ""
                self.rpNode.attributedText = NSAttributedString(string: rpText, font: Font.bold(24), textColor: .white, paragraphAlignment: .center)
                self.rpNode.isHidden = false
                let statusText = isSender ? "" : ""
                self.statusNode.attributedText = NSAttributedString(string: statusText, font: Font.regular(14), textColor: UIColor(hexString: "#C4FFFFFF")!, paragraphAlignment: .center)
                self.statusNode.isHidden = false
            case .unReceived:
                self.rpNode.isHidden = true
                self.statusNode.isHidden = true
            }
        }
    }
    
    func update(layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        let statusBarHeight = layout.statusBarHeight ?? 20.0
        let navHeight = 44.0 + statusBarHeight
        let height = (self.pageType == .unReceived ? 112.0 : 253.0) + navHeight
        transition.updateFrame(node: self.bgImageNode, frame: CGRect(x: 0, y: 0, width: layout.size.width, height: height))
        transition.updateFrame(view: self.backButton, frame: CGRect(x: 6, y: statusBarHeight, width: 44, height: 44))
        transition.updateFrame(node: self.avatarNode, frame: CGRect(x: (layout.size.width - 32) / 2.0, y: navHeight + 4, width: 32, height: 32))
        transition.updateFrame(node: self.nameNode, frame: CGRect(x: 16, y: navHeight + 40, width: layout.size.width - 32, height: 18))
        
        transition.updateFrame(node: self.rpNode, frame: CGRect(x: 16, y: navHeight + 83, width: layout.size.width - 32, height: 49))
        transition.updateFrame(node: self.statusNode, frame: CGRect(x: 16, y: navHeight + 142, width: layout.size.width - 32, height: 20))
    }
    
    private func updateNameBy(_ user: TelegramUser?) {
        guard let user = user else { return }
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
        let text = (name.isEmpty ? "***" : name) + " "
        self.nameNode.attributedText = NSAttributedString(string: text, font: Font.bold(15), textColor: .white, paragraphAlignment: .center)
    }
    
    private func updateAvatarBy(_ user: TelegramUser?) {
        guard let user = user else { return }
        let peer = EnginePeer(user)
        if let signal = peerAvatarImage(account: self.context.account, peerReference: PeerReference(peer._asPeer()), authorOfMessage: nil, representation: peer.smallProfileImage, displayDimensions: CGSize(width: 60, height: 60)) {
            let _ = signal.start {[weak self] a in
                self?.avatarNode.image = a?.0
            }
        }else {
            self.avatarNode.image = nil
        }
    }
    
    @objc func closeButtonClick() {
        self.backEvent?()
    }
}

class AvatarItem {
    
    private let context: AccountContext
    private let peerId: PeerId
    
    let userNamePromise: ValuePromise<String> = ValuePromise()
    let avatarPromise: ValuePromise<UIImage?> = ValuePromise()
    
    init(context: AccountContext, peerId: PeerId) {
        self.context = context
        self.peerId = peerId
        
        let _ = context.account.viewTracker.peerView(peerId).start {[weak self] peerView in
            let user = peerView.peers[peerView.peerId] as? TelegramUser
            self?.updateNameBy(user)
            self?.updateAvatarBy(user)
        }
    }
    
    private func updateNameBy(_ user: TelegramUser?) {
        guard let user = user else { return }
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
        self.userNamePromise.set(name)
    }
    
    private func updateAvatarBy(_ user: TelegramUser?) {
        guard let user = user else { return }
        let peer = EnginePeer(user)
        if let signal = peerAvatarImage(account: self.context.account, peerReference: PeerReference(peer._asPeer()), authorOfMessage: nil, representation: peer.smallProfileImage, displayDimensions: CGSize(width: 60, height: 60)) {
            let _ = signal.start {[weak self] a in
                self?.avatarPromise.set(a?.0)
            }
        }else {
            self.avatarPromise.set(nil)
        }
    }
}


typealias RecordCellItem = (record: RecordItem, avatarItem: AvatarItem)

class RecordCell: UITableViewCell {

    private let avatarView = UIImageView()
    private let nameLab = UILabel()
    private let amountLab = UILabel()
    private let addressLab = UILabel()
    private let priceLab = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        
        self.avatarView.layer.cornerRadius = 20
        self.avatarView.backgroundColor = UIColor.red
        self.addSubview(self.avatarView)
        
        self.nameLab.textColor = UIColor(hexString: "#FF1A1A1D")!
        self.nameLab.font = Font.medium(16)
        self.addSubview(self.nameLab)
        
        self.amountLab.textColor = UIColor(hexString: "#FFD0A782")!
        self.amountLab.font = Font.medium(15)
        self.amountLab.textAlignment = .right
        self.addSubview(self.amountLab)
        
        self.addressLab.textColor = UIColor(hexString: "#FF828282")!
        self.addressLab.font = Font.regular(14)
        self.addSubview(self.addressLab)
        
        self.priceLab.textColor = UIColor(hexString: "#FFB5B5B5")
        self.priceLab.font = Font.medium(14)
        self.priceLab.textAlignment = .right
        self.addSubview(self.priceLab)
        
        self.nameLab.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        self.amountLab.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        self.addressLab.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        self.priceLab.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        
        self.avatarView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
            make.width.height.equalTo(40)
        }
        
        self.nameLab.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(11)
            make.leading.equalToSuperview().offset(68)
        }
        
        self.amountLab.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(11)
            make.trailing.equalToSuperview().offset(-16)
            make.leading.equalTo(self.nameLab.snp_trailingMargin).offset(20)
        }
        
        self.addressLab.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(34)
            make.leading.equalToSuperview().offset(68)
        }
        
        self.priceLab.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(34)
            make.trailing.equalToSuperview().offset(-16)
            make.leading.equalTo(self.addressLab.snp_trailingMargin).offset(20)
        }
        
    }
    
    func updateRecord(item: RecordCellItem, symbol:String) {
        self.amountLab.text = item.record.amount + " " + symbol
        self.addressLab.text = item.record.receipt_account.simpleAddress()
        self.priceLab.text = "$" + item.record.usd_amount
        let _ = (item.avatarItem.avatarPromise.get() |> deliverOnMainQueue).start(next: {[weak self] image in
            self?.avatarView.image = image
        })
        let _ = (item.avatarItem.userNamePromise.get() |> deliverOnMainQueue).start {[weak self] name in
            self?.nameLab.text = name
        }
    }
}

class RecordHeaderView: UITableViewHeaderFooterView {
    
    let titleLab = UILabel()
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        self.titleLab.textColor = UIColor(hexString: "#FF868686")!
        self.titleLab.font = Font.medium(15)
        self.contentView.addSubview(self.titleLab)
        self.titleLab.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class RecordController: ViewController, SegementSlideContentScrollViewDelegate {
    
    public let context: AccountContext
    private var presentationData: PresentationData
    private let presentationDataValue = Promise<PresentationData>()
    private var presentationDataDisposable: Disposable?
    
    private let tableView: UITableView
    @objc var scrollView: UIScrollView {
        get {
            return self.tableView
        }
    }
    
    private let rpDetail: RedEnvelopeDetail
    private var cellItems = [RecordCellItem]()
    
    public init(context: AccountContext, rpDetail: RedEnvelopeDetail) {
        self.context = context
        self.presentationData = (context.sharedContext.currentPresentationData.with { $0 })
        self.presentationDataValue.set(.single(self.presentationData))
        self.tableView = UITableView(frame: .zero, style: .plain)
        self.rpDetail = rpDetail
        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData))
        for rd in rpDetail.record {
            let peerId = PeerId(namespace: Namespaces.Peer.CloudUser, id: PeerId.Id._internalFromInt64Value(NSDecimalNumber(string: rd.tg_user_id.decimalString()).int64Value))
            let avatar = AvatarItem(context: context, peerId: peerId)
            let ci = RecordCellItem(record: rd, avatarItem: avatar)
            self.cellItems.append(ci)
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
        self.tableView.contentInsetAdjustmentBehavior = .never
        self.view.addSubview(self.tableView)
        self.tableView.delegate = self
        self.tableView.dataSource = self
        if #available(iOS 15.0, *) {
            self.tableView.sectionHeaderTopPadding = 0
        }
        self.tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        self.tableView.register(RecordCell.self, forCellReuseIdentifier: String(describing: RecordCell.self))
        self.tableView.register(RecordHeaderView.self, forHeaderFooterViewReuseIdentifier: String(describing: RecordHeaderView.self))
        self.tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        
    }
}

extension RecordController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.cellItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: RecordCell.self)) as? RecordCell {
            if indexPath.row < self.cellItems.count {
                let record = self.cellItems[indexPath.row]
                cell.updateRecord(item: record, symbol: self.rpDetail.currency_name)
            } else {
                cell.isHidden = true
            }
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: String(describing: RecordHeaderView.self)) as? RecordHeaderView {
            let isSender = self.context.account.peerId.id.description == self.rpDetail.tg_user_id
            let isGroup = self.rpDetail.source == 1
            let pageType = self.rpDetail.getPageType(with: context.account.peerId.id.description)
            if isGroup {
                headerView.titleLab.text = self.rpDetail.rpNumberStr()
            } else {
                switch pageType {
                case .waitOnline:
                    let senderText = " " + self.rpDetail.amount + self.rpDetail.currency_name + ", "
                    headerView.titleLab.text = isSender ? senderText : ""
                case .onlineSuccess, .empty:
                    headerView.titleLab.text = isSender ? "" : ""
                case .overTime:
                    let rpText = isSender ? "" : ""
                    headerView.titleLab.text = rpText
                case .unReceived:
                    let rpText = isSender ? "" : ""
                    headerView.titleLab.text = rpText
                }
            }
            return headerView
        }
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return 48.0
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
}



class ActivityCell: UITableViewCell {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
    
    }
    
    func updateRecord(item: RecordItem) {
        
    }
}

class ActivityController: ViewController, SegementSlideContentScrollViewDelegate {
    
    public let context: AccountContext
    private var presentationData: PresentationData
    private let presentationDataValue = Promise<PresentationData>()
    private var presentationDataDisposable: Disposable?
    
    private let tableView: UITableView
    @objc var scrollView: UIScrollView {
        get {
            return self.tableView
        }
    }
    
    public init(context: AccountContext) {
        self.context = context
        self.presentationData = (context.sharedContext.currentPresentationData.with { $0 })
        self.presentationDataValue.set(.single(self.presentationData))
        self.tableView = UITableView(frame: .zero, style: .plain)
        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData))
        
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.presentationDataDisposable?.dispose()
    }
    
    
    public override func displayNodeDidLoad() {
        super.displayNodeDidLoad()
    }
    
    
    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        
    }
    
    
}
