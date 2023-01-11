






import UIKit
import SnapKit
import TBWeb3Core
import SDWebImage

public class TBTransferToItHeaderCell: UICollectionViewCell {
    
    let titleLabel: UILabel
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override init(frame: CGRect) {
    
        self.titleLabel = UILabel()
        self.titleLabel.numberOfLines = 1
        self.titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        self.titleLabel.textColor = UIColor(rgb: 0x56565C)
        
        super.init(frame: frame)
        self.contentView.backgroundColor = .white
        self.batchMakeConstraints()
        
    }
    
    func batchMakeConstraints() -> Void {
        self.contentView.addSubview(self.titleLabel)
        
        self.titleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(self.contentView)
            make.leading.equalTo(0)
        }

    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    func reloadCell(title: String, textColor:UIColor) {
        self.titleLabel.text = title
        self.titleLabel.textColor = textColor
    }

    
}

