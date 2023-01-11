import Foundation
import UIKit
import Display
import AsyncDisplayKit
import TBAccount
import SnapKit
import TBWeb3Core

public class TBItemListLabelItemTextCell: UICollectionViewCell {
    
    private var item: TBWeb3GroupInfoEntry.Tag?
    private let contentLabel: UILabel
    
    public override init(frame: CGRect) {
        
        self.contentLabel = UILabel()
        self.contentLabel.text = ""
        self.contentLabel.textColor = UIColor(rgb: 0x56565C)
        self.contentLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        self.contentLabel.numberOfLines = 1
    
        super.init(frame: frame)
        
        self.contentView.layer.cornerRadius = 33 / 2.0
        self.contentView.layer.borderColor = UIColor(rgb: 0xDCDDE0).cgColor
        self.contentView.layer.borderWidth = 1
        self.contentView.clipsToBounds = true
        
        self.contentView.addSubview(self.contentLabel)
       
        self.contentLabel.snp.makeConstraints { make in
            make.center.equalTo(self.contentView)
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
        self.contentLabel.text = item.name
    }
    
}
