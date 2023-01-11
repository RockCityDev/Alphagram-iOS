import Foundation
import UIKit
import AsyncDisplayKit
import Display
import TelegramCore
import TelegramPresentationData
import PhoneInputNode
import CountrySelectionUI
import QrCode
import SwiftSignalKit
import Postbox
import AccountContext
import AnimatedStickerNode
import TelegramAnimatedStickerNode
import SolidRoundedButtonNode
import AuthorizationUtils
import ManagedAnimationNode
import TBLanguage
import Display

private final class PhoneAndCountryNode: ASDisplayNode {
    let strings: PresentationStrings
    let countryButton: ASButtonNode
    let countryBackNode: ASDisplayNode
    let phoneBackground: ASImageNode
    let phoneDecoration:ASTextNode
    let phoneInputNode: PhoneInputNode
    
    var selectCountryCode: (() -> Void)?
    var checkPhone: (() -> Void)?
    var hasNumberUpdated: ((Bool) -> Void)?
    var keyPressed: ((Int) -> Void)?
    
    var preferredCountryIdForCode: [String: String] = [:]
    
    var hasCountry = false
    
    init(strings: PresentationStrings, theme: PresentationTheme) {
        self.strings = strings
        
        
        
        self.countryBackNode = ASDisplayNode()
        self.countryBackNode.layer.borderWidth = 1
        self.countryBackNode.layer.borderColor = UIColor(rgb:0xE0E0E0 ).cgColor
        self.countryBackNode.layer.cornerRadius = 7
        self.countryBackNode.backgroundColor = .white
        
        self.countryButton = ASButtonNode()
        self.countryButton.displaysAsynchronously = false
        
        self.countryButton.titleNode.maximumNumberOfLines = 1
        self.countryButton.titleNode.truncationMode = .byTruncatingTail
        
        
        self.phoneBackground = ASImageNode()
        
        self.phoneBackground.displaysAsynchronously = false
        self.phoneBackground.displayWithoutProcessing = true
        self.phoneBackground.isLayerBacked = true
        
        self.phoneBackground.layer.borderWidth = 1.5
        self.phoneBackground.layer.borderColor = UIColor(rgb: 0x03BDFF).cgColor
        self.phoneBackground.layer.cornerRadius = 7
        self.phoneBackground.layer.masksToBounds = true
        self.phoneBackground.backgroundColor = .white
        
        self.phoneDecoration = ASTextNode()
        self.phoneDecoration.textAlignment = .center
        self.phoneDecoration.backgroundColor = .white
        
        self.phoneDecoration.attributedText = NSAttributedString(string: TBLanguage.sharedInstance.localizable(TBLankey.login_phone_number), attributes: [.font:UIFont.systemFont(ofSize: 13, weight: .medium), .foregroundColor:UIColor(rgb: 0x03BDFF)])
        self.phoneDecoration.insets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        
        self.phoneInputNode = PhoneInputNode()
        
        super.init()
        
        self.addSubnode(self.countryBackNode)
        self.addSubnode(self.countryButton)
        
        self.addSubnode(self.phoneBackground)
        self.addSubnode(self.phoneDecoration)
        self.addSubnode(self.phoneInputNode)
        
        self.phoneInputNode.countryCodeField.textField.keyboardAppearance = theme.rootController.keyboardColor.keyboardAppearance
        self.phoneInputNode.numberField.textField.keyboardAppearance = theme.rootController.keyboardColor.keyboardAppearance
        self.phoneInputNode.countryCodeField.textField.textColor = theme.list.itemPrimaryTextColor
        self.phoneInputNode.numberField.textField.textColor = theme.list.itemPrimaryTextColor
        self.phoneInputNode.countryCodeField.textField.tintColor = theme.list.itemAccentColor
        self.phoneInputNode.numberField.textField.tintColor = theme.list.itemAccentColor
        
        self.phoneInputNode.countryCodeField.textField.tintColor = theme.list.itemAccentColor
        self.phoneInputNode.numberField.textField.tintColor = theme.list.itemAccentColor
        
        self.phoneInputNode.countryCodeField.textField.disableAutomaticKeyboardHandling = [.forward]
        self.phoneInputNode.numberField.textField.disableAutomaticKeyboardHandling = [.forward]
        
        
        
        self.countryButton.contentEdgeInsets = UIEdgeInsets(top: 0.0, left: 15.0, bottom: 0, right: 0.0)
        self.countryButton.contentHorizontalAlignment = .left
        
        self.countryButton.addTarget(self, action: #selector(self.countryPressed), forControlEvents: .touchUpInside)
        
        let processNumberChange: (String) -> Bool = { [weak self] number in
            guard let strongSelf = self else {
                return false
            }
            if let (country, _) = AuthorizationSequenceCountrySelectionController.lookupCountryIdByNumber(number, preferredCountries: strongSelf.preferredCountryIdForCode) {
                let flagString = emojiFlagForISOCountryCode(country.id)
                let localizedName: String = AuthorizationSequenceCountrySelectionController.lookupCountryNameById(country.id, strings: strongSelf.strings) ?? country.name
                strongSelf.countryButton.setTitle("\(flagString) \(localizedName)", with: Font.regular(20.0), with: theme.list.itemAccentColor, for: [])
                strongSelf.hasCountry = true
                
                let maskFont = Font.with(size: 20.0, design: .regular, traits: [.monospacedNumbers])
                if let mask = AuthorizationSequenceCountrySelectionController.lookupPatternByNumber(number, preferredCountries: strongSelf.preferredCountryIdForCode).flatMap({ NSAttributedString(string: $0, font: maskFont, textColor: theme.list.itemPlaceholderTextColor) }) {
                    strongSelf.phoneInputNode.numberField.textField.attributedPlaceholder = nil
                    strongSelf.phoneInputNode.mask = mask
                } else {
                    strongSelf.phoneInputNode.mask = nil
                    strongSelf.phoneInputNode.numberField.textField.attributedPlaceholder = NSAttributedString(string: strings.Login_PhonePlaceholder, font: Font.regular(20.0), textColor: theme.list.itemPlaceholderTextColor)
                }
                return true
            } else {
                return false
            }
        }
        
        self.phoneInputNode.numberTextUpdated = { [weak self] number in
            if let strongSelf = self {
                let _ = processNumberChange(strongSelf.phoneInputNode.number)
                                
                if strongSelf.hasCountry {
                    strongSelf.hasNumberUpdated?(!strongSelf.phoneInputNode.codeAndNumber.2.isEmpty)
                } else {
                    strongSelf.hasNumberUpdated?(false)
                }
            }
        }
        
        self.phoneInputNode.countryCodeUpdated = { [weak self] code, name in
            if let strongSelf = self {
                if let name = name {
                    strongSelf.preferredCountryIdForCode[code] = name
                }
                                
                if processNumberChange(strongSelf.phoneInputNode.number) {
                } else if let code = Int(code), let name = name, let countryName = countryCodeAndIdToName[CountryCodeAndId(code: code, id: name)] {
                    let flagString = emojiFlagForISOCountryCode(name)
                    let localizedName: String = AuthorizationSequenceCountrySelectionController.lookupCountryNameById(name, strings: strongSelf.strings) ?? countryName
                    strongSelf.countryButton.setTitle("\(flagString) \(localizedName)", with: Font.regular(20.0), with: theme.list.itemAccentColor, for: [])
                    strongSelf.hasCountry = true
                    
                    if strongSelf.phoneInputNode.mask == nil {
                        strongSelf.phoneInputNode.numberField.textField.attributedPlaceholder = NSAttributedString(string: strings.Login_PhonePlaceholder, font: Font.regular(20.0), textColor: theme.list.itemPlaceholderTextColor)
                    }
                } else if let code = Int(code), let (countryId, countryName) = countryCodeToIdAndName[code] {
                    let flagString = emojiFlagForISOCountryCode(countryId)
                    let localizedName: String = AuthorizationSequenceCountrySelectionController.lookupCountryNameById(countryId, strings: strongSelf.strings) ?? countryName
                    strongSelf.countryButton.setTitle("\(flagString) \(localizedName)", with: Font.regular(20.0), with: theme.list.itemAccentColor, for: [])
                    strongSelf.hasCountry = true
                    
                    if strongSelf.phoneInputNode.mask == nil {
                        strongSelf.phoneInputNode.numberField.textField.attributedPlaceholder = NSAttributedString(string: strings.Login_PhonePlaceholder, font: Font.regular(20.0), textColor: theme.list.itemPlaceholderTextColor)
                    }
                } else {
                    strongSelf.hasCountry = false
                    strongSelf.countryButton.setTitle(TBLanguage.sharedInstance.localizable(TBLankey.login_selectCountryArea_title), with: Font.regular(20.0), with: theme.list.itemPlaceholderTextColor, for: [])
                    strongSelf.phoneInputNode.mask = nil
                    strongSelf.phoneInputNode.numberField.textField.attributedPlaceholder = NSAttributedString(string: strings.Login_PhonePlaceholder, font: Font.regular(20.0), textColor: theme.list.itemPlaceholderTextColor)
                }
                
                if strongSelf.hasCountry {
                    strongSelf.hasNumberUpdated?(!strongSelf.phoneInputNode.codeAndNumber.2.isEmpty)
                } else {
                    strongSelf.hasNumberUpdated?(false)
                }
            }
        }
        
        self.phoneInputNode.customFormatter = { number in
            if let (_, code) = AuthorizationSequenceCountrySelectionController.lookupCountryIdByNumber(number, preferredCountries: [:]) {
                return code.code
            } else {
                return nil
            }
        }
        
        self.phoneInputNode.number = "+1"
        self.phoneInputNode.returnAction = { [weak self] in
            self?.checkPhone?()
        }
        
        self.phoneInputNode.keyPressed = { [weak self] num in
            self?.keyPressed?(num)
        }
    }
    
    @objc func countryPressed() {
        self.selectCountryCode?()
    }
    
    override func layout() {
        super.layout()
        
        let size = self.bounds.size
        
        self.countryButton.frame = CGRect(origin: CGPoint(x: 37.0, y: 0), size: CGSize(width: size.width - 37 * 2, height: 54.0))
        self.countryBackNode.frame = self.countryButton.frame
        
        self.phoneBackground.frame = CGRect(origin: CGPoint(x: 37.0, y: size.height - 54.0), size: CGSize(width: size.width - 37.0 * 2, height: 54.0))
        let phoneDecorationSize = self.phoneDecoration.measure(CGSize(width: size.width, height: CGFloat.greatestFiniteMagnitude))
        
        self.phoneDecoration.frame = CGRect(x: self.phoneBackground.frame.minX + 11, y: self.phoneBackground.frame.minY - phoneDecorationSize.height / 2 , width: phoneDecorationSize.width, height: phoneDecorationSize.height)
        
        let countryCodeFrame = CGRect(origin: CGPoint(x: 34.0, y: self.phoneBackground.frame.minY), size: CGSize(width: 71.0, height: 54.0))
        let numberFrame = CGRect(origin: CGPoint(x: 107.0, y: countryCodeFrame.minY), size: CGSize(width: size.width - 96.0 - 8.0, height: 54.0))
        let placeholderFrame = numberFrame.offsetBy(dx: 0.0, dy: 16.0)
        let phoneInputFrame = countryCodeFrame.union(numberFrame)
        
        self.phoneInputNode.frame = phoneInputFrame
        self.phoneInputNode.countryCodeField.frame = countryCodeFrame.offsetBy(dx: -phoneInputFrame.minX, dy: -phoneInputFrame.minY)
        self.phoneInputNode.numberField.frame = numberFrame.offsetBy(dx: -phoneInputFrame.minX, dy: -phoneInputFrame.minY)
        self.phoneInputNode.placeholderNode.frame = placeholderFrame.offsetBy(dx: -phoneInputFrame.minX, dy: -phoneInputFrame.minY)
    }
}

private final class BotTokenLoginNode: ASDisplayNode {
    private let botTokenNode: ASButtonNode
    var tapAction :(()->Void)?
    init(strings: PresentationStrings, theme: PresentationTheme) {
        self.botTokenNode = ASButtonNode()
        self.botTokenNode.titleNode.textAlignment = .center
        self.botTokenNode.titleNode.maximumNumberOfLines = 1
        self.botTokenNode.contentEdgeInsets = UIEdgeInsets(top: 15, left: 37, bottom: 15, right: 37)
        self.botTokenNode.setAttributedTitle(NSAttributedString(string: TBLanguage.sharedInstance.localizable(TBLankey.bot_token_login_text), attributes: [.foregroundColor: UIColor(rgb: 0x03BDFF), .font: UIFont.systemFont(ofSize: 13, weight: .medium)]), for: [])
        
        
        
        super.init()
        self.botTokenNode.addTarget(self, action: #selector(self.tapBotTokenLoginAction), forControlEvents: .touchUpInside)
        self.addSubnode(self.botTokenNode)

    }
    
    override func layout() {
        super.layout()
        let size = self.bounds.size
        
        let botTokonSize = self.botTokenNode.measure(CGSize(width: size.width, height: CGFloat.greatestFiniteMagnitude))
        self.botTokenNode.frame = CGRect(x: 0, y: 0, width: botTokonSize.width, height: botTokonSize.height)
    }
    
    @objc private func tapBotTokenLoginAction() {
        self.tapAction?()
        debugPrint("[TB]: tapBotTokenLoginAction")
    }
}

private final class ContactSyncNode: ASDisplayNode {
    private let titleNode: ImmediateTextNode
    let switchNode: SwitchNode
    
    init(theme: PresentationTheme, strings: PresentationStrings) {
        self.titleNode = ImmediateTextNode()
        self.titleNode.maximumNumberOfLines = 1
        self.titleNode.attributedText = NSAttributedString(string: strings.Privacy_ContactsSync, font: Font.regular(17.0), textColor: theme.list.itemPrimaryTextColor)
        self.switchNode = SwitchNode()
        self.switchNode.frameColor = theme.list.itemSwitchColors.frameColor
        self.switchNode.contentColor = theme.list.itemSwitchColors.contentColor
        self.switchNode.handleColor = theme.list.itemSwitchColors.handleColor
        self.switchNode.isOn = true
        
        super.init()
        
        self.addSubnode(self.titleNode)
        self.addSubnode(self.switchNode)
    }
    
    func updateLayout(width: CGFloat) -> CGSize {
        let switchSize = CGSize(width: 51.0, height: 31.0)
        let inset: CGFloat = 24.0
        let titleSize = self.titleNode.updateLayout(CGSize(width: width - switchSize.width - inset * 2.0 - 8.0, height: .greatestFiniteMagnitude))
        let height: CGFloat = 40.0
        self.titleNode.frame = CGRect(origin: CGPoint(x: inset, y: floor((height - titleSize.height) / 2.0)), size: titleSize)
        self.switchNode.frame = CGRect(origin: CGPoint(x: width - inset - switchSize.width, y: floor((height - switchSize.height) / 2.0)), size: switchSize)
        return CGSize(width: width, height: height)
    }
}

private final class SettingNode : ASDisplayNode {
    let settingView: TBAuthorizationSequenceSettingView
    
    init(theme: PresentationTheme, strings: PresentationStrings) {
        self.settingView = TBAuthorizationSequenceSettingView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        super.init()
    }
    
    override func layout() {
        super.layout()
        self.settingView.frame = self.bounds
    }

    override func didLoad() {
        super.didLoad()
        self.view.addSubview(self.settingView)
    }
}

private final class LanguageNode : ASDisplayNode {
    let settingView: TBAuthorizationSequenceLanguageView
    
    init(theme: PresentationTheme, strings: PresentationStrings) {
        self.settingView = TBAuthorizationSequenceLanguageView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        super.init()
        self.settingView.selectLan = { item in
            TBLanguage.sharedInstance.setLanguage(language:item.data.lanCode)
        }
    }
    
    override func layout() {
        super.layout()
        self.settingView.frame = self.bounds
    }

    override func didLoad() {
        super.didLoad()
        self.view.addSubview(self.settingView)
    }
}

extension UIImage {
    func supposedSizeWithFixWidth(_ fixWidth: CGFloat) -> CGSize {
        guard self.size.width > 0 else {
            return CGSize(width: fixWidth, height: self.size.height)
        }
        let h = self.size.height * (fixWidth / self.size.width)
        return CGSize(width: fixWidth, height: h)
    }
    func supposedSizeWithFixHeight(_ fixHeight: CGFloat) -> CGSize {
        guard self.size.height > 0 else {
            return CGSize(width: self.size.width, height: fixHeight)
        }
        let w = self.size.width * (fixHeight / self.size.height)
        return CGSize(width: w, height: fixHeight)
    }
}

final class AuthorizationSequencePhoneEntryControllerNode: ASDisplayNode, UIGestureRecognizerDelegate {
    public weak var navigationBar:NavigationBar?
    private var tapGes: UITapGestureRecognizer?
    private let sharedContext: SharedAccountContext
    private var account: UnauthorizedAccount
    private let strings: PresentationStrings
    private let theme: PresentationTheme
    private let hasOtherAccounts: Bool
    
    private let scrollNode: ASScrollNode
    private let animationNode: AnimatedStickerNode
    private let managedAnimationNode: ManagedPhoneAnimationNode
    private let loginBgNode: ASImageNode
    private let titleNode: ASTextNode
    private let noticeNode: ASTextNode
    private let phoneAndCountryNode: PhoneAndCountryNode
    private let botTokenLoginNode: BotTokenLoginNode
    private let contactSyncNode: ContactSyncNode
    private let settingNode: SettingNode
    private let languageNode: LanguageNode
    private let proceedNode: SolidRoundedButtonNode
    
    private var qrNode: ASImageNode?
    private let exportTokenDisposable = MetaDisposable()
    private let tokenEventsDisposable = MetaDisposable()
    var accountUpdated: ((UnauthorizedAccount) -> Void)?
    
    private let debugAction: () -> Void
    
    var currentNumber: String {
        return self.phoneAndCountryNode.phoneInputNode.number
    }
    
    var codeAndNumber: (Int32?, String?, String) {
        get {
            return self.phoneAndCountryNode.phoneInputNode.codeAndNumber
        } set(value) {
            self.phoneAndCountryNode.phoneInputNode.codeAndNumber = value
        }
    }
    
    var formattedCodeAndNumber: (String, String) {
        return self.phoneAndCountryNode.phoneInputNode.formattedCodeAndNumber
    }
    
    var syncContacts: Bool {
        get {
            if self.hasOtherAccounts {
                return self.contactSyncNode.switchNode.isOn
            } else {
                return true
            }
        }
    }
    
    var selectCountryCode: (() -> Void)?
    var checkPhone: (() -> Void)?
    
    var inProgress: Bool = false {
        didSet {
            self.phoneAndCountryNode.phoneInputNode.enableEditing = !self.inProgress
            self.phoneAndCountryNode.phoneInputNode.alpha = self.inProgress ? 0.6 : 1.0
            self.phoneAndCountryNode.countryButton.isEnabled = !self.inProgress
            
            if self.inProgress != oldValue {
                if self.inProgress {
                    self.proceedNode.transitionToProgress()
                } else {
                    self.proceedNode.transitionFromProgress()
                }
            }
        }
    }
    
    var codeNode: ASDisplayNode {
        return self.phoneAndCountryNode.phoneInputNode.countryCodeField
    }
    
    var numberNode: ASDisplayNode {
        return self.phoneAndCountryNode.phoneInputNode.numberField
    }
    
    var buttonNode: ASDisplayNode {
        return self.proceedNode
    }
    
    init(sharedContext: SharedAccountContext, account: UnauthorizedAccount, strings: PresentationStrings, theme: PresentationTheme, debugAction: @escaping () -> Void, hasOtherAccounts: Bool) {
        self.sharedContext = sharedContext
        self.account = account
        
        self.strings = strings
        self.theme = theme
        self.debugAction = debugAction
        self.hasOtherAccounts = hasOtherAccounts
        
        self.scrollNode = ASScrollNode()
        self.scrollNode.view.showsVerticalScrollIndicator = true
        self.scrollNode.view.showsHorizontalScrollIndicator = false
        self.scrollNode.view.scrollsToTop = true
        self.scrollNode.view.delaysContentTouches = false
        self.scrollNode.view.canCancelContentTouches = true
        if #available(iOS 11.0, *) {
            self.scrollNode.view.contentInsetAdjustmentBehavior = .never
        }
        
        self.loginBgNode = ASImageNode()
        self.loginBgNode.image = UIImage(named: "Login/image_bg_login")
        self.loginBgNode.isUserInteractionEnabled = true
        
        self.animationNode = DefaultAnimatedStickerNodeImpl()
        self.animationNode.setup(source: AnimatedStickerNodeLocalFileSource(name: "IntroPhone"), width: 256, height: 256, playbackMode: .once, mode: .direct(cachePathPrefix: nil))
        
        self.managedAnimationNode = ManagedPhoneAnimationNode()
        self.managedAnimationNode.isHidden = true
        
        self.titleNode = ASTextNode()
        self.titleNode.isUserInteractionEnabled = true
        self.titleNode.displaysAsynchronously = false
        self.titleNode.attributedText = NSAttributedString(string: strings.Login_PhoneTitle, font: Font.light(30.0), textColor: theme.list.itemPrimaryTextColor)
        
        self.noticeNode = ASTextNode()
        self.noticeNode.maximumNumberOfLines = 0
        self.noticeNode.isUserInteractionEnabled = true
        self.noticeNode.displaysAsynchronously = false
        
        self.noticeNode.attributedText = NSAttributedString(string:TBLanguage.sharedInstance.localizable(TBLankey.login_phone_view_subtitle) , font: UIFont.systemFont(ofSize: 13, weight: .medium), textColor: UIColor(rgb: 0x868686), paragraphAlignment: .center)
        
        self.phoneAndCountryNode = PhoneAndCountryNode(strings: strings, theme: theme)
        
        self.botTokenLoginNode = BotTokenLoginNode(strings: strings, theme: theme)
        
        self.contactSyncNode = ContactSyncNode(theme: theme, strings: strings)
        
        self.settingNode = SettingNode(theme: theme, strings: strings)
    
        self.languageNode = LanguageNode(theme: theme, strings: strings)
        
        self.proceedNode = SolidRoundedButtonNode(title: self.strings.Login_Continue, theme: SolidRoundedButtonTheme(theme: self.theme), height: 50.0, cornerRadius: 11.0, gloss: false)
        self.proceedNode.progressType = .embedded
        self.proceedNode.isEnabled = false
        
        super.init()
        
        self.setViewBlock({
            return UITracingLayerView()
        })
        
        self.backgroundColor = theme.list.plainBackgroundColor
        
        self.addSubnode(self.scrollNode)
        self.scrollNode.addSubnode(self.loginBgNode)
        self.scrollNode.addSubnode(self.titleNode)
        self.scrollNode.addSubnode(self.noticeNode)
        self.scrollNode.addSubnode(self.phoneAndCountryNode)
        self.scrollNode.addSubnode(self.botTokenLoginNode)
        self.scrollNode.addSubnode(self.settingNode)
        self.scrollNode.addSubnode(self.languageNode)
        self.scrollNode.addSubnode(self.contactSyncNode)
        self.scrollNode.addSubnode(self.proceedNode)
        self.scrollNode.addSubnode(self.animationNode)
        self.scrollNode.addSubnode(self.managedAnimationNode)
        self.contactSyncNode.isHidden = true
        
        self.phoneAndCountryNode.selectCountryCode = { [weak self] in
            self?.selectCountryCode?()
        }
        self.phoneAndCountryNode.checkPhone = { [weak self] in
            self?.checkPhone?()
        }
        self.phoneAndCountryNode.hasNumberUpdated = { [weak self] hasNumber in
            self?.proceedNode.isEnabled = hasNumber
        }
        self.phoneAndCountryNode.keyPressed = { [weak self] num in
            if let strongSelf = self, !strongSelf.managedAnimationNode.isHidden {
                strongSelf.managedAnimationNode.animate(num: num)
            }
        }
        
        self.tokenEventsDisposable.set((account.updateLoginTokenEvents
        |> deliverOnMainQueue).start(next: { [weak self] _ in
            self?.refreshQrToken()
        }))
        
        self.proceedNode.pressed = { [weak self] in
            self?.checkPhone?()
        }
        
        self.animationNode.completed = { [weak self] _ in
            self?.animationNode.removeFromSupernode()
            self?.managedAnimationNode.isHidden = false
        }
    }
    
    deinit {
        self.exportTokenDisposable.dispose()
        self.tokenEventsDisposable.dispose()
    }
    
    override func didLoad() {
        super.didLoad()
        
        
        #if DEBUG
        
        #endif
        
        
        let tapGes = UITapGestureRecognizer(target: self, action: #selector(self.tapNode))
        tapGes.delegate = self
        self.view.addGestureRecognizer(tapGes)
        self.tapGes = tapGes
    }
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let tapGes = self.tapGes, let bar = self.navigationBar  {
            if tapGes.isEqual(gestureRecognizer) {
                let point = gestureRecognizer.location(in: gestureRecognizer.view)
                if bar.frame.contains(point){
                    return false
                }
            }
        }
        return true
    }
    
    @objc func tapNode() {
        self.phoneAndCountryNode.phoneInputNode.numberField.textField.resignFirstResponder()
    }
    
    private var animationSnapshotView: UIView?
    private var textSnapshotView: UIView?
    private var forcedButtonFrame: CGRect?
    
    func willAnimateIn(buttonFrame: CGRect, buttonTitle: String, animationSnapshot: UIView, textSnapshot: UIView) {
        self.proceedNode.frame = buttonFrame
        
        self.proceedNode.isEnabled = true
        self.proceedNode.title = buttonTitle
        
        self.animationSnapshotView = animationSnapshot
        self.view.insertSubview(animationSnapshot, at: 0)
        
        self.textSnapshotView = textSnapshot
        self.view.insertSubview(textSnapshot, at: 0)
        
        let nodes: [ASDisplayNode] = [
            self.animationNode,
            self.titleNode,
            self.noticeNode,
            self.phoneAndCountryNode,
            self.contactSyncNode
        ]

        for node in nodes {
            node.alpha = 0.0
        }
    }
    
    func animateIn(buttonFrame: CGRect, buttonTitle: String, animationSnapshot: UIView, textSnapshot: UIView) {
        self.proceedNode.animateTitle(to: self.strings.Login_Continue)
                
        self.animationSnapshotView?.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.2, removeOnCompletion: false, completion: { [weak self] _ in
            self?.animationSnapshotView?.removeFromSuperview()
            self?.animationSnapshotView = nil
        })
        self.animationSnapshotView?.layer.animatePosition(from: CGPoint(), to: CGPoint(x: 0.0, y: -100.0), duration: 0.3, timingFunction: kCAMediaTimingFunctionSpring, removeOnCompletion: false, additive: true)
        self.animationSnapshotView?.layer.animateScale(from: 1.0, to: 0.3, duration: 0.4)
       
        self.textSnapshotView?.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.2, removeOnCompletion: false, completion: { [weak self] _ in
            self?.textSnapshotView?.removeFromSuperview()
            self?.textSnapshotView = nil
        })
        self.textSnapshotView?.layer.animatePosition(from: CGPoint(), to: CGPoint(x: 0.0, y: -140.0), duration: 0.3, timingFunction: kCAMediaTimingFunctionSpring, removeOnCompletion: false, additive: true)
    
        let nodes: [ASDisplayNode] = [
            self.animationNode,
            self.titleNode,
            self.noticeNode,
            self.phoneAndCountryNode,
            self.contactSyncNode
        ]
        
        self.animationNode.layer.animateScale(from: 0.3, to: 1.0, duration: 0.3)

        for node in nodes {
            node.alpha = 1.0
            node.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.3)
        }
    }
    
    func updateCountryCode() {
        self.phoneAndCountryNode.phoneInputNode.codeAndNumber = self.codeAndNumber
    }
    
    func containerLayoutUpdated(_ layout: ContainerViewLayout, navigationBarHeight: CGFloat, transition: ContainedViewLayoutTransition) {
        
        self.scrollNode.view.scrollIndicatorInsets = UIEdgeInsets(top: navigationBarHeight, left: 0.0, bottom: 0.0, right: 0.0)
        
        let scrollNodeFrame: CGRect
        if let inputHeight = layout.inputHeight {
            scrollNodeFrame = CGRect(origin: CGPoint(), size: CGSizeMake(layout.size.width, layout.size.height - inputHeight))
        }else{
            scrollNodeFrame = CGRect(origin: CGPoint(), size:layout.size)
        }
        transition.updateFrame(node: self.scrollNode, frame: scrollNodeFrame)
        
        var insets = layout.insets(options: [])
        insets.top = layout.statusBarHeight ?? 20.0
        
        let bgSize = self.loginBgNode.image!.supposedSizeWithFixWidth(layout.size.width)
        self.loginBgNode.frame = CGRect(x: 0, y: 0, width: bgSize.width, height: bgSize.height)
        



        
        
        let titleInset: CGFloat = layout.size.width > 320.0 && false ? 18.0 : 0.0
        
        let additionalBottomInset: CGFloat = layout.size.width > 320.0 && false ? 80.0 : 10.0
        
        let tii = TBLanguage.sharedInstance.localizable(TBLankey.login_phone_view_title)
        self.titleNode.attributedText = NSAttributedString(string:tii, font: UIFont.systemFont(ofSize: 18, weight: .medium), textColor: UIColor(rgb: 0x000000))
        
        let inset: CGFloat = 24.0
        
        let animationSize = CGSize(width: 100.0, height: 100.0)
        let titleSize = self.titleNode.measure(CGSize(width: layout.size.width, height: CGFloat.greatestFiniteMagnitude))
        let noticeSize = self.noticeNode.measure(CGSize(width: min(274.0, layout.size.width - 28.0), height: CGFloat.greatestFiniteMagnitude))
        let proceedHeight = self.proceedNode.updateLayout(width: layout.size.width - inset * 2.0, transition: transition)
        let proceedSize = CGSize(width: layout.size.width - inset * 2.0, height: proceedHeight)
        
        let languageHeight =  CGFloat(TBLanguage.sharedInstance.supportLanguages.count) * 48.0 + 14.0 + 25.0
        
        var items: [AuthorizationLayoutItem] = [
            AuthorizationLayoutItem(node: self.titleNode, size: titleSize, spacingBefore: AuthorizationLayoutItemSpacing(weight: titleInset, maxValue: titleInset), spacingAfter: AuthorizationLayoutItemSpacing(weight: 0.0, maxValue: 0.0)),
            AuthorizationLayoutItem(node: self.noticeNode, size: noticeSize, spacingBefore: AuthorizationLayoutItemSpacing(weight: 12.0, maxValue: 12.0), spacingAfter: AuthorizationLayoutItemSpacing(weight: 0.0, maxValue: 0.0)),
            AuthorizationLayoutItem(node: self.phoneAndCountryNode, size: CGSize(width: layout.size.width, height: 54 + 25 + (7 + 54)), spacingBefore: AuthorizationLayoutItemSpacing(weight: 35.0, maxValue: 35.0), spacingAfter: AuthorizationLayoutItemSpacing(weight: 0.0, maxValue: 0.0)),
            AuthorizationLayoutItem(node: self.botTokenLoginNode, size:CGSize(width: layout.size.width, height: 48), spacingBefore: AuthorizationLayoutItemSpacing(weight: 0, maxValue: 0), spacingAfter: AuthorizationLayoutItemSpacing(weight: 0.0, maxValue: 0.0)),
            AuthorizationLayoutItem(node: self.settingNode, size:CGSize(width: layout.size.width, height: 68 * 2), spacingBefore: AuthorizationLayoutItemSpacing(weight: 8, maxValue: 8), spacingAfter: AuthorizationLayoutItemSpacing(weight: 0.0, maxValue: 0.0)),
            AuthorizationLayoutItem(node: self.languageNode, size: CGSize(width: layout.size.width, height: languageHeight), spacingBefore: AuthorizationLayoutItemSpacing(weight: 0, maxValue: 0), spacingAfter: AuthorizationLayoutItemSpacing(weight: 0.0, maxValue: 0.0))
        ]
        
        
        if layout.size.width > 320.0 && false {
            items.insert(AuthorizationLayoutItem(node: self.animationNode, size: animationSize, spacingBefore: AuthorizationLayoutItemSpacing(weight: 10.0, maxValue: 10.0), spacingAfter: AuthorizationLayoutItemSpacing(weight: 0.0, maxValue: 0.0)), at: 0)
            self.proceedNode.isHidden = false
            self.animationNode.isHidden = false
            self.animationNode.visibility = true
        } else {
            insets.top = navigationBarHeight
            self.proceedNode.isHidden = true
            self.animationNode.isHidden = true
            self.managedAnimationNode.isHidden = true
        }
        
        let contactSyncSize = self.contactSyncNode.updateLayout(width: layout.size.width)
        if self.hasOtherAccounts {
            self.contactSyncNode.isHidden = false
            items.append(AuthorizationLayoutItem(node: self.contactSyncNode, size: contactSyncSize, spacingBefore: AuthorizationLayoutItemSpacing(weight: 14.0, maxValue: 14.0), spacingAfter: AuthorizationLayoutItemSpacing(weight: 0.0, maxValue: 0.0)))
        } else {
            self.contactSyncNode.isHidden = true
        }
        
        let buttonFrame: CGRect
        if let forcedButtonFrame = self.forcedButtonFrame, (layout.inputHeight ?? 0.0).isZero {
            buttonFrame = forcedButtonFrame
        } else {
            buttonFrame = CGRect(origin: CGPoint(x: floorToScreenPixels((layout.size.width - proceedSize.width) / 2.0), y: layout.size.height - insets.bottom - proceedSize.height - inset), size: proceedSize)
        }
        
        transition.updateFrame(node: self.proceedNode, frame: buttonFrame)
        
        self.animationNode.updateLayout(size: animationSize)
        
        
        var contentHeight = layoutAuthorizationItemsFromTop(bounds: CGRect(origin: CGPoint(x: 0.0, y: insets.top), size: CGSize(width: layout.size.width, height: layout.size.height - insets.top - insets.bottom - additionalBottomInset)), items: items, transition: transition)
        
        if let inputheight = layout.inputHeight, !inputheight.isZero {
            contentHeight += 0
        }else{
            contentHeight += layout.intrinsicInsets.bottom
        }
        self.scrollNode.view.contentSize = CGSize(width: layout.size.width, height: contentHeight)
        transition.updateFrame(node: self.managedAnimationNode, frame: self.animationNode.frame)
    }
    
    func activateInput() {
        self.phoneAndCountryNode.phoneInputNode.numberField.textField.becomeFirstResponder()
    }
    
    func animateError() {
        self.phoneAndCountryNode.phoneInputNode.countryCodeField.layer.addShakeAnimation()
        self.phoneAndCountryNode.phoneInputNode.numberField.layer.addShakeAnimation()
    }
    
    private var debugTapCounter: (Double, Int) = (0.0, 0)
    @objc private func debugTap(_ recognizer: UITapGestureRecognizer) {
        if case .ended = recognizer.state {
            let timestamp = CACurrentMediaTime()
            if self.debugTapCounter.0 < timestamp - 0.4 {
                self.debugTapCounter.0 = timestamp
                self.debugTapCounter.1 = 0
            }
            
            if self.debugTapCounter.0 >= timestamp - 0.4 {
                self.debugTapCounter.0 = timestamp
                self.debugTapCounter.1 += 1
            }
            
            if self.debugTapCounter.1 >= 10 {
                self.debugTapCounter.1 = 0
                
                self.debugAction()
            }
        }
    }
    
    @objc private func debugQrTap(_ recognizer: UITapGestureRecognizer) {
        if self.qrNode == nil {
            let qrNode = ASImageNode()
            qrNode.frame = CGRect(origin: CGPoint(x: 16.0, y: 64.0 + 16.0), size: CGSize(width: 200.0, height: 200.0))
            self.qrNode = qrNode
            self.addSubnode(qrNode)
            
            self.refreshQrToken()
        }
    }
    
    private func refreshQrToken() {
        let sharedContext = self.sharedContext
        let account = self.account
        let tokenSignal = sharedContext.activeAccountContexts
        |> castError(ExportAuthTransferTokenError.self)
        |> take(1)
        |> mapToSignal { activeAccountsAndInfo -> Signal<ExportAuthTransferTokenResult, ExportAuthTransferTokenError> in
            let (_, activeAccounts, _) = activeAccountsAndInfo
            let activeProductionUserIds = activeAccounts.map({ $0.1.account }).filter({ !$0.testingEnvironment }).map({ $0.peerId.id })
            let activeTestingUserIds = activeAccounts.map({ $0.1.account }).filter({ $0.testingEnvironment }).map({ $0.peerId.id })
            
            let allProductionUserIds = activeProductionUserIds
            let allTestingUserIds = activeTestingUserIds
            
            return TelegramEngineUnauthorized(account: account).auth.exportAuthTransferToken(accountManager: sharedContext.accountManager, otherAccountUserIds: account.testingEnvironment ? allTestingUserIds : allProductionUserIds, syncContacts: true)
        }
        
        self.exportTokenDisposable.set((tokenSignal
        |> deliverOnMainQueue).start(next: { [weak self] result in
            guard let strongSelf = self else {
                return
            }
            switch result {
            case let .displayToken(token):
                var tokenString = token.value.base64EncodedString()
                print("export token \(tokenString)")
                tokenString = tokenString.replacingOccurrences(of: "+", with: "-")
                tokenString = tokenString.replacingOccurrences(of: "/", with: "_")
                let urlString = "tg://login?token=\(tokenString)"
                let _ = (qrCode(string: urlString, color: .black, backgroundColor: .white, icon: .none)
                |> deliverOnMainQueue).start(next: { _, generate in
                    guard let strongSelf = self else {
                        return
                    }
                    
                    let context = generate(TransformImageArguments(corners: ImageCorners(), imageSize: CGSize(width: 200.0, height: 200.0), boundingSize: CGSize(width: 200.0, height: 200.0), intrinsicInsets: UIEdgeInsets()))
                    if let image = context?.generateImage() {
                        strongSelf.qrNode?.image = image
                    }
                })
                
                let timestamp = Int32(Date().timeIntervalSince1970)
                let timeout = max(5, token.validUntil - timestamp)
                strongSelf.exportTokenDisposable.set((Signal<Never, NoError>.complete()
                |> delay(Double(timeout), queue: .mainQueue())).start(completed: {
                    guard let strongSelf = self else {
                        return
                    }
                    strongSelf.refreshQrToken()
                }))
            case let .changeAccountAndRetry(account):
                strongSelf.exportTokenDisposable.set(nil)
                strongSelf.account = account
                strongSelf.accountUpdated?(account)
                strongSelf.tokenEventsDisposable.set((account.updateLoginTokenEvents
                |> deliverOnMainQueue).start(next: { _ in
                    self?.refreshQrToken()
                }))
                strongSelf.refreshQrToken()
            case .loggedIn, .passwordRequested:
                strongSelf.exportTokenDisposable.set(nil)
            }
        }))
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let phoneRect = CGRectInset(self.phoneAndCountryNode.frame, 0, 0)
        if CGRectContainsPoint(phoneRect, point) {
            self.view.endEditing(true)
        }
        return super.hitTest(point, with: event)
    }
}

final class PhoneConfirmationController: ViewController {
    private var controllerNode: Node {
        return self.displayNode as! Node
    }
    
    private let theme: PresentationTheme
    private let strings: PresentationStrings
    private let code: String
    private let number: String
    private weak var sourceController: AuthorizationSequencePhoneEntryController?
    
    var inProgress: Bool = false {
        didSet {
            if self.inProgress != oldValue {
                if self.inProgress {
                    self.controllerNode.proceedNode.transitionToProgress()
                } else {
                    self.controllerNode.proceedNode.transitionFromProgress()
                }
            }
        }
    }
    
    var proceed: () -> Void = {}
    
    class Node: ASDisplayNode {
        private let theme: PresentationTheme
        
        private let code: String
        private let number: String
        
        private let dimNode: ASDisplayNode
        private let backgroundNode: ASDisplayNode
        
        private let codeSourceNode: ImmediateTextNode
        private let phoneSourceNode: ImmediateTextNode
        
        private let codeTargetNode: ImmediateTextNode
        private let phoneTargetNode: ImmediateTextNode
        
        private let textNode: ImmediateTextNode
        
        private let cancelButton: HighlightableButtonNode
        fileprivate let proceedNode: SolidRoundedButtonNode
        
        var proceed: () -> Void = {}
        var cancel: () -> Void = {}
        
        private var validLayout: ContainerViewLayout?
        
        init(theme: PresentationTheme, strings: PresentationStrings, code: String, number: String) {
            self.theme = theme
            
            self.code = code
            self.number = number
            
            self.dimNode = ASDisplayNode()
            self.dimNode.backgroundColor = UIColor(white: 0.0, alpha: 0.4)
            
            self.backgroundNode = ASDisplayNode()
            self.backgroundNode.backgroundColor = theme.list.plainBackgroundColor
            self.backgroundNode.cornerRadius = 11.0
            
            self.textNode = ImmediateTextNode()
            self.textNode.displaysAsynchronously = false
            self.textNode.attributedText = NSAttributedString(string: strings.Login_PhoneNumberConfirmation, font: Font.regular(17.0), textColor: theme.list.itemPrimaryTextColor)
            self.textNode.textAlignment = .center
            
            self.cancelButton = HighlightableButtonNode()
            self.cancelButton.setTitle(strings.Login_Edit, with: Font.regular(19.0), with: theme.list.itemAccentColor, for: .normal)
            
            self.proceedNode = SolidRoundedButtonNode(title: strings.Login_Continue, theme: SolidRoundedButtonTheme(theme: theme), height: 50.0, cornerRadius: 11.0, gloss: false)
            self.proceedNode.progressType = .embedded
            
            let font = Font.with(size: 20.0, design: .regular, traits: [.monospacedNumbers])
            let largeFont = Font.with(size: 34.0, design: .regular, weight: .bold, traits: [.monospacedNumbers])
            
            self.codeSourceNode = ImmediateTextNode()
            self.codeSourceNode.alpha = 0.0
            self.codeSourceNode.displaysAsynchronously = false
            self.codeSourceNode.attributedText = NSAttributedString(string: code, font: font, textColor: theme.list.itemPrimaryTextColor)
            
            self.phoneSourceNode = ImmediateTextNode()
            self.phoneSourceNode.alpha = 0.0
            self.phoneSourceNode.displaysAsynchronously = false
            
            let sourceString = NSMutableAttributedString(string: number, font: font, textColor: theme.list.itemPrimaryTextColor)
            sourceString.addAttribute(NSAttributedString.Key.kern, value: 1.6, range: NSRange(location: 0, length: sourceString.length))
            self.phoneSourceNode.attributedText = sourceString
            
            self.codeTargetNode = ImmediateTextNode()
            self.codeTargetNode.displaysAsynchronously = false
            self.codeTargetNode.attributedText = NSAttributedString(string: code, font: largeFont, textColor: theme.list.itemPrimaryTextColor)
            
            self.phoneTargetNode = ImmediateTextNode()
            self.phoneTargetNode.displaysAsynchronously = false
            
            let targetString = NSMutableAttributedString(string: number, font: largeFont, textColor: theme.list.itemPrimaryTextColor)
            targetString.addAttribute(NSAttributedString.Key.kern, value: 1.6, range: NSRange(location: 0, length: sourceString.length))
            self.phoneTargetNode.attributedText = targetString
            
            super.init()
            
            self.clipsToBounds = false
            
            self.addSubnode(self.dimNode)
            self.addSubnode(self.backgroundNode)
            
            self.addSubnode(self.codeSourceNode)
            self.addSubnode(self.phoneSourceNode)
            
            self.addSubnode(self.codeTargetNode)
            self.addSubnode(self.phoneTargetNode)
            
            self.addSubnode(self.textNode)
            
            self.addSubnode(self.cancelButton)
            self.addSubnode(self.proceedNode)
            
            self.cancelButton.addTarget(self, action: #selector(self.cancelPressed), forControlEvents: .touchUpInside)
            self.proceedNode.pressed = { [weak self] in
                self?.proceed()
            }
        }
        
        override func didLoad() {
            super.didLoad()
            
            self.dimNode.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.dimTapped)))
        }
        
        @objc private func dimTapped() {
            self.cancelPressed()
        }
        
        @objc private func cancelPressed() {
            self.dimNode.isUserInteractionEnabled = false
            self.cancel()
        }
        
        func animateIn(codeNode: ASDisplayNode, numberNode: ASDisplayNode, buttonNode: ASDisplayNode) {
            guard let layout = self.validLayout else {
                return
            }
            let codeFrame = codeNode.convert(codeNode.bounds, to: nil)
            let numberFrame = numberNode.convert(numberNode.bounds, to: nil)
            let buttonFrame = buttonNode.convert(buttonNode.bounds, to: nil)
            
            codeNode.isHidden = true
            numberNode.isHidden = true
            buttonNode.isHidden = true
            
            self.dimNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.3)
            
            let duration: Double = 0.25
            
            let codeSize = self.codeSourceNode.updateLayout(layout.size)
            self.codeSourceNode.frame = CGRect(origin: CGPoint(x: codeFrame.midX - codeSize.width / 2.0, y: codeFrame.midY - codeSize.height / 2.0), size: codeSize)
            
            let numberSize = self.phoneSourceNode.updateLayout(layout.size)
            self.phoneSourceNode.frame = CGRect(origin: CGPoint(x: numberFrame.minX, y: numberFrame.midY - numberSize.height / 2.0), size: numberSize)
            
            let targetScale = codeSize.height / self.codeTargetNode.frame.height
            let sourceScale = self.codeTargetNode.frame.height / codeSize.height
            
            self.codeSourceNode.layer.animateScale(from: 1.0, to: sourceScale, duration: duration)
            self.codeSourceNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: duration)
            self.codeSourceNode.layer.animatePosition(from: self.codeSourceNode.position, to: self.codeTargetNode.position, duration: duration)
            
            self.phoneSourceNode.layer.animateScale(from: 1.0, to: sourceScale, duration: duration)
            self.phoneSourceNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: duration)
            self.phoneSourceNode.layer.animatePosition(from: self.phoneSourceNode.position, to: self.phoneTargetNode.position, duration: duration)
            
            self.codeTargetNode.layer.animateScale(from: targetScale, to: 1.0, duration: duration)
            self.codeTargetNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: duration)
            self.codeTargetNode.layer.animatePosition(from: self.codeSourceNode.position, to: self.codeTargetNode.position, duration: duration)
            
            self.phoneTargetNode.layer.animateScale(from: targetScale, to: 1.0, duration: duration)
            self.phoneTargetNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: duration)
            self.phoneTargetNode.layer.animatePosition(from: self.phoneSourceNode.position, to: self.phoneTargetNode.position, duration: duration)
            
            self.backgroundNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.1)
            self.backgroundNode.layer.animateFrame(from: CGRect(origin: CGPoint(x: 14.0, y: codeFrame.minY), size: CGSize(width: self.backgroundNode.frame.width - 12.0, height: buttonFrame.maxY + 18.0 - codeFrame.minY)), to: self.backgroundNode.frame, duration: duration)
            
            self.textNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: duration)
            self.textNode.layer.animateScale(from: 0.5, to: 1.0, duration: duration)
            self.textNode.layer.animatePosition(from: CGPoint(x: -100.0, y: -45.0), to: CGPoint(), duration: duration, additive: true)
            
            self.cancelButton.layer.animateAlpha(from: 0.0, to: 1.0, duration: duration)
            self.cancelButton.layer.animateScale(from: 0.5, to: 1.0, duration: duration)
            self.cancelButton.layer.animatePosition(from: CGPoint(x: -100.0, y: -70.0), to: CGPoint(), duration: duration, additive: true)
            
            self.proceedNode.layer.animatePosition(from: buttonFrame.center, to: self.proceedNode.position, duration: duration)
        }
        
        func animateOut(codeNode: ASDisplayNode, numberNode: ASDisplayNode, buttonNode: ASDisplayNode, completion: @escaping () -> Void) {
            let codeFrame = codeNode.convert(codeNode.bounds, to: nil)
            let numberFrame = numberNode.convert(numberNode.bounds, to: nil)
            let buttonFrame = buttonNode.convert(buttonNode.bounds, to: nil)
            
            self.dimNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.2, removeOnCompletion: false)
            
            let duration: Double = 0.25
            
            let codeSize = self.codeSourceNode.updateLayout(self.frame.size)
            self.codeSourceNode.frame = CGRect(origin: CGPoint(x: codeFrame.midX - codeSize.width / 2.0, y: codeFrame.midY - codeSize.height / 2.0), size: codeSize)
            
            let numberSize = self.phoneSourceNode.updateLayout(self.frame.size)
            self.phoneSourceNode.frame = CGRect(origin: CGPoint(x: numberFrame.minX, y: numberFrame.midY - numberSize.height / 2.0), size: numberSize)
            
            let targetScale = codeSize.height / self.codeTargetNode.frame.height
            let sourceScale = self.codeTargetNode.frame.height / codeSize.height
            
            self.codeSourceNode.layer.animateScale(from: sourceScale, to: 1.0, duration: duration)
            self.codeSourceNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: duration)
            self.codeSourceNode.layer.animatePosition(from: self.codeTargetNode.position, to: self.codeSourceNode.position, duration: duration)
            
            self.phoneSourceNode.layer.animateScale(from: sourceScale, to: 1.0, duration: duration)
            self.phoneSourceNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: duration)
            self.phoneSourceNode.layer.animatePosition(from: self.phoneTargetNode.position, to: self.phoneSourceNode.position, duration: duration)
            
            self.codeTargetNode.layer.animateScale(from: 1.0, to: targetScale, duration: duration)
            self.codeTargetNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: duration, removeOnCompletion: false)
            self.codeTargetNode.layer.animatePosition(from: self.codeTargetNode.position, to: self.codeSourceNode.position, duration: duration)
            
            Queue.mainQueue().after(0.2) {
                codeNode.isHidden = false
                numberNode.isHidden = false
                buttonNode.isHidden = false
            }
            
            self.phoneTargetNode.layer.animateScale(from: 1.0, to: targetScale, duration: duration)
            self.phoneTargetNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: duration, removeOnCompletion: false, completion: { _ in
                completion()
            })
            self.phoneTargetNode.layer.animatePosition(from: self.phoneTargetNode.position, to: self.phoneSourceNode.position, duration: duration)
            
            self.backgroundNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.2, delay: 0.1, removeOnCompletion: false)
            self.backgroundNode.layer.animateFrame(from: self.backgroundNode.frame, to: CGRect(origin: CGPoint(x: 14.0, y: codeFrame.minY), size: CGSize(width: self.backgroundNode.frame.width - 12.0, height: buttonFrame.maxY + 18.0 - codeFrame.minY)), duration: duration)
                        
            self.textNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.2, removeOnCompletion: false)
            self.textNode.layer.animateScale(from: 1.0, to: 0.5, duration: duration, removeOnCompletion: false)
            self.textNode.layer.animatePosition(from: CGPoint(), to: CGPoint(x: -100.0, y: -45.0), duration: duration, removeOnCompletion: false, additive: true)
            
            self.cancelButton.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.2, removeOnCompletion: false)
            self.cancelButton.layer.animateScale(from: 1.0, to: 0.5, duration: duration, removeOnCompletion: false)
            self.cancelButton.layer.animatePosition(from: CGPoint(), to: CGPoint(x: -100.0, y: -70.0), duration: duration, removeOnCompletion: false, additive: true)
            
            self.proceedNode.layer.animatePosition(from: self.proceedNode.position, to: buttonFrame.center, duration: duration, removeOnCompletion: false)
        }
        
        func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
            let hadLayout = self.validLayout != nil
            self.validLayout = layout
            
            let sideInset: CGFloat = 8.0
            let innerInset: CGFloat = 18.0
            
            transition.updateFrame(node: self.dimNode, frame: CGRect(origin: CGPoint(x: -layout.size.width, y: 0.0), size: CGSize(width: layout.size.width * 3.0, height: layout.size.height)))
            
            let backgroundSize = CGSize(width: layout.size.width - sideInset * 2.0, height: 243.0)
            let backgroundFrame = CGRect(origin: CGPoint(x: floorToScreenPixels((layout.size.width - backgroundSize.width) / 2.0), y: layout.size.height - backgroundSize.height - 260.0), size: backgroundSize)
            transition.updateFrame(node: self.backgroundNode, frame: backgroundFrame)
              
            let maxWidth = layout.size.width - 20.0
            if !hadLayout {
                var fontSize = 34.0
                if layout.size.width < 375.0 {
                    fontSize = 30.0
                }
              
                let largeFont = Font.with(size: fontSize, design: .regular, weight: .bold, traits: [.monospacedNumbers])
                
                self.codeTargetNode.attributedText = NSAttributedString(string: self.code, font: largeFont, textColor: self.theme.list.itemPrimaryTextColor)
                let targetString = NSMutableAttributedString(string: self.number, font: largeFont, textColor: self.theme.list.itemPrimaryTextColor)
                targetString.addAttribute(NSAttributedString.Key.kern, value: 1.6, range: NSRange(location: 0, length: targetString.length))
                self.phoneTargetNode.attributedText = targetString
            }
            
            let spacing: CGFloat = 10.0
            
            let codeSize = self.codeTargetNode.updateLayout(CGSize(width: maxWidth, height: .greatestFiniteMagnitude))
            let numberSize = self.phoneTargetNode.updateLayout(CGSize(width: maxWidth - codeSize.width - spacing, height: .greatestFiniteMagnitude))
            
            let totalWidth = codeSize.width + numberSize.width + spacing
            
            let codeFrame = CGRect(origin: CGPoint(x: floorToScreenPixels((backgroundSize.width - totalWidth) / 2.0), y: 30.0), size: codeSize)
            transition.updateFrame(node: self.codeTargetNode, frame: codeFrame.offsetBy(dx: backgroundFrame.minX, dy: backgroundFrame.minY))
            
            let numberFrame = CGRect(origin: CGPoint(x: codeFrame.maxX + spacing, y: 30.0), size: numberSize)
            transition.updateFrame(node: self.phoneTargetNode, frame: numberFrame.offsetBy(dx: backgroundFrame.minX, dy: backgroundFrame.minY))
            
            let textSize = self.textNode.updateLayout(backgroundSize)
            transition.updateFrame(node: self.textNode, frame: CGRect(origin: CGPoint(x: floorToScreenPixels((backgroundSize.width - textSize.width) / 2.0), y: 88.0), size: textSize).offsetBy(dx: backgroundFrame.minX, dy: backgroundFrame.minY))
            
            let proceedWidth = backgroundSize.width - 16.0 * 2.0
            let proceedHeight = self.proceedNode.updateLayout(width: proceedWidth, transition: transition)
            transition.updateFrame(node: self.proceedNode, frame: CGRect(origin: CGPoint(x: innerInset, y: backgroundSize.height - proceedHeight - innerInset), size: CGSize(width: proceedWidth, height: proceedHeight)).offsetBy(dx: backgroundFrame.minX, dy: backgroundFrame.minY))
            
            let cancelSize = self.cancelButton.measure(layout.size)
            transition.updateFrame(node: self.cancelButton, frame: CGRect(origin: CGPoint(x: floorToScreenPixels((backgroundSize.width - cancelSize.width) / 2.0), y: backgroundSize.height - proceedHeight - innerInset - cancelSize.height - 25.0), size: cancelSize).offsetBy(dx: backgroundFrame.minX, dy: backgroundFrame.minY))
        }
    }
    
    public init(theme: PresentationTheme, strings: PresentationStrings, code: String, number: String, sourceController: AuthorizationSequencePhoneEntryController) {
        self.theme = theme
        self.strings = strings
        self.code = code
        self.number = number
        self.sourceController = sourceController
        
        super.init(navigationBarPresentationData: nil)
        
        self.blocksBackgroundWhenInOverlay = true
        
        self.statusBar.statusBarStyle = .Ignore
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var isDismissed = false
    override public func loadDisplayNode() {
        self.displayNode = Node(theme: self.theme, strings: self.strings, code: self.code, number: self.number)
        self.displayNodeDidLoad()
        
        self.controllerNode.proceed = { [weak self] in
            self?.proceed()
        }
        self.controllerNode.cancel = { [weak self] in
            if let strongSelf = self, let sourceController = strongSelf.sourceController {
                strongSelf.controllerNode.animateOut(codeNode: sourceController.codeNode, numberNode: sourceController.numberNode, buttonNode: sourceController.buttonNode, completion: { [weak self] in
                    self?.dismiss()
                })
            }
        }
    }
    
    func dismissAnimated() {
        self.controllerNode.cancel()
    }
    
    func transitionOut() {
        self.controllerNode.cancel()
        
        let transition = ContainedViewLayoutTransition.animated(duration: 0.5, curve: .spring)
        transition.updatePosition(layer: self.view.layer, position: CGPoint(x: self.view.center.x - self.view.frame.width, y: self.view.center.y))
    }
    
    private var didPlayAppearanceAnimation = false
    override public func viewDidAppear(_ animated: Bool) {
        if !self.didPlayAppearanceAnimation {
            self.didPlayAppearanceAnimation = true
            if let sourceController = self.sourceController {
                self.controllerNode.animateIn(codeNode: sourceController.codeNode, numberNode: sourceController.numberNode, buttonNode: sourceController.buttonNode)
            }
        }
    }
    
    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        
        self.controllerNode.containerLayoutUpdated(layout, transition: transition)
    }
}

private final class PhoneKeyNode: ASDisplayNode {
    private let imageNode: ASImageNode
    private var highlightedNode: ASImageNode?
    
    private let image: UIImage?
    private let highlightedImage: UIImage?
    
    init(offset: CGPoint, image: UIImage?, highlightedImage: UIImage?) {
        self.image = image
        self.highlightedImage = highlightedImage
        
        self.imageNode = ASImageNode()
        self.imageNode.displaysAsynchronously = false
        self.imageNode.image = image
        
        super.init()
        
        self.clipsToBounds = true
        
        if let imageSize = self.imageNode.image?.size {
            self.imageNode.frame = CGRect(origin: CGPoint(x: -offset.x, y: -offset.y), size: imageSize)
        }
        
        self.addSubnode(self.imageNode)
    }
    
    func animatePress() {
        guard self.highlightedNode == nil else {
            return
        }
        
        let highlightedNode = ASImageNode()
        highlightedNode.displaysAsynchronously = false
        highlightedNode.image = self.highlightedImage
        highlightedNode.frame = self.imageNode.frame
        self.addSubnode(highlightedNode)
        self.highlightedNode = highlightedNode
        
        highlightedNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.16, removeOnCompletion: false, completion: { [weak self] _ in
            self?.highlightedNode?.removeFromSupernode()
            self?.highlightedNode = nil
        })
        
        let values: [NSNumber] = [0.75, 0.5, 0.75, 1.0]
        self.layer.animateKeyframes(values: values, duration: 0.16, keyPath: "transform.scale")
    }
}

private final class ManagedPhoneAnimationNode: ManagedAnimationNode {
    private var timer: SwiftSignalKit.Timer?
    
    private let plateNode: ASDisplayNode
    private var nodes: [PhoneKeyNode]
    
    init() {
        self.plateNode = ASDisplayNode()
        self.plateNode.backgroundColor = UIColor(rgb: 0xc30023)
        self.plateNode.frame = CGRect(x: 27.0, y: 38.0, width: 46.0, height: 32.0)
        
        let image = UIImage(bundleImageName: "Settings/Keypad")
        let highlightedImage = generateTintedImage(image: image, color: UIColor(rgb: 0x000000, alpha: 0.4))
        
        var nodes: [PhoneKeyNode] = []
        for i in 0 ..< 9 {
            let offset: CGPoint
            switch i {
                case 1:
                    offset = CGPoint(x: 15.0, y: 0.0)
                case 2:
                    offset = CGPoint(x: 30.0, y: 0.0)
                case 3:
                    offset = CGPoint(x: 0.0, y: 10.0)
                case 4:
                    offset = CGPoint(x: 15.0, y: 10.0)
                case 5:
                    offset = CGPoint(x: 30.0, y: 10.0)
                case 6:
                    offset = CGPoint(x: 0.0, y: 21.0)
                case 7:
                    offset = CGPoint(x: 15.0, y: 21.0)
                case 8:
                    offset = CGPoint(x: 30.0, y: 21.0)
                default:
                    offset = CGPoint(x: 0.0, y: 0.0)
            }
            let node = PhoneKeyNode(offset: offset, image: image, highlightedImage: highlightedImage)
            node.frame = CGRect(origin: offset.offsetBy(dx: 28.0, dy: 38.0), size: CGSize(width: 15.0, height: 10.0))
            nodes.append(node)
        }
        self.nodes = nodes
        
        super.init(size: CGSize(width: 100.0, height: 100.0))
        
        self.trackTo(item: ManagedAnimationItem(source: .local("IntroPhone"), frames: .range(startFrame: 0, endFrame: 0), duration: 0.001))
        
        self.addSubnode(self.plateNode)
        
        for node in nodes {
            self.addSubnode(node)
        }
    }
    
    func animate(num: Int) {
        guard num != 0 else {
            return
        }
        let index = max(0, min(self.nodes.count - 1, num - 1))
        self.nodes[index].animatePress()
    }
}
