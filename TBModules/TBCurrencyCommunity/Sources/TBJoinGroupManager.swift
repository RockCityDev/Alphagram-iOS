






import UIKit
import Postbox
import SwiftSignalKit
import AsyncDisplayKit
import Display
import TelegramCore
import TelegramPresentationData
import AccountContext
import SegementSlide
import HandyJSON
import TBWeb3Core
import MJRefresh
import TBWalletCore
import ProgressHUD
import TBAccount


public class TBJoinGroupManager {
    
    
    public class func tryJoinGroup(_ params:TBJoinGroupParams) {
        
        if let tgGroupId = params.tgGroupId {
            
            self.tryDirectJoinGroupByTgGroupId(tgGroupId, params: params) { ret in
                if !ret {
                    
                    self.tryJoinGroupByGroupId(params.groupId, params: params)
                }
            }
        }else{
            self.tryJoinGroupByGroupId(params.groupId, params: params)
        }
    }
    
    
    private class func tryDirectJoinGroupByTgGroupId(_ tgGroupId: Int64, params: TBJoinGroupParams, callBack:@escaping (Bool)->Void){
        let peerId = PeerId(namespace: Namespaces.Peer.CloudGroup, id: PeerId.Id._internalFromInt64Value(tgGroupId))
        let _ = (params.context.engine.data.get(TelegramEngine.EngineData.Item.Peer.Peer(id: peerId)) |> take(1) |> deliverOnMainQueue).start(next:{ result in
            if let peer = result?._asPeer() as? TelegramGroup { 
                self.jumpByGroup(peer, params: params)
                callBack(true)
            }else{
                callBack(false)
            }
        })
    }
    
    
    private class func tryJoinGroupByGroupId(_ groupId:Int64, params: TBJoinGroupParams) {
        ProgressHUD.show()
        let _ = (TBWeb3GroupInteractor().web3GroupInfoSignal(group_id: String(params.groupId)) |> deliverOnMainQueue).start(next: { infoEntry in
            ProgressHUD.dismiss()
            if let infoEntry = infoEntry {
                
                self.tryDirectJoinGroupByTgGroupId(infoEntry.abs_tg_group_id(), params: params) { ret in
                    if !ret {
                        
                        self.tryJoinGroupByGroupInfo(infoEntry, params: params)
                    }
                }
            }
        })
    }
    
    
    private class func tryJoinGroupByGroupInfo(_ groupInfo: TBWeb3GroupInfoEntry, params: TBJoinGroupParams) {
        let joinType = TBWeb3GroupInfoEntry.LimitType.transferFrom(int: groupInfo.join_type)
        switch joinType {
        case .noLimit:
            self.tryJoinNoLimitGroup(by: groupInfo, params: params)
        case .payLimit:
            if let walletAddress = params.walletAddress, let connect = TBWalletConnectManager.shared.availableConnect(byWalletAccount: walletAddress) {
                self.tryJoinPayLimitGroup(by: groupInfo, params: params, walletConect: connect)
            }else{
                if let c = TBWalletConnectManager.shared.getAllAvailabelConnecttions().first {
                    self.tryJoinPayLimitGroup(by: groupInfo, params: params, walletConect: c)
                }else{
                    TBWalletConnectManager.shared.connectToPlatform(platform: .metaMask) { ret, connect in
                        if let connect = connect, ret == true {
                            self.tryJoinPayLimitGroup(by: groupInfo, params: params, walletConect: connect)
                        }
                    }
                }
                
            }
        case .conditionLimit:
            let connect: TBWalletConnect?
            if let walletAddress = params.walletAddress, let c = TBWalletConnectManager.shared.availableConnect(byWalletAccount: walletAddress) {
                connect = c
            }else{
                connect = TBWalletConnectManager.shared.getAllAvailabelConnecttions().first
            }
            self.tryJoinConditionLimitGroup(by: groupInfo, params: params, walletConect: connect)
        }
    }
    
    
    private class func tryJoinNoLimitGroup(by groupInfo: TBWeb3GroupInfoEntry, params: TBJoinGroupParams) {
        let groupId = groupInfo.id
        let _ = TBHomeInteractor.fetchGroupAccredit(by: "\(groupId)", payment_account: "").start(next: { order in
            if let url = order.ship?.url, url.isEmpty == false {
                self.jumpGroup(by: url, params: params)
            }
        })
    }
    
    
    private class func tryJoinPayLimitGroup(by groupInfo: TBWeb3GroupInfoEntry, params: TBJoinGroupParams,  walletConect:TBWalletConnect) {
        if let orderInfo = groupInfo.order_info.first, !orderInfo.tx_hash.isEmpty { 
            if !orderInfo.ship.url.isEmpty { 
                self.jumpGroup(by: orderInfo.ship.url, params: params)
            }else{
                Queue.mainQueue().after(0.2) {
                    ProgressHUD.showFailed("")
                }
            }
        }else{
            let _ = (TBWeb3Config.shared.configSignal |> take(1) |> deliverOnMainQueue).start(next: { config in
                if let config = config {
                    let groupInfoController = TBVipGroupInfoViewController(
                        context: params.context,
                        configEntry: config,
                        groupInfo: groupInfo,
                        walletConnect: walletConect)
                    params.inViewController?.push(groupInfoController)
                }
            })
        }
    }
    
    
    private class func tryJoinConditionLimitGroup(by groupInfo: TBWeb3GroupInfoEntry, params: TBJoinGroupParams, walletConect:TBWalletConnect?) {
        if let url = groupInfo.order_info.first?.ship.url, url.isEmpty == false  {
            self.jumpGroup(by: url, params: params)
            return
        }
        let _ = (TBWeb3Config.shared.configSignal |> deliverOnMainQueue).start(next: { config in
            if let config = config {
                let groupInfoController = TBVerifyGroupInfoController(
                    context: params.context,
                    configEntry: config,
                    groupInfo: groupInfo,
                    walletConnect: walletConect)
                groupInfoController.verifySuccessHandle = { [weak groupInfoController] url in
                    groupInfoController?.dismiss(animated: true)
                    self.jumpGroup(by: url, params: params)
                }
                params.inViewController?.push(groupInfoController)
            }
        })
    }
    

    
    
    private class func jumpGroup(by url: String, params: TBJoinGroupParams) {
        if let nav = params.inViewController?.navigationController as? NavigationController {
            params.context.sharedContext.openResolvedUrl(ResolvedUrl.externalUrl(url), context: params.context, urlContext: .generic, navigationController: nav, forceExternal: false, openPeer: { peerId, navigation in
            }, sendFile: nil, sendSticker: nil, requestMessageActionUrlAuth: nil, joinVoiceChat: nil, present: { vc, a in
            }, dismissInput: {
            }, contentContext: nil)
        }
    }
    
    
    private class func jumpByGroup(_ group: TelegramGroup, params: TBJoinGroupParams) {
        if let nav = params.inViewController?.navigationController as? NavigationController {
            params.context.sharedContext.navigateToChatController(NavigateToChatControllerParams(navigationController: nav, context: params.context, chatLocation: .peer(.legacyGroup(group))))
        }
    }
   
}
