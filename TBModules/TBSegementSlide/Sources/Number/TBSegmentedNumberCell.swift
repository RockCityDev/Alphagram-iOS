







import UIKit
import JXSegmentedView
import Display

open class TBSegmentedNumberCell: JXSegmentedNumberCell {
    
    public let accossoryView = UIView()

    open override func commonInit() {
        super.commonInit()
        self.contentView.insertSubview(self.accossoryView, at: 0)
        
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()

        guard let myItemModel = itemModel as? TBSegmentedNumberItemModel else {
            return
        }
        
        let height = myItemModel.accessoryHeight
        let width = titleLabel.frame.width + myItemModel.accessoryWidthIncrement
        accossoryView.layer.cornerRadius = height / 2
        accossoryView.layer.borderWidth = myItemModel.accessoryBorderWidth
        accossoryView.bounds.size = CGSize(width: width, height: height)
        accossoryView.center = titleLabel.center
    }

    open override func reloadData(itemModel: JXSegmentedBaseItemModel, selectedType: JXSegmentedViewItemSelectedType) {
        super.reloadData(itemModel: itemModel, selectedType: selectedType )

        guard let myItemModel = itemModel as? TBSegmentedNumberItemModel else {
            return
        }
        accossoryView.layer.borderColor = myItemModel.currentAccessoryBorderColor.cgColor
        accossoryView.backgroundColor = myItemModel.currentAccessoryColor
        setNeedsLayout()
    }

}
