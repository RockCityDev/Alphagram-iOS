






import Foundation

public extension EKAttributes {
    
    
    enum PopBehavior {
                
        
        case overridden
        
        
        case animated(animation: Animation)
        
        public var isOverriden: Bool {
            switch self {
            case .overridden:
                return true
            case .animated:
                return false
            }
        }
        
        var animation: Animation? {
            switch self {
            case .animated(animation: let animation):
                return animation
            case .overridden:
                return nil
            }
        }
        
        func validate() {
            #if DEBUG
            guard let animation = animation else { return }
            guard animation == .none else { return }
            print("""
            SwiftEntryKit warning: cannot associate value `EKAttributes.Animation()`
            with `EKAttributes.PopBehavior.animated`. This may result in undefined behavior.
            Please use `PopBehavior.overridden` instead.
            """)
            #endif
        }
    }
}
