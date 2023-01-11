






import UIKit
import SnapKit
import TBWeb3Core
import SDWebImage

public class TBTransferToItSeperatorCell: UICollectionViewCell {
    
    let lineView: UIView
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override init(frame: CGRect) {
    
        self.lineView = UIView()
        self.lineView.backgroundColor = UIColor(rgb: 0xDCDDE0)
        super.init(frame: frame)
        self.contentView.backgroundColor = .white
        self.batchMakeConstraints()
        
    }
    
    func batchMakeConstraints() -> Void {
        self.contentView.addSubview(self.lineView)
    
        self.lineView.snp.makeConstraints { make in
            make.center.equalTo(self.contentView)
            make.leading.equalTo(0)
            make.height.equalTo(1)
        }
        
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
    }

}

