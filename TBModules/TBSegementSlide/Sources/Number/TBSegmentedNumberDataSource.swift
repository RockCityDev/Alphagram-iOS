







import UIKit
import JXSegmentedView
import Display

open class TBSegmentedNumberDataSource: JXSegmentedNumberDataSource{
    
    open var accessoryBorderWidth: CGFloat = 1.0
    open var accessoryWidthIncrement: CGFloat = 32
    open var accessoryHeight:CGFloat = 34
    
    open var normalAccessoryBorderColor:UIColor = UIColor(rgb: 0xE7E8EB)
    open var normalAccessoryColor:UIColor = .clear
    
    open var selectAccessoryBorderColor: UIColor = UIColor(rgb: 0x4B5BFF)
    open var selectAccessoryColor:UIColor = .clear
    
    open var isAccessoryGradientEnabled: Bool = true
    open var isAccessoryBorderGradientEnabled:Bool = true
    
    open override func preferredItemModelInstance() -> JXSegmentedBaseItemModel {
        return TBSegmentedNumberItemModel()
    }

    
    open override func registerCellClass(in segmentedView: JXSegmentedView) {
        segmentedView.collectionView.register(TBSegmentedNumberCell.self, forCellWithReuseIdentifier: "cell")
    }
    
    open override func preferredRefreshItemModel(_ itemModel: JXSegmentedBaseItemModel, at index: Int, selectedIndex: Int) {
        super.preferredRefreshItemModel(itemModel, at: index, selectedIndex: selectedIndex)

        guard let itemModel = itemModel as? TBSegmentedNumberItemModel else {
            return
        }
        itemModel.accessoryBorderWidth = self.accessoryBorderWidth
        itemModel.accessoryWidthIncrement = self.accessoryWidthIncrement
        itemModel.accessoryHeight = self.accessoryHeight
        
        
        itemModel.normalAccessoryBorderColor = self.normalAccessoryBorderColor
        itemModel.normalAccessoryColor = self.normalAccessoryColor
        itemModel.selectAccessoryBorderColor = self.selectAccessoryBorderColor
        itemModel.selectAccessoryColor = self.selectAccessoryColor
        
        if index == selectedIndex {
            itemModel.currentAccessoryColor = self.selectAccessoryColor
            itemModel.currentAccessoryBorderColor = self.selectAccessoryBorderColor
        }else {
            itemModel.currentAccessoryColor = self.normalAccessoryColor
            itemModel.currentAccessoryBorderColor = self.normalAccessoryBorderColor
        }
    }
    
    open override func refreshItemModel(_ segmentedView: JXSegmentedView, leftItemModel: JXSegmentedBaseItemModel, rightItemModel: JXSegmentedBaseItemModel, percent: CGFloat) {
        super.refreshItemModel(segmentedView, leftItemModel: leftItemModel, rightItemModel: rightItemModel, percent: percent)
        
        guard let leftModel = leftItemModel as? TBSegmentedNumberItemModel, let rightModel = rightItemModel as? TBSegmentedNumberItemModel else {
            return
        }
        
        if isAccessoryGradientEnabled && isItemTransitionEnabled {
            leftModel.currentAccessoryColor = JXSegmentedViewTool.interpolateThemeColor(from: leftModel.selectAccessoryColor, to: leftModel.normalAccessoryColor, percent: percent)
            rightModel.currentAccessoryColor =  JXSegmentedViewTool.interpolateThemeColor(from:rightModel.normalAccessoryColor , to:rightModel.selectAccessoryColor, percent: percent)
        }
        
        if isAccessoryBorderGradientEnabled && isItemTransitionEnabled {
            leftModel.currentAccessoryBorderColor = JXSegmentedViewTool.interpolateThemeColor(from: leftModel.selectAccessoryBorderColor, to: leftModel.normalAccessoryBorderColor, percent: percent)
            rightModel.currentAccessoryBorderColor = JXSegmentedViewTool.interpolateThemeColor(from:rightModel.normalAccessoryBorderColor , to:rightModel.selectAccessoryBorderColor, percent: percent)
        }
    }

    open override func refreshItemModel(_ segmentedView: JXSegmentedView, currentSelectedItemModel: JXSegmentedBaseItemModel, willSelectedItemModel: JXSegmentedBaseItemModel, selectedType: JXSegmentedViewItemSelectedType) {
        super.refreshItemModel(segmentedView, currentSelectedItemModel: currentSelectedItemModel, willSelectedItemModel: willSelectedItemModel, selectedType: selectedType)

        guard let myCurrentSelectedItemModel = currentSelectedItemModel as? TBSegmentedNumberItemModel, let myWillSelectedItemModel = willSelectedItemModel as? TBSegmentedNumberItemModel else {
            return
        }
        
        myCurrentSelectedItemModel.currentAccessoryColor = myCurrentSelectedItemModel.normalAccessoryColor
        myCurrentSelectedItemModel.currentAccessoryBorderColor = myCurrentSelectedItemModel.normalAccessoryBorderColor
        
        myWillSelectedItemModel.currentAccessoryColor = myWillSelectedItemModel.selectAccessoryColor
        myWillSelectedItemModel.currentAccessoryBorderColor = myWillSelectedItemModel.selectAccessoryBorderColor
    }

    
    
}
