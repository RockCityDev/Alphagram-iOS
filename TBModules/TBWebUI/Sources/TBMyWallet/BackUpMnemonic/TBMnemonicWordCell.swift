import Foundation
import UIKit
import AppBundle
import AccountContext

class TBMnemonicWordCell:UICollectionViewCell {
    struct Item {
        let index: Int
        let name: String
    }
    
    private let verticalLine: UIView
    private let horizontalLine: UIView
    private let indexLabel: UILabel
    private let nameLabel: UILabel
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override init(frame: CGRect) {
        
        self.verticalLine = UIView()
        self.verticalLine.backgroundColor = UIColor(rgb: 0xDCDCDC)
        
        self.horizontalLine = UIView()
        self.horizontalLine.backgroundColor = UIColor(rgb: 0xDCDCDC)
    
        self.indexLabel = UILabel()
        self.indexLabel.numberOfLines = 1
        self.indexLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        self.indexLabel.textColor = UIColor(rgb: 0xBBBBBB)
        
        self.nameLabel = UILabel()
        self.nameLabel.numberOfLines = 0
        self.nameLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        self.nameLabel.textColor = UIColor(rgb: 0x000000)
        
        super.init(frame: frame)
        
        self.contentView.backgroundColor = .white
        
        self.batchMakeConstraints()
        
    }
    
    private func batchMakeConstraints() -> Void {
        self.contentView.addSubview(self.indexLabel)
        self.contentView.addSubview(self.nameLabel)
        self.contentView.addSubview(self.horizontalLine)
        self.contentView.addSubview(self.verticalLine)
        
        self.indexLabel.snp.makeConstraints { make in
            make.top.equalTo(8)
            make.leading.equalTo(12)
            make.trailing.lessThanOrEqualTo(-12)
            make.height.equalTo(18)
        }
        
        self.nameLabel.snp.makeConstraints { make in
            make.top.equalTo(self.indexLabel.snp.bottom).offset(6)
            make.leading.equalTo(12)
            make.trailing.lessThanOrEqualTo(-12)
            make.height.greaterThanOrEqualTo(20)
        }
        
        self.horizontalLine.snp.makeConstraints { make in
            make.leading.bottom.trailing.equalTo(0)
            make.height.equalTo(0.5)
        }
        
        self.verticalLine.snp.makeConstraints { make in
            make.top.bottom.trailing.equalTo(0)
            make.width.equalTo(0.5)
        }
    }
    
     func reloadCell(item: Item) {
        self.indexLabel.text = "\(item.index)"
        self.nameLabel.text = item.name
    }
}


