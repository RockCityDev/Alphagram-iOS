import Foundation
import Postbox
import CryptoUtils


private final class LinkHelperClass: NSObject {
}

public extension MemoryBuffer {
    func md5Digest() -> Data {
        return CryptoMD5(self.memory, Int32(self.length))
    }
}
