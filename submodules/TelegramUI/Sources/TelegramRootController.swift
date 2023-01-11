import Foundation
import UIKit
import Display
import AsyncDisplayKit
import Postbox
import TelegramCore
import SwiftSignalKit
import TelegramPresentationData
import AccountContext
import ContactListUI
import CallListUI
import ChatListUI
import SettingsUI
import AppBundle
import DatePickerNode
import DebugSettingsUI
import TabBarUI
import PremiumUI
import ChatListUI
import TBAccount
import TBStorage
import TBNetwork
import TBTrack
import TBLanguage
import TelegramUIPreferences
import TBWalletUI
import TBWalletCore
import TBAnalyticsBridge
import TBCurrencyCommunity
import AGToolsCenterUI
import TBWebUI
import TBWalletCore

public final class TelegramRootController: NavigationController {
    private let context: AccountContext
    
    public var rootTabController: TabBarController?
    
    public var contactsController: ContactsController?
    public var callListController: CallListController?
    public var toolsCenterController: AGToolsCenterController?
    public var chatListController: ChatListController?
    public var accountSettingsController: PeerInfoScreen?
    public var currencyCommunityController: TBCurrencyCommunityHomeController?
    public var myWalletController: TBMyWalletController?
    
    private var permissionsDisposable: Disposable?
    private var presentationDataDisposable: Disposable?
    private var presentationData: PresentationData
    
    private var peerloginDisposable:Disposable?
    
    private var applicationInFocusDisposable: Disposable?


    
    private let disposable = MetaDisposable()

    
    private var flyNav : TBFlyNavManager?
        
    public init(context: AccountContext) {
        self.context = context
                
        
        let setLanguageCode = TBLanguage.sharedInstance.languageCode ?? TBLanguage.sharedInstance.getCurrentSystemLanguageCode()
        
        self.disposable.set((self.context.engine.localization.downloadAndApplyLocalization(accountManager: self.context.sharedContext.accountManager, languageCode: setLanguageCode)
        |> deliverOnMainQueue).start(error: {  _ in
            print("error")
        }, completed: {
            
            print("TG set language success ")
        }))
        
        let _ = (context.engine.privacy.requestAccountPrivacySettings() |> take(1)).start { accountPrivacySettings in
            if UserDefaults.standard.bool(forKey: "DontShowMyPhone") {
                var peerIds = [PeerId : SelectivePrivacyPeer]()
                switch accountPrivacySettings.phoneNumber {
                case let .disableEveryone(enablePeerIds):
                    peerIds = enablePeerIds
                case let .enableContacts(enablePeerIds, _):
                    peerIds = enablePeerIds
                default :
                    break
                }
                let updateSettingSignal =  context.engine.privacy.updateSelectiveAccountPrivacySettings(type: .phoneNumber, settings: .disableEveryone(enableFor: peerIds)) |> then(context.engine.privacy.updatePhoneNumberDiscovery(value: accountPrivacySettings.phoneDiscoveryEnabled))
              let _ = updateSettingSignal.start(completed:{
                    UserDefaults.standard.removeObject(forKey: "DontShowMyPhone")
                })
            }
        } error: { e in
            
        } completed: {
            
        }

        self.presentationData = context.sharedContext.currentPresentationData.with { $0 }
        
        let navigationDetailsBackgroundMode: NavigationEmptyDetailsBackgoundMode?
        switch presentationData.chatWallpaper {
        case .color:
            let image = generateTintedImage(image: UIImage(bundleImageName: "Chat List/EmptyMasterDetailIcon"), color: presentationData.theme.chatList.messageTextColor.withAlphaComponent(0.2))
            navigationDetailsBackgroundMode = image != nil ? .image(image!) : nil
        default:
            let image = chatControllerBackgroundImage(theme: presentationData.theme, wallpaper: presentationData.chatWallpaper, mediaBox: context.account.postbox.mediaBox, knockoutMode: context.sharedContext.immediateExperimentalUISettings.knockoutWallpaper)
            navigationDetailsBackgroundMode = image != nil ? .wallpaper(image!) : nil
        }
        
        super.init(mode: .automaticMasterDetail, theme: NavigationControllerTheme(presentationTheme: self.presentationData.theme), backgroundDetailsMode: navigationDetailsBackgroundMode)
        
        
        let _ = (context.sharedContext.accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.translationSettings])
                 |> take(1)
                 |> deliverOnMainQueue).start(next: { [weak self] sharedData in
            let translationSettings: TranslationSettings
            if let current = sharedData.entries[ApplicationSpecificSharedDataKeys.translationSettings]?.get(TranslationSettings.self) {
                translationSettings = current
            } else {
                translationSettings = TranslationSettings.defaultSettings
            }
          let _ = updateTranslationSettingsInteractively(accountManager: context.sharedContext.accountManager) { setting in
                var updated = setting
               updated = updated.withUpdatedShowTranslate(translationSettings.showTranslate)
               updated = updated.withUpdatedIgnoredLanguages(translationSettings.ignoredLanguages)
               return updated
          }.start()
        })
        
        TBAccount.shared.setup(context: self.context)
        self.peerloginDisposable = (self.context.engine.data.subscribe(TelegramEngine.EngineData.Item.Peer.Peer(id: self.context.account.peerId))|>distinctUntilChanged(isEqual: { ls, rs in
            if let ls = ls, let rs = rs{
                return ls._asPeer().id.toInt64() == rs._asPeer().id.toInt64()
            }
            return false
        })).start { peer in
            if let peer = peer?._asPeer() as? TelegramUser {
                TBWalletGroupManager.shared.setup(tgUserId:peer.id.id._internalGetInt64Value())
                debugPrint("[TB] peer: \(peer.id.id._internalGetInt64Value())")
                TBFlurry.shared.setUserId(String(peer.id.id._internalGetInt64Value()))
                let _ = TBAccount.shared.login(userId: peer.id.id._internalGetInt64Value(), newer: TBShareStorage.shared.is_tg_new_login).start(next: {
                    user in
                    storageToken(user.token)
                })
                
                TBWalletConnectManager.shared.setup(context: self.context)
                TBAccount.shared.setup(context: self.context)
                TBWalletConnectManager.shared.tryReconnectAllWallet()
            }
            self.setupsensitiveData()
        } error: { e in
            
        } completed: {

        }
        
        
        self.presentationDataDisposable = (context.sharedContext.presentationData
        |> deliverOnMainQueue).start(next: { [weak self] presentationData in
            if let strongSelf = self {
                if presentationData.chatWallpaper != strongSelf.presentationData.chatWallpaper {
                    let navigationDetailsBackgroundMode: NavigationEmptyDetailsBackgoundMode?
                    switch presentationData.chatWallpaper {
                        case .color:
                            let image = generateTintedImage(image: UIImage(bundleImageName: "Chat List/EmptyMasterDetailIcon"), color: presentationData.theme.chatList.messageTextColor.withAlphaComponent(0.2))
                            navigationDetailsBackgroundMode = image != nil ? .image(image!) : nil
                        default:
                            navigationDetailsBackgroundMode = chatControllerBackgroundImage(theme: presentationData.theme, wallpaper: presentationData.chatWallpaper, mediaBox: strongSelf.context.sharedContext.accountManager.mediaBox, knockoutMode: strongSelf.context.sharedContext.immediateExperimentalUISettings.knockoutWallpaper).flatMap(NavigationEmptyDetailsBackgoundMode.wallpaper)
                    }
                    strongSelf.updateBackgroundDetailsMode(navigationDetailsBackgroundMode, transition: .immediate)
                }

                let previousTheme = strongSelf.presentationData.theme
                strongSelf.presentationData = presentationData
                if previousTheme !== presentationData.theme {
                    (strongSelf.rootTabController as? TabBarControllerImpl)?.updateTheme(navigationBarPresentationData: NavigationBarPresentationData(presentationData: presentationData), theme: TabBarControllerTheme(rootControllerTheme: presentationData.theme))
                    strongSelf.rootTabController?.statusBar.statusBarStyle = presentationData.theme.rootController.statusBarStyle.style
                }
            }
        })
        
        if context.sharedContext.applicationBindings.isMainApp {
            self.applicationInFocusDisposable = (context.sharedContext.applicationBindings.applicationIsActive
            |> distinctUntilChanged
            |> deliverOn(Queue.mainQueue())).start(next: { value in
                context.sharedContext.mainWindow?.setForceBadgeHidden(!value)
            })
        }
    }
    

    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.permissionsDisposable?.dispose()
        self.presentationDataDisposable?.dispose()
        self.applicationInFocusDisposable?.dispose()
        self.peerloginDisposable?.dispose()

    }
    
    private func setupsensitiveData() {

        self.updateSensitive(enable:true)
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(appBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillTerminate), name: UIApplication.willTerminateNotification, object: nil)
    }
    
    
    
    @objc func appBecomeActive() {
        self.updateSensitive(enable:true)
    }
    
    @objc func appEnterBackground() {
        self.updateSensitive(enable:false)

    }
    
    @objc func applicationWillTerminate() {
        self.updateSensitive(enable:false)
    }
    
    private func updateSensitive(enable: Bool) {
        let updateSensitiveContentDisposable = MetaDisposable()
        updateSensitiveContentDisposable.set(updateRemoteContentSettingsConfiguration(postbox: context.account.postbox, network: context.account.network, sensitiveContentEnabled: enable).start())
    }
    
    
    public func addRootControllers(showCallsTab: Bool) {
        let tabBarController = TabBarControllerImpl(navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData), theme: TabBarControllerTheme(rootControllerTheme: self.presentationData.theme))
        tabBarController.navigationPresentation = .master
        tabBarController.didSelect = {[weak tabBarController] _ in
            if let strongTabCtrl = tabBarController {
                if let _ = strongTabCtrl.currentController as? ContactsController {
                    TBTrack.track(TBTrackEvent.Tab.contacts_tab_click.rawValue)
                }else if let _ = strongTabCtrl.currentController as? PeerInfoScreenImpl {
                    TBTrack.track(TBTrackEvent.Tab.settings_tab_click.rawValue)
                } else if let _ = strongTabCtrl.currentController as? TBCurrencyCommunityHomeController {
                    TBTrack.track(TBTrackEvent.Asset.profile_tab_click.rawValue)
                }
            }
        }
        let callListController = CallListController(context: self.context, mode: .tab)
        
        let currencyCommunityController = TBCurrencyCommunityHomeController(context: self.context)
        let myWalletController = TBMyWalletController(context: self.context)
        var controllers: [ViewController] = []
        
        let contactsController = ContactsController(context: self.context)
        contactsController.switchToChatsController = {  [weak self] in
            self?.openChatsController(activateSearch: false)
        }






        
        var restoreSettignsController: (ViewController & SettingsController)?
        if let sharedContext = self.context.sharedContext as? SharedAccountContextImpl {
            restoreSettignsController = sharedContext.switchingData.settingsController
        }
        restoreSettignsController?.updateContext(context: self.context)
        if let sharedContext = self.context.sharedContext as? SharedAccountContextImpl {
            sharedContext.switchingData = (nil, nil, nil)
        }
        
        
        let chatListController = self.context.sharedContext.makeChatListController(context: self.context, location: .chatList(groupId: .root), controlsHistoryPreload: true, hideNetworkActivityStatus: false, previewing: false, enableDebugActions: !GlobalExperimentalSettings.isAppStoreBuild)
        if let sharedContext = self.context.sharedContext as? SharedAccountContextImpl {
            chatListController.tabBarItem.badgeValue = sharedContext.switchingData.chatListBadge
        }
        controllers.append(chatListController)
        
        
        let toolsCenter = AGToolsCenterController(context: self.context)
        toolsCenter.tabBarItem.title = TBLanguage.sharedInstance.localizable(TBLankey.tb_tab_hot)
        toolsCenter.tabBarItem.image = UIImage(bundleImageName: "TabBar/btn_tools_navagation_off")!.withRenderingMode(UIImage.RenderingMode.alwaysOriginal)
        
        toolsCenter.tabBarItem.selectedImage = UIImage(bundleImageName: "TabBar/btn_tools_navagation_on")!.withRenderingMode(UIImage.RenderingMode.alwaysOriginal)
        controllers.append(toolsCenter)
        
        
        currencyCommunityController.tabBarItem.image = UIImage(bundleImageName: "TabBar/btn_groups_navagation_off")!.withRenderingMode(UIImage.RenderingMode.alwaysOriginal)
        
        currencyCommunityController.tabBarItem.selectedImage = UIImage(bundleImageName: "TabBar/btn_groups_navagation_on")!.withRenderingMode(UIImage.RenderingMode.alwaysOriginal)
        controllers.append(currencyCommunityController)
        

    
        
        let accountSettingsController = PeerInfoScreenImpl(context: self.context, updatedPresentationData: nil, peerId: self.context.account.peerId, avatarInitiallyExpanded: false, isOpenedFromChat: false, nearbyPeerDistance: nil, reactionSourceMessageId: nil, callMessages: [], isSettings: true)
        accountSettingsController.tabBarItemDebugTapAction = { [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.pushViewController(debugController(sharedContext: strongSelf.context.sharedContext, context: strongSelf.context))
        }
        
        
        
        myWalletController.tabBarItem.title = ""
        myWalletController.tabBarItem.image = UIImage(bundleImageName: "TabBar/btn_wallet_tab_off")!.withRenderingMode(UIImage.RenderingMode.alwaysOriginal)
        
        myWalletController.tabBarItem.selectedImage = UIImage(bundleImageName: "TabBar/btn_wallet_tab_on")!.withRenderingMode(UIImage.RenderingMode.alwaysOriginal)
        controllers.append(myWalletController)
        
        
        controllers.append(accountSettingsController)

        
        tabBarController.setControllers(controllers, selectedIndex: restoreSettignsController != nil ? (controllers.count - 1) : (0))
        
        self.contactsController = contactsController
        self.currencyCommunityController = currencyCommunityController
        self.callListController = callListController
        self.chatListController = chatListController
        self.toolsCenterController = toolsCenter
        self.accountSettingsController = accountSettingsController
        self.myWalletController = myWalletController
        self.rootTabController = tabBarController
        self.pushViewController(tabBarController, animated: false)
    }
        
    public func updateRootControllers(showCallsTab: Bool) {
        guard let rootTabController = self.rootTabController as? TabBarControllerImpl else {
            return
        }
        var controllers: [ViewController] = []
        controllers.append(self.chatListController!)
        if showCallsTab {
            controllers.append(self.callListController!)
        }
        controllers.append(self.toolsCenterController!)
        controllers.append(self.currencyCommunityController!)

        controllers.append(self.myWalletController!)
        controllers.append(self.accountSettingsController!)


        rootTabController.setControllers(controllers, selectedIndex: nil)
    }
    
    public func openChatsController(activateSearch: Bool, filter: ChatListSearchFilter = .chats, query: String? = nil) {
        guard let rootTabController = self.rootTabController else {
            return
        }
        
        if activateSearch {
            self.popToRoot(animated: false)
        }
        
        if let index = rootTabController.controllers.firstIndex(where: { $0 is ChatListController}) {
            rootTabController.selectedIndex = index
        }
        
        if activateSearch {
            self.chatListController?.activateSearch(filter: filter, query: query)
        }
    }
    
    public func openRootCompose() {
        self.chatListController?.activateCompose()
    }
    
    public func openRootCamera() {
        guard let controller = self.viewControllers.last as? ViewController else {
            return
        }
        controller.view.endEditing(true)
        presentedLegacyShortcutCamera(context: self.context, saveCapturedMedia: false, saveEditedPhotos: false, mediaGrouping: true, parentController: controller)
    }
}
