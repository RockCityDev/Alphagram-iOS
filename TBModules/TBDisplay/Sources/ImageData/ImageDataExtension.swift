
import Foundation
import UIKit


extension String {
    
    func imageData() -> Data? {
        if let url = URL(string: self) {
            return try? NSData(contentsOf: url) as Data
        }
        return nil
    }

}

extension UIImage {
    
    func pngData_tb() -> Data? {
        return self.pngData()
    }
    
    func jpegData(quality: CGFloat) -> Data? {
        return self.jpegData(compressionQuality: quality)
    }
    
}
