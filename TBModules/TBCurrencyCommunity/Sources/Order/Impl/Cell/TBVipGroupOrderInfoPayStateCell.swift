






import UIKit
import SnapKit
import TBWeb3Core
import TBLanguage

public class TBVipGroupOrderInfoPayStateCell:UICollectionViewCell {
    
    let titleLabel: UILabel
    let statusLabel: UILabel
    let timeLabel: UILabel
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override init(frame: CGRect) {
    
        self.titleLabel = UILabel()
        self.titleLabel.numberOfLines = 1
        self.titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        self.titleLabel.textColor = UIColor(rgb: 0x56565C)
        self.titleLabel.text = TBLanguage.sharedInstance.localizable(TBLankey.transfer_detatils_dialog_status)
        
        self.statusLabel = UILabel()
        self.statusLabel.numberOfLines = 1
        self.statusLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        self.statusLabel.textColor = UIColor(rgb: 0xFFD233)
        
        self.timeLabel = UILabel()
        self.timeLabel.numberOfLines = 1
        self.timeLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        self.timeLabel.textColor = UIColor(rgb: 0x56565C)
    
        super.init(frame: frame)
        self.contentView.backgroundColor = .white
        self.batchMakeConstraints()
        
    }
    
    func batchMakeConstraints() -> Void {
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.statusLabel)
        self.contentView.addSubview(self.timeLabel)
        
        self.titleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(self.contentView)
        }
        
        self.statusLabel.snp.makeConstraints { make in
            make.top.equalTo(self.titleLabel.snp.bottom).offset(9)
            make.leading.equalTo(0)
        }
        
        self.timeLabel.snp.makeConstraints { make in
            make.centerY.equalTo(self.statusLabel)
            make.trailing.equalTo(0)
        }
    }
    
    func reloadCell(item: TBWeb3GroupInfoEntry, payStatus: LocalPayStatus) {
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateFormat = "MM-dd HH:mm"
        let date = Date()
        if payStatus != .paySuccess {
            self.statusLabel.text = TBLanguage.sharedInstance.localizable(TBLankey.group_pay_confirm_pay_off)
            self.statusLabel.textColor = UIColor(rgb: 0xFFD233)
        }else{
            self.statusLabel.text = TBLanguage.sharedInstance.localizable(TBLankey.group_pay_confirm_pay_success)
            self.statusLabel.textColor = UIColor(rgb: 0x44D320)
        }
        
        self.timeLabel.text = dateFormatter.string(from: date)
    }

    
}

