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
import ProgressHUD
import TBDisplay
import SwiftEntryKit
private struct TextItem: Equatable {
    let title: String
    let des: String
    
    static func == (lhs: TextItem, rhs: TextItem) -> Bool {
        if lhs.title != rhs.title {
            return false
        }
        if lhs.des != rhs.des {
            return false
        }
        return true
    }
}

private struct State:Equatable {
    
    var textItemList: [TextItem]
    var privateKey: String
    var wallet: TBWallet
    
    static func == (lhs: State, rhs: State) -> Bool {
        if lhs.textItemList != rhs.textItemList {
            return false
        }
        if lhs.privateKey != rhs.privateKey {
            return false
        }
        return true
    }
}


private class TextStackView: UIView {
    
    class ItemView: UIView {
        private let titleLabel: UILabel
        private let desLabel: UILabel
        
        override init(frame: CGRect) {
            
            self.titleLabel = UILabel()
            self.titleLabel.textColor = UIColor(rgb: 0x000000)
            self.titleLabel.font = .systemFont(ofSize: 14, weight: .bold)
            self.titleLabel.numberOfLines = 0
            
            self.desLabel = UILabel()
            self.desLabel.textColor = UIColor(rgb: 0x000000, alpha: 0.6)
            self.desLabel.font = .systemFont(ofSize: 14, weight: .regular)
            self.desLabel.numberOfLines = 0
            
            super.init(frame: frame)
            
            self.addSubview(self.titleLabel)
            self.addSubview(self.desLabel)
            self.titleLabel.snp.makeConstraints { make in
                make.top.leading.equalTo(0)
                make.trailing.lessThanOrEqualTo(0)
            }
            self.desLabel.snp.makeConstraints { make in
                make.top.equalTo(self.titleLabel.snp.bottom).offset(2)
                make.leading.equalTo(0)
                make.trailing.lessThanOrEqualTo(0)
                make.bottom.equalTo(0)
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func reload(_ item: TextItem) {
            self.titleLabel.text = item.title
            self.desLabel.text = item.des
        }
    }
    
    
    private let stackView: UIStackView
    
    override init(frame: CGRect) {
        self.stackView = UIStackView()
        self.stackView.axis = .vertical
        self.stackView.alignment = .fill
        self.stackView.distribution = .equalSpacing
        self.stackView.spacing = 20
        super.init(frame: frame)
        self.addSubview(self.stackView)
        self.stackView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
    }
    
    func reloadItemList(_ list: [TextItem]) {
        for subView in self.stackView.arrangedSubviews {
            subView.removeFromSuperview()
        }
        for item in list {
            let itemView = ItemView()
            itemView.reload(item)
            self.stackView.addArrangedSubview(itemView)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


public class TBExportPrivateKeyNodeView: UIView {
    
    let context: AccountContext
    let params: TBExportPrivateKeyController.Params
    weak var controller: TBExportPrivateKeyController?
    
    private let statePromise: ValuePromise<State>
    private let stateValue: Atomic<State>
    private let updateState: ((State) -> State) -> Void
    private var stateDisposable: Disposable?
    
    private let scrollView: UIScrollView
    private let contentView: UIView
    
    private let textStackView: TextStackView
    private let privateKeyLabel: UIButton
    private let confirmBtn: UIButton
    
    
    init(context:AccountContext, controller:TBExportPrivateKeyController,  params: TBExportPrivateKeyController.Params) {
        self.context = context
        self.params = params
        self.controller = controller
        let initialState = State(
            textItemList: [
                TextItem(title: "", des: ""),
                TextItem(title: "", des: ""),
                TextItem(title: "", des: "")
            ],
            privateKey: "",
            wallet: params.wallet
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
        
        self.textStackView = TextStackView()
        
        self.privateKeyLabel = UIButton(type: .custom)
        self.privateKeyLabel.setTitleColor(.black, for: .normal)
        self.privateKeyLabel.titleLabel?.font = .systemFont(ofSize: 15, weight: .regular)
        self.privateKeyLabel.titleLabel?.numberOfLines = 0
        self.privateKeyLabel.backgroundColor = UIColor(rgb: 0xF6F6F6)
        self.privateKeyLabel.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        self.privateKeyLabel.isUserInteractionEnabled = false
        self.privateKeyLabel.clipsToBounds = true
        self.privateKeyLabel.layer.cornerRadius = 12
        self.privateKeyLabel.layer.borderWidth = 1
        self.privateKeyLabel.layer.borderColor = UIColor(rgb: 0xD9D9D9).cgColor
        
        self.confirmBtn = UIButton(type: .custom)
        self.confirmBtn.setTitle(" Private Key", for: .normal)
        self.confirmBtn.backgroundColor = UIColor(rgb: 0x3954D5)
        self.confirmBtn.setTitleColor(.white, for: .normal)
        self.confirmBtn.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        self.confirmBtn.clipsToBounds = true
        self.confirmBtn.layer.cornerRadius = 24
        
        super.init(frame: .zero)
        self.backgroundColor = .white
        
        self.addSubview(self.scrollView)
        
        self.scrollView.addSubview(self.contentView)
        self.contentView.addSubview(self.textStackView)
        self.contentView.addSubview(self.privateKeyLabel)
        self.contentView.addSubview(self.confirmBtn)
        
        self.scrollView.snp.makeConstraints { make in
            make.top.equalTo(0)
            make.leading.trailing.bottom.equalToSuperview()
        }
        self.contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(self)
        }
        self.textStackView.snp.makeConstraints { make in
            make.top.equalTo(24)
            make.centerX.equalToSuperview()
            make.leading.equalTo(16)
        }
        self.privateKeyLabel.snp.makeConstraints { make in
            make.top.equalTo(self.textStackView.snp.bottom).offset(24)
            make.centerX.equalToSuperview()
            make.leading.equalTo(16)
            make.height.greaterThanOrEqualTo(150)
        }
        
        self.confirmBtn.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(self.privateKeyLabel.snp.bottom).offset(32)
            make.leading.equalTo(20)
            make.height.equalTo(48)
            make.bottom.equalToSuperview()
        }
        
        self.isUserInteractionEnabled = true
        
        self.scrollView.delegate = self
        self.confirmBtn.addTarget(self, action: #selector(self.confirmAction), for: .touchUpInside)
        
        switch self.params.wallet {
        case let .mine(myWallet):
            let entryView = TBEntryIndicatorView(status: .export_wallet_privateKey)
            SwiftEntryKit.display(entry: entryView, using: .tb_center_fade_alert_indicator)
            let _ = TBMyWalletManager.shared.exportPrivateKey(account: myWallet, password: TBMyWalletManager.password).start(next: {
                [weak self] privateKey in
                SwiftEntryKit.dismiss()
                if !privateKey.isEmpty {
                    self?.updateState{ current in
                        var current = current
                        current.privateKey = privateKey
                        return current
                    }
                }else{
                    self?.controller?.dismiss()
                }
            })
        case .connect:
            ProgressHUD.showFailed("")
        }
        
        
        self.stateDisposable = (self.statePromise.get() |> deliverOnMainQueue).start(next: {
             [weak self] state in
            self?.reloadWithState(state)
        })
        
    }
    
    private func reloadWithState(_ state: State) {
        
        self.textStackView.reloadItemList(state.textItemList)
        self.privateKeyLabel.setTitle(state.privateKey, for: .normal)
        
        if state.privateKey.isEmpty {
            self.confirmBtn.isUserInteractionEnabled = false
            self.confirmBtn.alpha = 0.5
        }else{
            self.confirmBtn.isUserInteractionEnabled = true
            self.confirmBtn.alpha = 1
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
    
    @objc private func confirmAction() {
        UIPasteboard.general.string = self.stateValue.with{$0.privateKey}
        ProgressHUD.showSucceed("")
    }
    
    deinit {
        self.stateDisposable?.dispose()
    }
    
}

extension TBExportPrivateKeyNodeView: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
    }
}

