






import UIKit
import SnapKit
import TBWeb3Core
import Display
import TBLanguage

public class TBInviteGroupInfoInviteCell:UICollectionViewCell {
    
    let titleLabel: UILabel
    
    let urlLabel: UILabel
    
    let qrCodeView: UIButton
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override init(frame: CGRect) {
        
        self.titleLabel = UILabel()
        self.titleLabel.numberOfLines = 1
        self.titleLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        self.titleLabel.textColor = UIColor(rgb: 0x2F2F33)
        
        self.urlLabel = UILabel()
        self.urlLabel.numberOfLines = 1
        self.urlLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        self.urlLabel.textColor = UIColor(rgb: 0x4B5BFF)
        self.urlLabel.text = ""
        
        self.qrCodeView = UIButton(type: .custom)
        self.qrCodeView.setImage(UIImage(bundleImageName: "TBWebPage/ic_tb_qr"), for: .normal)
        self.qrCodeView.isUserInteractionEnabled = false
        
        super.init(frame: frame)
        self.contentView.backgroundColor = .white
        self.batchMakeConstraints()
        
    }
    
    func batchMakeConstraints() -> Void {
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.urlLabel)
        self.contentView.addSubview(self.qrCodeView)
        
        self.titleLabel.snp.makeConstraints { make in
            make.top.leading.equalTo(self.contentView)
        }
        
        self.urlLabel.snp.makeConstraints { make in
            make.leading.equalTo(0)
            make.top.equalTo(self.titleLabel.snp.bottom).offset(8)
            make.trailing.lessThanOrEqualTo(self.qrCodeView.snp.leading).offset(-8)
        }
        
        self.qrCodeView.snp.makeConstraints { make in
            make.centerY.equalTo(self.urlLabel)
            make.trailing.equalTo(-23)
            make.width.height.equalTo(21)
        }
    }
    
    func reloadCell(item: TBWeb3GroupInfoEntry, config:TBWeb3ConfigEntry) {
        self.titleLabel.text = TBLanguage.sharedInstance.localizable(TBLankey.group_details_invitation_title)
        self.urlLabel.text = item.getShareUrl()
    }

    
}

