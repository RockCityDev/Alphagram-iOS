







import UIKit


protocol EKAnimation {
    var delay: TimeInterval { get set }
    var duration: TimeInterval { get set }
    var spring: EKAttributes.Animation.Spring? { get set }
}


protocol EKRangeAnimation: EKAnimation {
    var start: CGFloat { get set }
    var end: CGFloat { get set }
}

public extension EKAttributes {
    
    
    struct Animation: Equatable {
    
        
        public struct Spring: Equatable {
            
            
            public var damping: CGFloat
            
            
            public var initialVelocity: CGFloat
            
            
            public init(damping: CGFloat, initialVelocity: CGFloat) {
                self.damping = damping
                self.initialVelocity = initialVelocity
            }
        }

        
        public struct RangeAnimation: EKRangeAnimation, Equatable {
            
            
            public var duration: TimeInterval
            
            
            public var delay: TimeInterval
            
            
            public var start: CGFloat
            
            
            public var end: CGFloat
            
            
            public var spring: Spring?
            
            
            public init(from start: CGFloat, to end: CGFloat, duration: TimeInterval, delay: TimeInterval = 0, spring: Spring? = nil) {
                self.start = start
                self.end = end
                self.delay = delay
                self.duration = duration
                self.spring = spring
            }
        }
        
        
        public struct Translate: EKAnimation, Equatable {
            
            
            public enum AnchorPosition: Equatable {
                
                
                case top
                
                
                case bottom
                
                
                case automatic
            }
            
            
            public var duration: TimeInterval
            
            
            public var delay: TimeInterval
            
            
            public var anchorPosition: AnchorPosition
            
            
            public var spring: Spring?

            
            public init(duration: TimeInterval, anchorPosition: AnchorPosition = .automatic, delay: TimeInterval = 0, spring: Spring? = nil) {
                self.anchorPosition = anchorPosition
                self.duration = duration
                self.delay = delay
                self.spring = spring
            }
        }
        
        
        public var translate: Translate?
        
        
        public var scale: RangeAnimation?
        
        
        public var fade: RangeAnimation?
        
        
        public var containsTranslation: Bool {
            return translate != nil
        }
        
        
        public var containsScale: Bool {
            return scale != nil
        }
        
        
        public var containsFade: Bool {
            return fade != nil
        }
        
        
        public var containsAnimation: Bool {
            return containsTranslation || containsScale || containsFade
        }
        
        
        public var maxDelay: TimeInterval {
            return max(translate?.delay ?? 0, max(scale?.delay ?? 0, fade?.delay ?? 0))
        }
        
        
        public var maxDuration: TimeInterval {
            return max(translate?.duration ?? 0, max(scale?.duration ?? 0, fade?.duration ?? 0))
        }
        
        
        public var totalDuration: TimeInterval {
            return maxDelay + maxDuration
        }
        
        
        public static var translation: Animation {
            return Animation(translate: .init(duration: 0.3))
        }
        
        
        public static var none: Animation {
            return Animation()
        }
        
        
        public init(translate: Translate? = nil, scale: RangeAnimation? = nil, fade: RangeAnimation? = nil) {
            self.translate = translate
            self.scale = scale
            self.fade = fade
        }
    }
}
