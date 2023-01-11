






import UIKit


public final class SwiftEntryKit {
    
    
    public enum EntryDismissalDescriptor {
        
        
        case specific(entryName: String)
        
        
        case prioritizedLowerOrEqualTo(priority: EKAttributes.Precedence.Priority)
        
        
        case enqueued
        
        
        case all
        
        
        case displayed
    }
    
    
    public enum RollbackWindow {
        
        
        case main
        
        
        case custom(window: UIWindow)
    }
    
    
    public typealias DismissCompletionHandler = () -> Void
    
    
    private init() {}
    
    
    public class var window: UIWindow? {
        return EKWindowProvider.shared.entryWindow
    }
    
    
    public class var isCurrentlyDisplaying: Bool {
        return isCurrentlyDisplaying()
    }
    
    
    public class func isCurrentlyDisplaying(entryNamed name: String? = nil) -> Bool {
        return EKWindowProvider.shared.isCurrentlyDisplaying(entryNamed: name)
    }
    
    
    public class var isQueueEmpty: Bool {
        return !queueContains()
    }
    
    
    public class func queueContains(entryNamed name: String? = nil) -> Bool {
        return EKWindowProvider.shared.queueContains(entryNamed: name)
    }
    
    
    public class func display(entry view: UIView, using attributes: EKAttributes, presentInsideKeyWindow: Bool = false, rollbackWindow: RollbackWindow = .main) {
        DispatchQueue.main.async {
            EKWindowProvider.shared.display(view: view, using: attributes, presentInsideKeyWindow: presentInsideKeyWindow, rollbackWindow: rollbackWindow)
        }
    }
    
    
    public class func display(entry viewController: UIViewController, using attributes: EKAttributes, presentInsideKeyWindow: Bool = false, rollbackWindow: RollbackWindow = .main) {
        DispatchQueue.main.async {
            EKWindowProvider.shared.display(viewController: viewController, using: attributes, presentInsideKeyWindow: presentInsideKeyWindow, rollbackWindow: rollbackWindow)
        }
    }
    
    
    public class func transform(to view: UIView) {
        DispatchQueue.main.async {
            EKWindowProvider.shared.transform(to: view)
        }
    }
    
    
    public class func dismiss(_ descriptor: EntryDismissalDescriptor = .displayed, with completion: DismissCompletionHandler? = nil) {
        DispatchQueue.main.async {
            EKWindowProvider.shared.dismiss(descriptor, with: completion)
        }
    }
    
    
    public class func layoutIfNeeded() {
        if Thread.isMainThread {
            EKWindowProvider.shared.layoutIfNeeded()
        } else {
            DispatchQueue.main.async {
                EKWindowProvider.shared.layoutIfNeeded()
            }
        }
    }
}
