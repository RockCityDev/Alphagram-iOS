import Foundation
import UIKit
import Display
import AsyncDisplayKit
import SwiftSignalKit
import AccountContext
import ChatPresentationInterfaceState
import ComponentFlow
import EntityKeyboard
import AnimationCache
import MultiAnimationRenderer
import Postbox
import TelegramCore
import ComponentDisplayAdapters
import SettingsUI
import TextFormat
import PagerComponent
import AppBundle
import PremiumUI
import AudioToolbox
import UndoUI
import ContextUI
import GalleryUI
import AttachmentTextInputPanelNode
import TelegramPresentationData
import TelegramNotices
import StickerPeekUI

final class EntityKeyboardGifContent: Equatable {
    let hasRecentGifs: Bool
    let component: GifPagerContentComponent
    
    init(hasRecentGifs: Bool, component: GifPagerContentComponent) {
        self.hasRecentGifs = hasRecentGifs
        self.component = component
    }
    
    static func ==(lhs: EntityKeyboardGifContent, rhs: EntityKeyboardGifContent) -> Bool {
        if lhs.hasRecentGifs != rhs.hasRecentGifs {
            return false
        }
        if lhs.component != rhs.component {
            return false
        }
        return true
    }
}

final class ChatEntityKeyboardInputNode: ChatInputNode {
    struct InputData: Equatable {
        var emoji: EmojiPagerContentComponent
        var stickers: EmojiPagerContentComponent?
        var gifs: EntityKeyboardGifContent?
        var availableGifSearchEmojies: [EntityKeyboardComponent.GifSearchEmoji]
        
        init(
            emoji: EmojiPagerContentComponent,
            stickers: EmojiPagerContentComponent?,
            gifs: EntityKeyboardGifContent?,
            availableGifSearchEmojies: [EntityKeyboardComponent.GifSearchEmoji]
        ) {
            self.emoji = emoji
            self.stickers = stickers
            self.gifs = gifs
            self.availableGifSearchEmojies = availableGifSearchEmojies
        }
    }
    
    static func hasPremium(context: AccountContext, chatPeerId: EnginePeer.Id?, premiumIfSavedMessages: Bool) -> Signal<Bool, NoError> {
        let hasPremium: Signal<Bool, NoError>
        if premiumIfSavedMessages, let chatPeerId = chatPeerId, chatPeerId == context.account.peerId {
            hasPremium = .single(true)
        } else {
            hasPremium = context.engine.data.subscribe(TelegramEngine.EngineData.Item.Peer.Peer(id: context.account.peerId))
            |> map { peer -> Bool in
                guard case let .user(user) = peer else {
                    return false
                }
                return user.isPremium
            }
            |> distinctUntilChanged
        }
        return hasPremium
    }
    
    static func inputData(context: AccountContext, interfaceInteraction: ChatPanelInterfaceInteraction, controllerInteraction: ChatControllerInteraction?, chatPeerId: PeerId?, areCustomEmojiEnabled: Bool) -> Signal<InputData, NoError> {
        let premiumConfiguration = PremiumConfiguration.with(appConfiguration: context.currentAppConfiguration.with { $0 })
        let isPremiumDisabled = premiumConfiguration.isPremiumDisabled
        
        let animationCache = context.animationCache
        let animationRenderer = context.animationRenderer
        
        let emojiItems = EmojiPagerContentComponent.emojiInputData(context: context, animationCache: animationCache, animationRenderer: animationRenderer, isStandalone: false, isStatusSelection: false, isReactionSelection: false, topReactionItems: [], areUnicodeEmojiEnabled: true, areCustomEmojiEnabled: areCustomEmojiEnabled, chatPeerId: chatPeerId)
        
        let stickerNamespaces: [ItemCollectionId.Namespace] = [Namespaces.ItemCollection.CloudStickerPacks]
        let stickerOrderedItemListCollectionIds: [Int32] = [Namespaces.OrderedItemList.CloudSavedStickers, Namespaces.OrderedItemList.CloudRecentStickers, Namespaces.OrderedItemList.CloudAllPremiumStickers]
        
        struct PeerSpecificPackData: Equatable {
            var info: StickerPackCollectionInfo
            var items: [StickerPackItem]
            var peer: EnginePeer
            
            static func ==(lhs: PeerSpecificPackData, rhs: PeerSpecificPackData) -> Bool {
                if lhs.info.id != rhs.info.id {
                    return false
                }
                if lhs.items != rhs.items {
                    return false
                }
                if lhs.peer != rhs.peer {
                    return false
                }
                
                return true
            }
        }
        
        let peerSpecificPack: Signal<PeerSpecificPackData?, NoError>
        if let chatPeerId = chatPeerId {
            peerSpecificPack = combineLatest(
                context.engine.peers.peerSpecificStickerPack(peerId: chatPeerId),
                context.engine.data.subscribe(TelegramEngine.EngineData.Item.Peer.Peer(id: chatPeerId))
            )
            |> map { packData, peer -> PeerSpecificPackData? in
                guard let peer = peer else {
                    return nil
                }
                
                guard let (info, items) = packData.packInfo else {
                    return nil
                }
                
                return PeerSpecificPackData(info: info, items: items.compactMap { $0 as? StickerPackItem }, peer: peer)
            }
            |> distinctUntilChanged
        } else {
            peerSpecificPack = .single(nil)
        }
        
        let strings = context.sharedContext.currentPresentationData.with({ $0 }).strings
        
        let stickerItems: Signal<EmojiPagerContentComponent, NoError> = combineLatest(
            context.account.postbox.itemCollectionsView(orderedItemListCollectionIds: stickerOrderedItemListCollectionIds, namespaces: stickerNamespaces, aroundIndex: nil, count: 10000000),
            ChatEntityKeyboardInputNode.hasPremium(context: context, chatPeerId: chatPeerId, premiumIfSavedMessages: false),
            context.account.viewTracker.featuredStickerPacks(),
            context.engine.data.get(TelegramEngine.EngineData.Item.ItemCache.Item(collectionId: Namespaces.CachedItemCollection.featuredStickersConfiguration, id: ValueBoxKey(length: 0))),
            ApplicationSpecificNotice.dismissedTrendingStickerPacks(accountManager: context.sharedContext.accountManager),
            peerSpecificPack
        )
        |> map { view, hasPremium, featuredStickerPacks, featuredStickersConfiguration, dismissedTrendingStickerPacks, peerSpecificPack -> EmojiPagerContentComponent in
            struct ItemGroup {
                var supergroupId: AnyHashable
                var id: AnyHashable
                var title: String
                var subtitle: String?
                var actionButtonTitle: String?
                var isPremiumLocked: Bool
                var isFeatured: Bool
                var displayPremiumBadges: Bool
                var headerItem: EntityKeyboardAnimationData?
                var items: [EmojiPagerContentComponent.Item]
            }
            var itemGroups: [ItemGroup] = []
            var itemGroupIndexById: [AnyHashable: Int] = [:]
            
            var savedStickers: OrderedItemListView?
            var recentStickers: OrderedItemListView?
            var cloudPremiumStickers: OrderedItemListView?
            for orderedView in view.orderedItemListsViews {
                if orderedView.collectionId == Namespaces.OrderedItemList.CloudRecentStickers {
                    recentStickers = orderedView
                } else if orderedView.collectionId == Namespaces.OrderedItemList.CloudSavedStickers {
                    savedStickers = orderedView
                } else if orderedView.collectionId == Namespaces.OrderedItemList.CloudAllPremiumStickers {
                    cloudPremiumStickers = orderedView
                }
            }
            
            var installedCollectionIds = Set<ItemCollectionId>()
            for (id, _, _) in view.collectionInfos {
                installedCollectionIds.insert(id)
            }
            
            let dismissedTrendingStickerPacksSet = Set(dismissedTrendingStickerPacks ?? [])
            let featuredStickerPacksSet = Set(featuredStickerPacks.map(\.info.id.id))
            
            if dismissedTrendingStickerPacksSet != featuredStickerPacksSet {
                let featuredStickersConfiguration = featuredStickersConfiguration?.get(FeaturedStickersConfiguration.self)
                for featuredStickerPack in featuredStickerPacks {
                    if installedCollectionIds.contains(featuredStickerPack.info.id) {
                        continue
                    }
                    
                    guard let item = featuredStickerPack.topItems.first else {
                        continue
                    }
                    
                    let animationData: EntityKeyboardAnimationData
                    
                    if let thumbnail = featuredStickerPack.info.thumbnail {
                        let type: EntityKeyboardAnimationData.ItemType
                        if item.file.isAnimatedSticker {
                            type = .lottie
                        } else if item.file.isVideoEmoji || item.file.isVideoSticker {
                            type = .video
                        } else {
                            type = .still
                        }
                        
                        animationData = EntityKeyboardAnimationData(
                            id: .stickerPackThumbnail(featuredStickerPack.info.id),
                            type: type,
                            resource: .stickerPackThumbnail(stickerPack: .id(id: featuredStickerPack.info.id.id, accessHash: featuredStickerPack.info.accessHash), resource: thumbnail.resource),
                            dimensions: thumbnail.dimensions.cgSize,
                            immediateThumbnailData: featuredStickerPack.info.immediateThumbnailData,
                            isReaction: false
                        )
                    } else {
                        animationData = EntityKeyboardAnimationData(file: item.file)
                    }
                    
                    let resultItem = EmojiPagerContentComponent.Item(
                        animationData: animationData,
                        content: .animation(animationData),
                        itemFile: item.file,
                        subgroupId: nil,
                        icon: .none,
                        accentTint: false
                    )
                    
                    let supergroupId = "featuredTop"
                    let groupId: AnyHashable = supergroupId
                    let isPremiumLocked: Bool = item.file.isPremiumSticker && !hasPremium
                    if isPremiumLocked && isPremiumDisabled {
                        continue
                    }
                    if let groupIndex = itemGroupIndexById[groupId] {
                        itemGroups[groupIndex].items.append(resultItem)
                    } else {
                        itemGroupIndexById[groupId] = itemGroups.count
                        
                        let trendingIsPremium = featuredStickersConfiguration?.isPremium ?? false
                        let title = trendingIsPremium ? strings.Stickers_TrendingPremiumStickers : strings.StickerPacksSettings_FeaturedPacks
                        
                        itemGroups.append(ItemGroup(supergroupId: groupId, id: groupId, title: title, subtitle: nil, actionButtonTitle: nil, isPremiumLocked: false, isFeatured: false, displayPremiumBadges: false, headerItem: nil, items: [resultItem]))
                    }
                }
            }
            
            if let savedStickers = savedStickers {
                for item in savedStickers.items {
                    guard let item = item.contents.get(SavedStickerItem.self) else {
                        continue
                    }
                    if isPremiumDisabled && item.file.isPremiumSticker {
                        continue
                    }
                    
                    let animationData = EntityKeyboardAnimationData(file: item.file)
                    let resultItem = EmojiPagerContentComponent.Item(
                        animationData: animationData,
                        content: .animation(animationData),
                        itemFile: item.file,
                        subgroupId: nil,
                        icon: .none,
                        accentTint: false
                    )
                    
                    let groupId = "saved"
                    if let groupIndex = itemGroupIndexById[groupId] {
                        itemGroups[groupIndex].items.append(resultItem)
                    } else {
                        itemGroupIndexById[groupId] = itemGroups.count
                        itemGroups.append(ItemGroup(supergroupId: groupId, id: groupId, title: strings.EmojiInput_SectionTitleFavoriteStickers, subtitle: nil, actionButtonTitle: nil, isPremiumLocked: false, isFeatured: false, displayPremiumBadges: false, headerItem: nil, items: [resultItem]))
                    }
                }
            }
            
            if let recentStickers = recentStickers {
                for item in recentStickers.items {
                    guard let item = item.contents.get(RecentMediaItem.self) else {
                        continue
                    }
                    if isPremiumDisabled && item.media.isPremiumSticker {
                        continue
                    }
                    
                    let animationData = EntityKeyboardAnimationData(file: item.media)
                    let resultItem = EmojiPagerContentComponent.Item(
                        animationData: animationData,
                        content: .animation(animationData),
                        itemFile: item.media,
                        subgroupId: nil,
                        icon: .none,
                        accentTint: false
                    )
                    
                    let groupId = "recent"
                    if let groupIndex = itemGroupIndexById[groupId] {
                        itemGroups[groupIndex].items.append(resultItem)
                    } else {
                        itemGroupIndexById[groupId] = itemGroups.count
                        itemGroups.append(ItemGroup(supergroupId: groupId, id: groupId, title: strings.Stickers_FrequentlyUsed, subtitle: nil, actionButtonTitle: nil, isPremiumLocked: false, isFeatured: false, displayPremiumBadges: false, headerItem: nil, items: [resultItem]))
                    }
                }
            }
            
            var premiumStickers: [StickerPackItem] = []
            if hasPremium {
                for entry in view.entries {
                    guard let item = entry.item as? StickerPackItem else {
                        continue
                    }
                    
                    if item.file.isPremiumSticker {
                        premiumStickers.append(item)
                    }
                }
                
                if let cloudPremiumStickers = cloudPremiumStickers, !cloudPremiumStickers.items.isEmpty {
                    premiumStickers.append(contentsOf: cloudPremiumStickers.items.compactMap { item -> StickerPackItem? in guard let item = item.contents.get(RecentMediaItem.self) else {
                            return nil
                        }
                        return StickerPackItem(index: ItemCollectionItemIndex(index: 0, id: 0), file: item.media, indexKeys: [])
                    })
                }
            }
            
            if !premiumStickers.isEmpty {
                var processedIds = Set<MediaId>()
                for item in premiumStickers {
                    if isPremiumDisabled && item.file.isPremiumSticker {
                        continue
                    }
                    if processedIds.contains(item.file.fileId) {
                        continue
                    }
                    processedIds.insert(item.file.fileId)
                    
                    let animationData = EntityKeyboardAnimationData(file: item.file)
                    let resultItem = EmojiPagerContentComponent.Item(
                        animationData: animationData,
                        content: .animation(animationData),
                        itemFile: item.file,
                        subgroupId: nil,
                        icon: .none,
                        accentTint: false
                    )
                    
                    let groupId = "premium"
                    if let groupIndex = itemGroupIndexById[groupId] {
                        itemGroups[groupIndex].items.append(resultItem)
                    } else {
                        itemGroupIndexById[groupId] = itemGroups.count
                        itemGroups.append(ItemGroup(supergroupId: groupId, id: groupId, title: strings.EmojiInput_SectionTitlePremiumStickers, subtitle: nil, actionButtonTitle: nil, isPremiumLocked: false, isFeatured: false, displayPremiumBadges: false, headerItem: nil, items: [resultItem]))
                    }
                }
            }
            
            var avatarPeer: EnginePeer?
            if let peerSpecificPack = peerSpecificPack {
                avatarPeer = peerSpecificPack.peer
                
                var processedIds = Set<MediaId>()
                for item in peerSpecificPack.items {
                    if isPremiumDisabled && item.file.isPremiumSticker {
                        continue
                    }
                    if processedIds.contains(item.file.fileId) {
                        continue
                    }
                    processedIds.insert(item.file.fileId)
                    
                    let animationData = EntityKeyboardAnimationData(file: item.file)
                    let resultItem = EmojiPagerContentComponent.Item(
                        animationData: animationData,
                        content: .animation(animationData),
                        itemFile: item.file,
                        subgroupId: nil,
                        icon: .none,
                        accentTint: false
                    )
                    
                    let groupId = "peerSpecific"
                    if let groupIndex = itemGroupIndexById[groupId] {
                        itemGroups[groupIndex].items.append(resultItem)
                    } else {
                        itemGroupIndexById[groupId] = itemGroups.count
                        itemGroups.append(ItemGroup(supergroupId: groupId, id: groupId, title: peerSpecificPack.peer.compactDisplayTitle, subtitle: nil, actionButtonTitle: nil, isPremiumLocked: false, isFeatured: false, displayPremiumBadges: false, headerItem: nil, items: [resultItem]))
                    }
                }
            }
            
            for entry in view.entries {
                guard let item = entry.item as? StickerPackItem else {
                    continue
                }
                let animationData = EntityKeyboardAnimationData(file: item.file)
                let resultItem = EmojiPagerContentComponent.Item(
                    animationData: animationData,
                    content: .animation(animationData),
                    itemFile: item.file,
                    subgroupId: nil,
                    icon: .none,
                    accentTint: false
                )
                let groupId = entry.index.collectionId
                if let groupIndex = itemGroupIndexById[groupId] {
                    itemGroups[groupIndex].items.append(resultItem)
                } else {
                    itemGroupIndexById[groupId] = itemGroups.count
                    
                    var title = ""
                    var headerItem: EntityKeyboardAnimationData?
                    inner: for (id, info, _) in view.collectionInfos {
                        if id == groupId, let info = info as? StickerPackCollectionInfo {
                            title = info.title
                            
                            if let thumbnail = info.thumbnail {
                                let type: EntityKeyboardAnimationData.ItemType
                                if item.file.isAnimatedSticker {
                                    type = .lottie
                                } else if item.file.isVideoEmoji || item.file.isVideoSticker {
                                    type = .video
                                } else {
                                    type = .still
                                }
                                
                                headerItem = EntityKeyboardAnimationData(
                                    id: .stickerPackThumbnail(info.id),
                                    type: type,
                                    resource: .stickerPackThumbnail(stickerPack: .id(id: info.id.id, accessHash: info.accessHash), resource: thumbnail.resource),
                                    dimensions: thumbnail.dimensions.cgSize,
                                    immediateThumbnailData: info.immediateThumbnailData,
                                    isReaction: false
                                )
                            }
                            
                            break inner
                        }
                    }
                    itemGroups.append(ItemGroup(supergroupId: groupId, id: groupId, title: title, subtitle: nil, actionButtonTitle: nil, isPremiumLocked: false, isFeatured: false, displayPremiumBadges: true, headerItem: headerItem, items: [resultItem]))
                }
            }
            
            for featuredStickerPack in featuredStickerPacks {
                if installedCollectionIds.contains(featuredStickerPack.info.id) {
                    continue
                }
                
                for item in featuredStickerPack.topItems {
                    let animationData = EntityKeyboardAnimationData(file: item.file)
                    let resultItem = EmojiPagerContentComponent.Item(
                        animationData: animationData,
                        content: .animation(animationData),
                        itemFile: item.file,
                        subgroupId: nil,
                        icon: .none,
                        accentTint: false
                    )
                    
                    let supergroupId = featuredStickerPack.info.id
                    let groupId: AnyHashable = supergroupId
                    let isPremiumLocked: Bool = item.file.isPremiumSticker && !hasPremium
                    if isPremiumLocked && isPremiumDisabled {
                        continue
                    }
                    if let groupIndex = itemGroupIndexById[groupId] {
                        itemGroups[groupIndex].items.append(resultItem)
                    } else {
                        itemGroupIndexById[groupId] = itemGroups.count
                        
                        let subtitle: String = strings.StickerPack_StickerCount(Int32(featuredStickerPack.info.count))
                        var headerItem: EntityKeyboardAnimationData?
                        
                        if let thumbnailFileId = featuredStickerPack.info.thumbnailFileId, let file = featuredStickerPack.topItems.first(where: { $0.file.fileId.id == thumbnailFileId }) {
                            headerItem = EntityKeyboardAnimationData(file: file.file)
                        } else if let thumbnail = featuredStickerPack.info.thumbnail {
                            let info = featuredStickerPack.info
                            let type: EntityKeyboardAnimationData.ItemType
                            if item.file.isAnimatedSticker {
                                type = .lottie
                            } else if item.file.isVideoEmoji || item.file.isVideoSticker {
                                type = .video
                            } else {
                                type = .still
                            }
                            
                            headerItem = EntityKeyboardAnimationData(
                                id: .stickerPackThumbnail(info.id),
                                type: type,
                                resource: .stickerPackThumbnail(stickerPack: .id(id: info.id.id, accessHash: info.accessHash), resource: thumbnail.resource),
                                dimensions: thumbnail.dimensions.cgSize,
                                immediateThumbnailData: info.immediateThumbnailData,
                                isReaction: false
                            )
                        }
                        
                        itemGroups.append(ItemGroup(supergroupId: groupId, id: groupId, title: featuredStickerPack.info.title, subtitle: subtitle, actionButtonTitle: strings.Stickers_Install, isPremiumLocked: isPremiumLocked, isFeatured: true, displayPremiumBadges: false, headerItem: headerItem, items: [resultItem]))
                    }
                }
            }
            
            return EmojiPagerContentComponent(
                id: "stickers",
                context: context,
                avatarPeer: avatarPeer,
                animationCache: animationCache,
                animationRenderer: animationRenderer,
                inputInteractionHolder: EmojiPagerContentComponent.InputInteractionHolder(),
                itemGroups: itemGroups.map { group -> EmojiPagerContentComponent.ItemGroup in
                    var hasClear = false
                    var isEmbedded = false
                    if group.id == AnyHashable("recent") {
                        hasClear = true
                    } else if group.id == AnyHashable("featuredTop") {
                        hasClear = true
                        isEmbedded = true
                    }
                    
                    return EmojiPagerContentComponent.ItemGroup(
                        supergroupId: group.supergroupId,
                        groupId: group.id,
                        title: group.title,
                        subtitle: group.subtitle,
                        actionButtonTitle: group.actionButtonTitle,
                        isFeatured: group.isFeatured,
                        isPremiumLocked: group.isPremiumLocked,
                        isEmbedded: isEmbedded,
                        hasClear: hasClear,
                        collapsedLineCount: nil,
                        displayPremiumBadges: group.displayPremiumBadges,
                        headerItem: group.headerItem,
                        items: group.items
                    )
                },
                itemLayoutType: .detailed,
                itemContentUniqueId: nil,
                warpContentsOnEdges: false,
                displaySearchWithPlaceholder: nil,
                emptySearchResults: nil,
                enableLongPress: false,
                selectedItems: Set()
            )
        }
        
        let reactions: Signal<[String], NoError> = context.engine.data.subscribe(TelegramEngine.EngineData.Item.Configuration.App())
        |> map { appConfiguration -> [String] in
            let defaultReactions: [String] = ["👍", "👎", "😍", "😂", "😯", "😕", "😢", "😡", "💪", "👏", "🙈", "😒"]
            
            guard let data = appConfiguration.data, let emojis = data["gif_search_emojies"] as? [String] else {
                return defaultReactions
            }
            return emojis
        }
        |> distinctUntilChanged
        
        let animatedEmojiStickers = context.engine.stickers.loadedStickerPack(reference: .animatedEmoji, forceActualized: false)
        |> map { animatedEmoji -> [String: [StickerPackItem]] in
            var animatedEmojiStickers: [String: [StickerPackItem]] = [:]
            switch animatedEmoji {
                case let .result(_, items, _):
                    for item in items {
                        if let emoji = item.getStringRepresentationsOfIndexKeys().first {
                            animatedEmojiStickers[emoji.basicEmoji.0] = [item]
                            let strippedEmoji = emoji.basicEmoji.0.strippedEmoji
                            if animatedEmojiStickers[strippedEmoji] == nil {
                                animatedEmojiStickers[strippedEmoji] = [item]
                            }
                        }
                    }
                default:
                    break
            }
            return animatedEmojiStickers
        }
        
        let gifInputInteraction = GifPagerContentComponent.InputInteraction(
            performItemAction: { [weak controllerInteraction] item, view, rect in
                guard let controllerInteraction = controllerInteraction else {
                    return
                }
                let _ = controllerInteraction.sendGif(item.file, view, rect, false, false)
            },
            openGifContextMenu: { _, _, _, _, _ in
            },
            loadMore: { _ in
            }
        )
        
        
        let gifItems: Signal<EntityKeyboardGifContent, NoError> = .single(EntityKeyboardGifContent(
            hasRecentGifs: true,
            component: GifPagerContentComponent(
                context: context,
                inputInteraction: gifInputInteraction,
                subject: .recent,
                items: [],
                isLoading: false,
                loadMoreToken: nil
            )
        ))
        
        return combineLatest(queue: .mainQueue(),
            emojiItems,
            stickerItems,
            gifItems,
            reactions,
            animatedEmojiStickers
        )
        |> map { emoji, stickers, gifs, reactions, animatedEmojiStickers -> InputData in
            var availableGifSearchEmojies: [EntityKeyboardComponent.GifSearchEmoji] = []
            for reaction in reactions {
                if let file = animatedEmojiStickers[reaction]?.first?.file {
                    var title: String?
                    switch reaction {
                        case "😡":
                            title = strings.Gif_Emotion_Angry
                        case "😮":
                            title = strings.Gif_Emotion_Surprised
                        case "😂":
                            title = strings.Gif_Emotion_Joy
                        case "😘":
                            title = strings.Gif_Emotion_Kiss
                        case "😍":
                            title = strings.Gif_Emotion_Hearts
                        case "👍":
                            title = strings.Gif_Emotion_ThumbsUp
                        case "👎":
                            title = strings.Gif_Emotion_ThumbsDown
                        case "🙄":
                            title = strings.Gif_Emotion_RollEyes
                        case "😎":
                            title = strings.Gif_Emotion_Cool
                        case "🥳":
                            title = strings.Gif_Emotion_Party
                        default:
                            break
                    }
                    
                    guard let title = title else {
                        continue
                    }
                    
                    availableGifSearchEmojies.append(EntityKeyboardComponent.GifSearchEmoji(emoji: reaction, file: file, title: title))
                }
            }
            
            return InputData(
                emoji: emoji,
                stickers: stickers,
                gifs: gifs,
                availableGifSearchEmojies: availableGifSearchEmojies
            )
        }
    }
    
    private let context: AccountContext
    private let entityKeyboardView: ComponentHostView<Empty>
    
    private let defaultToEmojiTab: Bool
    private var stableReorderableGroupOrder: [EntityKeyboardComponent.ReorderCategory: [ItemCollectionId]] = [:]
    private var currentInputData: InputData
    private var inputDataDisposable: Disposable?
    private var hasRecentGifsDisposable: Disposable?
    
    private let controllerInteraction: ChatControllerInteraction?
    
    private var inputNodeInteraction: ChatMediaInputNodeInteraction?
    
    private let trendingGifsPromise = Promise<ChatMediaInputGifPaneTrendingState?>(nil)
    
    private var isMarkInputCollapsed: Bool = false
    
    var externalTopPanelContainerImpl: PagerExternalTopPanelContainer?
    override var externalTopPanelContainer: UIView? {
        return self.externalTopPanelContainerImpl
    }
    
    var switchToTextInput: (() -> Void)?
    
    private var currentState: (width: CGFloat, leftInset: CGFloat, rightInset: CGFloat, bottomInset: CGFloat, standardInputHeight: CGFloat, inputHeight: CGFloat, maximumHeight: CGFloat, inputPanelHeight: CGFloat, interfaceState: ChatPresentationInterfaceState, deviceMetrics: DeviceMetrics, isVisible: Bool, isExpanded: Bool)?
    
    private var scheduledContentAnimationHint: EmojiPagerContentComponent.ContentAnimation?
    private var scheduledInnerTransition: Transition?
    
    private var gifMode: GifPagerContentComponent.Subject? {
        didSet {
            if let gifMode = self.gifMode, gifMode != oldValue {
                self.reloadGifContext()
            }
        }
    }
    
    var canSwitchToTextInputAutomatically: Bool {
        if let pagerView = self.entityKeyboardView.componentView as? EntityKeyboardComponent.View, let centralId = pagerView.centralId {
            if centralId == AnyHashable("emoji") {
                return false
            }
        }
        return true
    }
    
    private final class GifContext {
        private var componentValue: EntityKeyboardGifContent? {
            didSet {
                if let componentValue = self.componentValue {
                    self.componentResult.set(.single(componentValue))
                }
            }
        }
        private let componentPromise = Promise<EntityKeyboardGifContent>()
        
        private let componentResult = Promise<EntityKeyboardGifContent>()
        var component: Signal<EntityKeyboardGifContent, NoError> {
            return self.componentResult.get()
        }
        private var componentDisposable: Disposable?
        
        private let context: AccountContext
        private let subject: GifPagerContentComponent.Subject
        private let gifInputInteraction: GifPagerContentComponent.InputInteraction
        
        private var loadingMoreToken: String?
        
        init(context: AccountContext, subject: GifPagerContentComponent.Subject, gifInputInteraction: GifPagerContentComponent.InputInteraction, trendingGifs: Signal<ChatMediaInputGifPaneTrendingState?, NoError>) {
            self.context = context
            self.subject = subject
            self.gifInputInteraction = gifInputInteraction
            
            let hasRecentGifs = context.engine.data.subscribe(TelegramEngine.EngineData.Item.OrderedLists.ListItems(collectionId: Namespaces.OrderedItemList.CloudRecentGifs))
            |> map { savedGifs -> Bool in
                return !savedGifs.isEmpty
            }
            
            let gifItems: Signal<EntityKeyboardGifContent, NoError>
            switch subject {
            case .recent:
                gifItems = context.engine.data.subscribe(TelegramEngine.EngineData.Item.OrderedLists.ListItems(collectionId: Namespaces.OrderedItemList.CloudRecentGifs))
                |> map { savedGifs -> EntityKeyboardGifContent in
                    var items: [GifPagerContentComponent.Item] = []
                    for gifItem in savedGifs {
                        items.append(GifPagerContentComponent.Item(
                            file: .savedGif(media: gifItem.contents.get(RecentMediaItem.self)!.media),
                            contextResult: nil
                        ))
                    }
                    return EntityKeyboardGifContent(
                        hasRecentGifs: true,
                        component: GifPagerContentComponent(
                            context: context,
                            inputInteraction: gifInputInteraction,
                            subject: subject,
                            items: items,
                            isLoading: false,
                            loadMoreToken: nil
                        )
                    )
                }
            case .trending:
                gifItems = combineLatest(hasRecentGifs, trendingGifs)
                |> map { hasRecentGifs, trendingGifs -> EntityKeyboardGifContent in
                    var items: [GifPagerContentComponent.Item] = []
                    
                    var isLoading = false
                    if let trendingGifs = trendingGifs {
                        for file in trendingGifs.files {
                            items.append(GifPagerContentComponent.Item(
                                file: file.file,
                                contextResult: file.contextResult
                            ))
                        }
                    } else {
                        isLoading = true
                    }
                    
                    return EntityKeyboardGifContent(
                        hasRecentGifs: hasRecentGifs,
                        component: GifPagerContentComponent(
                            context: context,
                            inputInteraction: gifInputInteraction,
                            subject: subject,
                            items: items,
                            isLoading: isLoading,
                            loadMoreToken: nil
                        )
                    )
                }
            case let .emojiSearch(query):
                gifItems = combineLatest(hasRecentGifs, paneGifSearchForQuery(context: context, query: query, offset: nil, incompleteResults: true, staleCachedResults: true, delayRequest: false, updateActivity: nil))
                |> map { hasRecentGifs, result -> EntityKeyboardGifContent in
                    var items: [GifPagerContentComponent.Item] = []
                    
                    var loadMoreToken: String?
                    var isLoading = false
                    if let result = result {
                        for file in result.files {
                            items.append(GifPagerContentComponent.Item(
                                file: file.file,
                                contextResult: file.contextResult
                            ))
                        }
                        loadMoreToken = result.nextOffset
                    } else {
                        isLoading = true
                    }
                    
                    return EntityKeyboardGifContent(
                        hasRecentGifs: hasRecentGifs,
                        component: GifPagerContentComponent(
                            context: context,
                            inputInteraction: gifInputInteraction,
                            subject: subject,
                            items: items,
                            isLoading: isLoading,
                            loadMoreToken: loadMoreToken
                        )
                    )
                }
            }
            
            self.componentPromise.set(gifItems)
            self.componentDisposable = (self.componentPromise.get()
            |> deliverOnMainQueue).start(next: { [weak self] result in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.componentValue = result
            })
        }
        
        deinit {
            self.componentDisposable?.dispose()
        }
        
        func loadMore(token: String) {
            if self.loadingMoreToken == token {
                return
            }
            self.loadingMoreToken = token
            
            guard let componentValue = self.componentValue else {
                return
            }
            
            let context = self.context
            let subject = self.subject
            let gifInputInteraction = self.gifInputInteraction
            
            switch self.subject {
            case let .emojiSearch(query):
                let hasRecentGifs = context.engine.data.subscribe(TelegramEngine.EngineData.Item.OrderedLists.ListItems(collectionId: Namespaces.OrderedItemList.CloudRecentGifs))
                |> map { savedGifs -> Bool in
                    return !savedGifs.isEmpty
                }
                
                let gifItems: Signal<EntityKeyboardGifContent, NoError>
                gifItems = combineLatest(hasRecentGifs, paneGifSearchForQuery(context: context, query: query, offset: token, incompleteResults: true, staleCachedResults: true, delayRequest: false, updateActivity: nil))
                |> map { hasRecentGifs, result -> EntityKeyboardGifContent in
                    var items: [GifPagerContentComponent.Item] = []
                    var existingIds = Set<MediaId>()
                    for item in componentValue.component.items {
                        items.append(item)
                        existingIds.insert(item.file.media.fileId)
                    }
                    
                    var loadMoreToken: String?
                    var isLoading = false
                    if let result = result {
                        for file in result.files {
                            if existingIds.contains(file.file.media.fileId) {
                                continue
                            }
                            existingIds.insert(file.file.media.fileId)
                            items.append(GifPagerContentComponent.Item(
                                file: file.file,
                                contextResult: file.contextResult
                            ))
                        }
                        if !result.isComplete {
                            loadMoreToken = result.nextOffset
                        }
                    } else {
                        isLoading = true
                    }
                    
                    return EntityKeyboardGifContent(
                        hasRecentGifs: hasRecentGifs,
                        component: GifPagerContentComponent(
                            context: context,
                            inputInteraction: gifInputInteraction,
                            subject: subject,
                            items: items,
                            isLoading: isLoading,
                            loadMoreToken: loadMoreToken
                        )
                    )
                }
                
                self.componentPromise.set(gifItems)
            default:
                break
            }
        }
    }
    private var gifContext: GifContext? {
        didSet {
            if let gifContext = self.gifContext {
                self.gifComponent.set(gifContext.component)
            }
        }
    }
    private let gifComponent = Promise<EntityKeyboardGifContent>()
    private var gifInputInteraction: GifPagerContentComponent.InputInteraction?
    
    fileprivate var emojiInputInteraction: EmojiPagerContentComponent.InputInteraction?
    private var stickerInputInteraction: EmojiPagerContentComponent.InputInteraction?
    
    private weak var currentUndoOverlayController: UndoOverlayController?
    
    init(context: AccountContext, currentInputData: InputData, updatedInputData: Signal<InputData, NoError>, defaultToEmojiTab: Bool, controllerInteraction: ChatControllerInteraction?, interfaceInteraction: ChatPanelInterfaceInteraction?, chatPeerId: PeerId?) {
        self.context = context
        self.currentInputData = currentInputData
        self.defaultToEmojiTab = defaultToEmojiTab
        
        self.controllerInteraction = controllerInteraction
        
        self.entityKeyboardView = ComponentHostView<Empty>()
        
        super.init()
        
        self.currentInputData = self.processInputData(inputData: self.currentInputData)
        
        self.topBackgroundExtension = 34.0
        self.followsDefaultHeight = true
        
        self.view.addSubview(self.entityKeyboardView)
        
        self.externalTopPanelContainerImpl = PagerExternalTopPanelContainer()
        
        var premiumToastCounter = 0
        self.emojiInputInteraction = EmojiPagerContentComponent.InputInteraction(
            performItemAction: { [weak self, weak interfaceInteraction, weak controllerInteraction] groupId, item, _, _, _, _ in
                let _ = (ChatEntityKeyboardInputNode.hasPremium(context: context, chatPeerId: chatPeerId, premiumIfSavedMessages: true) |> take(1) |> deliverOnMainQueue).start(next: { hasPremium in
                    guard let strongSelf = self,  let controllerInteraction = controllerInteraction, let interfaceInteraction = interfaceInteraction else {
                        return
                    }
                    
                    if let file = item.itemFile {
                        var text = "."
                        var emojiAttribute: ChatTextInputTextCustomEmojiAttribute?
                        loop: for attribute in file.attributes {
                            switch attribute {
                            case let .CustomEmoji(_, displayText, _):
                                text = displayText
                                
                                var packId: ItemCollectionId?
                                if let id = groupId.base as? ItemCollectionId {
                                    packId = id
                                }
                                emojiAttribute = ChatTextInputTextCustomEmojiAttribute(interactivelySelectedFromPackId: packId, fileId: file.fileId.id, file: file)
                                break loop
                            default:
                                break
                            }
                        }
                        
                        if file.isPremiumEmoji && !hasPremium {
                            var animateInAsReplacement = false
                            if let currentUndoOverlayController = strongSelf.currentUndoOverlayController {
                                currentUndoOverlayController.dismissWithCommitActionAndReplacementAnimation()
                                strongSelf.currentUndoOverlayController = nil
                                animateInAsReplacement = true
                            }
                                                        
                            let presentationData = context.sharedContext.currentPresentationData.with { $0 }
                            
                            premiumToastCounter += 1
                            let suggestSavedMessages = premiumToastCounter % 2 == 0
                            let text: String
                            let actionTitle: String
                            if suggestSavedMessages {
                                text = presentationData.strings.EmojiInput_PremiumEmojiToast_TryText
                                actionTitle = presentationData.strings.EmojiInput_PremiumEmojiToast_TryAction
                            } else {
                                text = presentationData.strings.EmojiInput_PremiumEmojiToast_Text
                                actionTitle = presentationData.strings.EmojiInput_PremiumEmojiToast_Action
                            }
                            
                            let controller = UndoOverlayController(presentationData: presentationData, content: .sticker(context: context, file: file, title: nil, text: text, undoText: actionTitle, customAction: { [weak controllerInteraction] in
                                guard let controllerInteraction = controllerInteraction else {
                                    return
                                }
                                
                                if suggestSavedMessages {
                                    let _ = (context.engine.data.get(TelegramEngine.EngineData.Item.Peer.Peer(id: context.account.peerId))
                                    |> deliverOnMainQueue).start(next: { peer in
                                        guard let peer = peer, let navigationController = controllerInteraction.navigationController() else {
                                            return
                                        }
                                        
                                        context.sharedContext.navigateToChatController(NavigateToChatControllerParams(
                                            navigationController: navigationController,
                                            chatController: nil,
                                            context: context,
                                            chatLocation: .peer(peer),
                                            subject: nil,
                                            updateTextInputState: nil,
                                            activateInput: .entityInput,
                                            keepStack: .always,
                                            completion: { _ in
                                            })
                                        )
                                    })
                                } else {
                                    var replaceImpl: ((ViewController) -> Void)?
                                    let controller = PremiumDemoScreen(context: context, subject: .animatedEmoji, action: {
                                        let controller = PremiumIntroScreen(context: context, source: .animatedEmoji)
                                        replaceImpl?(controller)
                                    })
                                    replaceImpl = { [weak controller] c in
                                        controller?.replace(with: c)
                                    }
                                    controllerInteraction.navigationController()?.pushViewController(controller)
                                }
                            }), elevatedLayout: false, animateInAsReplacement: animateInAsReplacement, action: { _ in return false })
                            strongSelf.currentUndoOverlayController = controller
                            controllerInteraction.presentController(controller, nil)
                            return
                        }
                        
                        if let emojiAttribute = emojiAttribute {
                            AudioServicesPlaySystemSound(0x450)
                            interfaceInteraction.insertText(NSAttributedString(string: text, attributes: [ChatTextInputAttributes.customEmoji: emojiAttribute]))
                        }
                    } else if case let .staticEmoji(staticEmoji) = item.content {
                        AudioServicesPlaySystemSound(0x450)
                        interfaceInteraction.insertText(NSAttributedString(string: staticEmoji, attributes: [:]))
                    }
                })
            },
            deleteBackwards: { [weak interfaceInteraction] in
                guard let interfaceInteraction = interfaceInteraction else {
                    return
                }
                interfaceInteraction.backwardsDeleteText()
            },
            openStickerSettings: {
            },
            openFeatured: {
            },
            addGroupAction: { [weak self, weak controllerInteraction] groupId, isPremiumLocked in
                guard let controllerInteraction = controllerInteraction, let collectionId = groupId.base as? ItemCollectionId else {
                    return
                }
                
                if isPremiumLocked {
                    var replaceImpl: ((ViewController) -> Void)?
                    let controller = PremiumDemoScreen(context: context, subject: .animatedEmoji, action: {
                        let controller = PremiumIntroScreen(context: context, source: .animatedEmoji)
                        replaceImpl?(controller)
                    })
                    replaceImpl = { [weak controller] c in
                        controller?.replace(with: c)
                    }
                    controllerInteraction.navigationController()?.pushViewController(controller)
                    
                    return
                }
                
                let viewKey = PostboxViewKey.orderedItemList(id: Namespaces.OrderedItemList.CloudFeaturedEmojiPacks)
                let _ = (context.account.postbox.combinedView(keys: [viewKey])
                |> take(1)
                |> deliverOnMainQueue).start(next: { views in
                    guard let view = views.views[viewKey] as? OrderedItemListView else {
                        return
                    }
                    for featuredEmojiPack in view.items.lazy.map({ $0.contents.get(FeaturedStickerPackItem.self)! }) {
                        if featuredEmojiPack.info.id == collectionId {
                            if let strongSelf = self {
                                strongSelf.scheduledContentAnimationHint = EmojiPagerContentComponent.ContentAnimation(type: .groupInstalled(id: collectionId))
                            }
                            let _ = context.engine.stickers.addStickerPackInteractively(info: featuredEmojiPack.info, items: featuredEmojiPack.topItems).start()
                            
                            break
                        }
                    }
                })
            },
            clearGroup: { [weak controllerInteraction] groupId in
                guard let controllerInteraction = controllerInteraction else {
                    return
                }
                if groupId == AnyHashable("recent") {
                    let presentationData = context.sharedContext.currentPresentationData.with { $0 }
                    let actionSheet = ActionSheetController(theme: ActionSheetControllerTheme(presentationTheme: presentationData.theme, fontSize: presentationData.listsFontSize))
                    var items: [ActionSheetItem] = []
                    items.append(ActionSheetButtonItem(title: presentationData.strings.Emoji_ClearRecent, color: .destructive, action: { [weak actionSheet] in
                        actionSheet?.dismissAnimated()
                        let _ = context.engine.stickers.clearRecentlyUsedEmoji().start()
                    }))
                    actionSheet.setItemGroups([ActionSheetItemGroup(items: items), ActionSheetItemGroup(items: [
                        ActionSheetButtonItem(title: presentationData.strings.Common_Cancel, color: .accent, font: .bold, action: { [weak actionSheet] in
                            actionSheet?.dismissAnimated()
                        })
                    ])])
                    controllerInteraction.presentController(actionSheet, nil)
                }
            },
            pushController: { [weak controllerInteraction] controller in
                guard let controllerInteraction = controllerInteraction else {
                    return
                }
                controllerInteraction.navigationController()?.pushViewController(controller)
            },
            presentController: { [weak controllerInteraction] controller in
                guard let controllerInteraction = controllerInteraction else {
                    return
                }
                controllerInteraction.presentController(controller, nil)
            },
            presentGlobalOverlayController: { [weak controllerInteraction] controller in
                guard let controllerInteraction = controllerInteraction else {
                    return
                }
                controllerInteraction.presentGlobalOverlayController(controller, nil)
            },
            navigationController: { [weak controllerInteraction] in
                return controllerInteraction?.navigationController()
            },
            requestUpdate: { _ in
            },
            updateSearchQuery: { _, _ in
            },
            chatPeerId: chatPeerId,
            peekBehavior: nil,
            customLayout: nil,
            externalBackground: nil,
            externalExpansionView: nil,
            useOpaqueTheme: false
        )
        
        var stickerPeekBehavior: EmojiContentPeekBehaviorImpl?
        if let controllerInteraction = controllerInteraction {
            stickerPeekBehavior = EmojiContentPeekBehaviorImpl(
                context: self.context,
                controllerInteraction: controllerInteraction,
                chatPeerId: chatPeerId
            )
        }
        self.stickerInputInteraction = EmojiPagerContentComponent.InputInteraction(
            performItemAction: { [weak controllerInteraction, weak interfaceInteraction] groupId, item, view, rect, layer, _ in
                let _ = (ChatEntityKeyboardInputNode.hasPremium(context: context, chatPeerId: chatPeerId, premiumIfSavedMessages: false) |> take(1) |> deliverOnMainQueue).start(next: { hasPremium in
                    guard let controllerInteraction = controllerInteraction, let interfaceInteraction = interfaceInteraction else {
                        return
                    }
                    guard let file = item.itemFile else {
                        return
                    }
                    
                    if groupId == AnyHashable("featuredTop") {
                        let viewKey = PostboxViewKey.orderedItemList(id: Namespaces.OrderedItemList.CloudFeaturedStickerPacks)
                        let _ = (context.account.postbox.combinedView(keys: [viewKey])
                        |> take(1)
                        |> deliverOnMainQueue).start(next: { [weak controllerInteraction] views in
                            guard let controllerInteraction = controllerInteraction else {
                                return
                            }
                            guard let view = views.views[viewKey] as? OrderedItemListView else {
                                return
                            }
                            for featuredStickerPack in view.items.lazy.map({ $0.contents.get(FeaturedStickerPackItem.self)! }) {
                                if featuredStickerPack.topItems.contains(where: { $0.file.fileId == file.fileId }) {
                                    controllerInteraction.navigationController()?.pushViewController(FeaturedStickersScreen(
                                        context: context,
                                        highlightedPackId: featuredStickerPack.info.id,
                                        sendSticker: { [weak controllerInteraction] fileReference, sourceNode, sourceRect in
                                            guard let controllerInteraction = controllerInteraction else {
                                                return false
                                            }
                                            return controllerInteraction.sendSticker(fileReference, false, false, nil, false, sourceNode, sourceRect, nil, [])
                                        }
                                    ))
                                    
                                    break
                                }
                            }
                        })
                    } else {
                        if file.isPremiumSticker && !hasPremium {
                            let controller = PremiumIntroScreen(context: context, source: .stickers)
                            controllerInteraction.navigationController()?.pushViewController(controller)
                            
                            return
                        }
                        var bubbleUpEmojiOrStickersets: [ItemCollectionId] = []
                        if let id = groupId.base as? ItemCollectionId {
                            bubbleUpEmojiOrStickersets.append(id)
                        }
                        let _ = interfaceInteraction.sendSticker(.standalone(media: file), false, view, rect, layer, bubbleUpEmojiOrStickersets)
                    }
                })
            },
            deleteBackwards: { [weak interfaceInteraction] in
                guard let interfaceInteraction = interfaceInteraction else {
                    return
                }
                interfaceInteraction.backwardsDeleteText()
            },
            openStickerSettings: { [weak controllerInteraction] in
                guard let controllerInteraction = controllerInteraction else {
                    return
                }
                let controller = installedStickerPacksController(context: context, mode: .modal)
                controller.navigationPresentation = .modal
                controllerInteraction.navigationController()?.pushViewController(controller)
            },
            openFeatured: { [weak controllerInteraction] in
                guard let controllerInteraction = controllerInteraction else {
                    return
                }

                controllerInteraction.navigationController()?.pushViewController(FeaturedStickersScreen(
                    context: context,
                    highlightedPackId: nil,
                    sendSticker: { [weak controllerInteraction] fileReference, sourceNode, sourceRect in
                        guard let controllerInteraction = controllerInteraction else {
                            return false
                        }
                        return controllerInteraction.sendSticker(fileReference, false, false, nil, false, sourceNode, sourceRect, nil, [])
                    }
                ))
            },
            addGroupAction: { groupId, isPremiumLocked in
                guard let controllerInteraction = controllerInteraction, let collectionId = groupId.base as? ItemCollectionId else {
                    return
                }
                
                if isPremiumLocked {
                    let controller = PremiumIntroScreen(context: context, source: .stickers)
                    controllerInteraction.navigationController()?.pushViewController(controller)
                    
                    return
                }
                
                let viewKey = PostboxViewKey.orderedItemList(id: Namespaces.OrderedItemList.CloudFeaturedStickerPacks)
                let _ = (context.account.postbox.combinedView(keys: [viewKey])
                |> take(1)
                |> deliverOnMainQueue).start(next: { views in
                    guard let view = views.views[viewKey] as? OrderedItemListView else {
                        return
                    }
                    for featuredStickerPack in view.items.lazy.map({ $0.contents.get(FeaturedStickerPackItem.self)! }) {
                        if featuredStickerPack.info.id == collectionId {
                            let _ = (context.engine.stickers.loadedStickerPack(reference: .id(id: featuredStickerPack.info.id.id, accessHash: featuredStickerPack.info.accessHash), forceActualized: false)
                            |> mapToSignal { result -> Signal<Void, NoError> in
                                switch result {
                                case let .result(info, items, installed):
                                    if installed {
                                        return .complete()
                                    } else {
                                        return context.engine.stickers.addStickerPackInteractively(info: info, items: items)
                                    }
                                case .fetching:
                                    break
                                case .none:
                                    break
                                }
                                return .complete()
                            }
                            |> deliverOnMainQueue).start(completed: {
                            })
                            
                            break
                        }
                    }
                })
            },
            clearGroup: { [weak controllerInteraction] groupId in
                guard let controllerInteraction = controllerInteraction else {
                    return
                }
                if groupId == AnyHashable("recent") {
                    let presentationData = context.sharedContext.currentPresentationData.with { $0 }
                    let actionSheet = ActionSheetController(theme: ActionSheetControllerTheme(presentationTheme: presentationData.theme, fontSize: presentationData.listsFontSize))
                    var items: [ActionSheetItem] = []
                    items.append(ActionSheetButtonItem(title: presentationData.strings.Stickers_ClearRecent, color: .destructive, action: { [weak actionSheet] in
                        actionSheet?.dismissAnimated()
                        let _ = context.engine.stickers.clearRecentlyUsedStickers().start()
                    }))
                    actionSheet.setItemGroups([ActionSheetItemGroup(items: items), ActionSheetItemGroup(items: [
                        ActionSheetButtonItem(title: presentationData.strings.Common_Cancel, color: .accent, font: .bold, action: { [weak actionSheet] in
                            actionSheet?.dismissAnimated()
                        })
                    ])])
                    controllerInteraction.presentController(actionSheet, nil)
                } else if groupId == AnyHashable("featuredTop") {
                    let viewKey = PostboxViewKey.orderedItemList(id: Namespaces.OrderedItemList.CloudFeaturedStickerPacks)
                    let _ = (context.account.postbox.combinedView(keys: [viewKey])
                    |> take(1)
                    |> deliverOnMainQueue).start(next: { views in
                        guard let view = views.views[viewKey] as? OrderedItemListView else {
                            return
                        }
                        var stickerPackIds: [Int64] = []
                        for featuredStickerPack in view.items.lazy.map({ $0.contents.get(FeaturedStickerPackItem.self)! }) {
                            stickerPackIds.append(featuredStickerPack.info.id.id)
                        }
                        let _ = ApplicationSpecificNotice.setDismissedTrendingStickerPacks(accountManager: context.sharedContext.accountManager, values: stickerPackIds).start()
                    })
                } else if groupId == AnyHashable("peerSpecific") {
                }
            },
            pushController: { [weak controllerInteraction] controller in
                guard let controllerInteraction = controllerInteraction else {
                    return
                }
                controllerInteraction.navigationController()?.pushViewController(controller)
            },
            presentController: { [weak controllerInteraction] controller in
                guard let controllerInteraction = controllerInteraction else {
                    return
                }
                controllerInteraction.presentController(controller, nil)
            },
            presentGlobalOverlayController: { [weak controllerInteraction] controller in
                guard let controllerInteraction = controllerInteraction else {
                    return
                }
                controllerInteraction.presentGlobalOverlayController(controller, nil)
            },
            navigationController: { [weak controllerInteraction] in
                return controllerInteraction?.navigationController()
            },
            requestUpdate: { _ in
            },
            updateSearchQuery: { _, _ in
            },
            chatPeerId: chatPeerId,
            peekBehavior: stickerPeekBehavior,
            customLayout: nil,
            externalBackground: nil,
            externalExpansionView: nil,
            useOpaqueTheme: false
        )
        
        self.inputDataDisposable = (combineLatest(queue: .mainQueue(),
            updatedInputData,
            self.gifComponent.get()
        )
        |> deliverOnMainQueue).start(next: { [weak self] inputData, gifs in
            guard let strongSelf = self else {
                return
            }
            var inputData = inputData
            inputData.gifs = gifs
            
            var transition: Transition = .immediate
            var useAnimation = false
            
            if let pagerView = strongSelf.entityKeyboardView.componentView as? EntityKeyboardComponent.View, let centralId = pagerView.centralId {
                if centralId == AnyHashable("emoji") {
                    useAnimation = strongSelf.currentInputData.emoji != inputData.emoji
                } else if centralId == AnyHashable("stickers"),  strongSelf.currentInputData.stickers != nil, inputData.stickers != nil {
                    useAnimation = strongSelf.currentInputData.stickers != inputData.stickers
                }
            }
            
            if useAnimation {
                let contentAnimation: EmojiPagerContentComponent.ContentAnimation
                if let scheduledContentAnimationHint = strongSelf.scheduledContentAnimationHint {
                    strongSelf.scheduledContentAnimationHint = nil
                    contentAnimation = scheduledContentAnimationHint
                } else {
                    contentAnimation = EmojiPagerContentComponent.ContentAnimation(type: .generic)
                }
                transition = Transition(animation: .curve(duration: 0.4, curve: .spring)).withUserData(contentAnimation)
            }
            strongSelf.currentInputData = strongSelf.processInputData(inputData: inputData)
            strongSelf.performLayout(transition: transition)
        })
        
        self.inputNodeInteraction = ChatMediaInputNodeInteraction(
            navigateToCollectionId: { _ in
            },
            navigateBackToStickers: {
            },
            setGifMode: { _ in
            },
            openSettings: {
            },
            openTrending: { _ in
            },
            dismissTrendingPacks: { _ in
            },
            toggleSearch: { _, _, _ in
            },
            openPeerSpecificSettings: {
            },
            dismissPeerSpecificSettings: {
            },
            clearRecentlyUsedStickers: {
            }
        )
        
        self.trendingGifsPromise.set(.single(nil))
        self.trendingGifsPromise.set(paneGifSearchForQuery(context: context, query: "", offset: nil, incompleteResults: true, delayRequest: false, updateActivity: nil)
        |> map { items -> ChatMediaInputGifPaneTrendingState? in
            if let items = items {
                return ChatMediaInputGifPaneTrendingState(files: items.files, nextOffset: items.nextOffset)
            } else {
                return nil
            }
        })
        
        self.gifInputInteraction = GifPagerContentComponent.InputInteraction(
            performItemAction: { [weak controllerInteraction] item, view, rect in
                guard let controllerInteraction = controllerInteraction else {
                    return
                }
                
                if let (collection, result) = item.contextResult {
                    let _ = controllerInteraction.sendBotContextResultAsGif(collection, result, view, rect, false)
                } else {
                    let _ = controllerInteraction.sendGif(item.file, view, rect, false, false)
                }
            },
            openGifContextMenu: { [weak self] item, sourceView, sourceRect, gesture, isSaved in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.openGifContextMenu(item: item, sourceView: sourceView, sourceRect: sourceRect, gesture: gesture, isSaved: isSaved)
            },
            loadMore: { [weak self] token in
                guard let strongSelf = self, let gifContext = strongSelf.gifContext else {
                    return
                }
                gifContext.loadMore(token: token)
            }
        )
        
        self.switchToTextInput = { [weak self] in
            guard let strongSelf = self, let controllerInteraction = strongSelf.controllerInteraction else {
                return
            }
            controllerInteraction.updateInputMode { _ in
                return .text
            }
        }
        
        if self.currentInputData.gifs != nil {
            let hasRecentGifs = context.engine.data.subscribe(TelegramEngine.EngineData.Item.OrderedLists.ListItems(collectionId: Namespaces.OrderedItemList.CloudRecentGifs))
            |> map { savedGifs -> Bool in
                return !savedGifs.isEmpty
            }
            
            self.hasRecentGifsDisposable = (hasRecentGifs
            |> deliverOnMainQueue).start(next: { [weak self] hasRecentGifs in
                guard let strongSelf = self else {
                    return
                }
                
                if let gifMode = strongSelf.gifMode {
                    if !hasRecentGifs, case .recent = gifMode {
                        strongSelf.gifMode = .trending
                    }
                } else {
                    strongSelf.gifMode = hasRecentGifs ? .recent : .trending
                }
            })
        }
    }
    
    deinit {
        self.inputDataDisposable?.dispose()
        self.hasRecentGifsDisposable?.dispose()
    }
    
    private func reloadGifContext() {
        if let gifInputInteraction = self.gifInputInteraction, let gifMode = self.gifMode {
            self.gifContext = GifContext(context: self.context, subject: gifMode, gifInputInteraction: gifInputInteraction, trendingGifs: self.trendingGifsPromise.get())
        }
    }
    
    func markInputCollapsed() {
        self.isMarkInputCollapsed = true
    }
    
    private func performLayout(transition: Transition) {
        guard let (width, leftInset, rightInset, bottomInset, standardInputHeight, inputHeight, maximumHeight, inputPanelHeight, interfaceState, deviceMetrics, isVisible, isExpanded) = self.currentState else {
            return
        }
        self.scheduledInnerTransition = transition
        let _ = self.updateLayout(width: width, leftInset: leftInset, rightInset: rightInset, bottomInset: bottomInset, standardInputHeight: standardInputHeight, inputHeight: inputHeight, maximumHeight: maximumHeight, inputPanelHeight: inputPanelHeight, transition: .immediate, interfaceState: interfaceState, deviceMetrics: deviceMetrics, isVisible: isVisible, isExpanded: isExpanded)
    }
    
    func simulateUpdateLayout(isVisible: Bool) {
        guard let (width, leftInset, rightInset, bottomInset, standardInputHeight, inputHeight, maximumHeight, inputPanelHeight, interfaceState, deviceMetrics, _, isExpanded) = self.currentState else {
            return
        }
        let _ = self.updateLayout(width: width, leftInset: leftInset, rightInset: rightInset, bottomInset: bottomInset, standardInputHeight: standardInputHeight, inputHeight: inputHeight, maximumHeight: maximumHeight, inputPanelHeight: inputPanelHeight, transition: .immediate, interfaceState: interfaceState, deviceMetrics: deviceMetrics, isVisible: isVisible, isExpanded: isExpanded)
    }
    
    override func updateLayout(width: CGFloat, leftInset: CGFloat, rightInset: CGFloat, bottomInset: CGFloat, standardInputHeight: CGFloat, inputHeight: CGFloat, maximumHeight: CGFloat, inputPanelHeight: CGFloat, transition: ContainedViewLayoutTransition, interfaceState: ChatPresentationInterfaceState, deviceMetrics: DeviceMetrics, isVisible: Bool, isExpanded: Bool) -> (CGFloat, CGFloat) {
        self.currentState = (width, leftInset, rightInset, bottomInset, standardInputHeight, inputHeight, maximumHeight, inputPanelHeight, interfaceState, deviceMetrics, isVisible, isExpanded)
        
        let innerTransition: Transition
        if let scheduledInnerTransition = self.scheduledInnerTransition {
            self.scheduledInnerTransition = nil
            innerTransition = scheduledInnerTransition
        } else {
            innerTransition = Transition(transition)
        }
        
        let wasMarkedInputCollapsed = self.isMarkInputCollapsed
        self.isMarkInputCollapsed = false
        
        let expandedHeight = standardInputHeight
        
        var hiddenInputHeight: CGFloat = 0.0
        if self.hideInput && !self.adjustLayoutForHiddenInput {
            hiddenInputHeight = inputPanelHeight
        }
        
        let context = self.context
        let controllerInteraction = self.controllerInteraction
        let inputNodeInteraction = self.inputNodeInteraction!
        let trendingGifsPromise = self.trendingGifsPromise
        
        var mappedTransition = innerTransition
        
        if wasMarkedInputCollapsed || !isExpanded {
            mappedTransition = mappedTransition.withUserData(EntityKeyboardComponent.MarkInputCollapsed())
        }
        
        var stickerContent: EmojiPagerContentComponent? = self.currentInputData.stickers
        var gifContent: EntityKeyboardGifContent? = self.currentInputData.gifs
        
        var stickersEnabled = true
        if let peer = interfaceState.renderedPeer?.peer as? TelegramChannel {
            if peer.hasBannedPermission(.banSendStickers) != nil {
                stickersEnabled = false
            }
        } else if let peer = interfaceState.renderedPeer?.peer as? TelegramGroup {
            if peer.hasBannedPermission(.banSendStickers) {
                stickersEnabled = false
            }
        }
        
        if !stickersEnabled || interfaceState.interfaceState.editMessage != nil {
            stickerContent = nil
            gifContent = nil
        }
        
        stickerContent?.inputInteractionHolder.inputInteraction = self.stickerInputInteraction
        self.currentInputData.emoji.inputInteractionHolder.inputInteraction = self.emojiInputInteraction
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let entityKeyboardSize = self.entityKeyboardView.update(
            transition: mappedTransition,
            component: AnyComponent(EntityKeyboardComponent(
                theme: interfaceState.theme,
                strings: interfaceState.strings,
                isContentInFocus: isVisible,
                containerInsets: UIEdgeInsets(top: 0.0, left: leftInset, bottom: bottomInset, right: rightInset),
                topPanelInsets: UIEdgeInsets(),
                emojiContent: self.currentInputData.emoji,
                stickerContent: stickerContent,
                gifContent: gifContent?.component,
                hasRecentGifs: gifContent?.hasRecentGifs ?? false,
                availableGifSearchEmojies: self.currentInputData.availableGifSearchEmojies,
                defaultToEmojiTab: self.defaultToEmojiTab,
                externalTopPanelContainer: self.externalTopPanelContainerImpl,
                topPanelExtensionUpdated: { [weak self] topPanelExtension, transition in
                    guard let strongSelf = self else {
                        return
                    }
                    if strongSelf.topBackgroundExtension != topPanelExtension {
                        strongSelf.topBackgroundExtension = topPanelExtension
                        strongSelf.topBackgroundExtensionUpdated?(transition.containedViewLayoutTransition)
                    }
                },
                hideInputUpdated: { [weak self] hideInput, adjustLayout, transition in
                    guard let strongSelf = self else {
                        return
                    }
                    if strongSelf.hideInput != hideInput || strongSelf.adjustLayoutForHiddenInput != adjustLayout {
                        strongSelf.hideInput = hideInput
                        strongSelf.adjustLayoutForHiddenInput = adjustLayout
                        strongSelf.hideInputUpdated?(transition.containedViewLayoutTransition)
                    }
                },
                hideTopPanelUpdated: { _, _ in
                },
                switchToTextInput: { [weak self] in
                    self?.switchToTextInput?()
                },
                switchToGifSubject: { [weak self] subject in
                    guard let strongSelf = self else {
                        return
                    }
                    strongSelf.gifMode = subject
                },
                reorderItems: { [weak self] category, items in
                    guard let strongSelf = self else {
                        return
                    }
                    strongSelf.reorderItems(category: category, items: items)
                },
                makeSearchContainerNode: { [weak controllerInteraction] content in
                    guard let controllerInteraction = controllerInteraction else {
                        return nil
                    }

                    let mappedMode: ChatMediaInputSearchMode
                    switch content {
                    case .stickers:
                        mappedMode = .sticker
                    case .gifs:
                        mappedMode = .gif
                    }
                    
                    let presentationData = context.sharedContext.currentPresentationData.with { $0 }
                    return PaneSearchContainerNode(
                        context: context,
                        theme: presentationData.theme,
                        strings: presentationData.strings,
                        controllerInteraction: controllerInteraction,
                        inputNodeInteraction: inputNodeInteraction,
                        mode: mappedMode,
                        trendingGifsPromise: trendingGifsPromise,
                        cancel: {
                        }
                    )
                },
                deviceMetrics: deviceMetrics,
                hiddenInputHeight: hiddenInputHeight,
                displayBottomPanel: true,
                isExpanded: isExpanded
            )),
            environment: {},
            containerSize: CGSize(width: width, height: expandedHeight)
        )
        transition.updateFrame(view: self.entityKeyboardView, frame: CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: entityKeyboardSize))
        
        let layoutTime = CFAbsoluteTimeGetCurrent() - startTime
        if layoutTime > 0.1 {
            #if DEBUG
            print("EntityKeyboard layout in \(layoutTime * 1000.0) ms")
            #endif
        }
        
        return (expandedHeight, 0.0)
    }
    
    private func processStableItemGroupList(category: EntityKeyboardComponent.ReorderCategory, itemGroups: [EmojiPagerContentComponent.ItemGroup]) -> [EmojiPagerContentComponent.ItemGroup] {
        let nextIds: [ItemCollectionId] = itemGroups.compactMap { group -> ItemCollectionId? in
            if group.isEmbedded {
                return nil
            }
            if group.isFeatured {
                return nil
            }
            if let collectionId = group.groupId.base as? ItemCollectionId {
                return collectionId
            } else {
                return nil
            }
        }
        
        let stableOrder = self.stableReorderableGroupOrder[category] ?? nextIds
        
        var updatedGroups: [EmojiPagerContentComponent.ItemGroup] = []
        
        for group in itemGroups {
            if !(group.groupId.base is ItemCollectionId) {
                if group.groupId != AnyHashable("static") {
                    updatedGroups.append(group)
                }
            } else {
                if group.isEmbedded {
                    continue
                }
                if group.isFeatured {
                    continue
                }
                if !stableOrder.contains(where: { AnyHashable($0) == group.groupId }) {
                    updatedGroups.append(group)
                }
            }
        }
        for id in stableOrder {
            if let group = itemGroups.first(where: { $0.groupId == AnyHashable(id) }) {
                updatedGroups.append(group)
            }
        }
        for group in itemGroups {
            if !updatedGroups.contains(where: { $0.groupId == group.groupId }) {
                updatedGroups.append(group)
            }
        }
        
        let updatedIds = updatedGroups.compactMap { group -> ItemCollectionId? in
            if group.isEmbedded {
                return nil
            }
            if group.isFeatured {
                return nil
            }
            if let collectionId = group.groupId.base as? ItemCollectionId {
                return collectionId
            } else {
                return nil
            }
        }

        self.stableReorderableGroupOrder[category] = updatedIds
        
        return updatedGroups
    }
    
    private func processInputData(inputData: InputData) -> InputData {
        return InputData(
            emoji: inputData.emoji.withUpdatedItemGroups(itemGroups: self.processStableItemGroupList(category: .emoji, itemGroups: inputData.emoji.itemGroups), itemContentUniqueId: nil, emptySearchResults: nil),
            stickers: inputData.stickers.flatMap { stickers in
                return stickers.withUpdatedItemGroups(itemGroups: self.processStableItemGroupList(category: .stickers, itemGroups: stickers.itemGroups), itemContentUniqueId: nil, emptySearchResults: nil)
            },
            gifs: inputData.gifs,
            availableGifSearchEmojies: inputData.availableGifSearchEmojies
        )
    }
    
    private func reorderItems(category: EntityKeyboardComponent.ReorderCategory, items: [EntityKeyboardTopPanelComponent.Item]) {
        var currentIds: [ItemCollectionId] = []
        for item in items {
            guard let id = item.id.base as? ItemCollectionId else {
                continue
            }
            currentIds.append(id)
        }
        let namespace: ItemCollectionId.Namespace
        switch category {
        case .stickers:
            namespace = Namespaces.ItemCollection.CloudStickerPacks
        case .emoji:
            namespace = Namespaces.ItemCollection.CloudEmojiPacks
        }
        
        self.stableReorderableGroupOrder.removeValue(forKey: category)
        
        let _ = (self.context.engine.stickers.reorderStickerPacks(namespace: namespace, itemIds: currentIds)
        |> deliverOnMainQueue).start(completed: { [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.performLayout(transition: Transition(animation: .curve(duration: 0.4, curve: .spring)))
        })
    }
    
    private func openGifContextMenu(item: GifPagerContentComponent.Item, sourceView: UIView, sourceRect: CGRect, gesture: ContextGesture, isSaved: Bool) {
        let file = item
        
        let canSaveGif: Bool
        if file.file.media.fileId.namespace == Namespaces.Media.CloudFile {
            canSaveGif = true
        } else {
            canSaveGif = false
        }
        
        let _ = (self.context.engine.stickers.isGifSaved(id: file.file.media.fileId)
        |> deliverOnMainQueue).start(next: { [weak self] isGifSaved in
            guard let strongSelf = self else {
                return
            }
            var isGifSaved = isGifSaved
            if !canSaveGif {
                isGifSaved = false
            }
            let presentationData = strongSelf.context.sharedContext.currentPresentationData.with { $0 }
            
            let message = Message(stableId: 0, stableVersion: 0, id: MessageId(peerId: PeerId(0), namespace: Namespaces.Message.Local, id: 0), globallyUniqueId: nil, groupingKey: nil, groupInfo: nil, threadId: nil, timestamp: 0, flags: [], tags: [], globalTags: [], localTags: [], forwardInfo: nil, author: nil, text: "", attributes: [], media: [file.file.media], peers: SimpleDictionary(), associatedMessages: SimpleDictionary(), associatedMessageIds: [], associatedMedia: [:], associatedThreadInfo: nil)
            
            let gallery = GalleryController(context: strongSelf.context, source: .standaloneMessage(message), streamSingleVideo: true, replaceRootController: { _, _ in
            }, baseNavigationController: nil)
            gallery.setHintWillBePresentedInPreviewingContext(true)
            
            var items: [ContextMenuItem] = []
            items.append(.action(ContextMenuActionItem(text: presentationData.strings.MediaPicker_Send, icon: { theme in
                return generateTintedImage(image: UIImage(bundleImageName: "Chat/Context Menu/Resend"), color: theme.actionSheet.primaryTextColor)
            }, action: { _, f in
                f(.default)
                if isSaved {
                    let _ = self?.controllerInteraction?.sendGif(file.file, sourceView, sourceRect, false, false)
                } else if let (collection, result) = file.contextResult {
                    let _ = self?.controllerInteraction?.sendBotContextResultAsGif(collection, result, sourceView, sourceRect, false)
                }
            })))
            
            if let currentState = strongSelf.currentState {
                let interfaceState = currentState.interfaceState
                
                var isScheduledMessages = false
                if case .scheduledMessages = interfaceState.subject {
                    isScheduledMessages = true
                }
                if !isScheduledMessages {
                    if case let .peer(peerId) = interfaceState.chatLocation {
                        if peerId != self?.context.account.peerId && peerId.namespace != Namespaces.Peer.SecretChat  {
                            items.append(.action(ContextMenuActionItem(text: presentationData.strings.Conversation_SendMessage_SendSilently, icon: { theme in
                                return generateTintedImage(image: UIImage(bundleImageName: "Chat/Input/Menu/SilentIcon"), color: theme.actionSheet.primaryTextColor)
                            }, action: { _, f in
                                f(.default)
                                if isSaved {
                                    let _ = self?.controllerInteraction?.sendGif(file.file, sourceView, sourceRect, true, false)
                                } else if let (collection, result) = file.contextResult {
                                    let _ = self?.controllerInteraction?.sendBotContextResultAsGif(collection, result, sourceView, sourceRect, true)
                                }
                            })))
                        }
                    
                        if isSaved {
                            items.append(.action(ContextMenuActionItem(text: presentationData.strings.Conversation_SendMessage_ScheduleMessage, icon: { theme in
                                return generateTintedImage(image: UIImage(bundleImageName: "Chat/Input/Menu/ScheduleIcon"), color: theme.actionSheet.primaryTextColor)
                            }, action: { _, f in
                                f(.default)
                                
                                let _ = self?.controllerInteraction?.sendGif(file.file, sourceView, sourceRect, false, true)
                            })))
                        }
                    }
                }
            }
            
            if isSaved || isGifSaved {
                items.append(.action(ContextMenuActionItem(text: presentationData.strings.Conversation_ContextMenuDelete, textColor: .destructive, icon: { theme in
                    return generateTintedImage(image: UIImage(bundleImageName: "Chat/Context Menu/Delete"), color: theme.actionSheet.destructiveActionTextColor)
                }, action: { _, f in
                    f(.dismissWithoutContent)
                    
                    guard let strongSelf = self else {
                        return
                    }
                    let _ = removeSavedGif(postbox: strongSelf.context.account.postbox, mediaId: file.file.media.fileId).start()
                })))
            } else if canSaveGif && !isGifSaved {
                items.append(.action(ContextMenuActionItem(text: presentationData.strings.Preview_SaveGif, icon: { theme in
                    return generateTintedImage(image: UIImage(bundleImageName: "Chat/Context Menu/Save"), color: theme.actionSheet.primaryTextColor)
                }, action: { _, f in
                    f(.dismissWithoutContent)
                    
                    guard let strongSelf = self else {
                        return
                    }
                    
                    let context = strongSelf.context
                    let presentationData = context.sharedContext.currentPresentationData.with { $0 }
                    let _ = (toggleGifSaved(account: context.account, fileReference: file.file, saved: true)
                    |> deliverOnMainQueue).start(next: { result in
                        guard let strongSelf = self else {
                            return
                        }
                        switch result {
                            case .generic:
                                strongSelf.controllerInteraction?.presentController(UndoOverlayController(presentationData: presentationData, content: .universal(animation: "anim_gif", scale: 0.075, colors: [:], title: nil, text: presentationData.strings.Gallery_GifSaved, customUndoText: nil), elevatedLayout: false, animateInAsReplacement: false, action: { _ in return false }), nil)
                            case let .limitExceeded(limit, premiumLimit):
                                let premiumConfiguration = PremiumConfiguration.with(appConfiguration: context.currentAppConfiguration.with { $0 })
                                let text: String
                                if limit == premiumLimit || premiumConfiguration.isPremiumDisabled {
                                    text = presentationData.strings.Premium_MaxSavedGifsFinalText
                                } else {
                                    text = presentationData.strings.Premium_MaxSavedGifsText("\(premiumLimit)").string
                                }
                                strongSelf.controllerInteraction?.presentController(UndoOverlayController(presentationData: presentationData, content: .universal(animation: "anim_gif", scale: 0.075, colors: [:], title: presentationData.strings.Premium_MaxSavedGifsTitle("\(limit)").string, text: text, customUndoText: nil), elevatedLayout: false, animateInAsReplacement: false, action: { action in
                                    guard let strongSelf = self else {
                                        return false
                                    }
                                    
                                    if case .info = action {
                                        let controller = PremiumIntroScreen(context: context, source: .savedGifs)
                                        strongSelf.controllerInteraction?.navigationController()?.pushViewController(controller)
                                        return true
                                    }
                                    return false
                                }), nil)
                        }
                    })
                })))
            }
            
            let contextController = ContextController(account: strongSelf.context.account, presentationData: presentationData, source: .controller(ContextControllerContentSourceImpl(controller: gallery, sourceView: sourceView, sourceRect: sourceRect)), items: .single(ContextController.Items(content: .list(items))), gesture: gesture)
            strongSelf.controllerInteraction?.presentGlobalOverlayController(contextController, nil)
        })
    }
}

private final class ContextControllerContentSourceImpl: ContextControllerContentSource {
    let controller: ViewController
    weak var sourceView: UIView?
    let sourceRect: CGRect
    
    let navigationController: NavigationController? = nil
    
    let passthroughTouches: Bool = false
    
    init(controller: ViewController, sourceView: UIView?, sourceRect: CGRect) {
        self.controller = controller
        self.sourceView = sourceView
        self.sourceRect = sourceRect
    }
    
    func transitionInfo() -> ContextControllerTakeControllerInfo? {
        let sourceView = self.sourceView
        let sourceRect = self.sourceRect
        return ContextControllerTakeControllerInfo(contentAreaInScreenSpace: CGRect(origin: CGPoint(), size: CGSize(width: 10.0, height: 10.0)), sourceNode: { [weak sourceView] in
            if let sourceView = sourceView {
                return (sourceView, sourceRect)
            } else {
                return nil
            }
        })
    }
    
    func animatedIn() {
        if let controller = self.controller as? GalleryController {
            controller.viewDidAppear(false)
        }
    }
}

final class EntityInputView: UIView, AttachmentTextInputPanelInputView, UIInputViewAudioFeedback {
    private let context: AccountContext
    
    public var insertText: ((NSAttributedString) -> Void)?
    public var deleteBackwards: (() -> Void)?
    public var switchToKeyboard: (() -> Void)?
    public var presentController: ((ViewController) -> Void)?
    
    private var presentationData: PresentationData
    private var inputNode: ChatEntityKeyboardInputNode?
    private let animationCache: AnimationCache
    private let animationRenderer: MultiAnimationRenderer
    
    init(
        context: AccountContext,
        isDark: Bool,
        areCustomEmojiEnabled: Bool
    ) {
        self.context = context
        
        self.animationCache = context.animationCache
        self.animationRenderer = context.animationRenderer
        
        self.presentationData = context.sharedContext.currentPresentationData.with { $0 }
        if isDark {
            self.presentationData = self.presentationData.withUpdated(theme: defaultDarkPresentationTheme)
        }
        
        
        super.init(frame: CGRect(origin: CGPoint(), size: CGSize(width: 1.0, height: 1.0)))
        
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.clipsToBounds = true
        
        let inputInteraction = EmojiPagerContentComponent.InputInteraction(
            performItemAction: { [weak self] groupId, item, _, _, _, _ in
                let _ = (ChatEntityKeyboardInputNode.hasPremium(context: context, chatPeerId: nil, premiumIfSavedMessages: false) |> take(1) |> deliverOnMainQueue).start(next: { hasPremium in
                    guard let strongSelf = self else {
                        return
                    }
                    
                    if let file = item.itemFile {
                        var text = "."
                        var emojiAttribute: ChatTextInputTextCustomEmojiAttribute?
                        loop: for attribute in file.attributes {
                            switch attribute {
                            case let .CustomEmoji(_, displayText, _):
                                text = displayText
                                var packId: ItemCollectionId?
                                if let id = groupId.base as? ItemCollectionId {
                                    packId = id
                                }
                                emojiAttribute = ChatTextInputTextCustomEmojiAttribute(interactivelySelectedFromPackId: packId, fileId: file.fileId.id, file: file)
                                break loop
                            default:
                                break
                            }
                        }
                        
                        if file.isPremiumEmoji && !hasPremium {
                            let presentationData = context.sharedContext.currentPresentationData.with { $0 }
                            strongSelf.presentController?(UndoOverlayController(presentationData: presentationData, content: .sticker(context: context, file: file, title: nil, text: presentationData.strings.EmojiInput_PremiumEmojiToast_Text, undoText: presentationData.strings.EmojiInput_PremiumEmojiToast_Action, customAction: {
                                guard let strongSelf = self else {
                                    return
                                }
                                
                                var replaceImpl: ((ViewController) -> Void)?
                                let controller = PremiumDemoScreen(context: strongSelf.context, subject: .animatedEmoji, action: {
                                    let controller = PremiumIntroScreen(context: strongSelf.context, source: .animatedEmoji)
                                    replaceImpl?(controller)
                                })
                                replaceImpl = { [weak controller] c in
                                    controller?.replace(with: c)
                                }
                                strongSelf.presentController?(controller)
                            }), elevatedLayout: false, animateInAsReplacement: false, action: { _ in return false }))
                            return
                        }
                        
                        if let emojiAttribute = emojiAttribute {
                            AudioServicesPlaySystemSound(0x450)
                            strongSelf.insertText?(NSAttributedString(string: text, attributes: [ChatTextInputAttributes.customEmoji: emojiAttribute]))
                        }
                    } else if case let .staticEmoji(staticEmoji) = item.content {
                        AudioServicesPlaySystemSound(0x450)
                        strongSelf.insertText?(NSAttributedString(string: staticEmoji, attributes: [:]))
                    }
                })
            },
            deleteBackwards: { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.deleteBackwards?()
            },
            openStickerSettings: {
            },
            openFeatured: {
            },
            addGroupAction: { _, _ in
            },
            clearGroup: { [weak self] groupId in
                guard let strongSelf = self else {
                    return
                }
                if groupId == AnyHashable("recent") {
                    let presentationData = context.sharedContext.currentPresentationData.with { $0 }
                    let actionSheet = ActionSheetController(theme: ActionSheetControllerTheme(presentationTheme: presentationData.theme, fontSize: presentationData.listsFontSize))
                    var items: [ActionSheetItem] = []
                    items.append(ActionSheetButtonItem(title: presentationData.strings.Emoji_ClearRecent, color: .destructive, action: { [weak actionSheet] in
                        actionSheet?.dismissAnimated()
                        let _ = context.engine.stickers.clearRecentlyUsedEmoji().start()
                    }))
                    actionSheet.setItemGroups([ActionSheetItemGroup(items: items), ActionSheetItemGroup(items: [
                        ActionSheetButtonItem(title: presentationData.strings.Common_Cancel, color: .accent, font: .bold, action: { [weak actionSheet] in
                            actionSheet?.dismissAnimated()
                        })
                    ])])
                    strongSelf.presentController?(actionSheet)
                }
            },
            pushController: { _ in
            },
            presentController: { _ in
            },
            presentGlobalOverlayController: { _ in
            },
            navigationController: {
                return nil
            },
            requestUpdate: { _ in   
            },
            updateSearchQuery: { _, _ in
            },
            chatPeerId: nil,
            peekBehavior: nil,
            customLayout: nil,
            externalBackground: nil,
            externalExpansionView: nil,
            useOpaqueTheme: false
        )
        
        let semaphore = DispatchSemaphore(value: 0)
        var emojiComponent: EmojiPagerContentComponent?
        let _ = EmojiPagerContentComponent.emojiInputData(context: context, animationCache: self.animationCache, animationRenderer: self.animationRenderer, isStandalone: true, isStatusSelection: false, isReactionSelection: false, topReactionItems: [], areUnicodeEmojiEnabled: true, areCustomEmojiEnabled: areCustomEmojiEnabled, chatPeerId: nil).start(next: { value in
            emojiComponent = value
            semaphore.signal()
        })
        semaphore.wait()
        
        if let emojiComponent = emojiComponent {
            let inputNode = ChatEntityKeyboardInputNode(
                context: self.context,
                currentInputData: ChatEntityKeyboardInputNode.InputData(
                    emoji: emojiComponent,
                    stickers: nil,
                    gifs: nil,
                    availableGifSearchEmojies: []
                ),
                updatedInputData: EmojiPagerContentComponent.emojiInputData(context: context, animationCache: self.animationCache, animationRenderer: self.animationRenderer, isStandalone: true, isStatusSelection: false, isReactionSelection: false, topReactionItems: [], areUnicodeEmojiEnabled: true, areCustomEmojiEnabled: areCustomEmojiEnabled, chatPeerId: nil) |> map { emojiComponent -> ChatEntityKeyboardInputNode.InputData in
                    return ChatEntityKeyboardInputNode.InputData(
                        emoji: emojiComponent,
                        stickers: nil,
                        gifs: nil,
                        availableGifSearchEmojies: []
                    )
                },
                defaultToEmojiTab: true,
                controllerInteraction: nil,
                interfaceInteraction: nil,
                chatPeerId: nil
            )
            self.inputNode = inputNode
            inputNode.emojiInputInteraction = inputInteraction
            inputNode.externalTopPanelContainerImpl = nil
            inputNode.switchToTextInput = { [weak self] in
                self?.switchToKeyboard?()
            }
            self.addSubnode(inputNode)
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard let inputNode = self.inputNode else {
            return
        }
        
        for view in self.subviews {
            if view !== inputNode.view {
                view.isHidden = true
            }
        }
        
        let bottomInset: CGFloat
        if #available(iOS 11.0, *) {
            bottomInset = max(0.0, UIScreen.main.bounds.height - (self.window?.safeAreaLayoutGuide.layoutFrame.maxY ?? 10000.0))
        } else {
            bottomInset = 0.0
        }
            
        let presentationInterfaceState = ChatPresentationInterfaceState(
            chatWallpaper: .builtin(WallpaperSettings()),
            theme: self.presentationData.theme,
            strings: self.presentationData.strings,
            dateTimeFormat: self.presentationData.dateTimeFormat,
            nameDisplayOrder: self.presentationData.nameDisplayOrder,
            limitsConfiguration: self.context.currentLimitsConfiguration.with { $0 },
            fontSize: self.presentationData.chatFontSize,
            bubbleCorners: self.presentationData.chatBubbleCorners,
            accountPeerId: self.context.account.peerId,
            mode: .standard(previewing: false),
            chatLocation: .peer(id: self.context.account.peerId),
            subject: nil,
            peerNearbyData: nil,
            greetingData: nil,
            pendingUnpinnedAllMessages: false,
            activeGroupCallInfo: nil,
            hasActiveGroupCall: false,
            importState: nil,
            threadData: nil
        )

        let _ = inputNode.updateLayout(
            width: self.bounds.width,
            leftInset: 0.0,
            rightInset: 0.0,
            bottomInset: bottomInset,
            standardInputHeight: self.bounds.height,
            inputHeight: self.bounds.height,
            maximumHeight: self.bounds.height,
            inputPanelHeight: 0.0,
            transition: .immediate,
            interfaceState: presentationInterfaceState,
            deviceMetrics: DeviceMetrics.iPhone12,
            isVisible: true,
            isExpanded: false
        )
        inputNode.frame = self.bounds
    }
}

private final class EmojiContentPeekBehaviorImpl: EmojiContentPeekBehavior {
    private let context: AccountContext
    private let controllerInteraction: ChatControllerInteraction
    private let chatPeerId: EnginePeer.Id?
    
    private var peekRecognizer: PeekControllerGestureRecognizer?
    private weak var peekController: PeekController?
    
    init(context: AccountContext, controllerInteraction: ChatControllerInteraction, chatPeerId: EnginePeer.Id?) {
        self.context = context
        self.controllerInteraction = controllerInteraction
        self.chatPeerId = chatPeerId
    }
    
    func setGestureRecognizerEnabled(view: UIView, isEnabled: Bool, itemAtPoint: @escaping (CGPoint) -> (AnyHashable, EmojiPagerContentComponent.View.ItemLayer, TelegramMediaFile)?) {
        if self.peekRecognizer == nil {
            let peekRecognizer = PeekControllerGestureRecognizer(contentAtPoint: { [weak self, weak view] point in
                guard let strongSelf = self else {
                    return nil
                }
                guard let (groupId, itemLayer, file) = itemAtPoint(point) else {
                    return nil
                }
                
                var bubbleUpEmojiOrStickersets: [ItemCollectionId] = []
                if let id = groupId.base as? ItemCollectionId {
                    bubbleUpEmojiOrStickersets.append(id)
                }
                
                let context = strongSelf.context
                let accountPeerId = context.account.peerId
                return combineLatest(
                    context.engine.stickers.isStickerSaved(id: file.fileId),
                    context.engine.data.get(TelegramEngine.EngineData.Item.Peer.Peer(id: accountPeerId)) |> map { peer -> Bool in
                        var hasPremium = false
                        if case let .user(user) = peer, user.isPremium {
                            hasPremium = true
                        }
                        return hasPremium
                    }
                )
                |> deliverOnMainQueue
                |> map { [weak itemLayer] isStarred, hasPremium -> (UIView, CGRect, PeekControllerContent)? in
                    guard let strongSelf = self, let itemLayer = itemLayer else {
                        return nil
                    }
                    var menuItems: [ContextMenuItem] = []
                    
                    let presentationData = context.sharedContext.currentPresentationData.with { $0 }
                    
                    let sendSticker: (FileMediaReference, Bool, Bool, String?, Bool, UIView, CGRect, CALayer?) -> Void = { fileReference, silentPosting, schedule, query, clearInput, sourceView, sourceRect, sourceLayer in
                        guard let strongSelf = self else {
                            return
                        }
                        let _ = strongSelf.controllerInteraction.sendSticker(fileReference, silentPosting, schedule, query, clearInput, sourceView, sourceRect, sourceLayer, bubbleUpEmojiOrStickersets)
                    }
                    
                    if let chatPeerId = strongSelf.chatPeerId {
                        if chatPeerId != strongSelf.context.account.peerId && chatPeerId.namespace != Namespaces.Peer.SecretChat  {
                            menuItems.append(.action(ContextMenuActionItem(text: presentationData.strings.Conversation_SendMessage_SendSilently, icon: { theme in
                                return generateTintedImage(image: UIImage(bundleImageName: "Chat/Input/Menu/SilentIcon"), color: theme.actionSheet.primaryTextColor)
                            }, action: { _, f in
                                if let strongSelf = self, let peekController = strongSelf.peekController {
                                    if let animationNode = (peekController.contentNode as? StickerPreviewPeekContentNode)?.animationNode {
                                        sendSticker(.standalone(media: file), true, false, nil, false, animationNode.view, animationNode.bounds, nil)
                                    } else if let imageNode = (peekController.contentNode as? StickerPreviewPeekContentNode)?.imageNode {
                                        sendSticker(.standalone(media: file), true, false, nil, false, imageNode.view, imageNode.bounds, nil)
                                    }
                                }
                                f(.default)
                            })))
                        }
                    
                        menuItems.append(.action(ContextMenuActionItem(text: presentationData.strings.Conversation_SendMessage_ScheduleMessage, icon: { theme in
                            return generateTintedImage(image: UIImage(bundleImageName: "Chat/Input/Menu/ScheduleIcon"), color: theme.actionSheet.primaryTextColor)
                        }, action: { _, f in
                            if let strongSelf = self, let peekController = strongSelf.peekController {
                                if let animationNode = (peekController.contentNode as? StickerPreviewPeekContentNode)?.animationNode {
                                    let _ = sendSticker(.standalone(media: file), false, true, nil, false, animationNode.view, animationNode.bounds, nil)
                                } else if let imageNode = (peekController.contentNode as? StickerPreviewPeekContentNode)?.imageNode {
                                    let _ = sendSticker(.standalone(media: file), false, true, nil, false, imageNode.view, imageNode.bounds, nil)
                                }
                            }
                            f(.default)
                        })))
                    }
                    
                    menuItems.append(
                        .action(ContextMenuActionItem(text: isStarred ? presentationData.strings.Stickers_RemoveFromFavorites : presentationData.strings.Stickers_AddToFavorites, icon: { theme in generateTintedImage(image: isStarred ? UIImage(bundleImageName: "Chat/Context Menu/Unfave") : UIImage(bundleImageName: "Chat/Context Menu/Fave"), color: theme.contextMenu.primaryColor) }, action: { _, f in
                            f(.default)
                            
                            let presentationData = context.sharedContext.currentPresentationData.with { $0 }
                            let _ = (context.engine.stickers.toggleStickerSaved(file: file, saved: !isStarred)
                            |> deliverOnMainQueue).start(next: { result in
                                guard let strongSelf = self else {
                                    return
                                }
                                
                                switch result {
                                case .generic:
                                    strongSelf.controllerInteraction.presentGlobalOverlayController(UndoOverlayController(presentationData: presentationData, content: .sticker(context: context, file: file, title: nil, text: !isStarred ? presentationData.strings.Conversation_StickerAddedToFavorites : presentationData.strings.Conversation_StickerRemovedFromFavorites, undoText: nil, customAction: nil), elevatedLayout: false, action: { _ in return false }), nil)
                                case let .limitExceeded(limit, premiumLimit):
                                    let premiumConfiguration = PremiumConfiguration.with(appConfiguration: context.currentAppConfiguration.with { $0 })
                                    let text: String
                                    if limit == premiumLimit || premiumConfiguration.isPremiumDisabled {
                                        text = presentationData.strings.Premium_MaxFavedStickersFinalText
                                    } else {
                                        text = presentationData.strings.Premium_MaxFavedStickersText("\(premiumLimit)").string
                                    }
                                    strongSelf.controllerInteraction.presentGlobalOverlayController(UndoOverlayController(presentationData: presentationData, content: .sticker(context: context, file: file, title: presentationData.strings.Premium_MaxFavedStickersTitle("\(limit)").string, text: text, undoText: nil, customAction: nil), elevatedLayout: false, action: { action in
                                        guard let strongSelf = self else {
                                            return false
                                        }
                                        if case .info = action {
                                            let controller = PremiumIntroScreen(context: context, source: .savedStickers)
                                            strongSelf.controllerInteraction.navigationController()?.pushViewController(controller)
                                            return true
                                        }
                                        return false
                                    }), nil)
                                }
                            })
                        }))
                    )
                    menuItems.append(
                        .action(ContextMenuActionItem(text: presentationData.strings.StickerPack_ViewPack, icon: { theme in
                            return generateTintedImage(image: UIImage(bundleImageName: "Chat/Context Menu/Sticker"), color: theme.actionSheet.primaryTextColor)
                        }, action: { _, f in
                            f(.default)
                            
                            guard let strongSelf = self else {
                                return
                            }
                            
                            loop: for attribute in file.attributes {
                            switch attribute {
                            case let .CustomEmoji(_, _, packReference), let .Sticker(_, packReference, _):
                                if let packReference = packReference {
                                    let controller = strongSelf.context.sharedContext.makeStickerPackScreen(context: context, updatedPresentationData: nil, mainStickerPack: packReference, stickerPacks: [packReference], loadedStickerPacks: [], parentNavigationController: strongSelf.controllerInteraction.navigationController(), sendSticker: { file, sourceView, sourceRect in
                                        sendSticker(file, false, false, nil, false, sourceView, sourceRect, nil)
                                        return true
                                    })
                                    
                                    strongSelf.controllerInteraction.navigationController()?.view.window?.endEditing(true)
                                    strongSelf.controllerInteraction.presentController(controller, nil)
                                }
                                break loop
                            default:
                                break
                            }
                        }
                        }))
                    )
                    
                    guard let view = view else {
                        return nil
                    }
                    
                    return (view, itemLayer.convert(itemLayer.bounds, to: view.layer), StickerPreviewPeekContent(account: context.account, theme: presentationData.theme, strings: presentationData.strings, item: .pack(file), isLocked: file.isPremiumSticker && !hasPremium, menu: menuItems, openPremiumIntro: {
                        guard let strongSelf = self else {
                            return
                        }
                        let controller = PremiumIntroScreen(context: context, source: .stickers)
                        strongSelf.controllerInteraction.navigationController()?.pushViewController(controller)
                    }))
                }
            }, present: { [weak self] content, sourceView, sourceRect in
                guard let strongSelf = self else {
                    return nil
                }
                
                let presentationData = strongSelf.context.sharedContext.currentPresentationData.with { $0 }
                let controller = PeekController(presentationData: presentationData, content: content, sourceView: {
                    return (sourceView, sourceRect)
                })
                
                strongSelf.peekController = controller
                strongSelf.controllerInteraction.presentGlobalOverlayController(controller, nil)
                return controller
            }, updateContent: { [weak self] content in
                guard let strongSelf = self else {
                    return
                }
                
                let _ = strongSelf
            })
            self.peekRecognizer = peekRecognizer
            view.addGestureRecognizer(peekRecognizer)
            peekRecognizer.isEnabled = isEnabled
        } else {
            self.peekRecognizer?.isEnabled = isEnabled
        }
    }
}
