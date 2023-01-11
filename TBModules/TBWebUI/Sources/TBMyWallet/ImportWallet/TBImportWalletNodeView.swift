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

    static func == (lhs: State, rhs: State) -> Bool {
        if lhs.inputString != rhs.inputString {
            return false
        }
        if lhs.errorMessage != rhs.errorMessage {
            return false
        }
        return true
    }
    
    static func ret(_ inputString: String) -> TBImportWalletNodeView.InputData? {
        return TBImportWalletNodeView.InputData.transferFrom(inputString)
    }
    
    func ret() -> TBImportWalletNodeView.InputData? {
        return State.ret(self.inputString)
    }
    
    func updateInputString(_ string: String) -> State {
        var state = self
        state.inputString = string
        if let _ = state.ret() { 
            state.errorMessage = ""
        }else{
            if state.inputString.isEmpty { 
                state.errorMessage = ""
            }else{
                state.errorMessage = ""
            }
        }
        return state
    }
}

private class InputView: UIView {
    
    let textView: UITextView
    let qrBtn: UIButton
    let tempInputAccessoryView: UILabel
    
    init(context: AccountContext) {
        self.textView = UITextView()
        self.textView.textColor = .black
        self.textView.font = .systemFont(ofSize: 15, weight: .medium)
        self.textView.returnKeyType = .done
        
        let inputAccessoryView = UILabel()
        inputAccessoryView.backgroundColor = UIColor(rgb: 0xFFF5F5)
        inputAccessoryView.textAlignment = .center
        inputAccessoryView.textColor = UIColor(rgb: 0xFF4550)
        inputAccessoryView.font = .systemFont(ofSize: 15, weight: .medium)
        inputAccessoryView.frame = CGRect(origin: .zero, size: CGSize(width: UIScreen.main.bounds.width, height: 50))
        inputAccessoryView.isHidden = true
        self.textView.inputAccessoryView = inputAccessoryView
        self.tempInputAccessoryView = inputAccessoryView
        
        self.qrBtn = UIButton(type: .custom)
        self.qrBtn.setImage(UIImage(bundleImageName: "TBMyWallet/icon_scan_qrcode_wallet"), for: .normal)
        super.init(frame: .zero)
        
        self.addSubview(self.textView)
        self.addSubview(self.qrBtn)
        self.textView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.top.equalTo(16)
        }
        self.qrBtn.snp.makeConstraints { make in
            make.trailing.bottom.equalTo(-16)
            make.width.height.equalTo(33)
        }
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public class TBImportWalletNodeView: UIView {
    
    public enum InputData {
        case mnemonic(String)
        case privateKey(String)
        public static func transferFrom(_ string: String) -> InputData? {
            if string.tb_is_mnemonic() {
                return .mnemonic(string)
            }else if string.tb_is_privateKey(){
                return .privateKey(string)
            }else{
                return nil
            }
        }
    }
    
    public enum OutActionType {
        case confirm(TBImportWalletNodeView.InputData)
        case qrCode
    }
    
    public enum InActionType {
        case qr(String)
    }
    
    let context: AccountContext
    let params: TBImportWalletController.Params
    weak var controller: TBImportWalletController?
    var outAction:((OutActionType)->Void)?
    var inAction:((InActionType)->Void)?
    
    private let statePromise: ValuePromise<State>
    private let stateValue: Atomic<State>
    private let updateState: ((State) -> State) -> Void
    private var stateDisposable: Disposable?
    
    private let scrollView: UIScrollView
    private let contentView: UIView
    
    private let titleLabel: UILabel
    private let userInputView: InputView
    private let tipsIconView: UIImageView
    private let tipsLabel: UILabel
    private let confirmBtn: UIButton
    
    init(context:AccountContext, controller:TBImportWalletController,  params: TBImportWalletController.Params) {
        self.context = context
        self.params = params
        self.controller = controller
        let initialState = State(inputString: "", errorMessage: "")
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
        
        self.titleLabel = UILabel()
        self.titleLabel.numberOfLines = 0
        self.titleLabel.textColor = UIColor(rgb: 0x3954D5)
        self.titleLabel.font = .systemFont(ofSize: 15, weight: .regular)
        self.titleLabel.text = ""
        
        self.userInputView = InputView(context: context)
        self.userInputView.clipsToBounds = true
        self.userInputView.layer.cornerRadius = 10
        self.userInputView.layer.borderColor = UIColor(rgb: 0x3954D5).cgColor
        self.userInputView.layer.borderWidth = 1
        
        self.tipsIconView = UIImageView(image: UIImage(bundleImageName: "TBMyWallet/icon_info_circle_wallet"))
        
        self.tipsLabel = UILabel()
        self.tipsLabel.numberOfLines = 0
        self.tipsLabel.textColor = UIColor(rgb: 0x3954D5)
        self.tipsLabel.font = .systemFont(ofSize: 13, weight: .medium)
        self.tipsLabel.text = "alphagram"
        
        self.confirmBtn = UIButton(type: .custom)
        self.confirmBtn.setTitle("", for: .normal)
        self.confirmBtn.backgroundColor = UIColor(rgb: 0x3954D5)
        self.confirmBtn.setTitleColor(.white, for: .normal)
        self.confirmBtn.titleLabel?.font = .systemFont(ofSize: 19, weight: .medium)
        self.confirmBtn.clipsToBounds = true
        self.confirmBtn.layer.cornerRadius = 25
        
        super.init(frame: .zero)
        self.backgroundColor = .white
        
        self.addSubview(self.scrollView)
        
        self.scrollView.addSubview(self.contentView)
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.userInputView)
        self.contentView.addSubview(self.tipsIconView)
        self.contentView.addSubview(self.tipsLabel)
        self.contentView.addSubview(self.confirmBtn)
        
        self.scrollView.snp.makeConstraints { make in
            make.top.equalTo(0)
            make.leading.trailing.bottom.equalToSuperview()
        }
        self.contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(self)
        }
        self.titleLabel.snp.makeConstraints { make in
            make.top.equalTo(28)
            make.leading.equalTo(22)
            make.trailing.lessThanOrEqualTo(-22)
        }
        self.userInputView.snp.makeConstraints { make in
            make.top.equalTo(self.titleLabel.snp.bottom).offset(13)
            make.centerX.equalToSuperview()
            make.leading.equalTo(16)
            make.height.equalTo(150)
        }
        self.tipsIconView.snp.makeConstraints { make in
            make.top.equalTo(self.userInputView.snp.bottom).offset(50)
            make.leading.equalTo(16)
            make.width.height.equalTo(18)
        }
        self.tipsLabel.snp.makeConstraints { make in
            make.top.equalTo(self.tipsIconView)
            make.leading.equalTo(self.tipsIconView.snp.trailing).offset(8)
            make.trailing.equalTo(-16)
        }
        self.confirmBtn.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.greaterThanOrEqualTo(self.tipsLabel.snp.bottom).offset(12)
            make.top.greaterThanOrEqualTo(self.tipsIconView.snp.bottom).offset(12)
            make.leading.equalTo(18)
            make.height.equalTo(50)
            make.bottom.equalToSuperview()
        }
        
        self.isUserInteractionEnabled = true
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tapAction)))
        
        self.scrollView.delegate = self
        self.confirmBtn.addTarget(self, action: #selector(self.confirmAction), for: .touchUpInside)
        
        self.userInputView.textView.delegate = self
        self.userInputView.qrBtn.addTarget(self, action: #selector(self.qrBtnAction), for: .touchUpInside)
        
        self.stateDisposable = (self.statePromise.get() |> deliverOnMainQueue).start(next: {
             [weak self] state in
            self?.reloadWithState(state)
        })
        
    }
    
    private func reloadWithState(_ state: State) {
        if let _ = state.ret() {
            self.confirmBtn.isUserInteractionEnabled = true
            self.confirmBtn.alpha = 1
        }else{
            self.confirmBtn.isUserInteractionEnabled = false
            self.confirmBtn.alpha = 0.5
        }
        if state.errorMessage.isEmpty {
            self.userInputView.tempInputAccessoryView.isHidden = true
        }else{
            self.userInputView.tempInputAccessoryView.text = state.errorMessage
            self.userInputView.tempInputAccessoryView.isHidden = false
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
        if let inputData = state.ret(){
            self.outAction?(.confirm(inputData))
        }
        
    }
    
    @objc private func qrBtnAction() {
        self.endEditing(true)
        self.outAction?(.qrCode)
    }
    
    @objc private func tapAction() {
        self.endEditing(true)
    }
    
    deinit {
        self.stateDisposable?.dispose()
    }
    
}

extension TBImportWalletNodeView: UITextViewDelegate {
    public func textViewDidChange(_ textView: UITextView) {
        self.updateState { current in
            return current.updateInputString(textView.text ?? "")
        }
    }
    
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n"{
            Queue.mainQueue().async {
                textView.resignFirstResponder()
            }
            return false
        }
        return true
    }
    
    public func textViewDidEndEditing(_ textView: UITextView) {
        
    }
    
    public func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        return true
    }
}

extension TBImportWalletNodeView: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
    }
}


