







import Foundation
#if os(macOS)
import Cocoa
#else
import UIKit
#endif

#if os(macOS)
public typealias GView = NSView
#else
public typealias GView = UIView
#endif


extension GView {
    static let oneDevicePixel: CGFloat = (1.0 / max(2, min(1, deviceScale)))
}
