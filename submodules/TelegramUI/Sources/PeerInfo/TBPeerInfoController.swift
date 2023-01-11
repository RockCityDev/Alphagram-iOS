
import UIKit
import UIKit
import Postbox
import SwiftSignalKit
import AsyncDisplayKit
import Display
import TelegramCore
import TelegramPresentationData
import AccountContext
import TBLanguage
import PeerInfoUI
import PresentationDataUtils
import ShareController
import UndoUI
import TBWalletCore
import TBTransferAssetUI
import ProgressHUD
import TBTrack

class TBPeerInfoController: ViewController {

    public let context: AccountContext
    private var presentationData: PresentationData
    private let presentationDataValue = Promise<PresentationData>()
    private var presentationDataDisposable: Disposable?
    
    private let updatedPresentationData: (initial: PresentationData, signal: Signal<PresentationData, NoError>)?
    private let peer: Peer
    private let avatarInitiallyExpanded: Bool
    private let isOpenedFromChat: Bool
    private let nearbyPeerDistance: Int32?
    private let callMessages: [Message]
    private let hintGroupInCommon: PeerId?
    private let commonGroup: GroupsInCommonContext
    private let chatLocation: ChatLocation
    private let chatLocationContextHolder = Atomic<ChatLocationContextHolder?>(value: nil)
    private let controller: ViewController
    
    private var controllerNode: TBPeerInfoControllerNode {
        return self.displayNode as! TBPeerInfoControllerNode
    }
    
    private var commonGroupDisposable: Disposable?
    private var isAppearOnce = false
    
    public init(context: AccountContext, updatedPresentationData: (initial: PresentationData, signal: Signal<PresentationData, NoError>)?, peer: Peer, avatarInitiallyExpanded: Bool, isOpenedFromChat: Bool, nearbyPeerDistance: Int32?, callMessages: [Message], hintGroupInCommon: PeerId? = nil, fromController: ViewController) {
        self.context = context
        self.updatedPresentationData = updatedPresentationData
        self.peer = peer
        self.avatarInitiallyExpanded = avatarInitiallyExpanded
        self.isOpenedFromChat = isOpenedFromChat
        self.nearbyPeerDistance = nearbyPeerDistance
        self.callMessages = callMessages
        self.hintGroupInCommon = hintGroupInCommon
        self.commonGroup = GroupsInCommonContext(account: context.account, peerId: peer.id, hintGroupInCommon: hintGroupInCommon)
        self.presentationData = updatedPresentationData?.0 ?? context.sharedContext.currentPresentationData.with { $0 }
        self.chatLocation = .peer(id: peer.id)
        self.controller = fromController
        
        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData))
        
        self.displayNavigationBar = false
        let presentationDataSignal: Signal<PresentationData, NoError>
        if let updatedPresentationData = updatedPresentationData {
            presentationDataSignal = updatedPresentationData.signal
        } else {
            presentationDataSignal = context.sharedContext.presentationData
        }
        
        self.presentationDataDisposable = (presentationDataSignal
        |> deliverOnMainQueue).start(next: { [weak self] presentationData in
            if let strongSelf = self {
                let previousTheme = strongSelf.presentationData.theme
                let previousStrings = strongSelf.presentationData.strings
                strongSelf.presentationData = presentationData
                if previousTheme !== presentationData.theme || previousStrings !== presentationData.strings {
                    strongSelf.controllerNode.updatePresentationData(strongSelf.presentationData)
                }
            }
        })
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.presentationDataDisposable?.dispose()
        self.commonGroupDisposable?.dispose()
    }
    
    
    override public func loadDisplayNode() {
        let screenData = peerInfoScreenData(context: self.context, peerId: self.peer.id, strings: self.presentationData.strings, dateTimeFormat: self.presentationData.dateTimeFormat, isSettings: false, hintGroupInCommon: self.hintGroupInCommon, existingRequestsContext: nil, chatLocation: self.chatLocation, chatLocationContextHolder: self.chatLocationContextHolder)
        self.displayNode = TBPeerInfoControllerNode(context: self.context, presentationData: self.presentationData, peerId: self.peer.id, screenData: screenData)
        self.controllerNode.containNode.callBackEvent = { [weak self] in
            self?.dismiss(animated: true)
        }
        self.controllerNode.containNode.infoItemClickEvent = { [weak self] type in
            guard let strongSelf = self else { return }
            switch type {
            case .message:
                defer {
                    strongSelf.dismiss(animated: true)
                }
                if let navigationController = strongSelf.controller.navigationController as? NavigationController {
                    strongSelf.context.sharedContext.navigateToChatController(NavigateToChatControllerParams(navigationController: navigationController, context: strongSelf.context, chatLocation: .peer(EnginePeer(strongSelf.peer)) , keepStack: strongSelf.nearbyPeerDistance != nil ? .always : .default, peerNearbyData: strongSelf.nearbyPeerDistance.flatMap({ ChatPeerNearbyData(distance: $0) }), completion: { [weak self] _ in
                        if let strongSelf = self, strongSelf.nearbyPeerDistance != nil {
                            var viewControllers = navigationController.viewControllers
                            viewControllers = viewControllers.filter { controller in
                                if controller is PeerInfoScreen {
                                    return false
                                }
                                return true
                            }
                            navigationController.setViewControllers(viewControllers, animated: false)
                        }
                    }))
                }
            case .voice:
                strongSelf.context.requestCall(peerId: strongSelf.peer.id, isVideo: false, completion: {})
            case .secret:
                strongSelf.openStartSecretChat()
            case .addFriend:
                strongSelf.openAddContact()
            case .mainPage:
                let infoController = PeerInfoScreenImpl(
                    context: strongSelf.context,
                    updatedPresentationData: strongSelf.updatedPresentationData,
                    peerId: strongSelf.peer.id,
                    avatarInitiallyExpanded: strongSelf.avatarInitiallyExpanded,
                    isOpenedFromChat: strongSelf.isOpenedFromChat,
                    nearbyPeerDistance: strongSelf.nearbyPeerDistance,
                    reactionSourceMessageId:nil,
                    callMessages: strongSelf.callMessages,
                    hintGroupInCommon: strongSelf.hintGroupInCommon)
                if let nav = strongSelf.controller.navigationController {
                    defer {
                        strongSelf.dismiss(animated: true)
                    }
                    var viewControllers = nav.viewControllers
                    if viewControllers.count > 1 {
                        viewControllers.removeLast()
                        viewControllers.append(infoController)
                        nav.setViewControllers(viewControllers, animated: true)
                    } else {
                        nav.pushViewController(infoController, animated: true)
                    }
                }
            }
        }
        
        self.controllerNode.containNode.commonGroupClickEvent = { [weak self] peer in
            guard let strongSelf = self else { return }
            defer {
                strongSelf.dismiss(animated: true)
            }
            if let navigationController = strongSelf.controller.navigationController as? NavigationController {
                strongSelf.context.sharedContext.navigateToChatController(NavigateToChatControllerParams(navigationController: navigationController, context: strongSelf.context, chatLocation: .peer(EnginePeer(peer)), keepStack: .always))
            }
        }
        
        self.controllerNode.containNode.messageInGroupEvent = {[weak self] in
            self?.openChatWithMessageSearch()
        }
        
        self.controllerNode.containNode.peerIdClickEvent = { [weak self] peerId in
            if peerId.count <= 0 { return }
            self?.openUsername(value: peerId)
        }
        
        self.controllerNode.containNode.infoNode.walletNode.walletInfoTouchEvent = { [weak self] url in
            guard let strongSelf = self, let nav = strongSelf.controller.navigationController as? NavigationController  else { return }
            strongSelf.context.sharedContext.openExternalUrl(context: strongSelf.context, urlContext: .generic, url: url, forceExternal: false, presentationData: strongSelf.context.sharedContext.currentPresentationData.with { $0 }, navigationController: nav, dismissInput: {})
        }
        
        self.controllerNode.containNode.infoNode.walletNode.addressTouchEvent = { address in
            UIPasteboard.general.string = address
            ProgressHUD.showSucceed("")
        }
        
        self.controllerNode.containNode.infoNode.walletNode.checkWalletTouchEvent = { [weak self] address in
            TBTrack.track(TBTrackEvent.Transfer.user_profile_click.rawValue)
            guard let strongSelf = self else { return }
            strongSelf.dismiss(animated: true)
            let vc = strongSelf.context.sharedContext.makeMyWebPageController(context: strongSelf.context, peerId: strongSelf.peer.id, address: address, isMe: false)
            strongSelf.controller.push(vc)
        }
        
        self.controllerNode.containNode.infoNode.walletNode.transferEvent = { [weak self] address in
            TBTrack.track(TBTrackEvent.Transfer.user_profile_transfer.rawValue)
            guard let strongSelf = self, let nav = strongSelf.controller.navigationController as? NavigationController  else { return }
            if let c = TBWalletConnectManager.shared.getAllAvailabelConnecttions().first{
                let controller = TBTransferToItController(context: strongSelf.context, wallet: .connect(c), inputAddress: address)
                strongSelf.controller.present(controller, in: .window(.root))
            }else{
                TBWalletConnectManager.shared.connectToPlatform(platform: .metaMask, callBack: { ret, c in
                    if let c = c, ret {
                        let controller = TBTransferToItController(context: strongSelf.context, wallet: .connect(c), inputAddress: address)
                        strongSelf.controller.present(controller, in: .window(.root))
                    }
                })
            }
        }
        
        self.displayNodeDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.isAppearOnce {
            return
        }
        let location = SearchMessagesLocation.peer(peerId: self.hintGroupInCommon!, fromId: self.peer.id, tags: nil, topMsgId: nil, minDate: nil, maxDate: nil)
        let _ = self.context.engine.messages.searchMessages(location: location, query: "", state: nil, limit: 2).start(next: {[weak self] result in
            let totalCount = result.0.totalCount
            var time = "??"
            if let timestamp = result.0.messages.first?.timestamp {
                let format = DateFormatter()
                format.dateFormat = "yyyy/MM/dd HH:mm"
                time = format.string(from: Date(timeIntervalSince1970: Double(timestamp)))
            }
            self?.controllerNode.containNode.updateMessageInfo(totalCount: totalCount, timestamp: time)
        })
        self.commonGroupDisposable = self.commonGroup.state.start(next: {[weak self] state in
            var groups = [Peer]()
            for peer in state.peers {
                if let group = peer.peers[peer.peerId] {
                    groups.append(group)
                }
            }
            self?.controllerNode.containNode.updateCommonGroup(groups)
        })
        self.isAppearOnce = true
    }
    
    
    public override func displayNodeDidLoad() {
        super.displayNodeDidLoad()
    }
    
    
    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        self.controllerNode.update(layout: layout, transition: transition)
    }

    
    private func openAddContact() {
        let _ = (getUserPeer(engine: self.context.engine, peerId: self.peer.id)
        |> deliverOnMainQueue).start(next: { [weak self] peer in
            guard let strongSelf = self, let peer = peer else {
                return
            }
            openAddPersonContactImpl(context: strongSelf.context, peerId: peer.id, pushController: { c in
                defer {
                    self?.dismiss(animated: true)
                }
                self?.controller.push(c)
            }, present: { c, a in
                self?.present(c, in: .window(.root), with: a)
            })
        })
    }
    
    private func getUserPeer(engine: TelegramEngine, peerId: EnginePeer.Id) -> Signal<EnginePeer?, NoError> {
        return engine.data.get(TelegramEngine.EngineData.Item.Peer.Peer(id: peerId))
        |> mapToSignal { peer -> Signal<EnginePeer?, NoError> in
            guard let peer = peer else {
                return .single(nil)
            }
            if case let .secretChat(secretChat) = peer {
                return engine.data.get(TelegramEngine.EngineData.Item.Peer.Peer(id: secretChat.regularPeerId))
            } else {
                return .single(peer)
            }
        }
    }
    
    private func openStartSecretChat() {
        let peerId = self.peer.id
        let _ = (combineLatest(
            self.context.engine.data.get(TelegramEngine.EngineData.Item.Peer.Peer(id: self.peer.id)),
            self.context.engine.peers.mostRecentSecretChat(id: self.peer.id))
        |> deliverOnMainQueue).start(next: { [weak self] peer, currentPeerId in
            guard let strongSelf = self else { return }
            let displayTitle = peer?.displayTitle(strings: strongSelf.presentationData.strings, displayOrder: strongSelf.presentationData.nameDisplayOrder) ?? ""
            let vc = textAlertController(context: strongSelf.context, updatedPresentationData: strongSelf.updatedPresentationData, title: nil, text: strongSelf.presentationData.strings.UserInfo_StartSecretChatConfirmation(displayTitle).string, actions: [TextAlertAction(type: .genericAction, title: strongSelf.presentationData.strings.Common_Cancel, action: {}), TextAlertAction(type: .defaultAction, title: strongSelf.presentationData.strings.UserInfo_StartSecretChatStart, action: {
                guard let strongSelf = self else { return }
                var createSignal = strongSelf.context.engine.peers.createSecretChat(peerId: peerId)
                var cancelImpl: (() -> Void)?
                let progressSignal = Signal<Never, NoError> { subscriber in
                    if let strongSelf = self {
                        let statusController = OverlayStatusController(theme: strongSelf.presentationData.theme, type: .loading(cancelled: {
                            cancelImpl?()
                        }))
                        strongSelf.present(statusController, in: .window(.root))
                        return ActionDisposable { [weak statusController] in
                            Queue.mainQueue().async() {
                                statusController?.dismiss()
                            }
                        }
                    } else {
                        return EmptyDisposable
                    }
                }
                |> runOn(Queue.mainQueue())
                |> delay(0.15, queue: Queue.mainQueue())
                let progressDisposable = progressSignal.start()
                
                createSignal = createSignal
                |> afterDisposed {
                    Queue.mainQueue().async {
                        progressDisposable.dispose()
                    }
                }
                let createSecretChatDisposable = MetaDisposable()
                cancelImpl = {
                    createSecretChatDisposable.set(nil)
                }
                
                createSecretChatDisposable.set((createSignal
                |> deliverOnMainQueue).start(next: { peerId in
                    guard let strongSelf = self else {
                        return
                    }
                    defer {
                        strongSelf.dismiss(animated: true)
                    }
                    if let navigationController = (strongSelf.controller.navigationController as? NavigationController) {
                        strongSelf.context.sharedContext.navigateToChatController(NavigateToChatControllerParams(navigationController: navigationController, context: strongSelf.context, chatLocation: .peer(EnginePeer(strongSelf.peer))))
                    }
                }, error: { error in
                    guard let strongSelf = self else {
                        return
                    }
                    let text: String
                    switch error {
                        case .limitExceeded:
                            text = strongSelf.presentationData.strings.TwoStepAuth_FloodError
                        default:
                            text = strongSelf.presentationData.strings.Login_UnknownError
                    }
                    strongSelf.present(textAlertController(context: strongSelf.context, updatedPresentationData: strongSelf.updatedPresentationData, title: nil, text: text, actions: [TextAlertAction(type: .defaultAction, title: strongSelf.presentationData.strings.Common_OK, action: {})]), in: .window(.root))
                }))
            })])
            strongSelf.present(vc, in: .window(.root))
        })
    }
    
    private func openChatWithMessageSearch() {
        if let navigationController = self.controller.navigationController as? NavigationController, let groupid = self.hintGroupInCommon {
            let _ = (self.context.account.viewTracker.peerView(self.peer.id) |> take(1) |> deliverOnMainQueue).start(next: { [weak self] peerView in
                guard let strongSelf = self else { return }
                if let user = peerView.peers[peerView.peerId] {
                    defer {
                        strongSelf.dismiss(animated: true)
                    }
                    strongSelf.context.sharedContext.navigateToChatController(NavigateToChatControllerParams(navigationController: navigationController, context: strongSelf.context, chatLocation: .peer(EnginePeer(strongSelf.peer)), keepStack: strongSelf.nearbyPeerDistance != nil ? .always : .default, activateMessageSearch: (.member(user), ""), peerNearbyData: strongSelf.nearbyPeerDistance.flatMap({ ChatPeerNearbyData(distance: $0) }), completion: { [weak self] _ in
                        if let strongSelf = self, strongSelf.nearbyPeerDistance != nil {
                            var viewControllers = navigationController.viewControllers
                            viewControllers = viewControllers.filter { controller in
                                if controller is PeerInfoScreen {
                                    return false
                                }
                                return true
                            }
                            navigationController.setViewControllers(viewControllers, animated: false)
                        }
                    }))
                }
            })
        }
    }
    
    private func openUsername(value: String) {
        let shareController = ShareController(context: self.context, subject: .url("https://t.me/\(value)"), updatedPresentationData: self.updatedPresentationData)
        shareController.completed = { [weak self] peerIds in
            guard let strongSelf = self else {
                return
            }
            let _ = (strongSelf.context.engine.data.get(
                EngineDataList(
                    peerIds.map(TelegramEngine.EngineData.Item.Peer.Peer.init)
                )
            )
            |> deliverOnMainQueue).start(next: { [weak self] peerList in
                guard let strongSelf = self else {
                    return
                }
                
                let peers = peerList.compactMap { $0 }
                let presentationData = strongSelf.context.sharedContext.currentPresentationData.with { $0 }
                
                let text: String
                var savedMessages = false
                if peerIds.count == 1, let peerId = peerIds.first, peerId == strongSelf.context.account.peerId {
                    text = presentationData.strings.UserInfo_LinkForwardTooltip_SavedMessages_One
                    savedMessages = true
                } else {
                    if peers.count == 1, let peer = peers.first {
                        let peerName = peer.id == strongSelf.context.account.peerId ? presentationData.strings.DialogList_SavedMessages : peer.displayTitle(strings: presentationData.strings, displayOrder: presentationData.nameDisplayOrder)
                        text = presentationData.strings.UserInfo_LinkForwardTooltip_Chat_One(peerName).string
                    } else if peers.count == 2, let firstPeer = peers.first, let secondPeer = peers.last {
                        let firstPeerName = firstPeer.id == strongSelf.context.account.peerId ? presentationData.strings.DialogList_SavedMessages : firstPeer.displayTitle(strings: presentationData.strings, displayOrder: presentationData.nameDisplayOrder)
                        let secondPeerName = secondPeer.id == strongSelf.context.account.peerId ? presentationData.strings.DialogList_SavedMessages : secondPeer.displayTitle(strings: presentationData.strings, displayOrder: presentationData.nameDisplayOrder)
                        text = presentationData.strings.UserInfo_LinkForwardTooltip_TwoChats_One(firstPeerName, secondPeerName).string
                    } else if let peer = peers.first {
                        let peerName = peer.displayTitle(strings: presentationData.strings, displayOrder: presentationData.nameDisplayOrder)
                        text = presentationData.strings.UserInfo_LinkForwardTooltip_ManyChats_One(peerName, "\(peers.count - 1)").string
                    } else {
                        text = ""
                    }
                }
                
                strongSelf.present(UndoOverlayController(presentationData: presentationData, content: .forward(savedMessages: savedMessages, text: text), elevatedLayout: false, animateInAsReplacement: true, action: { _ in return false }), in: .current)
            })
        }
        shareController.actionCompleted = { [weak self] in
            if let strongSelf = self {
                let presentationData = strongSelf.context.sharedContext.currentPresentationData.with { $0 }
                strongSelf.present(UndoOverlayController(presentationData: presentationData, content: .linkCopied(text: presentationData.strings.Conversation_LinkCopied), elevatedLayout: false, animateInAsReplacement: false, action: { _ in return false }), in: .current)
            }
        }
        self.view.endEditing(true)
        self.present(shareController, in: .window(.root))
    }
}
