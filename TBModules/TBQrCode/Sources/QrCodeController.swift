import Foundation
import UIKit
import SwiftSignalKit
import AccountContext
import Postbox
import AsyncDisplayKit
import Display
import TelegramCore
import TelegramPresentationData
import QrCode
import ComponentFlow
import TBDisplay
import TBLanguage
import ProgressHUD
import ShareController
import UndoUI

public class QrCodeController: ViewController {
    
    private let context: AccountContext
    private let code: String
    private var presentationData: PresentationData
    private let presentationDataValue = Promise<PresentationData>()
    private var presentationDataDisposable: Disposable?
    
    private var popNode: TBPopDisplayNode {
        return self.displayNode as! TBPopDisplayNode
    }
    
    private var animatedIn = false
    private var initialBrightness: CGFloat?
    private var brightnessArguments: (Double, Double, CGFloat, CGFloat)?
    private let qrNode: QrContentNode
    
    private var animator: ConstantDisplayLinkAnimator?
    
    public init(context: AccountContext, code: String) {
        self.context = context
        self.code = code
        self.presentationData = (context.sharedContext.currentPresentationData.with { $0 })
        self.presentationDataValue.set(.single(self.presentationData))
        
        self.qrNode = QrContentNode(context: context, code: code)
        
        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData))
        
        self.displayNavigationBar = false
        self.animator = ConstantDisplayLinkAnimator(update: { [weak self] in
            self?.updateBrightness()
        })
        self.animator?.isPaused = true
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.presentationDataDisposable?.dispose()
    }

    override public func loadDisplayNode() {
        self.displayNode = TBPopDisplayNode(context: self.context, presentationData: self.presentationData, contentHeight: 570)
        self.displayNodeDidLoad()
        self.popNode.contentNodeDidLoad = {[weak self] node in
            guard let strongSelf = self else { return }
            node.addSubnode(strongSelf.qrNode)
        }
        self.popNode.contentNodeDidUpdateLayout = { [weak self] size, transition in
            guard let strongSelf = self else { return }
            strongSelf.qrNode.updateLayout(size: size, transition: transition)
            transition.updateFrame(node: strongSelf.qrNode, frame: CGRect(origin: .zero, size: size))
        }
        
        self.popNode.dismiss = { [weak self] in
            self?.dismiss(animated: true)
        }
        
        self.qrNode.closeEvent = { [weak self] in
            self?.dismiss(animated: true)
        }
        
        self.qrNode.copyEvent = { [weak self] in
            guard let strongSelf = self else { return }
            UIPasteboard.general.string = getAddressFromQrcode(qrCode: strongSelf.code) ?? ""
            ProgressHUD.showSucceed("")
        }
        
        self.qrNode.shareEvent = { [weak self] in
            guard let strongSelf = self else { return }
            let txt = getAddressFromQrcode(qrCode: strongSelf.code) ?? ""
            let context = strongSelf.context
            let subject: ShareControllerSubject = .text(txt)
            
            let shareController = ShareController(context: context, subject: subject)
            shareController.completed = {peerIds in
                let _ = (context.engine.data.get(EngineDataList(peerIds.map(TelegramEngine.EngineData.Item.Peer.Peer.init)))
                         |> deliverOnMainQueue).start(next: {peerList in
                    guard let strongSelf = self else { return }
                    let peers = peerList.compactMap { $0 }
                    let presentationData = context.sharedContext.currentPresentationData.with { $0 }
                    
                    let text: String
                    var savedMessages = false
                    if peerIds.count == 1, let peerId = peerIds.first, peerId == context.account.peerId {
                        text = presentationData.strings.InviteLink_InviteLinkForwardTooltip_SavedMessages_One
                        savedMessages = true
                    } else {
                        if peers.count == 1, let peer = peers.first {
                            let peerName = peer.id == context.account.peerId ? presentationData.strings.DialogList_SavedMessages : peer.displayTitle(strings: presentationData.strings, displayOrder: presentationData.nameDisplayOrder)
                            text = presentationData.strings.InviteLink_InviteLinkForwardTooltip_Chat_One(peerName).string
                        } else if peers.count == 2, let firstPeer = peers.first, let secondPeer = peers.last {
                            let firstPeerName = firstPeer.id == context.account.peerId ? presentationData.strings.DialogList_SavedMessages : firstPeer.displayTitle(strings: presentationData.strings, displayOrder: presentationData.nameDisplayOrder)
                            let secondPeerName = secondPeer.id == context.account.peerId ? presentationData.strings.DialogList_SavedMessages : secondPeer.displayTitle(strings: presentationData.strings, displayOrder: presentationData.nameDisplayOrder)
                            text = presentationData.strings.InviteLink_InviteLinkForwardTooltip_TwoChats_One(firstPeerName, secondPeerName).string
                        } else if let peer = peers.first {
                            let peerName = peer.displayTitle(strings: presentationData.strings, displayOrder: presentationData.nameDisplayOrder)
                            text = presentationData.strings.InviteLink_InviteLinkForwardTooltip_ManyChats_One(peerName, "\(peers.count - 1)").string
                        } else {
                            text = ""
                        }
                    }
                    strongSelf.present(UndoOverlayController(presentationData: presentationData, content: .forward(savedMessages: savedMessages, text: text), elevatedLayout: false, animateInAsReplacement: true, action: { _ in return false }), in: .window(.root))
                })
            }
            shareController.actionCompleted = {
                guard let strongSelf = self else { return }
                let presentationData = context.sharedContext.currentPresentationData.with { $0 }
                strongSelf.present(UndoOverlayController(presentationData: presentationData, content: .linkCopied(text: presentationData.strings.InviteLink_InviteLinkCopiedText), elevatedLayout: false, animateInAsReplacement: false, action: { _ in return false }), in: .window(.root))
            }
            
            strongSelf.present(shareController, in: .window(.root))
        }
    }
    
    
    public override func displayNodeDidLoad() {
        super.displayNodeDidLoad()
        
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !self.animatedIn {
            self.animatedIn = true
            self.popNode.animateIn()
            self.initialBrightness = UIScreen.main.brightness
            self.brightnessArguments = (CACurrentMediaTime(), 0.3, UIScreen.main.brightness, 1.0)
            self.updateBrightness()
        }
    }
    
    private func updateBrightness() {
        if let (startTime, duration, initial, target) = self.brightnessArguments {
            self.animator?.isPaused = false
            let t = CGFloat(max(0.0, min(1.0, (CACurrentMediaTime() - startTime) / duration)))
            let value = initial + (target - initial) * t
            UIScreen.main.brightness = value
            if t >= 1.0 {
                self.brightnessArguments = nil
                self.animator?.isPaused = true
            }
        } else {
            self.animator?.isPaused = true
        }
    }
    
    override public func dismiss(completion: (() -> Void)? = nil) {
        if UIScreen.main.brightness > 0.99, let initialBrightness = self.initialBrightness {
            self.brightnessArguments = (CACurrentMediaTime(), 0.3, UIScreen.main.brightness, initialBrightness)
            self.updateBrightness()
        }
        self.popNode.animateOut(completion: completion)
    }
    
    
    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        
        self.popNode.containerLayoutUpdated(layout, transition: transition)
    }
}


private class QrContentNode: ASDisplayNode {
    private let context: AccountContext
    private let code: String
    
    fileprivate let containerNode: ASDisplayNode
    private let codeBackgroundNode: ASDisplayNode
    private let codeForegroundNode: ASDisplayNode
    private var codeForegroundDimNode: ASDisplayNode
    private let codeMaskNode: ASDisplayNode
    private let codeImageNode: TransformImageNode
    private let codeIconBackgroundNode: ASImageNode
    
    private let titleNode: ASTextNode
    private let closeButtonNode: ASButtonNode
    private let addressNode: ASTextNode
    private let alertNode: ASTextNode
    private let copyButton: TBButtonView
    private let shareButton: TBButtonView
    
    private var qrCodeSize: Int?
        
    private var currentParams: (PresentationTheme, TelegramWallpaper, Bool, String?)?
    private var validLayout: CGSize?
    
    private let _ready = Promise<Bool>()
    var isReady: Signal<Bool, NoError> {
        return self._ready.get()
    }
    
    var closeEvent: (()->())?
    var copyEvent: (()->())?
    var shareEvent: (()->())?
    
    init(context: AccountContext, code: String) {
        self.context = context
        self.code = code
        
        self.containerNode = ASDisplayNode()
        self.codeBackgroundNode = ASDisplayNode()
        self.codeBackgroundNode.backgroundColor = .white
        self.codeBackgroundNode.cornerRadius = 42.0
        if #available(iOS 13.0, *) {
            self.codeBackgroundNode.layer.cornerCurve = .continuous
        }
        
        self.codeForegroundNode = ASDisplayNode()
        self.codeForegroundNode.backgroundColor = .black
        
        self.codeForegroundDimNode = ASDisplayNode()
        self.codeForegroundDimNode.alpha = 0.3
        self.codeForegroundDimNode.backgroundColor = .black
        
        self.codeMaskNode = ASDisplayNode()
        
        self.codeImageNode = TransformImageNode()
        self.codeIconBackgroundNode = ASImageNode()
        
        self.titleNode = ASTextNode()
        self.closeButtonNode = ASButtonNode()
        self.addressNode = ASTextNode()
        self.alertNode = ASTextNode()
        let config = TBBottonViewNormalConfig(gradientColors: [UIColor(rgb: 0x3954D5).cgColor, UIColor(rgb: 0x3954D5).cgColor], borderWidth: 0, borderColor: UIColor.clear.cgColor, borderRadius:23, enbale: true, alpha: 1, iconSize: CGSize(width: 15, height: 15), titleFont: Font.medium(16), buttonType: .titleRight)
        self.copyButton = TBButtonView(config: config)
        self.shareButton = TBButtonView(config: config)
        
        super.init()
        
        let codeReadyPromise = ValuePromise<Bool>()
        self.codeImageNode.setSignal(qrCode(string: code, color: .black, backgroundColor: nil, icon: .cutout, ecl: "Q") |> beforeNext { [weak self] size, _ in
            guard let strongSelf = self else {
                return
            }
            strongSelf.qrCodeSize = size
            if let size = strongSelf.validLayout {
                strongSelf.updateLayout(size: size, transition: .immediate)
            }
            codeReadyPromise.set(true)
        } |> map { $0.1 }, attemptSynchronously: true)
        
        self._ready.set(codeReadyPromise.get()
        |> map { codeReady in
            return codeReady
        })
    }
    
    override func didLoad() {
        super.didLoad()
        self.addSubnode(self.containerNode)
        self.containerNode.addSubnode(self.codeBackgroundNode)
        self.containerNode.addSubnode(self.codeForegroundNode)
        
        self.codeForegroundNode.addSubnode(self.codeForegroundDimNode)
        self.codeMaskNode.addSubnode(self.codeImageNode)
        self.codeMaskNode.addSubnode(self.codeIconBackgroundNode)
        self.codeForegroundNode.view.mask = self.codeMaskNode.view
        
        self.titleNode.attributedText = NSAttributedString(string: "", font: Font.medium(14), textColor: .black, paragraphAlignment: .center)
        self.containerNode.addSubnode(self.titleNode)
        self.closeButtonNode.setImage(UIImage(named: "Nav/nav_close_icon"), for: .normal)
        self.closeButtonNode.addTarget(self, action: #selector(self.closeBUttonClick), forControlEvents: .touchUpInside)
        self.containerNode.addSubnode(self.closeButtonNode)
        
        let addressText = getAddressFromQrcode(qrCode: self.code) ?? ""
        self.addressNode.attributedText = NSAttributedString(string: addressText, font: Font.medium(13), textColor: UIColor(hexString: "#56565C")!, paragraphAlignment: .center)
        self.addressNode.maximumNumberOfLines = 3
        self.containerNode.addSubnode(self.addressNode)
        self.alertNode.attributedText = NSAttributedString(string: " ThunderCore ", font: Font.medium(13), textColor: UIColor(hexString: "#3954D5")!)
        self.alertNode.maximumNumberOfLines = 3
        self.containerNode.addSubnode(self.alertNode)
        self.containerNode.view.addSubview(self.copyButton)
        self.copyButton.contentView.titleLabel.textColor = UIColor(rgb: 0xFFFFFF)
        self.copyButton.contentView.titleLabel.text = TBLanguage.sharedInstance.localizable(TBLankey.dialog_copy)
        self.copyButton.contentView.icon.image = UIImage(bundleImageName: "TBWebPage/ic_tb_copy")
        self.copyButton.contentView.activityView.isHidden = true
        self.copyButton.tapBlock = { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.copyEvent?()
        }
        
        self.containerNode.view.addSubview(self.shareButton)
        self.shareButton.contentView.titleLabel.textColor = UIColor(rgb: 0xFFFFFF)
        self.shareButton.contentView.titleLabel.text = TBLanguage.sharedInstance.localizable(TBLankey.ac_download_text_share)
        self.shareButton.contentView.icon.image = UIImage(bundleImageName: "TBWebPage/ic_tb_share")
        self.shareButton.contentView.activityView.isHidden = true
        self.shareButton.tapBlock = { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.shareEvent?()
        }
    }
    
    @objc func closeBUttonClick() {
        self.closeEvent?()
    }
    
    func updateLayout(size: CGSize,transition: ContainedViewLayoutTransition) {
        self.validLayout = size
        transition.updateFrame(node: self.containerNode, frame: CGRect(origin: .zero, size: size))
        let codeInset: CGFloat = 90.0
        let codeBackgroundWidth = size.width - 2 * codeInset
        let imageSide: CGFloat = codeBackgroundWidth - 26
        let codeBackgroundFrame = CGRect(x: floor((size.width - codeBackgroundWidth) / 2.0), y: 65, width: codeBackgroundWidth, height: codeBackgroundWidth)
        transition.updateFrame(node: self.codeBackgroundNode, frame: codeBackgroundFrame)
        transition.updateFrame(node: self.codeForegroundNode, frame: codeBackgroundFrame)
        transition.updateFrame(node: self.codeMaskNode, frame: CGRect(origin: CGPoint(), size: codeBackgroundFrame.size))
        transition.updateFrame(node: self.codeForegroundDimNode, frame: CGRect(origin: CGPoint(), size: codeBackgroundFrame.size))
        let makeImageLayout = self.codeImageNode.asyncLayout()
        let imageSize = CGSize(width: imageSide, height: imageSide)
        let imageApply = makeImageLayout(TransformImageArguments(corners: ImageCorners(), imageSize: imageSize, boundingSize: imageSize, intrinsicInsets: UIEdgeInsets(), emptyColor: nil, scale: 3.0))
        let _ = imageApply()
        let imageFrame = CGRect(origin: CGPoint(x: 13, y: 13), size: imageSize)
        transition.updateFrame(node: self.codeImageNode, frame: imageFrame)
        if let qrCodeSize = self.qrCodeSize {
            let (_, cutoutFrame, _) = qrCodeCutout(size: qrCodeSize, dimensions: imageSize, scale: nil)
            let backgroundSize = CGSize(width: floorToScreenPixels(cutoutFrame.width - 8.0), height: floorToScreenPixels(cutoutFrame.height - 8.0))
            transition.updateFrame(node: self.codeIconBackgroundNode, frame: CGRect(origin: CGPoint(x: floorToScreenPixels(imageFrame.center.x - backgroundSize.width / 2.0), y: floorToScreenPixels(imageFrame.center.y - backgroundSize.height / 2.0)), size: backgroundSize))
            if self.codeIconBackgroundNode.image == nil {
                self.codeIconBackgroundNode.image = generateFilledCircleImage(diameter: backgroundSize.width, color: .black)
            }
        }
        let titleSize = self.titleNode.updateLayout(CGSize(width: 300.0, height: .greatestFiniteMagnitude))
        transition.updateFrame(node: self.titleNode, frame: CGRect(x: (size.width - titleSize.width) / 2.0, y: (55 - titleSize.height) / 2.0, width: titleSize.width, height: titleSize.height))
        transition.updateFrame(node: self.closeButtonNode, frame: CGRect(x: size.width - 50, y: 5, width: 44, height: 44))
        let addressSize = self.addressNode.updateLayout(CGSize(width: 300.0, height: .greatestFiniteMagnitude))
        transition.updateFrame(node: self.addressNode, frame: CGRect(x: (size.width - addressSize.width) / 2.0, y: 336, width: addressSize.width, height: addressSize.height))
        let alertSize = self.alertNode.updateLayout(CGSize(width: 300.0, height: .greatestFiniteMagnitude))
        transition.updateFrame(node: self.alertNode, frame: CGRect(x: (size.width - alertSize.width) / 2.0, y: 409, width: alertSize.width, height: alertSize.height))
        
        let buttonWidth = (size.width - 8 - 46) / 2.0
        transition.updateFrame(view: self.copyButton, frame: CGRect(x: 23, y: 494, width: buttonWidth, height: 46))
        transition.updateFrame(view: self.shareButton, frame: CGRect(x: 23 + buttonWidth + 8, y: 494, width: buttonWidth, height: 46))
    }
}


func getAddressFromQrcode(qrCode: String) -> String? {
    if let achain = qrCode.components(separatedBy: ":").last, let rAddress = achain.components(separatedBy: "@").first {
        return rAddress
    } else {
        return nil
    }
}
