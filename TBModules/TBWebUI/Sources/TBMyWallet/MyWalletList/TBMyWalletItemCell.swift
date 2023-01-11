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

class TBMyWalletItemCell:UICollectionViewCell {
    
    private let iconView: UIImageView
    private let nameLabel: UILabel
    private let amountLabel: UILabel
    private let editView: UIButton
    private let copyView: UIButton
    var editAction: (()->Void)?
    var copyAction:(()->Void)?
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override init(frame: CGRect) {
    
        self.iconView = UIImageView(image: UIImage(bundleImageName: "TBMyWallet/icon_selected_network_doalog_wallet"))
        self.iconView.contentMode = .scaleAspectFit
        
        self.nameLabel = UILabel()
        self.nameLabel.numberOfLines = 1
        self.nameLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        self.nameLabel.textColor = UIColor(rgb: 0x000000)
        
        self.amountLabel = UILabel()
        self.amountLabel.numberOfLines = 1
        self.amountLabel.font = UIFont.systemFont(ofSize: 11, weight: .regular)
        self.amountLabel.textColor = UIColor(rgb: 0x868686)
        self.amountLabel.lineBreakMode = .byTruncatingMiddle
        
        self.editView = UIButton(type: .custom)
        self.editView.setImage(UIImage(bundleImageName: "TBMyWallet/icon_edit_dialog_wallet"), for: .normal)
        
        self.copyView = UIButton(type: .custom)
        self.copyView.setImage(UIImage(bundleImageName: "TBMyWallet/Icon_address_copy_wallet_1"), for: .normal)
        
        super.init(frame: frame)
        
        let selectBg = UIView()
        selectBg.backgroundColor = UIColor(rgb: 0xF7F7F7)
        self.selectedBackgroundView = selectBg
        
        self.editView.addTarget(self, action: #selector(self.editBtnAction), for: .touchUpInside)
        self.copyView.addTarget(self, action: #selector(self.copyBtnAction), for: .touchUpInside)
        
        self.contentView.backgroundColor = .white
        self.batchMakeConstraints()
        
    }
    
    func batchMakeConstraints() -> Void {
        self.contentView.addSubview(self.iconView)
        self.contentView.addSubview(self.nameLabel)
        self.contentView.addSubview(self.amountLabel)
        self.contentView.addSubview(self.copyView)
        self.contentView.addSubview(self.editView)
        
        self.iconView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
            make.width.height.equalTo(20)
        }
        
        self.editView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalTo(-10)
            make.width.height.equalTo(30)
        }
        
        self.copyView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalTo(self.editView.snp.leading).offset(-17)
            make.width.height.equalTo(30)
        }
        
        self.nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(self.iconView.snp.trailing).offset(11)
            make.bottom.equalTo(self.contentView.snp.centerY).offset(-1)
            make.height.equalTo(22)
            make.trailing.lessThanOrEqualTo(self.copyView.snp.leading).offset(-10)
        }
        
        self.amountLabel.snp.makeConstraints { make in
            make.leading.equalTo(self.nameLabel)
            make.top.equalTo(self.contentView.snp.centerY).offset(1)
            make.height.equalTo(18)
            make.trailing.lessThanOrEqualTo(self.copyView.snp.leading).offset(-10)
        }
        
    }
    
    @objc private func editBtnAction() {
        self.editAction?()
    }
    
    @objc private func copyBtnAction() {
        self.copyAction?()
    }
    
    func reloadCell(item: TBWallet, isSelect:Bool, context: AccountContext, editAction:@escaping ()->Void, copyAcion:@escaping ()->Void) {
        self.editAction = editAction
        self.copyAction = copyAcion
        
        self.nameLabel.text = item.walletName()
        self.amountLabel.text = item.walletAddress()
        if isSelect {
            self.contentView.backgroundColor = UIColor(rgb: 0xF7F7F7)
            self.iconView.isHidden = false
        }else{
            self.contentView.backgroundColor = .white
            self.iconView.isHidden = true
        }
    }
}


