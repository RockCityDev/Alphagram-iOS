







import Foundation
#if os(macOS)
import Cocoa
#else
import UIKit
#endif

extension Array {
    func safeElement(at index: Int) -> Element? {
        if index >= 0 && index < count {
            return self[index]
        }
        return nil
    }
}
