import Foundation
import UIKit
import Display
import TelegramCore
import SwiftSignalKit
import AsyncDisplayKit
import Postbox
import StickerResources
import AccountContext
import AnimatedStickerNode
import TelegramAnimatedStickerNode
import TelegramPresentationData
import ShimmerEffect
import StickerPeekUI
import TextFormat

final class StickerPackPreviewInteraction {
    var previewedItem: StickerPreviewPeekItem?
    var playAnimatedStickers: Bool
    
    let addStickerPack: (StickerPackCollectionInfo, [StickerPackItem]) -> Void
    let removeStickerPack: (StickerPackCollectionInfo) -> Void
    let emojiSelected: (String, ChatTextInputTextCustomEmojiAttribute) -> Void
    let emojiLongPressed: (String, ChatTextInputTextCustomEmojiAttribute, ASDisplayNode, CGRect) -> Void
    
    init(playAnimatedStickers: Bool, addStickerPack: @escaping (StickerPackCollectionInfo, [StickerPackItem]) -> Void, removeStickerPack: @escaping (StickerPackCollectionInfo) -> Void, emojiSelected: @escaping (String, ChatTextInputTextCustomEmojiAttribute) -> Void, emojiLongPressed: @escaping (String, ChatTextInputTextCustomEmojiAttribute, ASDisplayNode, CGRect) -> Void) {
        self.playAnimatedStickers = playAnimatedStickers
        self.addStickerPack = addStickerPack
        self.removeStickerPack = removeStickerPack
        self.emojiSelected = emojiSelected
        self.emojiLongPressed = emojiLongPressed
    }
}

final class StickerPackPreviewGridItem: GridItem {
    let account: Account
    let stickerItem: StickerPackItem?
    let interaction: StickerPackPreviewInteraction
    let theme: PresentationTheme
    let isPremium: Bool
    let isLocked: Bool
    let isEmpty: Bool
    
    let section: GridSection? = nil
        
    init(account: Account, stickerItem: StickerPackItem?, interaction: StickerPackPreviewInteraction, theme: PresentationTheme, isPremium: Bool, isLocked: Bool, isEmpty: Bool) {
        self.account = account
        self.stickerItem = stickerItem
        self.interaction = interaction
        self.theme = theme
        self.isPremium = isPremium
        self.isLocked = isLocked
        self.isEmpty = isEmpty
    }
    
    func node(layout: GridNodeLayout, synchronousLoad: Bool) -> GridItemNode {
        let node = StickerPackPreviewGridItemNode()
        node.setup(account: self.account, stickerItem: self.stickerItem, interaction: self.interaction, theme: self.theme, isLocked: self.isLocked, isPremium: self.isPremium, isEmpty: self.isEmpty)
        return node
    }
    
    func update(node: GridItemNode) {
        guard let node = node as? StickerPackPreviewGridItemNode else {
            assertionFailure()
            return
        }
        node.setup(account: self.account, stickerItem: self.stickerItem, interaction: self.interaction, theme: self.theme, isLocked: self.isLocked, isPremium: self.isPremium, isEmpty: self.isEmpty)
    }
}

private let textFont = Font.regular(20.0)

final class StickerPackPreviewGridItemNode: GridItemNode {
    private var currentState: (Account, StickerPackItem?)?
    private var isLocked: Bool?
    private var isPremium: Bool?
    private var isEmpty: Bool?
    private let imageNode: TransformImageNode
    private var animationNode: AnimatedStickerNode?
    private var placeholderNode: StickerShimmerEffectNode
    
    private var lockBackground: UIVisualEffectView?
    private var lockTintView: UIView?
    private var lockIconNode: ASImageNode?
    
    private var theme: PresentationTheme?
    
    override var isVisibleInGrid: Bool {
        didSet {
            let visibility = self.isVisibleInGrid && (self.interaction?.playAnimatedStickers ?? true)
            if visibility && self.setupTimestamp == nil {
                self.setupTimestamp = CACurrentMediaTime()
            }
            if let animationNode = self.animationNode {
                animationNode.visibility = visibility
            }
        }
    }
    
    private var currentIsPreviewing = false
    
    private let stickerFetchedDisposable = MetaDisposable()
    private let effectFetchedDisposable = MetaDisposable()
    
    var interaction: StickerPackPreviewInteraction?
    
    var selected: (() -> Void)?
    
    var stickerPackItem: StickerPackItem? {
        return self.currentState?.1
    }
    
    override init() {
        self.imageNode = TransformImageNode()
        self.imageNode.isLayerBacked = !smartInvertColorsEnabled()
        self.placeholderNode = StickerShimmerEffectNode()
        self.placeholderNode.isUserInteractionEnabled = false
        
        super.init()
        
        self.addSubnode(self.imageNode)
        self.addSubnode(self.placeholderNode)
        
        var firstTime = true
        self.imageNode.imageUpdated = { [weak self] image in
            guard let strongSelf = self else {
                return
            }
            
            if image != nil {
                if let stickerItem = strongSelf.currentState?.1 {
                    if stickerItem.file.isVideoSticker || stickerItem.file.isAnimatedSticker {
                        strongSelf.removePlaceholder(animated: !firstTime)
                    } else {
                        let current = CACurrentMediaTime()
                        if let setupTimestamp = strongSelf.setupTimestamp, current - setupTimestamp > 0.3 {
                            strongSelf.removePlaceholder(animated: true)
                        } else {
                            strongSelf.removePlaceholder(animated: false)
                        }
                    }
                }
                firstTime = false
            }
        }
    }
    
    deinit {
        self.stickerFetchedDisposable.dispose()
        self.effectFetchedDisposable.dispose()
    }
    
    private func removePlaceholder(animated: Bool) {
        guard self.placeholderNode.alpha != 0 else {
            return
        }
        if !animated {
            self.placeholderNode.removeFromSupernode()
        } else {
            self.placeholderNode.alpha = 0.0
            self.placeholderNode.allowsGroupOpacity = true
            self.placeholderNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.2, completion: { [weak self] _ in
                self?.placeholderNode.removeFromSupernode()
                self?.placeholderNode.allowsGroupOpacity = false
            })
        }
    }
    
    override func didLoad() {
        super.didLoad()
        
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.imageNodeTap(_:))))
    }
    
    private var setupTimestamp: Double?
    func setup(account: Account, stickerItem: StickerPackItem?, interaction: StickerPackPreviewInteraction, theme: PresentationTheme, isLocked: Bool, isPremium: Bool, isEmpty: Bool) {
        self.interaction = interaction
        self.theme = theme
        
        if self.currentState == nil || self.currentState!.0 !== account || self.currentState!.1 != stickerItem || self.isLocked != isLocked || self.isPremium != isPremium || self.isEmpty != isEmpty {
            self.isLocked = isLocked
            
            if isLocked {
                let lockBackground: UIVisualEffectView
                let lockIconNode: ASImageNode
                if let currentBackground = self.lockBackground, let currentIcon = self.lockIconNode {
                    lockBackground = currentBackground
                    lockIconNode = currentIcon
                } else {
                    let effect: UIBlurEffect
                    if #available(iOS 10.0, *) {
                        effect = UIBlurEffect(style: .regular)
                    } else {
                        effect = UIBlurEffect(style: .light)
                    }
                    lockBackground = UIVisualEffectView(effect: effect)
                    lockBackground.clipsToBounds = true
                    lockBackground.isUserInteractionEnabled = false
                    lockIconNode = ASImageNode()
                    lockIconNode.displaysAsynchronously = false
                    lockIconNode.image = generateTintedImage(image: UIImage(bundleImageName: "Chat List/PeerPremiumIcon"), color: .white)
                    
                    let lockTintView = UIView()
                    lockTintView.backgroundColor = UIColor(rgb: 0x000000, alpha: 0.15)
                    lockBackground.contentView.addSubview(lockTintView)
                    
                    self.lockBackground = lockBackground
                    self.lockTintView = lockTintView
                    self.lockIconNode = lockIconNode
                    
                    self.view.addSubview(lockBackground)
                    self.addSubnode(lockIconNode)
                }
            } else if let lockBackground = self.lockBackground, let lockTintView = self.lockTintView, let lockIconNode = self.lockIconNode {
                self.lockBackground = nil
                self.lockTintView = nil
                self.lockIconNode = nil
                lockBackground.removeFromSuperview()
                lockTintView.removeFromSuperview()
                lockIconNode.removeFromSupernode()
            }
            
            if let stickerItem = stickerItem {
                let visibility = self.isVisibleInGrid && self.interaction?.playAnimatedStickers ?? true
                if visibility && self.setupTimestamp == nil {
                    self.setupTimestamp = CACurrentMediaTime()
                }
                
                if stickerItem.file.isAnimatedSticker || stickerItem.file.isVideoSticker {
                    let dimensions = stickerItem.file.dimensions ?? PixelDimensions(width: 512, height: 512)
                    if stickerItem.file.isVideoSticker {
                        self.imageNode.setSignal(chatMessageSticker(account: account, file: stickerItem.file, small: true))
                    } else {
                        self.imageNode.setSignal(chatMessageAnimatedSticker(postbox: account.postbox, file: stickerItem.file, small: false, size: dimensions.cgSize.aspectFitted(CGSize(width: 160.0, height: 160.0))))
                    }
                    
                    if self.animationNode == nil {
                        let animationNode = DefaultAnimatedStickerNodeImpl()
                        self.animationNode = animationNode
                        self.insertSubnode(animationNode, aboveSubnode: self.imageNode)
                        animationNode.started = { [weak self] in
                            guard let strongSelf = self else {
                                return
                            }
                            self?.imageNode.isHidden = true
                            
                            let current = CACurrentMediaTime()
                            if let setupTimestamp = strongSelf.setupTimestamp, current - setupTimestamp > 0.3 {
                                if !strongSelf.placeholderNode.alpha.isZero {
                                    strongSelf.removePlaceholder(animated: true)
                                }
                            } else {
                                strongSelf.removePlaceholder(animated: false)
                            }
                        }
                    }
                    let fittedDimensions = dimensions.cgSize.aspectFitted(CGSize(width: 160.0, height: 160.0))
                    self.animationNode?.setup(source: AnimatedStickerResourceSource(account: account, resource: stickerItem.file.resource, isVideo: stickerItem.file.isVideoSticker), width: Int(fittedDimensions.width), height: Int(fittedDimensions.height), playbackMode: .loop, mode: .cached)
                    
                    self.animationNode?.visibility = visibility
                                        
                    self.stickerFetchedDisposable.set(freeMediaFileResourceInteractiveFetched(account: account, fileReference: stickerPackFileReference(stickerItem.file), resource: stickerItem.file.resource).start())
                    
                    if stickerItem.file.isPremiumSticker, let effect = stickerItem.file.videoThumbnails.first {
                        self.effectFetchedDisposable.set(freeMediaFileResourceInteractiveFetched(account: account, fileReference: stickerPackFileReference(stickerItem.file), resource: effect.resource).start())
                    }
                } else {
                    if let animationNode = self.animationNode {
                        animationNode.visibility = false
                        self.animationNode = nil
                        animationNode.removeFromSupernode()
                    }
                    self.imageNode.setSignal(chatMessageSticker(account: account, file: stickerItem.file, small: true))
                    self.stickerFetchedDisposable.set(freeMediaFileResourceInteractiveFetched(account: account, fileReference: stickerPackFileReference(stickerItem.file), resource: chatMessageStickerResource(file: stickerItem.file, small: true)).start())
                }
            } else {
                if isEmpty {
                    if !self.placeholderNode.alpha.isZero {
                        self.placeholderNode.alpha = 0.0
                        self.placeholderNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.2)
                    }
                } else {
                    self.placeholderNode.alpha = 1.0
                }
            }
            
            self.animationNode?.alpha = isLocked ? 0.5 : 1.0
            self.imageNode.alpha = isLocked ? 0.5 : 1.0
            
            self.currentState = (account, stickerItem)
            self.setNeedsLayout()
        }
        self.isEmpty = isEmpty
    }
    
    override func layout() {
        super.layout()
        
        let bounds = self.bounds
        let boundsSide = min(bounds.size.width - 14.0, bounds.size.height - 14.0)
        var boundingSize = CGSize(width: boundsSide, height: boundsSide)
                
        if let (_, item) = self.currentState {
            if let item = item, let dimensions = item.file.dimensions?.cgSize {
                if item.file.isPremiumSticker {
                    boundingSize = CGSize(width: boundingSize.width * 1.1, height: boundingSize.width * 1.1)
                }
                
                let imageSize = dimensions.aspectFitted(boundingSize)
                let imageFrame = CGRect(origin: CGPoint(x: floor((bounds.size.width - imageSize.width) / 2.0), y: (bounds.size.height - imageSize.height) / 2.0), size: imageSize)
                self.imageNode.asyncLayout()(TransformImageArguments(corners: ImageCorners(), imageSize: imageSize, boundingSize: imageSize, intrinsicInsets: UIEdgeInsets()))()
                self.imageNode.frame = imageFrame
                if let animationNode = self.animationNode {
                    animationNode.frame = imageFrame
                    animationNode.updateLayout(size: imageSize)
                }
            }
        }
        
        let imageFrame = self.imageNode.frame
            
        let placeholderFrame = imageFrame
        self.placeholderNode.frame = imageFrame
    
        if let theme = self.theme, let (_, stickerItem) = self.currentState, let item = stickerItem {
            self.placeholderNode.update(backgroundColor: theme.list.itemBlocksBackgroundColor, foregroundColor: theme.list.mediaPlaceholderColor, shimmeringColor: theme.list.itemBlocksBackgroundColor.withAlphaComponent(0.4), data: item.file.immediateThumbnailData, size: placeholderFrame.size)
        }
        
        if let lockBackground = self.lockBackground, let lockTintView = self.lockTintView, let lockIconNode = self.lockIconNode {
            let lockSize = CGSize(width: 16.0, height: 16.0)
            let lockBackgroundFrame = CGRect(origin: CGPoint(x: bounds.width - lockSize.width, y: bounds.height - lockSize.height), size: lockSize)
            lockBackground.frame = lockBackgroundFrame
            lockBackground.layer.cornerRadius = lockSize.width / 2.0
            if #available(iOS 13.0, *) {
                lockBackground.layer.cornerCurve = .circular
            }
            lockTintView.frame = CGRect(origin: CGPoint(), size: lockBackgroundFrame.size)
            if let icon = lockIconNode.image {
                let iconSize = CGSize(width: icon.size.width - 4.0, height: icon.size.height - 4.0)
                lockIconNode.frame = CGRect(origin: CGPoint(x: lockBackgroundFrame.minX + floorToScreenPixels((lockBackgroundFrame.width - iconSize.width) / 2.0), y: lockBackgroundFrame.minY + floorToScreenPixels((lockBackgroundFrame.height - iconSize.height) / 2.0)), size: iconSize)
            }
        }
    }
    
    override func updateAbsoluteRect(_ absoluteRect: CGRect, within containerSize: CGSize) {
        self.placeholderNode.updateAbsoluteRect(absoluteRect, within: containerSize)
    }
    
    func transitionNode() -> ASDisplayNode? {
        return self
    }
    
    @objc func imageNodeTap(_ recognizer: UITapGestureRecognizer) {
    }
    
    func updatePreviewing(animated: Bool) {
        var isPreviewing = false
        if let (_, maybeItem) = self.currentState, let interaction = self.interaction, let item = maybeItem {
            isPreviewing = interaction.previewedItem == .pack(item.file)
        }
        if self.currentIsPreviewing != isPreviewing {
            self.currentIsPreviewing = isPreviewing
            
            if isPreviewing {
                self.layer.sublayerTransform = CATransform3DMakeScale(0.8, 0.8, 1.0)
                if animated {
                    self.layer.animateSpring(from: 1.0 as NSNumber, to: 0.8 as NSNumber, keyPath: "sublayerTransform.scale", duration: 0.4)
                }
            } else {
                self.layer.sublayerTransform = CATransform3DIdentity
                if animated {
                    self.layer.animateSpring(from: 0.8 as NSNumber, to: 1.0 as NSNumber, keyPath: "sublayerTransform.scale", duration: 0.5)
                }
            }
        }
    }
}

