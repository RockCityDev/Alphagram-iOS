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
import TelegramCore
import TBLanguage
import QrCode
import QrCodeUI
import DeviceAccess
import TBDisplay


public struct TBVipTransactionListEntry: Equatable {
    
    let transactionItem: TBUserTransferListEntity.Item
    let paymentUserInfo: NetworkInfo?
    let receiptUserInfo: NetworkInfo?
    
    public static func == (lhs: TBVipTransactionListEntry, rhs: TBVipTransactionListEntry) -> Bool {
        if lhs.transactionItem != rhs.transactionItem {
            return false
        }
        if lhs.paymentUserInfo != rhs.paymentUserInfo {
            return false
        }
        if lhs.receiptUserInfo != rhs.paymentUserInfo {
            return false
        }
        return true
    }
}

public struct TBVipSelectTransactionEntry: Equatable {
    let tgUser: TelegramUser?
    let transactionItem: TBUserTransferListEntity.Item
    
    public static func == (lhs: TBVipSelectTransactionEntry, rhs: TBVipSelectTransactionEntry) -> Bool {
        if lhs.tgUser != rhs.tgUser {
            return false
        }
        if lhs.transactionItem != rhs.transactionItem {
            return false
        }
        return true
    }
}

public struct TBVipContactListEntry: Equatable {
    
    let tgUser: TelegramUser
    let tgInfo: NetworkInfo
    
    public static func == (lhs: TBVipContactListEntry, rhs: TBVipContactListEntry) -> Bool {
        if lhs.tgUser != rhs.tgUser {
            return false
        }
        if lhs.tgInfo != rhs.tgInfo {
            return false
        }
        return true
    }
}


private enum Section: Equatable {
    case account
    case recentTransaction
    case contacts
    case promote
    static func == (lhs: Section, rhs: Section) -> Bool {
        if lhs.sectionId() == rhs.sectionId() {
            return true
        }else{
            return false
        }
    }
    
    func sectionId() -> Int64 {
        switch self {
        case .account:
            return 1
        case .recentTransaction:
            return 2
        case .contacts:
            return 3
        case .promote:
            return 4
        }
    }
    
    func sectionInset() -> UIEdgeInsets {
        switch self {
        case .account:
            return UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        case .recentTransaction:
            return UIEdgeInsets(top: 24, left: 20, bottom: 0, right: 20)
        case .contacts:
            return UIEdgeInsets(top: 4, left: 20, bottom: 0, right: 20)
        case .promote:
            return UIEdgeInsets(top: 27, left: 20, bottom: 0, right: 20)
        }
    }
    
    func minimumLineSpacing() -> CGFloat {
        switch self {
        case .account:
            return 16
        case .recentTransaction:
            return 4
        case .contacts:
            return 4
        case .promote:
            return 0
        }
    }
    
    func minimumInteritemSpacing() -> CGFloat {
        switch self {
        case .account:
            return 16
        case .recentTransaction:
            return 4
        case .contacts:
            return 4
        case .promote:
            return 0
        }
    }
}


private enum Item: Equatable {

    case header(Section, String, UIColor)
    case fromAndTo(
        wallet:TBWallet,
        mySelf:TelegramUser?,
        selectContact: TBVipContactListEntry?,
        selectTransaction:TBVipSelectTransactionEntry?,
        inputText:String,
        hiddenTips:Bool)
    case transaction(TBUserTransferListEntity.Item)
    case transactionPlaceHolder
    case seperatorLine
    case contact(TBVipContactListEntry)
    case contactPlaceHodler
    case promote(String, String)
    
    func cellClass() -> AnyClass {
        switch self {
        case .header:
            return TBTransferToItHeaderCell.self
        case .fromAndTo:
            return TBTransferToItFromToCell.self
        case .transaction:
            return TBTransferToItRencentTransactionCell.self
        case .transactionPlaceHolder, .contactPlaceHodler:
            return TBTransferToItListPlaceholderCell.self
        case .seperatorLine:
            return TBTransferToItSeperatorCell.self
        case .contact:
            return TBTransferToItContactCell.self
        case .promote:
            return TBTransferToItBottomPromoteCell.self
        }
    }
    
    func section() -> Section {
        switch self {
        case .header(let section, _, _):
            return section
        case .fromAndTo:
            return .account
        case .transaction, .transactionPlaceHolder, .seperatorLine:
            return .recentTransaction
        case .contact, .contactPlaceHodler:
            return .contacts
        case .promote:
            return .promote
        }
    }
    
    func size(viewSize:CGSize = UIScreen.main.bounds.size) -> CGSize {
        let itemWidth = viewSize.width - self.section().sectionInset().left - self.section().sectionInset().right
        switch self {
        case .header:
            return CGSize(width: itemWidth, height: 22)
        case .fromAndTo(wallet: _, mySelf: _, selectContact: _, selectTransaction:_, inputText: _, hiddenTips: let hiddenTips):
            let height:CGFloat
            if hiddenTips {
                height = 64 * 2
            }else{
                height = 64 * 2 + 28
            }
            return CGSize(width: itemWidth, height: height)
        case .transaction:
            return CGSize(width: itemWidth, height: 56)
        case .transactionPlaceHolder:
            return CGSize(width: itemWidth, height: 56)
        case .seperatorLine:
            return CGSize(width: itemWidth, height: 20)
        case .contact:
            return CGSize(width: itemWidth, height: 56)
        case .contactPlaceHodler:
            return CGSize(width: itemWidth, height: 56)
        case .promote:
            return CGSize(width: itemWidth, height: 42)
        }
    }
    
    func itemId() -> Int64 {
        switch self {
        case .header:
            return 1
        case .fromAndTo:
            return 2
        case .transaction:
            return 3
        case .transactionPlaceHolder:
            return 4
        case .seperatorLine:
            return 5
        case .contact:
            return 6
        case .contactPlaceHodler:
            return 7
        case .promote:
            return 8
        }
    }
    
    static func == (lhs: Item, rhs: Item) -> Bool {
        return lhs.itemId() == rhs.itemId()
    }

}


private struct State: Equatable {
    
    struct ValidRet {
        enum To {
            case selectContact(TBVipContactListEntry)
            case input(String)
            case selectTransaction(TBVipSelectTransactionEntry)
        }
        let from: TBWallet
        let to: To
    }
    var context: AccountContext
    var wallet:TBWallet
    var selectContact: TBVipContactListEntry?
    var mySelf:TelegramUser? = nil
    var myNetWorkInfo: NetworkInfo? = nil
    var inputAddress:String = ""
    var selectTranSactionEntry: TBVipSelectTransactionEntry? = nil
    var transactions = [TBUserTransferListEntity.Item]()
    var contanctList = [TBVipContactListEntry]()
    
    static func == (lhs: State, rhs: State) -> Bool {
        if lhs.wallet != rhs.wallet {
            return false
        }
        if lhs.selectContact != rhs.selectContact {
            return false
        }
        if !lhs.transactions.elementsEqual(rhs.transactions) {
            return false
        }
        
        if lhs.mySelf != rhs.mySelf {
            return false
        }
        
        if lhs.inputAddress != rhs.inputAddress {
            return false
        }
        
        if !lhs.contanctList.elementsEqual(rhs.contanctList) {
            return false
        }
        
        if lhs.myNetWorkInfo != rhs.myNetWorkInfo{
            return false
        }
        
        if lhs.selectTranSactionEntry != rhs.selectTranSactionEntry {
            return false
        }
    
        return true
    }
}


extension State {
    func transferValidRet() -> ValidRet? {
        if self.isValidToAddress() {
            if let selectContact = self.selectContact {
                return ValidRet(from: self.wallet, to: .selectContact(selectContact))
            }else if let selectTransaction = self.selectTranSactionEntry {
                return ValidRet(from: self.wallet, to: .selectTransaction(selectTransaction))
            } else{
                return ValidRet(from: self.wallet, to: .input(self.inputAddress))
            }
        }else{
            return nil
        }
        return nil
    }
    func isValidToAddress() -> Bool {
        if let _ = self.selectContact  {
            return true
        }
        if let _ = self.selectTranSactionEntry {
            return true
        }
        if self.inputAddress.lowercased().hasPrefix("0x") {
            return true
        }
        return false
    }
}


extension State {
    
    
    func refreshTransactions(_ items: [TBUserTransferListEntity.Item]) -> State {
        var ret = self
        ret.transactions = items
        return ret
    }
    
    
    func refreshContactList(_ contactList: [TBVipContactListEntry],
                            _ mySelf: TelegramUser,
                            _ myNetWorkInfo: NetworkInfo) -> State {
        var ret = self
        ret.contanctList = contactList
        ret.mySelf = mySelf
        ret.myNetWorkInfo = myNetWorkInfo
        return ret
    }
    
    
    func refreshWalletConnect(_ wallet: TBWallet) -> State {
        var ret = self
        ret.wallet = wallet
        return ret
    }
    
    
    func refreshSelectContact(_ entry: TBVipContactListEntry) -> State {
        var ret = self
        if let address = entry.tgInfo.wallet_info.first?.wallet_address, !address.isEmpty {
            ret.inputAddress = address
            ret.selectContact = entry
            ret.selectTranSactionEntry = nil
        }
        return ret
    }
    
    
    func refreshSelectTransaction(_ entry: TBVipSelectTransactionEntry) ->State {
        var ret = self
        let address = entry.transactionItem.relativeWalletAddress()
        if !address.isEmpty {
            ret.inputAddress = address
            ret.selectTranSactionEntry = entry
            ret.selectContact = nil
        }
        return ret
    }
    
    
    func refreshInputText(_ input: String) -> State {
        var ret = self
        ret.inputAddress = input
        if let selectContact = self.selectContact { 
            if let address = selectContact.tgInfo.wallet_info.first?.wallet_address, address != ret.inputAddress {
                ret.selectContact = nil
            }
        }
        if let selectTransaction = self.selectTranSactionEntry { 
            if selectTransaction.transactionItem.relativeWalletAddress() != ret.inputAddress {
                ret.selectTranSactionEntry = nil
            }
        }
        
        return ret
    }
    
}


private typealias DataMap = [Section : [Item]]


extension DataMap {
    fileprivate func validSortKeys() -> [Section] {
        let map = self.compactMapValues { $0.isEmpty ? nil : $0}
        return map.keys.sorted{$0.sectionId() < $1.sectionId()}
    }
    fileprivate func isEqualToOther(other:DataMap) -> Bool {
        var selfItems = [Item]()
        for key in self.validSortKeys() {
            selfItems.append(contentsOf: self[key] ?? [Item]())
        }
        
        var otherItems = [Item]()
        for key in other.validSortKeys() {
            otherItems.append(contentsOf: other[key] ?? [Item]())
        }
        return selfItems.elementsEqual(otherItems)
    }
}

private class BottomButtonView: UIView {
    
    private let titleLabel: UILabel
    private let gradientLayer: CAGradientLayer
    
    fileprivate var tapBlock:(() -> Void)?
    
    override init(frame: CGRect) {
        
        self.titleLabel = UILabel()
        self.titleLabel.textColor = UIColor(rgb: 0xFFFFFF)
        self.titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        self.titleLabel.text = TBLanguage.sharedInstance.localizable(TBLankey.transfer_activity_transfer_nextstep)
        
        self.gradientLayer = CAGradientLayer()
        self.gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        self.gradientLayer.endPoint = CGPoint(x: 1, y: 0)
        self.gradientLayer.colors = [UIColor(rgb: 0x01B4FF).cgColor, UIColor(rgb: 0x8836DF)]
        self.gradientLayer.locations = [0, 1]
        super.init(frame: frame)
        
        self.backgroundColor = UIColor(rgb: 0x8836DF)
        
        self.addSubview(self.titleLabel)
        self.layer.insertSublayer(self.gradientLayer, at: 0)
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
        self.gradientLayer.frame = self.bounds
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func tapAction() {
        self.tapBlock?()
    }
}

class TBTransferToItImplController: UIViewController {
    let context: AccountContext
    weak private var fromToCell: TBTransferToItFromToCell?
    private var presentationData: PresentationData
    private let presentationDataValue = Promise<PresentationData>()
    private var presentationDataDisposable: Disposable?
    func _parentViewController() -> TBTransferToItController {
        return self.parent as! TBTransferToItController
    }
    
    let closeButton: UIButton
    let titleLabel: UILabel
    let collectionView: UICollectionView
    private var dataMap = DataMap()
    private let bottomView: BottomButtonView
    private let statePromise: ValuePromise<State>
    private let stateValue: Atomic<State>
    private let updateState: ((State) -> State) -> Void
    private var stateDisposable: Disposable?
    private var userTransferDisposable: Disposable?
    
    
    private let contactPeersViewPromise = Promise<(EngineContactList, EnginePeer?)>()
    
    init(context: AccountContext,
         wallet:TBWallet, inputAddress: String = "") {
        self.context = context
        self.presentationData = (context.sharedContext.currentPresentationData.with { $0 })
        self.presentationDataValue.set(.single(self.presentationData))
        
        
        self.closeButton = UIButton(type: .custom)
        self.closeButton.setImage(UIImage(bundleImageName: "Nav/nav_close_icon"), for: .normal)
        self.closeButton.contentEdgeInsets = UIEdgeInsets(top: 3, left: 3, bottom: 3, right: 3)
        
        self.titleLabel = UILabel()
        self.titleLabel.numberOfLines = 1
        self.titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        self.titleLabel.textColor = UIColor(rgb: 0x000000)
        self.titleLabel.text = TBLanguage.sharedInstance.localizable(TBLankey.transfer_activity_title)
        
        let layout = UICollectionViewFlowLayout()
        self.collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        var initialState = State(context: context, wallet: wallet)
        initialState.inputAddress = inputAddress
        let statePromise = ValuePromise(initialState, ignoreRepeated: true)
        let stateValue = Atomic(value: initialState)
        let updateState: ((State) -> State) -> Void = { f in
            statePromise.set(stateValue.modify { f($0) })
        }

        self.statePromise = statePromise
        self.stateValue = stateValue
        self.updateState = updateState
        
        self.bottomView = BottomButtonView()

        super.init(nibName: nil, bundle: nil)
        
        self.contactPeersViewPromise.set(self.context.engine.data.subscribe(
            TelegramEngine.EngineData.Item.Contacts.List(includePresences: true),
            TelegramEngine.EngineData.Item.Peer.Peer(id: self.context.engine.account.peerId)
        ))
    
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor(rgb: 0xFFFFFF)
        
        self.closeButton.addTarget(self, action: #selector(self.tapClose), for: .touchUpInside)
        
        self.collectionView.contentInsetAdjustmentBehavior = .never
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.backgroundColor = .white
        self.collectionView.alwaysBounceVertical = false

        self.collectionView.register(TBTransferToItHeaderCell.self, forCellWithReuseIdentifier: NSStringFromClass(TBTransferToItHeaderCell.self))
        self.collectionView.register(TBTransferToItFromToCell.self, forCellWithReuseIdentifier: NSStringFromClass(TBTransferToItFromToCell.self))
        self.collectionView.register(TBTransferToItRencentTransactionCell.self, forCellWithReuseIdentifier: NSStringFromClass(TBTransferToItRencentTransactionCell.self))
        self.collectionView.register(TBTransferToItContactCell.self, forCellWithReuseIdentifier: NSStringFromClass(TBTransferToItContactCell.self))
        self.collectionView.register(TBTransferToItListPlaceholderCell.self, forCellWithReuseIdentifier: NSStringFromClass(TBTransferToItListPlaceholderCell.self))
        self.collectionView.register(TBTransferToItSeperatorCell.self, forCellWithReuseIdentifier: NSStringFromClass(TBTransferToItSeperatorCell.self))
        self.collectionView.register(TBTransferToItBottomPromoteCell.self, forCellWithReuseIdentifier: NSStringFromClass(TBTransferToItBottomPromoteCell.self))
        self.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: NSStringFromClass(UICollectionViewCell.self))
        
        self.bottomView.tapBlock = {[weak self] in
            if  let strongSelf = self  {
                let state = strongSelf.stateValue.with{$0}
                if let ret = state.transferValidRet() {
                    
                    let vc: TBTransferAssetController
                    switch ret.to {
                    case .input(let string):
                        vc = TBTransferAssetController(context: strongSelf.context, from: ret.from, toAddress: string)
                    case .selectContact(let listEntry):
                        vc = TBTransferAssetController(context: strongSelf.context, from: ret.from, toPeerId: listEntry.tgUser.id, toAddress: listEntry.tgInfo.wallet_info.first?.wallet_address ?? "")
                    case .selectTransaction(let transaction):
                        vc = TBTransferAssetController(context: strongSelf.context, from: ret.from, toPeerId: transaction.tgUser?.id, toAddress: transaction.transactionItem.relativeWalletAddress())
                    }
                    
                    strongSelf._parentViewController().present(vc, in: .window(.root))
                }
            }
        }
        
        self.view.addSubview(self.collectionView)
        self.view.addSubview(self.titleLabel)
        self.view.addSubview(self.closeButton)
        self.view.addSubview(self.bottomView)
        
        self.titleLabel.snp.makeConstraints { make in
            make.centerX.equalTo(self.view)
            make.top.equalTo(26)
            make.height.equalTo(22)
        }
        self.closeButton.snp.makeConstraints { make in
            make.centerY.equalTo(self.titleLabel)
            make.trailing.equalTo(-12)
            make.width.height.equalTo(30)
        }
        
        self.bottomView.snp.makeConstraints { make in
            make.bottom.equalTo(-22)
            make.centerX.equalTo(self.view)
            make.leading.equalTo(16)
            make.height.equalTo(46)
        }
        self.collectionView.snp.makeConstraints { make in
            make.top.equalTo(82)
            make.leading.trailing.equalTo(self.view)
            make.bottom.equalTo(self.bottomView.snp.top)
        }
    
        self.stateDisposable = self.statePromise.get().start(next: { [weak self] state in
            if let strongSelf = self {
                strongSelf.reloadView(state: state)
            }
        })
        self.reloadData()
        NotificationCenter.default.addObserver(self, selector: #selector(self.safeDelayReloadData), name:UIApplication.didBecomeActiveNotification , object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.safeDelayReloadData()
    }

    
    func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition){
        
    }
    
    @objc func tapClose() {
        self._parentViewController().dismiss(animated: true)
    }

    
    private func creatContatsListSignal(context: AccountContext) -> Signal<([TBVipContactListEntry], TelegramUser, NetworkInfo), NoError> {
        let signal = self.contactPeersViewPromise.get()
        |> map({ view in
            let mySelf = view.1?._asPeer() as? TelegramUser
            let peerList = view.0.peers.compactMap { enginePeer in
                if let ret = enginePeer._asPeer() as? TelegramUser {
                    return ret
                }else{
                    return nil
                }
            }
            let ret:(TelegramUser?, [TelegramUser]) = (mySelf, peerList)
            return ret
        })
    
        
        return signal |> mapToSignal({[weak self] view in
            return Signal {[weak self] subscriber in
                let (mySelf, peerList) = view
                if let mySelf = mySelf, !peerList.isEmpty{
                    var tgUserIds = [Int64]()
                    for user in peerList {
                        tgUserIds.append(user.id.id._internalGetInt64Value())
                    }
                    let _ = TBTransferAssetInteractor.fetchNetworkInfoMap(by: tgUserIds.map{String($0)}).start(next: {[weak self] infoMap  in
                        
                        let myNetWorkInfo: NetworkInfo
                        if let info = infoMap[mySelf.id.id._internalGetInt64Value()]{
                            myNetWorkInfo = info
                        }else{
                           myNetWorkInfo = NetworkInfo()
                        }
                        var retList  =  [TBVipContactListEntry]()
                        for peer in peerList {
                            if let info = infoMap[peer.id.id._internalGetInt64Value()], peer.id.id._internalGetInt64Value() != context.account.peerId.id._internalGetInt64Value() {
                                retList.append(TBVipContactListEntry(tgUser: peer, tgInfo: info))
                            }
                        }
                        subscriber.putNext((retList, mySelf, myNetWorkInfo))
                        subscriber.putCompletion()
                    })
                   
                }else{
                    if let mySelf = mySelf {
                        subscriber.putNext(([TBVipContactListEntry](), mySelf, NetworkInfo()))
                    }
                    subscriber.putCompletion()
                }
                return EmptyDisposable
            }
        })
    }
    
    
    private func creatTransactionListSignal(context: AccountContext) -> Signal<([TBVipTransactionListEntry]), NoError> {
        let signal =  TBTransferAssetInteractor.fetchUserTransferInfo_()
        let retSignal: Signal<[TBVipTransactionListEntry], NoError> = signal |> mapToSignal({ listEntry in
            return Signal { subscriber in
                if let listEntry = listEntry, !listEntry.data.isEmpty {
                    var tgUserIdSet = Set<Int64>()
                    for entry in listEntry.data {
                        tgUserIdSet = tgUserIdSet.union(entry.int64tgUserIdSet())
                    }
                    if !tgUserIdSet.isEmpty {
                        let _ = TBTransferAssetInteractor.fetchNetworkInfoMap(by: tgUserIdSet.sorted().compactMap({String($0)})).start(
                            next: { infoMap in
                                var ret  = [TBVipTransactionListEntry]()
                                for listItem in listEntry.data {
                                    ret.append(
                                        TBVipTransactionListEntry(transactionItem: listItem, paymentUserInfo: infoMap[listItem.paymentInt64TgUserId() ?? 0], receiptUserInfo: infoMap[listItem.relativeInt64TgUserId() ?? 0]))
                                }
                                subscriber.putNext(ret)
                                subscriber.putCompletion()
                            }, error: { _ in
                                subscriber.putNext([TBVipTransactionListEntry]())
                                subscriber.putCompletion()
                            })
                    }else{
                        subscriber.putNext([TBVipTransactionListEntry]())
                        subscriber.putCompletion()
                    }
                    
                }
                subscriber.putNext([TBVipTransactionListEntry]())
                subscriber.putCompletion()
                return EmptyDisposable
            }
        })
        return retSignal
    }
    
    @objc func safeDelayReloadData() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2, execute: { [weak self] in
            self?.reloadData()
        })
    }
    
    func reloadData() {
        
        
        
        self.userTransferDisposable = TBTransferAssetInteractor.fetchUserTransferInfo().start(next: { [weak self] listEntry in
            if let strongSelf = self {
                strongSelf.updateState {$0.refreshTransactions(listEntry.data)}
            }
        })
        
        let _  = self.creatContatsListSignal(context: self.context).start(next: {[weak self] view in
            let (contactList, mySelf, myNetWorkInfo) = view
            self?.updateState{ current in
                return current.refreshContactList(contactList, mySelf, myNetWorkInfo)
            }
        })

    }
    
    private func reloadView(state: State) {
        
        let old = self.dataMap
        self.dataMap = TBTransferToItImplController.creatDataMap(state: state)
        if let cell = self.fromToCell, cell.textFieldIsFirstResponder() && self.dataMap.isEqualToOther(other: old) {
            
            self.collectionView.performBatchUpdates(nil)
        }else{
            self.collectionView.reloadData()
        }
        self.bottomView.isUserInteractionEnabled = state.transferValidRet() == nil ? false : true
        self.bottomView.alpha = self.bottomView.isUserInteractionEnabled ? 1 : 0.5
    }
    
    deinit {
        self.presentationDataDisposable?.dispose()
        self.stateDisposable?.dispose()
        self.userTransferDisposable?.dispose()
        NotificationCenter.default.removeObserver(self)
    }

}


extension TBTransferToItImplController {
    private static func creatDataMap(state: State) -> DataMap {
        var ret = DataMap()
        
        var accountSectionList = [Item]()
        var transationSectionList = [Item]()
        var contactsSectionList = [Item]()
        var promoteSectionList = [Item]()
        
        accountSectionList.append(.header(.account, TBLanguage.sharedInstance.localizable(TBLankey.transfer_activity_sended), UIColor(rgb: 0x828283)))
        
        let hiddenTips: Bool
        
        if state.inputAddress.isEmpty {
            hiddenTips = true
        }else{
            if state.inputAddress.hasPrefix("0x") {
                hiddenTips = true
            }else {
                hiddenTips = false
            }
        }
        accountSectionList.append(
            .fromAndTo(
                wallet: state.wallet,
                mySelf: state.mySelf,
                selectContact: state.selectContact,
                selectTransaction: state.selectTranSactionEntry,
                inputText: state.inputAddress,
                hiddenTips: hiddenTips
            )
        )
        
        if state.transactions.isEmpty {
            transationSectionList.append(.header(.recentTransaction, TBLanguage.sharedInstance.localizable(TBLankey.transfer_activity_recenttransactions), UIColor(rgb: 0xABABAF)))
            transationSectionList.append(.transactionPlaceHolder)
        }else{
            transationSectionList.append(.header(.recentTransaction, TBLanguage.sharedInstance.localizable(TBLankey.transfer_activity_recenttransactions), UIColor(rgb: 0x414147)))
            for item in state.transactions {
                transationSectionList.append(.transaction(item))
            }
            transationSectionList.append(.seperatorLine)
        }
        
        
        if state.contanctList.isEmpty {
            contactsSectionList.append(.header(.contacts, TBLanguage.sharedInstance.localizable(TBLankey.transfer_activity_myfriend), UIColor(rgb:0xABABAF)))
            contactsSectionList.append(.contactPlaceHodler)
            promoteSectionList.append(.promote(TBLanguage.sharedInstance.localizable(TBLankey.transfer_activity_nobind_friend), TBLanguage.sharedInstance.localizable(TBLankey.transfer_activity_tips)))
        }else{
            
            contactsSectionList.append(.header(.contacts, TBLanguage.sharedInstance.localizable(TBLankey.transfer_activity_myfriend), UIColor(rgb: 0x414147)))
            for contanct in state.contanctList {
                contactsSectionList.append(.contact(contanct))
            }
        }

        ret[.account] = accountSectionList
        ret[.recentTransaction] = transationSectionList
        ret[.contacts] = contactsSectionList
        ret[.promote] = promoteSectionList
        ret = ret.compactMapValues{$0.isEmpty ? nil : $0}
        return ret
    }
}


extension TBTransferToItImplController: UICollectionViewDataSource {
    
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
            case .header(_, let title, let textColor):
                if let cell = cell as? TBTransferToItHeaderCell {
                    cell.reloadCell(title: title, textColor: textColor)
                }
            case .fromAndTo:
                if let cell = cell as? TBTransferToItFromToCell {
                    self.fromToCell = cell
                    self.reloadFromToCell(cell: cell, item: item)
                }
            case .transaction(let item):
                if let cell = cell as? TBTransferToItRencentTransactionCell {
                    cell.reloadCell(item: item, context: context)
                }
            case .transactionPlaceHolder,.contactPlaceHodler:
                break
            case .seperatorLine:
                break
            case .contact(let entry):
                if let cell = cell as? TBTransferToItContactCell {
                    cell.reloadCell(context:self.context , entry: entry)
                }
            case .promote(let title, let des):
                if let cell = cell as? TBTransferToItBottomPromoteCell {
                    cell.reloadCell(title: title, des: des)
                }
            }
            return cell
        }else{
            return collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(UICollectionViewCell.self), for: indexPath)
        }
    }
    
    private func toQrcode() {
        let context = self.context
        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        DeviceAccess.authorizeAccess(to: .camera(.qrCode), presentationData: presentationData, present: { c, a in
            c.presentationArguments = a
            context.sharedContext.mainWindow?.present(c, on: .root)
        }, openSettings: {
            context.sharedContext.applicationBindings.openSettings()
        }, { [weak self] granted in
            guard let strongSelf = self else {
                return
            }
            guard granted else {
                return
            }
            let activeSessionsContext = context.engine.privacy.activeSessions()
            let controller = TBQrCodeScanScreen(context: context, subject: .wallet, callBack: {[weak self] address in
                if let ret = address.tb_regularExpression(regularExpress: "0x[0-9a-fA-F]+").first {
                    self?.updateState { current in
                        return current.refreshInputText(ret)
                    }
                }
            })
            controller.showMyCode = { [weak self, weak controller] in
                if let strongSelf = self {
                    let _ = (strongSelf.context.account.postbox.loadedPeerWithId(strongSelf.context.account.peerId)
                             |> deliverOnMainQueue).start(next: { [weak self, weak controller] peer in
                        if let strongSelf = self, let controller = controller {
                            controller.present(strongSelf.context.sharedContext.makeChatQrCodeScreen(context: strongSelf.context, peer: peer, threadId: nil), in: .window(.root))
                        }
                    })
                }
            }
            strongSelf._parentViewController().present(controller, in: .window(.root))
        })
    }
    
    private func reloadFromToCell(cell: TBTransferToItFromToCell, item: Item) {
        switch item {
        case .fromAndTo(wallet: let wallet,
                        mySelf: let mySelf,
                        selectContact: let selectContact,
                        selectTransaction:let selectTransaction,
                        inputText: let inputText,
                        hiddenTips: let hiddenTips):
            cell.reloadCell(
                context: self.context,
                wallet: wallet,
                mySelf: mySelf,
                selectContact: selectContact,
                selectTransaction: selectTransaction,
                inputText: inputText,
                hiddenTips: hiddenTips,
                textUpdate: {[weak self] text in
                    self?.updateState{ current in
                        return current.refreshInputText(text)
                    }
                },
                qrButtonTap: { [weak self] in
                    self?.toQrcode()
                }
            )
        default:
            break
        }
    }
}




extension TBTransferToItImplController {
    
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


extension TBTransferToItImplController: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if let item = self.safeItem(at: indexPath) {
            switch item {
            case .contact(let entry):
                self.view.endEditing(true)
                self.updateState{ current in
                    return current.refreshSelectContact(entry)
                }
            case .transaction(let item):
                self.view.endEditing(true)
                if let cell = collectionView.cellForItem(at: indexPath) as? TBTransferToItRencentTransactionCell,  !item.relativeWalletAddress().isEmpty {
                    self.updateState{ current in
                        return current.refreshSelectTransaction(TBVipSelectTransactionEntry(tgUser: cell.releativeTgUser, transactionItem: item))
                        
                    }
                }
            default:
                self.view.endEditing(true)
            }
        }
    }
}


extension TBTransferToItImplController : UICollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if let item = self.safeItem(at: indexPath) {
            if let cell = self.fromToCell {
                self.reloadFromToCell(cell: cell, item: item)
            }
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









