import Foundation
import UIKit
import Postbox
import SwiftSignalKit
import AsyncDisplayKit
import Display
import TelegramCore
import TelegramPresentationData
import AnimationCache
import MultiAnimationRenderer
import AccountContext
import TBWeb3Core
import TBAccount
import TBLanguage
import TBWalletCore
import TBDisplay

extension TBWallet: NetworkItem {
    public func getIconName() -> String {
        return ""
    }
    
    public func getTitle() -> String {
        return self.walletName()
    }
    
    public func getArrowName() -> String? {
        return "TBMyWallet/icon_arrow"
    }
    
}


class TBRedEnvelopeNavNode: ASDisplayNode {
    private let context: AccountContext
    private var presentationData: PresentationData
    
    let walletNode: NetworkNode
    private let closeNode: ASButtonNode
    
    var closeEvent: (()->())?
    
    var wallet: NetworkItem = UnClearNetworkItem()
    
    init(context: AccountContext, presentationData: PresentationData) {
        self.context = context
        self.presentationData = presentationData
        
        self.walletNode = NetworkNode(context: context, presentationData: presentationData, config: NetworkNodeConfig(iconWidth: 0, titleFont: Font.bold(18), titleColor: UIColor(hexString: "#FF1A1A1D")!, arrowWidth: 16, margin: 0, space: 4))
        self.closeNode = ASButtonNode()
        
        super.init()
    }
    
    override func didLoad() {
        super.didLoad()
        
        self.addSubnode(self.walletNode)
        
        self.closeNode.addTarget(self, action: #selector(closeButtonClick(sender:)), forControlEvents: .touchUpInside)
        self.closeNode.setImage(UIImage(named: "Nav/nav_close_icon"), for: .normal)
        self.addSubnode(self.closeNode)
    }
    
    func update(size: CGSize, transition: ContainedViewLayoutTransition) {
        let width = self.walletNode.updateNetwork(self.wallet)
        transition.updateFrame(node: self.walletNode, frame: CGRect(x: 16, y: size.height - 43, width: width, height: 30))
        transition.updateFrame(node: self.closeNode, frame: CGRect(x: size.width - 44, y: size.height - 46, width: 36, height: 36))
        self.walletNode.update(size: CGSize(width: width, height: 30), transition: transition)
    }
    
    @objc func closeButtonClick(sender: UIButton) {
        self.closeEvent?()
    }
    
    func updateWallet(by wallet: NetworkItem) {
        self.wallet = wallet
        let width = self.walletNode.updateNetwork(wallet)
        if self.walletNode.frame != .zero {
            let size = CGSize(width: width, height: self.walletNode.frame.height)
            let transition = ContainedViewLayoutTransition.animated(duration: 0.2, curve: .spring)
            transition.updateFrame(node: self.walletNode, frame: CGRect(origin: self.walletNode.frame.origin, size: size))
            self.walletNode.update(size: size, transition: transition)
        }
    }
}

class CurrencyNode: ASDisplayNode {
    
    private let context: AccountContext
    private var presentationData: PresentationData
    
    let tokenNode: NetworkNode
    let amountTF: UITextField
    let bitInputPromise: ValuePromise<String>
    
    private var currentToken: NetworkItem = UnClearNetworkItem()
    var currencyClickEvent: (()->())?
    init(context: AccountContext, presentationData: PresentationData) {
        self.context = context
        self.presentationData = presentationData
        let config = NetworkNodeConfig(iconWidth: 20, titleFont: Font.medium(14), titleColor: UIColor(hexString: "#FF828283")!, margin: 8, space: 4)
        self.tokenNode = NetworkNode(context: context, presentationData: presentationData, config: config)
        self.amountTF = UITextField(frame: .zero)
        self.bitInputPromise = ValuePromise<String>(ignoreRepeated: true)
        super.init()
    }
    
    override func didLoad() {
        super.didLoad()
        self.tokenNode.cornerRadius = 8
        self.tokenNode.borderWidth = 1
        self.tokenNode.borderColor = UIColor(hexString: "#FFDCDDE0")!.cgColor
        self.addSubnode(self.tokenNode)
        self.tokenNode.titleClickEvent = {[weak self] in
            self?.currencyClickEvent?()
        }
        self.amountTF.keyboardType = .decimalPad
        self.amountTF.placeholder = ""
        self.amountTF.textAlignment = .right
        self.amountTF.font = Font.regular(15)
        self.amountTF.textColor = UIColor(hexString: "#FF000000")
        self.amountTF.delegate = self
        self.view.addSubview(self.amountTF)
    }
    
    func update(size: CGSize, transition: ContainedViewLayoutTransition) {
        let tokenWidth = self.tokenNode.updateNetwork(self.currentToken)
        transition.updateFrame(node: self.tokenNode, frame: CGRect(x: 16, y: (size.height - 36) / 2.0, width: tokenWidth, height: 36))
        self.tokenNode.update(size: CGSize(width: tokenWidth, height: 36), transition: transition)
        transition.updateFrame(view: self.amountTF, frame: CGRect(x: 16.0 + tokenWidth + 8, y: (size.height - 44) / 2.0, width: size.width - 32 - tokenWidth - 8, height: 44))
    }
    
    func updateCurrency(_ currency: NetworkItem?) {
        let item = currency ?? UnClearNetworkItem()
        self.currentToken = item
        let width = self.tokenNode.updateNetwork(item)
        if self.tokenNode.frame != .zero {
            let size = CGSize(width: width, height: self.tokenNode.frame.height)
            let transition = ContainedViewLayoutTransition.animated(duration: 0.2, curve: .spring)
            transition.updateFrame(node: self.tokenNode, frame: CGRect(origin: self.tokenNode.frame.origin, size: size))
            self.tokenNode.update(size: size, transition: transition)
        }
    }
}

extension CurrencyNode: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let text = textField.text, string == "." {
            if text.count == 0 || text.contains(".") {
                return false
            } else {
                let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
                self.bitInputPromise.set(text)
                return true
            }
        }
        let length = string.lengthOfBytes(using: String.Encoding.utf8)
        for index in 0..<length {
            let char = (string as NSString).character(at: index)
            if char < 48 || char > 57 {
                return false
            }
        }
        let zeroRange = ((textField.text ?? "") as NSString).range(of: "0")
        if zeroRange == NSRange(location: 0, length: 1) && 1 == textField.text?.count && string != "." {
            if string != "0" {
                textField.text = string
                self.bitInputPromise.set(string)
            }
            return false
        }
        let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
        self.bitInputPromise.set(text)
        return true
    }
}

class GasFeeNode: ASDisplayNode {
    private let context: AccountContext
    private var presentationData: PresentationData
    private let titleNode: ASTextNode
    private let desNode: ASTextNode
    
    init(context: AccountContext, presentationData: PresentationData) {
        self.context = context
        self.presentationData = presentationData
        self.titleNode = ASTextNode()
        self.desNode = ASTextNode()
        super.init()
    }
    
    override func didLoad() {
        super.didLoad()
        
        self.titleNode.attributedText = NSAttributedString(string: "Gasfee", font: Font.regular(14), textColor: UIColor(hexString: "#FF868686")!)
        self.addSubnode(self.titleNode)
        
        self.desNode.attributedText = NSAttributedString(string: "", font: Font.regular(14), textColor: UIColor(hexString: "#FF868686")!, paragraphAlignment: .right)
        self.addSubnode(self.desNode)
        
    }
    
    func update(size: CGSize, transition: ContainedViewLayoutTransition) {
        let titleSize = self.titleNode.updateLayout(CGSize(width: 150.0, height: .greatestFiniteMagnitude))
        transition.updateFrame(node: self.titleNode, frame: CGRect(x: 0, y: 2, width: titleSize.width, height: titleSize.height))
        let desSize = self.desNode.updateLayout(CGSize(width: 200.0, height: .greatestFiniteMagnitude))
        transition.updateFrame(node: self.desNode, frame: CGRect(x: size.width - desSize.width, y: 2, width: desSize.width, height: desSize.height))
    }
    
    func updateGas(by gasfeeType: GasfeeType) {
        switch gasfeeType {
        case .none:
            self.titleNode.attributedText = NSAttributedString(string: "Gasfee", font: Font.regular(14), textColor: UIColor(hexString: "#FF868686")!)
            self.desNode.attributedText = NSAttributedString(string: "", font: Font.regular(14), textColor: UIColor(hexString: "#FF868686")!, paragraphAlignment: .right)
        case .gas(let num, let price, let symbol):
            let title = "Gas fee*\(num)()"
            self.titleNode.attributedText = NSAttributedString(string: title, font: Font.regular(14), textColor: UIColor(hexString: "#FF868686")!)
            
            let total = NSDecimalNumber(string: price).multiplying(by: NSDecimalNumber(string: String(num))).description
            let des = "\(price)*\(num)=\(total)\(symbol)"
            self.desNode.attributedText = NSAttributedString(string: des, font: Font.regular(14), textColor: UIColor(hexString: "#FF868686")!, paragraphAlignment: .right)
            break
        }
        if self.titleNode.frame != .zero {
            let titleSize = self.titleNode.updateLayout(CGSize(width: 150.0, height: .greatestFiniteMagnitude))
            self.titleNode.frame = CGRect(origin: self.titleNode.frame.origin, size: titleSize)
        }
        if self.desNode.frame != .zero {
            let desSize = self.desNode.updateLayout(CGSize(width: 200.0, height: .greatestFiniteMagnitude))
            self.desNode.frame = CGRect(x: self.desNode.frame.minX - (desSize.width - self.desNode.frame.width), y: 2, width: desSize.width, height: desSize.height)
        }
    }
}

class RedEnvelopeAmountNode: ASDisplayNode {
    private let context: AccountContext
    private let titleNode: ASTextNode
    let amountTF: UITextField
    let amountInputPromise: ValuePromise<String>
    
    init(context: AccountContext) {
        self.context = context
        self.titleNode = ASTextNode()
        self.amountTF = UITextField(frame: .zero)
        self.amountInputPromise = ValuePromise<String>("0", ignoreRepeated: true)
        super.init()
    }
    
    override func didLoad() {
        super.didLoad()
        self.titleNode.attributedText = NSAttributedString(string: "", font: Font.medium(15), textColor: UIColor(hexString: "#FF333333")!)
        self.addSubnode(self.titleNode)
        
        self.amountTF.keyboardType = .numberPad
        self.amountTF.placeholder = ""
        self.amountTF.textAlignment = .right
        self.amountTF.font = Font.regular(15)
        self.amountTF.textColor = UIColor(hexString: "#FF000000")
        self.amountTF.delegate = self
        self.view.addSubview(self.amountTF)
    }
    
    func update(size: CGSize, transition: ContainedViewLayoutTransition) {
        let titleSize = self.titleNode.updateLayout(CGSize(width: 200.0, height: .greatestFiniteMagnitude))
        transition.updateFrame(node: self.titleNode, frame: CGRect(x: 16, y: (size.height - titleSize.height) / 2.0, width: titleSize.width, height: titleSize.height))
        transition.updateFrame(view: self.amountTF, frame: CGRect(x: 16.0 + titleSize.width + 8, y: (size.height - 44) / 2.0, width: size.width - 32 - titleSize.width - 8, height: 44))
    }
}

extension RedEnvelopeAmountNode: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let length = string.lengthOfBytes(using: String.Encoding.utf8)
        for index in 0..<length {
            let char = (string as NSString).character(at: index)
            if char < 48 || char > 57 {
                return false
            }
        }
        
        let zeroRange = ((textField.text ?? "") as NSString).range(of: "0")
        if zeroRange.length == 1 && zeroRange.location == 0 {
            if 1 == textField.text?.count && string != "0" {
                textField.text = string
                self.amountInputPromise.set(string)
            }
            return false
        }
        
        let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
        self.amountInputPromise.set(text)
        return true
    }
}



class TBRedEnvelopeControllerNode: ASDisplayNode {
    
    private let context: AccountContext
    private var presentationData: PresentationData
    private let isPersonnal: Bool
    
    let navNode: TBRedEnvelopeNavNode
    let lineNode: ASDisplayNode
    let networkNode: NetworkNode
    private var currentNetwork: NetworkItem = UnClearNetworkItem()
    let currencyNode: CurrencyNode
    let gasFeeNode: GasFeeNode
    let redEnvelopAmountNode: RedEnvelopeAmountNode
    
    private let sumCurrencyNode: ASTextNode
    private let sumMoneyNode: ASTextNode
    private let lackOfBalanceAlertNode: ASTextNode
    
    private let bottomNode: ASDisplayNode
    private let balanceNode: ASTextNode
    private let sendButtonNode: ASButtonNode
    
    var sendEvent: (() -> Void)?
    
    init(context: AccountContext, presentationData: PresentationData, isPersonnal: Bool) {
        self.context = context
        self.presentationData = presentationData
        self.isPersonnal = isPersonnal
        
        self.navNode = TBRedEnvelopeNavNode(context: context, presentationData: presentationData)
        self.lineNode = ASDisplayNode()
        let config = NetworkNodeConfig(iconWidth: 20, margin: 0, space: 4)
        self.networkNode = NetworkNode(context: context, presentationData: presentationData, config: config)
        self.currencyNode = CurrencyNode(context: context, presentationData: presentationData)
        self.gasFeeNode = GasFeeNode(context: context, presentationData: presentationData)
        self.redEnvelopAmountNode = RedEnvelopeAmountNode(context: context)
        
        self.sumCurrencyNode = ASTextNode()
        self.sumMoneyNode = ASTextNode()
        self.lackOfBalanceAlertNode = ASTextNode()
        
        self.bottomNode = ASDisplayNode()
        self.balanceNode = ASTextNode()
        self.sendButtonNode = ASButtonNode()
        
        super.init()
        
        self.backgroundColor = UIColor.white
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(noti:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHidden(noti:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func didLoad() {
        super.didLoad()
        
        self.navNode.backgroundColor = .white
        self.addSubnode(self.navNode)
        
        self.lineNode.backgroundColor = UIColor(hexString: "#FFE6E6E6")
        self.addSubnode(lineNode)
        
        self.addSubnode(self.networkNode)
        
        self.currencyNode.cornerRadius = 8
        self.currencyNode.borderColor = UIColor(hexString: "#FFDCDDE0")!.cgColor
        self.currencyNode.borderWidth = 1
        self.addSubnode(self.currencyNode)
        
        self.redEnvelopAmountNode.cornerRadius = 8
        self.redEnvelopAmountNode.borderColor = UIColor(hexString: "#FFE0E0E0")!.cgColor
        self.redEnvelopAmountNode.borderWidth = 1
        self.addSubnode(self.redEnvelopAmountNode)
        self.redEnvelopAmountNode.isHidden = self.isPersonnal
        
        self.addSubnode(self.gasFeeNode)
        
        self.addSubnode(self.sumCurrencyNode)
        self.addSubnode(self.sumMoneyNode)
        self.addSubnode(self.lackOfBalanceAlertNode)
        
        self.addSubnode(self.bottomNode)
        self.balanceNode.attributedText = NSAttributedString(string: "1234TT  $129.57", font: Font.regular(14), textColor: UIColor(hexString: "#FF868686")!, paragraphAlignment: .center)
        self.bottomNode.addSubnode(self.balanceNode)
        self.sendButtonNode.setTitle("", with: Font.medium(16), with: UIColor(hexString: "#FFFFDBBA")!, for: .normal)
        self.sendButtonNode.cornerRadius = 24
        self.sendButtonNode.backgroundColor = UIColor(hexString: "#FFFF2525")
        self.bottomNode.addSubnode(self.sendButtonNode)
        self.sendButtonNode.addTarget(self, action: #selector(sendButtonClickEvent(sender:)), forControlEvents: .touchUpInside)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(hiddenKeyBoard(tap:)))
        self.view.addGestureRecognizer(tap)
    }
    
    func update(layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        let navHeight = (layout.statusBarHeight ?? 20.0) + 44
        transition.updateFrame(node: self.navNode, frame: CGRect(x: 0, y: 0, width: layout.size.width, height: navHeight))
        self.navNode.update(size: CGSize(width: layout.size.width, height: navHeight), transition: transition)
        
        transition.updateFrame(node: self.lineNode, frame: CGRect(x: 0, y: navHeight, width: layout.size.width, height: 1))
        
        let networkWidth = self.networkNode.updateNetwork(self.currentNetwork)
        transition.updateFrame(node: self.networkNode, frame: CGRect(x: 16, y: navHeight + 10, width: networkWidth, height: 30))
        self.networkNode.update(size: CGSize(width: networkWidth, height: 30), transition: transition)
        
        transition.updateFrame(node: self.currencyNode, frame: CGRect(x: 16, y: navHeight + 52, width: layout.size.width - 32, height: 64))
        self.currencyNode.update(size: CGSize(width: layout.size.width - 32, height: 64), transition: transition)
        
        if !self.isPersonnal {
            transition.updateFrame(node: self.redEnvelopAmountNode, frame: CGRect(x: 16, y: navHeight + 128, width: layout.size.width - 32, height: 52))
            self.redEnvelopAmountNode.update(size: CGSize(width: layout.size.width - 32, height: 52), transition: transition)
            
            transition.updateFrame(node: self.gasFeeNode, frame: CGRect(x: 16, y: navHeight + 186, width: layout.size.width - 32, height: 20))
            self.gasFeeNode.update(size: CGSize(width: layout.size.width - 32, height: 20), transition: transition)
            
            transition.updateFrame(node: self.sumCurrencyNode, frame: CGRect(x: 16, y: navHeight + 257, width: layout.size.width - 32, height: 38))
            transition.updateFrame(node: self.sumMoneyNode, frame: CGRect(x: 16, y: navHeight + 295, width: layout.size.width - 32, height: 20))
            transition.updateFrame(node: self.lackOfBalanceAlertNode, frame: CGRect(x: 16, y: navHeight + 295, width: layout.size.width - 32, height: 20))
            
        } else {
            transition.updateFrame(node: self.gasFeeNode, frame: CGRect(x: 16, y: navHeight + 122, width: layout.size.width - 32, height: 20))
            self.gasFeeNode.update(size: CGSize(width: layout.size.width - 32, height: 20), transition: transition)
            
            transition.updateFrame(node: self.sumCurrencyNode, frame: CGRect(x: 16, y: navHeight + 187, width: layout.size.width - 32, height: 38))
            transition.updateFrame(node: self.sumMoneyNode, frame: CGRect(x: 16, y: navHeight + 225, width: layout.size.width - 32, height: 20))
            transition.updateFrame(node: self.lackOfBalanceAlertNode, frame: CGRect(x: 16, y: navHeight + 225, width: layout.size.width - 32, height: 20))
        }
        
        let bottom = layout.intrinsicInsets.bottom
        transition.updateFrame(node: self.bottomNode, frame: CGRect(x: 0, y: layout.size.height - bottom - 85, width: layout.size.width, height: 85))
        transition.updateFrame(node: self.balanceNode, frame: CGRect(x: 25, y: 6, width: layout.size.width - 50, height: 16))
        transition.updateFrame(node: self.sendButtonNode, frame: CGRect(x: 23, y: 30, width: layout.size.width - 46, height: 48))
    }
    
    func updateNetwork(_ chain: TBWeb3ConfigEntry.Chain?) {
        let networkItem: NetworkItem = chain ?? UnClearNetworkItem()
        self.currentNetwork = networkItem
        let width = self.networkNode.updateNetwork(networkItem)
        if self.networkNode.frame != .zero {
            let size = CGSize(width: width, height: self.networkNode.frame.height)
            let transition = ContainedViewLayoutTransition.animated(duration: 0.2, curve: .spring)
            transition.updateFrame(node: self.networkNode, frame: CGRect(origin: self.networkNode.frame.origin, size: size))
            self.networkNode.update(size: size, transition: transition)
        }
    }
    
    func updateSendButtonStatus(useAble: Bool) {
        self.sendButtonNode.alpha = useAble ? 1 : 0.6
        self.sendButtonNode.isEnabled = useAble
    }
    
    func endEdit() {
        self.redEnvelopAmountNode.amountTF.resignFirstResponder()
        self.currencyNode.amountTF.resignFirstResponder()
    }
    
    func cleanInput() {
        self.currencyNode.amountTF.text = ""
        self.currencyNode.bitInputPromise.set("")
        if !self.isPersonnal {
            self.redEnvelopAmountNode.amountTF.text = ""
            self.redEnvelopAmountNode.amountInputPromise.set("")
        }
    }
    
    func updateBalance(by balance: Balance) {
        switch balance {
        case .unowned:
            self.balanceNode.isHidden = true
        case let .valid(value):
            self.balanceNode.isHidden = false
            self.balanceNode.attributedText = NSAttributedString(string: TBLanguage.sharedInstance.localizable(TBLankey.chat_transfer_wallet_balance) + value, font: Font.regular(14), textColor: UIColor(hexString: "#FF56565C")!,paragraphAlignment: .center)
        }
    }
    
    func updateFromBalance(by type: BalanceType) {
        switch type {
        case .none:
            self.lackOfBalanceAlertNode.isHidden = true
            self.sumMoneyNode.isHidden = true
        case .lackOfBalance:
            self.lackOfBalanceAlertNode.isHidden = false
            self.sumMoneyNode.isHidden = true
            self.lackOfBalanceAlertNode.attributedText = NSAttributedString(string: TBLanguage.sharedInstance.localizable(TBLankey.chat_transfer_input_price_tips1), font: Font.regular(14), textColor: UIColor(hexString: "#FFFF4550")!, paragraphAlignment: .center)
        case let .input(value):
            self.lackOfBalanceAlertNode.isHidden = true
            self.sumMoneyNode.isHidden = false
            self.sumMoneyNode.attributedText = NSAttributedString(string: value, font: Font.regular(14), textColor: UIColor(hexString: "#FF868686")!, paragraphAlignment: .center)
        }
    }
    
    func updateSumTokens(_ symTokens: String) {
        self.sumCurrencyNode.attributedText = NSAttributedString(string: symTokens, font: Font.bold(32), textColor: UIColor(hexString: "#FF000000")!, paragraphAlignment: .center)
    }
    
    public func getInputText() -> String {
        return self.currencyNode.amountTF.text ?? "0"
    }
    
    @objc func sendButtonClickEvent(sender: UIButton) {
        self.sendEvent?()
    }
    
    @objc func hiddenKeyBoard(tap: UITapGestureRecognizer) {
        self.endEdit()
    }
    
    private var keyBoardHeight: CGFloat = 0.0
    private var keyBoardShow: Bool = false
    @objc func keyboardWillShow(noti: Notification) {
        if self.keyBoardShow { return }
        self.keyBoardShow = true
        let duration = noti.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as! TimeInterval
        let endY = (noti.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue.origin.y
        self.keyBoardHeight = UIScreen.main.bounds.height - endY
        let transition = ContainedViewLayoutTransition.animated(duration: duration, curve: .easeInOut)
        var frame = self.bottomNode.frame
        frame.origin.y -= self.keyBoardHeight
        transition.updateFrame(node: self.bottomNode, frame: frame)
    }
    
    @objc func keyboardWillHidden(noti: Notification) {
        if self.keyBoardShow == false { return }
        self.keyBoardShow = false
        let duration = noti.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as! TimeInterval
        let transition = ContainedViewLayoutTransition.animated(duration: duration, curve: .easeInOut)
        var frame = self.bottomNode.frame
        frame.origin.y += self.keyBoardHeight
        transition.updateFrame(node: self.bottomNode, frame: frame)
    }
}

enum Balance {
    case unowned
    case valid(value: String)
}

enum BalanceType {
    case none
    case lackOfBalance
    case input(value: String)
}


extension TBWeb3ConfigEntry.Chain: NetworkItem {
    public func getIconName() -> String {
        return self.icon
    }
    
    public func getTitle() -> String {
        return self.name
    }
}
