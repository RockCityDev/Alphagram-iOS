







import Foundation
import UIKit

public extension EKAttributes {

    
    enum Shadow {
        
        
        case none
        
        
        case active(with: Value)
        
        
        public struct Value {
            public let radius: CGFloat
            public let opacity: Float
            public let color: EKColor
            public let offset: CGSize
            
            public init(color: EKColor = .black,
                        opacity: Float,
                        radius: CGFloat,
                        offset: CGSize = .zero) {
                self.color = color
                self.radius = radius
                self.offset = offset
                self.opacity = opacity
            }
        }
    }
}


