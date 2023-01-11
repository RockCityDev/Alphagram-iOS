






import UIKit
import SnapKit
import TBWeb3Core

public class TBVipGroupInfoDescCell:UICollectionViewCell {
    
    let titleLabel: UILabel
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override init(frame: CGRect) {
    
        self.titleLabel = UILabel()
        self.titleLabel.numberOfLines = 0
        self.titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        self.titleLabel.textColor = UIColor(rgb: 0x56565C)
        self.titleLabel.text = "We have been working on CarnivoreZ for the last few month, and we have so much in store for you all to see over the foreseeable future!"
    
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
        self.titleLabel.text = item.description
    }

    
}

