







import Foundation

public extension EKAttributes {

    
    struct LifecycleEvents {
        
        public typealias Event = () -> Void

        
        public var willAppear: Event?
        
        
        public var didAppear: Event?

        
        public var willDisappear: Event?
        
        
        public var didDisappear: Event?
        
        public init(willAppear: Event? = nil, didAppear: Event? = nil, willDisappear: Event? = nil, didDisappear: Event? = nil) {
            self.willAppear = willAppear
            self.didAppear = didAppear
            self.willDisappear = willDisappear
            self.didDisappear = didDisappear
        }
    }
}
