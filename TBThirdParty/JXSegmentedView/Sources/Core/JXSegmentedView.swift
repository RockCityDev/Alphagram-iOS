







import UIKit

public let JXSegmentedViewAutomaticDimension: CGFloat = -1







public enum JXSegmentedViewItemSelectedType {
    case unknown
    case code
    case click
    case scroll
}

public protocol JXSegmentedViewListContainer {
    var defaultSelectedIndex: Int { set get }
    func contentScrollView() -> UIScrollView
    func reloadData()
    func didClickSelectedItem(at index: Int)
}

public protocol JXSegmentedViewDataSource: AnyObject {
    var isItemWidthZoomEnabled: Bool { get }
    var selectedAnimationDuration: TimeInterval { get }
    var itemSpacing: CGFloat { get }
    var isItemSpacingAverageEnabled: Bool { get }

    func reloadData(selectedIndex: Int)

    
    
    
    
    func itemDataSource(in segmentedView: JXSegmentedView) -> [JXSegmentedBaseItemModel]

    
    
    
    
    
    
    func segmentedView(_ segmentedView: JXSegmentedView, widthForItemAt index: Int) -> CGFloat

    
    
    
    
    func segmentedView(_ segmentedView: JXSegmentedView, widthForItemContentAt index: Int) -> CGFloat

    
    
    
    func registerCellClass(in segmentedView: JXSegmentedView)

    
    
    
    
    
    
    func segmentedView(_ segmentedView: JXSegmentedView, cellForItemAt index: Int) -> JXSegmentedBaseCell

    
    
    
    
    
    
    func refreshItemModel(_ segmentedView: JXSegmentedView, _ itemModel: JXSegmentedBaseItemModel, at index: Int, selectedIndex: Int)

    
    
    
    
    
    
    func refreshItemModel(_ segmentedView: JXSegmentedView, currentSelectedItemModel: JXSegmentedBaseItemModel, willSelectedItemModel: JXSegmentedBaseItemModel, selectedType: JXSegmentedViewItemSelectedType)

    
    
    
    
    
    
    func refreshItemModel(_ segmentedView: JXSegmentedView, leftItemModel: JXSegmentedBaseItemModel, rightItemModel: JXSegmentedBaseItemModel, percent: CGFloat)
}


public protocol JXSegmentedViewDelegate: AnyObject {
    
    
    
    
    
    func segmentedView(_ segmentedView: JXSegmentedView, didSelectedItemAt index: Int)

    
    
    
    
    
    func segmentedView(_ segmentedView: JXSegmentedView, didClickSelectedItemAt index: Int)

    
    
    
    
    
    func segmentedView(_ segmentedView: JXSegmentedView, didScrollSelectedItemAt index: Int)

    
    
    
    
    
    
    
    func segmentedView(_ segmentedView: JXSegmentedView, scrollingFrom leftIndex: Int, to rightIndex: Int, percent: CGFloat)


    
    
    
    
    
    func segmentedView(_ segmentedView: JXSegmentedView, canClickItemAt index: Int) -> Bool
}


public extension JXSegmentedViewDelegate {
    func segmentedView(_ segmentedView: JXSegmentedView, didSelectedItemAt index: Int) { }
    func segmentedView(_ segmentedView: JXSegmentedView, didClickSelectedItemAt index: Int) { }
    func segmentedView(_ segmentedView: JXSegmentedView, didScrollSelectedItemAt index: Int) { }
    func segmentedView(_ segmentedView: JXSegmentedView, scrollingFrom leftIndex: Int, to rightIndex: Int, percent: CGFloat) { }
    func segmentedView(_ segmentedView: JXSegmentedView, canClickItemAt index: Int) -> Bool { return true }
}


open class JXSegmentedView: UIView, JXSegmentedViewRTLCompatible {
    open weak var dataSource: JXSegmentedViewDataSource? {
        didSet {
            dataSource?.reloadData(selectedIndex: selectedIndex)
        }
    }
    open weak var delegate: JXSegmentedViewDelegate?
    open private(set) var collectionView: JXSegmentedCollectionView!
    open var contentScrollView: UIScrollView? {
        willSet {
            contentScrollView?.removeObserver(self, forKeyPath: "contentOffset")
        }
        didSet {
            contentScrollView?.scrollsToTop = false
            contentScrollView?.addObserver(self, forKeyPath: "contentOffset", options: .new, context: nil)
        }
    }
    public var listContainer: JXSegmentedViewListContainer? = nil {
        didSet {
            listContainer?.defaultSelectedIndex = defaultSelectedIndex
            contentScrollView = listContainer?.contentScrollView()
        }
    }
    
    open var indicators = [JXSegmentedIndicatorProtocol & UIView]() {
        didSet {
            collectionView.indicators = indicators
        }
    }
    
    open var defaultSelectedIndex: Int = 0 {
        didSet {
            selectedIndex = defaultSelectedIndex
            if listContainer != nil {
                listContainer?.defaultSelectedIndex = defaultSelectedIndex
            }
        }
    }
    open private(set) var selectedIndex: Int = 0
    
    open var contentEdgeInsetLeft: CGFloat = JXSegmentedViewAutomaticDimension
    
    open var contentEdgeInsetRight: CGFloat = JXSegmentedViewAutomaticDimension
    
    open var isContentScrollViewClickTransitionAnimationEnabled: Bool = true

    private var itemDataSource = [JXSegmentedBaseItemModel]()
    private var innerItemSpacing: CGFloat = 0
    private var lastContentOffset: CGPoint = CGPoint.zero
    
    private var scrollingTargetIndex: Int = -1
    private var isFirstLayoutSubviews = true

    deinit {
        contentScrollView?.removeObserver(self, forKeyPath: "contentOffset")
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)

        commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        commonInit()
    }

    private func commonInit() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        collectionView = JXSegmentedCollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.scrollsToTop = false
        collectionView.dataSource = self
        collectionView.delegate = self
        if #available(iOS 10.0, *) {
            collectionView.isPrefetchingEnabled = false
        }
        if #available(iOS 11.0, *) {
            collectionView.contentInsetAdjustmentBehavior = .never
        }
        if segmentedViewShouldRTLLayout() {
            collectionView.semanticContentAttribute = .forceLeftToRight
            segmentedView(horizontalFlipForView: collectionView)
        }
        addSubview(collectionView)
    }

    open override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)

        var nextResponder: UIResponder? = newSuperview
        while nextResponder != nil {
            if let parentVC = nextResponder as? UIViewController  {
                parentVC.automaticallyAdjustsScrollViewInsets = false
                break
            }
            nextResponder = nextResponder?.next
        }
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        
        
        let targetFrame = CGRect(x: 0, y: 0, width: bounds.size.width, height: floor(bounds.size.height))
        if isFirstLayoutSubviews {
            isFirstLayoutSubviews = false
            collectionView.frame = targetFrame
            reloadDataWithoutListContainer()
        }else {
            if collectionView.frame != targetFrame {
                collectionView.frame = targetFrame
                collectionView.collectionViewLayout.invalidateLayout()
                collectionView.reloadData()
            }
        }
    }

    
    public final func dequeueReusableCell(withReuseIdentifier identifier: String, at index: Int) -> JXSegmentedBaseCell {
        let indexPath = IndexPath(item: index, section: 0)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)
        guard cell.isKind(of: JXSegmentedBaseCell.self) else {
            fatalError("Cell class must be subclass of JXSegmentedBaseCell")
        }
        return cell as! JXSegmentedBaseCell
    }

    open func reloadData() {
        reloadDataWithoutListContainer()
        listContainer?.reloadData()
    }

    open func reloadDataWithoutListContainer() {
        dataSource?.reloadData(selectedIndex: selectedIndex)
        dataSource?.registerCellClass(in: self)
        if let itemSource = dataSource?.itemDataSource(in: self) {
            itemDataSource = itemSource
        }
        if selectedIndex < 0 || selectedIndex >= itemDataSource.count {
            defaultSelectedIndex = 0
            selectedIndex = 0
        }

        innerItemSpacing = dataSource?.itemSpacing ?? 0
        var totalItemWidth: CGFloat = 0
        var totalContentWidth: CGFloat = getContentEdgeInsetLeft()
        for (index, itemModel) in itemDataSource.enumerated() {
            itemModel.index = index
            itemModel.itemWidth = (dataSource?.segmentedView(self, widthForItemAt: index) ?? 0)
            if dataSource?.isItemWidthZoomEnabled == true {
                itemModel.itemWidth *= itemModel.itemWidthCurrentZoomScale
            }
            itemModel.isSelected = (index == selectedIndex)
            totalItemWidth += itemModel.itemWidth
            if index == itemDataSource.count - 1 {
                totalContentWidth += itemModel.itemWidth + getContentEdgeInsetRight()
            }else {
                totalContentWidth += itemModel.itemWidth + innerItemSpacing
            }
        }

        if dataSource?.isItemSpacingAverageEnabled == true && totalContentWidth < bounds.size.width {
            var itemSpacingCount = itemDataSource.count - 1
            var totalItemSpacingWidth = bounds.size.width - totalItemWidth
            if contentEdgeInsetLeft == JXSegmentedViewAutomaticDimension {
                itemSpacingCount += 1
            }else {
                totalItemSpacingWidth -= contentEdgeInsetLeft
            }
            if contentEdgeInsetRight == JXSegmentedViewAutomaticDimension {
                itemSpacingCount += 1
            }else {
                totalItemSpacingWidth -= contentEdgeInsetRight
            }
            if itemSpacingCount > 0 {
                innerItemSpacing = totalItemSpacingWidth / CGFloat(itemSpacingCount)
            }
        }

        var selectedItemFrameX = innerItemSpacing
        var selectedItemWidth: CGFloat = 0
        totalContentWidth = getContentEdgeInsetLeft()
        for (index, itemModel) in itemDataSource.enumerated() {
            if index < selectedIndex {
                selectedItemFrameX += itemModel.itemWidth + innerItemSpacing
            }else if index == selectedIndex {
                selectedItemWidth = itemModel.itemWidth
            }
            if index == itemDataSource.count - 1 {
                totalContentWidth += itemModel.itemWidth + getContentEdgeInsetRight()
            }else {
                totalContentWidth += itemModel.itemWidth + innerItemSpacing
            }
        }

        let minX: CGFloat = 0
        let maxX = totalContentWidth - bounds.size.width
        let targetX = selectedItemFrameX - bounds.size.width/2 + selectedItemWidth/2
        collectionView.setContentOffset(CGPoint(x: max(min(maxX, targetX), minX), y: 0), animated: false)

        if contentScrollView != nil {
            if contentScrollView!.frame.equalTo(CGRect.zero) &&
                contentScrollView!.superview != nil {
                
                
                var parentView = contentScrollView?.superview
                while parentView != nil && parentView?.frame.equalTo(CGRect.zero) == true {
                    parentView = parentView?.superview
                }
                parentView?.setNeedsLayout()
                parentView?.layoutIfNeeded()
            }

            contentScrollView!.setContentOffset(CGPoint(x: CGFloat(selectedIndex) * contentScrollView!.bounds.size.width
                , y: 0), animated: false)
        }

        for indicator in indicators {
            if itemDataSource.isEmpty {
                indicator.isHidden = true
            }else {
                indicator.isHidden = false
                let selectedItemFrame = getItemFrameAt(index: selectedIndex)
                let indicatorParams = JXSegmentedIndicatorSelectedParams(currentSelectedIndex: selectedIndex,
                                                                         currentSelectedItemFrame: selectedItemFrame,
                                                                         selectedType: .unknown,
                                                                         currentItemContentWidth: dataSource?.segmentedView(self, widthForItemContentAt: selectedIndex) ?? 0,
                                                                         collectionViewContentSize: CGSize(width: totalContentWidth, height: bounds.size.height))
                indicator.refreshIndicatorState(model: indicatorParams)

                if indicator.isIndicatorConvertToItemFrameEnabled {
                    var indicatorConvertToItemFrame = indicator.frame
                    indicatorConvertToItemFrame.origin.x -= selectedItemFrame.origin.x
                    itemDataSource[selectedIndex].indicatorConvertToItemFrame = indicatorConvertToItemFrame
                }
            }
        }
        collectionView.reloadData()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    open func reloadItem(at index: Int) {
        guard index >= 0 && index < itemDataSource.count else {
            return
        }

        dataSource?.refreshItemModel(self, itemDataSource[index], at: index, selectedIndex: selectedIndex)
        let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? JXSegmentedBaseCell
        cell?.reloadData(itemModel: itemDataSource[index], selectedType: .unknown)
    }


    
    
    
    
    open func selectItemAt(index: Int) {
        selectItemAt(index: index, selectedType: .code)
    }

    
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "contentOffset" {
            let contentOffset = change?[NSKeyValueChangeKey.newKey] as! CGPoint
            if contentScrollView?.isTracking == true || contentScrollView?.isDecelerating == true {
                
                if contentScrollView?.bounds.size.width == 0 {
                    
                    return
                }
                var progress = contentOffset.x/contentScrollView!.bounds.size.width
                if Int(progress) > itemDataSource.count - 1 || progress < 0 {
                    
                    return
                }
                if contentOffset.x == 0 && selectedIndex == 0 && lastContentOffset.x == 0 {
                    
                    return
                }
                let maxContentOffsetX = contentScrollView!.contentSize.width - contentScrollView!.bounds.size.width
                if contentOffset.x == maxContentOffsetX && selectedIndex == itemDataSource.count - 1 && lastContentOffset.x == maxContentOffsetX {
                    
                    return
                }

                progress = max(0, min(CGFloat(itemDataSource.count - 1), progress))
                let baseIndex = Int(floor(progress))
                let remainderProgress = progress - CGFloat(baseIndex)

                let leftItemFrame = getItemFrameAt(index: baseIndex)
                let rightItemFrame = getItemFrameAt(index: baseIndex + 1)
                var rightItemContentWidth: CGFloat = 0
                if baseIndex + 1 < itemDataSource.count {
                    rightItemContentWidth = dataSource?.segmentedView(self, widthForItemContentAt: baseIndex + 1) ?? 0
                }
                let indicatorParams = JXSegmentedIndicatorTransitionParams(currentSelectedIndex: selectedIndex,
                                                                           leftIndex: baseIndex,
                                                                           leftItemFrame: leftItemFrame,
                                                                           leftItemContentWidth: dataSource?.segmentedView(self, widthForItemContentAt: baseIndex) ?? 0,
                                                                           rightIndex: baseIndex + 1,
                                                                           rightItemFrame: rightItemFrame,
                                                                           rightItemContentWidth: rightItemContentWidth,
                                                                           percent: remainderProgress)

                if remainderProgress == 0 {
                    
                    
                    if !(lastContentOffset.x == contentOffset.x && selectedIndex == baseIndex) {
                        scrollSelectItemAt(index: baseIndex)
                    }
                }else {
                    
                    if abs(progress - CGFloat(selectedIndex)) > 1 {
                        var targetIndex = baseIndex
                        if progress < CGFloat(selectedIndex) {
                            targetIndex = baseIndex + 1
                        }
                        scrollSelectItemAt(index: targetIndex)
                    }
                    if selectedIndex == baseIndex {
                        scrollingTargetIndex = baseIndex + 1
                    }else {
                        scrollingTargetIndex = baseIndex
                    }

                    dataSource?.refreshItemModel(self, leftItemModel: itemDataSource[baseIndex], rightItemModel: itemDataSource[baseIndex + 1], percent: remainderProgress)

                    for indicator in indicators {
                        indicator.contentScrollViewDidScroll(model: indicatorParams)
                        if indicator.isIndicatorConvertToItemFrameEnabled {
                            var leftIndicatorConvertToItemFrame = indicator.frame
                            leftIndicatorConvertToItemFrame.origin.x -= leftItemFrame.origin.x
                            itemDataSource[baseIndex].indicatorConvertToItemFrame = leftIndicatorConvertToItemFrame

                            var rightIndicatorConvertToItemFrame = indicator.frame
                            rightIndicatorConvertToItemFrame.origin.x -= rightItemFrame.origin.x
                            itemDataSource[baseIndex + 1].indicatorConvertToItemFrame = rightIndicatorConvertToItemFrame
                        }
                    }

                    let leftCell = collectionView.cellForItem(at: IndexPath(item: baseIndex, section: 0)) as? JXSegmentedBaseCell
                    leftCell?.reloadData(itemModel: itemDataSource[baseIndex], selectedType: .unknown)

                    let rightCell = collectionView.cellForItem(at: IndexPath(item: baseIndex + 1, section: 0)) as? JXSegmentedBaseCell
                    rightCell?.reloadData(itemModel: itemDataSource[baseIndex + 1], selectedType: .unknown)

                    delegate?.segmentedView(self, scrollingFrom: baseIndex, to: baseIndex + 1, percent: remainderProgress)
                }
            }
            lastContentOffset = contentOffset
        }
    }

    
    private func clickSelectItemAt(index: Int) {
        guard delegate?.segmentedView(self, canClickItemAt: index) != false else {
            return
        }
        selectItemAt(index: index, selectedType: .click)
    }

    private func scrollSelectItemAt(index: Int) {
        selectItemAt(index: index, selectedType: .scroll)
    }

    private func selectItemAt(index: Int, selectedType: JXSegmentedViewItemSelectedType) {
        guard index >= 0 && index < itemDataSource.count else {
            return
        }

        if index == selectedIndex {
            if selectedType == .code {
                listContainer?.didClickSelectedItem(at: index)
            }else if selectedType == .click {
                delegate?.segmentedView(self, didClickSelectedItemAt: index)
                listContainer?.didClickSelectedItem(at: index)
            }else if selectedType == .scroll {
                delegate?.segmentedView(self, didScrollSelectedItemAt: index)
            }
            delegate?.segmentedView(self, didSelectedItemAt: index)
            scrollingTargetIndex = -1
            return
        }

        let currentSelectedItemModel = itemDataSource[selectedIndex]
        let willSelectedItemModel = itemDataSource[index]
        dataSource?.refreshItemModel(self, currentSelectedItemModel: currentSelectedItemModel, willSelectedItemModel: willSelectedItemModel, selectedType: selectedType)

        let currentSelectedCell = collectionView.cellForItem(at: IndexPath(item: selectedIndex, section: 0)) as? JXSegmentedBaseCell
        currentSelectedCell?.reloadData(itemModel: currentSelectedItemModel, selectedType: selectedType)

        let willSelectedCell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? JXSegmentedBaseCell
        willSelectedCell?.reloadData(itemModel: willSelectedItemModel, selectedType: selectedType)

        if scrollingTargetIndex != -1 && scrollingTargetIndex != index {
            let scrollingTargetItemModel = itemDataSource[scrollingTargetIndex]
            scrollingTargetItemModel.isSelected = false
            dataSource?.refreshItemModel(self, currentSelectedItemModel: scrollingTargetItemModel, willSelectedItemModel: willSelectedItemModel, selectedType: selectedType)
            let scrollingTargetCell = collectionView.cellForItem(at: IndexPath(item: scrollingTargetIndex, section: 0)) as? JXSegmentedBaseCell
            scrollingTargetCell?.reloadData(itemModel: scrollingTargetItemModel, selectedType: selectedType)
        }

        if dataSource?.isItemWidthZoomEnabled == true {
            if selectedType == .click || selectedType == .code {
                
                let selectedAnimationDurationInMilliseconds = Int((dataSource?.selectedAnimationDuration ?? 0)*1000)
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.milliseconds(selectedAnimationDurationInMilliseconds)) {
                    self.collectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: .centeredHorizontally, animated: true)
                }
            }else if selectedType == .scroll {
                
                collectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: .centeredHorizontally, animated: true)
            }
        }else {
            collectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: .centeredHorizontally, animated: true)
        }

        if contentScrollView != nil && (selectedType == .click || selectedType == .code) {
            contentScrollView!.setContentOffset(CGPoint(x: contentScrollView!.bounds.size.width*CGFloat(index), y: 0), animated: isContentScrollViewClickTransitionAnimationEnabled)
        }

        selectedIndex = index

        let currentSelectedItemFrame = getSelectedItemFrameAt(index: selectedIndex)
        for indicator in indicators {
            let indicatorParams = JXSegmentedIndicatorSelectedParams(currentSelectedIndex: selectedIndex,
                                                                     currentSelectedItemFrame: currentSelectedItemFrame,
                                                                     selectedType: selectedType,
                                                                     currentItemContentWidth: dataSource?.segmentedView(self, widthForItemContentAt: selectedIndex) ?? 0,
                                                                     collectionViewContentSize: nil)
            indicator.selectItem(model: indicatorParams)

            if indicator.isIndicatorConvertToItemFrameEnabled {
                var indicatorConvertToItemFrame = indicator.frame
                indicatorConvertToItemFrame.origin.x -= currentSelectedItemFrame.origin.x
                itemDataSource[selectedIndex].indicatorConvertToItemFrame = indicatorConvertToItemFrame
                willSelectedCell?.reloadData(itemModel: willSelectedItemModel, selectedType: selectedType)
            }
        }

        scrollingTargetIndex = -1
        if selectedType == .code {
            listContainer?.didClickSelectedItem(at: index)
        }else if selectedType == .click {
            delegate?.segmentedView(self, didClickSelectedItemAt: index)
            listContainer?.didClickSelectedItem(at: index)
        }else if selectedType == .scroll {
            delegate?.segmentedView(self, didScrollSelectedItemAt: index)
        }
        delegate?.segmentedView(self, didSelectedItemAt: index)
    }

    private func getItemFrameAt(index: Int) -> CGRect {
        guard index < itemDataSource.count else {
            return CGRect.zero
        }
        var x = getContentEdgeInsetLeft()
        for i in 0..<index {
            let itemModel = itemDataSource[i]
            var itemWidth: CGFloat = 0
            if itemModel.isTransitionAnimating && itemModel.isItemWidthZoomEnabled {
                
                if itemModel.isSelected {
                    itemWidth = (dataSource?.segmentedView(self, widthForItemAt: itemModel.index) ?? 0) * itemModel.itemWidthSelectedZoomScale
                }else {
                    itemWidth = (dataSource?.segmentedView(self, widthForItemAt: itemModel.index) ?? 0) * itemModel.itemWidthNormalZoomScale
                }
            }else {
                itemWidth = itemModel.itemWidth
            }
            x += itemWidth + innerItemSpacing
        }
        var width: CGFloat = 0
        let selectedItemModel = itemDataSource[index]
        if selectedItemModel.isTransitionAnimating && selectedItemModel.isItemWidthZoomEnabled {
            width = (dataSource?.segmentedView(self, widthForItemAt: selectedItemModel.index) ?? 0) * selectedItemModel.itemWidthSelectedZoomScale
        }else {
            width = selectedItemModel.itemWidth
        }
        return CGRect(x: x, y: 0, width: width, height: bounds.size.height)
    }

    private func getSelectedItemFrameAt(index: Int) -> CGRect {
        guard index < itemDataSource.count else {
            return CGRect.zero
        }
        var x = getContentEdgeInsetLeft()
        for i in 0..<index {
            let itemWidth = (dataSource?.segmentedView(self, widthForItemAt: i) ?? 0)
            x += itemWidth + innerItemSpacing
        }
        var width: CGFloat = 0
        let selectedItemModel = itemDataSource[index]
        if selectedItemModel.isItemWidthZoomEnabled {
            width = (dataSource?.segmentedView(self, widthForItemAt: selectedItemModel.index) ?? 0) * selectedItemModel.itemWidthSelectedZoomScale
        }else {
            width = selectedItemModel.itemWidth
        }
        return CGRect(x: x, y: 0, width: width, height: bounds.size.height)
    }

    private func getContentEdgeInsetLeft() -> CGFloat {
        if contentEdgeInsetLeft == JXSegmentedViewAutomaticDimension {
            return innerItemSpacing
        }else {
            return contentEdgeInsetLeft
        }
    }

    private func getContentEdgeInsetRight() -> CGFloat {
        if contentEdgeInsetRight == JXSegmentedViewAutomaticDimension {
            return innerItemSpacing
        }else {
            return contentEdgeInsetRight
        }
    }
}

extension JXSegmentedView: UICollectionViewDataSource {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return itemDataSource.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = dataSource?.segmentedView(self, cellForItemAt: indexPath.item) {
            cell.reloadData(itemModel: itemDataSource[indexPath.item], selectedType: .unknown)
            return cell
        }else {
            return UICollectionViewCell(frame: CGRect.zero)
        }
    }
}

extension JXSegmentedView: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        var isTransitionAnimating = false
        for itemModel in itemDataSource {
            if itemModel.isTransitionAnimating {
                isTransitionAnimating = true
                break
            }
        }
        if !isTransitionAnimating {
            
            clickSelectItemAt(index: indexPath.item)
        }
    }
}

extension JXSegmentedView: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: getContentEdgeInsetLeft(), bottom: 0, right: getContentEdgeInsetRight())
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: itemDataSource[indexPath.item].itemWidth, height: collectionView.bounds.size.height)
    }
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return innerItemSpacing
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return innerItemSpacing
    }
}
