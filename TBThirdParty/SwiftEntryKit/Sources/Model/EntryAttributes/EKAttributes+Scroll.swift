






import Foundation
import CoreGraphics

public extension EKAttributes {
    
    
    enum Scroll {
    
        
        public struct PullbackAnimation {
            public var duration: TimeInterval
            public var damping: CGFloat
            public var initialSpringVelocity: CGFloat
            
            public init(duration: TimeInterval, damping: CGFloat, initialSpringVelocity: CGFloat) {
                self.duration = duration
                self.damping = damping
                self.initialSpringVelocity = initialSpringVelocity
            }
            
            
            public static var jolt: PullbackAnimation {
                return PullbackAnimation(duration: 0.5, damping: 0.3, initialSpringVelocity: 10)
            }
            
            
            public static var easeOut: PullbackAnimation {
                return PullbackAnimation(duration: 0.3, damping: 1, initialSpringVelocity: 10)
            }
        }
        
        
        case disabled
        
        
        case edgeCrossingDisabled(swipeable: Bool)
        
        
        case enabled(swipeable: Bool, pullbackAnimation: PullbackAnimation)
        
        var isEnabled: Bool {
            switch self {
            case .disabled:
                return false
            default:
                return true
            }
        }
        
        var isSwipeable: Bool {
            switch self {
            case .edgeCrossingDisabled(swipeable: let swipeable), .enabled(swipeable: let swipeable, pullbackAnimation: _):
                return swipeable
            default:
                return false
            }
        }
        
        var isEdgeCrossingEnabled: Bool {
            switch self {
            case .edgeCrossingDisabled:
                return false
            default:
                return true
            }
        }
    }
}
