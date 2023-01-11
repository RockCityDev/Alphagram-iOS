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
import TBDisplay
import SDWebImage
import TBLanguage


private enum Section: Equatable {
    case title
    case des
    case price
    case share
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
            return 0
        case .des:
            return 1
        case .price:
            return 2
        case .share:
            return 3
        }
    }
    
    func sectionInset() -> UIEdgeInsets {
        switch self {
        case .title:
            return UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        case .des:
            return UIEdgeInsets(top: 20, left: 20, bottom: 0, right: 20)
        case .price:
            return UIEdgeInsets(top: 20, left: 20, bottom: 0, right: 20)
        case .share:
            return UIEdgeInsets(top: 18, left: 20, bottom: 0, right: 20)
        }
    }
    
    func minimumLineSpacing() -> CGFloat {
        switch self {
        case .title:
            return 0
        case .des:
            return 0
        case .price:
            return 0
        case .share:
            return 0
        }
    }
    
    func minimumInteritemSpacing() -> CGFloat {
        switch self {
        case .title:
            return 0
        case .des:
            return 0
        case .price:
            return 0
        case .share:
            return 0
        }
    }
}


private enum Item {
    case title(TBWeb3GroupInfoEntry)
    case des(TBWeb3GroupInfoEntry)
    case price(TBWeb3GroupInfoEntry, TBWeb3ConfigEntry)
    case share(TBWeb3GroupInfoEntry, TBWeb3ConfigEntry)
    
    func cellClass() -> AnyClass {
        switch self {
        case .title:
            return TBInviteGroupInfoTitleCell.self
        case .des:
            return TBInviteGroupInfoDescCell.self
        case .price:
            return TBInviteGroupInfoConditionCell.self
        case .share:
            return TBInviteGroupInfoInviteCell.self
        }
    }
    
    func section() -> Section {
        switch self {
        case .title:
            return .title
        case .des:
            return .des
        case .price:
            return .price
        case .share:
            return .share
        }
    }
    
    func size(viewSize:CGSize = UIScreen.main.bounds.size) -> CGSize {
        let itemWidth = viewSize.width - self.section().sectionInset().left - self.section().sectionInset().right
        switch self {
        case .title(let groupInfo):
            let titleHeight = groupInfo.title.tb_heightForComment(fontSize: 18, width: itemWidth)
            return CGSize(width: itemWidth, height: titleHeight)
        case .des(let groupInfo):
            let descHeight = groupInfo.description.tb_heightForComment(fontSize: 14, width: itemWidth)
            return CGSize(width: itemWidth, height: descHeight)
        case .price:
            return CGSize(width: itemWidth, height: 60)
        case .share:
          return CGSize(width: itemWidth, height: 50)
        }
    }
    
}


private struct State: Equatable {
    var groupInfo: TBWeb3GroupInfoEntry
    var config: TBWeb3ConfigEntry
    static func == (lhs: State, rhs: State) -> Bool {
        if lhs.groupInfo != rhs.groupInfo {
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
    
    fileprivate func contentSize(width: CGFloat) -> CGSize {
        var height: CGFloat = 0
        for section in self.validSortKeys() {
            height += section.sectionInset().top + section.sectionInset().bottom
            for item in self[section]! {
                height += item.size(viewSize: CGSize(width: width, height: 1)).height
            }
            height += CGFloat((self[section]!.count - 1)) * section.minimumLineSpacing()
        }
        return CGSize(width: width, height: height)
    }
}

class TBInviteLinkListContentView: UIView {
    
    private let groupInfo: TBWeb3GroupInfoEntry
    private let context: AccountContext
    private let navView:UIView
    private let closeButton: UIButton
    private let avatar: UIImageView
    private let leftBtn: TBButtonView
    private let rightBtn: TBButtonView
    
    public let inviteView: TBInviteGroupInfoView
    
    private let collectionView: UICollectionView
    
    var pasteBlock:(()->Void)?
    var shareBlock:(()->Void)?
    var getQrCodeBlock:(()->Void)?
    var cancelBlock:(()->Void)?
    
    private var dataMap = DataMap()
    
    private let statePromise: ValuePromise<State>
    private let stateValue: Atomic<State>
    private let updateState: ((State) -> State) -> Void
    private var stateDisposable: Disposable?
    
    init(context:AccountContext, groupInfo:TBWeb3GroupInfoEntry, configEntry:TBWeb3ConfigEntry) {
        self.context = context
        self.groupInfo = groupInfo
        
        self.navView = UIView()
        self.navView.backgroundColor = UIColor(rgb: 0x4B5BFF)
        
        self.closeButton = UIButton(type: .custom)
        let image = UIImage(named: "Settings/wallet/tb_ic_close_white")
        image?.withTintColor(UIColor.white, renderingMode: .alwaysTemplate)
        self.closeButton.tintColor = .white
        self.closeButton.setImage(image, for: .normal)
        
        self.avatar = UIImageView()
        self.avatar.contentMode = .scaleAspectFill
        self.avatar.layer.cornerRadius = 88 / 2.0
        self.avatar.layer.borderColor = UIColor(rgb: 0xFFFFFF).cgColor
        self.avatar.layer.borderWidth = 4
        self.avatar.clipsToBounds = true
        
        let config = TBBottonViewNormalConfig(gradientColors: [UIColor(rgb: 0x3954D5).cgColor, UIColor(rgb: 0x3954D5).cgColor], borderWidth: 0, borderColor: UIColor.clear.cgColor, borderRadius:23, enbale: true, alpha: 1, iconSize: CGSize(width: 15, height: 15), titleFont: .systemFont(ofSize: 16, weight: .medium), buttonType: .titleRight)
        self.leftBtn = TBButtonView(config: config)
        self.leftBtn.contentView.titleLabel.textColor = UIColor(rgb: 0xFFFFFF)
        self.leftBtn.contentView.titleLabel.text = TBLanguage.sharedInstance.localizable(TBLankey.dialog_copy)
        self.leftBtn.contentView.icon.image = UIImage(bundleImageName: "TBWebPage/ic_tb_copy")
        self.leftBtn.contentView.activityView.isHidden = true
        self.leftBtn.reload(config:config)
        
        self.rightBtn = TBButtonView(config: config)
        self.rightBtn.contentView.titleLabel.textColor = UIColor(rgb: 0xFFFFFF)
        self.rightBtn.contentView.titleLabel.text = TBLanguage.sharedInstance.localizable(TBLankey.ac_download_text_share)
        self.rightBtn.contentView.icon.image = UIImage(bundleImageName: "TBWebPage/ic_tb_share")
        self.rightBtn.contentView.activityView.isHidden = true
        self.rightBtn.reload(config:config)
    
        
        let layout = UICollectionViewFlowLayout()
        self.collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        let initialState = State(
            groupInfo: groupInfo,
            config: configEntry
        )
        let statePromise = ValuePromise(initialState, ignoreRepeated: true)
        let stateValue = Atomic(value: initialState)
        let updateState: ((State) -> State) -> Void = { f in
            statePromise.set(stateValue.modify { f($0) })
        }

        self.statePromise = statePromise
        self.stateValue = stateValue
        self.updateState = updateState
        
        self.inviteView = TBInviteGroupInfoView(groupInfo: groupInfo)
        super.init(frame: .zero)
        
        self.closeButton.addTarget(self, action: #selector(self.cancelAction), for: .touchUpInside)
        self.layer.cornerRadius = 15
        self.clipsToBounds = true
        
        self.collectionView.contentInsetAdjustmentBehavior = .never
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.backgroundColor = .white
        self.collectionView.alwaysBounceVertical = false
        self.collectionView.isScrollEnabled = false
        self.collectionView.register(TBInviteGroupInfoTitleCell.self, forCellWithReuseIdentifier: NSStringFromClass(TBInviteGroupInfoTitleCell.self))
        self.collectionView.register(TBInviteGroupInfoDescCell.self, forCellWithReuseIdentifier: NSStringFromClass(TBInviteGroupInfoDescCell.self))
        self.collectionView.register(TBInviteGroupInfoConditionCell.self, forCellWithReuseIdentifier: NSStringFromClass(TBInviteGroupInfoConditionCell.self))
        self.collectionView.register(TBInviteGroupInfoInviteCell.self, forCellWithReuseIdentifier: NSStringFromClass(TBInviteGroupInfoInviteCell.self))
        self.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: NSStringFromClass(UICollectionViewCell.self))
        
        self.addSubview(self.navView)
        self.addSubview(self.closeButton)
        self.addSubview(self.collectionView)
        self.addSubview(self.avatar)
        self.addSubview(self.leftBtn)
        self.addSubview(self.rightBtn)
        self.addSubview(inviteView)
        
        self.navView.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(self)
            make.height.equalTo(76)
        }
        self.closeButton.snp.makeConstraints { make in
            make.top.equalTo(16)
            make.trailing.equalTo(-16)
            make.width.height.equalTo(32)
        }
        
        self.avatar.snp.makeConstraints { make in
            make.top.equalTo(42)
            make.leading.equalTo(24)
            make.width.height.equalTo(88)
        }
        
        self.leftBtn.snp.makeConstraints { make in
            make.bottom.equalTo(-33)
            make.leading.equalTo(23)
            make.height.equalTo(46)
        }
        
        self.rightBtn.snp.makeConstraints { make in
            make.leading.equalTo(self.leftBtn.snp.trailing).offset(8)
            make.width.height.top.equalTo(self.leftBtn)
            make.trailing.equalTo(-23)
        }
       
        self.collectionView.snp.makeConstraints { make in
            make.top.equalTo(150)
            make.leading.trailing.equalTo(self)
            make.bottom.equalTo(self)
        }
        
        self.inviteView.snp.makeConstraints { make in
            make.center.equalTo(CGPoint(x: -10000, y: -10000))
            
        }
        
        self.leftBtn.tapBlock = {[weak self] in
            self?.pasteBlock?()
        }
        
        self.rightBtn.tapBlock = {[weak self] in
            self?.shareBlock?()
        }
        self.stateDisposable = self.statePromise.get().start(next: { [weak self] state in
            if let strongSelf = self {
                strongSelf.reloadView(state: state)
            }
        })
        
    }
    @objc func cancelAction() {
        self.cancelBlock?()
    }
    
    public class func contentSize(with:CGFloat, groupInfo:TBWeb3GroupInfoEntry, config:TBWeb3ConfigEntry) -> CGSize{
        let state = State(groupInfo: groupInfo, config: config)
        let dataMap = TBInviteLinkListContentView.creatDataMap(state: state)
        let height:CGFloat = 150 + 130 + dataMap.contentSize(width: with).height
        return CGSize(width: with, height: height)
    }
    
    private func reloadView(state: State) {
        self.dataMap = TBInviteLinkListContentView.creatDataMap(state: state)
        self.collectionView.reloadData()
        self.avatar.sd_setImage(with: URL(string: state.groupInfo.avatar), placeholderImage: UIImage(named: "TBWallet/avatar"))
    }

    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}

extension TBInviteLinkListContentView {
    private static func creatDataMap(state: State) -> DataMap {
        var ret = DataMap()
        
        var titleSectionList = [Item]()
        titleSectionList.append(.title(state.groupInfo))
    
        var descSectionList = [Item]()
        if !state.groupInfo.description.isEmpty {
            descSectionList.append(.des(state.groupInfo))
        }
      
        var priceSectionList = [Item]()
        priceSectionList.append(.price(state.groupInfo, state.config))
        
        var inviteSectionList = [Item]()
        inviteSectionList.append(.share(state.groupInfo, state.config))
        
        ret[.title] = titleSectionList
        ret[.des] = descSectionList
        ret[.price] = priceSectionList
        ret[.share] = inviteSectionList
        ret = ret.compactMapValues{$0.isEmpty ? nil : $0}
        return ret
    }
}


extension TBInviteLinkListContentView: UICollectionViewDataSource {
    
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
                if let cell = cell as? TBInviteGroupInfoTitleCell {
                    cell.reloadCell(item: groupInfo)
                }
            case .des(let groupInfo):
                if let cell = cell as? TBInviteGroupInfoDescCell {
                    cell.reloadCell(item: groupInfo)
                }
            case .price(let groupInfo, let config):
                if let cell = cell as? TBInviteGroupInfoConditionCell {
                    cell.reloadCell(item: groupInfo, config: config)
                }
            case .share(let groupInfo, let config):
                if let cell = cell as? TBInviteGroupInfoInviteCell {
                    cell.reloadCell(item: groupInfo, config: config)
                }
            
            }
            return cell
        }else{
            return collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(UICollectionViewCell.self), for: indexPath)
        }
    }
    
}


extension TBInviteLinkListContentView {
    
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


extension TBInviteLinkListContentView: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let item = self.safeItem(at: indexPath) {
            switch item {
            case .title:
                break
            case .des:
                break
            case .price:
                break
            case .share:
                self.getQrCodeBlock?()
                break
            }
        }
    }
}


extension TBInviteLinkListContentView : UICollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if let item = self.safeItem(at: indexPath) {
            return item.size(viewSize: collectionView.bounds.size)
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
