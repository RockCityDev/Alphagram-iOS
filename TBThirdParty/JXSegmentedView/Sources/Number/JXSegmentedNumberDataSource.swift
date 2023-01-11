







import Foundation
import UIKit

open class JXSegmentedNumberDataSource: JXSegmentedTitleDataSource {
    
    open var numbers = [Int]()
    
    open var numberWidthIncrement: CGFloat = 10
    
    open var numberBackgroundColor: UIColor = .red
    
    open var numberTextColor: UIColor = .white
    
    open var numberFont: UIFont = UIFont.systemFont(ofSize: 11)
    
    open var numberOffset: CGPoint = CGPoint.zero
    
    open var numberStringFormatterClosure: ((Int) -> String)?
    
    open var numberHeight: CGFloat = 14

    open override func preferredItemModelInstance() -> JXSegmentedBaseItemModel {
        return JXSegmentedNumberItemModel()
    }

    open override func preferredRefreshItemModel(_ itemModel: JXSegmentedBaseItemModel, at index: Int, selectedIndex: Int) {
        super.preferredRefreshItemModel(itemModel, at: index, selectedIndex: selectedIndex)

        guard let itemModel = itemModel as? JXSegmentedNumberItemModel else {
            return
        }

        itemModel.number = numbers[index]
        if numberStringFormatterClosure != nil {
            itemModel.numberString = numberStringFormatterClosure!(itemModel.number)
        }else {
            itemModel.numberString = "\(itemModel.number)"
        }
        itemModel.numberTextColor = numberTextColor
        itemModel.numberBackgroundColor = numberBackgroundColor
        itemModel.numberOffset = numberOffset
        itemModel.numberWidthIncrement = numberWidthIncrement
        itemModel.numberHeight = numberHeight
        itemModel.numberFont = numberFont
    }

    
    open override func registerCellClass(in segmentedView: JXSegmentedView) {
        segmentedView.collectionView.register(JXSegmentedNumberCell.self, forCellWithReuseIdentifier: "cell")
    }

    open override func segmentedView(_ segmentedView: JXSegmentedView, cellForItemAt index: Int) -> JXSegmentedBaseCell {
        let cell = segmentedView.dequeueReusableCell(withReuseIdentifier: "cell", at: index)
        return cell
    }
}
