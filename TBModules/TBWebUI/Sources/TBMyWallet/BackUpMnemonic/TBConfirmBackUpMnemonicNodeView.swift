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
import TBDisplay
import SwiftEntryKit


private enum Section: Equatable {
    case wordList
    static func == (lhs: Section, rhs: Section) -> Bool {
        if lhs.sectionId() == rhs.sectionId() {
            return true
        }else{
            return false
        }
    }
    
    func sectionId() -> Int64 {
        switch self {
        case .wordList:
            return 1
        }
    }
    
    func sectionInset() -> UIEdgeInsets {
        switch self {
        case .wordList:
            return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
    }
    
    func minimumLineSpacing() -> CGFloat {
        switch self {
        case .wordList:
            return 0
        }
    }
    
    func minimumInteritemSpacing() -> CGFloat {
        switch self {
        case .wordList:
            return 0
        }
    }
}


private enum Item {
    case word(TBMnemonicWordCell.Item)
    func cellClass() -> AnyClass {
        switch self {
        case .word:
            return TBMnemonicWordCell.self
        }
    }
    
    func section() -> Section {
        switch self {
        case .word:
            return .wordList
        }
    }
    
    func size(viewSize:CGSize = UIScreen.main.bounds.size) -> CGSize {
        let itemWidth = (viewSize.width - self.section().sectionInset().left - self.section().sectionInset().right) / 3.0
        var floatValue =  Float(itemWidth)
        floatValue  = floorf(floatValue)
        switch self {
        case .word:
            return CGSize(width: CGFloat(floatValue), height: 68)
        }
    }
    
}


private typealias DataMap = [Section : [Item]]


extension DataMap {
    fileprivate func validSortKeys() -> [Section] {
        let map = self.compactMapValues { $0.isEmpty ? nil : $0}
        return map.keys.sorted{$0.sectionId() < $1.sectionId()}
    }
}



private struct State:Equatable {
    var mnemonic: String
    var wallet: TBMyWalletModel
    
    static func == (lhs: State, rhs: State) -> Bool {
        if lhs.mnemonic != rhs.mnemonic {
            return false
        }
        if lhs.wallet != rhs.wallet {
            return false
        }
        return true
    }
}

public class TBConfirmBackUpMnemonicNodeView: UIView {
    
    enum OutActionType {
        case back
        case hasConfirm
    }
    
    let context: AccountContext
    let params: TBConfirmBackUpMnemonicController.Params
    weak var controller: TBConfirmBackUpMnemonicController?
    var outAction:((OutActionType)->Void)?
    
    private let statePromise: ValuePromise<State>
    private let stateValue: Atomic<State>
    private let updateState: ((State) -> State) -> Void
    private var stateDisposable: Disposable?
    
    private let scrollView: UIScrollView
    private let contentView: UIView
    
    private let backButton: UIButton
    private let confirmBtn: UIButton
    
    private let titleLabel: UILabel
    private let subTitleLabel: UILabel
    private let collectionView: UICollectionView
    private var dataMap = DataMap()
    private let desLabel: UILabel
    
    init(context:AccountContext, controller:TBConfirmBackUpMnemonicController,  params: TBConfirmBackUpMnemonicController.Params) {
        self.context = context
        self.params = params
        self.controller = controller
        let initialState = State(
            mnemonic: params.mnemonic,
            wallet: params.wallet
            )
        let statePromise = ValuePromise(initialState, ignoreRepeated: true)
        let stateValue = Atomic(value: initialState)
        let updateState: ((State) -> State) -> Void = { f in
            statePromise.set(stateValue.modify { f($0) })
        }
        self.statePromise = statePromise
        self.stateValue = stateValue
        self.updateState = updateState
        
        self.scrollView = UIScrollView()
        self.scrollView.alwaysBounceVertical = true
        self.contentView = UIView()
        
        self.backButton = UIButton(type: .system)
        self.backButton.setImage(UIImage(bundleImageName: "TBMyWallet/ic_back")?.withRenderingMode(.alwaysOriginal), for: .normal)
        self.backButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)

        self.confirmBtn = UIButton(type: .custom)
        self.confirmBtn.setTitle("", for: .normal)
        self.confirmBtn.backgroundColor = UIColor(rgb: 0x3954D5)
        self.confirmBtn.setTitleColor(.white, for: .normal)
        self.confirmBtn.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        self.confirmBtn.clipsToBounds = true
        self.confirmBtn.layer.cornerRadius = 24
        
        self.titleLabel = UILabel()
        self.titleLabel.textColor = UIColor(rgb: 0x000000)
        self.titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        self.titleLabel.numberOfLines = 0
        self.titleLabel.text = ""
        
        self.subTitleLabel = UILabel()
        self.subTitleLabel.textColor = UIColor(rgb: 0x000000, alpha: 0.6)
        self.subTitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        self.subTitleLabel.numberOfLines = 0
        self.subTitleLabel.text = ""
        
        let layout = UICollectionViewFlowLayout()
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        self.collectionView.backgroundColor = .white
        self.collectionView.register(TBMnemonicWordCell.self, forCellWithReuseIdentifier: NSStringFromClass(TBMnemonicWordCell.self))
        self.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: NSStringFromClass(UICollectionViewCell.self))
        self.collectionView.frame = CGRect(origin: .zero, size: CGSize(width: 1, height: 1))
        self.collectionView.isScrollEnabled = false
        self.collectionView.layer.cornerRadius = 8
        self.collectionView.layer.borderColor = UIColor(rgb: 0xDCDCDC).cgColor
        self.collectionView.layer.borderWidth = 1
        self.collectionView.clipsToBounds = true
        self.collectionView.isUserInteractionEnabled = false
        
        self.desLabel = UILabel()
        self.desLabel.textColor = UIColor(rgb: 0x000000, alpha: 0.6)
        self.desLabel.font = .systemFont(ofSize: 14, weight: .regular)
        self.desLabel.numberOfLines = 0
        self.desLabel.text = "  \n "
        
        super.init(frame: .zero)
        self.backgroundColor = .white
        self.addSubview(self.scrollView)
        self.addSubview(self.backButton)
        self.addSubview(self.confirmBtn)
        
        self.scrollView.addSubview(self.contentView)
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.subTitleLabel)
        self.contentView.addSubview(self.collectionView)
        self.contentView.addSubview(self.desLabel)
        
        self.confirmBtn.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.leading.equalTo(20)
            make.height.equalTo(48)
            make.bottom.equalTo(-24)
        }
        self.scrollView.snp.makeConstraints { make in
            make.top.equalTo(0)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(self.confirmBtn.snp.top).offset(-8)
        }
        self.contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(self)
        }
        self.backButton.snp.makeConstraints { make in
            make.leading.equalTo(0)
            make.top.equalTo(28)
            make.width.height.equalTo(24 + 12 * 2)
        }
        self.titleLabel.snp.makeConstraints { make in
            make.top.equalTo(80)
            make.leading.equalTo(20)
            make.trailing.lessThanOrEqualTo(-20)
        }
        self.subTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(self.titleLabel.snp.bottom).offset(6)
            make.leading.equalTo(20)
            make.trailing.lessThanOrEqualTo(-20)
        }
        self.collectionView.snp.makeConstraints { make in
            make.top.equalTo(self.subTitleLabel.snp.bottom).offset(24)
            make.centerX.equalToSuperview()
            make.leading.equalTo(20)
            make.height.equalTo(20*4)
        }
        self.desLabel.snp.makeConstraints { make in
            make.top.equalTo(self.collectionView.snp.bottom).offset(23)
            make.leading.equalTo(20)
            make.trailing.lessThanOrEqualTo(-20)
            make.bottom.equalToSuperview()
        }
        
        self.scrollView.delegate = self
        self.confirmBtn.addTarget(self, action: #selector(self.confirmAction), for: .touchUpInside)
        self.backButton.addTarget(self, action: #selector(self.backAction), for: .touchUpInside)
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        
        self.stateDisposable = (self.statePromise.get() |> deliverOnMainQueue).start(next: {
             [weak self] state in
            self?.reloadWithState(state)
        })
    }
    
    private func reloadWithState(_ state: State) {
        self.dataMap = TBConfirmBackUpMnemonicNodeView.creatDataMap(state: state)
        self.collectionView.reloadData()
        let lineCount = self.dataMap[.wordList]?.split(3).count ?? 0
        let height:CGFloat = CGFloat(lineCount * 68)
        if height != self.collectionView.frame.height {
            self.collectionView.snp.updateConstraints { make in
                make.height.equalTo(height)
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        if let navigationLayout = self.controller?.navigationLayout(layout: layout) {
            let navigationHeight = navigationLayout.navigationFrame.maxY
            self.scrollView.snp.updateConstraints { make in
                make.top.equalTo(navigationHeight)
            }
        }
    }
    
    @objc private func confirmAction() {
        self.outAction?(.hasConfirm)
    }
    
    @objc private func backAction() {
        self.outAction?(.back)
    }
    
    deinit {
        self.stateDisposable?.dispose()
    }
    
}


extension TBConfirmBackUpMnemonicNodeView {
    private static func creatDataMap(state: State) -> DataMap {
        var ret = DataMap()
        var list = [Item]()
        for (idx, value) in state.mnemonic.components(separatedBy: " ").enumerated() {
            list.append(.word(.init(index: idx + 1, name: value)))
        }
        ret[.wordList] = list
        ret = ret.compactMapValues{$0.isEmpty ? nil : $0}
        return ret
    }
}

extension TBConfirmBackUpMnemonicNodeView: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
    }
}


extension TBConfirmBackUpMnemonicNodeView: UICollectionViewDataSource {
    
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
            case let .word(item):
                if let cell = cell as? TBMnemonicWordCell {
                    cell.reloadCell(item: item)
                }
            }
            return cell
        }else{
            return collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(UICollectionViewCell.self), for: indexPath)
        }
    }
    
}


extension TBConfirmBackUpMnemonicNodeView {
    
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


extension TBConfirmBackUpMnemonicNodeView: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    }
}


extension TBConfirmBackUpMnemonicNodeView : UICollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if let item = self.safeItem(at: indexPath) {
            return item.size(viewSize: self.collectionView.frame.size)
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
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return .zero
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return .zero
    }
    
}

extension Array {
    func split(_ segment: Int) -> [[Element]] {
        if segment <= 0 {
            return [self]
        }
        var resultArray: [[Element]] = []
        var beginIndex = 0
        var endIndex = segment
        var count = self.count
        while count >= segment {
            resultArray.append(Array(self[beginIndex ..< endIndex]))
            beginIndex += segment
            endIndex += segment
            count -= segment
        }
        if count < segment {
            resultArray.append(Array(self[beginIndex ..< self.count]))
        }
        return resultArray.compactMap{$0.isEmpty ? nil : $0}
    }
}


