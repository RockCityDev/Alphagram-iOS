import Foundation
import UIKit
import AsyncDisplayKit
import Display
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import AppBundle
import AccountContext
import PresentationDataUtils
import TBWeb3Core
import Web3swift
import Web3swiftCore
import TBWalletCore


private enum Section: Equatable {
    case walletList
    static func == (lhs: Section, rhs: Section) -> Bool {
        if lhs.sectionId() == rhs.sectionId() {
            return true
        }else{
            return false
        }
    }
    
    func sectionId() -> Int64 {
        switch self {
        case .walletList:
            return 1
        }
    }
    
    func sectionInset() -> UIEdgeInsets {
        switch self {
        case .walletList:
            return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
    }
    
    func minimumLineSpacing() -> CGFloat {
        switch self {
        case .walletList:
            return 0
        }
    }
    
    func minimumInteritemSpacing() -> CGFloat {
        switch self {
        case .walletList:
            return 0
        }
    }
}


private enum Item {
    case wallet(TBWallet, Bool)
    func cellClass() -> AnyClass {
        switch self {
        case .wallet:
            return TBMyWalletItemCell.self
        }
    }
    
    func section() -> Section {
        switch self {
        case .wallet:
            return .walletList
        }
    }
    
    func size(viewSize:CGSize = UIScreen.main.bounds.size) -> CGSize {
        let itemWidth = viewSize.width - self.section().sectionInset().left - self.section().sectionInset().right
        switch self {
        case .wallet:
            return CGSize(width: itemWidth, height: 60)
        }
    }
    
}


extension State {
    
    static func == (lhs: State, rhs: State) -> Bool {
        if lhs.currentWallet != rhs.currentWallet {
            return false
        }
        if !lhs.wallets.elementsEqual(rhs.wallets) {
            return false
        }
        return true
    }
}


private typealias DataMap = [Section : [Item]]


extension DataMap {
    fileprivate func validSortKeys() -> [Section] {
        let map = self.compactMapValues { $0.isEmpty ? nil : $0}
        return map.keys.sorted{$0.sectionId() < $1.sectionId()}
    }
}

private struct State: Equatable {
    var wallets: [TBWallet]
    var currentWallet: TBWallet?
    
    
}

private class TopView: UIView {
    
    enum ActionType {
        case list
        case close
    }
    
    private let leftBtn: UIButton
    private let rightBtn: UIButton
    private let titleLabel: UILabel
    var action:((ActionType)->Void)?
    
    override init(frame: CGRect) {
        
        self.leftBtn = UIButton(type: .custom)
        self.leftBtn.setImage(UIImage(bundleImageName: ""), for: .normal)
        
        self.titleLabel = UILabel()
        self.titleLabel.textColor = UIColor(rgb: 0x000000)
        self.titleLabel.font = .systemFont(ofSize: 13, weight: .medium)
        self.titleLabel.text = ""
        
        self.rightBtn = UIButton(type: .custom)
        self.rightBtn.setImage(UIImage(bundleImageName: ""), for: .normal)
       
        
        super.init(frame: frame)
        
        self.backgroundColor = .clear
        
        self.leftBtn.addTarget(self, action: #selector(self.leftBtnAction), for: .touchUpInside)
        self.rightBtn.addTarget(self, action: #selector(self.rightBtnAction), for: .touchUpInside)
        self.addSubview(self.leftBtn)
        self.addSubview(self.titleLabel)
        self.addSubview(self.rightBtn)
        
        self.leftBtn.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(16)
            make.width.height.equalTo(16)
        }
        
        self.titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        self.rightBtn.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-12)
            make.width.height.equalTo(24)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func leftBtnAction() {
        self.action?(.list)
    }
    
    @objc private func rightBtnAction() {
        self.action?(.close)
    }
    
}


class TBMyWalletListView: UIView {
    
    enum ActionType {
        case list
        case close
        case importWallet
        case editName
        case selectWallet(TBWallet)
    }
    
    let context: AccountContext
    var action:((ActionType)->Void)?
    private let statePromise: ValuePromise<State>
    private let stateValue: Atomic<State>
    private let updateState: ((State) -> State) -> Void
    private var stateDisposable: Disposable?
    
    private let topView: TopView
    private let importBtn: UIButton
    private let importDesLabel: UILabel
    
    private var dataMap = DataMap()
    
    private let collectionView: UICollectionView
    
    init(context:AccountContext, params:TBMyWalletListController.Params) {
        self.context = context
        
        let initialState = State(wallets: [TBWallet](), currentWallet: params.initialSelectWallet)
        let statePromise = ValuePromise(initialState, ignoreRepeated: true)
        let stateValue = Atomic(value: initialState)
        let updateState: ((State) -> State) -> Void = { f in
            statePromise.set(stateValue.modify { f($0) })
        }
        self.statePromise = statePromise
        self.stateValue = stateValue
        self.updateState = updateState
        
        self.topView = TopView()
        
        let layout = UICollectionViewFlowLayout()
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        self.collectionView.backgroundColor = .white
        self.collectionView.register(TBMyWalletItemCell.self, forCellWithReuseIdentifier: NSStringFromClass(TBMyWalletItemCell.self))
        self.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: NSStringFromClass(UICollectionViewCell.self))
        self.collectionView.frame = CGRect(origin: .zero, size: CGSize(width: 1, height: 1))
        
        self.importBtn = UIButton(type: .custom)
        self.importBtn.setTitle("", for: .normal)
        self.importBtn.setTitleColor(UIColor(rgb: 0xFFFFFF), for: .normal)
        self.importBtn.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        self.importBtn.backgroundColor = UIColor(rgb: 0x3954D5)
        self.importBtn.clipsToBounds = true
        self.importBtn.layer.cornerRadius = 47 / 2.0
        
        self.importDesLabel = UILabel()
        self.importDesLabel.textColor = UIColor(rgb: 0x929292)
        self.importDesLabel.font = .systemFont(ofSize: 13, weight: .medium)
        self.importDesLabel.numberOfLines = 0
        self.importDesLabel.text = ""

        super.init(frame: .zero)
        
        self.topView.action = {[weak self] type in
            switch type {
            case .close:
                self?.action?(.close)
            case .list:
                self?.action?(.list)
            }
        }
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        
        self.importBtn.addTarget(self, action: #selector(self.importBtnAction), for: .touchUpInside)
        
        self.backgroundColor = .clear
        
        self.addSubview(self.topView)
        self.addSubview(self.collectionView)
        self.addSubview(self.importBtn)
        self.addSubview(self.importDesLabel)
        
        self.topView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.leading.equalToSuperview()
            make.height.equalTo(48)
        }
        
        self.importBtn.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.leading.equalTo(30)
            make.height.equalTo(47)
            make.bottom.equalTo(-70)
        }
        
        self.collectionView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(self.topView.snp.bottom).offset(0)
            make.leading.equalToSuperview()
            make.bottom.equalTo(self.importBtn.snp.top)
        }
        
        self.importDesLabel.snp.makeConstraints { make in
            make.top.equalTo(self.importBtn.snp.bottom).offset(10)
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualTo(self.importBtn)
        }
        
        let walletsSignal:Signal<[TBWallet], NoError> = .single(params.initialWallets) |> then(TBWalletWrapper.getAllWalletsSignal(context: context, password: ""))
        let _ = walletsSignal.start(next: {[weak self] wallets in
            self?.updateState { current in
                var current = current
                current.wallets = wallets
                
                if let cur = current.currentWallet, current.wallets.contains(cur) {
                  
                }else if let initialSelectWallet = params.initialSelectWallet, current.wallets.contains(initialSelectWallet){
                    current.currentWallet = initialSelectWallet
                    
                }else{
                    current.currentWallet = current.wallets.first
                }
                return current
            }
        })
        
        self.stateDisposable = (self.statePromise.get() |> deliverOnMainQueue).start(next: {
            [weak self] state in
            self?.reloadList(state: state)
        })
        
        
    }
    
    @objc private func importBtnAction() {
        self.action?(.importWallet)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    private func reloadList(state:State) {
        self.dataMap = TBMyWalletListView.creatDataMap(state: state)
        self.collectionView.reloadData()
    }
   
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.stateDisposable?.dispose()
    }
}


extension TBMyWalletListView {
    private static func creatDataMap(state: State) -> DataMap {
        var ret = DataMap()
        var walletSectionList = [Item]()
        for wallet in state.wallets {
            walletSectionList.append(.wallet(wallet, wallet == state.currentWallet))
        }
        ret[.walletList] = walletSectionList
        ret = ret.compactMapValues{$0.isEmpty ? nil : $0}
        return ret
    }
}


extension TBMyWalletListView: UICollectionViewDataSource {
    
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
            case let .wallet(wallet, isSelect):
                if let cell = cell as? TBMyWalletItemCell {
                    cell.reloadCell(item: wallet, isSelect: isSelect, context: self.context) {[weak self] in
                        self?.action?(.editName)
                    }
                }
            }
            return cell
        }else{
            return collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(UICollectionViewCell.self), for: indexPath)
        }
    }
    
}


extension TBMyWalletListView {
    
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


extension TBMyWalletListView: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let item = self.safeItem(at: indexPath) {
            switch item {
            case let .wallet(wallet, _):
                self.updateState { current in
                    var current = current
                    current.currentWallet = wallet
                    return current
                }
                self.action?(.selectWallet(wallet))
                break
            }
        }
    }
}


extension TBMyWalletListView : UICollectionViewDelegateFlowLayout {
    
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

