






import UIKit
import SnapKit
import TBWeb3Core
import SDWebImage

public class TBTransferToItBottomPromoteCell: UICollectionViewCell {
    
    let titleLabel: UILabel
    let desLabel: UILabel
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override init(frame: CGRect) {
    
        self.titleLabel = UILabel()
        self.titleLabel.numberOfLines = 0
        self.titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        self.titleLabel.textColor = UIColor(rgb: 0x56565C)
        self.titleLabel.textAlignment = .center
        
        self.desLabel = UILabel()
        self.desLabel.numberOfLines = 0
        self.desLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        self.desLabel.textColor = UIColor(rgb: 0x83868B)
        self.desLabel.textAlignment = .center
        
        super.init(frame: frame)
        self.contentView.backgroundColor = .white
        self.batchMakeConstraints()
        
    }
    
    func batchMakeConstraints() -> Void {
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.desLabel)
        
        self.titleLabel.snp.makeConstraints { make in
            make.top.equalTo(0)
            make.centerX.equalTo(self.contentView)
            make.leading.greaterThanOrEqualTo(0)
        }
        
        self.desLabel.snp.makeConstraints { make in
            make.top.equalTo(self.titleLabel.snp.bottom).offset(10)
            make.centerX.equalTo(self.contentView)
            make.leading.greaterThanOrEqualTo(0)
        }
        
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    func reloadCell(title: String, des:String) {
        self.titleLabel.text = title
        self.desLabel.text = des
    }

    
}

