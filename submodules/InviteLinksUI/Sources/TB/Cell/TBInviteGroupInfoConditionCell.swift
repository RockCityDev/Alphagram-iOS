






import UIKit
import SnapKit
import TBWeb3Core
import Display
import TBLanguage

public class TBInviteGroupInfoConditionCell:UICollectionViewCell {
    
    let line:UIView
    
    let titleLabel: UILabel
    
    let currencyLabel: UILabel
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override init(frame: CGRect) {
        
        self.line = UIView()
        self.line.backgroundColor = UIColor(rgb: 0xF7F7F7)
    
        self.titleLabel = UILabel()
        self.titleLabel.numberOfLines = 1
        self.titleLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        self.titleLabel.textColor = UIColor(rgb: 0x2F2F33)
        
        self.currencyLabel = UILabel()
        self.currencyLabel.numberOfLines = 1
        self.currencyLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        self.currencyLabel.textColor = UIColor(rgb: 0x4B5BFF)
        self.currencyLabel.text = "0.0729 ETH"
        
        super.init(frame: frame)
        self.contentView.backgroundColor = .white
        self.batchMakeConstraints()
        
    }
    
    func batchMakeConstraints() -> Void {
        self.contentView.addSubview(self.line)
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.currencyLabel)

        self.line.snp.makeConstraints { make in
            make.top.centerX.equalTo(self.contentView)
            make.leading.equalTo(-20)
            make.height.equalTo(0.5)
        }
        
        self.titleLabel.snp.makeConstraints { make in
            make.top.equalTo(15)
            make.leading.equalTo(self.contentView)
        }
        
        self.currencyLabel.snp.makeConstraints { make in
            make.leading.equalTo(0)
            make.top.equalTo(self.titleLabel.snp.bottom).offset(8)
        }
    }
    
    func reloadCell(item: TBWeb3GroupInfoEntry, config:TBWeb3ConfigEntry) {
        let limitType = TBWeb3GroupInfoEntry.LimitType.transferFrom(int: item.join_type)
        switch limitType {
        case .payLimit:
            self.titleLabel.text = TBLanguage.sharedInstance.localizable(TBLankey.dialog_create_group_successful_addpaynum)
            self.currencyLabel.text = "\(item.amount) \(item.currency_name)"
        case .conditionLimit:
            self.titleLabel.text = TBLanguage.sharedInstance.localizable(TBLankey.group_validate_join_condition_join_title)
            let format  = TBLanguage.sharedInstance.localizable(TBLankey.dialog_create_group_successful_condition_join)
            self.currencyLabel.text =  String(format: format, "\(item.amount)\(item.currency_name)")
        case .noLimit:
            self.titleLabel.text = TBLanguage.sharedInstance.localizable(TBLankey.group_validate_join_condition_join_title)
            self.currencyLabel.text = TBLanguage.sharedInstance.localizable(TBLankey.create_group_join_group)
            break
        }
    }

    
}

