







import UIKit
import SegementSlide
import JXSegmentedView
import Display

open class SegementSlideCustomViewController: SegementSlideViewController {
    
    private let segmentedView = JXSegmentedView()
    
    private lazy var segmentedDataSource: JXSegmentedNumberDataSource = {
        let dataSource = TBSegmentedNumberDataSource()
        dataSource.titleSelectedColor = .white
        dataSource.titleNormalColor = UIColor(rgb: 0x414147)
        dataSource.titleNormalFont = UIFont.systemFont(ofSize: 13, weight: .regular)
        dataSource.titleSelectedFont = UIFont.systemFont(ofSize: 13, weight: .regular)
        dataSource.isTitleColorGradientEnabled = true
        dataSource.isItemTransitionEnabled = true
        dataSource.isItemSpacingAverageEnabled = false
        dataSource.isSelectedAnimable = true
        dataSource.isTitleMaskEnabled = false
        dataSource.itemSpacing = 40
        return dataSource
    }()
    
    public override func segementSlideSwitcherView() -> SegementSlideSwitcherDelegate {
        let indicator = JXSegmentedIndicatorBackgroundView()
        indicator.indicatorColor = UIColor(rgb: 0x4B5BFF)
        indicator.indicatorHeight = 34
        indicator.indicatorWidthIncrement = 32
        segmentedView.indicators = [indicator]
        segmentedView.delegate = self
        segmentedView.ssDataSource = self
        segmentedView.contentEdgeInsetLeft = 28
        segmentedView.contentEdgeInsetRight = 28
        return segmentedView
    }
    
    open override func setupSwitcher() {
        super.setupSwitcher()
        segmentedDataSource.titles = titlesInSwitcher
        segmentedDataSource.numbers = badgesInSwitcher
        segmentedView.dataSource = segmentedDataSource
        segmentedView.contentScrollView = contentView.scrollView
    }
    
    open var switcherViewHeight: CGFloat {
        return 50
    }
    
    open var titlesInSwitcher: [String] {
        return []
    }
    
    open var badgesInSwitcher: [Int] {
        return []
    }
    
}

extension SegementSlideCustomViewController: SegementSlideSwitcherDataSource {
    
    public var height: CGFloat {
        return switcherViewHeight
    }
    
    public var titles: [String] {
        return titlesInSwitcher
    }
    
}

extension SegementSlideCustomViewController: JXSegmentedViewDelegate {
    
    public func segmentedView(_ segmentedView: JXSegmentedView, didClickSelectedItemAt index: Int) {
        contentView.selectItem(at: index, animated: true)
    }
    
}
