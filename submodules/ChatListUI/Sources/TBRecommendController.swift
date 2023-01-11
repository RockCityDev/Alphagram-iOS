
import Foundation
import UIKit
import Postbox
import SwiftSignalKit
import AsyncDisplayKit
import Display
import TelegramCore
import TelegramPresentationData
import AccountContext
import TBLanguage
import HandyJSON
import TBNetwork

struct TBRecommendItem: HandyJSON {
    var chat_type: TBRecommendController.ChatType = .group
    var avatar: String?
    var chat_title: String?
    var chat_id: NSInteger = 0
    var chat_link: String?
    var online: Int = 0
    var follows: Int = 0
}

class TBRecommendController: ViewController {
    
    enum ChatType {
        case channel
        case group
        case bot
    }
    
    public let context: AccountContext
    
    private let chatType: ChatType
    private let hideNetworkActivityStatus: Bool
    private var presentationData: PresentationData
    private let presentationDataValue = Promise<PresentationData>()
    private var presentationDataDisposable: Disposable?
    
    private var recommendDisplayNode: TBRecommendControllerNode {
        return super.displayNode as! TBRecommendControllerNode
    }
    private var pageDispose: Disposable?
    private var defaultTitle: String

    public init(context: AccountContext, chatType: ChatType, hideNetworkActivityStatus: Bool = false) {
        self.context = context
        self.chatType = chatType
        self.hideNetworkActivityStatus = hideNetworkActivityStatus
        
        self.presentationData = (context.sharedContext.currentPresentationData.with { $0 })
        self.presentationDataValue.set(.single(self.presentationData))
        switch chatType {
        case .channel:
            self.defaultTitle = TBLanguage.sharedInstance.localizable(TBLankey.commontools_channel_recommend)
        case .group:
            self.defaultTitle = TBLanguage.sharedInstance.localizable(TBLankey.commontools_group_recommend)
        case .bot:
            self.defaultTitle = ""
        }
        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData))
        
        self.tabBarItemContextActionType = .always
        self.statusBar.statusBarStyle = self.presentationData.theme.rootController.statusBarStyle.style
        self.navigationItem.title = self.defaultTitle
        self.navigationBar?.updateBarBackgroundColor(UIColor.white)
        let backBarButtonItem = UIBarButtonItem(image: UIImage(named: "Chat/nav/btn_back_tittle_bar"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(backAction))
        self.navigationItem.leftBarButtonItem = backBarButtonItem
    }

    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.presentationDataDisposable?.dispose()
        self.pageDispose?.dispose()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.navigationBar?.updateBarBackgroundColor(UIColor.clear)
    }
    
    override public func loadDisplayNode() {
        self.displayNode = TBRecommendControllerNode(context: self.context, presentationData: self.presentationData)
        self.displayNode.backgroundColor = UIColor.white
        self.recommendDisplayNode.itemClickEvent = {[weak self] link in
            guard let strongSelf = self, let nav = strongSelf.navigationController as? NavigationController else { return }
            strongSelf.context.sharedContext.openResolvedUrl(ResolvedUrl.externalUrl("https://t.me/\(link)"), context: strongSelf.context, urlContext: .generic, navigationController: nav, forceExternal: false, openPeer: { peerId, navigation in
                
            }, sendFile: nil, sendSticker: nil, requestMessageActionUrlAuth: nil, joinVoiceChat: nil, present: { vc, a in
                
            }, dismissInput: {
                self?.view.window?.endEditing(true)
            }, contentContext: nil)
        }
        self.pageDispose = self.recommendDisplayNode.pagePromise.get().start {[weak self] page in
            guard let strongSelf = self, page > 0 else { return }
            let chatType: Int = {
                switch strongSelf.chatType {
                case .channel:
                    return 1
                case .group:
                    return 2
                case .bot:
                    return 3
                }
            }()
            self?.navigationItem.title = self?.presentationData.strings.State_Updating
            TBNetwork.request(api: Recommend.tgchatRecommend.rawValue,
                              method: .post,
                              paramsFillter: ["page" : "\(page)", "pageSize" : "15", "chat_type" : "\(chatType)"],
                              successHandle: {[weak self] data, message in
                self?.navigationItem.title = self?.defaultTitle
                if let data = data as? Dictionary<String, Any>, let data = data["data"] as? [Any] {
                    if let values = JSONDeserializer<TBRecommendItem>.deserializeModelArrayFrom(array: data)?.filter({$0 != nil}) {
                        self?.recommendDisplayNode.endRefresh(values.count < 15)
                        self?.recommendDisplayNode.iWillUseChineseAndShuaXinList(values as! [TBRecommendItem])
                        return
                    }
                }
                self?.recommendDisplayNode.endRefresh()
            }, failHandle: { [weak self] code, message in
                self?.navigationItem.title = self?.defaultTitle
                self?.recommendDisplayNode.endRefresh()
            })
        }
    }
    
    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        self.updateLayout(layout: layout, transition: transition)
    }
    
    private func updateLayout(layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        self.recommendDisplayNode.update(layout: layout, transition: transition)
    }

    @objc func backAction() {
        self.navigationBar?.backPressed()
    }
}
