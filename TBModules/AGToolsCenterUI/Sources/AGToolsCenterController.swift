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
import ChatListUI
import TBTransferAssetUI
import TBLanguage
import TBDisplay

public class AGToolsCenterController: ViewController {

    public let context: AccountContext

    private let hideNetworkActivityStatus: Bool
    private var presentationData: PresentationData
    private let presentationDataValue = Promise<PresentationData>()
    private var presentationDataDisposable: Disposable?
    private var cacheUsageStatsDisposable: Disposable?
    private let cacheUsageStatsPromise: Promise<CacheUsageStats>

    private var toolsCenterDisplayNode: AGToolsCenterControllerNode {
        return super.displayNode as! AGToolsCenterControllerNode
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

        self.navigationBar?.updateBarBackgroundColor(UIColor.white)
        self.presentationDataDisposable = (context.sharedContext.presentationData
        |> deliverOnMainQueue).start(next: { [weak self] presentationData in
            if let strongSelf = self {
                let previousTheme = strongSelf.presentationData.theme
                let previousStrings = strongSelf.presentationData.strings
                strongSelf.presentationData = presentationData
                strongSelf.presentationDataValue.set(.single(presentationData))
                strongSelf.updateThemeAndStrings()
            }
        })

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
        self.displayNode = AGToolsCenterControllerNode(context: self.context, presentationData: self.presentationData, cleanCacheEvent: { [weak self] in
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
            case .invite:
                if let strongSelf = self {
                    strongSelf.context.sharedContext.tb_flyStartNav(type: .newFriend, accountContext: strongSelf.context)
                }
            case .filter:
                if let strongSelf = self {
                    let vc = chatListFilterPresetListController(context: strongSelf.context, mode: .default)
                    strongSelf.navigationController?.pushViewController(vc, animated: true)
                }
                break
            case .group:
                if let strongSelf = self {
                    strongSelf.jumpToChat(by: "https://t.me/alphagramio")
                }
                break
            }
        }
        
        self.toolsCenterDisplayNode.groupToolsClickEvent = { [weak self] tools in
            guard let strongSelf = self else { return }
            switch tools.type {
            case .group:
                strongSelf.jumpToChat(by: tools.url)
            default:
                if let url = URL(string: tools.url) {
                    let web = TBWebviewController(context: strongSelf.context, webUrl: url)
                    strongSelf.push(web)
                }
            }
        }
    }
    
    func updateThemeAndStrings() {
        self.navigationItem.title = TBLanguage.sharedInstance.localizable(TBLankey.tb_tab_hot)
        self.tabBarItem.title = TBLanguage.sharedInstance.localizable(TBLankey.tb_tab_hot)
        self.toolsCenterDisplayNode.updateThemeAndStrings()
    }
    
    func jumpToChat(by url: String) {
        if let nav = self.navigationController as? NavigationController {
            self.context.sharedContext.openResolvedUrl(ResolvedUrl.externalUrl(url), context: self.context, urlContext: .generic, navigationController: nav, forceExternal: false, openPeer: { peerId, navigation in

            }, sendFile: nil, sendSticker: nil, requestMessageActionUrlAuth: nil, joinVoiceChat: nil, present: { vc, a in

            }, dismissInput: { [weak self] in
                self?.view.window?.endEditing(true)
            }, contentContext: nil)
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
