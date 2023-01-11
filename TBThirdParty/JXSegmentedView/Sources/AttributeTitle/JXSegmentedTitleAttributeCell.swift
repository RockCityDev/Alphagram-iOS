







import UIKit

open class JXSegmentedTitleAttributeCell: JXSegmentedBaseCell {
    open var titleLabel = UILabel()

    open override func commonInit() {
        super.commonInit()

        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)

        let centerX = NSLayoutConstraint(item: titleLabel, attribute: .centerX, relatedBy: .equal, toItem: contentView, attribute: .centerX, multiplier: 1, constant: 0)
        contentView.addConstraint(centerX)
        let centerY = NSLayoutConstraint(item: titleLabel, attribute: .centerY, relatedBy: .equal, toItem: contentView, attribute: .centerY, multiplier: 1, constant: 0)
        contentView.addConstraint(centerY)
    }

    open override func reloadData(itemModel: JXSegmentedBaseItemModel, selectedType: JXSegmentedViewItemSelectedType) {
        super.reloadData(itemModel: itemModel, selectedType: selectedType )

        guard let myItemModel = itemModel as? JXSegmentedTitleAttributeItemModel else {
            return
        }

        titleLabel.numberOfLines = myItemModel.titleNumberOfLines
        if myItemModel.isSelected && myItemModel.selectedAttributedTitle != nil {
            titleLabel.attributedText = myItemModel.selectedAttributedTitle
        }else {
            titleLabel.attributedText = myItemModel.attributedTitle
        }
    }
}
