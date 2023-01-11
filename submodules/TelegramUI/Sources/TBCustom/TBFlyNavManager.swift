






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
import ContactListUI
import ChatListUI


class TBFlyNavManager {
    
    private let type: TBFlyMenu
    private let context: AccountContext
    private let presentationData: PresentationData
    private var navigationController: NavigationController?
    private var viewController: ViewController?
    
    private let createActionDisposable = MetaDisposable()
    
    init(type: TBFlyMenu, accountContext:AccountContext) {
        self.type = type
        self.context = accountContext
        self.presentationData = self.context.sharedContext.currentPresentationData.with { $0 }
        
        
        if let navCtrl = self.context.sharedContext.mainWindow?.viewController as? NavigationController{
            self.navigationController = navCtrl
        }
        
        if let vc = self.navigationController?.viewControllers.last as? ViewController {
            self.viewController = vc
        }
    }
    
    
    func startNav() {
        switch self.type {
        case .qrCode:
            self.navQRScan()
        case .chatQRCode:
            self.navQRChat()
        case .linkDeviceQRCode:
            self.navQRLinkDevice()
        case .newFriend:
            self.navNewContact()
        case let .newGroup(chainName, chainId):
            self.navCreatGroup(chainName: chainName, chainId: chainId)
        case .newChannel:
            self.navNewChannel()
        case .startSeret:
            self.navSecretChat()
        default:
            self.emptyAction()
        }
    }
    
    
    private func navQRScan() {
        let context = self.context
        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        DeviceAccess.authorizeAccess(to: .camera(.qrCode), presentationData: presentationData, present: { c, a in
            c.presentationArguments = a
            context.sharedContext.mainWindow?.present(c, on: .root)
        }, openSettings: {
            context.sharedContext.applicationBindings.openSettings()
        }, { [weak self] granted in
            guard let strongSelf = self else {
                return
            }
            guard granted else {
                return
            }
            let activeSessionsContext = strongSelf.context.engine.privacy.activeSessions()
            let controller = TBQrCodeScanScreen(context: strongSelf.context, subject: .general(activeSessionsContext: activeSessionsContext))
            controller.showMyCode = { [weak self, weak controller] in
                if let strongSelf = self {
                    let _ = (strongSelf.context.account.postbox.loadedPeerWithId(strongSelf.context.account.peerId)
                             |> deliverOnMainQueue).start(next: { [weak self, weak controller] peer in
                        if let strongSelf = self, let controller = controller {
                            controller.present(strongSelf.context.sharedContext.makeChatQrCodeScreen(context: strongSelf.context, peer: peer, threadId: nil), in: .window(.root))
                        }
                    })
                }
            }
            strongSelf.navigationController?.pushViewController(controller, completion: {})
        })
    }
    
    
    private func navQRChat() {
        let context = self.context
        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        DeviceAccess.authorizeAccess(to: .camera(.qrCode), presentationData: presentationData, present: { c, a in
            c.presentationArguments = a
            context.sharedContext.mainWindow?.present(c, on: .root)
        }, openSettings: {
            context.sharedContext.applicationBindings.openSettings()
        }, { [weak self] granted in
            guard let strongSelf = self else {
                return
            }
            guard granted else {
                return
            }
            let controller = TBQrCodeScanScreen(context: strongSelf.context, subject: .peer)
            controller.showMyCode = { [weak self, weak controller] in
                if let strongSelf = self {
                    let _ = (strongSelf.context.account.postbox.loadedPeerWithId(strongSelf.context.account.peerId)
                             |> deliverOnMainQueue).start(next: { [weak self, weak controller] peer in
                        if let strongSelf = self, let controller = controller {
                            controller.present(strongSelf.context.sharedContext.makeChatQrCodeScreen(context: strongSelf.context, peer: peer, threadId: nil), in: .window(.root))
                        }
                    })
                }
            }
            strongSelf.navigationController?.pushViewController(controller, completion: {})
        })
    }
    
    
    private func navQRLinkDevice() {
        DeviceAccess.authorizeAccess(to: .camera(.qrCode), presentationData: presentationData, present: { c, a in
            c.presentationArguments = a
            self.context.sharedContext.mainWindow?.present(c, on: .root)
        }, openSettings: {
            self.context.sharedContext.applicationBindings.openSettings()
        }, { granted in
            guard granted else {
                return
            }
            let activeSessionsContext = self.context.engine.privacy.activeSessions()
            self.viewController?.push(TBQrCodeScanScreen(context: self.context, subject: .authTransfer(activeSessionsContext: activeSessionsContext)))
        })
    }
    
    
    private func navNewContact() {
        let _ = (DeviceAccess.authorizationStatus(subject: .contacts)
                 |> take(1)
                 |> deliverOnMainQueue).start(next: { [weak self] status in
            guard let strongSelf = self else {
                return
            }
            switch status {
            case .allowed:
                let contactData = DeviceContactExtendedData(basicData: DeviceContactBasicData(firstName: "", lastName: "", phoneNumbers: [DeviceContactPhoneNumberData(label: "_$!<Mobile>!$_", value: "+")]), middleName: "", prefix: "", suffix: "", organization: "", jobTitle: "", department: "", emailAddresses: [], urls: [], addresses: [], birthdayDate: nil, socialProfiles: [], instantMessagingProfiles: [], note: "")
                if let navigationController = strongSelf.context.sharedContext.mainWindow?.viewController as? NavigationController {
                    navigationController.pushViewController(strongSelf.context.sharedContext.makeDeviceContactInfoController(context: strongSelf.context, subject: .create(peer: nil, contactData: contactData, isSharing: false, shareViaException: false, completion: { peer, stableId, contactData in
                        guard let strongSelf = self else {
                            return
                        }
                        if let peer = peer {
                            DispatchQueue.main.async {
                                if let infoController = strongSelf.context.sharedContext.makePeerInfoController(context: strongSelf.context, updatedPresentationData: nil, peer: peer, mode: .generic, avatarInitiallyExpanded: false, fromChat: false, requestsContext: nil, fromViewController: nil) {
                                    if let navigationController = strongSelf.context.sharedContext.mainWindow?.viewController as? NavigationController {
                                        navigationController.pushViewController(infoController)
                                    }
                                }
                            }
                        } else {
                            if let navigationController = strongSelf.context.sharedContext.mainWindow?.viewController as? NavigationController {
                                navigationController.pushViewController(strongSelf.context.sharedContext.makeDeviceContactInfoController(context: strongSelf.context, subject: .vcard(nil, stableId, contactData), completed: nil, cancelled: nil))
                            }
                        }
                    }), completed: nil, cancelled: nil))
                }
            case .notDetermined:
                DeviceAccess.authorizeAccess(to: .contacts)
            default:
                let presentationData = strongSelf.presentationData
                if let navigationController = strongSelf.context.sharedContext.mainWindow?.viewController as? NavigationController, let topController = navigationController.topViewController as? ViewController {
                    topController.present(textAlertController(context: strongSelf.context, title: presentationData.strings.AccessDenied_Title, text: presentationData.strings.Contacts_AccessDeniedError, actions: [TextAlertAction(type: .defaultAction, title: presentationData.strings.Common_NotNow, action: {}), TextAlertAction(type: .genericAction, title: presentationData.strings.AccessDenied_Settings, action: {
                        self?.context.sharedContext.applicationBindings.openSettings()
                    })]), in: .window(.root))
                }
            }
        })
    }
    
    
    private func navCreatGroup(chainName: String?, chainId: String?){
        var peerIds: [ContactListPeerId] = []
        let createGroup = self.context.sharedContext.makeTBCreateGroupController(context: self.context, peerIds: peerIds.compactMap({ peerId in
            if case let .peer(peerId) = peerId {
                return peerId
            } else {
                return nil
            }
        }), chainName: chainName, chainId: chainId, initialTitle: nil, mode: .generic, completion: nil)
        self.navigationController?.pushViewController(createGroup)
    }
    
    private func creatGroupWithSelectPeers() {
        let controller = self.context.sharedContext.makeContactMultiselectionController(ContactMultiselectionControllerParams(context: self.context, mode: .groupCreation, options: []))
        self.navigationController?.pushViewController(controller, completion: {})
        self.createActionDisposable.set((controller.result
                                         |> deliverOnMainQueue).start(next: { [weak controller] result in
            var peerIds: [ContactListPeerId] = []
            if case let .result(peerIdsValue, _) = result {
                peerIds = peerIdsValue
            }
            
            if  let controller = controller {
                let createGroup = self.context.sharedContext.makeCreateGroupController(context: self.context, peerIds: peerIds.compactMap({ peerId in
                    if case let .peer(peerId) = peerId {
                        return peerId
                    } else {
                        return nil
                    }
                }), initialTitle: nil, mode: .generic, completion: nil)
                (controller.navigationController as? NavigationController)?.pushViewController(createGroup)
            }
        }))
    }
    
    
    private func navNewChannel() {
        let presentationData = self.context.sharedContext.currentPresentationData.with { $0 }
        let controller = PermissionController(context: self.context, splashScreen: true)
        controller.setState(.custom(icon: .animation("Channel"), title: presentationData.strings.ChannelIntro_Title, subtitle: nil, text: presentationData.strings.ChannelIntro_Text, buttonTitle: presentationData.strings.ChannelIntro_CreateChannel, secondaryButtonTitle: nil, footerText: nil), animated: false)
        controller.proceed = { [weak self] result in
            if let strongSelf = self {
                strongSelf.navigationController?.replaceTopController(createChannelController(context: strongSelf.context), animated: true)
            }
        }
        self.navigationController?.pushViewController(controller, completion: {})
    }
    
    
    private func navSecretChat(){
        let controller = ContactSelectionControllerImpl(ContactSelectionControllerParams(context: self.context, autoDismiss: false, title: { $0.Compose_NewEncryptedChatTitle }))
        self.createActionDisposable.set((controller.result
                                         |> take(1)
                                         |> deliverOnMainQueue).start(next: { [weak controller] result in
            if let (contactPeers, _, _, _, _) = result, case let .peer(peer, _, _) = contactPeers.first {
                controller?.dismissSearch()
                controller?.displayNavigationActivity = true
                self.createActionDisposable.set((self.context.engine.peers.createSecretChat(peerId: peer.id) |> deliverOnMainQueue).start(next: { peerId in
                    if let controller = controller {
                        controller.displayNavigationActivity = false
                        (controller.navigationController as? NavigationController)?.replaceAllButRootController(ChatControllerImpl(context: self.context, chatLocation: .peer(id: peerId)), animated: true)
                    }
                }, error: { error in
                    if let controller = controller {
                        let presentationData = self.context.sharedContext.currentPresentationData.with { $0 }
                        controller.displayNavigationActivity = false
                        let text: String
                        switch error {
                        case .limitExceeded:
                            text = presentationData.strings.TwoStepAuth_FloodError
                        default:
                            text = presentationData.strings.Login_UnknownError
                        }
                        controller.present(textAlertController(context: self.context, title: nil, text: text, actions: [TextAlertAction(type: .defaultAction, title: presentationData.strings.Common_OK, action: {})]), in: .window(.root))
                    }
                }))
            }
        }))
        self.navigationController?.pushViewController(controller, completion: {})
        
    }
    
    
    private func navInviteFriends() {
        let _ = (DeviceAccess.authorizationStatus(subject: .contacts)
                 |> take(1)
                 |> deliverOnMainQueue).start(next: { value in
            switch value {
            case .allowed:
                self.navigationController?.pushViewController(InviteContactsController(context: self.context), completion: {})
            case .notDetermined:
                DeviceAccess.authorizeAccess(to: .contacts)
            default:
                let presentationData = self.presentationData
                self.viewController?.present(textAlertController(context: self.context, title: presentationData.strings.AccessDenied_Title, text: presentationData.strings.Contacts_AccessDeniedError, actions: [TextAlertAction(type: .defaultAction, title: presentationData.strings.Common_NotNow, action: {}), TextAlertAction(type: .genericAction, title: presentationData.strings.AccessDenied_Settings, action: {
                    self.context.sharedContext.applicationBindings.openSettings()
                })]), in: .window(.root))
            }
        })
    }
    
    
    private func emptyAction() {
        
    }
    
    deinit {
        self.createActionDisposable.dispose()
    }
    
}
