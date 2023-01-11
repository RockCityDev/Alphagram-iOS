







import Foundation
#if os(macOS)
import Cocoa
#else
import UIKit
#endif


extension CGFloat {
    func roundedUpToPixelGrid() -> CGFloat {
        return (self * deviceScale).rounded(.up) / deviceScale
    }
}
