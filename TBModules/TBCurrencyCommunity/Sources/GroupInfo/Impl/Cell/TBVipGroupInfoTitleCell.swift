






import UIKit
import SnapKit
import TBWeb3Core
import TBLanguage

public class TBVipGroupInfoTitleCell:UICollectionViewCell {
    
    let titleLabel: UILabel
    let membersLabel: UILabel
    let onlineMembers: UILabel
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override init(frame: CGRect) {
    
        self.titleLabel = UILabel()
        self.titleLabel.numberOfLines = 0
        self.titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        self.titleLabel.textColor = .black
        self.titleLabel.text = "BAYC HOULDER GROUP"
        
        self.membersLabel = UILabel()
        self.membersLabel.numberOfLines = 1
        self.membersLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        self.membersLabel.textColor = UIColor(rgb: 0x56565C)
        
        self.onlineMembers = UILabel()
        self.onlineMembers.numberOfLines = 1
        self.onlineMembers.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        self.onlineMembers.textColor = UIColor(rgb: 0x2DC307)
        self.onlineMembers.text = ""
    
        super.init(frame: frame)
        self.contentView.backgroundColor = .white
        self.batchMakeConstraints()
        
    }
    
    func batchMakeConstraints() -> Void {
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.membersLabel)
        self.contentView.addSubview(self.onlineMembers)
        self.titleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(self.contentView)
        }
        
        self.membersLabel.snp.makeConstraints { make in
            make.leading.equalTo(self.titleLabel)
            make.top.equalTo(self.titleLabel.snp.bottom).offset(8)
        }
        
        self.onlineMembers.snp.makeConstraints { make in
            make.top.equalTo(self.membersLabel)
            make.leading.equalTo(self.membersLabel.snp.trailing).offset(8)
        }
    }
    
    func reloadCell(item: TBWeb3GroupInfoEntry) {
        self.titleLabel.text = item.title
        let suf = TBLanguage.sharedInstance.localizable(TBLankey.act_permissions_chat_group)
        self.membersLabel.text = String(format: suf, item.ship)
    }
    
}

