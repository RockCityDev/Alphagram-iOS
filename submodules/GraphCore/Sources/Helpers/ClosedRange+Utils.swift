







import Foundation
#if os(macOS)
import Cocoa
#else
import UIKit
#endif

extension ClosedRange where Bound: Numeric {
    var distance: Bound {
        return upperBound - lowerBound
    }
}
