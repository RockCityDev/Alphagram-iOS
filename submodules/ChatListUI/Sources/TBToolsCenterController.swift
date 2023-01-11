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
import TBTransferAssetUI
import TBWalletCore

public class TBToolsCenterController: ViewController {
    
    public let context: AccountContext
    
    private let hideNetworkActivityStatus: Bool
    private var presentationData: PresentationData
    private let presentationDataValue = Promise<PresentationData>()
    private var presentationDataDisposable: Disposable?
    private var cacheUsageStatsDisposable: Disposable?
    private let cacheUsageStatsPromise: Promise<CacheUsageStats>
    
    private var toolsCenterDisplayNode: TBToolsCenterControllerNode {
        return super.displayNode as! TBToolsCenterControllerNode
    }
    
    public init(context: AccountContext, hideNetworkActivityStatus: Bool = false) {
        self.context = context
        self.hideNetworkActivityStatus = hideNetworkActivityStatus
        
        self.presentationData = (context.sharedContext.currentPresentationData.with { $0 })
        self.presentationDataValue.set(.single(self.presentationData))
        self.cacheUsageStatsPromise = Promise<CacheUsageStats>()
        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData))
        
        self.tabBarItemContextActionType = .always
        self.statusBar.statusBarStyle = self.presentationData.theme.rootController.statusBarStyle.style
        
#if DEBUG
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            self.navigationItem.title = TBLanguage.sharedInstance.localizable(TBLankey.home_commontools) + version
        }
#else
        self.navigationItem.title = TBLanguage.sharedInstance.localizable(TBLankey.home_commontools)
#endif
        
        self.navigationBar?.updateBarBackgroundColor(UIColor.white)
        let backBarButtonItem = UIBarButtonItem(image: UIImage(named: "Chat/nav/btn_back_tittle_bar"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(backAction))
        self.navigationItem.leftBarButtonItem = backBarButtonItem
        
        let statsPromise = Promise<CacheUsageStatsResult?>()
        statsPromise.set(cacheUsageStats(context: context))
        self.cacheUsageStatsDisposable = (statsPromise.get()
                 |> deliverOnMainQueue).start(next: { [weak self] result in
            if let result = result, case let .result(stats) = result {
                self?.cacheUsageStatsPromise.set(.single(stats))
            }
        })
        
        let _ = (self.cacheUsageStatsPromise.get() |> deliverOnMainQueue).start {[weak self] stats in
            var sizeIndex: [PeerCacheUsageCategory: (Bool, Int64)] = [:]
            var otherSize: (Bool, Int64) = (true, 0)
            for (_, categories) in stats.media {
                for (category, media) in categories {
                    var combinedSize: Int64 = 0
                    for (_, size) in media {
                        combinedSize += size
                    }
                    sizeIndex[category] = (true, (sizeIndex[category]?.1 ?? 0) + combinedSize)
                }
            }
            if stats.cacheSize + stats.otherSize + stats.tempSize > 10 * 1024 {
                otherSize = (true, stats.cacheSize + stats.otherSize + stats.tempSize)
            }

            var filteredSize = sizeIndex.values.reduce(0, { $0 + ($1.0 ? $1.1 : 0) })
            if otherSize.0 {
                filteredSize += otherSize.1
            }
            self?.toolsCenterDisplayNode.updateCacheTotal(filteredSize)
        }
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.presentationDataDisposable?.dispose()
        self.cacheUsageStatsDisposable?.dispose()
    }
    
    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.navigationBar?.updateBarBackgroundColor(UIColor.clear)
    }
    
    override public func loadDisplayNode() {
        self.displayNode = TBToolsCenterControllerNode(context: self.context, presentationData: self.presentationData, cleanCacheEvent: { [weak self] in
            if let strongSelf = self, let nav = strongSelf.navigationController {
                let vc = TBCleanCacheController(context: strongSelf.context, cacheStatsSignal: strongSelf.cacheUsageStatsPromise.get())
                vc.cleanEvent = {[weak self] stats in
                    self?.cacheUsageStatsPromise.set(.single(stats))
                }
                nav.pushViewController(vc, animated: true)
            }
        })
        self.displayNode.backgroundColor = UIColor.white
        self.toolsCenterDisplayNode.toolClickEvent = {[weak self] type in
            switch type {
            case .qr:
                if let strongSelf = self {
                    strongSelf.context.sharedContext.tb_flyStartNav(type: .qrCode, accountContext: strongSelf.context)
                }
            case .transferAsset:
                if let strongSelf = self {
                    if let c = TBWalletConnectManager.shared.getAllAvailabelConnecttions().first{
                        let controller = TBTransferToItController(context: strongSelf.context, wallet: .connect(c))
                        strongSelf.present(controller, in: .window(.root))
                    }else{
                        TBWalletConnectManager.shared.connectToPlatform(platform: .metaMask, callBack: { ret, c in
                            if let c = c, ret {
                                let controller = TBTransferToItController(context: strongSelf.context, wallet: .connect(c))
                                strongSelf.present(controller, in: .window(.root))
                            }
                        })
                    }
                }
            case .invite:
                if let strongSelf = self {
                    strongSelf.context.sharedContext.tb_flyStartNav(type: .newFriend, accountContext: strongSelf.context)
                }
            case .filter:
                if let strongSelf = self {
                    let vc = chatListFilterPresetListController(context: strongSelf.context, mode: .default)
                    strongSelf.navigationController?.pushViewController(vc, animated: true)
                }
            case .source:
                print("source")
            case .group:
                if let strongSelf = self, let nav = strongSelf.navigationController {
                    let vc = TBRecommendController(context: strongSelf.context, chatType: .group)
                    nav.pushViewController(vc, animated: true)
                }
            case let .official(type):
                let urlStr: String
                switch type {
                case .group:
                    urlStr = "https://t.me/alphagramgroup"
                case .channel:
                    urlStr = "https://t.me/alphagramio"
                case .englishGroup:
                    urlStr = "https://t.me/alphagramgroup"
                case .chineseGroup:
                    urlStr = "https://t.me/alphagramgroup"
                }
                if let strongSelf = self, let nav = strongSelf.navigationController as? NavigationController {
                    strongSelf.context.sharedContext.openResolvedUrl(ResolvedUrl.externalUrl(urlStr), context: strongSelf.context, urlContext: .generic, navigationController: nav, forceExternal: false, openPeer: { peerId, navigation in
                        
                    }, sendFile: nil, sendSticker: nil, requestMessageActionUrlAuth: nil, joinVoiceChat: nil, present: { vc, a in
                        
                    }, dismissInput: {
                        self?.view.window?.endEditing(true)
                    }, contentContext: nil)
                }
            case .chanal:
                if let strongSelf = self, let nav = strongSelf.navigationController {
                    let vc = TBRecommendController(context: strongSelf.context, chatType: .channel)
                    nav.pushViewController(vc, animated: true)
                }
            }
        }
    }
    
    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        self.updateLayout(layout: layout, transition: transition)
    }
    
    private func updateLayout(layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        self.toolsCenterDisplayNode.update(layout: layout, transition: transition)
    }
    
    @objc func backAction() {
        self.navigationBar?.backPressed()
    }
    
}


func cacheUsageStats(context: AccountContext) -> Signal<CacheUsageStatsResult?, NoError> {
    let containerPath = context.sharedContext.applicationBindings.containerPath
    let additionalPaths: [String] = [
        NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0],
        containerPath + "/Documents/files",
        containerPath + "/Documents/video",
        containerPath + "/Documents/audio",
        containerPath + "/Documents/mediacache",
        containerPath + "/Documents/tempcache_v1/store",
    ]
    return .single(nil)
    |> then(context.engine.resources.collectCacheUsageStats(additionalCachePaths: additionalPaths, logFilesPath: context.sharedContext.applicationBindings.containerPath + "/telegram-data/logs")
    |> map(Optional.init))
}
