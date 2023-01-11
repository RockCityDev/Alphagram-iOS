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

class TBMyWalletHeaderReusableView:UICollectionReusableView {
    
    private let nameLabel: UILabel
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override init(frame: CGRect) {
        
        self.nameLabel = UILabel()
        self.nameLabel.numberOfLines = 1
        self.nameLabel.font = UIFont.systemFont(ofSize: 11, weight: .regular)
        self.nameLabel.textColor = UIColor(rgb: 0x868686)

        super.init(frame: frame)
        
        self.batchMakeConstraints()
        
    }
    
    func batchMakeConstraints() -> Void {
        self.addSubview(self.nameLabel)
        self.nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(50)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(-11)
        }
        
    }
    
    func reloadHeader(_ title: String) {
        self.nameLabel.text = title
    }
}


