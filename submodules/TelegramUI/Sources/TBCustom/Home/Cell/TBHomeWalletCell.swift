






import UIKit

class TBHomeWalletCell: UICollectionViewCell {
    convenience required init(coder : NSCoder){
        self.init(frame:CGRect.zero)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.brown
    }
}
