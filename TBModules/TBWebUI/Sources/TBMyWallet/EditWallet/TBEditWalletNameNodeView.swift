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

private struct State:Equatable {
    
    var inputString: String
    var errorMessage:String
    var wallet: TBWallet

    static func == (lhs: State, rhs: State) -> Bool {
        if lhs.inputString != rhs.inputString {
            return false
        }
        if lhs.errorMessage != rhs.errorMessage {
            return false
        }
        if lhs.wallet != rhs.wallet {
            return false
        }
        return true
    }
    
    func updateInputString(_ string: String) -> State {
        var state = self
        state.inputString = string
        if string.count > 10 {
            state.errorMessage = ""
        }else{
            state.errorMessage = ""
        }
        return state
    }
    
    func isValid() -> Bool {
        if self.errorMessage.isEmpty && !self.inputString.isEmpty && self.inputString != self.wallet.walletName(){
            return true
        }
        return false
    }
}


private class InputView: UIView {
    
    let tipsLabel: UILabel
    let textField: UITextField
    let lineView: UIView
    init(context: AccountContext) {
        
        self.tipsLabel = UILabel()
        self.tipsLabel.numberOfLines = 1
        
        
        self.textField = UITextField()
        self.textField.textColor = .black
        self.textField.font = .systemFont(ofSize: 28, weight: .medium)
        self.textField.textAlignment = .center
        self.textField.borderStyle = .none
        self.textField.returnKeyType = .done
        
        self.lineView = UIView()
        self.lineView.backgroundColor = UIColor(rgb: 0xDCDDE0)
        
        super.init(frame: .zero)
        
        self.addSubview(self.tipsLabel)
        self.addSubview(self.textField)
        self.addSubview(self.lineView)
        
        self.tipsLabel.snp.makeConstraints { make in
            make.top.equalTo(0)
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualTo(12)
        }
        self.textField.snp.makeConstraints { make in
            make.top.equalTo(self.tipsLabel.snp.bottom).offset(15)
            make.leading.equalTo(12)
            make.centerX.equalToSuperview()
            make.height.equalTo(46)
        }
        
        self.lineView.snp.makeConstraints { make in
            make.top.equalTo(self.textField.snp.bottom).offset(0)
            make.leading.equalTo(40)
            make.centerX.equalToSuperview()
            make.height.equalTo(1)
            make.bottom.equalTo(0)
        }
        
    }
    
    func updateWithInputString(_ inputString: String, errorMessage: String, placeHolder:String) {
        self.textField.text = inputString
        if errorMessage.isEmpty {
            self.tipsLabel.attributedText = NSAttributedString(string: "", font: .systemFont(ofSize: 14, weight: .regular), textColor: UIColor(rgb: 0x56565C))
        }else{
            self.tipsLabel.attributedText = NSAttributedString(string: errorMessage, font: .systemFont(ofSize: 14, weight: .regular), textColor: UIColor(rgb: 0xFF4550))
        }
        self.textField.attributedPlaceholder = NSAttributedString(string: placeHolder, font: .systemFont(ofSize: 28, weight: .medium), textColor: UIColor(rgb: 0xE7E8EB))
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public class TBEditWalletNameNodeView: UIView {
    
    public enum OutActionType {
        case confirm(String)
    }
    
    let context: AccountContext
    let params: TBEditWalletNameController.Params
    weak var controller: TBEditWalletNameController?
    var outAction:((OutActionType)->Void)?
    
    private let statePromise: ValuePromise<State>
    private let stateValue: Atomic<State>
    private let updateState: ((State) -> State) -> Void
    private var stateDisposable: Disposable?
    
    private let scrollView: UIScrollView
    private let contentView: UIView
    
    private let userInputView: InputView
    private let confirmBtn: UIButton
    
    init(context:AccountContext, controller:TBEditWalletNameController,  params: TBEditWalletNameController.Params) {
        self.context = context
        self.params = params
        self.controller = controller
        let initialState = State(inputString: "", errorMessage: "", wallet: params.wallet)
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
        
        self.userInputView = InputView(context: context)
        
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
        
        self.scrollView.addSubview(self.contentView)
        self.contentView.addSubview(self.userInputView)
        self.contentView.addSubview(self.confirmBtn)
        
        self.scrollView.snp.makeConstraints { make in
            make.top.equalTo(0)
            make.leading.trailing.bottom.equalToSuperview()
        }
        self.contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(self)
        }
        self.userInputView.snp.makeConstraints { make in
            make.top.equalTo(76)
            make.centerX.equalToSuperview()
            make.leading.equalTo(0)
        }
        
        self.confirmBtn.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(self.userInputView.snp.bottom).offset(34)
            make.height.equalTo(50)
            make.bottom.equalToSuperview()
        }
        
        self.isUserInteractionEnabled = true
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tapAction)))
        
        self.scrollView.delegate = self
        self.confirmBtn.addTarget(self, action: #selector(self.confirmAction), for: .touchUpInside)
        
        self.userInputView.textField.delegate = self
        self.userInputView.textField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: .editingChanged)
        
        self.stateDisposable = (self.statePromise.get() |> deliverOnMainQueue).start(next: {
             [weak self] state in
            self?.reloadWithState(state)
        })
        
    }
    
    private func reloadWithState(_ state: State) {
        self.userInputView.updateWithInputString(state.inputString, errorMessage: state.errorMessage, placeHolder:state.wallet.walletName())
        if state.isValid() {
            self.confirmBtn.alpha = 1
            self.confirmBtn.isUserInteractionEnabled = true
        }else{
            self.confirmBtn.alpha = 0.5
            self.confirmBtn.isUserInteractionEnabled = false
            
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
        self.endEditing(true)
        let state = self.stateValue.with{$0}
        self.outAction?(.confirm(state.inputString))
    }
    
    @objc private func tapAction() {
        self.endEditing(true)
    }
    
    deinit {
        self.stateDisposable?.dispose()
    }
    
}

extension TBEditWalletNameNodeView: UITextFieldDelegate {
    
    @objc func textFieldDidChange(_ sender: UITextField) {
        self.updateState { current in
            return current.updateInputString(sender.text ?? "")
        }
    }
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return true
    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}

extension TBEditWalletNameNodeView: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
    }
}


