import Foundation
import UIKit
import Display
import AsyncDisplayKit
import TelegramPresentationData
import TBAccount
import SnapKit
import SwiftUI
import TBWeb3Core


public class TBItemListLabelsContentView: UIView {
    public var didSelectItemBlock:((TBWeb3GroupInfoEntry.Tag)->Void)?
    public var didTapItemIconBlock:((TBWeb3GroupInfoEntry.Tag)->Void)?
    public let collectionView:UICollectionView
    public var items = [TBWeb3GroupInfoEntry.Tag]()
    public let config: TBItemListLabelsContentLayoutConfig
    
    public init(config:TBItemListLabelsContentLayoutConfig) {
        self.config = config
        let layout = AlignedCollectionViewFlowLayout()
        layout.horizontalAlignment = .leading
        layout.sectionInset = config.insetForSection
        layout.minimumLineSpacing = config.minimumLineSpacing
        layout.minimumInteritemSpacing = config.minimumInteritemSpacing
        self.collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        super.init(frame: .zero)
        
        self.addSubview(self.collectionView)
        self.collectionView.contentInsetAdjustmentBehavior = .never
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.backgroundColor = .clear
        self.collectionView.register(TBItemListLabelItemCell.self, forCellWithReuseIdentifier: NSStringFromClass(TBItemListLabelItemCell.self))
        self.collectionView.register(TBItemListLabelItemSpecialCell.self, forCellWithReuseIdentifier: NSStringFromClass(TBItemListLabelItemSpecialCell.self))
        self.collectionView.register(TBItemListLabelItemTextCell.self, forCellWithReuseIdentifier: NSStringFromClass(TBItemListLabelItemTextCell.self))
        self.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: NSStringFromClass(UICollectionViewCell.self))
        self.collectionView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
        self.collectionView.reloadData()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    public func reloadView(items:[TBWeb3GroupInfoEntry.Tag]){
        self.items = items
        self.collectionView.reloadData()
    }
    
    public func deleteLabel(_ labelEntity: TBWeb3GroupInfoEntry.Tag, completion:@escaping ([TBWeb3GroupInfoEntry.Tag]) -> Void) {
        if self.items.contains(labelEntity) {
            var items = self.items
            var index:Int? = nil
            for (idx, e) in items.enumerated() {
                if e == labelEntity {
                    items.remove(at: idx)
                    index = idx
                    break
                }
            }
            self.items = items
            self.collectionView.performBatchUpdates {
                if let index = index {
                   try? self.collectionView.deleteItems(at: [IndexPath(item: index, section: 0)])
                }
            } completion: { finished in
                completion(self.items)
            }
        }else{
            completion(self.items)
        }
    }
}

extension TBItemListLabelsContentView: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.items.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if let item = self.safeItem(at: indexPath) {
            let cell: UICollectionViewCell
            switch self.config.viewType {
            case .normal:
                cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(TBItemListLabelItemCell.self), for: indexPath)
                if let cell:TBItemListLabelItemCell = cell as? TBItemListLabelItemCell {
                    cell.reloadCell(item: item, config: self.config)
                }
            case .special:
                cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(TBItemListLabelItemSpecialCell.self), for: indexPath)
                if let cell:TBItemListLabelItemSpecialCell = cell as? TBItemListLabelItemSpecialCell {
                    cell.reloadCell(item: item, config: self.config)
                }
            case .text:
                cell = collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(TBItemListLabelItemTextCell.self), for: indexPath)
                if let cell:TBItemListLabelItemTextCell = cell as? TBItemListLabelItemTextCell {
                    cell.reloadCell(item: item, config: self.config)
                }
            }
            return cell
        }else{
            return collectionView.dequeueReusableCell(withReuseIdentifier: NSStringFromClass(UICollectionViewCell.self), for: indexPath)
        }
    }
    
}

extension TBItemListLabelsContentView {
    fileprivate func safeItem(at indexPath: IndexPath) -> TBWeb3GroupInfoEntry.Tag? {
        if indexPath.item < self.items.count {
            return self.items[indexPath.item]
        }else{
            return nil
        }
    }
}

extension TBItemListLabelsContentView: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let item = self.safeItem(at: indexPath) {
            if let didSelectItemBlock = self.didSelectItemBlock {
                didSelectItemBlock(item)
            }
        }
    }
}

extension TBItemListLabelsContentView : UICollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if let item = self.safeItem(at: indexPath) {
            return item.itemSize(config: self.config)
        }
        return CGSize.zero
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return self.config.minimumLineSpacing
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return self.config.minimumInteritemSpacing
    }
    
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return self.config.insetForSection
    }
    
    
}
