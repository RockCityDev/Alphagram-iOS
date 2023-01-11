






import UIKit
import SnapKit
import AuthorizationUI

private enum TBChannelRecommendItemType: Int {
    case group
    case explore
}


class TBChannelRecommendCell : UICollectionViewCell, TBCell, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    private var dataSourceArr = [TBCollectionSection]()
    private let collectionView : UICollectionView

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        self.collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: flowLayout)
        super.init(frame: frame)
        self.setupView()
    }
    
    
    
    func setupView() {
        self.configCollection()
        self.batchMakeConstraints()
        self.setupDataSource()
        self.collectionView.reloadData()
    }
    
    func configCollection() -> Void {
        self.collectionView.backgroundColor = UIColor.white;
        self.contentView.addSubview(self.collectionView)
        self.collectionView.alwaysBounceHorizontal = true
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        self.collectionView.register(TBChannelExploreGroupCell.self, forCellWithReuseIdentifier: NSStringFromClass(TBChannelExploreGroupCell.self))
        self.collectionView.register(TBChannelGroupCel.self, forCellWithReuseIdentifier: NSStringFromClass(TBChannelGroupCel.self))
        self.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: NSStringFromClass(UICollectionViewCell.self))
        
    }
    
    func batchMakeConstraints() {
        self.contentView.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.leading.trailing.bottom.equalTo(0)
        }
    }
    
    
    
    func setupDataSource() ->Void {
        
        
        let section =  TBCollectionSection()
        section.insets = UIEdgeInsets(top: 13, left: 16, bottom: 13, right: 16)
        section.minumLineSpace = 4
        section.minimumInteritemSpace = 0
        
        
        let groupItem = TBCollectionItem()
        groupItem.itemType = TBChannelRecommendItemType.group.rawValue
        groupItem.cellClass = TBChannelGroupCel.self
        groupItem.itemSize = CGSize(width: 213, height: 60)
        
        let exploreItem = TBCollectionItem()
        exploreItem.itemType = TBChannelRecommendItemType.explore.rawValue
        exploreItem.cellClass = TBChannelExploreGroupCell.self
        exploreItem.itemSize = CGSize(width: 213, height: 60)
        
        for _ in 1...10 {
            section.items.append(groupItem)
        }
        section.items.append(exploreItem)
        
        self.dataSourceArr = [section]
        
    }
    
    
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let item = TBCollectionSection.item(self.dataSourceArr, indexPath){
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(item.cellClass), for: indexPath)
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
    
    
    func reloadCell<T>(data: T) {
        
    }

    
}
