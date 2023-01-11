






import UIKit

public extension EKAttributes {
    
    
    enum NotificationHapticFeedback {
        case success
        case warning
        case error
        case none
        
        @available(iOS 10.0, *)
        var value: UINotificationFeedbackGenerator.FeedbackType? {
            switch self {
            case .success:
                return .success
            case .warning:
                return .warning
            case .error:
                return .error
            case .none:
                return nil
            }
        }
        
        var isValid: Bool {
            return self != .none
        }
    }
}
