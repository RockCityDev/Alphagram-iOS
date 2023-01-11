







import UIKit



open class JXSegmentedIndicatorRainbowLineView: JXSegmentedIndicatorLineView {
    
    open var indicatorColors = [UIColor]()

    open override func refreshIndicatorState(model: JXSegmentedIndicatorSelectedParams) {
        super.refreshIndicatorState(model: model)

        backgroundColor = indicatorColors[model.currentSelectedIndex]
    }

    open override func contentScrollViewDidScroll(model: JXSegmentedIndicatorTransitionParams) {
        super.contentScrollViewDidScroll(model: model)

        guard canHandleTransition(model: model) else {
            return
        }

        backgroundColor = JXSegmentedViewTool.interpolateColor(from: indicatorColors[model.leftIndex], to: indicatorColors[model.rightIndex], percent: model.percent)
    }

    open override func selectItem(model: JXSegmentedIndicatorSelectedParams) {
        super.selectItem(model: model)

        backgroundColor = indicatorColors[model.currentSelectedIndex]
    }

}
