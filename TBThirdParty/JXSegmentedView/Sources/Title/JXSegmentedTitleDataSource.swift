







import UIKit

open class JXSegmentedTitleDataSource: JXSegmentedBaseDataSource{
    
    open var titles = [String]()
    
    open var widthForTitleClosure: ((String)->(CGFloat))?
    
    open var titleNumberOfLines: Int = 1
    
    open var titleNormalColor: UIColor = .black
    
    open var titleSelectedColor: UIColor = .red
    
    open var titleNormalFont: UIFont = UIFont.systemFont(ofSize: 15)
    
    open var titleSelectedFont: UIFont?
    
    open var isTitleColorGradientEnabled: Bool = false
    
    open var isTitleZoomEnabled: Bool = false
    
    open var titleSelectedZoomScale: CGFloat = 1.2
    
    open var isTitleStrokeWidthEnabled: Bool = false
    
    open var titleSelectedStrokeWidth: CGFloat = -2
    
    open var isTitleMaskEnabled: Bool = false


    open override func preferredItemCount() -> Int {
        return titles.count
    }

    open override func preferredItemModelInstance() -> JXSegmentedBaseItemModel {
        return JXSegmentedTitleItemModel()
    }

    open override func preferredRefreshItemModel( _ itemModel: JXSegmentedBaseItemModel, at index: Int, selectedIndex: Int) {
        super.preferredRefreshItemModel(itemModel, at: index, selectedIndex: selectedIndex)

        guard let myItemModel = itemModel as? JXSegmentedTitleItemModel else {
            return
        }

        myItemModel.title = titles[index]
        myItemModel.textWidth = widthForTitle(myItemModel.title ?? "")
        myItemModel.titleNumberOfLines = titleNumberOfLines
        myItemModel.isSelectedAnimable = isSelectedAnimable
        myItemModel.titleNormalColor = titleNormalColor
        myItemModel.titleSelectedColor = titleSelectedColor
        myItemModel.titleNormalFont = titleNormalFont
        myItemModel.titleSelectedFont = titleSelectedFont != nil ? titleSelectedFont! : titleNormalFont
        myItemModel.isTitleZoomEnabled = isTitleZoomEnabled
        myItemModel.isTitleStrokeWidthEnabled = isTitleStrokeWidthEnabled
        myItemModel.isTitleMaskEnabled = isTitleMaskEnabled
        myItemModel.titleNormalZoomScale = 1
        myItemModel.titleSelectedZoomScale = titleSelectedZoomScale
        myItemModel.titleSelectedStrokeWidth = titleSelectedStrokeWidth
        myItemModel.titleNormalStrokeWidth = 0
        if index == selectedIndex {
            myItemModel.titleCurrentColor = titleSelectedColor
            myItemModel.titleCurrentZoomScale = titleSelectedZoomScale
            myItemModel.titleCurrentStrokeWidth = titleSelectedStrokeWidth
        }else {
            myItemModel.titleCurrentColor = titleNormalColor
            myItemModel.titleCurrentZoomScale = 1
            myItemModel.titleCurrentStrokeWidth = 0
        }
    }

    open func widthForTitle(_ title: String) -> CGFloat {
        if widthForTitleClosure != nil {
            return widthForTitleClosure!(title)
        }else {
            let textWidth = NSString(string: title).boundingRect(with: CGSize(width: CGFloat.infinity, height: CGFloat.infinity), options: [.usesFontLeading, .usesLineFragmentOrigin], attributes: [NSAttributedString.Key.font : titleNormalFont], context: nil).size.width
            return CGFloat(ceilf(Float(textWidth)))
        }
    }

    
    open override func preferredSegmentedView(_ segmentedView: JXSegmentedView, widthForItemAt index: Int) -> CGFloat {
        var width = super.preferredSegmentedView(segmentedView, widthForItemAt: index)
        if itemWidth == JXSegmentedViewAutomaticDimension {
            width += (dataSource[index] as! JXSegmentedTitleItemModel).textWidth
        }else {
            width += itemWidth
        }
        return width
    }

    
    open override func registerCellClass(in segmentedView: JXSegmentedView) {
        segmentedView.collectionView.register(JXSegmentedTitleCell.self, forCellWithReuseIdentifier: "cell")
    }

    open override func segmentedView(_ segmentedView: JXSegmentedView, cellForItemAt index: Int) -> JXSegmentedBaseCell {
        let cell = segmentedView.dequeueReusableCell(withReuseIdentifier: "cell", at: index)
        return cell
    }

    public override func segmentedView(_ segmentedView: JXSegmentedView, widthForItemContentAt index: Int) -> CGFloat {
        let model = dataSource[index] as! JXSegmentedTitleItemModel
        if isTitleZoomEnabled {
            return model.textWidth*model.titleCurrentZoomScale
        }else {
            return model.textWidth
        }
    }

    open override func refreshItemModel(_ segmentedView: JXSegmentedView, leftItemModel: JXSegmentedBaseItemModel, rightItemModel: JXSegmentedBaseItemModel, percent: CGFloat) {
        super.refreshItemModel(segmentedView, leftItemModel: leftItemModel, rightItemModel: rightItemModel, percent: percent)
        
        guard let leftModel = leftItemModel as? JXSegmentedTitleItemModel, let rightModel = rightItemModel as? JXSegmentedTitleItemModel else {
            return
        }

        if isTitleZoomEnabled && isItemTransitionEnabled {
            leftModel.titleCurrentZoomScale = JXSegmentedViewTool.interpolate(from: leftModel.titleSelectedZoomScale, to: leftModel.titleNormalZoomScale, percent: CGFloat(percent))
            rightModel.titleCurrentZoomScale = JXSegmentedViewTool.interpolate(from: rightModel.titleNormalZoomScale, to: rightModel.titleSelectedZoomScale, percent: CGFloat(percent))
        }

        if isTitleStrokeWidthEnabled && isItemTransitionEnabled {
            leftModel.titleCurrentStrokeWidth = JXSegmentedViewTool.interpolate(from: leftModel.titleSelectedStrokeWidth, to: leftModel.titleNormalStrokeWidth, percent: CGFloat(percent))
            rightModel.titleCurrentStrokeWidth = JXSegmentedViewTool.interpolate(from: rightModel.titleNormalStrokeWidth, to: rightModel.titleSelectedStrokeWidth, percent: CGFloat(percent))
        }

        if isTitleColorGradientEnabled && isItemTransitionEnabled {
            leftModel.titleCurrentColor = JXSegmentedViewTool.interpolateThemeColor(from: leftModel.titleSelectedColor, to: leftModel.titleNormalColor, percent: percent)
            rightModel.titleCurrentColor = JXSegmentedViewTool.interpolateThemeColor(from:rightModel.titleNormalColor , to:rightModel.titleSelectedColor, percent: percent)
        }
    }

    open override func refreshItemModel(_ segmentedView: JXSegmentedView, currentSelectedItemModel: JXSegmentedBaseItemModel, willSelectedItemModel: JXSegmentedBaseItemModel, selectedType: JXSegmentedViewItemSelectedType) {
        super.refreshItemModel(segmentedView, currentSelectedItemModel: currentSelectedItemModel, willSelectedItemModel: willSelectedItemModel, selectedType: selectedType)

        guard let myCurrentSelectedItemModel = currentSelectedItemModel as? JXSegmentedTitleItemModel, let myWillSelectedItemModel = willSelectedItemModel as? JXSegmentedTitleItemModel else {
            return
        }

        myCurrentSelectedItemModel.titleCurrentColor = myCurrentSelectedItemModel.titleNormalColor
        myCurrentSelectedItemModel.titleCurrentZoomScale = myCurrentSelectedItemModel.titleNormalZoomScale
        myCurrentSelectedItemModel.titleCurrentStrokeWidth = myCurrentSelectedItemModel.titleNormalStrokeWidth
        myCurrentSelectedItemModel.indicatorConvertToItemFrame = CGRect.zero

        myWillSelectedItemModel.titleCurrentColor = myWillSelectedItemModel.titleSelectedColor
        myWillSelectedItemModel.titleCurrentZoomScale = myWillSelectedItemModel.titleSelectedZoomScale
        myWillSelectedItemModel.titleCurrentStrokeWidth = myWillSelectedItemModel.titleSelectedStrokeWidth
    }
}
