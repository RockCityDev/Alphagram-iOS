







import UIKit

public extension EKAttributes {
    
    
    enum WindowLevel {
        
        
        case alerts
        
        
        case statusBar
        
        
        case normal
        
        
        case custom(level: UIWindow.Level)
        
        
        public var value: UIWindow.Level {
            switch self {
            case .alerts:
                return .alert
            case .statusBar:
                return .statusBar
            case .normal:
                return .normal
            case .custom(level: let level):
                return level
            }
        }
    }
}
