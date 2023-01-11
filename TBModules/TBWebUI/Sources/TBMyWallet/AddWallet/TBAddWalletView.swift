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
    case list
    static func == (lhs: Section, rhs: Section) -> Bool {
        if lhs.sectionId() == rhs.sectionId() {
            return true
        }else{
            return false
        }
    }
    
    func sectionId() -> Int64 {
        switch self {
        case .list:
            return 1
        }
    }

    func sectionInset() -> UIEdgeInsets {
        return UIEdgeInsets(top: 20, left: 24, bottom: 0, right: 24)
    }
    
    func minimumLineSpacing() -> CGFloat {
       return 18
    }
    
    func minimumInteritemSpacing() -> CGFloat {
       return 18
    }
}


private enum Item {
    case creatWallet(String, String)
    case importWallet(String, String)
    case connectWallet(TBWalletConnect?, String, String, UIImage?)
    case focusWallet(String, String)
    func cellClass() -> AnyClass {
        switch self {
        case .connectWallet:
            return TBAddConnectWalletItemCell.self
        default:
            return TBAddWalletItemCell.self
        }
        
    }
    
    func section() -> Section {
        return .list
    }
    
    func size(viewSize:CGSize = UIScreen.main.bounds.size) -> CGSize {
        let itemWidth = viewSize.width - self.section().sectionInset().left - self.section().sectionInset().right
        return CGSize(width: itemWidth, height: 56)
    }
    
}


extension State {
    
    static func == (lhs: State, rhs: State) -> Bool {
        if lhs.currentConnectWallet != rhs.currentConnectWallet {
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
    var currentConnectWallet: TBWalletConnect?
}

private class TopView: UIView {
    
    enum ActionType {
        case back
        case close
    }
    
    private let leftBtn: UIButton
    private let rightBtn: UIButton
    private let titleLabel: UILabel
    var action:((ActionType)->Void)?
    
    override init(frame: CGRect) {
        
        self.leftBtn = UIButton(type: .custom)
        self.leftBtn.setImage(UIImage(bundleImageName: "TBMyWallet/icon_back_dialog"), for: .normal)
        
        self.titleLabel = UILabel()
        self.titleLabel.textColor = UIColor(rgb: 0x000000)
        self.titleLabel.font = .systemFont(ofSize: 13, weight: .medium)
        self.titleLabel.text = ""
        
        self.rightBtn = UIButton(type: .custom)
        self.rightBtn.setImage(UIImage(bundleImageName: "TBMyWallet/icon_close_tg_rpofile_bg"), for: .normal)
       
        
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
        self.action?(.back)
    }
    
    @objc private func rightBtnAction() {
        self.action?(.close)
    }
    
}


class TBAddWalletView: UIView {
    
    enum ActionType {
        case creatWallet
        case importWallet
        case connectWallet(TBWalletConnect?)
        case focusWallet
        case close
        case back
        case cancel
    }
    
    let context: AccountContext
    var action:((ActionType)->Void)?
    private let statePromise: ValuePromise<State>
    private let stateValue: Atomic<State>
    private let updateState: ((State) -> State) -> Void
    private var stateDisposable: Disposable?
    private var walletGroupDisposale: Disposable?
    
    private let topView: TopView
    private let cancelBtn: UIButton
    private let importDesLabel: UILabel
    
    private var dataMap = DataMap()
    
    private let collectionView: UICollectionView
    
    init(context:AccountContext, params:TBAddWalletController.Params) {
        self.context = context
        let initialState = State(currentConnectWallet: nil)
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
        self.collectionView.register(TBAddWalletItemCell.self, forCellWithReuseIdentifier: NSStringFromClass(TBAddWalletItemCell.self))
        self.collectionView.register(TBAddConnectWalletItemCell.self, forCellWithReuseIdentifier: NSStringFromClass(TBAddConnectWalletItemCell.self))
        self.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: NSStringFromClass(UICollectionViewCell.self))
        self.collectionView.frame = CGRect(origin: .zero, size: CGSize(width: 1, height: 1))
        
        self.cancelBtn = UIButton(type: .custom)
        self.cancelBtn.setTitle("", for: .normal)
        self.cancelBtn.setTitleColor(UIColor(rgb: 0x868686), for: .normal)
        self.cancelBtn.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        self.cancelBtn.backgroundColor = UIColor(rgb: 0xF7F8F9)
        self.cancelBtn.clipsToBounds = true
        self.cancelBtn.layer.cornerRadius = 47 / 2.0
        
        self.importDesLabel = UILabel()
        self.importDesLabel.textColor = UIColor(rgb: 0x929292)
        self.importDesLabel.font = .systemFont(ofSize: 13, weight: .medium)
        self.importDesLabel.numberOfLines = 0
        self.importDesLabel.text = ""
        self.importDesLabel.isHidden = true

        super.init(frame: .zero)
        
        self.topView.action = {[weak self] type in
            switch type {
            case .close:
                self?.action?(.close)
            case .back:
                self?.action?(.back)
            }
        }
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        
        self.cancelBtn.addTarget(self, action: #selector(self.cancelBtnAction), for: .touchUpInside)
        
        self.backgroundColor = .clear
        
        self.addSubview(self.topView)
        self.addSubview(self.collectionView)
        self.addSubview(self.cancelBtn)
        self.addSubview(self.importDesLabel)
        
        self.topView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.leading.equalToSuperview()
            make.height.equalTo(48)
        }
        
        self.cancelBtn.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.leading.equalTo(30)
            make.height.equalTo(47)
            make.bottom.equalTo(self.safeAreaLayoutGuide).offset(-60)
        }
        
        self.collectionView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(self.topView.snp.bottom).offset(0)
            make.leading.equalToSuperview()
            make.bottom.equalTo(self.cancelBtn.snp.top)
        }
        
        self.importDesLabel.snp.makeConstraints { make in
            make.top.equalTo(self.cancelBtn.snp.bottom).offset(10)
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualTo(self.cancelBtn)
        }
        
    
        self.walletGroupDisposale = TBWalletConnectManager.shared.availabelConnectionsSignal.start(next: { [weak self] connections in
            self?.updateState { current in
                var current = current
                current.currentConnectWallet = connections.first
                return current
            }
        })
        
        self.stateDisposable = (self.statePromise.get() |> deliverOnMainQueue).start(next: {
            [weak self] state in
            self?.reloadList(state: state)
        })
        
        
    }
    
    @objc private func cancelBtnAction() {
        self.action?(.cancel)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    private func reloadList(state:State) {
        self.dataMap = TBAddWalletView.creatDataMap(state: state)
        self.collectionView.reloadData()
    }
   
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.stateDisposable?.dispose()
        self.walletGroupDisposale?.dispose()
    }
}


extension TBAddWalletView {
    private static func creatDataMap(state: State) -> DataMap {
        var ret = DataMap()
        
        var list = [Item]()
        
        list.append(.creatWallet("", ""))
        list.append(.importWallet("", ""))
        list.append(.connectWallet(state.currentConnectWallet, "", "", UIImage(bundleImageName: "TBWallet/MetaMask")))
        list.append(.focusWallet("", ""))
        ret[.list] = list
        ret = ret.compactMapValues{$0.isEmpty ? nil : $0}
        return ret
    }
}


extension TBAddWalletView: UICollectionViewDataSource {
    
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
            case .creatWallet(let title, let subtitle),
                    .importWallet(let title, let subtitle),
                    .focusWallet(let title, let subtitle):
                if let cell = cell as? TBAddWalletItemCell {
                    cell.reloadCell(title: title, des: subtitle)
                }
            case let .connectWallet(c, title, subTitle, image):
                if let cell = cell as? TBAddConnectWalletItemCell {
                    cell.reloadCell(title: title, des: subTitle, image: image, wallet: c)
                }
            
            }
            return cell
        }else{
            return collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(UICollectionViewCell.self), for: indexPath)
        }
    }
    
    
}


extension TBAddWalletView {
    
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


extension TBAddWalletView: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let item = self.safeItem(at: indexPath) {
            switch item {
            case .creatWallet(_, _):
                self.action?(.creatWallet)
            case .importWallet(_, _):
                self.action?(.importWallet)
            case .connectWallet(let tBWalletConnect, _, _, _):
                self.action?(.connectWallet(tBWalletConnect))
            case .focusWallet(_, _):
                self.action?(.focusWallet)
            }
        }
    }
}


extension TBAddWalletView : UICollectionViewDelegateFlowLayout {
    
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

