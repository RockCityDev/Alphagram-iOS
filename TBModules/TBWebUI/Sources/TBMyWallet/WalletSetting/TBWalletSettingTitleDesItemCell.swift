import Foundation
import UIKit
import AsyncDisplayKit
import Display
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import AppBundle
import AccountContext
import PresentationDataUtils
import TBWeb3Core
import Web3swift
import Web3swiftCore
import TBWalletCore

class TBWalletSettingTitleDesItemCell:UICollectionViewCell {

    private let titleLabel: UILabel
    private let desLabel: UILabel
    private let lineView: UIView
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override init(frame: CGRect) {
    
        self.titleLabel = UILabel()
        self.titleLabel.numberOfLines = 1
        self.titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        self.titleLabel.textColor = UIColor(rgb: 0x000000)
        self.titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        self.titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        self.desLabel = UILabel()
        self.desLabel.numberOfLines = 1
        self.desLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        self.desLabel.textColor = UIColor(rgb: 0x03BDFF)
        
        self.lineView = UIView()
        self.lineView.backgroundColor = UIColor(rgb: 0xE9EBEA)
        
        super.init(frame: frame)
        
        self.contentView.backgroundColor = .white
        self.batchMakeConstraints()
        
    }
    
    override func layoutSubviews() {
         super.layoutSubviews()
    }
    
    func batchMakeConstraints() -> Void {
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.desLabel)
        self.contentView.addSubview(self.lineView)
    
        self.titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(22)
            make.centerY.equalToSuperview()
        }
        
        self.desLabel.snp.makeConstraints { make in
            make.trailing.equalTo(-16)
            make.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualTo(self.titleLabel.snp.trailing).offset(10)
        }
        
        self.lineView.snp.makeConstraints { make in
            make.bottom.equalTo(0)
            make.height.equalTo(0.5)
            make.leading.equalTo(self.titleLabel)
            make.trailing.equalTo(0)
        }
        
      
    }
    
    func reloadCell(title: String, des: String) {
        self.titleLabel.text = title
        self.desLabel.text = des
    }
}


