







import UIKit

final class EKWindowProvider: EntryPresenterDelegate {
    
    
    static var safeAreaInsets: UIEdgeInsets {
        if #available(iOS 11.0, *) {
            return EKWindowProvider.shared.entryWindow?.rootViewController?.view?.safeAreaInsets ?? UIApplication.shared.keyWindow?.rootViewController?.view.safeAreaInsets ?? .zero
        } else {
            let statusBarMaxY = UIApplication.shared.statusBarFrame.maxY
            return UIEdgeInsets(top: statusBarMaxY, left: 0, bottom: 10, right: 0)
        }
    }
    
    
    static let shared = EKWindowProvider()
    
    
    var entryWindow: EKWindow!
    
    
    var rootVC: EKRootViewController? {
        return entryWindow?.rootViewController as? EKRootViewController
    }
    
    
    private var rollbackWindow: SwiftEntryKit.RollbackWindow!
    
    
    private weak var mainRollbackWindow: UIWindow?

    
    private let entryQueue = EKAttributes.Precedence.QueueingHeuristic.value.heuristic
    
    private weak var entryView: EKEntryView!

    
    private init() {}
    
    var isResponsiveToTouches: Bool {
        set {
            entryWindow.isAbleToReceiveTouches = newValue
        }
        get {
            return entryWindow.isAbleToReceiveTouches
        }
    }
    
    
    
    
    private func prepare(for attributes: EKAttributes, presentInsideKeyWindow: Bool) -> EKRootViewController? {
        let entryVC = setupWindowAndRootVC()
        guard entryVC.canDisplay(attributes: attributes) || attributes.precedence.isEnqueue else {
            return nil
        }
        entryVC.setStatusBarStyle(for: attributes)

        entryWindow.windowLevel = attributes.windowLevel.value
        if presentInsideKeyWindow {
            entryWindow.makeKeyAndVisible()
        } else {
            entryWindow.isHidden = false
        }

        return entryVC
    }
    
    
    private func setupWindowAndRootVC() -> EKRootViewController {
        let entryVC: EKRootViewController
        if entryWindow == nil {
            entryVC = EKRootViewController(with: self)
            entryWindow = EKWindow(with: entryVC)
            mainRollbackWindow = UIApplication.shared.keyWindow
        } else {
            entryVC = rootVC!
        }
        return entryVC
    }
    
    
    private func display(entryView: EKEntryView, using attributes: EKAttributes, presentInsideKeyWindow: Bool, rollbackWindow: SwiftEntryKit.RollbackWindow) {
        switch entryView.attributes.precedence {
        case .override(priority: _, dropEnqueuedEntries: let dropEnqueuedEntries):
            if dropEnqueuedEntries {
                entryQueue.removeAll()
            }
            show(entryView: entryView, presentInsideKeyWindow: presentInsideKeyWindow, rollbackWindow: rollbackWindow)
        case .enqueue where isCurrentlyDisplaying():
            entryQueue.enqueue(entry: .init(view: entryView, presentInsideKeyWindow: presentInsideKeyWindow, rollbackWindow: rollbackWindow))
        case .enqueue:
            show(entryView: entryView, presentInsideKeyWindow: presentInsideKeyWindow, rollbackWindow: rollbackWindow)
        }
    }
    
    
    
    func queueContains(entryNamed name: String? = nil) -> Bool {
        if name == nil && !entryQueue.isEmpty {
            return true
        }
        if let name = name {
            return entryQueue.contains(entryNamed: name)
        } else {
            return false
        }
    }
    
    
    func isCurrentlyDisplaying(entryNamed name: String? = nil) -> Bool {
        guard let entryView = entryView else {
            return false
        }
        if let name = name { 
            return entryView.content.attributes.name == name
        } else { 
            return true
        }
    }
    
    
    func transform(to view: UIView) {
        entryView?.transform(to: view)
    }
    
    
    func display(view: UIView, using attributes: EKAttributes, presentInsideKeyWindow: Bool, rollbackWindow: SwiftEntryKit.RollbackWindow) {
        let entryView = EKEntryView(newEntry: .init(view: view, attributes: attributes))
        display(entryView: entryView, using: attributes, presentInsideKeyWindow: presentInsideKeyWindow, rollbackWindow: rollbackWindow)
    }

    
    func display(viewController: UIViewController, using attributes: EKAttributes, presentInsideKeyWindow: Bool, rollbackWindow: SwiftEntryKit.RollbackWindow) {
        let entryView = EKEntryView(newEntry: .init(viewController: viewController, attributes: attributes))
        display(entryView: entryView, using: attributes, presentInsideKeyWindow: presentInsideKeyWindow, rollbackWindow: rollbackWindow)
    }
    
    
    func displayRollbackWindow() {
        if #available(iOS 13.0, *) {
            entryWindow.windowScene = nil
        }
        entryWindow = nil
        entryView = nil
        switch rollbackWindow! {
        case .main:
            if let mainRollbackWindow = mainRollbackWindow {
                mainRollbackWindow.makeKeyAndVisible()
            } else {
                UIApplication.shared.keyWindow?.makeKeyAndVisible()
            }
        case .custom(window: let window):
            window.makeKeyAndVisible()
        }
    }
    
    
    func displayPendingEntryOrRollbackWindow(dismissCompletionHandler: SwiftEntryKit.DismissCompletionHandler?) {
        if let next = entryQueue.dequeue() {
            
            
            dismissCompletionHandler?()
            
            
            show(entryView: next.view, presentInsideKeyWindow: next.presentInsideKeyWindow, rollbackWindow: next.rollbackWindow)
        } else {
            
            
            displayRollbackWindow()
            
            
            dismissCompletionHandler?()
        }
    }
    
    
    func dismiss(_ descriptor: SwiftEntryKit.EntryDismissalDescriptor, with completion: SwiftEntryKit.DismissCompletionHandler? = nil) {
        guard let rootVC = rootVC else {
            return
        }
        
        switch descriptor {
        case .displayed:
            rootVC.animateOutLastEntry(completionHandler: completion)
        case .specific(entryName: let name):
            entryQueue.removeEntries(by: name)
            if entryView?.attributes.name == name {
                rootVC.animateOutLastEntry(completionHandler: completion)
            }
        case .prioritizedLowerOrEqualTo(priority: let priorityThreshold):
            entryQueue.removeEntries(withPriorityLowerOrEqualTo: priorityThreshold)
            if let currentPriority = entryView?.attributes.precedence.priority, currentPriority <= priorityThreshold {
                rootVC.animateOutLastEntry(completionHandler: completion)
            }
        case .enqueued:
            entryQueue.removeAll()
        case .all:
            entryQueue.removeAll()
            rootVC.animateOutLastEntry(completionHandler: completion)
        }
    }
    
    
    func layoutIfNeeded() {
        entryWindow?.layoutIfNeeded()
    }
    
    
    private func show(entryView: EKEntryView, presentInsideKeyWindow: Bool, rollbackWindow: SwiftEntryKit.RollbackWindow) {
        guard let entryVC = prepare(for: entryView.attributes, presentInsideKeyWindow: presentInsideKeyWindow) else {
            return
        }
        entryVC.configure(entryView: entryView)
        self.entryView = entryView
        self.rollbackWindow = rollbackWindow
    }
}
