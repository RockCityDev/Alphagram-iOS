






import Foundation
import UIKit

open class TBCollectionItem {
    public var itemType = 0
    public var cellClass:AnyClass = UICollectionViewCell.self
    public var itemSize = CGSize.zero
    public var indexPath : IndexPath?
    
    public init() {
        
    }
}
