







import Foundation
#if os(macOS)
import Cocoa
#else
import UIKit
#endif

private let milionsScale = "M"
private let thousandsScale = "K"

class ScalesNumberFormatter: NumberFormatter {
    override func string(from number: NSNumber) -> String? {
        let value = number.doubleValue
        let pow = log10(value)
        if pow >= 6 {
            guard let string = super.string(from: NSNumber(value: value / 1_000_000)) else {
                return nil
            }
            return string + milionsScale
        } else if pow >= 4 {
            guard let string = super.string(from: NSNumber(value: value / 1_000)) else {
                return nil
            }
            return string + thousandsScale
        } else {
            return super.string(from: number)
        }
    }
}
