







import Foundation
#if os(macOS)
import Cocoa
#else
import UIKit
#endif

enum ChartsError: Error {
    case invalidJson
    case generalConversion(String)
}
