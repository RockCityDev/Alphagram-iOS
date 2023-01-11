






import UIKit
import SnapKit
import TBWeb3Core
import SDWebImage

public class TBVipGroupOrderInfoPriceCell:UICollectionViewCell {
    
    let titleLabel: UILabel
    let currencyIcon: UIImageView
    let currencyLabel: UILabel
    let amountLabel: UILabel
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override init(frame: CGRect) {
    
        self.titleLabel = UILabel()
        self.titleLabel.numberOfLines = 1
        self.titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        self.titleLabel.textColor = UIColor(rgb: 0x56565C)
        self.titleLabel.text = "Total:"
        
        self.currencyIcon = UIImageView()
        self.currencyIcon.contentMode = .scaleAspectFit
        
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
        
        super.init(frame: frame)
        self.contentView.backgroundColor = .white
        self.batchMakeConstraints()
        
    }
    
    func batchMakeConstraints() -> Void {
        
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.currencyIcon)
        self.contentView.addSubview(self.currencyLabel)
        self.contentView.addSubview(self.amountLabel)
        
        self.titleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(self.contentView)
            make.leading.equalTo(0)
        }
        
        self.currencyLabel.snp.makeConstraints { make in
            make.centerY.equalTo(self.contentView)
            make.trailing.equalTo(0)
            make.height.equalTo(29)
        }
        
        self.currencyIcon.snp.makeConstraints { make in
            make.centerY.equalTo(self.currencyLabel)
            make.trailing.equalTo(self.currencyLabel.snp.leading).offset(-4)
            make.width.height.equalTo(20)
        }
        
        self.amountLabel.snp.makeConstraints { make in
            make.top.equalTo(self.currencyLabel.snp.bottom)
            make.trailing.equalTo(0)
            make.height.equalTo(20)
        }
    }
    
    func reloadCell(item: TBWeb3GroupInfoEntry, config:TBWeb3ConfigEntry) {
        
        if let icon = config.getConfigCurrency(chainId: Int(item.chain_id), currenyId: Int(item.currency_id))?.icon {
            self.currencyIcon.sd_setImage(with: URL(string: icon))
        }
        self.currencyLabel.text = "\(item.amount) \(item.currency_name)"
        self.amountLabel.isHidden = true
        //self.amountLabel.text = ""
    }

    
}

