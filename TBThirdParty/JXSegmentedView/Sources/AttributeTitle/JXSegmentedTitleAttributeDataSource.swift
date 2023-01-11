







import UIKit

open class JXSegmentedTitleAttributeDataSource: JXSegmentedBaseDataSource {
    
    open var attributedTitles = [NSAttributedString]()
    
    open var selectedAttributedTitles: [NSAttributedString]?
    
    open var widthForTitleClosure: ((NSAttributedString)->(CGFloat))?
    
    open var titleNumberOfLines: Int = 2

    open override func preferredItemModelInstance() -> JXSegmentedBaseItemModel {
        return JXSegmentedTitleAttributeItemModel()
    }

    open override func preferredItemCount() -> Int {
        return attributedTitles.count
    }

    open override func preferredRefreshItemModel(_ itemModel: JXSegmentedBaseItemModel, at index: Int, selectedIndex: Int) {
        super.preferredRefreshItemModel(itemModel, at: index, selectedIndex: selectedIndex)

        guard let myItemModel = itemModel as? JXSegmentedTitleAttributeItemModel else {
            return
        }

        myItemModel.attributedTitle = attributedTitles[index]
        myItemModel.selectedAttributedTitle = selectedAttributedTitles?[index]
        myItemModel.textWidth = widthForTitle(myItemModel.attributedTitle, selectedTitle: myItemModel.selectedAttributedTitle)
        myItemModel.titleNumberOfLines = titleNumberOfLines
    }

    open func widthForTitle(_ title: NSAttributedString?, selectedTitle: NSAttributedString?) -> CGFloat {
        let attriText = selectedTitle != nil ? selectedTitle : title
        guard let text = attriText else {
            return 0
        }
        if widthForTitleClosure != nil {
            return widthForTitleClosure!(text)
        }else {
            let textWidth = text.boundingRect(with: CGSize(width: CGFloat.infinity, height: CGFloat.infinity), options: NSStringDrawingOptions.init(rawValue: NSStringDrawingOptions.usesLineFragmentOrigin.rawValue | NSStringDrawingOptions.usesFontLeading.rawValue), context: nil).size.width
            return CGFloat(ceilf(Float(textWidth)))
        }
    }

    
    open override func preferredSegmentedView(_ segmentedView: JXSegmentedView, widthForItemAt index: Int) -> CGFloat {
        var width: CGFloat = 0
        if itemWidth == JXSegmentedViewAutomaticDimension {
            let myItemModel = dataSource[index] as! JXSegmentedTitleAttributeItemModel
            width = myItemModel.textWidth + itemWidthIncrement
        }else {
            width = itemWidth + itemWidthIncrement
        }
        return width
    }

    
    open override func registerCellClass(in segmentedView: JXSegmentedView) {
        segmentedView.collectionView.register(JXSegmentedTitleAttributeCell.self, forCellWithReuseIdentifier: "cell")
    }

    open override func segmentedView(_ segmentedView: JXSegmentedView, cellForItemAt index: Int) -> JXSegmentedBaseCell {
        let cell = segmentedView.dequeueReusableCell(withReuseIdentifier: "cell", at: index)
        return cell
    }
}
