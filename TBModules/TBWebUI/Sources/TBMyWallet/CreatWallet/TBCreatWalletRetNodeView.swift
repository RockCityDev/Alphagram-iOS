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


private class CardView: UIView {
    
    let titleLabel: UILabel
    
    let shadowView: UIView
    let addressLabel: UILabel
    let copyIconView: UIImageView
    
    let amountLabel: UILabel
    
    var tapCopy:(() -> Void)?
    
    override init(frame: CGRect) {
        self.titleLabel = UILabel()
        self.titleLabel.numberOfLines = 1
        self.titleLabel.textColor = UIColor(rgb: 0x000000)
        self.titleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        
        self.shadowView = UIView()
        self.shadowView.backgroundColor = UIColor(rgb: 0xF7F8F9)
        self.shadowView.clipsToBounds = true
        self.shadowView.layer.cornerRadius = 8
        
        self.addressLabel = UILabel()
        self.addressLabel.numberOfLines = 0
        self.addressLabel.textColor = UIColor(rgb: 0x000000, alpha: 0.6)
        self.addressLabel.font = .systemFont(ofSize: 14, weight: .regular)
        
        self.copyIconView = UIImageView(image: UIImage(bundleImageName: "TBMyWallet/Icon_address_copy_wallet"))
        
        self.amountLabel = UILabel()
        self.amountLabel.numberOfLines = 1
        self.amountLabel.textColor = UIColor(rgb: 0x000000)
        self.amountLabel.font = .systemFont(ofSize: 22, weight: .medium)
        
        super.init(frame: frame)
        
        self.clipsToBounds = true
        self.layer.cornerRadius = 11
        self.layer.borderColor = UIColor(rgb: 0xD9D9D9).cgColor
        self.layer.borderWidth = 1
        
        self.addSubview(self.titleLabel)
        self.addSubview(self.shadowView)
        self.shadowView.addSubview(self.addressLabel)
        self.shadowView.addSubview(self.copyIconView)
        self.addSubview(self.amountLabel)
        
        self.titleLabel.snp.makeConstraints { make in
            make.top.leading.equalTo(16)
            make.trailing.lessThanOrEqualTo(-16)
        }
        
        self.shadowView.snp.makeConstraints { make in
            make.top.equalTo(self.titleLabel.snp.bottom).offset(9)
            make.centerX.equalToSuperview()
            make.leading.equalTo(16)
        }
        
        self.copyIconView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalTo(-16)
            make.width.height.equalTo(20)
        }
        
        self.addressLabel.snp.makeConstraints { make in
            make.top.equalTo(8)
            make.centerY.equalToSuperview()
            make.leading.equalTo(16)
            make.trailing.equalTo(self.copyIconView.snp.leading).offset(-20)
        }
        
        self.amountLabel.snp.makeConstraints { make in
            make.top.equalTo(self.shadowView.snp.bottom).offset(9)
            make.trailing.equalTo(-16)
            make.bottom.equalTo(-12)
        }
        
        self.shadowView.isUserInteractionEnabled = true
        self.shadowView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tapAction)))
    }
    
    @objc private func tapAction() {
        self.tapCopy?()
    }
    
    func reload(wallet: TBMyWalletModel, amount: String) {
        self.addressLabel.text = wallet.walletAddress()
        self.titleLabel.text = wallet.walletName()
        self.amountLabel.text = amount
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

private struct StackItem {
    enum ItemType {
        case backupMnemonic
        case exportPrivateKey
    }
    let icon: UIImage?
    let title: String
    let type: ItemType
}


private class StackView: UIView {
    
    
    class ItemView: UIView {
        private let iconView: UIImageView
        private let titleLabel: UILabel
        private var item: StackItem?
        var tap:((StackItem)->Void)?
        override init(frame: CGRect) {
            
            self.iconView = UIImageView()
            
            self.titleLabel = UILabel()
            self.titleLabel.numberOfLines = 1
            self.titleLabel.textColor = UIColor(rgb: 0x000000)
            self.titleLabel.font = .systemFont(ofSize: 15, weight: .medium)
            
            super.init(frame: frame)
            
            self.clipsToBounds = true
            self.layer.borderColor = UIColor(rgb: 0xD9D9D9).cgColor
            self.layer.borderWidth = 1
            self.layer.cornerRadius = 10
            
            self.addSubview(self.iconView)
            self.addSubview(self.titleLabel)
            
            self.iconView.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.top.equalTo(17)
                make.leading.equalTo(16)
                make.width.height.equalTo(24)
            }
            
            self.titleLabel.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.leading.equalTo(self.iconView.snp.trailing).offset(16)
                make.trailing.lessThanOrEqualTo(-16)
            }
            
            self.isUserInteractionEnabled = true
            self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tapAction)))
            
            
        }
        
        func reload(_ item: StackItem) {
            self.item = item
            self.titleLabel.text = item.title
            self.iconView.image = item.icon
        }
        
        
        @objc func tapAction() {
            if let item = self.item {
                self.tap?(item)
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    private let titleLabel: UILabel
    private let tipsLabel: UILabel
    private let stackView: UIStackView
    var tap:((StackItem)->Void)?
    
    override init(frame: CGRect) {
        self.titleLabel = UILabel()
        self.titleLabel.numberOfLines = 1
        self.titleLabel.textColor = UIColor(rgb: 0x000000)
        self.titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        self.titleLabel.text = ""
        
        self.tipsLabel = UILabel()
        self.tipsLabel.numberOfLines = 0
        self.tipsLabel.textColor = UIColor(rgb: 0x000000, alpha: 0.6)
        self.tipsLabel.font = .systemFont(ofSize: 14, weight: .regular)
        self.tipsLabel.text = ""
        
        self.stackView = UIStackView()
        self.stackView.alignment = .fill
        self.stackView.axis = .vertical
        self.stackView.spacing = 8
        self.stackView.distribution = .equalSpacing
    
        super.init(frame: frame)
        
        self.addSubview(self.titleLabel)
        self.addSubview(self.tipsLabel)
        self.addSubview(self.stackView)
        
        self.titleLabel.snp.makeConstraints { make in
            make.top.equalTo(0)
            make.leading.equalTo(20)
            make.trailing.lessThanOrEqualTo(-20)
        }
        
        self.tipsLabel.snp.makeConstraints { make in
            make.top.equalTo(self.titleLabel.snp.bottom).offset(5)
            make.leading.equalTo(20)
            make.trailing.lessThanOrEqualTo(-20)
        }
        
        self.stackView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(self.tipsLabel.snp.bottom).offset(20)
            make.leading.equalTo(20)
            make.bottom.equalTo(0)
        }
    }
    
    
    func reload(_ items: [StackItem]) {
        for subView in self.stackView.arrangedSubviews {
            subView.removeFromSuperview()
        }
        for item in items {
            let itemView = ItemView()
            itemView.reload(item)
            itemView.tap = {[weak self] item in
                self?.tap?(item)
            }
            self.stackView.addArrangedSubview(itemView)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private struct State:Equatable {
    var wallet: TBMyWalletModel
    var amount: String
    var stackItems: [StackItem]
    static func == (lhs: State, rhs: State) -> Bool {
        if lhs.wallet != rhs.wallet {
            return false
        }
        if lhs.amount != rhs.amount {
            return false
        }
        return true
    }
}

public class TBCreatWalletRetNodeView : UIView {

    public enum OutActionType {
        case copy(TBMyWalletModel)
        case backUpMnemonic(TBMyWalletModel)
        case exportPrivateKey(TBMyWalletModel)
        case returnHome
        case close
    }
    
    let context: AccountContext
    let params: TBCreatWalletRetController .Params
    weak var controller: TBCreatWalletRetController?
    var outAction:((OutActionType)->Void)?
    
    private let statePromise: ValuePromise<State>
    private let stateValue: Atomic<State>
    private let updateState: ((State) -> State) -> Void
    private var stateDisposable: Disposable?
    
    private let scrollView: UIScrollView
    private let contentView: UIView
    private let closeBtn: UIButton
    private let iconView: UIImageView
    private let titleLabel: UILabel
    private let cardView: CardView
    private let lineView: UIView
    private let stackView: StackView
    private let confirmBtn: UIButton
    
    init(context:AccountContext, controller:TBCreatWalletRetController ,  params: TBCreatWalletRetController .Params) {
        self.context = context
        self.params = params
        self.controller = controller
        let initialState = State(
            wallet: params.wallet,
            amount: "0.00TT",
            stackItems: [StackItem(icon: UIImage(bundleImageName: "TBMyWallet/ic_backup_mnemonic"), title: "", type: .backupMnemonic),
                         StackItem(icon: UIImage(bundleImageName: "TBMyWallet/ic_export_private_key"), title: "", type: .exportPrivateKey)]
        )
            
           
        let statePromise = ValuePromise(initialState, ignoreRepeated: true)
        let stateValue = Atomic(value: initialState)
        let updateState: ((State) -> State) -> Void = { f in
            statePromise.set(stateValue.modify { f($0) })
        }
        self.statePromise = statePromise
        self.stateValue = stateValue
        self.updateState = updateState
        
        self.scrollView = UIScrollView()
        self.scrollView.alwaysBounceVertical = true
        self.contentView = UIView()
        
        self.closeBtn = UIButton(type: .system)
        self.closeBtn.setImage(UIImage(bundleImageName: "TBMyWallet/icon_close_tg_rpofile_bg"), for: .normal)
        self.closeBtn.contentEdgeInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        
        self.iconView = UIImageView(image: UIImage(bundleImageName: "TBMyWallet/ic_succeed_mark"))
        
        self.titleLabel = UILabel()
        self.titleLabel.numberOfLines = 0
        self.titleLabel.textColor = UIColor(rgb: 0x000000)
        self.titleLabel.font = .systemFont(ofSize: 20, weight: .medium)
        self.titleLabel.text = ""
        
        self.cardView = CardView()
        
        self.lineView = UIView()
        self.lineView.backgroundColor = UIColor(rgb: 0xF7F8F9)
        
        self.stackView = StackView()
        
        self.confirmBtn = UIButton(type: .custom)
        self.confirmBtn.setTitle("", for: .normal)
        self.confirmBtn.backgroundColor = UIColor(rgb: 0x3954D5)
        self.confirmBtn.setTitleColor(.white, for: .normal)
        self.confirmBtn.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        self.confirmBtn.clipsToBounds = true
        self.confirmBtn.layer.cornerRadius = 25
        self.confirmBtn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 70, bottom: 0, right: 70)
        
        super.init(frame: .zero)
        self.backgroundColor = .white
        
        self.addSubview(self.scrollView)
        self.addSubview(self.confirmBtn)
        
        self.scrollView.addSubview(self.contentView)
        self.contentView.addSubview(self.closeBtn)
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.iconView)
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.cardView)
        self.contentView.addSubview(self.lineView)
        self.contentView.addSubview(self.stackView)
        
        self.confirmBtn.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.leading.equalTo(20)
            make.height.equalTo(50)
            make.bottom.equalTo(-24)
        }
        self.scrollView.snp.makeConstraints { make in
            make.top.equalTo(0)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(self.confirmBtn.snp.top).offset(-8)
        }
        self.contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(self)
        }
        
        self.closeBtn.snp.makeConstraints { make in
            make.top.trailing.equalTo(0)
            make.width.height.equalTo(24 + 16 * 2)
        }
        
        self.iconView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(90)
            make.width.height.equalTo(64)
        }

        self.titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(self.iconView.snp.bottom).offset(8)
            make.leading.greaterThanOrEqualTo(20)
        }
        
        self.cardView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(self.titleLabel.snp.bottom).offset(24)
            make.leading.equalTo(34)
        }
        self.lineView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(self.cardView.snp.bottom).offset(50)
            make.leading.equalTo(0)
            make.height.equalTo(12)
        }
        
        self.stackView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(self.lineView.snp.bottom).offset(24)
            make.leading.equalTo(0)
            make.bottom.equalTo(0)
        }
        
        self.closeBtn.addTarget(self, action: #selector(self.closeAction), for: .touchUpInside)
        self.confirmBtn.addTarget(self, action: #selector(self.returnFisrtPage), for: .touchUpInside)
        
        self.scrollView.delegate = self
        
        self.stateDisposable = (self.statePromise.get() |> deliverOnMainQueue).start(next: {
             [weak self] state in
            self?.reloadWithState(state)
        })
        
    }
    
    private func reloadWithState(_ state: State) {
        
        self.cardView.reload(wallet: state.wallet, amount: state.amount)
        self.cardView.tapCopy = { [weak self] in
            self?.outAction?(.copy(state.wallet))
        }
        self.stackView.reload(state.stackItems)
        self.stackView.tap = { [weak self] item in
            switch item.type {
            case .backupMnemonic:
                self?.outAction?(.backUpMnemonic(state.wallet))
            case .exportPrivateKey:
                self?.outAction?(.exportPrivateKey(state.wallet))
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        if let navigationLayout = self.controller?.navigationLayout(layout: layout) {
            let navigationHeight = navigationLayout.navigationFrame.maxY
            self.scrollView.snp.updateConstraints { make in
                make.top.equalTo(navigationHeight)
            }
        }
    }
    
    @objc private func returnFisrtPage() {
        self.outAction?(.returnHome)
    }
    
    @objc private func closeAction() {
        self.outAction?(.close)
    }

    
    deinit {
        self.stateDisposable?.dispose()
    }
    
}

extension TBCreatWalletRetNodeView : UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
    }
}


