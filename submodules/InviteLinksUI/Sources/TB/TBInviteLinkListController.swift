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
import QrCode
import QrCodeUI
import TBAccount
import ProgressHUD
import ShareController
import UndoUI

public final class TBInviteLinkListController: ViewController {
    
    private var controllerNode: Node {
        return self.displayNode as! Node
    }
    
    private var animatedIn = false
    
    private let context: AccountContext
    
    private let groupInfo: TBWeb3GroupInfoEntry
    
    private let configEntry: TBWeb3ConfigEntry
    
    private var presentationData: PresentationData
    private var presentationDataDisposable: Disposable?
    
    private var initialBrightness: CGFloat?
    private var brightnessArguments: (Double, Double, CGFloat, CGFloat)?
    
    private var animator: ConstantDisplayLinkAnimator?
    
    private let idleTimerExtensionDisposable = MetaDisposable()
    
    public init(context: AccountContext, updatedPresentationData: (initial: PresentationData, signal: Signal<PresentationData, NoError>)? = nil, groupInfo: TBWeb3GroupInfoEntry, configEntry: TBWeb3ConfigEntry) {
        self.context = context
        self.groupInfo = groupInfo
        self.configEntry = configEntry
        self.presentationData = updatedPresentationData?.initial ?? context.sharedContext.currentPresentationData.with { $0 }
        
        super.init(navigationBarPresentationData: nil)
        
        self.statusBar.statusBarStyle = .Ignore
        
        self.blocksBackgroundWhenInOverlay = true
        
        self.presentationDataDisposable = ((updatedPresentationData?.signal ?? context.sharedContext.presentationData)
        |> deliverOnMainQueue).start(next: { [weak self] presentationData in
            if let strongSelf = self {
                strongSelf.presentationData = presentationData
                strongSelf.controllerNode.updatePresentationData(presentationData)
            }
        })
        
        self.idleTimerExtensionDisposable.set(self.context.sharedContext.applicationBindings.pushIdleTimerExtension())
        
        self.statusBar.statusBarStyle = .Ignore
        
        self.animator = ConstantDisplayLinkAnimator(update: { [weak self] in
            self?.updateBrightness()
        })
        self.animator?.isPaused = true
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.presentationDataDisposable?.dispose()
        self.idleTimerExtensionDisposable.dispose()
        self.animator?.invalidate()
    }
    
    override public func loadDisplayNode() {
        self.displayNode = Node(context: self.context, presentationData: self.presentationData, groupInfo: self.groupInfo, config: self.configEntry, controller: self)
        self.controllerNode.dismiss = { [weak self] in
            self?.presentingViewController?.dismiss(animated: false, completion: nil)
        }
        self.controllerNode.cancel = { [weak self] in
            self?.dismiss()
        }
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !self.animatedIn {
            self.animatedIn = true
            self.controllerNode.animateIn()
            
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
        
        self.controllerNode.animateOut(completion: completion)
    }
    
    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        
        self.controllerNode.containerLayoutUpdated(layout, navigationBarHeight: self.navigationLayout(layout: layout).navigationFrame.maxY, transition: transition)
    }

    class Node: ViewControllerTracingNode, UIScrollViewDelegate {
        private weak var controller: TBInviteLinkListController?
        private let context: AccountContext
        private let groupInfo: TBWeb3GroupInfoEntry
        private let configEntry: TBWeb3ConfigEntry
        private var presentationData: PresentationData
    
        private let dimNode: ASDisplayNode
        private let wrappingScrollNode: ASScrollNode
        private let contentContainerNode: ASDisplayNode
        private let backgroundNode: ASDisplayNode
        private let contentBackgroundNode: ASDisplayNode
        private var contentView: TBInviteLinkListContentView?
                
        private var containerLayout: (ContainerViewLayout, CGFloat)?
        
        var completion: ((Int32) -> Void)?
        var dismiss: (() -> Void)?
        var cancel: (() -> Void)?
        
        init(context: AccountContext, presentationData: PresentationData, groupInfo: TBWeb3GroupInfoEntry, config:TBWeb3ConfigEntry, controller:TBInviteLinkListController) {
            self.controller = controller
            self.context = context
            self.groupInfo = groupInfo
            self.configEntry = config
            self.presentationData = presentationData

            self.wrappingScrollNode = ASScrollNode()
            self.wrappingScrollNode.view.alwaysBounceVertical = true
            self.wrappingScrollNode.view.delaysContentTouches = false
            self.wrappingScrollNode.view.canCancelContentTouches = true
            
            self.dimNode = ASDisplayNode()
            self.dimNode.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
            
            self.contentContainerNode = ASDisplayNode()
            self.contentContainerNode.isOpaque = false

            self.backgroundNode = ASDisplayNode()
            self.backgroundNode.clipsToBounds = true
            self.backgroundNode.cornerRadius = 16.0
            
            let backgroundColor = self.presentationData.theme.actionSheet.opaqueItemBackgroundColor
            let textColor = self.presentationData.theme.actionSheet.primaryTextColor
            let secondaryTextColor = self.presentationData.theme.actionSheet.secondaryTextColor
            let accentColor = self.presentationData.theme.actionSheet.controlAccentColor
            
            self.contentBackgroundNode = ASDisplayNode()
            self.contentBackgroundNode.backgroundColor = backgroundColor
            
        
            super.init()
            
            self.backgroundColor = nil
            self.isOpaque = false
            
            self.dimNode.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.dimTapGesture(_:))))
            self.addSubnode(self.dimNode)
            
            self.wrappingScrollNode.view.delegate = self
            self.addSubnode(self.wrappingScrollNode)
            
            self.wrappingScrollNode.addSubnode(self.backgroundNode)
            self.wrappingScrollNode.addSubnode(self.contentContainerNode)
            self.backgroundNode.addSubnode(self.contentBackgroundNode)
            
            
            self.contentContainerNode.onDidLoad {[weak self] node in
                if let strongSelf = self {
                    let contentView = TBInviteLinkListContentView(context: strongSelf.context, groupInfo: strongSelf.groupInfo, configEntry: strongSelf.configEntry)
                    node.view.addSubview(contentView)
                    contentView.frame = node.bounds
                    
                    contentView.pasteBlock = {[weak self] in
                        self?.paste_()
                    }
                    
                    let inviteView = contentView.inviteView
                    contentView.shareBlock = {[weak self] in
                        ProgressHUD.show()
                        let _ = inviteView.transformSignal().start(next:{[weak self] image in
                            ProgressHUD.dismiss()
                            self?.share_(image:image)
                        })
                    }
                    
                    contentView.cancelBlock = {[weak self] in
                        self?.cancelButtonPressed()
                    }
                    
                    contentView.getQrCodeBlock = {[weak self] in
                        self?.getQr_()
                    }
                    strongSelf.contentView = contentView
                }
            }
           
        }
        
        
        private func paste_() {
            UIPasteboard.general.string = self.groupInfo.getShareUrl()
            ProgressHUD.showSucceed("")
        }
        
        
        private func share_(image:UIImage) {
            guard let data = image.jpegData(compressionQuality: 0.1) else {
                return
            }
            
            let context = self.context
            let groupInfo = self.groupInfo
            
            
            let resource = LocalFileMediaResource(fileId: Int64.random(in: Int64.min ... Int64.max))
            context.account.postbox.mediaBox.storeResourceData(resource.id, data: data)
            let representation = TelegramMediaImageRepresentation(dimensions: PixelDimensions(width: Int32(image.size.width), height: Int32(image.size.height)), resource: resource, progressiveSizes: [], immediateThumbnailData: nil, hasVideo: false)
            
            let imageRep = ImageRepresentationWithReference(representation: representation, reference: .standalone(resource: representation.resource))
            
            let subject: ShareControllerSubject = .image([imageRep])

        
            
            let shareController = ShareController(context: context, subject: subject, tbForceText: groupInfo.getShareUrl())
            shareController.completed = {peerIds in
                let _ = (context.engine.data.get(
                    EngineDataList(
                        peerIds.map(TelegramEngine.EngineData.Item.Peer.Peer.init)
                    )
                )
                         |> deliverOnMainQueue).start(next: {peerList in
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
                    
                    self.controller?.present(UndoOverlayController(presentationData: presentationData, content: .forward(savedMessages: savedMessages, text: text), elevatedLayout: false, animateInAsReplacement: true, action: { _ in return false }), in: .window(.root))
                    
                })
            }
            shareController.actionCompleted = {
                let presentationData = context.sharedContext.currentPresentationData.with { $0 }
                self.controller?.present(UndoOverlayController(presentationData: presentationData, content: .linkCopied(text: presentationData.strings.InviteLink_InviteLinkCopiedText), elevatedLayout: false, animateInAsReplacement: false, action: { _ in return false }), in: .window(.root))
            }
            
            self.controller?.present(shareController, in: .window(.root))
        }
        
        
        private func getQr_() {
            let invite = ExportedInvitation.link(link: self.groupInfo.getShareUrl(), title: nil, isPermanent: true, requestApproval: false, isRevoked: false, adminId: self.context.account.peerId, date: Int32(NSDate().timeIntervalSince1970), startDate: nil, expireDate: nil, usageLimit: nil, count: nil, requestedCount: nil)
            let controller = QrCodeScreen(context: self.context, updatedPresentationData: nil, subject: .invite(invite: invite, isGroup: true))
            self.controller?.present(controller, in: .window(.root))
        }
            

        func updatePresentationData(_ presentationData: PresentationData) {
            let previousTheme = self.presentationData.theme
            self.presentationData = presentationData
            
            self.contentBackgroundNode.backgroundColor = self.presentationData.theme.actionSheet.opaqueItemBackgroundColor
            
            if previousTheme !== presentationData.theme, let (layout, navigationBarHeight) = self.containerLayout {
                self.containerLayoutUpdated(layout, navigationBarHeight: navigationBarHeight, transition: .immediate)
            }
        }
        
        override func didLoad() {
            super.didLoad()
            if #available(iOSApplicationExtension 11.0, iOS 11.0, *) {
                self.wrappingScrollNode.view.contentInsetAdjustmentBehavior = .never
            }
        }
        
        @objc func cancelButtonPressed() {
            self.cancel?()
        }
        
        @objc func dimTapGesture(_ recognizer: UITapGestureRecognizer) {
            if case .ended = recognizer.state {
                self.cancelButtonPressed()
            }
        }
        
        func animateIn() {
            self.dimNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.4)
            
            let offset = self.bounds.size.height - self.contentBackgroundNode.frame.minY
            
            let dimPosition = self.dimNode.layer.position
            self.dimNode.layer.animatePosition(from: CGPoint(x: dimPosition.x, y: dimPosition.y - offset), to: dimPosition, duration: 0.3, timingFunction: kCAMediaTimingFunctionSpring)
            self.layer.animateBoundsOriginYAdditive(from: -offset, to: 0.0, duration: 0.3, timingFunction: kCAMediaTimingFunctionSpring)
        }
        
        func animateOut(completion: (() -> Void)? = nil) {
            var dimCompleted = false
            var offsetCompleted = false
            
            let internalCompletion: () -> Void = { [weak self] in
                if let strongSelf = self, dimCompleted && offsetCompleted {
                    strongSelf.dismiss?()
                }
                completion?()
            }
            
            self.dimNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.3, removeOnCompletion: false, completion: { _ in
                dimCompleted = true
                internalCompletion()
            })
            
            let offset = self.bounds.size.height - self.contentBackgroundNode.frame.minY
            let dimPosition = self.dimNode.layer.position
            self.dimNode.layer.animatePosition(from: dimPosition, to: CGPoint(x: dimPosition.x, y: dimPosition.y - offset), duration: 0.3, timingFunction: kCAMediaTimingFunctionSpring, removeOnCompletion: false)
            self.layer.animateBoundsOriginYAdditive(from: 0.0, to: -offset, duration: 0.3, timingFunction: kCAMediaTimingFunctionSpring, removeOnCompletion: false, completion: { _ in
                offsetCompleted = true
                internalCompletion()
            })
        }
        
        override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
            if self.bounds.contains(point) {
                if !self.contentBackgroundNode.bounds.contains(self.convert(point, to: self.contentBackgroundNode)) {
                    return self.dimNode.view
                }
            }
            return super.hitTest(point, with: event)
        }
        
        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            let contentOffset = scrollView.contentOffset
            let additionalTopHeight = max(0.0, -contentOffset.y)
            
            if additionalTopHeight >= 30.0 {
                self.cancelButtonPressed()
            }
        }
        
        func containerLayoutUpdated(_ layout: ContainerViewLayout, navigationBarHeight: CGFloat, transition: ContainedViewLayoutTransition) {
            self.containerLayout = (layout, navigationBarHeight)
            
            var insets = layout.insets(options: [.statusBar, .input])
            insets.top = 32.0
            
            let width = horizontalContainerFillingSizeForLayout(layout: layout, sideInset: 0.0)
        
            let contentHeight:CGFloat = TBInviteLinkListContentView.contentSize(with: width, groupInfo: self.groupInfo, config: self.configEntry).height
                        
            let sideInset = floor((layout.size.width - width) / 2.0)
            let contentContainerFrame = CGRect(origin: CGPoint(x: sideInset, y: layout.size.height - contentHeight), size: CGSize(width: width, height: contentHeight))
            self.contentView?.frame = CGRect(origin: .zero, size: CGSize(width: width, height: contentHeight))
            let contentFrame = contentContainerFrame
            
            var backgroundFrame = CGRect(origin: CGPoint(x: contentFrame.minX, y: contentFrame.minY), size: CGSize(width: contentFrame.width, height: contentFrame.height + 2000.0))
            if backgroundFrame.minY < contentFrame.minY {
                backgroundFrame.origin.y = contentFrame.minY
            }
            transition.updateFrame(node: self.backgroundNode, frame: backgroundFrame)
            transition.updateFrame(node: self.contentBackgroundNode, frame: CGRect(origin: CGPoint(), size: backgroundFrame.size))
            transition.updateFrame(node: self.wrappingScrollNode, frame: CGRect(origin: CGPoint(), size: layout.size))
            transition.updateFrame(node: self.dimNode, frame: CGRect(origin: CGPoint(), size: layout.size))
        
            transition.updateFrame(node: self.contentContainerNode, frame: contentContainerFrame)
        }
    }
}
