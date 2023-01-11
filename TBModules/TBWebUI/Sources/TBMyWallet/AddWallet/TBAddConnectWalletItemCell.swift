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

class TBAddConnectWalletItemCell:UICollectionViewCell {

    private let titleLabel: UILabel
    private let desLabel: UILabel
    private let iconView: UIImageView
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override init(frame: CGRect) {
    
        self.titleLabel = UILabel()
        self.titleLabel.numberOfLines = 1
        self.titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        self.titleLabel.textColor = UIColor(rgb: 0x000000)
        
        self.desLabel = UILabel()
        self.desLabel.numberOfLines = 1
        self.desLabel.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        self.desLabel.textColor = UIColor(rgb: 0x868686)
        self.desLabel.lineBreakMode = .byTruncatingMiddle
        
        self.iconView = UIImageView(image: UIImage(bundleImageName: "TBWallet/MetaMask"))
        
        super.init(frame: frame)
        
        self.contentView.backgroundColor = UIColor(rgb:0xF7F8F9)
        self.contentView.clipsToBounds = true
        self.batchMakeConstraints()
        
    }
    
    override func layoutSubviews() {
         super.layoutSubviews()
        self.contentView.layer.cornerRadius = self.contentView.frame.height / 2.0
    }
    
    func batchMakeConstraints() -> Void {
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.desLabel)
        self.contentView.addSubview(self.iconView)
        
        self.iconView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalTo(-18)
            make.width.height.equalTo(24)
        }
        
        self.titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(40)
            make.bottom.equalTo(self.contentView.snp.centerY).offset(-2)
            make.trailing.lessThanOrEqualTo(self.iconView.snp.leading).offset(-10)
        }
        
        self.desLabel.snp.makeConstraints { make in
            make.leading.equalTo(self.titleLabel)
            make.top.equalTo(self.contentView.snp.centerY).offset(2)
            make.trailing.lessThanOrEqualTo(self.iconView.snp.leading).offset(-10)
        }
        
      
    }
    
    func reloadCell(title: String, des: String, image: UIImage?, wallet: TBWalletConnect?) {
        self.titleLabel.text = title
        self.desLabel.text = des
    }
}


