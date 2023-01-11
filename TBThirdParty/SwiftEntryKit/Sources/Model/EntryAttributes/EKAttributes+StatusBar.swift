







import UIKit

public extension EKAttributes {
    
    
    enum StatusBar {
        
        
        public typealias Appearance = (visible: Bool, style: UIStatusBarStyle)
        
        
        case ignored
        
        
        case hidden
        
        
        case dark
        
        
        case light
        
        
        case inferred
        
        
        public var appearance: Appearance {
            switch self {
            case .dark:
                if #available(iOS 13, *) {
                    return (true, .darkContent)
                } else {
                    return (true, .default)
                }
            case .light:
                return (true, .lightContent)
            case .inferred:
                return StatusBar.currentAppearance
            case .hidden:
                return (false, StatusBar.currentStyle)
            case .ignored:
                fatalError("There is no defined appearance for an ignored status bar")
            }
        }
        
        
        public static func statusBar(by appearance: Appearance) -> StatusBar {
            guard appearance.visible else {
                return .hidden
            }
            switch appearance.style {
            case .lightContent:
                return .light
            default:
                return .dark
            }
        }
        
        
        public static var currentAppearance: Appearance {
            return (StatusBar.isCurrentVisible, StatusBar.currentStyle)
        }
        
        
        public static var currentStatusBar: StatusBar {
            return statusBar(by: currentAppearance)
        }
        
        
        
        private static var currentStyle: UIStatusBarStyle {
            return UIApplication.shared.statusBarStyle
        }
        
        
        private static var isCurrentVisible: Bool {
            return !UIApplication.shared.isStatusBarHidden
        }
    }
}
