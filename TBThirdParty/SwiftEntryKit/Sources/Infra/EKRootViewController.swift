







import UIKit

protocol EntryPresenterDelegate: AnyObject {
    var isResponsiveToTouches: Bool { set get }
    func displayPendingEntryOrRollbackWindow(dismissCompletionHandler: SwiftEntryKit.DismissCompletionHandler?)
}

class EKRootViewController: UIViewController {
    
    
    
    private unowned let delegate: EntryPresenterDelegate
    
    private var lastAttributes: EKAttributes!
    
    private let backgroundView = EKBackgroundView()

    private lazy var wrapperView: EKWrapperView = {
        return EKWrapperView()
    }()
    
    
    fileprivate var displayingEntryCount: Int {
        return view.subviews.count - 1
    }
    
    fileprivate var isDisplaying: Bool {
        return lastEntry != nil
    }
    
    private var lastEntry: EKContentView? {
        return view.subviews.last as? EKContentView
    }
        
    private var isResponsive = false {
        didSet {
            wrapperView.isAbleToReceiveTouches = isResponsive
            delegate.isResponsiveToTouches = isResponsive
        }
    }

    override var shouldAutorotate: Bool {
        if lastAttributes == nil {
            return true
        }
        return lastAttributes.positionConstraints.rotation.isEnabled
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        guard let lastAttributes = lastAttributes else {
            return super.supportedInterfaceOrientations
        }
        switch lastAttributes.positionConstraints.rotation.supportedInterfaceOrientations {
        case .standard:
            return super.supportedInterfaceOrientations
        case .all:
            return .all
        }
    }
    
    
    private let previousStatusBar: EKAttributes.StatusBar
    
    private var statusBar: EKAttributes.StatusBar? = nil {
        didSet {
            if let statusBar = statusBar, ![statusBar, oldValue].contains(.ignored) {
                UIApplication.shared.set(statusBarStyle: statusBar)
            }
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if [previousStatusBar, statusBar].contains(.ignored) {
            return super.preferredStatusBarStyle
        }
        return statusBar?.appearance.style ?? previousStatusBar.appearance.style
    }

    override var prefersStatusBarHidden: Bool {
        if [previousStatusBar, statusBar].contains(.ignored) {
            return super.prefersStatusBarHidden
        }
        return !(statusBar?.appearance.visible ?? previousStatusBar.appearance.visible)
    }
    
    
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public init(with delegate: EntryPresenterDelegate) {
        self.delegate = delegate
        previousStatusBar = .currentStatusBar
        super.init(nibName: nil, bundle: nil)
    }
    
    override public func loadView() {
        view = wrapperView
        view.insertSubview(backgroundView, at: 0)
        backgroundView.isUserInteractionEnabled = false
        backgroundView.fillSuperview()
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        statusBar = previousStatusBar
    }
    
    
    func setStatusBarStyle(for attributes: EKAttributes) {
        statusBar = attributes.statusBar
    }
    
    
    
    func configure(entryView: EKEntryView) {

        
        if let viewController = entryView.content.viewController {
            addChild(viewController)
        }
        
        
        let attributes = entryView.attributes
        
        
        let previousAttributes = lastAttributes
        
        
        removeLastEntry(lastAttributes: previousAttributes, keepWindow: true)
        
        lastAttributes = attributes
        
        let entryContentView = EKContentView(withEntryDelegate: self)
        view.addSubview(entryContentView)
        entryContentView.setup(with: entryView)
        
        switch attributes.screenInteraction.defaultAction {
        case .forward:
            isResponsive = false
        default:
            isResponsive = true
        }

        if previousAttributes?.statusBar != attributes.statusBar {
            setNeedsStatusBarAppearanceUpdate()
        }
        
        if shouldAutorotate {
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }
        
    
    func canDisplay(attributes: EKAttributes) -> Bool {
        guard let lastAttributes = lastAttributes else {
            return true
        }
        return attributes.precedence.priority >= lastAttributes.precedence.priority
    }

    
    private func removeLastEntry(lastAttributes: EKAttributes?, keepWindow: Bool) {
        guard let attributes = lastAttributes else {
            return
        }
        if attributes.popBehavior.isOverriden {
            lastEntry?.removePromptly()
        } else {
            popLastEntry()
        }
    }
    
    
    func animateOutLastEntry(completionHandler: SwiftEntryKit.DismissCompletionHandler? = nil) {
        lastEntry?.dismissHandler = completionHandler
        lastEntry?.animateOut(pushOut: false)
    }
    
    
    func popLastEntry() {
        lastEntry?.animateOut(pushOut: true)
    }
}



extension EKRootViewController {
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch lastAttributes.screenInteraction.defaultAction {
        case .dismissEntry:
            lastEntry?.animateOut(pushOut: false)
            fallthrough
        default:
            lastAttributes.screenInteraction.customTapActions.forEach { $0() }
        }
    }
}



extension EKRootViewController: EntryContentViewDelegate {
    
    func didFinishDisplaying(entry: EKEntryView, keepWindowActive: Bool, dismissCompletionHandler: SwiftEntryKit.DismissCompletionHandler?) {
        guard !isDisplaying else {
            return
        }
        
        guard !keepWindowActive else {
            return
        }
        
        delegate.displayPendingEntryOrRollbackWindow(dismissCompletionHandler: dismissCompletionHandler)
    }
    
    func changeToInactive(withAttributes attributes: EKAttributes, pushOut: Bool) {
        guard displayingEntryCount <= 1 else {
            return
        }
        
        let clear = {
            let style = EKBackgroundView.Style(background: .clear, displayMode: attributes.displayMode)
            self.changeBackground(to: style, duration: attributes.exitAnimation.totalDuration)
        }
        
        guard pushOut else {
            clear()
            return
        }
        
        guard let lastBackroundStyle = lastAttributes?.screenBackground else {
            clear()
            return
        }
        
        if lastBackroundStyle != attributes.screenBackground {
            clear()
        }
    }
    
    func changeToActive(withAttributes attributes: EKAttributes) {
        let style = EKBackgroundView.Style(background: attributes.screenBackground,
                                           displayMode: attributes.displayMode)
        changeBackground(to: style, duration: attributes.entranceAnimation.totalDuration)
    }
    
    private func changeBackground(to style: EKBackgroundView.Style, duration: TimeInterval) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: duration, delay: 0, options: [], animations: {
                self.backgroundView.style = style
            }, completion: nil)
        }
    }
}

