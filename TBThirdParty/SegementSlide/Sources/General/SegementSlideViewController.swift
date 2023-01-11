







import UIKit

public enum BouncesType {
    case parent
    case child
}

open class SegementSlideViewController: UIViewController {
    
    public internal(set) var scrollView: SegementSlideScrollView!
    public internal(set) var headerView: SegementSlideHeaderView!
    public internal(set) var contentView: SegementSlideContentView!
    public internal(set) var switcherView: SegementSlideSwitcherDelegate!
    internal var innerHeaderView: UIView?
    
    internal var safeAreaTopConstraint: NSLayoutConstraint?
    internal var parentKeyValueObservation: NSKeyValueObservation?
    internal var childKeyValueObservations: [String: NSKeyValueObservation] = [:]
    internal var innerBouncesType: BouncesType = .parent
    internal var canParentViewScroll: Bool = true
    internal var canChildViewScroll: Bool = false
    internal var lastChildBouncesTranslationY: CGFloat = 0
    internal var cachedChildViewControllerIndex: Set<Int> = Set()
    
    public var headerStickyHeight: CGFloat {
        let headerHeight = headerView.frame.height.rounded(.up)
        var ret = headerHeight
        if edgesForExtendedLayout.contains(.top) {
            ret -= topLayoutLength
        }
        
        if headerHeight >= self.headerStickyHeightOffset {
            ret -= self.headerStickyHeightOffset
        }
        return ret
    }
    
    open var headerStickyHeightOffset: CGFloat {
        return 0
    }
    public var switcherHeight: CGFloat {
        return switcherView.ssDataSource?.height ?? 44
    }
    public var contentViewHeight: CGFloat {
        return view.bounds.height-topLayoutLength-switcherHeight
    }
    public var currentIndex: Int? {
        return switcherView.ssSelectedIndex
    }
    public var currentSegementSlideContentViewController: SegementSlideContentScrollViewDelegate? {
        guard let currentIndex = currentIndex else {
            return nil
        }
        return contentView.dequeueReusableViewController(at: currentIndex)
    }
    
    
    open var defaultSelectedIndex: Int? {
        didSet {
            switcherView.ssDefaultSelectedIndex = defaultSelectedIndex
            contentView.defaultSelectedIndex = defaultSelectedIndex
        }
    }
    
    open var bouncesType: BouncesType {
        return .parent
    }
    
    open func segementSlideHeaderView() -> UIView? {
        if edgesForExtendedLayout.contains(.top) {
            #if DEBUG
            assert(false, "must override this variable")
            #endif
            return nil
        } else {
            return nil
        }
    }
    
    open func segementSlideSwitcherView() -> SegementSlideSwitcherDelegate {
        #if DEBUG
        assert(false, "must override this variable")
        #endif
        return SegementSlideSwitcherEmptyView()
    }
    
    open func segementSlideContentViewController(at index: Int) -> SegementSlideContentScrollViewDelegate? {
        #if DEBUG
        assert(false, "must override this function")
        #endif
        return nil
    }
    
    open func scrollViewDidScroll(_ scrollView: UIScrollView, isParent: Bool) {
        
    }
    
    open func didSelectContentViewController(at index: Int) {
        
    }
    
    open func setupHeader() {
        innerHeaderView = segementSlideHeaderView()
    }
    
    open func setupSwitcher() {

    }
    
    open func setupContent() {
        cachedChildViewControllerIndex.removeAll()
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutSegementSlideScrollView()
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    
    
    
    
    
    public func reloadData() {
        setupBounces()
        setupHeader()
        setupSwitcher()
        setupContent()
        contentView.reloadData()
        switcherView.reloadData()
        layoutSegementSlideScrollView()
    }
    
    
    public func reloadHeader() {
        setupHeader()
        layoutSegementSlideScrollView()
    }
    
    
    public func reloadSwitcher() {
        setupSwitcher()
        switcherView.reloadData()
        layoutSegementSlideScrollView()
    }
    
    
    public func reloadContent() {
        setupContent()
        contentView.reloadData()
    }
    
    
    public func selectItem(at index: Int, animated: Bool) {
        switcherView.selectItem(at: index, animated: animated)
    }
    
    
    public func dequeueReusableViewController(at index: Int) -> SegementSlideContentScrollViewDelegate? {
        return contentView.dequeueReusableViewController(at: index)
    }
    
    deinit {
        parentKeyValueObservation?.invalidate()
        cleanUpChildKeyValueObservations()
        NotificationCenter.default.removeObserver(self, name: SegementSlideContentView.willCleanUpAllReusableViewControllersNotification, object: nil)
        #if DEBUG
        debugPrint("\(type(of: self)) deinit")
        #endif
    }
    
}
