







import Foundation

public extension EKAttributes {
    
    
    struct UserInteraction {
        
        
        public typealias Action = () -> ()
        
        
        public enum Default {
            
            
            case absorbTouches
            
            
            case delayExit(by: TimeInterval)
            
            
            case dismissEntry
            
            
            case forward
        }
        
        var isResponsive: Bool {
            switch defaultAction {
            case .forward:
                return false
            default:
                return true
            }
        }
        
        var isDelayExit: Bool {
            switch defaultAction {
            case .delayExit:
                return true
            default:
                return false
            }
        }
        
        
        public var defaultAction: Default
        
        
        public var customTapActions: [Action]
        
        public init(defaultAction: Default = .absorbTouches, customTapActions: [Action] = []) {
            self.defaultAction = defaultAction
            self.customTapActions = customTapActions
        }
        
        
        public static var dismiss: UserInteraction {
            return UserInteraction(defaultAction: .dismissEntry)
        }
        
        
        public static var forward: UserInteraction {
            return UserInteraction(defaultAction: .forward)
        }
        
        
        public static var absorbTouches: UserInteraction {
            return UserInteraction(defaultAction: .absorbTouches)
        }
        
        
        public static func delayExit(by delay: TimeInterval) -> UserInteraction {
            return UserInteraction(defaultAction: .delayExit(by: delay))
        }
    }
}
