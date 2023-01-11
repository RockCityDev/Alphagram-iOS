






import UIKit
import SnapKit
import TBWeb3Core
import TBDisplay
import TBWalletCore
import TelegramCore
import AccountContext
import TBLanguage

fileprivate class FromView: UIView {
    let titleLabel: UILabel
    let avatar: TBAvatarView
    let addressLabel: UILabel
    let line: UIView
    override init(frame: CGRect) {
        self.titleLabel = UILabel()
        self.titleLabel.numberOfLines = 1
        self.titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        self.titleLabel.textColor = UIColor(rgb: 0x1A1A1D)
        self.titleLabel.text = "From:"
        self.titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        self.titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        self.avatar = TBAvatarView()
        
        self.addressLabel = UILabel()
        self.addressLabel.numberOfLines = 1
        self.addressLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        self.addressLabel.textColor = UIColor(rgb: 0x56565C)
        self.addressLabel.lineBreakMode = .byTruncatingMiddle
        
        self.line = UIView()
        self.line.backgroundColor = UIColor(rgb: 0xDCDDE0)
        
        super.init(frame: frame)
        
        self.addSubview(self.titleLabel)
        self.addSubview(self.avatar)
        self.addSubview(self.addressLabel)
        self.addSubview(self.line)
        
        self.titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(16)
            make.centerY.equalTo(self)
        }
        self.avatar.snp.makeConstraints { make in
            make.centerY.equalTo(self)
            make.leading.equalTo(84)
            make.width.height.equalTo(36)
        }
        self.addressLabel.snp.makeConstraints { make in
            make.centerY.equalTo(self)
            make.leading.equalTo(self.avatar.snp.trailing).offset(8)
            make.width.lessThanOrEqualTo(93)
        }
        self.line.snp.makeConstraints { make in
            make.bottom.leading.trailing.equalTo(self)
            make.height.equalTo(0.5)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func reload(context:AccountContext, wallet:TBWallet, mySelf:TelegramUser?) {
        self.avatar.reloadAvatar(context: context, tgUser: mySelf)
        self.addressLabel.text = wallet.walletAddress()
    }
    
}

fileprivate class ToView: UIView, UITextFieldDelegate {
    let titleLabel: UILabel
    let avatar: TBAvatarView
    let addressTextField: UITextField
    let clearButton: UIButton
    let qrCodeButton: UIButton
    var textUpdate:((String) -> Void)?
    var qrButtonTap:(()->Void)?
    override init(frame: CGRect) {
        self.titleLabel = UILabel()
        self.titleLabel.numberOfLines = 1
        self.titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        self.titleLabel.textColor = UIColor(rgb: 0x1A1A1D)
        self.titleLabel.text = "To:"
        self.titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        self.titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        self.avatar = TBAvatarView()
        
        self.addressTextField = UITextField()
        self.addressTextField.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        self.addressTextField.textColor = UIColor(rgb: 0x56565C)
        self.addressTextField.clearButtonMode = .never
        self.addressTextField.borderStyle = .none
        self.addressTextField.returnKeyType = .done
        self.addressTextField.attributedPlaceholder = NSAttributedString(string: TBLanguage.sharedInstance.localizable(TBLankey.transfer_activity_search_hint))
        
        self.clearButton = UIButton(type: .custom)
        self.clearButton.setImage(UIImage(bundleImageName: "TBWallet/TransferAsset/ic_clear_gray"), for: .normal)
        self.clearButton.contentEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        self.clearButton.isHidden = true
        
        self.qrCodeButton = UIButton(type: .custom)
        self.qrCodeButton.setImage(UIImage(bundleImageName: "TBWallet/TransferAsset/ic_qr_code"), for: .normal)
        self.qrCodeButton.isHidden = false
        
        super.init(frame: frame)
        
        self.clearButton.addTarget(self, action: #selector(self.tapClearButtonAction), for: .touchUpInside)
        self.qrCodeButton.addTarget(self, action: #selector(self.tapqrCodeButtonAction), for: .touchUpInside)
        
        self.addressTextField.delegate = self
        
        self.addSubview(self.titleLabel)
        self.addSubview(self.avatar)
        self.addSubview(self.addressTextField)
        self.addSubview(self.clearButton)
        self.addSubview(self.qrCodeButton)
        
        self.titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(16)
            make.centerY.equalTo(self)
        }
        self.avatar.snp.makeConstraints { make in
            make.centerY.equalTo(self)
            make.leading.equalTo(84)
            make.width.height.equalTo(36)
        }
        self.addressTextField.snp.makeConstraints { make in
            make.centerY.equalTo(self)
            make.leading.equalTo(self.avatar.snp.trailing).offset(8)
            make.trailing.equalTo(-52)
        }
        
        self.clearButton.snp.makeConstraints { make in
            make.centerY.equalTo(self.addressTextField)
            make.trailing.equalTo(-16)
            make.width.height.equalTo(28)
        }
        
        self.qrCodeButton.snp.makeConstraints { make in
            make.edges.equalTo(self.clearButton)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func tapClearButtonAction() {
        self.addressTextField.text = ""
        self.textUpdate?("")
    }
    
    @objc func tapqrCodeButtonAction() {
        self.qrButtonTap?()
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.clearButton.isHidden = false
        self.qrCodeButton.isHidden = true
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        self.textUpdate?(textField.text ?? "")
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.textUpdate?(textField.text ?? "")
        self.clearButton.isHidden = true
        self.qrCodeButton.isHidden = false
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.endEditing(true)
        return true
    }
    
    func reload(context:AccountContext, selectContact: TBVipContactListEntry?, selectTransaction:TBVipSelectTransactionEntry?, inputText:String) {
        self.addressTextField.text = inputText
        var tgUser:TelegramUser?
        if let user = selectContact?.tgUser {
            tgUser = user
        }else{
            tgUser = selectTransaction?.tgUser
        }
        self.avatar.reloadAvatar(context: context, tgUser: tgUser)
        if self.addressTextField.isFirstResponder {
            self.clearButton.isHidden = false
            self.qrCodeButton.isHidden = true
        }else{
            self.clearButton.isHidden = true
            self.qrCodeButton.isHidden = false
        }
    }
}

private class InValidateView:UIView {
    let contentView: UIView
    let icon: UIImageView
    let titleLabel: UILabel

    override init(frame: CGRect) {
        
        self.contentView = UIView()
        
        self.icon = UIImageView(image: UIImage(bundleImageName: "TBWallet/TransferAsset/ic_info"))
        self.icon.contentMode = .scaleAspectFit
        self.icon.clipsToBounds = true
    
        self.titleLabel = UILabel()
        self.titleLabel.numberOfLines = 1
        self.titleLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        self.titleLabel.textColor = UIColor(rgb: 0xEB5757)
        self.titleLabel.text = TBLanguage.sharedInstance.localizable(TBLankey.ac_wallet_tips)

        super.init(frame: frame)
        self.backgroundColor = UIColor(rgb: 0xFDEEEE)
        self.addSubview(self.contentView)
        self.contentView.addSubview(self.icon)
        self.contentView.addSubview(self.titleLabel)
        
        self.contentView.snp.makeConstraints { make in
            make.center.equalTo(self)
        }
        self.icon.snp.makeConstraints { make in
            make.top.greaterThanOrEqualTo(0)
            make.centerY.leading.equalTo(self.contentView)
            make.width.height.equalTo(20)
        }
        self.titleLabel.snp.makeConstraints { make in
            make.top.greaterThanOrEqualTo(0)
            make.centerY.equalTo(self.contentView)
            make.leading.equalTo(self.icon.snp.trailing).offset(4)
            make.trailing.equalTo(0)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

public class TBTransferToItFromToCell:UICollectionViewCell {
    
    private let stackView: UIStackView
    private let fromView: FromView
    private let toView: ToView
    private let invalidView: InValidateView
    var textUpdate:((String) -> Void)?
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override init(frame: CGRect) {
        
        self.stackView = UIStackView()
        self.stackView.axis = .vertical
        self.stackView.alignment = .fill
        self.stackView.distribution = .equalSpacing
        self.stackView.spacing = 0
        
        self.fromView = FromView()
        self.toView = ToView()
        self.invalidView = InValidateView()
        self.invalidView.isHidden = true
        
        super.init(frame: frame)
        
        self.contentView.backgroundColor = UIColor(rgb: 0xFFFFFF)
        self.contentView.clipsToBounds = true
        self.contentView.layer.cornerRadius = 8
        self.contentView.layer.borderWidth = 1
        self.contentView.layer.borderColor = UIColor(rgb: 0xDCDDE0).cgColor
        self.batchMakeConstraints()
        
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
    }
    
    func batchMakeConstraints() -> Void {
        self.contentView.addSubview(self.stackView)
        self.stackView.addArrangedSubview(self.fromView)
        self.stackView.addArrangedSubview(self.toView)
        self.stackView.addArrangedSubview(self.invalidView)
        
        self.stackView.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(self.contentView)
        }
        self.fromView.snp.makeConstraints { make in
            make.height.equalTo(64)
        }
        self.toView.snp.makeConstraints { make in
            make.height.equalTo(64)
        }
        
        self.invalidView.snp.makeConstraints { make in
            make.height.equalTo(28)
        }
    }
    
    func reloadCell(context:AccountContext,
                    wallet:TBWallet,
                    mySelf:TelegramUser?,
                    selectContact: TBVipContactListEntry?,
                    selectTransaction:TBVipSelectTransactionEntry?,
                    inputText:String,
                    hiddenTips:Bool,
                    textUpdate:@escaping (String) -> Void,
                    qrButtonTap:@escaping ()->Void){
        self.invalidView.isHidden = hiddenTips
        self.fromView.reload(context: context, wallet: wallet, mySelf: mySelf)
        self.toView.reload(context: context, selectContact: selectContact, selectTransaction: selectTransaction, inputText: inputText)
        self.toView.textUpdate = { string in
            textUpdate(string)
        }
        self.toView.qrButtonTap = {
            qrButtonTap()
        }
    }
    
    func textFieldIsFirstResponder() -> Bool {
        return self.toView.addressTextField.isFirstResponder
    }

}

