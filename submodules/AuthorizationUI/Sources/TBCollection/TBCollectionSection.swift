






import Foundation
import UIKit

open class TBCollectionSection {
    
    public var sectionType = 0
    public var insets = UIEdgeInsets.zero
    public var items = [TBCollectionItem]()
    public var minumLineSpace: CGFloat = 0 
    public var minimumInteritemSpace: CGFloat = 0 
    public init() {
        
    }
}

public extension TBCollectionSection {
    
    class func section(_ inList: [TBCollectionSection], _ atIdx:Int) -> TBCollectionSection? {
        if atIdx < inList.count {
            return inList[atIdx]
        }else{
            return nil
        }
    }
    
    class func item(_ inList: [TBCollectionSection], _ atIndexPath: IndexPath) -> TBCollectionItem? {
        if let section = self.section(inList, atIndexPath.section) {
            if let item = section.item(atIndexPath.row){
                return item
            }
        }
        return nil
    }
    
    func item(_ atIdx:Int) -> TBCollectionItem? {
        if atIdx < self.items.count {
            return self.items[atIdx]
        }else{
            return nil
        }
    }
    
}
