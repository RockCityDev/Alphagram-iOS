






import UIKit
import SnapKit
import SwiftUI
import TBTrack
import TBLanguage

struct TBAuthorizationSequenceLanguageData {
    let lanKey : String
    let lanCode : String
}

enum TBAuthorizationSequenceLanguage: Int{
    case language = 1
}

class TBAuthorizationSequenceLanguageItem: TBCollectionItem {
    var isSelect = false
    var data : TBAuthorizationSequenceLanguageData
    var tap: (()->Void)?
    init(data: TBAuthorizationSequenceLanguageData) {
        self.data = data
        super.init()
    }
}

private final class LanguageCell : UICollectionViewCell, TBCell {
    private let titleLabel: UILabel
    private let checkMark: UIImageView
    private let lineView: UIView
    var cellItem: TBAuthorizationSequenceLanguageItem?
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override init(frame: CGRect) {
        
        self.titleLabel = UILabel()
        self.titleLabel.numberOfLines = 1
        self.titleLabel.font = UIFont.systemFont(ofSize: 15)
        self.titleLabel.textColor = UIColor(rgb: 0x000000)
        
        self.checkMark = UIImageView(image: UIImage(bundleImageName: "Login/check_mark"))
        self.checkMark.isHidden = true
        
        self.lineView = UIView()
        self.lineView.backgroundColor = UIColor(rgb:0xB4B5B9)
        
        super.init(frame: frame)
        self.contentView.backgroundColor = UIColor.white
        self.contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tapCellAction)))
        
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.checkMark)
        self.contentView.addSubview(self.lineView)
        
        self.titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(37)
            make.centerY.equalTo(self.contentView)
        }
        
        self.checkMark.snp.makeConstraints { make in
            make.centerY.equalTo(self.contentView)
            make.trailing.equalTo(-37)
            make.width.height.equalTo(26)
        }
        
        self.lineView.snp.makeConstraints { make in
            make.bottom.equalTo(0)
            make.centerX.equalTo(self.contentView)
            make.leading.equalTo(37)
            make.height.equalTo(0.5)
        }
    }
    
    @objc func tapCellAction() {
        self.cellItem?.tap?()
    }
    
    func reloadCell<T>(data: T) {
        guard let item = data as? TBAuthorizationSequenceLanguageItem else {
            return
        }
        self.cellItem = item
        self.titleLabel.text = TBLanguage.sharedInstance.localizable(item.data.lanKey)
        self.checkMark.isHidden = item.isSelect ? false : true
    }
}

class TBAuthorizationSequenceLanguageView : UIView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    private let collectionView: UICollectionView
    
    private let titleLabel : UILabel
    
    private var dataSourceArr: [TBCollectionSection]
    
    var selectLan: ((TBAuthorizationSequenceLanguageItem)->Void)?
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override init(frame: CGRect) {
        self.collectionView = UICollectionView(frame: frame, collectionViewLayout: UICollectionViewFlowLayout())
        self.dataSourceArr = [TBCollectionSection]()
        self.titleLabel = UILabel()
        super.init(frame: frame)
        self.setupView()
    }
    
    private func setupView() {
        self.configCollection()
        self.configLabel()
        self.batchMakeConstraints()
        self.reloadData()
    }
    
    func reloadData() {
        self.setupDataSource()
        self.collectionView.reloadData()
    }
    
    private func configLabel() {
        self.titleLabel.text = TBLanguage.sharedInstance.localizable(TBLankey.language_text)
        self.titleLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        self.titleLabel.textColor = UIColor(rgb: 0x03BDFF)
        self.titleLabel.numberOfLines = 1
    }
    
    private func configCollection() -> Void {
        self.collectionView.backgroundColor = UIColor(rgb: 0xFFFFFF);
        self.addSubview(self.collectionView)
        self.collectionView.showsVerticalScrollIndicator = false
        self.collectionView.isScrollEnabled = false
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        self.collectionView.register(LanguageCell.self, forCellWithReuseIdentifier: NSStringFromClass(LanguageCell.self))
        self.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: NSStringFromClass(UICollectionViewCell.self))
    }
    
    private func batchMakeConstraints() {
        self.addSubview(self.titleLabel)
        self.addSubview(collectionView)
        
        self.titleLabel.snp.makeConstraints { make in
            make.top.equalTo(25)
            make.leading.equalTo(37)
            make.height.equalTo(18)
        }
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(self.titleLabel.snp.bottom)
            make.leading.trailing.bottom.equalTo(0)
        }
    }
    
    
    
    private func setupDataSource() ->Void {
        
        
        let section =  TBCollectionSection()
        
        var itemArr = [TBAuthorizationSequenceLanguageItem]()
        for lanMap in TBLanguage.sharedInstance.supportLanguages {
            if let lankey = lanMap.keys.first, let lanCode = lanMap.values.first {
                let data = TBAuthorizationSequenceLanguageData(lanKey: lankey, lanCode: lanCode)
                let item = TBAuthorizationSequenceLanguageItem(data: data)
                if item.data.lanCode == TBLanguage.sharedInstance.languageCode{
                    item.isSelect = true
                }
                itemArr.append(item)
            }
        }
        section.items = itemArr
        for item in section.items {
            guard let aItem = item as? TBAuthorizationSequenceLanguageItem else {break}
            aItem.itemType = TBAuthorizationSequenceLanguage.language.rawValue
            aItem.itemSize = CGSize(width: UIScreen.main.bounds.width, height: 48)
            aItem.cellClass = LanguageCell.self
            aItem.tap = { [weak self, weak aItem] in
                if let strongSelf = self, let strongItem = aItem {
                    strongSelf.selectItem(strongItem, section)
                    strongSelf.collectionView.reloadData()
                    strongSelf.selectLan?(strongItem)
                }
            }
        }
        
        self.dataSourceArr = [section]
    }
    
    func selectItem(_ item:TBAuthorizationSequenceLanguageItem, _ section: TBCollectionSection) {
        item.isSelect = true
        TBTrack.track(TBTrackEvent.Language.phonenumber_language_click.rawValue)
        for aItem in section.items {
            guard let bItem = aItem as? TBAuthorizationSequenceLanguageItem else { break }
            if bItem.data.lanCode != item.data.lanCode {
                bItem.isSelect = false
            }
        }
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
