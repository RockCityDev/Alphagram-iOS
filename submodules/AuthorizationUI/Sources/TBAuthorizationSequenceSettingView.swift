






import UIKit
import SnapKit
import SwiftUI
import TBTrack
import TBLanguage
import TBStorage

 struct TBAuthorizationSequenceSettingData {
    let title : String
    let subTitle : String
}

enum TBAuthorizationSequenceSetting: Int{
    case phone = 1
    case mode
}

class TBAuthorizationSequenceSettingItem: TBCollectionItem {
    var isSelect = false
    var data : TBAuthorizationSequenceSettingData
    var tapSwitch:(()->Void)?
    
    init(data: TBAuthorizationSequenceSettingData) {
        self.data = data
        super.init()
    }
}

private final class SettingCell : UICollectionViewCell, TBCell {
    private let titleLabel: UILabel
    private let subtitleLabel: UILabel
    private let switchBtn: UISwitch
    var cellItem: TBAuthorizationSequenceSettingItem?
    
    override init(frame: CGRect) {
        
        self.titleLabel = UILabel()
        self.titleLabel.numberOfLines = 1
        self.titleLabel.font = UIFont.systemFont(ofSize: 15)
        self.titleLabel.textColor = UIColor(rgb: 0x000000)
        
        self.subtitleLabel = UILabel()
        self.subtitleLabel.numberOfLines = 1
        self.subtitleLabel.font = UIFont.systemFont(ofSize: 13)
        self.subtitleLabel.textColor = UIColor(rgb: 0x656565)
        
        self.switchBtn = UISwitch()
        
        
        self.switchBtn.thumbTintColor = UIColor.white
        
        self.switchBtn.tintColor = UIColor(rgb: 0xB4B5B9)
        
        self.switchBtn.onTintColor = UIColor(rgb:0x03BDFF)
        self.switchBtn.setContentHuggingPriority(.required, for: .horizontal)
        self.switchBtn.setContentCompressionResistancePriority(.required, for: .horizontal)
        

        self.switchBtn.isUserInteractionEnabled = false
        
        super.init(frame: frame)
        
        self.contentView.backgroundColor = UIColor.white
        self.contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tapCellAction)))
        
        
        self.switchBtn.addTarget(self, action: #selector(self.switchValueChangeAction), for: .valueChanged)
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.subtitleLabel)
        self.contentView.addSubview(self.switchBtn)
        
        self.titleLabel.snp.makeConstraints { make in
            make.bottom.equalTo(self.contentView.snp.centerY).offset(-1)
            make.leading.equalTo(37)
            make.trailing.lessThanOrEqualTo(self.switchBtn.snp.leading)
        }
        
        self.subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(self.contentView.snp.centerY).offset(1)
            make.leading.equalTo(self.titleLabel)
            make.trailing.lessThanOrEqualTo(self.switchBtn.snp.leading)
        }
        
        self.switchBtn.snp.makeConstraints { make in
            make.centerY.equalTo(self.contentView.snp.centerY)
            make.trailing.equalTo(-31)
        }
    }
    
    @objc func switchValueChangeAction() {


    }
    
    @objc func tapCellAction() {
        self.switchBtn.setOn(!self.switchBtn.isOn, animated: true)
        self.cellItem?.isSelect = self.switchBtn.isOn
        self.cellItem?.tapSwitch?()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func reloadCell<T>(data: T) {
        guard let item = data as? TBAuthorizationSequenceSettingItem else {
            return
        }
        self.cellItem = item
        
        self.titleLabel.text = item.data.title
        self.subtitleLabel.text = item.data.subTitle
        self.switchBtn.isOn = item.isSelect
    }
}

class TBAuthorizationSequenceSettingView : UIView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    var tapSwitch: ((TBAuthorizationSequenceSettingItem)->Void)?
    
    private let collectionView: UICollectionView
    
    private var dataSourceArr: [TBCollectionSection]
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override init(frame: CGRect) {
        self.collectionView = UICollectionView(frame: frame, collectionViewLayout: UICollectionViewFlowLayout())
        self.dataSourceArr = [TBCollectionSection]()
        super.init(frame: frame)
        self.setupView()
    }
    
    private func setupView() {
        self.configCollection()
        self.batchMakeConstraints()
        self.setupDataSource()
        self.collectionView.reloadData()
    }
    
    private func configCollection() -> Void {
        self.collectionView.backgroundColor = UIColor(rgb: 0xFFFFFF);
        self.addSubview(self.collectionView)
        self.collectionView.isScrollEnabled = false
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        self.collectionView.register(SettingCell.self, forCellWithReuseIdentifier: NSStringFromClass(SettingCell.self))
        self.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: NSStringFromClass(UICollectionViewCell.self))
    }
    
    private func batchMakeConstraints() {
        self.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.leading.trailing.bottom.equalTo(0)
        }
    }
    
    
    
    private func setupDataSource() ->Void {
        
        
        UserDefaults.standard.tb_set(bool: true, for: .dontShowMyPhone)
        UserDefaults.standard.tb_set(bool: true, for: .coinIncognitoMode)
      
        
        let section =  TBCollectionSection()
        
        let phoneItem = TBAuthorizationSequenceSettingItem(data: TBAuthorizationSequenceSettingData(title: TBLanguage.sharedInstance.localizable(TBLankey.login_see_phone_title), subTitle:TBLanguage.sharedInstance.localizable(TBLankey.login_see_phone_desc)))
        phoneItem.itemType = TBAuthorizationSequenceSetting.phone.rawValue
        phoneItem.itemSize = CGSize(width: UIScreen.main.bounds.width, height: 68)
        phoneItem.cellClass = SettingCell.self
        phoneItem.isSelect = UserDefaults.standard.tb_bool(for: .dontShowMyPhone)
        phoneItem.tapSwitch = { [weak self, weak phoneItem] in
            if let strongSelf = self, let strongItem = phoneItem {
                UserDefaults.standard.tb_set(bool: strongItem.isSelect ? true : false, for: .dontShowMyPhone)
                strongSelf.tapSwitch?(strongItem)
            }
        }
        
        let modeItem = TBAuthorizationSequenceSettingItem(data: TBAuthorizationSequenceSettingData(title: TBLanguage.sharedInstance.localizable(TBLankey.stealth_login_title), subTitle: TBLanguage.sharedInstance.localizable(TBLankey.stealth_login_tips)))
        modeItem.itemType = TBAuthorizationSequenceSetting.mode.rawValue
        modeItem.itemSize = CGSize(width: UIScreen.main.bounds.width, height: 68)
        modeItem.cellClass = SettingCell.self
        modeItem.isSelect = UserDefaults.standard.tb_bool(for: .coinIncognitoMode)
        modeItem.tapSwitch = { [weak self, weak modeItem] in
            if let strongSelf = self, let strongItem = modeItem {
                UserDefaults.standard.tb_set(bool: strongItem.isSelect ? true : false, for: .coinIncognitoMode)
                strongSelf.tapSwitch?(strongItem)
                if strongItem.isSelect {
                    TBTrack.track(TBTrackEvent.Logging.no_read_chat_open.rawValue)
                }
            }
        }
        section.items = [phoneItem, modeItem]
        self.dataSourceArr = [section]
    }
    
    
    
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let item = TBCollectionSection.item(self.dataSourceArr, indexPath){
            item.indexPath = indexPath
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(item.cellClass), for: indexPath)
            if let aCell = cell as? TBCell {
                aCell.reloadCell(data: item)
            }
            return cell
        }
        return collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(UICollectionViewCell.self), for: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let section = TBCollectionSection.section(self.dataSourceArr, section){
            return section.items.count
        }
        return 0
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.dataSourceArr.count
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if let item = TBCollectionSection.item(self.dataSourceArr, indexPath){
            return item.itemSize
        }
        return CGSize.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if let section = TBCollectionSection.section(self.dataSourceArr, section){
            return section.insets
        }
        return UIEdgeInsets.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if let section = TBCollectionSection.section(self.dataSourceArr, section){
            return section.minumLineSpace
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        if let section = TBCollectionSection.section(self.dataSourceArr, section){
            return section.minimumInteritemSpace
        }
        return 0
    }
}
