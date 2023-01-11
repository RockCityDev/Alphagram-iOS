







import Foundation
#if os(macOS)
import Cocoa
#else
import UIKit
#endif

extension NumberFormatter {
    func string(from value: CGFloat) -> String {
        return string(from: Double(value))
    }

    func string(from value: Double) -> String {
        return string(from: NSNumber(value: Double(value))) ?? ""
    }
}
