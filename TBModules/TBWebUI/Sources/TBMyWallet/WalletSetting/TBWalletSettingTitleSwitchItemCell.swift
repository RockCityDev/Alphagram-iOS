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

class TBWalletSettingTitleSwitchItemCell:UICollectionViewCell {

    private let titleLabel: UILabel
    private let switchView: UISwitch
    private let lineView: UIView
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override init(frame: CGRect) {
    
        self.titleLabel = UILabel()
        self.titleLabel.numberOfLines = 1
        self.titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        self.titleLabel.textColor = UIColor(rgb: 0x000000)
        
        self.switchView = UISwitch()
        
        self.switchView.thumbTintColor = UIColor(rgb: 0x03BDFF)
        
        self.switchView.tintColor = UIColor(rgb: 0x03BDFF, alpha: 0.38)
        
        self.switchView.onTintColor = UIColor(rgb: 0x03BDFF, alpha: 0.38)
        self.switchView.setContentHuggingPriority(.required, for: .horizontal)
        self.switchView.setContentCompressionResistancePriority(.required, for: .horizontal)
        

        self.switchView.isUserInteractionEnabled = false
        
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
        self.contentView.addSubview(self.switchView)
        self.contentView.addSubview(self.lineView)
        
        self.switchView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalTo(-16)
        }
        
        self.titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(22)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(self.switchView.snp.leading).offset(-10)
        }
        
        self.lineView.snp.makeConstraints { make in
            make.bottom.equalTo(0)
            make.height.equalTo(0.5)
            make.leading.equalTo(self.titleLabel)
            make.trailing.equalTo(0)
        }
    }
    
    func reloadCell(title: String, isOn: Bool) {
        self.titleLabel.text = title
        self.switchView.isOn = isOn
    }
}


