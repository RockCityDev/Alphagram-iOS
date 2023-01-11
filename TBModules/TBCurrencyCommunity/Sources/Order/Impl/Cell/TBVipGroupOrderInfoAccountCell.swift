






import UIKit
import SnapKit
import TBWeb3Core
import TBDisplay

public class TBVipGroupOrderInfoAccountCell:UICollectionViewCell {
    
    private let titleLabel: UILabel
    private let desLabel: UILabel
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override init(frame: CGRect) {
    
        self.titleLabel = UILabel()
        self.titleLabel.numberOfLines = 1
        self.titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        self.titleLabel.textColor = UIColor(rgb: 0xABABAF)
        self.titleLabel.text = "from"
        self.titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        self.titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        self.desLabel = UILabel()
        self.desLabel.numberOfLines = 1
        self.desLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        self.desLabel.textColor = UIColor(rgb: 0x37393D)
        self.desLabel.lineBreakMode = .byTruncatingMiddle
        self.desLabel.text = "0xA7EF92...998f"
        
        super.init(frame: frame)
        
        self.contentView.backgroundColor = UIColor(rgb: 0xF7F8F9)
        self.batchMakeConstraints()
        
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        self.contentView.layer.cornerRadius = 8
    }
    
    func batchMakeConstraints() -> Void {
        
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.desLabel)
        
        self.titleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(self.contentView)
            make.leading.equalTo(12)
        }
        self.desLabel.snp.makeConstraints { make in
            make.centerY.equalTo(self.contentView)
            make.trailing.equalTo(-12)
            make.leading.greaterThanOrEqualTo(self.contentView.snp.centerX).offset(20)
        }
    }
    
    func reloadCell(item: TBWeb3GroupInfoEntry, title: String, account:String) {
        self.titleLabel.text = title
        self.desLabel.text = account
    }

    
}

