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
    let attrTitle: NSAttributedString
    let attrDes: NSAttributedString
    static func == (lhs: TextItem, rhs: TextItem) -> Bool {
        if lhs.attrTitle != rhs.attrTitle {
            return false
        }
        if lhs.attrDes != rhs.attrDes {
            return false
        }
        return true
    }
}

private struct State:Equatable {
    
    var textItemList: [TextItem]
    var mnemonic: String
    var wallet: TBMyWalletModel
    
    static func == (lhs: State, rhs: State) -> Bool {
        if lhs.textItemList != rhs.textItemList {
            return false
        }
        if lhs.mnemonic != rhs.mnemonic {
            return false
        }
        if lhs.wallet != rhs.wallet {
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
            self.titleLabel.numberOfLines = 0
            
            self.desLabel = UILabel()
            self.desLabel.numberOfLines = 0
            
            super.init(frame: frame)
            
            self.addSubview(self.titleLabel)
            self.addSubview(self.desLabel)
            self.titleLabel.snp.makeConstraints { make in
                make.top.leading.equalTo(0)
                make.trailing.lessThanOrEqualTo(0)
            }
            self.desLabel.snp.makeConstraints { make in
                make.top.equalTo(self.titleLabel.snp.bottom).offset(6)
                make.leading.equalTo(0)
                make.trailing.lessThanOrEqualTo(0)
                make.bottom.equalTo(0)
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func reload(_ item: TextItem) {
            self.titleLabel.attributedText = item.attrTitle
            self.desLabel.attributedText = item.attrDes
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


public class TBStartBackUpMnemonicNodeView: UIView {
    
    enum OutActionType {
        case back
        case start
    }
    
    let context: AccountContext
    let params: TBStartBackUpMnemonicController.Params
    weak var controller: TBStartBackUpMnemonicController?
    var outAction:((OutActionType)->Void)?
    
    private let statePromise: ValuePromise<State>
    private let stateValue: Atomic<State>
    private let updateState: ((State) -> State) -> Void
    private var stateDisposable: Disposable?
    
    private let scrollView: UIScrollView
    private let contentView: UIView
    
    private let backButton: UIButton
    private let iconView: UIImageView
    private let textStackView: TextStackView
    private let confirmBtn: UIButton
    
    init(context:AccountContext, controller:TBStartBackUpMnemonicController,  params: TBStartBackUpMnemonicController.Params) {
        self.context = context
        self.params = params
        self.controller = controller
        let initialState = State(
            textItemList: [
                TextItem(attrTitle: NSAttributedString(string: "", font:.systemFont(ofSize: 20, weight: .medium), textColor: .black), attrDes: NSAttributedString(string: "12", font:.systemFont(ofSize: 14, weight: .regular), textColor: UIColor(rgb: 0x000000, alpha: 0.6))),
                TextItem(attrTitle: NSAttributedString(string: "", font:.systemFont(ofSize: 14, weight: .medium), textColor: .black), attrDes: NSAttributedString(string: "", font:.systemFont(ofSize: 14, weight: .regular), textColor: UIColor(rgb: 0x000000, alpha: 0.6))),
                TextItem(attrTitle: NSAttributedString(string: "", font:.systemFont(ofSize: 14, weight: .medium), textColor: .black), attrDes: NSAttributedString(string: " \n ", font:.systemFont(ofSize: 14, weight: .regular), textColor: UIColor(rgb: 0x000000, alpha: 0.6))),
            ],
            mnemonic: params.mnemonic,
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
        
        self.backButton = UIButton(type: .system)
        self.backButton.setImage(UIImage(bundleImageName: "TBMyWallet/ic_back")?.withRenderingMode(.alwaysOriginal), for: .normal)
        self.backButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        
        self.iconView = UIImageView(image: UIImage(bundleImageName: "TBMyWallet/ic_note"))
        
        self.textStackView = TextStackView()
        
        self.confirmBtn = UIButton(type: .custom)
        self.confirmBtn.setTitle("", for: .normal)
        self.confirmBtn.backgroundColor = UIColor(rgb: 0x3954D5)
        self.confirmBtn.setTitleColor(.white, for: .normal)
        self.confirmBtn.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        self.confirmBtn.clipsToBounds = true
        self.confirmBtn.layer.cornerRadius = 24
        
        super.init(frame: .zero)
        self.backgroundColor = .white
        self.addSubview(self.scrollView)
        self.addSubview(self.backButton)
        self.addSubview(self.confirmBtn)
        
        self.scrollView.addSubview(self.contentView)
        self.contentView.addSubview(self.iconView)
        self.contentView.addSubview(self.textStackView)
        
        self.confirmBtn.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.leading.equalTo(20)
            make.height.equalTo(48)
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
        self.backButton.snp.makeConstraints { make in
            make.leading.equalTo(0)
            make.top.equalTo(28)
            make.width.height.equalTo(24 + 12 * 2)
        }
        self.iconView.snp.makeConstraints { make in
            make.top.equalTo(88)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(184)
        }
        self.textStackView.snp.makeConstraints { make in
            make.top.equalTo(self.iconView.snp.bottom).offset(40)
            make.centerX.equalToSuperview()
            make.leading.equalTo(20)
        }
        
        self.scrollView.delegate = self
        self.confirmBtn.addTarget(self, action: #selector(self.confirmAction), for: .touchUpInside)
        self.backButton.addTarget(self, action: #selector(self.backAction), for: .touchUpInside)
        
        self.stateDisposable = (self.statePromise.get() |> deliverOnMainQueue).start(next: {
             [weak self] state in
            self?.reloadWithState(state)
        })
        
    }
    
    private func reloadWithState(_ state: State) {
        self.textStackView.reloadItemList(state.textItemList)
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
        self.outAction?(.start)
    }
    
    @objc private func backAction() {
        self.outAction?(.back)
    }
    
    deinit {
        self.stateDisposable?.dispose()
    }
    
}

extension TBStartBackUpMnemonicNodeView: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
    }
}

