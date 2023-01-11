
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

enum ItemCategory: Hashable {
    case category(category: PeerCacheUsageCategory)
    case other
}

struct CacheItem {
    let category: ItemCategory
    let title: String
    let sizeText: String
    let selected: Bool
    let size: Int64
    
    init(_ category: ItemCategory, title: String, size: Int64, sizeText: String, selected: Bool = true) {
        self.category = category
        self.title = title
        self.size = size
        self.sizeText = sizeText
        self.selected = selected
    }
}


public class TBCleanCacheController: ViewController {
    
    public let context: AccountContext
    
    private let hideNetworkActivityStatus: Bool
    private var presentationData: PresentationData
    private let presentationDataValue = Promise<PresentationData>()
    private var presentationDataDisposable: Disposable?
    
    private var cacheStatsDisposable: Disposable?
    private let statsPromise: Promise<CacheUsageStats>
    private let normalCachePromise: Promise<[PeerCacheUsageCategory: (Bool, Int64)]>
    private let otherCachePromise: Promise<(Bool, Int64)>
    
    private var cleanCacheDisplayNode: TBCleanCacheControllerNode {
        return super.displayNode as! TBCleanCacheControllerNode
    }
    
    public var cleanEvent: ((CacheUsageStats) -> Void)?
    
    public init(context: AccountContext, cacheStatsSignal: Signal<CacheUsageStats, NoError>, hideNetworkActivityStatus: Bool = false) {
        self.context = context
        self.hideNetworkActivityStatus = hideNetworkActivityStatus
        
        self.presentationData = (context.sharedContext.currentPresentationData.with { $0 })
        self.presentationDataValue.set(.single(self.presentationData))
        
        self.statsPromise = Promise<CacheUsageStats>()
        self.normalCachePromise = Promise<[PeerCacheUsageCategory: (Bool, Int64)]>()
        self.otherCachePromise = Promise<(Bool, Int64)>()
        
        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData))
        
        self.tabBarItemContextActionType = .always
        self.statusBar.statusBarStyle = self.presentationData.theme.rootController.statusBarStyle.style
        self.navigationItem.title = TBLanguage.sharedInstance.localizable(TBLankey.ac_title_storage_clean)
        self.navigationBar?.updateBarBackgroundColor(UIColor.white)
        let backBarButtonItem = UIBarButtonItem(image: UIImage(named: "Chat/nav/btn_back_tittle_bar"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(backAction))
        self.navigationItem.leftBarButtonItem = backBarButtonItem
        self.cacheStatsDisposable = (cacheStatsSignal
                                     |> take(1)
                                     |> deliverOnMainQueue).start {[weak self] stats in
            self?.updateStats(stats)
        }
        
        let _ = (combineLatest(queue: .mainQueue(),
                      self.normalCachePromise.get(),
                      self.otherCachePromise.get())
         |> deliverOnMainQueue).start {[weak self] normal, other in
            guard let strongSelf = self else { return }
            var items = [CacheItem]()
            let validCategories: [PeerCacheUsageCategory] = [.image, .video, .audio, .file]
            for categoryId in validCategories {
                if let (selected, size) = normal[categoryId] {
                    let title = stringForCategory(strings: strongSelf.presentationData.strings, category: categoryId)
                    let sizeText = dataSizeString(size, formatting: DataSizeStringFormatting(presentationData: strongSelf.presentationData))
                    items.append(CacheItem(.category(category: categoryId), title: title, size: size, sizeText: sizeText, selected: selected))
                }
            }
            do {
                let title = strongSelf.presentationData.strings.Localization_LanguageOther
                let sizeText = dataSizeString(other.1, formatting: DataSizeStringFormatting(presentationData: strongSelf.presentationData))
                items.append(CacheItem(.other, title: title, size: other.1, sizeText: sizeText, selected: other.0))
            }
            strongSelf.cleanCacheDisplayNode.updateCacheItems(items)
        }
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.presentationDataDisposable?.dispose()
        self.cacheStatsDisposable?.dispose()
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.navigationBar?.updateBarBackgroundColor(UIColor.clear)
    }
    
    override public func loadDisplayNode() {
        self.displayNode = TBCleanCacheControllerNode(context: self.context, presentationData: self.presentationData, itemClickEvent: {[weak self] cacheItem in
            self?.cacheItemClick(cacheItem)
        })
        self.displayNode.backgroundColor = UIColor.white
        self.cleanCacheDisplayNode.cleanAction = { [weak self] in
            guard let strongSelf = self else { return .single(1) }
            let context = strongSelf.context
            let progressPromise = ValuePromise<Float>(0.0)
            let _ = (combineLatest(queue: .mainQueue(),
                                   strongSelf.statsPromise.get(),
                                   strongSelf.normalCachePromise.get(),
                                   strongSelf.otherCachePromise.get())
                     |> take(1)
                     |> deliverOnMainQueue).start { stats, normal, other in
                let clearCategories = normal.keys.filter({ normal[$0]!.0 })
                var clearMediaIds = Set<MediaId>()
                var media = stats.media
                for (peerId, categories) in stats.media {
                    var categories = categories
                    for category in clearCategories {
                        if let contents = categories[category] {
                            for (mediaId, _) in contents {
                                clearMediaIds.insert(mediaId)
                            }
                        }
                        categories.removeValue(forKey: category)
                    }
                    media[peerId] = categories
                }
                
                var clearResourceIds = Set<MediaResourceId>()
                for id in clearMediaIds {
                    if let ids = stats.mediaResourceIds[id] {
                        for resourceId in ids {
                            clearResourceIds.insert(resourceId)
                        }
                    }
                }
                
                var updatedOtherPaths = stats.otherPaths
                var updatedOtherSize = stats.otherSize
                var updatedCacheSize = stats.cacheSize
                var updatedTempPaths = stats.tempPaths
                var updatedTempSize = stats.tempSize
                
                var signal: Signal<Float, NoError> = context.engine.resources.clearCachedMediaResources(mediaResourceIds: clearResourceIds)
                if other.0 {
                    let removeTempFiles: Signal<Float, NoError> = Signal { subscriber in
                        let fileManager = FileManager.default
                        var count: Int = 0
                        let totalCount = stats.tempPaths.count
                        let reportProgress: (Int) -> Void = { count in
                            Queue.mainQueue().async {
                                subscriber.putNext(min(1.0, Float(count) / Float(totalCount)))
                            }
                        }
                        if totalCount == 0 {
                            subscriber.putNext(1.0)
                            subscriber.putCompletion()
                            return EmptyDisposable
                        }
                        for path in stats.tempPaths {
                            let _ = try? fileManager.removeItem(atPath: path)
                            count += 1
                            reportProgress(count)
                        }
                        subscriber.putCompletion()
                        return EmptyDisposable
                    } |> runOn(Queue.concurrentDefaultQueue())
                    signal = (signal |> map { $0 * 0.7 })
                    |> then(context.account.postbox.mediaBox.removeOtherCachedResources(paths: stats.otherPaths) |> map { 0.7 + 0.2 * $0 })
                    |> then(removeTempFiles |> map { 0.9 + 0.1 * $0 })
                }
                if other.0 {
                    updatedOtherPaths = []
                    updatedOtherSize = 0
                    updatedCacheSize = 0
                    updatedTempPaths = []
                    updatedTempSize = 0
                }
                let resultStats = CacheUsageStats(media: media, mediaResourceIds: stats.mediaResourceIds, peers: stats.peers, otherSize: updatedOtherSize, otherPaths: updatedOtherPaths, cacheSize: updatedCacheSize, tempPaths: updatedTempPaths, tempSize: updatedTempSize, immutableSize: stats.immutableSize)
                let _ = signal.start(next: { progress in
                    progressPromise.set(progress)
                }, completed: {
                    progressPromise.set(1)
                    self?.cleanEvent?(resultStats)
                    self?.updateStats(resultStats)
                })
            }
            return progressPromise.get()
        }
    }
    
    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        self.updateLayout(layout: layout, transition: transition)
    }
    
    private func updateLayout(layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        self.cleanCacheDisplayNode.update(layout: layout, transition: transition)
    }
    
    private func updateStats(_ stats: CacheUsageStats) {
        self.statsPromise.set(.single(stats))
        
        var sizeIndex: [PeerCacheUsageCategory: (Bool, Int64)] = [:]
        let sortCategories: [PeerCacheUsageCategory] = [.image, .video, .audio, .file]
        for cate in sortCategories {
            sizeIndex[cate] = (false, 0)
        }
        for (_, categories) in stats.media {
            for (category, media) in categories {
                var combinedSize: Int64 = 0
                for (_, size) in media {
                    combinedSize += size
                }
                sizeIndex[category] = (true, (sizeIndex[category]?.1 ?? 0) + combinedSize)
            }
        }
        self.normalCachePromise.set(.single(sizeIndex))
        
        let size = stats.cacheSize + stats.otherSize + stats.tempSize
        let otherSize: (Bool, Int64) = (size > 0, size)
        self.otherCachePromise.set(.single(otherSize))
    }
    
    @objc func backAction() {
        self.navigationBar?.backPressed()
    }
    
    private func cacheItemClick(_ cacheItem: CacheItem) {
        switch cacheItem.category {
        case let .category(category):
            let _ = (self.normalCachePromise.get()
                     |> take(1)
                     |> deliverOnMainQueue).start {[weak self] normal in
                var newNormal = normal
                if let value = newNormal[category] {
                    newNormal[category] = (!value.0, value.1)
                }
                self?.normalCachePromise.set(.single(newNormal))
            }
        case .other:
            let _ = (self.otherCachePromise.get()
                     |> take(1)
                     |> deliverOnMainQueue).start {[weak self] other in
                var newOther = other
                newOther.0 = !newOther.0
                self?.otherCachePromise.set(.single(newOther))
            }
        }
    }
}


private func stringForCategory(strings: PresentationStrings, category: PeerCacheUsageCategory) -> String {
    switch category {
        case .image:
            return strings.Cache_Photos
        case .video:
            return strings.Cache_Videos
        case .audio:
            return strings.Cache_Music
        case .file:
            return strings.Cache_Files
    }
}
