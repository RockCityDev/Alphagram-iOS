







import UIKit

open class JXSegmentedDotDataSource: JXSegmentedTitleDataSource {
    
    open var dotStates = [Bool]()
    
    open var dotSize = CGSize(width: 10, height: 10)
    
    open var dotCornerRadius: CGFloat = JXSegmentedViewAutomaticDimension
    
    open var dotColor = UIColor.red
    
    open var dotOffset: CGPoint = CGPoint.zero

    open override func preferredItemModelInstance() -> JXSegmentedBaseItemModel {
        return JXSegmentedDotItemModel()
    }

    open override func preferredRefreshItemModel(_ itemModel: JXSegmentedBaseItemModel, at index: Int, selectedIndex: Int) {
        super.preferredRefreshItemModel(itemModel, at: index, selectedIndex: selectedIndex)

        guard let itemModel = itemModel as? JXSegmentedDotItemModel else {
            return
        }

        itemModel.dotOffset = dotOffset
        itemModel.dotState = dotStates[index]
        itemModel.dotColor = dotColor
        itemModel.dotSize = dotSize
        if dotCornerRadius == JXSegmentedViewAutomaticDimension {
            itemModel.dotCornerRadius = dotSize.height/2
        }else {
            itemModel.dotCornerRadius = dotCornerRadius
        }
    }

    
    open override func registerCellClass(in segmentedView: JXSegmentedView) {
        segmentedView.collectionView.register(JXSegmentedDotCell.self, forCellWithReuseIdentifier: "cell")
    }

    open override func segmentedView(_ segmentedView: JXSegmentedView, cellForItemAt index: Int) -> JXSegmentedBaseCell {
        let cell = segmentedView.dequeueReusableCell(withReuseIdentifier: "cell", at: index)
        return cell
    }
}
