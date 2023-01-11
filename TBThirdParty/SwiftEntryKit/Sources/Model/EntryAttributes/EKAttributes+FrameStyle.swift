






import Foundation
import CoreGraphics
import UIKit

public extension EKAttributes {
    
    
    enum RoundCorners {
        
        
        case none
        
        
        case all(radius: CGFloat)
        
        
        case top(radius: CGFloat)
        
        
        case bottom(radius: CGFloat)
        
        var hasRoundCorners: Bool {
            switch self {
            case .none:
                return false
            default:
                return true
            }
        }
        
        var cornerValues: (value: UIRectCorner, radius: CGFloat)? {
            switch self {
            case .all(radius: let radius):
                return (value: .allCorners, radius: radius)
            case .top(radius: let radius):
                return (value: .top, radius: radius)
            case .bottom(radius: let radius):
                return (value: .bottom, radius: radius)
            case .none:
                return nil
            }
        }
    }
    
    
    enum Border {
        
        
        case none
        
        
        case value(color: UIColor, width: CGFloat)
        
        var hasBorder: Bool {
            switch self {
            case .none:
                return false
            default:
                return true
            }
        }
        
        var borderValues: (color: UIColor, width: CGFloat)? {
            switch self {
            case .value(color: let color, width: let width):
                return(color: color, width: width)
            case .none:
                return nil
            }
        }
    }
}
