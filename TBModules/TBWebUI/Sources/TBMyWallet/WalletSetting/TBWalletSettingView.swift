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
import ProgressHUD


private enum Section: Equatable {
    case walletOption
    case paySetting
    static func == (lhs: Section, rhs: Section) -> Bool {
        if lhs.sectionId() == rhs.sectionId() {
            return true
        }else{
            return false
        }
    }
    
    func sectionId() -> Int64 {
        switch self {
        case .walletOption:
            return 1
        case .paySetting:
            return 2
        }
    }

    func sectionInset() -> UIEdgeInsets {
        switch self {
        case .walletOption:
            return UIEdgeInsets(top: 0, left: 0, bottom: 12, right: 0)
        case .paySetting:
            return .zero
        }
    }
    
    func minimumLineSpacing() -> CGFloat {
       return 0
    }
    
    func minimumInteritemSpacing() -> CGFloat {
       return 0
    }
    
    func sectionTitle() -> String {
        switch self {
        case .walletOption:
            return ""
        case .paySetting:
            return ""
        }
    }
}


private enum Item {
    case changeWalletName(title: String, des: String)
    case currencyUnit(title: String, unit: String)
    case browsePrivateKey(title: String)
    case browseMnemonic(title: String)
    case biometrics(title: String, enable: Bool)
    case passwordFreePayment(title: String, enable: Bool)
    
    func cellClass() -> AnyClass {
        switch self {
        case .changeWalletName, .currencyUnit:
            return TBWalletSettingTitleDesItemCell.self
        case .browseMnemonic, .browsePrivateKey:
            return TBWalletSettingTitleArrowItemCell.self
        case . biometrics, .passwordFreePayment:
            return TBWalletSettingTitleSwitchItemCell.self
        }
    }
    
    func section() -> Section {
        switch self {
        case .changeWalletName, .currencyUnit, .browseMnemonic, .browsePrivateKey:
            return .walletOption
        case . biometrics, .passwordFreePayment:
            return .paySetting
        }
    }
    
    func size(viewSize:CGSize = UIScreen.main.bounds.size) -> CGSize {
        let itemWidth = viewSize.width - self.section().sectionInset().left - self.section().sectionInset().right
        return CGSize(width: itemWidth, height: 50)
    }
    
}


extension State {
    
    static func == (lhs: State, rhs: State) -> Bool {
        if lhs.wallet != rhs.wallet {
            return false
        }
        if lhs.currencyUnit != rhs.currencyUnit {
            return false
        }
        if lhs.biometricsEnable != rhs.biometricsEnable {
            return false
        }
        if lhs.passwordForFreeEnable != rhs.passwordForFreeEnable {
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
    var wallet: TBWallet
    var currencyUnit: String
    var biometricsEnable: Bool
    var passwordForFreeEnable: Bool
}

class TBWalletSettingView: UIView {
    
    enum ActionType {
        case changeWalletName(TBWallet)
        case exportPrivateKey(TBWallet)
        case exportMnemonic(TBWallet)
        case disconnecWallet(TBWalletConnect)
        case deleteWallet(TBMyWalletModel)
    }
    
    let context: AccountContext
    var action:((ActionType)->Void)?
    private let statePromise: ValuePromise<State>
    private let stateValue: Atomic<State>
    private let updateState: ((State) -> State) -> Void
    private var stateDisposable: Disposable?
    private var changeDisposale: Disposable?
    
    private var dataMap = DataMap()
    
    private let collectionView: UICollectionView
    
    private let bottomButton: UIButton
    
    init(context:AccountContext, params:TBWalletSettingController.Params) {
        self.context = context
        let initialState = State(wallet: params.wallet, currencyUnit: "USD", biometricsEnable: false, passwordForFreeEnable: false)
        let statePromise = ValuePromise(initialState, ignoreRepeated: true)
        let stateValue = Atomic(value: initialState)
        let updateState: ((State) -> State) -> Void = { f in
            statePromise.set(stateValue.modify { f($0) })
        }
        self.statePromise = statePromise
        self.stateValue = stateValue
        self.updateState = updateState
        
        
        let layout = UICollectionViewFlowLayout()
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        self.collectionView.backgroundColor = UIColor(rgb: 0xF0F1F4)
        self.collectionView.register(TBWalletSettingTitleDesItemCell.self, forCellWithReuseIdentifier: NSStringFromClass(TBWalletSettingTitleDesItemCell.self))
        self.collectionView.register(TBWalletSettingTitleArrowItemCell.self, forCellWithReuseIdentifier: NSStringFromClass(TBWalletSettingTitleArrowItemCell.self))
        self.collectionView.register(TBWalletSettingTitleSwitchItemCell.self, forCellWithReuseIdentifier: NSStringFromClass(TBWalletSettingTitleSwitchItemCell.self))
        self.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: NSStringFromClass(UICollectionViewCell.self))
        self.collectionView.register(TBWalletSettingHeaderReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: NSStringFromClass(TBWalletSettingHeaderReusableView.self))
        self.collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: NSStringFromClass(UICollectionReusableView.self))
        self.collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: NSStringFromClass(UICollectionReusableView.self))
        self.collectionView.frame = CGRect(origin: .zero, size: CGSize(width: 1, height: 1))
        
        self.bottomButton = UIButton(type: .custom)
        self.bottomButton.setTitleColor(UIColor(rgb: 0xFF5F5F), for: .normal)
        self.bottomButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        self.bottomButton.backgroundColor = UIColor(rgb: 0xFFFFFF)
        self.bottomButton.clipsToBounds = true
        self.bottomButton.layer.cornerRadius = 47 / 2.0
    
        super.init(frame: .zero)
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        
        self.bottomButton.addTarget(self, action: #selector(self.bottomButtonAction), for: .touchUpInside)
        
        self.addSubview(self.collectionView)
        self.addSubview(self.bottomButton)
        
        self.bottomButton.snp.makeConstraints { make in
            make.bottom.equalTo(-60)
            make.centerX.equalToSuperview()
            make.leading.equalTo(24)
            make.height.equalTo(47)
        }

        self.collectionView.snp.makeConstraints { make in
            make.top.equalTo(self)
            make.leading.trailing.equalTo(0)
            make.bottom.equalTo(self.bottomButton.snp.top).offset(-12)
        }
        
        self.stateDisposable = (self.statePromise.get() |> deliverOnMainQueue).start(next: {
            [weak self] state in
            self?.reloadList(state: state)
        })
        self.changeDisposale = (TBWalletGroupManager.shared.storeEntryDidChangeSignal() |> deliverOnMainQueue).start(next: { [weak self] _ in
            if let state = self?.stateValue.with({$0}) {
                self?.reloadList(state: state)
            }
        })
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    private func reloadList(state:State) {
        self.dataMap = TBWalletSettingView.creatDataMap(state: state)
        self.collectionView.reloadData()
        switch state.wallet {
        case .connect:
            self.bottomButton.setTitle("", for: .normal)
        case .mine:
            self.bottomButton.setTitle(" ", for: .normal)
        }
        
    }
   
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func bottomButtonAction() {
        switch self.stateValue.with({$0}).wallet {
        case .mine(let mine):
            self.action?(.deleteWallet(mine))
        case .connect(let c):
            self.action?(.disconnecWallet(c))
        }
    }
    
    deinit {
        self.stateDisposable?.dispose()
        self.changeDisposale?.dispose()
    }
}


extension TBWalletSettingView {
    private static func creatDataMap(state: State) -> DataMap {
        var ret = DataMap()
        
        switch state.wallet {
        case .mine:
            ret[.walletOption] = [
                .changeWalletName(title:"" , des: state.wallet.walletName()),
                .currencyUnit(title: "", unit: state.currencyUnit),
                .browsePrivateKey(title: ""),
                .browseMnemonic(title: "")
            ]
            ret[.paySetting] = [
                .biometrics(title: "", enable: state.biometricsEnable),
                .passwordFreePayment(title: "", enable: state.passwordForFreeEnable)
            ]
        case .connect:
            ret[.walletOption] = [
                .changeWalletName(title:"" , des: state.wallet.walletName())
            ]
        }
        
       
        ret = ret.compactMapValues{$0.isEmpty ? nil : $0}
        return ret
    }
}


extension TBWalletSettingView: UICollectionViewDataSource {
    
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
            
            case .changeWalletName(title: let title, des: let des):
                if let cell = cell as? TBWalletSettingTitleDesItemCell {
                    cell.reloadCell(title: title, des: des)
                }
            case .currencyUnit(title: let title, unit: let unit):
                if let cell = cell as? TBWalletSettingTitleDesItemCell {
                    cell.reloadCell(title: title, des: unit)
                }
            case .browsePrivateKey(title: let title):
                if let cell = cell as? TBWalletSettingTitleArrowItemCell {
                    cell.reloadCell(title: title)
                }
            case .browseMnemonic(title: let title):
                if let cell = cell as? TBWalletSettingTitleArrowItemCell {
                    cell.reloadCell(title: title)
                }
            case .biometrics(title: let title, enable: let enable):
                if let cell = cell as? TBWalletSettingTitleSwitchItemCell {
                    cell.reloadCell(title: title, isOn: enable)
                }
            case .passwordFreePayment(title: let title, enable: let enable):
                if let cell = cell as? TBWalletSettingTitleSwitchItemCell {
                    cell.reloadCell(title: title, isOn: enable)
                }
            }
            return cell
        }else{
            return collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(UICollectionViewCell.self), for: indexPath)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: NSStringFromClass(TBWalletSettingHeaderReusableView.self), for: indexPath)
            if let header = header as? TBWalletSettingHeaderReusableView, let section = self.safeSectionKey(at: indexPath.section) {
                header.reloadHeader(section.sectionTitle())
            }
            return header
        }else{
            return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: NSStringFromClass(UICollectionReusableView.self), for: indexPath)
        }
    }
    
    
}


extension TBWalletSettingView {
    
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


extension TBWalletSettingView: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let item = self.safeItem(at: indexPath) {
            let state = self.stateValue.with{$0}
            switch item {
            case .changeWalletName:
                self.action?(.changeWalletName(state.wallet))
            case .currencyUnit:
                break
            case .browsePrivateKey:
                self.action?(.exportPrivateKey(state.wallet))
            case .browseMnemonic:
                self.action?(.exportMnemonic(state.wallet))
            case .biometrics:
                ProgressHUD.showError("")
            case .passwordFreePayment:
                ProgressHUD.showError("")
            }
        }
    }
}


extension TBWalletSettingView : UICollectionViewDelegateFlowLayout {
    
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
        return CGSize(width: collectionView.frame.width, height: 46)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return .zero
    }
    
}

