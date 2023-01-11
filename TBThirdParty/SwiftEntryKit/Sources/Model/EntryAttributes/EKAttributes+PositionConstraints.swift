







import UIKit

public extension EKAttributes {
    
    
    struct PositionConstraints {

        
        public enum SafeArea {
            
            
            case overridden
            
            
            case empty(fillSafeArea: Bool)
            
            public var isOverridden: Bool {
                switch self {
                case .overridden:
                    return true
                default:
                    return false
                }
            }
        }
        
        
        public enum Edge {
            
            
            case ratio(value: CGFloat)
            
            
            case offset(value: CGFloat)
            
            
            case constant(value: CGFloat)
            
            
            case intrinsic
            
            
            public static var fill: Edge {
                return .offset(value: 0)
            }
        }
        
        
        public struct Size {
            
            
            public var width: Edge
            
            
            public var height: Edge
            
            
            public init(width: Edge, height: Edge) {
                self.width = width
                self.height = height
            }
            
            
            public static var intrinsic: Size {
                return Size(width: .intrinsic, height: .intrinsic)
            }
            
            
            public static var sizeToWidth: Size {
                return Size(width: .offset(value: 0), height: .intrinsic)
            }
            
            
            public static var screen: Size {
                return Size(width: .fill, height: .fill)
            }
        }
        
        
        public enum KeyboardRelation {
            
            
            public struct Offset {
                
                
                public var bottom: CGFloat
                
                
                public var screenEdgeResistance: CGFloat?
                
                public init(bottom: CGFloat = 0, screenEdgeResistance: CGFloat? = nil) {
                    self.bottom = bottom
                    self.screenEdgeResistance = screenEdgeResistance
                }
                
                
                public static var none: Offset {
                    return Offset()
                }
            }
            
            
            case bind(offset: Offset)
            
            
            case unbind
            
            
            public var isBound: Bool {
                switch self {
                case .bind(offset: _):
                    return true
                case .unbind:
                    return false
                }
            }
        }
        
        
        public struct Rotation {
            
            
            public enum SupportedInterfaceOrientation {
                
                
                case standard
                
                
                case all
            }
            
            
            public var isEnabled = true
            
            
            public var supportedInterfaceOrientations = SupportedInterfaceOrientation.standard
            
            public init() {}
        }
        
        
        public var rotation = Rotation()
        
        
        public var keyboardRelation = KeyboardRelation.unbind
        
        
        public var size: Size
        
        
        public var maxSize: Size

        
        public var verticalOffset: CGFloat
        
        
        public var safeArea = SafeArea.empty(fillSafeArea: false)
        
        public var hasVerticalOffset: Bool {
            return verticalOffset > 0
        }
        
        
        public static var float: PositionConstraints {
            return PositionConstraints(verticalOffset: 10, size: .init(width: .offset(value: 20), height: .intrinsic))
        }
        
        
        public static var fullWidth: PositionConstraints {
            return PositionConstraints(verticalOffset: 0, size: .sizeToWidth)
        }
        
        
        public static var fullScreen: PositionConstraints {
            return PositionConstraints(verticalOffset: 0, size: .screen)
        }
        
        
        public init(verticalOffset: CGFloat = 0, size: Size = .sizeToWidth, maxSize: Size = .intrinsic) {
            self.verticalOffset = verticalOffset
            self.size = size
            self.maxSize = maxSize
        }
    }
}
