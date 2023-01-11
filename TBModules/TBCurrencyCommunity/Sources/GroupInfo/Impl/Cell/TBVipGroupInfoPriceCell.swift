






import UIKit
import SnapKit
import TBWeb3Core
import Display
import TBLanguage

public class TBVipGroupInfoPriceCell:UICollectionViewCell {
    
    let titleLabel: UILabel
    
    let currencyLabel: UILabel
    
    let amountLabel: UILabel
    
    let conditionLabel: UILabel
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override init(frame: CGRect) {
    
        self.titleLabel = UILabel()
        self.titleLabel.numberOfLines = 1
        self.titleLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        self.titleLabel.textColor = UIColor(rgb: 0x2F2F33)
        
        self.currencyLabel = UILabel()
        self.currencyLabel.numberOfLines = 1
        self.currencyLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        self.currencyLabel.textColor = UIColor(rgb: 0x4B5BFF)
        self.currencyLabel.text = "0.0729 ETH"
        
        self.amountLabel = UILabel()
        self.amountLabel.numberOfLines = 1
        self.amountLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        self.amountLabel.textColor = UIColor(rgb: 0xABABAF)
        self.amountLabel.text = "$114.57 USD"
        
        self.conditionLabel = UILabel()
        self.conditionLabel.numberOfLines = 1
        self.conditionLabel.font = Font.regular(14)
        self.conditionLabel.textColor = UIColor(hexString: "#FF56565C")
        
        super.init(frame: frame)
        self.contentView.backgroundColor = .white
        self.batchMakeConstraints()
        
    }
    
    func batchMakeConstraints() -> Void {
        
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.currencyLabel)
        self.contentView.addSubview(self.amountLabel)
        self.contentView.addSubview(self.conditionLabel)
        
        self.titleLabel.snp.makeConstraints { make in
            make.top.leading.equalTo(self.contentView)
        }
        
        self.currencyLabel.snp.makeConstraints { make in
            make.leading.equalTo(0)
            make.top.equalTo(self.titleLabel.snp.bottom).offset(8)
        }
        
        self.conditionLabel.snp.makeConstraints { make in
            make.leading.equalTo(0)
            make.top.equalTo(self.titleLabel.snp.bottom).offset(8)
        }
        
        self.amountLabel.snp.makeConstraints { make in
            make.centerY.equalTo(self.currencyLabel)
            make.leading.equalTo(self.currencyLabel.snp.trailing).offset(4)
        }
    }
    
    func reloadCell(item: TBWeb3GroupInfoEntry, config:TBWeb3ConfigEntry, limitType: TBWeb3GroupInfoEntry.LimitType) {
        switch limitType {
        case .payLimit:
            self.titleLabel.text = TBLanguage.sharedInstance.localizable(TBLankey.group_pay_join_amount_title)
            self.currencyLabel.isHidden = false
            self.amountLabel.isHidden = true
            self.conditionLabel.isHidden = true
            self.currencyLabel.text = "\(item.amount) \(item.currency_name)"
        case .conditionLimit:
            self.titleLabel.text = TBLanguage.sharedInstance.localizable(TBLankey.group_validate_join_condition_join_title)
            self.currencyLabel.isHidden = true
            self.amountLabel.isHidden = true
            self.conditionLabel.isHidden = false
            let format = TBLanguage.sharedInstance.localizable(TBLankey.group_validate_join_condition_join)
            self.conditionLabel.text =  String(format: format, "\(item.amount)\(item.currency_name)")
        case .noLimit:
            break
        }
    }

    
}

