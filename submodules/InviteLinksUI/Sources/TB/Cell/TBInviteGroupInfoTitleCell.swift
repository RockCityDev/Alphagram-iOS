






import UIKit
import SnapKit
import TBWeb3Core

public class TBInviteGroupInfoTitleCell:UICollectionViewCell {
    
    let titleLabel: UILabel
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override init(frame: CGRect) {
    
        self.titleLabel = UILabel()
        self.titleLabel.numberOfLines = 0
        self.titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        self.titleLabel.textColor = .black
        self.titleLabel.text = "BAYC HOULDER GROUP"
        
        super.init(frame: frame)
        self.contentView.backgroundColor = .white
        self.batchMakeConstraints()
        
    }
    
    func batchMakeConstraints() -> Void {
        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(self.contentView)
        }
    }
    
    func reloadCell(item: TBWeb3GroupInfoEntry) {
        self.titleLabel.text = item.title
    }

    
}

