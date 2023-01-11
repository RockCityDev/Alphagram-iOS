






import UIKit
import SnapKit
import TBWeb3Core
import SDWebImage
import TBLanguage

public class TBVipGroupOrderInfoGroupCell: UICollectionViewCell {
    
    let titleLabel: UILabel
    let avatar: UIImageView
    let nameLabel: UILabel
    let shipLabel: UILabel
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override init(frame: CGRect) {
    
        self.titleLabel = UILabel()
        self.titleLabel.numberOfLines = 1
        self.titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        self.titleLabel.textColor = UIColor(rgb: 0x56565C)
        self.titleLabel.text = TBLanguage.sharedInstance.localizable(TBLankey.group_pay_confirm_permit_title)
        
        self.avatar = UIImageView()
        self.avatar.contentMode = .scaleAspectFill
        self.avatar.clipsToBounds = true
        
        self.nameLabel = UILabel()
        self.nameLabel.numberOfLines = 1
        self.nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        self.nameLabel.textColor = UIColor(rgb: 0x202020)
        self.nameLabel.text = "BAYC HOULDER GROUP"
        
        self.shipLabel = UILabel()
        self.shipLabel.numberOfLines = 1
        self.shipLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        self.shipLabel.textColor = UIColor(rgb: 0x858585)
        
        super.init(frame: frame)
        self.contentView.backgroundColor = .white
        self.batchMakeConstraints()
        
    }
    
    func batchMakeConstraints() -> Void {
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.avatar)
        self.contentView.addSubview(self.nameLabel)
        self.contentView.addSubview(self.shipLabel)
        
        self.titleLabel.snp.makeConstraints { make in
            make.top.equalTo(8)
            make.leading.equalTo(0)
        }
        
        self.avatar.snp.makeConstraints { make in
            make.leading.equalTo(0)
            make.bottom.equalTo(-8)
            make.width.height.equalTo(42)
        }
        
        self.nameLabel.snp.makeConstraints { make in
            make.top.equalTo(self.avatar)
            make.leading.equalTo(self.avatar.snp.trailing).offset(12)
        }
        
        self.shipLabel.snp.makeConstraints { make in
            make.bottom.equalTo(self.avatar)
            make.leading.equalTo(self.avatar.snp.trailing).offset(12)
        }
        
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        self.avatar.layer.cornerRadius = 21
    }
    
    func reloadCell(item: TBWeb3GroupInfoEntry) {
        self.nameLabel.text = item.title
        let format = TBLanguage.sharedInstance.localizable(TBLankey.group_pay_confirm_pay_member_count)
        self.shipLabel.text = String(format: format, item.ship)
        self.avatar.sd_setImage(with: URL(string: item.avatar), placeholderImage: UIImage(bundleImageName: "TBWallet/avatar"))
    }

    
}

