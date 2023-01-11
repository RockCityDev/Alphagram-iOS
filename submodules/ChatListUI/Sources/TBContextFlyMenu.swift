






import Foundation
import UIKit
import Display
import AsyncDisplayKit
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import TelegramUIPreferences
import DeviceAccess
import AccountContext
import AlertUI
import PresentationDataUtils
import TelegramPermissions
import TelegramNotices
import ContactsPeerItem
import SearchUI
import TelegramPermissionsUI
import AppBundle
import StickerResources
import ContextUI
import QrCodeUI
import SwiftUI
import TBLanguage


final class TBFlyContextMenuItem: ContextMenuCustomItem {
     let tap: (TBFlyMenu) -> Void
     let value: TBFlyMenu
    
    init(tap: @escaping (TBFlyMenu) -> Void, value: TBFlyMenu) {
        self.tap = tap
        self.value = value
    }
    
    func node(presentationData: PresentationData, getController: @escaping () -> ContextControllerProtocol?, actionSelected: @escaping (ContextMenuActionResult) -> Void) -> ContextMenuCustomNode {
        return TBFlyMenuItemNode(presentationData: presentationData, getController: getController, actionSelected: actionSelected, item: self)
    }
}


final class TBFlyMenuItemNode: ASDisplayNode, ContextMenuCustomNode {
    private var presentationData: PresentationData
    private let actionSelected: (ContextMenuActionResult) -> Void
    private let getController:() -> ContextControllerProtocol?
    
    private let menueItem: TBFlyContextMenuItem
    
    private let titleNode: ASTextNode
    private let imageNode: ASImageNode
    
    init(presentationData: PresentationData, getController: @escaping () -> ContextControllerProtocol?,actionSelected: @escaping (ContextMenuActionResult) -> Void, item: TBFlyContextMenuItem) {
        self.presentationData = presentationData
        self.menueItem = item
        self.actionSelected = actionSelected
        self.getController = getController
        
        
        var imageBundleName = "FlyMenue/btn_qrcode_sub_menu"
        var titleName = TBLanguage.sharedInstance.localizable(TBLankey.homeoption_pop_qrcode)
        
        switch self.menueItem.value {
        case .qrCode:
            titleName = TBLanguage.sharedInstance.localizable(TBLankey.homeoption_pop_qrcode)
            imageBundleName = "FlyMenue/btn_qrcode_sub_menu"
        case .chatQRCode:
            titleName = "chat"
            imageBundleName = "FlyMenue/btn_qrcode_sub_menu"
        case .linkDeviceQRCode:
            titleName = "LinkDevice"
            imageBundleName = "FlyMenue/btn_qrcode_sub_menu"
        case .newMessage:
            titleName =  ""
            imageBundleName = "FlyMenue/btn_create_new_message_sub_menu"
        case .newFriend:
            titleName = TBLanguage.sharedInstance.localizable(TBLankey.homeoption_pop_addfriend)
            imageBundleName = "FlyMenue/btn_add_friend_menu"
        case .newGroup:
            titleName = TBLanguage.sharedInstance.localizable(TBLankey.homeoption_pop_creategroup)
            imageBundleName = "FlyMenue/btn_create_new_group_sub_menu"
        case .newChannel:
            titleName = TBLanguage.sharedInstance.localizable(TBLankey.homeoption_pop_createchannel)
            imageBundleName = "FlyMenue/btn_create_new_channel_sub_menu"
        case .startSeret:
            titleName = TBLanguage.sharedInstance.localizable(TBLankey.homeoption_pop_encryptedchat)
            imageBundleName = "FlyMenue/btn_private_message_sub_menu"
        }
        
        self.titleNode = ASTextNode()
        self.titleNode.attributedText = NSAttributedString(string:titleName, attributes: [.foregroundColor: UIColor(rgb: 0x1A1A1D), .font: UIFont.systemFont(ofSize: 15, weight: .regular)])
        self.titleNode.maximumNumberOfLines = 1
        self.titleNode.textAlignment = NSTextAlignment.left
        
        self.imageNode = ASImageNode()
        self.imageNode.image = UIImage(bundleImageName: imageBundleName)
        
        
        super.init()
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tapAction)))
        self.isUserInteractionEnabled = true
        self.addSubnode(self.titleNode)
        self.addSubnode(self.imageNode)
        self.updateTheme(presentationData: presentationData)
        
    }
    
    @objc func tapAction() {
        self.getController()?.dismiss(completion: {
            self.menueItem.tap(self.menueItem.value)
        })
    }
    
     func updateTheme(presentationData: PresentationData) {
        self.presentationData = presentationData
    }
    
     func updateLayout(constrainedWidth: CGFloat, constrainedHeight: CGFloat) -> (CGSize, (CGSize, ContainedViewLayoutTransition) -> Void) {
        let width: CGFloat = 196.0
        let height: CGFloat = 44.0

        return (CGSize(width: width, height: height), { size, transition in
            transition.updateFrame(node: self.titleNode, frame: CGRect(x: 55, y: 12, width: width - 55, height: 24))
            transition.updateFrame(node: self.imageNode, frame: CGRect(x: 16, y: 9, width: 24, height: 24))
        })
    }
    
     func canBeHighlighted() -> Bool {
        return false
    }
    
     func updateIsHighlighted(isHighlighted: Bool) {
        
    }
    
     func performAction() {
        
    }
}

public class TBFlyButtonNode: ASButtonNode {
    let referenceNode: ContextReferenceContentNode
    let containerNode: ContextControllerSourceNode
    let imgNode: ASImageNode
    var contextAction: ((ASDisplayNode, ContextGesture?) -> Void)?
    
    init(presentationData: PresentationData) {
        self.referenceNode = ContextReferenceContentNode()
        self.containerNode = ContextControllerSourceNode()
        self.containerNode.animateScale = false
        self.imgNode = ASImageNode()
        self.imgNode.displaysAsynchronously = false
        super.init()
        self.containerNode.addSubnode(self.referenceNode)
        self.referenceNode.addSubnode(self.imgNode)
        self.addSubnode(self.containerNode)
        
        self.containerNode.shouldBegin = { [weak self] location in
            guard let strongSelf = self, let _ = strongSelf.contextAction else {
                return false
            }
            return true
        }
        self.containerNode.activated = { [weak self] gesture, _ in
            guard let strongSelf = self else {
                return
            }
            strongSelf.contextAction?(strongSelf.containerNode, gesture)
        }
        self.update(theme: presentationData.theme, strings: presentationData.strings)
    }
    
    public override func didLoad() {
        super.didLoad()
        self.view.isOpaque = false
    }
    
    func update(theme: PresentationTheme, strings: PresentationStrings) {
        self.imgNode.image = UIImage(named: "Chat/nav/btn_add_tittle_bar")
        self.imgNode.frame = CGRect(x: 7, y: 7, width: 30, height: 30)
        self.containerNode.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        self.referenceNode.frame = self.containerNode.bounds
    }
    
    public override func calculateSizeThatFits(_ constrainedSize: CGSize) -> CGSize {
        return CGSize(width: 44, height: 44)
    }

    func onLayout() {
    }
    
}
