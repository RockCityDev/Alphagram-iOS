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

class TBWalletSettingHeaderReusableView: UICollectionReusableView {
    
    private let nameLabel: UILabel
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override init(frame: CGRect) {
        
        self.nameLabel = UILabel()
        self.nameLabel.numberOfLines = 1
        self.nameLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        self.nameLabel.textColor = UIColor(rgb: 0x03BDFF)

        super.init(frame: frame)
        self.backgroundColor = .white
        
        self.batchMakeConstraints()
        
    }
    
    func batchMakeConstraints() -> Void {
        self.addSubview(self.nameLabel)
        self.nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(22)
            make.top.equalTo(16)
            make.trailing.lessThanOrEqualTo(-11)
        }
        
    }
    
    func reloadHeader(_ title: String) {
        self.nameLabel.text = title
    }
}


