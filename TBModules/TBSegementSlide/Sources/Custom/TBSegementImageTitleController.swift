import UIKit
import SegementSlide
import JXSegmentedView
import Display
import SDWebImage

open class TBSegementImageTitleController: SegementSlideViewController, JXSegmentedViewDelegate {
    
    private let segmentedView = JXSegmentedView()
    
    private lazy var segmentedDataSource: JXSegmentedTitleImageDataSource = {
        let dataSource = JXSegmentedTitleImageDataSource()
        dataSource.titleSelectedColor = UIColor(rgb: 0x414147)
        dataSource.titleImageType = .leftImage
        dataSource.titleNormalColor = UIColor(rgb: 0x414147)
        dataSource.titleNormalFont = UIFont.systemFont(ofSize: 13, weight: .regular)
        dataSource.titleSelectedFont = UIFont.systemFont(ofSize: 13, weight: .regular)
        dataSource.isTitleColorGradientEnabled = true
        dataSource.isItemTransitionEnabled = true
        dataSource.isItemSpacingAverageEnabled = false
        dataSource.isSelectedAnimable = true
        dataSource.isTitleMaskEnabled = false
        dataSource.itemSpacing = 16
        return dataSource
    }()
    
    public override func segementSlideSwitcherView() -> SegementSlideSwitcherDelegate {
        let indicator = JXSegmentedIndicatorBackgroundView()
        indicator.backgroundColor = UIColor.red
        indicator.indicatorColor = UIColor(rgb: 0x4B5BFF)
        indicator.indicatorHeight = 3
        indicator.indicatorWidthIncrement = 2
        indicator.indicatorPosition = .bottom
        segmentedView.indicators = [indicator]
        segmentedView.delegate = self
        segmentedView.ssDataSource = self
        segmentedView.contentEdgeInsetLeft = 16
        segmentedView.contentEdgeInsetRight = 16
        return segmentedView
    }
    
    open override func setupSwitcher() {
        super.setupSwitcher()
        segmentedDataSource.titles = titlesInSwitcher
        segmentedDataSource.normalImageInfos = normalImageInfosSwitcher
        segmentedDataSource.loadImageClosure = {(imageView, normalImageInfo) in
            imageView.sd_setImage(with: URL(string: normalImageInfo), placeholderImage: UIImage(named: ""))
        }
        segmentedView.dataSource = segmentedDataSource
        segmentedView.contentScrollView = contentView.scrollView
    }
    
    open var switcherViewHeight: CGFloat {
        return 50
    }
    
    open var titlesInSwitcher: [String] {
        return []
    }
    
    open var normalImageInfosSwitcher: [String] {
        return []
    }
    
    open func segmentedView(_ segmentedView: JXSegmentedView, didClickSelectedItemAt index: Int) {
        contentView.selectItem(at: index, animated: true)
    }
    
    open func segmentedView(_ segmentedView: JXSegmentedView, didSelectedItemAt index: Int) {
        
    }
    
    open func segmentedView(_ segmentedView: JXSegmentedView, didScrollSelectedItemAt index: Int) {
        
    }
}

extension TBSegementImageTitleController: SegementSlideSwitcherDataSource {
    
    public var height: CGFloat {
        return switcherViewHeight
    }
    
    public var titles: [String] {
        return titlesInSwitcher
    }
    
}






