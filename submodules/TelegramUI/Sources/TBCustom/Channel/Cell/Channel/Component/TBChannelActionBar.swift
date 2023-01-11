






import UIKit

class TBChannelActionBar: UIView {
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }
    
    func setupView() {
        self.backgroundColor = UIColor.red
    }
    
    func batchMakeConstraints() {
        
    }
    
    func reload(item:TBCollectionChannelItem) {
        
    }
    

}
