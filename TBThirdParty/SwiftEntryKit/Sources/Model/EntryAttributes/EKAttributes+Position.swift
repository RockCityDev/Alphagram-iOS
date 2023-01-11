







import Foundation

public extension EKAttributes {

    
    enum Position {
        
        
        case top
        
        
        case bottom
        
        
        case center
        
        public var isTop: Bool {
            return self == .top
        }
        
        public var isCenter: Bool {
            return self == .center
        }
        
        public var isBottom: Bool {
            return self == .bottom
        }
    }
}
