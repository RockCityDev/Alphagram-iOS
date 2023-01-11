






import UIKit
import AuthorizationUI

struct TBLayoutItem {
    let width : CGFloat
    let height : CGFloat
}

class TBCollectionChannelItemLayout {
    
    var userHeader: TBLayoutItem
    var textContainer: TBLayoutItem
    var imageContainer: TBLayoutItem
    var statusView: TBLayoutItem
    var actionBar: TBLayoutItem
    var combineLayout: TBLayoutItem {
        let layouts = [userHeader, textContainer, imageContainer, statusView, actionBar]
        let combineHeight = layouts.reduce(0) { $0 + $1.height}
        return TBLayoutItem(width: userHeader.width, height: combineHeight)
    }
    
    init() {
        self.userHeader = TBLayoutItem(width: 0, height: 0)
        self.textContainer = TBLayoutItem(width: 0, height: 0)
        self.imageContainer = TBLayoutItem(width: 0, height: 0)
        self.statusView = TBLayoutItem(width: 0, height: 0)
        self.actionBar = TBLayoutItem(width: 0, height: 0)
    }
    
}

class TBCollectionChannelItem: TBCollectionItem {
    var layout = TBCollectionChannelItemLayout()
    var reloadItem:((TBCollectionChannelItem, Bool)->Void) = {_, _ in}
    var expandStatus : (can: Bool, isExpand:Bool) = (true, false)
    func updateLayout() {
        let width = itemSize.width
        layout.userHeader = TBLayoutItem(width: width, height: 62)
        var textContainerHeight: CGFloat = 123
        if expandStatus.can {
            textContainerHeight = expandStatus.isExpand ? 234 : 123
        }
        layout.textContainer = TBLayoutItem(width: width, height: textContainerHeight)
        layout.imageContainer = TBLayoutItem(width: width, height: 125)
        layout.statusView = TBLayoutItem(width: width, height: 46)
        layout.actionBar = TBLayoutItem(width: width, height: 46)
        let combineLayout = layout.combineLayout
        self.itemSize = CGSize(width: combineLayout.width, height: combineLayout.height)
        self.reloadItem(self, false)
    }
}
