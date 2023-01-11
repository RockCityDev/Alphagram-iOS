






import UIKit
import AccountContext
import Display
import AsyncDisplayKit

class TBHomeMessageGroupCell: UICollectionViewCell {
    public weak var chatListController : ChatListController?
    convenience required init(coder : NSCoder){
        self.init(frame:CGRect.zero)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.yellow
    }
    
    public func loadChatListControllerIfNeeded(aChatListContrller: ChatListController?, inController: ViewController) ->Void {
        
    }
}
