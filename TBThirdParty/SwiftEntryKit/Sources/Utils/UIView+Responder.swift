






import UIKit

extension UIView {
    var containsFirstResponder: Bool {
        var contains = false
        for subview in subviews.reversed() where !contains {
            if subview.isFirstResponder {
                contains = true
            } else {
                contains = subview.containsFirstResponder
            }
        }
        return contains
    }
}
