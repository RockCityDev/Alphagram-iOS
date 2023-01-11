






import Foundation
import UIKit


public typealias QLMultipleConstraints = [QLAttribute: NSLayoutConstraint]


public extension QLPriority {
    static let must = QLPriority(rawValue: 999)
    static let zero = QLPriority(rawValue: 0)
}


public struct QLAttributePair {
    public let first: QLAttribute
    public let second: QLAttribute
}


public struct QLSizeConstraints {
    public let width: NSLayoutConstraint
    public let height: NSLayoutConstraint
}


public struct QLCenterConstraints {
    public let x: NSLayoutConstraint
    public let y: NSLayoutConstraint
}


public struct QLAxisConstraints {
    public let first: NSLayoutConstraint
    public let second: NSLayoutConstraint
}


public struct QLFillConstraints {
    public let center: QLCenterConstraints
    public let size: QLSizeConstraints
}


public struct QLPriorityPair {
    
    public let horizontal: QLPriority
    public let vertical: QLPriority
    public static var required: QLPriorityPair {
        return QLPriorityPair(.required, .required)
    }
    
    public static var must: QLPriorityPair {
        return QLPriorityPair(.must, .must)
    }
    
    public init(_ horizontal: QLPriority, _ vertical: QLPriority) {
        self.horizontal = horizontal
        self.vertical = vertical
    }
}


public enum QLAxis {
    case horizontally
    case vertically
    
    public var attributes: QLAttributePair {
        
        let first: QLAttribute
        let second: QLAttribute
        
        switch self {
        case .horizontally:
            first = .left
            second = .right
        case .vertically:
            first = .top
            second = .bottom
        }
        return QLAttributePair(first: first, second: second)
    }
}
