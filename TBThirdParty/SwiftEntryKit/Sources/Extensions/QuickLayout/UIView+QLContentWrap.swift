






import Foundation
import UIKit



public extension QLView {

    
    func forceContentWrap(_ axes: QLAxis...) {
        if axes.contains(.vertically) {
            verticalHuggingPriority = .required
            verticalCompressionResistancePriority = .required
        }
        if axes.contains(.horizontally) {
            horizontalHuggingPriority = .required
            horizontalCompressionResistancePriority = .required
        }
    }
    
    
    func forceContentWrap() {
        contentHuggingPriority = .required
        contentCompressionResistancePriority = .required
    }
    
    
    var verticalHuggingPriority: QLPriority {
        set {
            setContentHuggingPriority(newValue, for: .vertical)
        }
        get {
            return contentHuggingPriority(for: .vertical)
        }
    }
    
    
    var horizontalHuggingPriority: QLPriority {
        set {
            setContentHuggingPriority(newValue, for: .horizontal)
        }
        get {
            return contentHuggingPriority(for: .horizontal)
        }
    }
    
    
    var contentHuggingPriority: QLPriorityPair {
        set {
            horizontalHuggingPriority = newValue.horizontal
            verticalHuggingPriority = newValue.vertical
        }
        get {
            return QLPriorityPair(horizontalHuggingPriority, verticalHuggingPriority)
        }
    }
    
    
    var verticalCompressionResistancePriority: QLPriority {
        set {
            setContentCompressionResistancePriority(newValue, for: .vertical)
        }
        get {
            return contentCompressionResistancePriority(for: .vertical)
        }
    }
    
    
    var horizontalCompressionResistancePriority: QLPriority {
        set {
            setContentCompressionResistancePriority(newValue, for: .horizontal)
        }
        get {
            return contentCompressionResistancePriority(for: .horizontal)
        }
    }
    
    
    var contentCompressionResistancePriority: QLPriorityPair {
        set {
            horizontalCompressionResistancePriority = newValue.horizontal
            verticalCompressionResistancePriority = newValue.vertical
        }
        get {
            return QLPriorityPair(horizontalCompressionResistancePriority, verticalCompressionResistancePriority)
        }
    }
}
