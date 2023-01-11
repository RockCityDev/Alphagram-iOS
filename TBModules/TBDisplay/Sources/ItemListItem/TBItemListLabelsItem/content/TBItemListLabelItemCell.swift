import Foundation
import UIKit
import Display
import AsyncDisplayKit
import TBAccount
import SnapKit
import TBWeb3Core

public class TBItemListLabelItemCell: UICollectionViewCell {
    
    private var item: TBWeb3GroupInfoEntry.Tag?
    private let contentLabel: UILabel
    private let deleteIcon: UIImageView
    
    public override init(frame: CGRect) {
        
        self.contentLabel = UILabel()
        self.contentLabel.text = ""
        self.contentLabel.textColor = UIColor(rgb: 0x56565C)
        self.contentLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        self.contentLabel.numberOfLines = 1
        
        
        self.deleteIcon = UIImageView(image: UIImage(bundleImageName: "Settings/wallet/tb_ic_close"))
        //"Settings/wallet/tb_ic_check"
        super.init(frame: frame)
        
        self.contentView.layer.cornerRadius = 33 / 2.0
        self.contentView.layer.borderColor = UIColor(rgb: 0xDCDDE0).cgColor
        self.contentView.layer.borderWidth = 1
        self.contentView.clipsToBounds = true
        
        self.contentView.addSubview(self.contentLabel)
        self.contentView.addSubview(self.deleteIcon)
        
        self.contentLabel.snp.makeConstraints { make in
            make.centerY.equalTo(self.contentView)
            make.leading.equalTo(10)
            make.top.greaterThanOrEqualTo(0)
            make.leading.greaterThanOrEqualTo(0)
        }
        self.deleteIcon.snp.makeConstraints { make in
            make.centerY.equalTo(self.contentLabel)
            make.trailing.equalTo(-10)
            make.width.height.equalTo(17)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        self.contentView.layer.cornerRadius = self.frame.height / 2.0
    }
    
    public func reloadCell(item: TBWeb3GroupInfoEntry.Tag, config: TBItemListLabelsContentLayoutConfig) {
        self.item = item
        self.contentLabel.font = config.font
        self.contentLabel.snp.updateConstraints { make in
            make.leading.equalTo(config.itemInset.left)
        }
        self.deleteIcon.snp.updateConstraints { make in
            make.trailing.equalTo(-config.itemInset.right)
        }
        self.contentLabel.text = item.name
    }
    
}
