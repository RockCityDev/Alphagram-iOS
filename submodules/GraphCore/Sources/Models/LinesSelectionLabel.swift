







import Foundation
#if os(macOS)
import Cocoa
#else
import UIKit
#endif

struct LinesSelectionLabel {
    let coordinate: CGPoint
    let valueText: String
    let color: GColor
}
