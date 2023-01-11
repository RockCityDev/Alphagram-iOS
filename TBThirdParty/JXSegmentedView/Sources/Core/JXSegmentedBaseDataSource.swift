







import Foundation
import  UIKit

open class JXSegmentedBaseDataSource: JXSegmentedViewDataSource {
    
    open var dataSource = [JXSegmentedBaseItemModel]()
    
    open var itemWidth: CGFloat = JXSegmentedViewAutomaticDimension
    
    open var itemWidthIncrement: CGFloat = 0
    
    open var itemSpacing: CGFloat = 20
    
    open var isItemSpacingAverageEnabled: Bool = true
    
    open var isItemTransitionEnabled: Bool = true
    
    open var isSelectedAnimable: Bool = false
    
    open var selectedAnimationDuration: TimeInterval = 0.25
    
    open var isItemWidthZoomEnabled: Bool = false
    
    open var itemWidthSelectedZoomScale: CGFloat = 1.5

    @available(*, deprecated, renamed: "itemWidth")
    open var itemContentWidth: CGFloat = JXSegmentedViewAutomaticDimension {
        didSet {
            itemWidth = itemContentWidth
        }
    }

    private var animator: JXSegmentedAnimator?

    deinit {
        animator?.stop()
    }

    public init() {
    }

    
    
    
    open func reloadData(selectedIndex: Int) {
        dataSource.removeAll()
        for index in 0..<preferredItemCount() {
            let itemModel = preferredItemModelInstance()
            preferredRefreshItemModel(itemModel, at: index, selectedIndex: selectedIndex)
            dataSource.append(itemModel)
        }
    }

    open func preferredItemCount() -> Int {
        return 0
    }

    
    open func preferredItemModelInstance() -> JXSegmentedBaseItemModel  {
        return JXSegmentedBaseItemModel()
    }

    
    open func preferredSegmentedView(_ segmentedView: JXSegmentedView, widthForItemAt index: Int) -> CGFloat {
        return itemWidthIncrement
    }

    
    open func preferredRefreshItemModel(_ itemModel: JXSegmentedBaseItemModel, at index: Int, selectedIndex: Int) {
        itemModel.index = index
        itemModel.isItemTransitionEnabled = isItemTransitionEnabled
        itemModel.isSelectedAnimable = isSelectedAnimable
        itemModel.selectedAnimationDuration = selectedAnimationDuration
        itemModel.isItemWidthZoomEnabled = isItemWidthZoomEnabled
        itemModel.itemWidthNormalZoomScale = 1
        itemModel.itemWidthSelectedZoomScale = itemWidthSelectedZoomScale
        if index == selectedIndex {
            itemModel.isSelected = true
            itemModel.itemWidthCurrentZoomScale = itemModel.itemWidthSelectedZoomScale
        }else {
            itemModel.isSelected = false
            itemModel.itemWidthCurrentZoomScale = itemModel.itemWidthNormalZoomScale
        }
    }

    
    open func itemDataSource(in segmentedView: JXSegmentedView) -> [JXSegmentedBaseItemModel] {
        return dataSource
    }

    
    public final func segmentedView(_ segmentedView: JXSegmentedView, widthForItemAt index: Int) -> CGFloat {
        return preferredSegmentedView(segmentedView, widthForItemAt: index)
    }

    public func segmentedView(_ segmentedView: JXSegmentedView, widthForItemContentAt index: Int) -> CGFloat {
        return self.segmentedView(segmentedView, widthForItemAt: index)
    }

    open func registerCellClass(in segmentedView: JXSegmentedView) {

    }

    open func segmentedView(_ segmentedView: JXSegmentedView, cellForItemAt index: Int) -> JXSegmentedBaseCell {
        return JXSegmentedBaseCell()
    }

    open func refreshItemModel(_ segmentedView: JXSegmentedView, currentSelectedItemModel: JXSegmentedBaseItemModel, willSelectedItemModel: JXSegmentedBaseItemModel, selectedType: JXSegmentedViewItemSelectedType) {
        currentSelectedItemModel.isSelected = false
        willSelectedItemModel.isSelected = true

        if isItemWidthZoomEnabled {
            if (selectedType == .scroll && !isItemTransitionEnabled) ||
                selectedType == .click ||
                selectedType == .code {
                animator = JXSegmentedAnimator()
                animator?.duration = selectedAnimationDuration
                animator?.progressClosure = {[weak self] (percent) in
                    guard let self = self else { return }
                    currentSelectedItemModel.itemWidthCurrentZoomScale = JXSegmentedViewTool.interpolate(from: currentSelectedItemModel.itemWidthSelectedZoomScale, to: currentSelectedItemModel.itemWidthNormalZoomScale, percent: percent)
                    currentSelectedItemModel.itemWidth = self.itemWidthWithZoom(at: currentSelectedItemModel.index, model: currentSelectedItemModel)
                    willSelectedItemModel.itemWidthCurrentZoomScale = JXSegmentedViewTool.interpolate(from: willSelectedItemModel.itemWidthNormalZoomScale, to: willSelectedItemModel.itemWidthSelectedZoomScale, percent: percent)
                    willSelectedItemModel.itemWidth = self.itemWidthWithZoom(at: willSelectedItemModel.index, model: willSelectedItemModel)
                    segmentedView.collectionView.collectionViewLayout.invalidateLayout()
                }
                animator?.start()
            }
        }else {
            currentSelectedItemModel.itemWidthCurrentZoomScale = currentSelectedItemModel.itemWidthNormalZoomScale
            willSelectedItemModel.itemWidthCurrentZoomScale = willSelectedItemModel.itemWidthSelectedZoomScale
        }
    }

    open func refreshItemModel(_ segmentedView: JXSegmentedView, leftItemModel: JXSegmentedBaseItemModel, rightItemModel: JXSegmentedBaseItemModel, percent: CGFloat) {
        
        animator?.stop()
        animator = nil
        if isItemWidthZoomEnabled && isItemTransitionEnabled {
            
            leftItemModel.itemWidthCurrentZoomScale = JXSegmentedViewTool.interpolate(from: leftItemModel.itemWidthSelectedZoomScale, to: leftItemModel.itemWidthNormalZoomScale, percent: percent)
            leftItemModel.itemWidth = itemWidthWithZoom(at: leftItemModel.index, model: leftItemModel)
            rightItemModel.itemWidthCurrentZoomScale = JXSegmentedViewTool.interpolate(from: rightItemModel.itemWidthNormalZoomScale, to: rightItemModel.itemWidthSelectedZoomScale, percent: percent)
            rightItemModel.itemWidth = itemWidthWithZoom(at: rightItemModel.index, model: rightItemModel)
            segmentedView.collectionView.collectionViewLayout.invalidateLayout()
        }
    }

    
    public final func refreshItemModel(_ segmentedView: JXSegmentedView, _ itemModel: JXSegmentedBaseItemModel, at index: Int, selectedIndex: Int) {
        preferredRefreshItemModel(itemModel, at: index, selectedIndex: selectedIndex)
    }

    private func itemWidthWithZoom(at index: Int, model: JXSegmentedBaseItemModel) -> CGFloat {
        var width = self.segmentedView(JXSegmentedView(), widthForItemAt: index)
        if isItemWidthZoomEnabled {
            width *= model.itemWidthCurrentZoomScale
        }
        return width
    }
}
