






import UIKit
import SnapKit
import TBWeb3Core
import SDWebImage
import Display
import TBDisplay
import AccountContext
import AsyncDisplayKit
import TelegramPresentationData
import TBLanguage

public class TBCurrencyCommunityRecommendItemCell:UICollectionViewCell {
    
    private class ConditionView: UIView{
        let textNode: ASTextNode
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        public override init(frame: CGRect) {
            self.textNode = ASTextNode()
            super.init(frame: frame)
            self.addSubnode(self.textNode)
            self.textNode.view.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(12)
                make.top.equalToSuperview().offset(13)
                make.trailing.equalToSuperview()
                make.height.equalTo(16)
            }
        }
    }
    
    private class PayView: UIView {
        
        private let icon: UIImageView
        private let amoutLabel: UILabel
        private let nameLabel: UILabel
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        fileprivate override init(frame: CGRect) {
            self.icon = UIImageView()
            
            self.amoutLabel = UILabel()
            self.amoutLabel.numberOfLines = 1
            self.amoutLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            self.amoutLabel.textColor = UIColor(rgb: 0x56565C)
            
            self.nameLabel = UILabel()
            self.nameLabel.numberOfLines = 1
            self.nameLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            self.nameLabel.textColor = UIColor(rgb: 0x56565C)
            
            super.init(frame: frame)
            self.batchMakeConstraints()
        }
        
        func batchMakeConstraints() -> Void {
            
            self.addSubview(self.icon)
            self.addSubview(self.amoutLabel)
            self.addSubview(self.nameLabel)
            
            self.icon.snp.makeConstraints { make in
                make.centerY.equalTo(self)
                make.leading.equalTo(12)
                make.width.height.equalTo(16)
            }
            
            self.amoutLabel.snp.makeConstraints { make in
                make.centerY.equalTo(self)
                make.leading.equalTo(self.icon.snp.trailing).offset(2)
            }
            
            self.nameLabel.snp.makeConstraints { make in
                make.centerY.equalTo(self)
                make.leading.equalTo(self.amoutLabel.snp.trailing).offset(4)
            }
        }
        
        fileprivate func reload(item: TBWeb3GroupListEntry.Item, limitType: TBWeb3GroupInfoEntry.LimitType) {
            self.icon.sd_setImage(with: URL(string: item.currency_icon))
            
            self.amoutLabel.text = limitType == .conditionLimit ? "Hold >= " + item.amount : item.amount
            self.nameLabel.text = item.currency_name
        }
    }
    
    private let avatar: UIImageView
    private let titleLabel: UILabel
    private let joinNumLabel: UILabel
    private let desLabel: UILabel
    private let grayLine: UIView
    private let conditionView: ConditionView
    private let payView: PayView
    private let joinButton: UIButton
    
    private var item: TBWeb3GroupListEntry.Item?
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override init(frame: CGRect) {
        
        self.avatar = UIImageView()
        self.avatar.layer.cornerRadius = 23
        self.avatar.clipsToBounds = true
        
        self.titleLabel = UILabel()
        self.titleLabel.numberOfLines = 1
        self.titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        self.titleLabel.textColor = UIColor(rgb: 0x1A1A1D)
        
        self.joinNumLabel = UILabel()
        self.joinNumLabel.numberOfLines = 1
        self.joinNumLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        self.joinNumLabel.textColor = UIColor(hexString: "#FF828283")
        
        self.desLabel = UILabel()
        self.desLabel.numberOfLines = 1
        self.desLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        self.desLabel.textColor = UIColor(rgb: 0x828283)
        
        self.grayLine = UIView()
        self.grayLine.backgroundColor = UIColor(rgb: 0x000000, alpha: 0.1)
        
        self.conditionView = ConditionView()
        self.conditionView.alpha = 0
        
        self.payView = PayView()
        self.payView.alpha = 0
        
        self.joinButton = UIButton(type: .custom)
        
        self.joinButton.layer.cornerRadius = 12.5
        self.joinButton.layer.borderColor = UIColor(rgb: 0x4B5BFF).cgColor
        self.joinButton.layer.borderWidth = 1
        self.joinButton.clipsToBounds = true
        self.joinButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        self.joinButton.isUserInteractionEnabled = false
        self.joinButton.setContentHuggingPriority(.required, for: .horizontal)
        self.joinButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        super.init(frame: frame)
        
        self.joinButton.addTarget(self, action: #selector(self.tapJoin), for: .touchUpInside)
        
        self.contentView.backgroundColor = .white
        self.contentView.layer.cornerRadius = 5
        self.contentView.layer.borderWidth = 1
        self.contentView.layer.borderColor = UIColor(rgb: 0xE6E6E6).cgColor
        self.contentView.clipsToBounds = true
        self.batchMakeConstraints()
        
    }
    
    @objc func tapJoin() {
        
    }
    
    func batchMakeConstraints() -> Void {
        self.contentView.addSubview(self.avatar)
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.joinNumLabel)
        self.contentView.addSubview(self.desLabel)
        self.contentView.addSubview(self.grayLine)
        self.contentView.addSubview(self.conditionView)
        self.contentView.addSubview(self.payView)
        self.contentView.addSubview(self.joinButton)
        
        self.avatar.snp.makeConstraints { make in
            make.top.equalTo(20)
            make.leading.equalTo(12)
            make.width.height.equalTo(46)
        }
        
        self.titleLabel.snp.makeConstraints { make in
            make.top.equalTo(20)
            make.leading.equalTo(self.avatar.snp.trailing).offset(12)
            make.trailing.lessThanOrEqualTo(-12)
        }
        
        self.joinNumLabel.snp.makeConstraints { make in
            make.top.equalTo(self.titleLabel.snp.bottom).offset(4)
            make.leading.equalTo(self.titleLabel)
            make.trailing.lessThanOrEqualTo(-12)
        }
        
        self.desLabel.snp.makeConstraints { make in
            make.top.equalTo(self.joinNumLabel.snp.bottom).offset(4)
            make.leading.equalTo(self.titleLabel)
            make.trailing.lessThanOrEqualTo(-12)
        }
        
        self.joinButton.snp.makeConstraints { make in
            make.trailing.equalTo(-12)
            make.bottom.equalTo(-12)
            make.height.equalTo(25)
        }
    
        self.conditionView.snp.makeConstraints { make in
            make.bottom.leading.equalTo(self.contentView)
            make.trailing.equalTo(self.joinButton.snp.leading).offset(0)
            make.height.equalTo(45)
        }
        
        self.payView.snp.makeConstraints { make in
            make.edges.equalTo(self.conditionView)
        }
        
        self.grayLine.snp.makeConstraints { make in
            make.bottom.equalTo(self.conditionView.snp.top)
            make.centerX.equalTo(self.contentView)
            make.leading.equalTo(12)
            make.height.equalTo(0.33)
        }
        
    }
    
    func reloadCell(item: TBWeb3GroupListEntry.Item, config: TBWeb3ConfigEntry) {
        self.item = item
        self.avatar.sd_setImage(with: URL(string: item.avatar), placeholderImage: UIImage(named: "TBWallet/avatar"))
        self.titleLabel.text = item.title
        let num = km_transfrom(number: NSDecimalNumber(decimal: Decimal(item.ship)))
        let joinText = TBLanguage.sharedInstance.localizable(TBLankey.vip_group_joined)
        self.joinNumLabel.text = num + " " + joinText
        self.desLabel.text = item.description
        let type = TBWeb3GroupInfoEntry.LimitType.transferFrom(int: item.join_type)
        
        let text = TBLanguage.sharedInstance.localizable(TBLankey.create_group_tips_unlimit)
        self.conditionView.textNode.attributedText = NSAttributedString(string: text, font: Font.regular(14), textColor: UIColor(hexString: "#FF828282")!, paragraphAlignment: .left)
        
        let joinButtonName = TBLanguage.sharedInstance.localizable(TBLankey.asset_home_button_join)
        self.joinButton.setAttributedTitle(NSAttributedString(string: joinButtonName, font: .systemFont(ofSize: 14, weight: .medium), textColor: UIColor(rgb: 0x4B5BFF)), for: .normal)
        switch type {
        case .noLimit:
            self.payView.alpha = 0
            self.conditionView.alpha = 1
        case .conditionLimit:
            self.payView.alpha = 1
            self.conditionView.alpha = 0
            self.payView.reload(item: item, limitType: .conditionLimit)
        case .payLimit:
            self.payView.alpha = 1
            self.conditionView.alpha = 0
            self.payView.reload(item: item, limitType: .payLimit)
        }
    }
}

