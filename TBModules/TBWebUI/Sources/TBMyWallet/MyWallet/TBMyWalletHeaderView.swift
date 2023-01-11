
import UIKit
import Display
import AccountContext
import AsyncDisplayKit
import TelegramPresentationData
import SnapKit
import TBWeb3Core
import SDWebImage
import TBDisplay
import TelegramCore
import AvatarNode
import TBWalletCore


private class NetworkView: UIView {
    private let context: AccountContext
    private var presentationData: PresentationData
    
    private let iconView: UIImageView
    private let nameLabel: UILabel
    private let arrowView: UIImageView
    
    init(context: AccountContext, presentationData: PresentationData) {
        self.context = context
        self.presentationData = presentationData
        
        self.iconView = UIImageView()
        
        self.nameLabel = UILabel()
        self.nameLabel.textColor = UIColor(rgb: 0x000000)
        self.nameLabel.font = .systemFont(ofSize: 13, weight: .medium)
        self.nameLabel.numberOfLines = 1
        
        self.arrowView = UIImageView()
        
        super.init(frame: .zero)
        
        self.addSubview(self.iconView)
        self.addSubview(self.nameLabel)
        self.addSubview(self.arrowView)
        
        self.iconView.snp.makeConstraints { make in
            make.centerY.equalTo(self)
            make.leading.equalTo(6)
            make.width.height.equalTo(24)
            make.top.equalTo(6)
        }
        
        self.nameLabel.snp.makeConstraints { make in
            make.centerY.equalTo(self)
            make.leading.equalTo(self.iconView.snp.trailing).offset(6)
        }
        
        self.arrowView.snp.makeConstraints { make in
            make.centerY.equalTo(self)
            make.leading.equalTo(self.nameLabel.snp.trailing).offset(6)
            make.trailing.equalTo(-6)
            make.width.height.equalTo(16)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.iconView.clipsToBounds = true
        self.iconView.layer.cornerRadius = 12
    }
    
    fileprivate func updateNetwork(_ network: NetworkItem) {
        let iconImage = network.getIconName()
        if !iconImage.isEmpty {
            if iconImage.hasPrefix("http") {
                self.iconView.sd_setImage(with: URL(string: iconImage))
            } else {
                self.iconView.image = UIImage(named: iconImage)
            }
        }
        self.nameLabel.text = network.getTitle()
        
        if let arrowName = network.getArrowName() {
            self.arrowView.isHidden = false
            let image = UIImage(bundleImageName: arrowName)
            self.arrowView.tintColor = .black
            self.arrowView.image = image
        } else {
            self.arrowView.isHidden = true
        }
    }
    
}


private class AccountView: UIView {
    private let context: AccountContext
    private var presentationData: PresentationData
    
    let nameLabel: UILabel
    private let arrowView: UIImageView
    
    init(context: AccountContext, presentationData: PresentationData) {
        self.context = context
        self.presentationData = presentationData
        
        self.nameLabel = UILabel()
        self.nameLabel.textColor = UIColor(rgb: 0x000000)
        self.nameLabel.font = .systemFont(ofSize: 13, weight: .medium)
        self.nameLabel.numberOfLines = 1
        self.nameLabel.text = ""
        
        self.arrowView = UIImageView(image: UIImage(bundleImageName: "TBMyWallet/icon_drop_drown_wallet"))
        
        super.init(frame: .zero)
        
        self.addSubview(self.nameLabel)
        self.addSubview(self.arrowView)
        
        self.nameLabel.snp.makeConstraints { make in
            make.centerY.equalTo(self)
            make.leading.equalTo(0)
            make.top.greaterThanOrEqualTo(0)
        }
        
        self.arrowView.snp.makeConstraints { make in
            make.centerY.equalTo(self)
            make.leading.equalTo(self.nameLabel.snp.trailing).offset(0)
            make.trailing.equalTo(0)
            make.width.height.equalTo(30)
            make.top.greaterThanOrEqualTo(0)
        }
    }
    
    func updateAccount(name: String) {
        self.nameLabel.text = name
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}


private class AddressView: UIView {
    private let context: AccountContext
    private var presentationData: PresentationData
    
    private let addressLabel: UILabel
    private let copyView: UIImageView
    
    init(context: AccountContext, presentationData: PresentationData) {
        self.context = context
        self.presentationData = presentationData
        
        self.addressLabel = UILabel()
        self.addressLabel.textColor = UIColor(rgb: 0x868686)
        self.addressLabel.font = .systemFont(ofSize: 13, weight: .medium)
        self.addressLabel.numberOfLines = 1
        self.addressLabel.lineBreakMode = .byTruncatingMiddle
        
        self.copyView = UIImageView(image: UIImage(bundleImageName: "TBMyWallet/Icon_address_copy_wallet"))
        self.copyView.isHidden = true
        
        super.init(frame: .zero)
        
        self.addSubview(self.addressLabel)
        self.addSubview(self.copyView)
        
        self.addressLabel.snp.makeConstraints { make in
            make.centerY.equalTo(self)
            make.leading.equalTo(0)
            make.width.equalTo(105)
            make.top.greaterThanOrEqualTo(0)
        }
        
        self.copyView.snp.makeConstraints { make in
            make.centerY.equalTo(self)
            make.leading.equalTo(self.addressLabel.snp.trailing).offset(0)
            make.trailing.equalTo(0)
            make.width.height.equalTo(28)
            make.top.greaterThanOrEqualTo(0)
        }
    }
    
    func updateAddress(_ address: String) {
        self.addressLabel.text = address
        self.copyView.isHidden = address.isEmpty ? true : false
    }
    
    func currentAddress() -> String {
        return self.addressLabel.text ?? ""
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}


private class MoneyView: UIView {
    private let context: AccountContext
    private var presentationData: PresentationData
    
    private let moneyLabel: UILabel
    
    init(context: AccountContext, presentationData: PresentationData) {
        self.context = context
        self.presentationData = presentationData
        
        self.moneyLabel = UILabel()
        self.moneyLabel.textColor = UIColor(rgb: 0x000000)
        self.moneyLabel.font = .systemFont(ofSize: 22, weight: .bold)
        self.moneyLabel.numberOfLines = 1
        
        super.init(frame: .zero)
        
        self.addSubview(self.moneyLabel)
        
        self.moneyLabel.snp.makeConstraints { make in
            make.edges.equalTo(self)
            make.height.equalTo(22)
        }
    }
    
    fileprivate func updateMoney(_ money: String) {
        self.moneyLabel.text = money
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}


private class ExploreView: UIView {
    private let context: AccountContext
    private var presentationData: PresentationData
    
    private let iconView: UIImageView
    private let textLabel: UILabel
    private let arrowView: UIImageView
    
    init(context: AccountContext, presentationData: PresentationData) {
        self.context = context
        self.presentationData = presentationData
        
        self.iconView = UIImageView(image:UIImage(bundleImageName: "TBMyWallet/icon_dapps_wallet"))
        
        self.textLabel = UILabel()
        self.textLabel.textColor = UIColor(rgb: 0xFFFFFF)
        self.textLabel.font = .systemFont(ofSize: 13, weight: .medium)
        self.textLabel.numberOfLines = 1
        self.textLabel.text = " DApps "
        
        self.arrowView = UIImageView(image:UIImage(bundleImageName: "TBMyWallet/icon_arrow_next__wallet_normal"))
        
        super.init(frame: .zero)
        
        self.backgroundColor = UIColor(rgb: 0x3954D5)
        self.addSubview(self.iconView)
        self.addSubview(self.textLabel)
        self.addSubview(self.arrowView)
        
        self.iconView.snp.makeConstraints { make in
            make.top.equalTo(9)
            make.centerY.equalTo(self)
            make.leading.equalTo(24)
            make.width.height.equalTo(18)
        }
        
        self.textLabel.snp.makeConstraints { make in
            make.centerY.equalTo(self)
            make.leading.equalTo(self.iconView.snp.trailing).offset(10)
            
        }
        
        self.arrowView.snp.makeConstraints { make in
            make.leading.greaterThanOrEqualTo(self.textLabel.snp.trailing).offset(10)
            make.centerY.equalTo(self)
            make.trailing.equalTo(-15)
            make.width.height.equalTo(24)
        }
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

enum TBMyWalletEventType {
    case chain
    case account
    case copyAddress(String)
    case explore
    case transfer
    case receive
    case exchange
    case qrCode
    case exportPrivateKey
    case creatWallet
}


private class StackView: UIView {
    
    private struct Item {
        let icon:String
        let name: String
        let eventType: TBMyWalletEventType
    }
    
    private class ItemView: UIView{
        private let iconView: UIImageView
        private let textLabel: UILabel
        var item: Item? {
            didSet {
                self.iconView.image = UIImage(bundleImageName:self.item?.icon ?? "")
                self.textLabel.text = self.item?.name
            }
        }
        override init(frame: CGRect) {
            
            self.iconView = UIImageView()
            
            self.textLabel = UILabel()
            self.textLabel.textColor = UIColor(rgb: 0x000000)
            self.textLabel.font = .systemFont(ofSize: 13, weight: .regular)
            self.textLabel.numberOfLines = 1
            
            super.init(frame: frame)
            
            self.addSubview(self.iconView)
            self.addSubview(self.textLabel)
            
            self.iconView.snp.makeConstraints { make in
                make.centerX.equalTo(self)
                make.top.leading.equalTo(0)
                make.width.height.equalTo(33)
            }
            
            self.textLabel.snp.makeConstraints { make in
                make.centerX.equalTo(self)
                make.top.equalTo(self.iconView.snp.bottom).offset(2)
                make.bottom.equalTo(0)
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    
    private let context: AccountContext
    private var presentationData: PresentationData
    
    private let stackView: UIStackView
    
    var tapEvent:((TBMyWalletEventType)->Void)?
    
    init(context: AccountContext, presentationData: PresentationData) {
        self.context = context
        self.presentationData = presentationData
        
        self.stackView = UIStackView()
        self.stackView.alignment = .center
        self.stackView.axis = .horizontal
        self.stackView.distribution = .equalSpacing
        
        super.init(frame: .zero)
        
        self.addSubview(self.stackView)
        
        self.stackView.snp.makeConstraints { make in
            make.center.equalTo(self)
            make.top.leading.equalTo(self)
        }
        
        let items = [
            Item(icon: "TBMyWallet/icon_transfer_wallet", name: "", eventType: .transfer),
            Item(icon: "TBMyWallet/btn_receive_qrcode_wallet", name: "", eventType: .receive),
            Item(icon: "TBMyWallet/icon_swap_wallet", name: "", eventType: .exchange),
            Item(icon: "TBMyWallet/icon_scan_qrcode_wallet", name: "", eventType: .qrCode),
            //Item(icon: "TBMyWallet/icon_swap_wallet", name: "", eventType: .exportPrivateKey),
            //Item(icon: "TBMyWallet/icon_swap_wallet", name: "", eventType: .creatWallet),
        ]
        
        for item in items {
            let itemView = ItemView()
            itemView.item = item
            let tapGes = UITapGestureRecognizer(target: self, action: #selector(self.tapEvent(sender:)))
            itemView.addGestureRecognizer(tapGes)
            itemView.isUserInteractionEnabled = true
            stackView.addArrangedSubview(itemView)
        }
    }
    
    @objc private func tapEvent(sender: UITapGestureRecognizer) {
        if let view = sender.view as? ItemView, let eventType = view.item?.eventType {
            self.tapEvent?(eventType)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}



private class CardView: UIView {
    private let context: AccountContext
    private var presentationData: PresentationData
    
    let addressView: AddressView
    let moneyView: MoneyView
    private let lineView: UIView
    let stackView: StackView
    let exploreView: ExploreView
    
    init(context: AccountContext, presentationData: PresentationData) {
        self.context = context
        self.presentationData = presentationData
        
        self.addressView = AddressView(context: context, presentationData: presentationData)
        self.moneyView = MoneyView(context: context, presentationData: presentationData)
        self.lineView = UIView()
        self.lineView.backgroundColor = UIColor(rgb: 0x3C3C43)
        self.stackView = StackView(context: context, presentationData: presentationData)
        self.exploreView = ExploreView(context: context, presentationData: presentationData)
        
        super.init(frame: .zero)
        
        self.clipsToBounds = true
        self.layer.borderColor = UIColor(rgb: 0x3954D5).cgColor
        self.layer.borderWidth = 1
        
        self.addSubview(self.addressView)
        self.addSubview(self.moneyView)
        self.addSubview(self.lineView)
        self.addSubview(self.stackView)
        self.addSubview(self.exploreView)
        
        self.addressView.snp.makeConstraints { make in
            make.top.equalTo(6)
            make.leading.equalTo(24)
        }
        
        self.moneyView.snp.makeConstraints { make in
            make.top.equalTo(self.addressView.snp.bottom)
            make.leading.equalTo(24)
        }
        
        self.lineView.snp.makeConstraints { make in
            make.top.equalTo(self.moneyView.snp.bottom).offset(10)
            make.centerX.equalTo(self)
            make.leading.equalTo(24)
            make.height.equalTo(0.5)
        }
        
        self.stackView.snp.makeConstraints { make in
            make.top.equalTo(self.lineView.snp.bottom).offset(10)
            make.centerX.equalTo(self)
            make.leading.equalTo(24)
        }
        
        self.exploreView.snp.makeConstraints { make in
            make.top.equalTo(self.stackView.snp.bottom).offset(15)
            make.centerX.leading.bottom.equalTo(self)
        }
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = 10
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}


class TBMyWalletHeaderView: UIView {
    
    private let context: AccountContext
    private var presentationData: PresentationData
    
    private let accountView: AccountView
    private let netWorkView: NetworkView
    private let cardView: CardView
    private let bottomLine: UIView
    var event: ((TBMyWalletEventType) -> ())?
    
    init(context: AccountContext, presentationData: PresentationData) {
        self.context = context
        self.presentationData = presentationData
        
        self.accountView = AccountView(context: context, presentationData: presentationData)
        self.netWorkView = NetworkView(context: context, presentationData: presentationData)
        self.cardView = CardView(context: context, presentationData: presentationData)
        
        self.bottomLine = UIView()
        self.bottomLine.backgroundColor = UIColor(rgb: 0xF2F2F2)
        
        super.init(frame: .zero)
        
        self.addSubview(self.accountView)
        self.addSubview(self.netWorkView)
        self.addSubview(self.cardView)
        self.addSubview(self.bottomLine)
        
        self.accountView.snp.makeConstraints { make in
            make.top.equalTo(24)
            make.leading.equalTo(23)
        }
        
        self.netWorkView.snp.makeConstraints { make in
            make.centerY.equalTo(self.accountView)
            make.trailing.equalTo(-16)
        }
        
        self.bottomLine.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalTo(self)
            make.height.equalTo(10)
        }
        
        self.cardView.snp.makeConstraints { make in
            make.bottom.equalTo(self.bottomLine.snp.top).offset(-22)
            make.centerX.equalTo(self)
            make.leading.equalTo(16)
        }
        
        let networkTap = UITapGestureRecognizer(target: self, action: #selector(networkTapClick(tap:)))
        self.netWorkView.isUserInteractionEnabled = true
        self.netWorkView.addGestureRecognizer(networkTap)
        
        let accountTap = UITapGestureRecognizer(target: self, action: #selector(self.accountEventClick))
        self.accountView.isUserInteractionEnabled = true
        self.accountView.addGestureRecognizer(accountTap)
        
        let copyTap = UITapGestureRecognizer(target: self, action: #selector(self.copyWalletAddressEventClick))
        self.cardView.addressView.isUserInteractionEnabled = true
        self.cardView.addressView.addGestureRecognizer(copyTap)
        
        let exploreTap = UITapGestureRecognizer(target: self, action: #selector(self.exploreEventClick))
        self.cardView.exploreView.isUserInteractionEnabled = true
        self.cardView.exploreView.addGestureRecognizer(exploreTap)
        
        self.cardView.stackView.tapEvent = {[weak self] eventType in
            self?.event?(eventType)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateMoney(_ money: String) {
        self.cardView.moneyView.updateMoney(money)
    }
    
    func updateNetwork(_ network: TBWeb3ConfigEntry.Chain?) {
        if let network = network {
            self.netWorkView.isHidden = false
            self.netWorkView.updateNetwork(network)
        } else {
            self.netWorkView.isHidden = true
        }
    }
    
    func updateAccount(_ wallet: TBWallet) {
        self.accountView.updateAccount(name: wallet.walletName())
    }
    
    func updateAddress(_ address: String?) {
        if let a = address {
            self.cardView.addressView.isHidden = false
            self.cardView.addressView.updateAddress(a)
        } else {
            self.cardView.addressView.isHidden = true
        }
    }
    
    @objc func networkTapClick(tap: UITapGestureRecognizer) {
        self.event?(.chain)
    }
    
    @objc func accountEventClick() {
        self.event?(.account)
    }
    
    @objc func exploreEventClick() {
        self.event?(.explore)
    }
    
    @objc func copyWalletAddressEventClick() {
        self.event?(.copyAddress(self.cardView.addressView.currentAddress()))
    }
    
}

