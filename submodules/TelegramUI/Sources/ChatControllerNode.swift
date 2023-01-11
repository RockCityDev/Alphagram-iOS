import Foundation
import UIKit
import AsyncDisplayKit
import Postbox
import SwiftSignalKit
import Display
import TelegramCore
import TelegramPresentationData
import TelegramUIPreferences
import TextFormat
import AccountContext
import TelegramNotices
import TelegramUniversalVideoContent
import ChatInterfaceState
import FastBlur
import ConfettiEffect
import WallpaperBackgroundNode
import GridMessageSelectionNode
import SparseItemGrid
import ChatPresentationInterfaceState
import ChatInputPanelContainer
import PremiumUI
import ChatTitleView

final class VideoNavigationControllerDropContentItem: NavigationControllerDropContentItem {
    let itemNode: OverlayMediaItemNode
    
    init(itemNode: OverlayMediaItemNode) {
        self.itemNode = itemNode
    }
}

private final class ChatControllerNodeView: UITracingLayerView, WindowInputAccessoryHeightProvider {
    var inputAccessoryHeight: (() -> CGFloat)?
    var hitTestImpl: ((CGPoint, UIEvent?) -> UIView?)?
    
    func getWindowInputAccessoryHeight() -> CGFloat {
        return self.inputAccessoryHeight?() ?? 0.0
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let result = self.hitTestImpl?(point, event) {
            return result
        }
        return super.hitTest(point, with: event)
    }
}

private final class ScrollContainerNode: ASScrollNode {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if super.hitTest(point, with: event) == self.view {
            return nil
        }
        
        return super.hitTest(point, with: event)
    }
}

private struct ChatControllerNodeDerivedLayoutState {
    var inputContextPanelsFrame: CGRect
    var inputContextPanelsOverMainPanelFrame: CGRect
    var inputNodeHeight: CGFloat?
    var inputNodeAdditionalHeight: CGFloat?
    var upperInputPositionBound: CGFloat?
}

class ChatControllerNode: ASDisplayNode, UIScrollViewDelegate {
    let context: AccountContext
    let chatLocation: ChatLocation
    let controllerInteraction: ChatControllerInteraction
    private weak var controller: ChatControllerImpl?
    
    let navigationBar: NavigationBar?
    let statusBar: StatusBar?
    
    private var backgroundEffectNode: ASDisplayNode?
    private var containerBackgroundNode: ASImageNode?
    private var scrollContainerNode: ScrollContainerNode?
    private var containerNode: ASDisplayNode?
    private var overlayNavigationBar: ChatOverlayNavigationBar?
    
    var overlayTitle: String? {
        didSet {
            self.overlayNavigationBar?.title = self.overlayTitle
        }
    }
    
    let contentContainerNode: ASDisplayNode
    let contentDimNode: ASDisplayNode
    let backgroundNode: WallpaperBackgroundNode
    let historyNode: ChatHistoryListNode
    var blurredHistoryNode: ASImageNode?
    let historyNodeContainer: ASDisplayNode
    let loadingNode: ChatLoadingNode
    private(set) var loadingPlaceholderNode: ChatLoadingPlaceholderNode?
    
    private var emptyNode: ChatEmptyNode?
    private(set) var emptyType: ChatHistoryNodeLoadState.EmptyType?
    private var didDisplayEmptyGreeting = false
    private var validEmptyNodeLayout: (CGSize, UIEdgeInsets)?
    var restrictedNode: ChatRecentActionsEmptyNode?
    
    private var validLayout: (ContainerViewLayout, CGFloat)?
    private var visibleAreaInset = UIEdgeInsets()
    
    private var searchNavigationNode: ChatSearchNavigationContentNode?
    
    private var navigationModalFrame: NavigationModalFrame?
    
    let inputPanelContainerNode: ChatInputPanelContainer
    private let inputPanelOverlayNode: SparseNode
    private let inputPanelClippingNode: SparseNode
    private let inputPanelBackgroundNode: NavigationBackgroundNode
    
    private var navigationBarBackgroundContent: WallpaperBubbleBackgroundNode?
    private var inputPanelBackgroundContent: WallpaperBubbleBackgroundNode?
    
    private var intrinsicInputPanelBackgroundNodeSize: CGSize?
    private let inputPanelBackgroundSeparatorNode: ASDisplayNode
    private var inputPanelBottomBackgroundSeparatorBaseOffset: CGFloat = 0.0
    private let inputPanelBottomBackgroundSeparatorNode: ASDisplayNode
    private var plainInputSeparatorAlpha: CGFloat?
    private var usePlainInputSeparator: Bool
    
    private var chatImportStatusPanel: ChatImportStatusPanel?
    
    private let titleAccessoryPanelContainer: ChatControllerTitlePanelNodeContainer
    private var titleAccessoryPanelNode: ChatTitleAccessoryPanelNode?
    
    private var inputPanelNode: ChatInputPanelNode?
    private(set) var inputPanelOverscrollNode: ChatInputPanelOverscrollNode?
    private weak var currentDismissedInputPanelNode: ChatInputPanelNode?
    private var secondaryInputPanelNode: ChatInputPanelNode?
    private(set) var accessoryPanelNode: AccessoryPanelNode?
    private var inputContextPanelNode: ChatInputContextPanelNode?
    let inputContextPanelContainer: ChatControllerTitlePanelNodeContainer
    private let inputContextOverTextPanelContainer: ChatControllerTitlePanelNodeContainer
    private var overlayContextPanelNode: ChatInputContextPanelNode?
    
    private var inputNode: ChatInputNode?
    private var disappearingNode: ChatInputNode?
    
    private(set) var textInputPanelNode: ChatTextInputPanelNode?
    
    private var inputMediaNode: ChatMediaInputNode?
    private var inputMediaNodeData: ChatEntityKeyboardInputNode.InputData?
    private var inputMediaNodeDataPromise = Promise<ChatEntityKeyboardInputNode.InputData>()
    private var didInitializeInputMediaNodeDataPromise: Bool = false
    private var inputMediaNodeDataDisposable: Disposable?
    
    let navigateButtons: ChatHistoryNavigationButtons
    
    private var ignoreUpdateHeight = false
    private var overrideUpdateTextInputHeightTransition: ContainedViewLayoutTransition?
    
    private var animateInAsOverlayCompletion: (() -> Void)?
    private var dismissAsOverlayCompletion: (() -> Void)?
    private var dismissedAsOverlay = false
    private var scheduledAnimateInAsOverlayFromNode: ASDisplayNode?
    private var dismissAsOverlayLayout: ContainerViewLayout?
    
    private var hapticFeedback: HapticFeedback?
    private var scrollViewDismissStatus = false
    
    var chatPresentationInterfaceState: ChatPresentationInterfaceState
    var automaticMediaDownloadSettings: MediaAutoDownloadSettings
    
    private var interactiveEmojis: InteractiveEmojiConfiguration?
    private var interactiveEmojisDisposable: Disposable?
    
    private let selectedMessagesPromise = Promise<Set<MessageId>?>(nil)
    var selectedMessages: Set<MessageId>? {
        didSet {
            if self.selectedMessages != oldValue {
                self.selectedMessagesPromise.set(.single(self.selectedMessages))
            }
        }
    }
    
    private let updatingMessageMediaPromise = Promise<[MessageId: ChatUpdatingMessageMedia]>([:])
    var updatingMessageMedia: [MessageId: ChatUpdatingMessageMedia] = [:] {
        didSet {
            if self.updatingMessageMedia != oldValue {
                self.updatingMessageMediaPromise.set(.single(self.updatingMessageMedia))
            }
        }
    }
    
    var requestUpdateChatInterfaceState: (ContainedViewLayoutTransition, Bool, (ChatInterfaceState) -> ChatInterfaceState) -> Void = { _, _, _ in }
    var requestUpdateInterfaceState: (ContainedViewLayoutTransition, Bool, (ChatPresentationInterfaceState) -> ChatPresentationInterfaceState) -> Void = { _, _, _ in }
    var sendMessages: ([EnqueueMessage], Bool?, Int32?, Bool) -> Void = { _, _, _, _ in }
    var displayAttachmentMenu: () -> Void = { }
    var paste: (ChatTextInputPanelPasteData) -> Void = { _ in }
    var updateTypingActivity: (Bool) -> Void = { _ in }
    var dismissUrlPreview: () -> Void = { }
    var setupSendActionOnViewUpdate: (@escaping () -> Void, Int64?) -> Void = { _, _ in }
    var requestLayout: (ContainedViewLayoutTransition) -> Void = { _ in }
    var dismissAsOverlay: () -> Void = { }
    
    var interfaceInteraction: ChatPanelInterfaceInteraction?
        
    private var expandedInputDimNode: ASDisplayNode?
    
    private var dropDimNode: ASDisplayNode?

    let messageTransitionNode: ChatMessageTransitionNode

    private let presentationContextMarker = ASDisplayNode()
    
    private var containerLayoutAndNavigationBarHeight: (ContainerViewLayout, CGFloat)?
    
    private var scheduledLayoutTransitionRequestId: Int = 0
    private var scheduledLayoutTransitionRequest: (Int, ContainedViewLayoutTransition)?
    
    private var panRecognizer: WindowPanRecognizer?
    private let keyboardGestureRecognizerDelegate = WindowKeyboardGestureRecognizerDelegate()
    private var upperInputPositionBound: CGFloat?
    private var keyboardGestureBeginLocation: CGPoint?
    private var keyboardGestureAccessoryHeight: CGFloat?
    
    private var derivedLayoutState: ChatControllerNodeDerivedLayoutState?
    
    private var isLoadingValue: Bool = false
    private var isLoadingEarlier: Bool = false
    private func updateIsLoading(isLoading: Bool, earlier: Bool, animated: Bool) {
        let useLoadingPlaceholder = self.chatLocation.peerId?.namespace != Namespaces.Peer.CloudUser
        
        let updated = isLoading != self.isLoadingValue || (isLoading && earlier && !self.isLoadingEarlier)
        
        if updated {
            let updatedIsLoading = self.isLoadingValue != isLoading
            self.isLoadingValue = isLoading
            
            let updatedIsEarlier = self.isLoadingEarlier != earlier && !updatedIsLoading
            self.isLoadingEarlier = earlier
            
            if isLoading {
                if useLoadingPlaceholder {
                    let loadingPlaceholderNode: ChatLoadingPlaceholderNode
                    if let current = self.loadingPlaceholderNode {
                        loadingPlaceholderNode = current
                        
                        if updatedIsEarlier {
                            loadingPlaceholderNode.setup(self.historyNode, updating: true)
                        }
                    } else {
                        loadingPlaceholderNode = ChatLoadingPlaceholderNode(theme: self.chatPresentationInterfaceState.theme, chatWallpaper: self.chatPresentationInterfaceState.chatWallpaper, bubbleCorners: self.chatPresentationInterfaceState.bubbleCorners, backgroundNode: self.backgroundNode)
                        loadingPlaceholderNode.updatePresentationInterfaceState(self.chatPresentationInterfaceState)
                        self.backgroundNode.supernode?.insertSubnode(loadingPlaceholderNode, aboveSubnode: self.backgroundNode)
                        
                        self.loadingPlaceholderNode = loadingPlaceholderNode
                     
                        loadingPlaceholderNode.setup(self.historyNode, updating: false)
                        
                        if let (layout, navigationHeight) = self.validLayout {
                            self.containerLayoutUpdated(layout, navigationBarHeight: navigationHeight, transition: .immediate, listViewTransaction: { _, _, _, _ in
                            }, updateExtraNavigationBarBackgroundHeight: { _, _ in
                            })
                        }
                    }
                    loadingPlaceholderNode.alpha = 1.0
                    loadingPlaceholderNode.isHidden = false
                } else {
                    self.historyNodeContainer.supernode?.insertSubnode(self.loadingNode, belowSubnode: self.historyNodeContainer)
                    self.loadingNode.isHidden = false
                    self.loadingNode.layer.removeAllAnimations()
                    self.loadingNode.alpha = 1.0
                    if animated {
                        self.loadingNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.3)
                    }
                }
            } else {
                if useLoadingPlaceholder {
                    if let loadingPlaceholderNode = self.loadingPlaceholderNode {
                        loadingPlaceholderNode.animateOut(self.historyNode, completion: { [weak self] in
                            if let strongSelf = self {
                                strongSelf.loadingPlaceholderNode?.removeFromSupernode()
                                strongSelf.loadingPlaceholderNode = nil
                            }
                        })
                    }
                } else {
                    self.loadingNode.alpha = 0.0
                    if animated {
                        self.loadingNode.layer.animateScale(from: 1.0, to: 0.1, duration: 0.3, removeOnCompletion: false)
                        self.loadingNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.3, completion: { [weak self] completed in
                            if let strongSelf = self {
                                strongSelf.loadingNode.layer.removeAllAnimations()
                                if completed {
                                    strongSelf.loadingNode.isHidden = true
                                }
                            }
                        })
                    } else {
                        self.loadingNode.isHidden = true
                    }
                }
            }
        }
    }
    
    private var lastSendTimestamp = 0.0
    
    private var openStickersBeginWithEmoji: Bool = false
    private var openStickersDisposable: Disposable?
    private var displayVideoUnmuteTipDisposable: Disposable?
    
    private var onLayoutCompletions: [(ContainedViewLayoutTransition) -> Void] = []

    init(context: AccountContext, chatLocation: ChatLocation, chatLocationContextHolder: Atomic<ChatLocationContextHolder?>, subject: ChatControllerSubject?, controllerInteraction: ChatControllerInteraction, chatPresentationInterfaceState: ChatPresentationInterfaceState, automaticMediaDownloadSettings: MediaAutoDownloadSettings, navigationBar: NavigationBar?, statusBar: StatusBar?, backgroundNode: WallpaperBackgroundNode, controller: ChatControllerImpl?) {
        self.context = context
        self.chatLocation = chatLocation
        self.controllerInteraction = controllerInteraction
        self.chatPresentationInterfaceState = chatPresentationInterfaceState
        self.automaticMediaDownloadSettings = automaticMediaDownloadSettings
        self.navigationBar = navigationBar
        self.statusBar = statusBar
        self.controller = controller
        
        self.backgroundNode = backgroundNode
        
        self.contentContainerNode = ASDisplayNode()
        self.contentDimNode = ASDisplayNode()
        self.contentDimNode.isUserInteractionEnabled = false
        self.contentDimNode.backgroundColor = UIColor(white: 0.0, alpha: 0.2)
        self.contentDimNode.alpha = 0.0
        
        self.titleAccessoryPanelContainer = ChatControllerTitlePanelNodeContainer()
        self.titleAccessoryPanelContainer.clipsToBounds = true
        
        self.inputContextPanelContainer = ChatControllerTitlePanelNodeContainer()
        self.inputContextOverTextPanelContainer = ChatControllerTitlePanelNodeContainer()
        
        var source: ChatHistoryListSource
        if case let .forwardedMessages(messageIds, options) = subject {
            let messages = combineLatest(context.account.postbox.messagesAtIds(messageIds), context.account.postbox.loadedPeerWithId(context.account.peerId), options)
            |> map { messages, accountPeer, options -> ([Message], Int32, Bool) in
                var messages = messages
                let forwardedMessageIds = Set(messages.map { $0.id })
                messages.sort(by: { lhsMessage, rhsMessage in
                    return lhsMessage.timestamp > rhsMessage.timestamp
                })
                messages = messages.map { message in
                    var flags = message.flags
                    flags.remove(.Incoming)
                    flags.remove(.IsIncomingMask)
                    
                    var hideNames = options.hideNames
                    if message.id.peerId == accountPeer.id && message.forwardInfo == nil {
                        hideNames = true
                    }
                    
                    var attributes = message.attributes
                    attributes = attributes.filter({ attribute in
                        if attribute is EditedMessageAttribute {
                            return false
                        }
                        if let attribute = attribute as? ReplyMessageAttribute {
                            if !forwardedMessageIds.contains(attribute.messageId) || hideNames {
                                return false
                            }
                        }
                        if attribute is ReplyMarkupMessageAttribute {
                            return false
                        }
                        if attribute is ReplyThreadMessageAttribute {
                            return false
                        }
                        if attribute is ViewCountMessageAttribute{
                            return false
                        }
                        if attribute is ForwardCountMessageAttribute {
                            return false
                        }
                        if attribute is ReactionsMessageAttribute {
                            return false
                        }
                        return true
                    })
                    
                    var messageText = message.text
                    var messageMedia = message.media
                    var hasDice = false
                    if hideNames {
                        for media in message.media {
                            if options.hideCaptions {
                                if media is TelegramMediaImage || media is TelegramMediaFile {
                                    messageText = ""
                                    break
                                }
                            }
                            if let poll = media as? TelegramMediaPoll {
                                var updatedMedia = message.media.filter { !($0 is TelegramMediaPoll) }
                                updatedMedia.append(TelegramMediaPoll(pollId: poll.pollId, publicity: poll.publicity, kind: poll.kind, text: poll.text, options: poll.options, correctAnswers: poll.correctAnswers, results: TelegramMediaPollResults(voters: nil, totalVoters: nil, recentVoters: [], solution: nil), isClosed: false, deadlineTimeout: nil))
                                messageMedia = updatedMedia
                            }
                            if let _ = media as? TelegramMediaDice {
                                hasDice = true
                            }
                        }
                    }
                    
                    var forwardInfo: MessageForwardInfo?
                    if let existingForwardInfo = message.forwardInfo {
                        forwardInfo = MessageForwardInfo(author: existingForwardInfo.author, source: existingForwardInfo.source, sourceMessageId: nil, date: 0, authorSignature: nil, psaType: nil, flags: [])
                    }
                    else {
                        forwardInfo = MessageForwardInfo(author: message.author, source: nil, sourceMessageId: nil, date: 0, authorSignature: nil, psaType: nil, flags: [])
                    }
                    if hideNames && !hasDice {
                        forwardInfo = nil
                    }
                    
                    return message.withUpdatedFlags(flags).withUpdatedText(messageText).withUpdatedMedia(messageMedia).withUpdatedTimestamp(Int32(context.account.network.context.globalTime())).withUpdatedAttributes(attributes).withUpdatedAuthor(accountPeer).withUpdatedForwardInfo(forwardInfo)
                }
                
                return (messages, Int32(messages.count), false)
            }
            source = .custom(messages: messages, messageId: MessageId(peerId: PeerId(0), namespace: 0, id: 0), loadMore: nil)
        } else {
            source = .default
        }

        var getMessageTransitionNode: (() -> ChatMessageTransitionNode?)?
        self.historyNode = ChatHistoryListNode(context: context, updatedPresentationData: controller?.updatedPresentationData ?? (context.sharedContext.currentPresentationData.with({ $0 }), context.sharedContext.presentationData), chatLocation: chatLocation, chatLocationContextHolder: chatLocationContextHolder, tagMask: nil, source: source, subject: subject, controllerInteraction: controllerInteraction, selectedMessages: self.selectedMessagesPromise.get(), messageTransitionNode: {
            return getMessageTransitionNode?()
        })
        self.historyNode.rotated = true

        
        

        self.historyNodeContainer = ASDisplayNode()
        self.historyNodeContainer.addSubnode(self.historyNode)
        

        var getContentAreaInScreenSpaceImpl: (() -> CGRect)?
        var onTransitionEventImpl: ((ContainedViewLayoutTransition) -> Void)?
        self.messageTransitionNode = ChatMessageTransitionNode(listNode: self.historyNode, getContentAreaInScreenSpace: {
            return getContentAreaInScreenSpaceImpl?() ?? CGRect()
        }, onTransitionEvent: { transition in
            onTransitionEventImpl?(transition)
        })
        
        self.loadingNode = ChatLoadingNode(theme: self.chatPresentationInterfaceState.theme, chatWallpaper: self.chatPresentationInterfaceState.chatWallpaper, bubbleCorners: self.chatPresentationInterfaceState.bubbleCorners)
                
        self.inputPanelContainerNode = ChatInputPanelContainer()
        self.inputPanelOverlayNode = SparseNode()
        self.inputPanelClippingNode = SparseNode()
        
        if case let .color(color) = self.chatPresentationInterfaceState.chatWallpaper, UIColor(rgb: color).isEqual(self.chatPresentationInterfaceState.theme.chat.inputPanel.panelBackgroundColorNoWallpaper) {
            self.inputPanelBackgroundNode = NavigationBackgroundNode(color: self.chatPresentationInterfaceState.theme.chat.inputPanel.panelBackgroundColorNoWallpaper)
            self.usePlainInputSeparator = true
        } else {
            self.inputPanelBackgroundNode = NavigationBackgroundNode(color: self.chatPresentationInterfaceState.theme.chat.inputPanel.panelBackgroundColor)
            self.usePlainInputSeparator = false
            self.plainInputSeparatorAlpha = nil
        }
        self.inputPanelBackgroundNode.isUserInteractionEnabled = false
        
        self.inputPanelBackgroundSeparatorNode = ASDisplayNode()
        self.inputPanelBackgroundSeparatorNode.backgroundColor = self.chatPresentationInterfaceState.theme.chat.inputPanel.panelSeparatorColor
        self.inputPanelBackgroundSeparatorNode.isLayerBacked = true
        
        self.inputPanelBottomBackgroundSeparatorNode = ASDisplayNode()
        self.inputPanelBottomBackgroundSeparatorNode.backgroundColor = self.chatPresentationInterfaceState.theme.chat.inputMediaPanel.panelSeparatorColor
        self.inputPanelBottomBackgroundSeparatorNode.isLayerBacked = true
        
        self.navigateButtons = ChatHistoryNavigationButtons(theme: self.chatPresentationInterfaceState.theme, dateTimeFormat: self.chatPresentationInterfaceState.dateTimeFormat, backgroundNode: self.backgroundNode)
        self.navigateButtons.accessibilityElementsHidden = true
        
        super.init()

        getContentAreaInScreenSpaceImpl = { [weak self] in
            guard let strongSelf = self else {
                return CGRect()
            }

            return strongSelf.view.convert(strongSelf.frameForVisibleArea(), to: nil)
        }

        onTransitionEventImpl = { [weak self] transition in
            guard let strongSelf = self else {
                return
            }
            if (strongSelf.context.sharedContext.currentPresentationData.with({ $0 })).reduceMotion {
                return
            }
            strongSelf.backgroundNode.animateEvent(transition: transition, extendAnimation: false)
        }

        getMessageTransitionNode = { [weak self] in
            return self?.messageTransitionNode
        }
        
        self.controller?.presentationContext.topLevelSubview = { [weak self] in
            guard let strongSelf = self else {
                return nil
            }
            return strongSelf.presentationContextMarker.view
        }
        
        self.setViewBlock({
            return ChatControllerNodeView()
        })
        
        (self.view as? ChatControllerNodeView)?.inputAccessoryHeight = { [weak self] in
            if let strongSelf = self {
                return strongSelf.getWindowInputAccessoryHeight()
            } else {
                return 0.0
            }
        }
        
        (self.view as? ChatControllerNodeView)?.hitTestImpl = { [weak self] point, event in
            return self?.hitTest(point, with: event)
        }
        
        assert(Queue.mainQueue().isCurrent())
                
        self.historyNode.setLoadStateUpdated { [weak self] loadState, animated in
            if let strongSelf = self {
                let wasLoading = strongSelf.isLoadingValue
                if case let .loading(earlier) = loadState {
                    strongSelf.updateIsLoading(isLoading: true, earlier: earlier, animated: animated)
                } else {
                    strongSelf.updateIsLoading(isLoading: false, earlier: false, animated: animated)
                }
                
                var emptyType: ChatHistoryNodeLoadState.EmptyType?
                if case let .empty(type) = loadState {
                    emptyType = type
                    if case .joined = type {
                        if strongSelf.didDisplayEmptyGreeting {
                            emptyType = .generic
                        } else {
                            strongSelf.didDisplayEmptyGreeting = true
                        }
                    }
                } else if case .messages = loadState {
                    strongSelf.didDisplayEmptyGreeting = true
                }
                strongSelf.updateIsEmpty(emptyType, wasLoading: wasLoading, animated: animated)
            }
        }
        
        self.interactiveEmojisDisposable = (self.context.account.postbox.preferencesView(keys: [PreferencesKeys.appConfiguration])
        |> map { preferencesView -> InteractiveEmojiConfiguration in
            let appConfiguration: AppConfiguration = preferencesView.values[PreferencesKeys.appConfiguration]?.get(AppConfiguration.self) ?? .defaultValue
            return InteractiveEmojiConfiguration.with(appConfiguration: appConfiguration)
        }
        |> deliverOnMainQueue).start(next: { [weak self] emojis in
            if let strongSelf = self {
                strongSelf.interactiveEmojis = emojis
            }
        })

        var backgroundColors: [UInt32] = []
        switch chatPresentationInterfaceState.chatWallpaper {
        case let .file(file):
            if file.isPattern {
                backgroundColors = file.settings.colors
            }
        case let .gradient(gradient):
            backgroundColors = gradient.colors
        case let .color(color):
            backgroundColors = [color]
        default:
            break
        }
        if !backgroundColors.isEmpty {
            let averageColor = UIColor.average(of: backgroundColors.map(UIColor.init(rgb:)))
            if averageColor.hsb.b >= 0.3 {
                self.historyNode.verticalScrollIndicatorColor = UIColor(white: 0.0, alpha: 0.3)
            } else {
                self.historyNode.verticalScrollIndicatorColor = UIColor(white: 1.0, alpha: 0.3)
            }
        } else {
            self.historyNode.verticalScrollIndicatorColor = UIColor(white: 0.5, alpha: 0.8)
        }
        self.historyNode.enableExtractedBackgrounds = true
    
        self.addSubnode(self.contentContainerNode)
        self.contentContainerNode.addSubnode(self.backgroundNode)
        self.contentContainerNode.addSubnode(self.historyNodeContainer)
        
        if let navigationBar = self.navigationBar {
            self.contentContainerNode.addSubnode(navigationBar)
        }
        
        self.inputPanelContainerNode.expansionUpdated = { [weak self] transition in
            guard let strongSelf = self else {
                return
            }

            if transition.isAnimated {
                strongSelf.scheduleLayoutTransitionRequest(transition)
            } else {
                strongSelf.requestLayout(transition)
            }
        }
        
        self.addSubnode(self.inputContextPanelContainer)
        self.addSubnode(self.inputPanelContainerNode)
        self.addSubnode(self.inputContextOverTextPanelContainer)
        
        self.inputPanelContainerNode.addSubnode(self.inputPanelClippingNode)
        self.inputPanelContainerNode.addSubnode(self.inputPanelOverlayNode)
        self.inputPanelClippingNode.addSubnode(self.inputPanelBackgroundNode)
        self.inputPanelClippingNode.addSubnode(self.inputPanelBackgroundSeparatorNode)
        self.inputPanelBackgroundNode.addSubnode(self.inputPanelBottomBackgroundSeparatorNode)

        self.addSubnode(self.messageTransitionNode)
        self.contentContainerNode.addSubnode(self.navigateButtons)
        self.contentContainerNode.addSubnode(self.presentationContextMarker)
        self.contentContainerNode.addSubnode(self.contentDimNode)

        self.navigationBar?.additionalContentNode.addSubnode(self.titleAccessoryPanelContainer)
        
        self.historyNode.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tapGesture(_:))))
        
        self.textInputPanelNode = ChatTextInputPanelNode(context: context, presentationInterfaceState: chatPresentationInterfaceState, presentationContext: ChatPresentationContext(context: context, backgroundNode: backgroundNode), presentController: { [weak self] controller in
            self?.interfaceInteraction?.presentController(controller, nil)
        })
        self.textInputPanelNode?.storedInputLanguage = chatPresentationInterfaceState.interfaceState.inputLanguage
        self.textInputPanelNode?.updateHeight = { [weak self] animated in
            if let strongSelf = self, let _ = strongSelf.inputPanelNode as? ChatTextInputPanelNode, !strongSelf.ignoreUpdateHeight {
                if strongSelf.scheduledLayoutTransitionRequest == nil {
                    let transition: ContainedViewLayoutTransition
                    if !animated {
                        transition = .immediate
                    } else if let overrideUpdateTextInputHeightTransition = strongSelf.overrideUpdateTextInputHeightTransition {
                        transition = overrideUpdateTextInputHeightTransition
                    } else {
                        transition = .animated(duration: 0.1, curve: .easeInOut)
                    }
                    strongSelf.scheduleLayoutTransitionRequest(transition)
                }
            }
        }
        
        self.textInputPanelNode?.sendMessage = { [weak self] in
            if let strongSelf = self {
                if case .scheduledMessages = strongSelf.chatPresentationInterfaceState.subject, strongSelf.chatPresentationInterfaceState.editMessageState == nil {
                    strongSelf.controllerInteraction.scheduleCurrentMessage()
                } else {
                    strongSelf.sendCurrentMessage()
                }
            }
        }
        
        self.textInputPanelNode?.paste = { [weak self] data in
            self?.paste(data)
        }
        self.textInputPanelNode?.displayAttachmentMenu = { [weak self] in
            self?.displayAttachmentMenu()
        }
        self.textInputPanelNode?.updateActivity = { [weak self] in
            self?.updateTypingActivity(true)
        }
        self.textInputPanelNode?.toggleExpandMediaInput = { [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.inputPanelContainerNode.toggleIfEnabled()
        }
        
        self.textInputPanelNode?.switchToTextInputIfNeeded = { [weak self] in
            guard let strongSelf = self, let interfaceInteraction = strongSelf.interfaceInteraction else {
                return
            }
            
            if let inputNode = strongSelf.inputNode as? ChatEntityKeyboardInputNode, !inputNode.canSwitchToTextInputAutomatically {
                return
            }
            
            interfaceInteraction.updateInputModeAndDismissedButtonKeyboardMessageId({ state in
                switch state.inputMode {
                case .media:
                    return (.text, state.keyboardButtonsMessage?.id)
                default:
                    return (state.inputMode, state.keyboardButtonsMessage?.id)
                }
            })
        }
        
        self.inputMediaNodeDataDisposable = (self.inputMediaNodeDataPromise.get()
        |> deliverOnMainQueue).start(next: { [weak self] value in
            guard let strongSelf = self else {
                return
            }
            strongSelf.inputMediaNodeData = value
        })
    }
    
    deinit {
        self.interactiveEmojisDisposable?.dispose()
        self.openStickersDisposable?.dispose()
        self.displayVideoUnmuteTipDisposable?.dispose()
        self.inputMediaNodeDataDisposable?.dispose()
    }
    
    override func didLoad() {
        super.didLoad()
        
        let recognizer = WindowPanRecognizer(target: nil, action: nil)
        recognizer.cancelsTouchesInView = false
        recognizer.delaysTouchesBegan = false
        recognizer.delaysTouchesEnded = false
        recognizer.delegate = self.keyboardGestureRecognizerDelegate
        recognizer.began = { [weak self] point in
            guard let strongSelf = self else {
                return
            }
            strongSelf.panGestureBegan(location: point)
        }
        recognizer.moved = { [weak self] point in
            guard let strongSelf = self else {
                return
            }
            strongSelf.panGestureMoved(location: point)
        }
        recognizer.ended = { [weak self] point, velocity in
            guard let strongSelf = self else {
                return
            }
            strongSelf.panGestureEnded(location: point, velocity: velocity)
        }
        self.panRecognizer = recognizer
        self.view.addGestureRecognizer(recognizer)
        
        self.view.disablesInteractiveTransitionGestureRecognizerNow = { [weak self] in
            guard let strongSelf = self else {
                return false
            }
            if let _ = strongSelf.chatPresentationInterfaceState.inputTextPanelState.mediaRecordingState {
                return true
            }
            var hasChatThemeScreen = false
            strongSelf.controller?.window?.forEachController { c in
                if c is ChatThemeScreen {
                    hasChatThemeScreen = true
                }
            }
            if hasChatThemeScreen {
                return true
            }
            return false
        }
        
        self.displayVideoUnmuteTipDisposable = (combineLatest(queue: Queue.mainQueue(), ApplicationSpecificNotice.getVolumeButtonToUnmute(accountManager: self.context.sharedContext.accountManager), self.historyNode.hasVisiblePlayableItemNodes, self.historyNode.isInteractivelyScrolling)
        |> mapToSignal { notice, hasVisiblePlayableItemNodes, isInteractivelyScrolling -> Signal<Bool, NoError> in
            let display = !notice && hasVisiblePlayableItemNodes && !isInteractivelyScrolling
            if display {
                return .complete()
                |> delay(2.5, queue: Queue.mainQueue())
                |> then(
                    .single(display)
                )
            } else {
                return .single(display)
            }
        }).start(next: { [weak self] display in
            if let strongSelf = self, let interfaceInteraction = strongSelf.interfaceInteraction {
                if display {
                    var nodes: [(CGFloat, ChatMessageItemView, ASDisplayNode)] = []
                    var skip = false
                    strongSelf.historyNode.forEachVisibleItemNode { itemNode in
                        if let itemNode = itemNode as? ChatMessageItemView, let (_, soundEnabled, isVideoMessage, _, badgeNode) = itemNode.playMediaWithSound(), let node = badgeNode {
                            if soundEnabled {
                                skip = true
                            } else if !skip && !isVideoMessage, case let .visible(fraction, _) = itemNode.visibility {
                                nodes.insert((fraction, itemNode, node), at: 0)
                            }
                        }
                    }
                    for (fraction, _, badgeNode) in nodes {
                        if fraction > 0.7 {
                            interfaceInteraction.displayVideoUnmuteTip(badgeNode.view.convert(badgeNode.view.bounds, to: strongSelf.view).origin.offsetBy(dx: 42.0, dy: -1.0))
                            break
                        }
                    }
                } else {
                    interfaceInteraction.displayVideoUnmuteTip(nil)
                }
            }
        })
    }
    
    public func updateText(text: String) {
        self.textInputPanelNode?.text = text
    }
    
    public func sendMessage() {
        self.textInputPanelNode?.sendMessageByCode()
    }
    
    private func updateIsEmpty(_ emptyType: ChatHistoryNodeLoadState.EmptyType?, wasLoading: Bool, animated: Bool) {
        self.emptyType = emptyType
        if let emptyType = emptyType, self.emptyNode == nil {
            let emptyNode = ChatEmptyNode(context: self.context, interaction: self.interfaceInteraction)
            emptyNode.isHidden = self.restrictedNode != nil
            self.emptyNode = emptyNode
            self.historyNodeContainer.supernode?.insertSubnode(emptyNode, aboveSubnode: self.historyNodeContainer)
            if let (size, insets) = self.validEmptyNodeLayout {
                emptyNode.updateLayout(interfaceState: self.chatPresentationInterfaceState, emptyType: emptyType, loadingNode: wasLoading && self.loadingNode.supernode != nil ? self.loadingNode : nil, backgroundNode: self.backgroundNode, size: size, insets: insets, transition: .immediate)
            }
            if animated {
                emptyNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)
            }
        } else if let emptyNode = self.emptyNode {
            self.emptyNode = nil
            if animated {
                emptyNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.2, removeOnCompletion: false, completion: { [weak emptyNode] _ in
                    emptyNode?.removeFromSupernode()
                })
            } else {
                emptyNode.removeFromSupernode()
            }
        }
    }
    
    private var isInFocus: Bool = false
    func inFocusUpdated(isInFocus: Bool) {
        self.isInFocus = isInFocus
        
        self.inputMediaNode?.simulateUpdateLayout(isVisible: isInFocus)
        if let inputNode = self.inputNode as? ChatEntityKeyboardInputNode {
            inputNode.simulateUpdateLayout(isVisible: isInFocus)
        }
    }
    
    func containerLayoutUpdated(_ layout: ContainerViewLayout, navigationBarHeight: CGFloat, transition protoTransition: ContainedViewLayoutTransition, listViewTransaction: (ListViewUpdateSizeAndInsets, CGFloat, Bool, @escaping () -> Void) -> Void, updateExtraNavigationBarBackgroundHeight: (CGFloat, ContainedViewLayoutTransition) -> Void) {
        let transition: ContainedViewLayoutTransition
        if let _ = self.scheduledAnimateInAsOverlayFromNode {
            transition = .immediate
        } else {
            transition = protoTransition
        }
        
        if let statusBar = self.statusBar {
            switch self.chatPresentationInterfaceState.mode {
            case .standard:
                if self.inputPanelContainerNode.expansionFraction > 0.3 {
                    statusBar.updateStatusBarStyle(.White, animated: true)
                } else {
                    statusBar.updateStatusBarStyle(self.chatPresentationInterfaceState.theme.rootController.statusBarStyle.style, animated: true)
                }
                self.controller?.deferScreenEdgeGestures = []
            case .overlay:
                self.controller?.deferScreenEdgeGestures = [.top]
            case .inline:
                statusBar.statusBarStyle = .Ignore
            }
        }

        var previousListBottomInset: CGFloat?
        if !self.historyNode.frame.isEmpty {
            previousListBottomInset = self.historyNode.insets.top
        }

        self.messageTransitionNode.frame = CGRect(origin: CGPoint(), size: layout.size)
        
        self.contentContainerNode.frame = CGRect(origin: CGPoint(), size: layout.size)
        
        let isOverlay: Bool
        switch self.chatPresentationInterfaceState.mode {
        case .overlay:
            isOverlay = true
        default:
            isOverlay = false
        }
        
        let visibleRootModalDismissProgress: CGFloat
        if isOverlay {
            visibleRootModalDismissProgress = 1.0
        } else {
            visibleRootModalDismissProgress = 1.0 - self.inputPanelContainerNode.expansionFraction
        }
        if !isOverlay && self.inputPanelContainerNode.expansionFraction != 0.0 {
            let navigationModalFrame: NavigationModalFrame
            var animateFromFraction: CGFloat?
            if let current = self.navigationModalFrame {
                navigationModalFrame = current
            } else {
                animateFromFraction = 1.0
                navigationModalFrame = NavigationModalFrame()
                self.navigationModalFrame = navigationModalFrame
                self.insertSubnode(navigationModalFrame, aboveSubnode: self.contentContainerNode)
            }
            if transition.isAnimated, let animateFromFraction = animateFromFraction, animateFromFraction != 1.0 - self.inputPanelContainerNode.expansionFraction {
                navigationModalFrame.update(layout: layout, transition: .immediate)
                navigationModalFrame.updateDismissal(transition: .immediate, progress: animateFromFraction, additionalProgress: 0.0, completion: {})
            }
            navigationModalFrame.update(layout: layout, transition: transition)
            navigationModalFrame.updateDismissal(transition: transition, progress: 1.0 - self.inputPanelContainerNode.expansionFraction, additionalProgress: 0.0, completion: {})
            
            self.inputPanelClippingNode.clipsToBounds = true
            transition.updateCornerRadius(node: self.inputPanelClippingNode, cornerRadius: self.inputPanelContainerNode.expansionFraction * 10.0)
        } else {
            if let navigationModalFrame = self.navigationModalFrame {
                self.navigationModalFrame = nil
                navigationModalFrame.updateDismissal(transition: transition, progress: 1.0, additionalProgress: 0.0, completion: { [weak navigationModalFrame] in
                    navigationModalFrame?.removeFromSupernode()
                })
            }
            self.inputPanelClippingNode.clipsToBounds = true
            transition.updateCornerRadius(node: self.inputPanelClippingNode, cornerRadius: 0.0, completion: { [weak self] completed in
                guard let strongSelf = self, completed else {
                    return
                }
                
                let _ = strongSelf
                let _ = completed
            })
        }
        
        transition.updateAlpha(node: self.contentDimNode, alpha: self.inputPanelContainerNode.expansionFraction)
        
        var topInset: CGFloat = 0.0
        if let statusBarHeight = layout.statusBarHeight {
            topInset += statusBarHeight
        }
        
        let maxScale: CGFloat
        let maxOffset: CGFloat
        maxScale = (layout.size.width - 16.0 * 2.0) / layout.size.width
        maxOffset = (topInset - (layout.size.height - layout.size.height * maxScale) / 2.0)
        
        let scale = 1.0 * visibleRootModalDismissProgress + (1.0 - visibleRootModalDismissProgress) * maxScale
        let offset = (1.0 - visibleRootModalDismissProgress) * maxOffset
        transition.updateSublayerTransformScaleAndOffset(node: self.contentContainerNode, scale: scale, offset: CGPoint(x: 0.0, y: offset), beginWithCurrentState: true)
        
        if let navigationModalFrame = self.navigationModalFrame {
            navigationModalFrame.update(layout: layout, transition: transition)
        }
        
        self.scheduledLayoutTransitionRequest = nil
        if case .overlay = self.chatPresentationInterfaceState.mode {
            if self.backgroundEffectNode == nil {
                let backgroundEffectNode = ASDisplayNode()
                backgroundEffectNode.backgroundColor = self.chatPresentationInterfaceState.theme.chatList.backgroundColor.withAlphaComponent(0.8)
                self.insertSubnode(backgroundEffectNode, at: 0)
                self.backgroundEffectNode = backgroundEffectNode
                backgroundEffectNode.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.backgroundEffectTap(_:))))
            }
            if self.scrollContainerNode == nil {
                let scrollContainerNode = ScrollContainerNode()
                scrollContainerNode.view.delaysContentTouches = false
                scrollContainerNode.view.delegate = self
                scrollContainerNode.view.alwaysBounceVertical = true
                if #available(iOSApplicationExtension 11.0, iOS 11.0, *) {
                    scrollContainerNode.view.contentInsetAdjustmentBehavior = .never
                }
                self.insertSubnode(scrollContainerNode, aboveSubnode: self.backgroundEffectNode!)
                self.scrollContainerNode = scrollContainerNode
            }
            if self.containerBackgroundNode == nil {
                let containerBackgroundNode = ASImageNode()
                containerBackgroundNode.displaysAsynchronously = false
                containerBackgroundNode.displayWithoutProcessing = true
                containerBackgroundNode.image = PresentationResourcesRootController.inAppNotificationBackground(self.chatPresentationInterfaceState.theme)
                self.scrollContainerNode?.addSubnode(containerBackgroundNode)
                self.containerBackgroundNode = containerBackgroundNode
            }
            if self.containerNode == nil {
                let containerNode = ASDisplayNode()
                containerNode.clipsToBounds = true
                containerNode.cornerRadius = 15.0
                containerNode.addSubnode(self.backgroundNode)
                containerNode.addSubnode(self.historyNodeContainer)
                self.contentContainerNode.isHidden = true
                if let restrictedNode = self.restrictedNode {
                    containerNode.addSubnode(restrictedNode)
                }
                self.containerNode = containerNode
                self.scrollContainerNode?.addSubnode(containerNode)
                self.navigationBar?.isHidden = true
            }
            if self.overlayNavigationBar == nil {
                let overlayNavigationBar = ChatOverlayNavigationBar(theme: self.chatPresentationInterfaceState.theme, strings: self.chatPresentationInterfaceState.strings, nameDisplayOrder: self.chatPresentationInterfaceState.nameDisplayOrder, tapped: { [weak self] in
                    if let strongSelf = self {
                        strongSelf.dismissAsOverlay()
                        if case let .peer(id) = strongSelf.chatPresentationInterfaceState.chatLocation {
                            strongSelf.interfaceInteraction?.navigateToChat(id)
                        }
                    }
                }, close: { [weak self] in
                    self?.dismissAsOverlay()
                })
                overlayNavigationBar.title = self.overlayTitle
                self.overlayNavigationBar = overlayNavigationBar
                self.containerNode?.addSubnode(overlayNavigationBar)
            }
        } else {
            if let backgroundEffectNode = self.backgroundEffectNode {
                backgroundEffectNode.removeFromSupernode()
                self.backgroundEffectNode = nil
            }
            if let scrollContainerNode = self.scrollContainerNode {
                scrollContainerNode.removeFromSupernode()
                self.scrollContainerNode = nil
            }
            if let containerNode = self.containerNode {
                self.containerNode = nil
                containerNode.removeFromSupernode()
                self.contentContainerNode.insertSubnode(self.backgroundNode, at: 0)
                self.contentContainerNode.insertSubnode(self.historyNodeContainer, aboveSubnode: self.backgroundNode)
                if let restrictedNode = self.restrictedNode {
                    self.contentContainerNode.insertSubnode(restrictedNode, aboveSubnode: self.historyNodeContainer)
                }
                self.navigationBar?.isHidden = false
            }
            if let overlayNavigationBar = self.overlayNavigationBar {
                overlayNavigationBar.removeFromSupernode()
                self.overlayNavigationBar = nil
            }
        }
        
        var dismissedInputByDragging = false
        if let (validLayout, _) = self.validLayout {
            var wasDraggingKeyboard = false
            if validLayout.inputHeight != nil && validLayout.inputHeightIsInteractivellyChanging {
                wasDraggingKeyboard = true
            }
            var wasDraggingInputNode = false
            if let derivedLayoutState = self.derivedLayoutState, let inputNodeHeight = derivedLayoutState.inputNodeHeight, !inputNodeHeight.isZero, let upperInputPositionBound = derivedLayoutState.upperInputPositionBound {
                let normalizedHeight = max(0.0, layout.size.height - upperInputPositionBound)
                if normalizedHeight < inputNodeHeight {
                    wasDraggingInputNode = true
                }
            }
            if wasDraggingKeyboard || wasDraggingInputNode {
                var isDraggingKeyboard = wasDraggingKeyboard
                if layout.inputHeight == 0.0 && validLayout.inputHeightIsInteractivellyChanging && !layout.inputHeightIsInteractivellyChanging {
                    isDraggingKeyboard = false
                }
                var isDraggingInputNode = false
                if self.upperInputPositionBound != nil {
                    isDraggingInputNode = true
                }
                if !isDraggingKeyboard && !isDraggingInputNode {
                    dismissedInputByDragging = true
                }
            }
        }
        
        self.validLayout = (layout, navigationBarHeight)
        
        let cleanInsets = layout.intrinsicInsets
        
        var previousInputHeight: CGFloat = 0.0
        if let (previousLayout, _) = self.containerLayoutAndNavigationBarHeight {
            previousInputHeight = previousLayout.insets(options: [.input]).bottom
        }
        if let inputNode = self.inputNode {
            previousInputHeight = inputNode.bounds.size.height
        }
        var previousInputPanelOrigin = CGPoint(x: 0.0, y: layout.size.height - previousInputHeight)
        if let inputPanelNode = self.inputPanelNode {
            previousInputPanelOrigin.y -= inputPanelNode.bounds.size.height
        }
        if let secondaryInputPanelNode = self.secondaryInputPanelNode {
            previousInputPanelOrigin.y -= secondaryInputPanelNode.bounds.size.height
        }
        self.containerLayoutAndNavigationBarHeight = (layout, navigationBarHeight)
        
        var dismissedTitleAccessoryPanelNode: ChatTitleAccessoryPanelNode?
        var immediatelyLayoutTitleAccessoryPanelNodeAndAnimateAppearance = false
        var titleAccessoryPanelHeight: CGFloat?
        var titleAccessoryPanelBackgroundHeight: CGFloat?
        var extraTransition = transition
        if let titleAccessoryPanelNode = titlePanelForChatPresentationInterfaceState(self.chatPresentationInterfaceState, context: self.context, currentPanel: self.titleAccessoryPanelNode, controllerInteraction: self.controllerInteraction, interfaceInteraction: self.interfaceInteraction) {
            if self.titleAccessoryPanelNode != titleAccessoryPanelNode {
                dismissedTitleAccessoryPanelNode = self.titleAccessoryPanelNode
                self.titleAccessoryPanelNode = titleAccessoryPanelNode
                immediatelyLayoutTitleAccessoryPanelNodeAndAnimateAppearance = true
                self.titleAccessoryPanelContainer.addSubnode(titleAccessoryPanelNode)
                
                titleAccessoryPanelNode.clipsToBounds = true
                if transition.isAnimated {
                    extraTransition = .animated(duration: 0.2, curve: .easeInOut)
                }
            }
            
            let layoutResult = titleAccessoryPanelNode.updateLayout(width: layout.size.width, leftInset: layout.safeInsets.left, rightInset: layout.safeInsets.right, transition: immediatelyLayoutTitleAccessoryPanelNodeAndAnimateAppearance ? .immediate : transition, interfaceState: self.chatPresentationInterfaceState)
            titleAccessoryPanelHeight = layoutResult.insetHeight
            titleAccessoryPanelBackgroundHeight = layoutResult.backgroundHeight
            if immediatelyLayoutTitleAccessoryPanelNodeAndAnimateAppearance {
                titleAccessoryPanelNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)
                titleAccessoryPanelNode.subnodeTransform = CATransform3DMakeTranslation(0.0, -layoutResult.backgroundHeight, 0.0)
                extraTransition.updateSublayerTransformOffset(layer: titleAccessoryPanelNode.layer, offset: CGPoint())
            }
        } else if let titleAccessoryPanelNode = self.titleAccessoryPanelNode {
            dismissedTitleAccessoryPanelNode = titleAccessoryPanelNode
            self.titleAccessoryPanelNode = nil
        }
        
        var dismissedImportStatusPanelNode: ChatImportStatusPanel?
        var importStatusPanelHeight: CGFloat?
        if let importState = self.chatPresentationInterfaceState.importState {
            let importStatusPanelNode: ChatImportStatusPanel
            if let current = self.chatImportStatusPanel {
                importStatusPanelNode = current
            } else {
                importStatusPanelNode = ChatImportStatusPanel()
            }
            
            if self.chatImportStatusPanel != importStatusPanelNode {
                 dismissedImportStatusPanelNode = self.chatImportStatusPanel
                self.chatImportStatusPanel = importStatusPanelNode
                self.contentContainerNode.addSubnode(importStatusPanelNode)
            }
            
            importStatusPanelHeight = importStatusPanelNode.update(context: self.context, progress: CGFloat(importState.progress), presentationData: ChatPresentationData(theme: ChatPresentationThemeData(theme: self.chatPresentationInterfaceState.theme, wallpaper: self.chatPresentationInterfaceState.chatWallpaper), fontSize: self.chatPresentationInterfaceState.fontSize, strings: self.chatPresentationInterfaceState.strings, dateTimeFormat: self.chatPresentationInterfaceState.dateTimeFormat, nameDisplayOrder: self.chatPresentationInterfaceState.nameDisplayOrder, disableAnimations: false, largeEmoji: false, chatBubbleCorners: PresentationChatBubbleCorners(mainRadius: 0.0, auxiliaryRadius: 0.0, mergeBubbleCorners: false)), width: layout.size.width)
        } else if let importStatusPanelNode = self.chatImportStatusPanel {
            dismissedImportStatusPanelNode = importStatusPanelNode
            self.chatImportStatusPanel = nil
        }
        
        var inputPanelNodeBaseHeight: CGFloat = 0.0
        if let inputPanelNode = self.inputPanelNode {
            inputPanelNodeBaseHeight += inputPanelNode.minimalHeight(interfaceState: self.chatPresentationInterfaceState, metrics: layout.metrics)
        }
        if let secondaryInputPanelNode = self.secondaryInputPanelNode {
            inputPanelNodeBaseHeight += secondaryInputPanelNode.minimalHeight(interfaceState: self.chatPresentationInterfaceState, metrics: layout.metrics)
        }
        
        let previewing: Bool
        if case .standard(true) = self.chatPresentationInterfaceState.mode {
            previewing = true
        } else {
            previewing = false
        }
        
        let inputNodeForState = inputNodeForChatPresentationIntefaceState(self.chatPresentationInterfaceState, context: self.context, currentNode: self.inputNode, interfaceInteraction: self.interfaceInteraction, inputMediaNode: self.inputMediaNode, controllerInteraction: self.controllerInteraction, inputPanelNode: self.inputPanelNode, makeMediaInputNode: {
            return self.makeMediaInputNode()
        })
        
        var insets: UIEdgeInsets
        var inputPanelBottomInsetTerm: CGFloat = 0.0
        if let inputNodeForState = inputNodeForState {
            if !self.inputPanelContainerNode.stableIsExpanded && inputNodeForState.adjustLayoutForHiddenInput {
                inputNodeForState.hideInput = false
                inputNodeForState.adjustLayoutForHiddenInput = false
            }
            
            insets = layout.insets(options: [])
            inputPanelBottomInsetTerm = max(insets.bottom, layout.standardInputHeight)
        } else {
            insets = layout.insets(options: [.input])
        }

        if case .overlay = self.chatPresentationInterfaceState.mode {
            insets.top = 44.0
        } else {
            insets.top += navigationBarHeight
        }
        
        var inputPanelSize: CGSize?
        var immediatelyLayoutInputPanelAndAnimateAppearance = false
        var secondaryInputPanelSize: CGSize?
        var immediatelyLayoutSecondaryInputPanelAndAnimateAppearance = false
        var inputPanelNodeHandlesTransition = false
        
        var dismissedInputPanelNode: ChatInputPanelNode?
        var dismissedSecondaryInputPanelNode: ASDisplayNode?
        var dismissedAccessoryPanelNode: AccessoryPanelNode?
        var dismissedInputContextPanelNode: ChatInputContextPanelNode?
        var dismissedOverlayContextPanelNode: ChatInputContextPanelNode?
        
        let inputPanelNodes = inputPanelForChatPresentationIntefaceState(self.chatPresentationInterfaceState, context: self.context, currentPanel: self.inputPanelNode, currentSecondaryPanel: self.secondaryInputPanelNode, textInputPanelNode: self.textInputPanelNode, interfaceInteraction: self.interfaceInteraction)
        
        let inputPanelBottomInset = max(insets.bottom, inputPanelBottomInsetTerm)
        
        if let inputPanelNode = inputPanelNodes.primary, !previewing {
            if inputPanelNode !== self.inputPanelNode {
                if let inputTextPanelNode = self.inputPanelNode as? ChatTextInputPanelNode {
                    if inputTextPanelNode.isFocused {
                        self.context.sharedContext.mainWindow?.simulateKeyboardDismiss(transition: .animated(duration: 0.5, curve: .spring))
                    }
                    let _ = inputTextPanelNode.updateLayout(width: layout.size.width, leftInset: layout.safeInsets.left, rightInset: layout.safeInsets.right, bottomInset: layout.intrinsicInsets.bottom, additionalSideInsets: layout.additionalInsets, maxHeight: layout.size.height - insets.top - inputPanelBottomInset, isSecondary: false, transition: transition, interfaceState: self.chatPresentationInterfaceState, metrics: layout.metrics, isMediaInputExpanded: self.inputPanelContainerNode.expansionFraction == 1.0)
                }
                if let prevInputPanelNode = self.inputPanelNode, inputPanelNode.canHandleTransition(from: prevInputPanelNode) {
                    inputPanelNodeHandlesTransition = true
                    inputPanelNode.removeFromSupernode()
                    inputPanelNode.prevInputPanelNode = prevInputPanelNode
                    inputPanelNode.addSubnode(prevInputPanelNode)
                } else {
                    dismissedInputPanelNode = self.inputPanelNode
                }
                let inputPanelHeight = inputPanelNode.updateLayout(width: layout.size.width, leftInset: layout.safeInsets.left, rightInset: layout.safeInsets.right, bottomInset: layout.intrinsicInsets.bottom, additionalSideInsets: layout.additionalInsets, maxHeight: layout.size.height - insets.top - inputPanelBottomInset, isSecondary: false, transition: inputPanelNode.supernode !== self ? .immediate : transition, interfaceState: self.chatPresentationInterfaceState, metrics: layout.metrics, isMediaInputExpanded: self.inputPanelContainerNode.expansionFraction == 1.0)
                inputPanelSize = CGSize(width: layout.size.width, height: inputPanelHeight)
                self.inputPanelNode = inputPanelNode
                if inputPanelNode.supernode !== self {
                    immediatelyLayoutInputPanelAndAnimateAppearance = true
                    self.inputPanelClippingNode.insertSubnode(inputPanelNode, aboveSubnode: self.inputPanelBackgroundNode)
                    
                    if let viewForOverlayContent = inputPanelNode.viewForOverlayContent {
                        self.inputPanelOverlayNode.view.addSubview(viewForOverlayContent)
                    }
                }
            } else {
                let inputPanelHeight = inputPanelNode.updateLayout(width: layout.size.width, leftInset: layout.safeInsets.left, rightInset: layout.safeInsets.right, bottomInset: layout.intrinsicInsets.bottom, additionalSideInsets: layout.additionalInsets, maxHeight: layout.size.height - insets.top - inputPanelBottomInset - 120.0, isSecondary: false, transition: transition, interfaceState: self.chatPresentationInterfaceState, metrics: layout.metrics, isMediaInputExpanded: self.inputPanelContainerNode.expansionFraction == 1.0)
                inputPanelSize = CGSize(width: layout.size.width, height: inputPanelHeight)
            }
        } else {
            dismissedInputPanelNode = self.inputPanelNode
            self.inputPanelNode = nil
        }
        
        if let secondaryInputPanelNode = inputPanelNodes.secondary, !previewing {
            if secondaryInputPanelNode !== self.secondaryInputPanelNode {
                dismissedSecondaryInputPanelNode = self.secondaryInputPanelNode
                let inputPanelHeight = secondaryInputPanelNode.updateLayout(width: layout.size.width, leftInset: layout.safeInsets.left, rightInset: layout.safeInsets.right, bottomInset: layout.intrinsicInsets.bottom, additionalSideInsets: layout.additionalInsets, maxHeight: layout.size.height - insets.top - inputPanelBottomInset, isSecondary: true, transition: .immediate, interfaceState: self.chatPresentationInterfaceState, metrics: layout.metrics, isMediaInputExpanded: self.inputPanelContainerNode.expansionFraction == 1.0)
                secondaryInputPanelSize = CGSize(width: layout.size.width, height: inputPanelHeight)
                self.secondaryInputPanelNode = secondaryInputPanelNode
                if secondaryInputPanelNode.supernode == nil {
                    immediatelyLayoutSecondaryInputPanelAndAnimateAppearance = true
                    self.inputPanelClippingNode.insertSubnode(secondaryInputPanelNode, aboveSubnode: self.inputPanelBackgroundNode)
                }
            } else {
                let inputPanelHeight = secondaryInputPanelNode.updateLayout(width: layout.size.width, leftInset: layout.safeInsets.left, rightInset: layout.safeInsets.right, bottomInset: layout.intrinsicInsets.bottom, additionalSideInsets: layout.additionalInsets, maxHeight: layout.size.height - insets.top - inputPanelBottomInset, isSecondary: true, transition: transition, interfaceState: self.chatPresentationInterfaceState, metrics: layout.metrics, isMediaInputExpanded: self.inputPanelContainerNode.expansionFraction == 1.0)
                secondaryInputPanelSize = CGSize(width: layout.size.width, height: inputPanelHeight)
            }
        } else {
            dismissedSecondaryInputPanelNode = self.secondaryInputPanelNode
            self.secondaryInputPanelNode = nil
        }
        
        var accessoryPanelSize: CGSize?
        var immediatelyLayoutAccessoryPanelAndAnimateAppearance = false
        if let accessoryPanelNode = accessoryPanelForChatPresentationIntefaceState(self.chatPresentationInterfaceState, context: self.context, currentPanel: self.accessoryPanelNode, chatControllerInteraction: self.controllerInteraction, interfaceInteraction: self.interfaceInteraction) {
            accessoryPanelSize = accessoryPanelNode.measure(CGSize(width: layout.size.width, height: layout.size.height))
            
            accessoryPanelNode.updateState(size: layout.size, inset: layout.safeInsets.left, interfaceState: self.chatPresentationInterfaceState)
            
            if accessoryPanelNode !== self.accessoryPanelNode {
                dismissedAccessoryPanelNode = self.accessoryPanelNode
                self.accessoryPanelNode = accessoryPanelNode
                
                if let inputPanelNode = self.inputPanelNode {
                    self.inputPanelClippingNode.insertSubnode(accessoryPanelNode, belowSubnode: inputPanelNode)
                } else {
                    self.inputPanelClippingNode.insertSubnode(accessoryPanelNode, aboveSubnode: self.inputPanelBackgroundNode)
                }
                accessoryPanelNode.animateIn()
                
                accessoryPanelNode.dismiss = { [weak self, weak accessoryPanelNode] in
                    if let strongSelf = self, let accessoryPanelNode = accessoryPanelNode, strongSelf.accessoryPanelNode === accessoryPanelNode {
                        if let _ = accessoryPanelNode as? ReplyAccessoryPanelNode {
                            strongSelf.requestUpdateChatInterfaceState(.animated(duration: 0.4, curve: .spring), false, { $0.withUpdatedReplyMessageId(nil) })
                        } else if let _ = accessoryPanelNode as? ForwardAccessoryPanelNode {
                            strongSelf.requestUpdateChatInterfaceState(.animated(duration: 0.4, curve: .spring), false, { $0.withUpdatedForwardMessageIds(nil).withUpdatedForwardOptionsState(nil) })
                        } else if let _ = accessoryPanelNode as? EditAccessoryPanelNode {
                            strongSelf.interfaceInteraction?.setupEditMessage(nil, { _ in })
                        } else if let _ = accessoryPanelNode as? WebpagePreviewAccessoryPanelNode {
                            strongSelf.dismissUrlPreview()
                        }
                    }
                }
                
                immediatelyLayoutAccessoryPanelAndAnimateAppearance = true
            }
        } else if let accessoryPanelNode = self.accessoryPanelNode {
            dismissedAccessoryPanelNode = accessoryPanelNode
            self.accessoryPanelNode = nil
        }
        
        var maximumInputNodeHeight = layout.size.height - max(layout.statusBarHeight ?? 0.0, layout.safeInsets.top) - 10.0
        if let inputPanelSize = inputPanelSize {
            if let inputNode = self.inputNode, inputNode.hideInput, !inputNode.adjustLayoutForHiddenInput {
                maximumInputNodeHeight -= inputPanelNodeBaseHeight
            } else {
                maximumInputNodeHeight -= inputPanelSize.height
            }
        }
        if let secondaryInputPanelSize = secondaryInputPanelSize {
            maximumInputNodeHeight -= secondaryInputPanelSize.height
        }
        if let accessoryPanelSize = accessoryPanelSize {
            maximumInputNodeHeight -= accessoryPanelSize.height
        }
        
        var dismissedInputNode: ChatInputNode?
        var dismissedInputNodeInputBackgroundExtension: CGFloat = 0.0
        var dismissedInputNodeExternalTopPanelContainer: UIView?
        var immediatelyLayoutInputNodeAndAnimateAppearance = false
        var inputNodeHeightAndOverflow: (CGFloat, CGFloat)?
        if let inputNode = inputNodeForState {
            if self.inputMediaNode != nil {
                if let inputPanelNode = self.inputPanelNode as? ChatTextInputPanelNode {
                    if inputPanelNode.isFocused {
                        self.context.sharedContext.mainWindow?.simulateKeyboardDismiss(transition: .animated(duration: 0.5, curve: .spring))
                    }
                }
            }
            if let inputMediaNode = inputNode as? ChatMediaInputNode, self.inputMediaNode == nil {
                self.inputMediaNode = inputMediaNode
                inputMediaNode.requestDisableStickerAnimations = { [weak self] disabled in
                    self?.controller?.disableStickerAnimations = disabled
                }
            }
            if self.inputNode != inputNode {
                inputNode.topBackgroundExtensionUpdated = { [weak self] transition in
                    self?.updateInputPanelBackgroundExtension(transition: transition)
                }
                inputNode.hideInputUpdated = { [weak self] transition in
                    guard let strongSelf = self else {
                        return
                    }
                    let applyAutocorrection = strongSelf.inputNode?.hideInput ?? false
                    
                    strongSelf.updateInputPanelBackgroundExpansion(transition: transition)
                    
                    if applyAutocorrection, let textInputPanelNode = strongSelf.textInputPanelNode {
                        if let textInputNode = textInputPanelNode.textInputNode, textInputNode.isFirstResponder() {
                            Keyboard.applyAutocorrection(textView: textInputNode.textView)
                        }
                    }
                }
                
                dismissedInputNode = self.inputNode
                if let inputNode = self.inputNode {
                    dismissedInputNodeInputBackgroundExtension = inputNode.topBackgroundExtension
                }
                dismissedInputNodeExternalTopPanelContainer = self.inputNode?.externalTopPanelContainer
                self.inputNode = inputNode
                inputNode.alpha = 1.0
                inputNode.layer.removeAnimation(forKey: "opacity")
                immediatelyLayoutInputNodeAndAnimateAppearance = true
                
                if self.inputMediaNode != nil {
                    if let inputPanelNode = self.inputPanelNode, inputPanelNode.supernode != nil {
                        self.inputPanelClippingNode.insertSubnode(inputNode, belowSubnode: inputPanelNode)
                    } else {
                        self.inputPanelClippingNode.insertSubnode(inputNode, belowSubnode: self.inputPanelBackgroundNode)
                    }
                } else {
                    self.inputPanelClippingNode.insertSubnode(inputNode, belowSubnode: self.inputPanelBackgroundNode)
                }
                
                if let externalTopPanelContainer = inputNode.externalTopPanelContainer {
                    if let inputPanelNode = self.inputPanelNode, inputPanelNode.supernode != nil {
                        self.inputPanelClippingNode.view.insertSubview(externalTopPanelContainer, belowSubview: inputPanelNode.view)
                    } else {
                        self.inputPanelClippingNode.view.addSubview(externalTopPanelContainer)
                    }
                }
            }
            
            if inputNode.hideInput, inputNode.adjustLayoutForHiddenInput, let inputPanelSize = inputPanelSize {
                maximumInputNodeHeight += inputPanelSize.height
            }
            
            let inputHeight = layout.standardInputHeight + self.inputPanelContainerNode.expansionFraction * (maximumInputNodeHeight - layout.standardInputHeight)
            
            let heightAndOverflow = inputNode.updateLayout(width: layout.size.width, leftInset: layout.safeInsets.left, rightInset: layout.safeInsets.right, bottomInset: cleanInsets.bottom, standardInputHeight: inputHeight, inputHeight: layout.inputHeight ?? 0.0, maximumHeight: maximumInputNodeHeight, inputPanelHeight: inputPanelNodeBaseHeight, transition: immediatelyLayoutInputNodeAndAnimateAppearance ? .immediate : transition, interfaceState: self.chatPresentationInterfaceState, deviceMetrics: layout.deviceMetrics, isVisible: self.isInFocus, isExpanded: self.inputPanelContainerNode.stableIsExpanded)
            
            let boundedHeight = min(heightAndOverflow.0, layout.standardInputHeight)
            
            inputNodeHeightAndOverflow = (
                boundedHeight,
                inputNode.followsDefaultHeight ? max(0.0, inputHeight - boundedHeight) : 0.0
            )
        } else if let inputNode = self.inputNode {
            dismissedInputNode = inputNode
            dismissedInputNodeInputBackgroundExtension = inputNode.topBackgroundExtension
            dismissedInputNodeExternalTopPanelContainer = inputNode.externalTopPanelContainer
            self.inputNode = nil
        }
        
        var effectiveInputNodeHeight: CGFloat?
        if let inputNodeHeightAndOverflow = inputNodeHeightAndOverflow {
            if let upperInputPositionBound = self.upperInputPositionBound {
                effectiveInputNodeHeight = max(0.0, min(layout.size.height - max(0.0, upperInputPositionBound), inputNodeHeightAndOverflow.0))
            } else {
                effectiveInputNodeHeight = inputNodeHeightAndOverflow.0
            }
        }
        
        var bottomOverflowOffset: CGFloat = 0.0
        if let effectiveInputNodeHeight = effectiveInputNodeHeight, let inputNodeHeightAndOverflow = inputNodeHeightAndOverflow {
            insets.bottom = max(effectiveInputNodeHeight, insets.bottom)
            bottomOverflowOffset = inputNodeHeightAndOverflow.1
        }
        
        var wrappingInsets = UIEdgeInsets()
        if case .overlay = self.chatPresentationInterfaceState.mode {
            let containerWidth = horizontalContainerFillingSizeForLayout(layout: layout, sideInset: 8.0 + layout.safeInsets.left)
            wrappingInsets.left = floor((layout.size.width - containerWidth) / 2.0)
            wrappingInsets.right = wrappingInsets.left
            
            wrappingInsets.top = 8.0
            if let statusBarHeight = layout.statusBarHeight, CGFloat(40.0).isLess(than: statusBarHeight) {
                wrappingInsets.top += statusBarHeight
            }
        }
        
        var isSelectionEnabled = true
        if previewing {
            isSelectionEnabled = false
        } else if case .pinnedMessages = self.chatPresentationInterfaceState.subject {
            isSelectionEnabled = false
        }
        self.historyNode.isSelectionGestureEnabled = isSelectionEnabled
                
        if let inputMediaNode = self.inputMediaNode, inputMediaNode != self.inputNode {
            let _ = inputMediaNode.updateLayout(width: layout.size.width, leftInset: layout.safeInsets.left, rightInset: layout.safeInsets.right, bottomInset: cleanInsets.bottom, standardInputHeight: layout.standardInputHeight, inputHeight: layout.inputHeight ?? 0.0, maximumHeight: maximumInputNodeHeight, inputPanelHeight: inputPanelSize?.height ?? 0.0, transition: .immediate, interfaceState: self.chatPresentationInterfaceState, deviceMetrics: layout.deviceMetrics, isVisible: false, isExpanded: self.inputPanelContainerNode.stableIsExpanded)
        }
        
        transition.updateFrame(node: self.titleAccessoryPanelContainer, frame: CGRect(origin: CGPoint(x: 0.0, y: insets.top), size: CGSize(width: layout.size.width, height: 100.0)))
        
        transition.updateFrame(node: self.inputContextPanelContainer, frame: CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: CGSize(width: layout.size.width, height: layout.size.height)))
        transition.updateFrame(node: self.inputContextOverTextPanelContainer, frame: CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: CGSize(width: layout.size.width, height: layout.size.height)))
        
        var titleAccessoryPanelFrame: CGRect?
        if let _ = self.titleAccessoryPanelNode, let panelHeight = titleAccessoryPanelHeight {
            titleAccessoryPanelFrame = CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: CGSize(width: layout.size.width, height: panelHeight))
            insets.top += panelHeight
        }

        updateExtraNavigationBarBackgroundHeight(titleAccessoryPanelBackgroundHeight ?? 0.0, extraTransition)
        
        var importStatusPanelFrame: CGRect?
        if let _ = self.chatImportStatusPanel, let panelHeight = importStatusPanelHeight {
            importStatusPanelFrame = CGRect(origin: CGPoint(x: 0.0, y: insets.top), size: CGSize(width: layout.size.width, height: panelHeight))
            insets.top += panelHeight
        }
        
        let contentBounds = CGRect(x: 0.0, y: 0.0, width: layout.size.width - wrappingInsets.left - wrappingInsets.right, height: layout.size.height - wrappingInsets.top - wrappingInsets.bottom)
        
        if let backgroundEffectNode = self.backgroundEffectNode {
            transition.updateFrame(node: backgroundEffectNode, frame: CGRect(origin: CGPoint(), size: layout.size))
        }
        
        transition.updateFrame(node: self.backgroundNode, frame: contentBounds)
        self.backgroundNode.updateLayout(size: contentBounds.size, transition: transition)

        transition.updateFrame(node: self.historyNodeContainer, frame: contentBounds)
        transition.updateBounds(node: self.historyNode, bounds: CGRect(origin: CGPoint(), size: contentBounds.size))
        transition.updatePosition(node: self.historyNode, position: CGPoint(x: contentBounds.size.width / 2.0, y: contentBounds.size.height / 2.0))
        if let blurredHistoryNode = self.blurredHistoryNode {
            transition.updateFrame(node: blurredHistoryNode, frame: contentBounds)
        }

        
        
        transition.updateFrame(node: self.loadingNode, frame: contentBounds)
        if let loadingPlaceholderNode = self.loadingPlaceholderNode {
            transition.updateFrame(node: loadingPlaceholderNode, frame: contentBounds)
        }
        
        if let restrictedNode = self.restrictedNode {
            transition.updateFrame(node: restrictedNode, frame: contentBounds)
            restrictedNode.update(rect: contentBounds, within: contentBounds.size, transition: transition)
            restrictedNode.updateLayout(backgroundNode: self.backgroundNode, size: contentBounds.size, transition: transition)
        }
        
        let (duration, curve) = listViewAnimationDurationAndCurve(transition: transition)
        
        var immediatelyLayoutInputContextPanelAndAnimateAppearance = false
        if let inputContextPanelNode = inputContextPanelForChatPresentationIntefaceState(self.chatPresentationInterfaceState, context: self.context, currentPanel: self.inputContextPanelNode, controllerInteraction: self.controllerInteraction, interfaceInteraction: self.interfaceInteraction, chatPresentationContext: self.controllerInteraction.presentationContext) {
            if inputContextPanelNode !== self.inputContextPanelNode {
                dismissedInputContextPanelNode = self.inputContextPanelNode
                self.inputContextPanelNode = inputContextPanelNode
                switch inputContextPanelNode.placement {
                case .overPanels:
                    self.inputContextPanelContainer.addSubnode(inputContextPanelNode)
                case .overTextInput:
                    inputContextPanelNode.view.disablesInteractiveKeyboardGestureRecognizer = true
                    self.inputContextOverTextPanelContainer.addSubnode(inputContextPanelNode)
                }
                immediatelyLayoutInputContextPanelAndAnimateAppearance = true
            }
        } else if let inputContextPanelNode = self.inputContextPanelNode {
            dismissedInputContextPanelNode = inputContextPanelNode
            self.inputContextPanelNode = nil
        }
        
        var immediatelyLayoutOverlayContextPanelAndAnimateAppearance = false
        if let overlayContextPanelNode = chatOverlayContextPanelForChatPresentationIntefaceState(self.chatPresentationInterfaceState, context: self.context, currentPanel: self.overlayContextPanelNode, interfaceInteraction: self.interfaceInteraction, chatPresentationContext: self.controllerInteraction.presentationContext) {
            if overlayContextPanelNode !== self.overlayContextPanelNode {
                dismissedOverlayContextPanelNode = self.overlayContextPanelNode
                self.overlayContextPanelNode = overlayContextPanelNode
                
                self.contentContainerNode.addSubnode(overlayContextPanelNode)
                immediatelyLayoutOverlayContextPanelAndAnimateAppearance = true
            }
        } else if let overlayContextPanelNode = self.overlayContextPanelNode {
            dismissedOverlayContextPanelNode = overlayContextPanelNode
            self.overlayContextPanelNode = nil
        }
        
        var inputPanelsHeight: CGFloat = 0.0
        
        var inputPanelFrame: CGRect?
        var secondaryInputPanelFrame: CGRect?
        
        var inputPanelHideOffset: CGFloat = 0.0
        if let inputNode = self.inputNode, inputNode.hideInput {
            if let inputPanelSize = inputPanelSize {
                inputPanelHideOffset += -inputPanelSize.height
            }
            if let accessoryPanelSize = accessoryPanelSize {
                inputPanelHideOffset += -accessoryPanelSize.height
            }
        }
        
        if self.inputPanelNode != nil {
            inputPanelFrame = CGRect(origin: CGPoint(x: 0.0, y: layout.size.height - insets.bottom - bottomOverflowOffset - inputPanelsHeight - inputPanelSize!.height), size: CGSize(width: layout.size.width, height: inputPanelSize!.height))
            inputPanelFrame = inputPanelFrame!.offsetBy(dx: 0.0, dy: inputPanelHideOffset)
            if self.dismissedAsOverlay {
                inputPanelFrame!.origin.y = layout.size.height
            }
            if let inputNode = self.inputNode, inputNode.hideInput, !inputNode.adjustLayoutForHiddenInput {
                inputPanelsHeight += inputPanelNodeBaseHeight
            } else {
                inputPanelsHeight += inputPanelSize!.height
            }
        }
        
        if self.secondaryInputPanelNode != nil {
            secondaryInputPanelFrame = CGRect(origin: CGPoint(x: 0.0, y: layout.size.height - insets.bottom - bottomOverflowOffset - inputPanelsHeight - secondaryInputPanelSize!.height), size: CGSize(width: layout.size.width, height: secondaryInputPanelSize!.height))
            if self.dismissedAsOverlay {
                secondaryInputPanelFrame!.origin.y = layout.size.height
            }
            inputPanelsHeight += secondaryInputPanelSize!.height
        }
        
        var accessoryPanelFrame: CGRect?
        if self.accessoryPanelNode != nil {
            assert(accessoryPanelSize != nil)
            accessoryPanelFrame = CGRect(origin: CGPoint(x: 0.0, y: layout.size.height - bottomOverflowOffset - insets.bottom - inputPanelsHeight - accessoryPanelSize!.height), size: CGSize(width: layout.size.width, height: accessoryPanelSize!.height))
            accessoryPanelFrame = accessoryPanelFrame!.offsetBy(dx: 0.0, dy: inputPanelHideOffset)
            if self.dismissedAsOverlay {
                accessoryPanelFrame!.origin.y = layout.size.height
            }
            if let inputNode = self.inputNode, inputNode.hideInput {
            } else {
                inputPanelsHeight += accessoryPanelSize!.height
            }
        }
        
        if self.dismissedAsOverlay {
            inputPanelsHeight = 0.0
        }
        
        if let inputNode = self.inputNode {
            if inputNode.hideInput && inputNode.adjustLayoutForHiddenInput {
                inputPanelsHeight = 0.0
            }
        }
        
        let inputBackgroundInset: CGFloat
        if cleanInsets.bottom < insets.bottom {
            if case .regular = layout.metrics.widthClass, insets.bottom < 88.0 {
                inputBackgroundInset = insets.bottom
            } else {
                inputBackgroundInset = 0.0
            }
        } else {
            inputBackgroundInset = cleanInsets.bottom
        }
        
        var inputBackgroundFrame = CGRect(origin: CGPoint(x: 0.0, y: layout.size.height - insets.bottom - bottomOverflowOffset - inputPanelsHeight), size: CGSize(width: layout.size.width, height: inputPanelsHeight + inputBackgroundInset))
        if self.dismissedAsOverlay {
            inputBackgroundFrame.origin.y = layout.size.height
        }
        
        let additionalScrollDistance: CGFloat = 0.0
        var scrollToTop = false
        if dismissedInputByDragging {
            if !self.historyNode.trackingOffset.isZero {
                if self.historyNode.beganTrackingAtTopOrigin {
                    scrollToTop = true
                }
            }
        }
        
        var emptyNodeInsets = insets
        emptyNodeInsets.bottom += inputPanelsHeight
        self.validEmptyNodeLayout = (contentBounds.size, emptyNodeInsets)
        if let emptyNode = self.emptyNode, let emptyType = self.emptyType {
            emptyNode.updateLayout(interfaceState: self.chatPresentationInterfaceState, emptyType: emptyType, loadingNode: nil, backgroundNode: self.backgroundNode, size: contentBounds.size, insets: emptyNodeInsets, transition: transition)
            transition.updateFrame(node: emptyNode, frame: contentBounds)
            emptyNode.update(rect: contentBounds, within: contentBounds.size, transition: transition)
        }
        
        var contentBottomInset: CGFloat = inputPanelsHeight + 4.0
        
        if let scrollContainerNode = self.scrollContainerNode {
            transition.updateFrame(node: scrollContainerNode, frame: CGRect(origin: CGPoint(), size: layout.size))
        }
        
        var containerInsets = insets
        if let dismissAsOverlayLayout = self.dismissAsOverlayLayout {
            if let inputNodeHeightAndOverflow = inputNodeHeightAndOverflow {
                containerInsets = dismissAsOverlayLayout.insets(options: [])
                containerInsets.bottom = max(inputNodeHeightAndOverflow.0 + inputNodeHeightAndOverflow.1, insets.bottom)
            } else {
                containerInsets = dismissAsOverlayLayout.insets(options: [.input])
            }
        }
        
        let visibleAreaInset = UIEdgeInsets(top: containerInsets.top, left: 0.0, bottom: containerInsets.bottom + inputPanelsHeight, right: 0.0)
        self.visibleAreaInset = visibleAreaInset
        self.loadingNode.updateLayout(size: contentBounds.size, insets: visibleAreaInset, transition: transition)
        
        if let loadingPlaceholderNode = self.loadingPlaceholderNode {
            loadingPlaceholderNode.updateLayout(size: contentBounds.size, insets: visibleAreaInset, transition: transition)
            loadingPlaceholderNode.update(rect: contentBounds, within: contentBounds.size, transition: transition)
        }
        
        if let containerNode = self.containerNode {
            contentBottomInset += 8.0
            let containerNodeFrame = CGRect(origin: CGPoint(x: wrappingInsets.left, y: wrappingInsets.top), size: CGSize(width: contentBounds.size.width, height: contentBounds.size.height - containerInsets.bottom - inputPanelsHeight - 8.0))
            transition.updateFrame(node: containerNode, frame: containerNodeFrame)
            
            if let containerBackgroundNode = self.containerBackgroundNode {
                transition.updateFrame(node: containerBackgroundNode, frame: CGRect(origin: CGPoint(x: containerNodeFrame.minX - 8.0 * 2.0, y: containerNodeFrame.minY - 8.0 * 2.0), size: CGSize(width: containerNodeFrame.size.width + 8.0 * 4.0, height: containerNodeFrame.size.height + 8.0 * 2.0 + 20.0)))
            }
        }
        
        if let overlayNavigationBar = self.overlayNavigationBar {
            let barFrame = CGRect(origin: CGPoint(), size: CGSize(width: contentBounds.size.width, height: 44.0))
            transition.updateFrame(node: overlayNavigationBar, frame: barFrame)
            overlayNavigationBar.updateLayout(size: barFrame.size, transition: transition)
        }
        
        var listInsets = UIEdgeInsets(top: containerInsets.bottom + contentBottomInset, left: containerInsets.right, bottom: containerInsets.top, right: containerInsets.left)
        let listScrollIndicatorInsets = UIEdgeInsets(top: containerInsets.bottom + inputPanelsHeight, left: containerInsets.right, bottom: containerInsets.top, right: containerInsets.left)
        if case .standard = self.chatPresentationInterfaceState.mode {
            listInsets.left += layout.safeInsets.left
            listInsets.right += layout.safeInsets.right
            
            if case .regular = layout.metrics.widthClass, case .regular = layout.metrics.heightClass {
                listInsets.left += 6.0
                listInsets.right += 6.0
                listInsets.top += 6.0
            }
        }
        
        var displayTopDimNode = false
        let ensureTopInsetForOverlayHighlightedItems: CGFloat? = nil
        var expandTopDimNode = false
        if case let .media(_, expanded, _) = self.chatPresentationInterfaceState.inputMode, expanded != nil {
            displayTopDimNode = true
            expandTopDimNode = true
        }
        
        if displayTopDimNode {
            var topInset = listInsets.bottom + UIScreenPixel
            if let titleAccessoryPanelHeight = titleAccessoryPanelHeight {
                if expandTopDimNode {
                    topInset -= titleAccessoryPanelHeight
                } else {
                    topInset -= UIScreenPixel
                }
            }
            
            let inputPanelOrigin = layout.size.height - insets.bottom - bottomOverflowOffset - inputPanelsHeight
            
            if expandTopDimNode {
                let exandedFrame = CGRect(origin: CGPoint(x: 0.0, y: inputPanelOrigin - layout.size.height), size: CGSize(width: layout.size.width, height: layout.size.height))
                let expandedInputDimNode: ASDisplayNode
                if let current = self.expandedInputDimNode {
                    expandedInputDimNode = current
                    transition.updateFrame(node: expandedInputDimNode, frame: exandedFrame)
                } else {
                    expandedInputDimNode = ASDisplayNode()
                    expandedInputDimNode.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
                    expandedInputDimNode.alpha = 0.0
                    self.expandedInputDimNode = expandedInputDimNode
                    self.contentContainerNode.insertSubnode(expandedInputDimNode, aboveSubnode: self.historyNodeContainer)
                    transition.updateAlpha(node: expandedInputDimNode, alpha: 1.0)
                    expandedInputDimNode.frame = exandedFrame
                    transition.animatePositionAdditive(node: expandedInputDimNode, offset: CGPoint(x: 0.0, y: previousInputPanelOrigin.y - inputPanelOrigin))
                }
            } else {
                if let expandedInputDimNode = self.expandedInputDimNode {
                    self.expandedInputDimNode = nil
                    transition.animatePositionAdditive(node: expandedInputDimNode, offset: CGPoint(x: 0.0, y: previousInputPanelOrigin.y - inputPanelOrigin))
                    transition.updateAlpha(node: expandedInputDimNode, alpha: 0.0, completion: { [weak expandedInputDimNode] _ in
                        expandedInputDimNode?.removeFromSupernode()
                    })
                }
            }
        } else {
            if let expandedInputDimNode = self.expandedInputDimNode {
                self.expandedInputDimNode = nil
                let inputPanelOrigin = layout.size.height - insets.bottom - bottomOverflowOffset - inputPanelsHeight
                let exandedFrame = CGRect(origin: CGPoint(x: 0.0, y: inputPanelOrigin - layout.size.height), size: CGSize(width: layout.size.width, height: layout.size.height))
                transition.updateFrame(node: expandedInputDimNode, frame: exandedFrame)
                transition.updateAlpha(node: expandedInputDimNode, alpha: 0.0, completion: { [weak expandedInputDimNode] _ in
                    expandedInputDimNode?.removeFromSupernode()
                })
            }
        }
        
        var childrenLayout = layout
        childrenLayout.intrinsicInsets = UIEdgeInsets(top: listInsets.bottom, left: listInsets.right, bottom: listInsets.top, right: listInsets.left)
        self.controller?.presentationContext.containerLayoutUpdated(childrenLayout, transition: transition)
        
        listViewTransaction(ListViewUpdateSizeAndInsets(size: contentBounds.size, insets: listInsets, scrollIndicatorInsets: listScrollIndicatorInsets, duration: duration, curve: curve, ensureTopInsetForOverlayHighlightedItems: ensureTopInsetForOverlayHighlightedItems), additionalScrollDistance, scrollToTop, { [weak self] in
            if let strongSelf = self {
                strongSelf.notifyTransitionCompletionListeners(transition: transition)
            }
        })
        
        let navigateButtonsSize = self.navigateButtons.updateLayout(transition: transition)
        var navigateButtonsFrame = CGRect(origin: CGPoint(x: layout.size.width - layout.safeInsets.right - navigateButtonsSize.width - 6.0, y: layout.size.height - containerInsets.bottom - inputPanelsHeight - navigateButtonsSize.height - 6.0), size: navigateButtonsSize)
        if case .overlay = self.chatPresentationInterfaceState.mode {
            navigateButtonsFrame = navigateButtonsFrame.offsetBy(dx: -8.0, dy: -8.0)
        }
        
        var apparentInputPanelFrame = inputPanelFrame
        let apparentSecondaryInputPanelFrame = secondaryInputPanelFrame
        var apparentInputBackgroundFrame = inputBackgroundFrame
        var apparentNavigateButtonsFrame = navigateButtonsFrame
        if case let .media(_, maybeExpanded, _) = self.chatPresentationInterfaceState.inputMode, let expanded = maybeExpanded, case .search = expanded, let inputPanelFrame = inputPanelFrame {
            let verticalOffset = -inputPanelFrame.height - 34.0
            apparentInputPanelFrame = inputPanelFrame.offsetBy(dx: 0.0, dy: verticalOffset)
            apparentInputBackgroundFrame.size.height -= verticalOffset
            apparentInputBackgroundFrame.origin.y += verticalOffset
            apparentNavigateButtonsFrame.origin.y += verticalOffset
        }
        
        if layout.additionalInsets.right > 0.0 {
            apparentNavigateButtonsFrame.origin.y -= 16.0
        }
        
        var isInputExpansionEnabled = false
        if case .media = self.chatPresentationInterfaceState.inputMode {
            isInputExpansionEnabled = true
        }
        
        let previousInputPanelBackgroundFrame = self.inputPanelBackgroundNode.frame
        transition.updateFrame(node: self.inputPanelContainerNode, frame: CGRect(origin: CGPoint(), size: layout.size))
        self.inputPanelContainerNode.update(size: layout.size, scrollableDistance: max(0.0, maximumInputNodeHeight - layout.standardInputHeight), isExpansionEnabled: isInputExpansionEnabled, transition: transition)
        transition.updatePosition(node: self.inputPanelClippingNode, position: CGRect(origin: apparentInputBackgroundFrame.origin, size: layout.size).center, beginWithCurrentState: true)
        transition.updateBounds(node: self.inputPanelClippingNode, bounds: CGRect(origin: CGPoint(x: 0.0, y: apparentInputBackgroundFrame.origin.y), size: layout.size), beginWithCurrentState: true)
        transition.updatePosition(node: self.inputPanelOverlayNode, position: CGRect(origin: apparentInputBackgroundFrame.origin, size: layout.size).center, beginWithCurrentState: true)
        transition.updateBounds(node: self.inputPanelOverlayNode, bounds: CGRect(origin: CGPoint(x: 0.0, y: apparentInputBackgroundFrame.origin.y), size: layout.size), beginWithCurrentState: true)
        transition.updateFrame(node: self.inputPanelBackgroundNode, frame: apparentInputBackgroundFrame, beginWithCurrentState: true)

        if let navigationBarBackgroundContent = self.navigationBarBackgroundContent {
            transition.updateFrame(node: navigationBarBackgroundContent, frame: CGRect(origin: .zero, size: CGSize(width: layout.size.width, height: navigationBarHeight + (titleAccessoryPanelBackgroundHeight ?? 0.0))), beginWithCurrentState: true)
            navigationBarBackgroundContent.update(rect: CGRect(origin: .zero, size: CGSize(width: layout.size.width, height: navigationBarHeight + (titleAccessoryPanelBackgroundHeight ?? 0.0))), within: layout.size, transition: transition)
        }
        
        if let inputPanelBackgroundContent = self.inputPanelBackgroundContent {
            var extensionValue: CGFloat = 0.0
            if let inputNode = self.inputNode {
                extensionValue = inputNode.topBackgroundExtension
            }
            let apparentInputBackgroundFrame = CGRect(origin: apparentInputBackgroundFrame.origin, size: CGSize(width: apparentInputBackgroundFrame.width, height: apparentInputBackgroundFrame.height + extensionValue))
            var transition = transition
            var delay: Double = 0.0
            if apparentInputBackgroundFrame.height > inputPanelBackgroundContent.frame.height {
                transition = .immediate
            } else if case let .animated(_, curve) = transition, case .spring = curve {
                delay = 0.3
            }
            
            transition.updateFrame(node: inputPanelBackgroundContent, frame: CGRect(origin: .zero, size: apparentInputBackgroundFrame.size), beginWithCurrentState: true, delay: delay)
            inputPanelBackgroundContent.update(rect: apparentInputBackgroundFrame, within: layout.size, delay: delay, transition: transition)
        }
        
        transition.updateFrame(node: self.contentDimNode, frame: CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: CGSize(width: layout.size.width, height: apparentInputBackgroundFrame.origin.y)))
        
        let intrinsicInputPanelBackgroundNodeSize = CGSize(width: apparentInputBackgroundFrame.size.width, height: apparentInputBackgroundFrame.size.height)
        self.intrinsicInputPanelBackgroundNodeSize = intrinsicInputPanelBackgroundNodeSize
        var inputPanelBackgroundExtension: CGFloat = 0.0
        if let inputNode = self.inputNode {
            inputPanelBackgroundExtension = inputNode.topBackgroundExtension
        } else {
            inputPanelBackgroundExtension = dismissedInputNodeInputBackgroundExtension
        }
        
        var inputPanelUpdateTransition = transition
        if immediatelyLayoutInputNodeAndAnimateAppearance {
            inputPanelUpdateTransition = .immediate
        }
        
        self.inputPanelBackgroundNode.update(size: CGSize(width: intrinsicInputPanelBackgroundNodeSize.width, height: intrinsicInputPanelBackgroundNodeSize.height + inputPanelBackgroundExtension), transition: inputPanelUpdateTransition, beginWithCurrentState: true)
        self.inputPanelBottomBackgroundSeparatorBaseOffset = intrinsicInputPanelBackgroundNodeSize.height
        inputPanelUpdateTransition.updateFrame(node: self.inputPanelBottomBackgroundSeparatorNode, frame: CGRect(origin: CGPoint(x: 0.0, y: intrinsicInputPanelBackgroundNodeSize.height + inputPanelBackgroundExtension), size: CGSize(width: intrinsicInputPanelBackgroundNodeSize.width, height: UIScreenPixel)), beginWithCurrentState: true)
        
        transition.updateFrame(node: self.inputPanelBackgroundSeparatorNode, frame: CGRect(origin: CGPoint(x: 0.0, y: apparentInputBackgroundFrame.origin.y), size: CGSize(width: apparentInputBackgroundFrame.size.width, height: UIScreenPixel)))
        transition.updateFrame(node: self.navigateButtons, frame: apparentNavigateButtonsFrame)
        self.navigateButtons.update(rect: apparentNavigateButtonsFrame, within: layout.size, transition: transition)
    
        if let titleAccessoryPanelNode = self.titleAccessoryPanelNode, let titleAccessoryPanelFrame = titleAccessoryPanelFrame, !titleAccessoryPanelNode.frame.equalTo(titleAccessoryPanelFrame) {
            titleAccessoryPanelNode.frame = titleAccessoryPanelFrame
            transition.animatePositionAdditive(node: titleAccessoryPanelNode, offset: CGPoint(x: 0.0, y: -titleAccessoryPanelFrame.height))
        }
        
        if let chatImportStatusPanel = self.chatImportStatusPanel, let importStatusPanelFrame = importStatusPanelFrame, !chatImportStatusPanel.frame.equalTo(importStatusPanelFrame) {
            chatImportStatusPanel.frame = importStatusPanelFrame
            
        }
        
        if let secondaryInputPanelNode = self.secondaryInputPanelNode, let apparentSecondaryInputPanelFrame = apparentSecondaryInputPanelFrame, !secondaryInputPanelNode.frame.equalTo(apparentSecondaryInputPanelFrame) {
            if immediatelyLayoutSecondaryInputPanelAndAnimateAppearance {
                secondaryInputPanelNode.frame = apparentSecondaryInputPanelFrame.offsetBy(dx: 0.0, dy: apparentSecondaryInputPanelFrame.height + previousInputPanelBackgroundFrame.maxY - apparentSecondaryInputPanelFrame.maxY)
                secondaryInputPanelNode.alpha = 0.0
            }
            
            transition.updateFrame(node: secondaryInputPanelNode, frame: apparentSecondaryInputPanelFrame)
            transition.updateAlpha(node: secondaryInputPanelNode, alpha: 1.0)
        }
        
        if let accessoryPanelNode = self.accessoryPanelNode, let accessoryPanelFrame = accessoryPanelFrame, !accessoryPanelNode.frame.equalTo(accessoryPanelFrame) {
            if immediatelyLayoutAccessoryPanelAndAnimateAppearance {
                var startAccessoryPanelFrame = accessoryPanelFrame
                startAccessoryPanelFrame.origin.y = previousInputPanelOrigin.y
                accessoryPanelNode.frame = startAccessoryPanelFrame
                accessoryPanelNode.alpha = 0.0
            }
            
            transition.updateFrame(node: accessoryPanelNode, frame: accessoryPanelFrame)
            transition.updateAlpha(node: accessoryPanelNode, alpha: 1.0)
        }
        
        let inputContextPanelsFrame = CGRect(origin: CGPoint(x: 0.0, y: insets.top), size: CGSize(width: layout.size.width, height: max(0.0, layout.size.height - insets.bottom - inputPanelsHeight - insets.top)))
        let inputContextPanelsOverMainPanelFrame = CGRect(origin: CGPoint(x: 0.0, y: insets.top), size: CGSize(width: layout.size.width, height: max(0.0, layout.size.height - insets.bottom - (inputPanelSize == nil ? CGFloat(0.0) : inputPanelSize!.height) - insets.top)))
        
        if let inputContextPanelNode = self.inputContextPanelNode {
            let panelFrame = inputContextPanelNode.placement == .overTextInput ? inputContextPanelsOverMainPanelFrame : inputContextPanelsFrame
            if immediatelyLayoutInputContextPanelAndAnimateAppearance {
                
                inputContextPanelNode.frame = panelFrame
                inputContextPanelNode.updateLayout(size: panelFrame.size, leftInset: layout.safeInsets.left, rightInset: layout.safeInsets.right, bottomInset: 0.0, transition: .immediate, interfaceState: self.chatPresentationInterfaceState)
            }
            
            if !inputContextPanelNode.frame.equalTo(panelFrame) || inputContextPanelNode.theme !== self.chatPresentationInterfaceState.theme {
                transition.updateFrame(node: inputContextPanelNode, frame: panelFrame)
                inputContextPanelNode.updateLayout(size: panelFrame.size, leftInset: layout.safeInsets.left, rightInset: layout.safeInsets.right, bottomInset: 0.0, transition: transition, interfaceState: self.chatPresentationInterfaceState)
            }
        }
        
        if let overlayContextPanelNode = self.overlayContextPanelNode {
            let panelFrame = overlayContextPanelNode.placement == .overTextInput ? inputContextPanelsOverMainPanelFrame : inputContextPanelsFrame
            if immediatelyLayoutOverlayContextPanelAndAnimateAppearance {
                overlayContextPanelNode.frame = panelFrame
                overlayContextPanelNode.updateLayout(size: panelFrame.size, leftInset: layout.safeInsets.left, rightInset: layout.safeInsets.right, bottomInset: 0.0, transition: .immediate, interfaceState: self.chatPresentationInterfaceState)
            } else if !overlayContextPanelNode.frame.equalTo(panelFrame) {
                transition.updateFrame(node: overlayContextPanelNode, frame: panelFrame)
                overlayContextPanelNode.updateLayout(size: panelFrame.size, leftInset: layout.safeInsets.left, rightInset: layout.safeInsets.right, bottomInset: 0.0, transition: transition, interfaceState: self.chatPresentationInterfaceState)
            }
        }
        
        if let inputNode = self.inputNode, let effectiveInputNodeHeight = effectiveInputNodeHeight, let inputNodeHeightAndOverflow = inputNodeHeightAndOverflow {
            let inputNodeHeight = effectiveInputNodeHeight + inputNodeHeightAndOverflow.1
            let inputNodeFrame = CGRect(origin: CGPoint(x: 0.0, y: layout.size.height - inputNodeHeight), size: CGSize(width: layout.size.width, height: inputNodeHeight))
            if immediatelyLayoutInputNodeAndAnimateAppearance {
                var adjustedForPreviousInputHeightFrame = inputNodeFrame
                var heightDifference = inputNodeHeight - previousInputHeight
                var externalTopPanelContainerOffset: CGFloat = 0.0
                if previousInputHeight.isLessThanOrEqualTo(cleanInsets.bottom) {
                    heightDifference = inputNodeHeight - inputPanelBackgroundExtension
                    externalTopPanelContainerOffset = inputPanelBackgroundExtension
                }
                adjustedForPreviousInputHeightFrame.origin.y += heightDifference
                inputNode.frame = adjustedForPreviousInputHeightFrame
                transition.updateFrame(node: inputNode, frame: inputNodeFrame)
                
                if let externalTopPanelContainer = inputNode.externalTopPanelContainer {
                    externalTopPanelContainer.frame = CGRect(origin: adjustedForPreviousInputHeightFrame.offsetBy(dx: 0.0, dy:  externalTopPanelContainerOffset).origin, size: CGSize(width: adjustedForPreviousInputHeightFrame.width, height: 0.0))
                    transition.updateFrame(view: externalTopPanelContainer, frame: CGRect(origin: inputNodeFrame.origin, size: CGSize(width: inputNodeFrame.width, height: 0.0)))
                }
            } else {
                transition.updateFrame(node: inputNode, frame: inputNodeFrame)
                if let externalTopPanelContainer = inputNode.externalTopPanelContainer {
                    transition.updateFrame(view: externalTopPanelContainer, frame: CGRect(origin: inputNodeFrame.origin, size: CGSize(width: inputNodeFrame.width, height: 0.0)))
                }
            }
        }
        
        if let dismissedTitleAccessoryPanelNode = dismissedTitleAccessoryPanelNode {
            var dismissedPanelFrame = dismissedTitleAccessoryPanelNode.frame
            dismissedPanelFrame.origin.y = -dismissedPanelFrame.size.height
            transition.updateFrame(node: dismissedTitleAccessoryPanelNode, frame: dismissedPanelFrame, completion: { [weak dismissedTitleAccessoryPanelNode] _ in
                dismissedTitleAccessoryPanelNode?.removeFromSupernode()
            })
        }
        
        if let dismissedImportStatusPanelNode = dismissedImportStatusPanelNode {
            var dismissedPanelFrame = dismissedImportStatusPanelNode.frame
            dismissedPanelFrame.origin.y = -dismissedPanelFrame.size.height
            transition.updateFrame(node: dismissedImportStatusPanelNode, frame: dismissedPanelFrame, completion: { [weak dismissedImportStatusPanelNode] _ in
                dismissedImportStatusPanelNode?.removeFromSupernode()
            })
        }
        
        if let inputPanelNode = self.inputPanelNode, let apparentInputPanelFrame = apparentInputPanelFrame, !inputPanelNode.frame.equalTo(apparentInputPanelFrame) {
            if immediatelyLayoutInputPanelAndAnimateAppearance {
                inputPanelNode.frame = apparentInputPanelFrame.offsetBy(dx: 0.0, dy: apparentInputPanelFrame.height + previousInputPanelBackgroundFrame.maxY - apparentInputBackgroundFrame.maxY)
                inputPanelNode.alpha = 0.0
            }
            if !transition.isAnimated {
                inputPanelNode.layer.removeAllAnimations()
                if let currentDismissedInputPanelNode = self.currentDismissedInputPanelNode, inputPanelNode is ChatSearchInputPanelNode {
                    currentDismissedInputPanelNode.layer.removeAllAnimations()
                }
            }
            if inputPanelNodeHandlesTransition {
                inputPanelNode.updateAbsoluteRect(apparentInputPanelFrame, within: layout.size, transition: .immediate)
                inputPanelNode.frame = apparentInputPanelFrame
                inputPanelNode.alpha = 1.0
            } else {
                inputPanelNode.updateAbsoluteRect(apparentInputPanelFrame, within: layout.size, transition: transition)
                transition.updateFrame(node: inputPanelNode, frame: apparentInputPanelFrame)
                transition.updateAlpha(node: inputPanelNode, alpha: 1.0)
            }
            
            if let viewForOverlayContent = inputPanelNode.viewForOverlayContent {
                if inputPanelNodeHandlesTransition {
                    viewForOverlayContent.frame = apparentInputPanelFrame
                } else {
                    transition.updateFrame(view: viewForOverlayContent, frame: apparentInputPanelFrame)
                }
            }
        }
        
        if let dismissedInputPanelNode = dismissedInputPanelNode, dismissedInputPanelNode !== self.secondaryInputPanelNode {
            var frameCompleted = false
            var alphaCompleted = false
            self.currentDismissedInputPanelNode = dismissedInputPanelNode
            let completed = { [weak self, weak dismissedInputPanelNode] in
                guard let strongSelf = self, let dismissedInputPanelNode = dismissedInputPanelNode else {
                    return
                }
                if strongSelf.currentDismissedInputPanelNode === dismissedInputPanelNode {
                    strongSelf.currentDismissedInputPanelNode = nil
                }
                if strongSelf.inputPanelNode === dismissedInputPanelNode {
                    return
                }
                if frameCompleted && alphaCompleted {
                    dismissedInputPanelNode.removeFromSupernode()
                }
            }
            let transitionTargetY = layout.size.height - insets.bottom
            transition.updateFrame(node: dismissedInputPanelNode, frame: CGRect(origin: CGPoint(x: 0.0, y: transitionTargetY), size: dismissedInputPanelNode.frame.size), completion: { _ in
                frameCompleted = true
                completed()
            })
            
            transition.updateAlpha(node: dismissedInputPanelNode, alpha: 0.0, completion: { _ in
                alphaCompleted = true
                completed()
            })
            
            dismissedInputPanelNode.viewForOverlayContent?.removeFromSuperview()
        }
        
        if let dismissedSecondaryInputPanelNode = dismissedSecondaryInputPanelNode, dismissedSecondaryInputPanelNode !== self.inputPanelNode {
            var frameCompleted = false
            var alphaCompleted = false
            let completed = { [weak self, weak dismissedSecondaryInputPanelNode] in
                if let strongSelf = self, let dismissedSecondaryInputPanelNode = dismissedSecondaryInputPanelNode, strongSelf.secondaryInputPanelNode === dismissedSecondaryInputPanelNode {
                    return
                }
                if frameCompleted && alphaCompleted {
                    dismissedSecondaryInputPanelNode?.removeFromSupernode()
                }
            }
            let transitionTargetY = layout.size.height - insets.bottom
            transition.updateFrame(node: dismissedSecondaryInputPanelNode, frame: CGRect(origin: CGPoint(x: 0.0, y: transitionTargetY), size: dismissedSecondaryInputPanelNode.frame.size), completion: { _ in
                frameCompleted = true
                completed()
            })
            
            transition.updateAlpha(node: dismissedSecondaryInputPanelNode, alpha: 0.0, completion: { _ in
                alphaCompleted = true
                completed()
            })
        }
        
        if let dismissedAccessoryPanelNode = dismissedAccessoryPanelNode {
            var frameCompleted = false
            var alphaCompleted = false
            let completed = { [weak dismissedAccessoryPanelNode] in
                if frameCompleted && alphaCompleted {
                    dismissedAccessoryPanelNode?.removeFromSupernode()
                }
            }
            var transitionTargetY = layout.size.height - insets.bottom
            if let inputPanelFrame = inputPanelFrame {
                transitionTargetY = inputPanelFrame.minY
            }

            dismissedAccessoryPanelNode.animateOut()
            dismissedAccessoryPanelNode.originalFrameBeforeDismissed = dismissedAccessoryPanelNode.frame

            transition.updateFrame(node: dismissedAccessoryPanelNode, frame: CGRect(origin: CGPoint(x: 0.0, y: transitionTargetY), size: dismissedAccessoryPanelNode.frame.size), completion: { _ in
                frameCompleted = true
                completed()
            })
            
            transition.updateAlpha(node: dismissedAccessoryPanelNode, alpha: 0.0, completion: { _ in
                alphaCompleted = true
                completed()
            })
        }
        
        if let dismissedInputContextPanelNode = dismissedInputContextPanelNode {
            var frameCompleted = false
            var animationCompleted = false
            let completed = { [weak dismissedInputContextPanelNode] in
                if let dismissedInputContextPanelNode = dismissedInputContextPanelNode, frameCompleted, animationCompleted {
                    dismissedInputContextPanelNode.removeFromSupernode()
                }
            }
            let panelFrame = dismissedInputContextPanelNode.placement == .overTextInput ? inputContextPanelsOverMainPanelFrame : inputContextPanelsFrame
            if !dismissedInputContextPanelNode.frame.equalTo(panelFrame) {
                dismissedInputContextPanelNode.updateLayout(size: panelFrame.size, leftInset: layout.safeInsets.left, rightInset: layout.safeInsets.right, bottomInset: 0.0, transition: transition, interfaceState: self.chatPresentationInterfaceState)
                transition.updateFrame(node: dismissedInputContextPanelNode, frame: panelFrame, completion: { _ in
                    frameCompleted = true
                    completed()
                })
            } else {
                frameCompleted = true
            }
            
            dismissedInputContextPanelNode.animateOut(completion: {
                animationCompleted = true
                completed()
            })
        }
        
        if let dismissedOverlayContextPanelNode = dismissedOverlayContextPanelNode {
            var frameCompleted = false
            var animationCompleted = false
            let completed = { [weak dismissedOverlayContextPanelNode] in
                if let dismissedOverlayContextPanelNode = dismissedOverlayContextPanelNode, frameCompleted, animationCompleted {
                    dismissedOverlayContextPanelNode.removeFromSupernode()
                }
            }
            let panelFrame = inputContextPanelsFrame
            if false && !dismissedOverlayContextPanelNode.frame.equalTo(panelFrame) {
                transition.updateFrame(node: dismissedOverlayContextPanelNode, frame: panelFrame, completion: { _ in
                    frameCompleted = true
                    completed()
                })
            } else {
                frameCompleted = true
            }
            
            dismissedOverlayContextPanelNode.animateOut(completion: {
                animationCompleted = true
                completed()
            })
        }
        
        if let disappearingNode = self.disappearingNode {
            let targetY: CGFloat
            if cleanInsets.bottom.isLess(than: insets.bottom) {
                targetY = layout.size.height - insets.bottom
            } else {
                targetY = layout.size.height
            }
            transition.updateFrame(node: disappearingNode, frame: CGRect(origin: CGPoint(x: 0.0, y: targetY), size: CGSize(width: layout.size.width, height: max(insets.bottom, disappearingNode.bounds.size.height))))
        }
        if let dismissedInputNode = dismissedInputNode {
            self.disappearingNode = dismissedInputNode
            let targetY: CGFloat
            if cleanInsets.bottom.isLess(than: insets.bottom) {
                targetY = layout.size.height - insets.bottom
            } else {
                targetY = layout.size.height
            }
            
            if let dismissedInputNodeExternalTopPanelContainer = dismissedInputNodeExternalTopPanelContainer {
                transition.updateFrame(view: dismissedInputNodeExternalTopPanelContainer, frame: CGRect(origin: CGPoint(x: 0.0, y: targetY), size: CGSize(width: layout.size.width, height: 0.0)), force: true, completion: { [weak self, weak dismissedInputNodeExternalTopPanelContainer] completed in
                    if let strongSelf = self, let dismissedInputNodeExternalTopPanelContainer = dismissedInputNodeExternalTopPanelContainer {
                        if strongSelf.inputNode?.externalTopPanelContainer !== dismissedInputNodeExternalTopPanelContainer {
                            dismissedInputNodeExternalTopPanelContainer.alpha = 0.0
                            dismissedInputNodeExternalTopPanelContainer.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.2, completion: { [weak dismissedInputNodeExternalTopPanelContainer] completed in
                                if completed, let strongSelf = self, let dismissedInputNodeExternalTopPanelContainer = dismissedInputNodeExternalTopPanelContainer {
                                    if strongSelf.inputNode?.externalTopPanelContainer !== dismissedInputNodeExternalTopPanelContainer {
                                        dismissedInputNodeExternalTopPanelContainer.removeFromSuperview()
                                    }
                                }
                            })
                        }
                    }
                })
            }
            
            transition.updateFrame(node: dismissedInputNode, frame: CGRect(origin: CGPoint(x: 0.0, y: targetY), size: CGSize(width: layout.size.width, height: max(insets.bottom, dismissedInputNode.bounds.size.height))), force: true, completion: { [weak self, weak dismissedInputNode] completed in
                if let dismissedInputNode = dismissedInputNode {
                    if let strongSelf = self {
                        if strongSelf.disappearingNode === dismissedInputNode {
                            strongSelf.disappearingNode = nil
                        }
                        if strongSelf.inputNode !== dismissedInputNode {
                            dismissedInputNode.alpha = 0.0
                            dismissedInputNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.2, completion: { [weak dismissedInputNode] completed in
                                if completed, let strongSelf = self, let dismissedInputNode = dismissedInputNode {
                                    if strongSelf.inputNode !== dismissedInputNode {
                                        dismissedInputNode.removeFromSupernode()
                                    }
                                }
                            })
                        }
                    } else {
                        dismissedInputNode.removeFromSupernode()
                    }
                }
            })
        }
        
        if let dismissAsOverlayCompletion = self.dismissAsOverlayCompletion {
            self.dismissAsOverlayCompletion = nil
            transition.updateBounds(node: self.navigateButtons, bounds: self.navigateButtons.bounds, force: true, completion: { _ in
                dismissAsOverlayCompletion()
            })
        }
        
        if let scheduledAnimateInAsOverlayFromNode = self.scheduledAnimateInAsOverlayFromNode {
            self.scheduledAnimateInAsOverlayFromNode = nil
            self.bounds = CGRect(origin: CGPoint(), size: self.bounds.size)
            let animatedTransition: ContainedViewLayoutTransition
            if case .animated = protoTransition {
                animatedTransition = protoTransition
            } else {
                animatedTransition = .animated(duration: 0.4, curve: .spring)
            }
            self.performAnimateInAsOverlay(from: scheduledAnimateInAsOverlayFromNode, transition: animatedTransition)
        }
        
        self.updatePlainInputSeparator(transition: transition)

        let listBottomInset = self.historyNode.insets.top
        if let previousListBottomInset = previousListBottomInset, listBottomInset != previousListBottomInset {
            if abs(listBottomInset - previousListBottomInset) > 80.0 {
                if (self.context.sharedContext.currentPresentationData.with({ $0 })).reduceMotion {
                    return
                }
                self.backgroundNode.animateEvent(transition: transition, extendAnimation: false)
            }
            
        }

        self.derivedLayoutState = ChatControllerNodeDerivedLayoutState(inputContextPanelsFrame: inputContextPanelsFrame, inputContextPanelsOverMainPanelFrame: inputContextPanelsOverMainPanelFrame, inputNodeHeight: inputNodeHeightAndOverflow?.0, inputNodeAdditionalHeight: inputNodeHeightAndOverflow?.1, upperInputPositionBound: inputNodeHeightAndOverflow?.0 != nil ? self.upperInputPositionBound : nil)
        
        
    }
    
    private func updateInputPanelBackgroundExtension(transition: ContainedViewLayoutTransition) {
        guard let intrinsicInputPanelBackgroundNodeSize = self.intrinsicInputPanelBackgroundNodeSize else {
            return
        }
        
        var extensionValue: CGFloat = 0.0
        if let inputNode = self.inputNode {
            extensionValue = inputNode.topBackgroundExtension
        }
        
        self.inputPanelBackgroundNode.update(size: CGSize(width: intrinsicInputPanelBackgroundNodeSize.width, height: intrinsicInputPanelBackgroundNodeSize.height + extensionValue), transition: transition)
        transition.updateFrame(node: self.inputPanelBottomBackgroundSeparatorNode, frame: CGRect(origin: CGPoint(x: 0.0, y: self.inputPanelBottomBackgroundSeparatorBaseOffset + extensionValue), size: CGSize(width: self.inputPanelBottomBackgroundSeparatorNode.bounds.width, height: UIScreenPixel)), beginWithCurrentState: true)
        
        if let inputPanelBackgroundContent = self.inputPanelBackgroundContent, let (layout, _) = self.validLayout {
            var inputPanelBackgroundFrame = self.inputPanelBackgroundNode.frame
            inputPanelBackgroundFrame.size.height = intrinsicInputPanelBackgroundNodeSize.height + extensionValue
            
            transition.updateFrame(node: inputPanelBackgroundContent, frame: CGRect(origin: .zero, size: inputPanelBackgroundFrame.size))
            inputPanelBackgroundContent.update(rect: inputPanelBackgroundFrame, within: layout.size, transition: transition)
        }
    }
    
    private var storedHideInputExpanded: Bool?
    
    private func updateInputPanelBackgroundExpansion(transition: ContainedViewLayoutTransition) {
        if let inputNode = self.inputNode {
            if inputNode.hideInput && inputNode.adjustLayoutForHiddenInput {
                self.storedHideInputExpanded = self.inputPanelContainerNode.expansionFraction == 1.0
                self.inputPanelContainerNode.expand()
            } else {
                if let storedHideInputExpanded = self.storedHideInputExpanded {
                    self.storedHideInputExpanded = nil
                    if !storedHideInputExpanded {
                        self.inputPanelContainerNode.collapse()
                    }
                }
            }
        }
        
        self.requestLayout(transition)
    }
    
    private func notifyTransitionCompletionListeners(transition: ContainedViewLayoutTransition) {
        if !self.onLayoutCompletions.isEmpty {
            let onLayoutCompletions = self.onLayoutCompletions
            self.onLayoutCompletions = []
            for completion in onLayoutCompletions {
                completion(transition)
            }
        }
    }
    
    private func chatPresentationInterfaceStateRequiresInputFocus(_ state: ChatPresentationInterfaceState) -> Bool {
        switch state.inputMode {
        case .text:
            if state.interfaceState.selectionState != nil {
                return false
            } else {
                return true
            }
        case .media:
            return true
        default:
            return false
        }
    }
    
    private final class EmptyInputView: UIView, UIInputViewAudioFeedback {
        var enableInputClicksWhenVisible: Bool {
            return true
        }
    }
    
    private let emptyInputView = EmptyInputView()
    private func chatPresentationInterfaceStateInputView(_ state: ChatPresentationInterfaceState) -> UIView? {
        switch state.inputMode {
        case .text:
            return nil
        case .media:
            return self.emptyInputView
        default:
            return nil
        }
    }
    
    func updateChatPresentationInterfaceState(_ chatPresentationInterfaceState: ChatPresentationInterfaceState, transition: ContainedViewLayoutTransition, interactive: Bool, completion: @escaping (ContainedViewLayoutTransition) -> Void) {
        self.selectedMessages = chatPresentationInterfaceState.interfaceState.selectionState?.selectedIds
        
        if let textInputPanelNode = self.textInputPanelNode {
            self.chatPresentationInterfaceState = self.chatPresentationInterfaceState.updatedInterfaceState { $0.withUpdatedEffectiveInputState(textInputPanelNode.inputTextState) }
        }
        
        let presentationReadyUpdated = self.chatPresentationInterfaceState.presentationReady != chatPresentationInterfaceState.presentationReady
        
        if self.chatPresentationInterfaceState != chatPresentationInterfaceState && chatPresentationInterfaceState.presentationReady {
            self.onLayoutCompletions.append(completion)
            
            let themeUpdated = presentationReadyUpdated || (self.chatPresentationInterfaceState.theme !== chatPresentationInterfaceState.theme)
            
            self.backgroundNode.update(wallpaper: chatPresentationInterfaceState.chatWallpaper)
            
            self.historyNode.verticalScrollIndicatorColor = UIColor(white: 0.5, alpha: 0.8)
            self.loadingPlaceholderNode?.updatePresentationInterfaceState(chatPresentationInterfaceState)
            
            var updatedInputFocus = self.chatPresentationInterfaceStateRequiresInputFocus(self.chatPresentationInterfaceState) != self.chatPresentationInterfaceStateRequiresInputFocus(chatPresentationInterfaceState)
            if self.chatPresentationInterfaceStateInputView(self.chatPresentationInterfaceState) !== self.chatPresentationInterfaceStateInputView(chatPresentationInterfaceState) {
                updatedInputFocus = true
            }
            
            let updateInputTextState = self.chatPresentationInterfaceState.interfaceState.effectiveInputState != chatPresentationInterfaceState.interfaceState.effectiveInputState
            self.chatPresentationInterfaceState = chatPresentationInterfaceState
            
            self.navigateButtons.update(theme: chatPresentationInterfaceState.theme, dateTimeFormat: chatPresentationInterfaceState.dateTimeFormat, backgroundNode: self.backgroundNode)
            
            if themeUpdated {
                if case let .color(color) = self.chatPresentationInterfaceState.chatWallpaper, UIColor(rgb: color).isEqual(self.chatPresentationInterfaceState.theme.chat.inputPanel.panelBackgroundColorNoWallpaper) {
                    self.inputPanelBackgroundNode.updateColor(color: self.chatPresentationInterfaceState.theme.chat.inputPanel.panelBackgroundColorNoWallpaper, transition: .immediate)
                    self.usePlainInputSeparator = true
                } else {
                    self.inputPanelBackgroundNode.updateColor(color: self.chatPresentationInterfaceState.theme.chat.inputPanel.panelBackgroundColor, transition: .immediate)
                    self.usePlainInputSeparator = false
                    self.plainInputSeparatorAlpha = nil
                }
                                
                self.updatePlainInputSeparator(transition: .immediate)
                self.inputPanelBackgroundSeparatorNode.backgroundColor = self.chatPresentationInterfaceState.theme.chat.inputPanel.panelSeparatorColor
                self.inputPanelBottomBackgroundSeparatorNode.backgroundColor = self.chatPresentationInterfaceState.theme.chat.inputMediaPanel.panelSeparatorColor

                self.backgroundNode.updateBubbleTheme(bubbleTheme: chatPresentationInterfaceState.theme, bubbleCorners: chatPresentationInterfaceState.bubbleCorners)
                
                if self.backgroundNode.hasExtraBubbleBackground() {
                    if self.navigationBarBackgroundContent == nil {
                        if let navigationBarBackgroundContent = self.backgroundNode.makeBubbleBackground(for: .free),
                           let inputPanelBackgroundContent = self.backgroundNode.makeBubbleBackground(for: .free) {
                            self.navigationBarBackgroundContent = navigationBarBackgroundContent
                            self.inputPanelBackgroundContent = inputPanelBackgroundContent
                            
                            navigationBarBackgroundContent.allowsGroupOpacity = true
                            navigationBarBackgroundContent.implicitContentUpdate = false
                            navigationBarBackgroundContent.alpha = 0.3
                            self.navigationBar?.insertSubnode(navigationBarBackgroundContent, at: 1)
                            
                            inputPanelBackgroundContent.allowsGroupOpacity = true
                            inputPanelBackgroundContent.implicitContentUpdate = false
                            inputPanelBackgroundContent.alpha = 0.3
                            self.inputPanelBackgroundNode.addSubnode(inputPanelBackgroundContent)
                        }
                    }
                } else {
                    self.navigationBarBackgroundContent?.removeFromSupernode()
                    self.navigationBarBackgroundContent = nil
                    self.inputPanelBackgroundContent?.removeFromSupernode()
                    self.inputPanelBackgroundContent = nil
                }
            }
            
            let keepSendButtonEnabled = chatPresentationInterfaceState.interfaceState.forwardMessageIds != nil || chatPresentationInterfaceState.interfaceState.editMessage != nil
            var extendedSearchLayout = false
            loop: for (_, result) in chatPresentationInterfaceState.inputQueryResults {
                if case let .contextRequestResult(peer, _) = result, peer != nil {
                    extendedSearchLayout = true
                    break loop
                }
            }
            
            if let textInputPanelNode = self.textInputPanelNode, updateInputTextState {
                let previous = self.overrideUpdateTextInputHeightTransition
                self.overrideUpdateTextInputHeightTransition = transition
                textInputPanelNode.updateInputTextState(chatPresentationInterfaceState.interfaceState.effectiveInputState, keepSendButtonEnabled: keepSendButtonEnabled, extendedSearchLayout: extendedSearchLayout, accessoryItems: chatPresentationInterfaceState.inputTextPanelState.accessoryItems, animated: transition.isAnimated)
                self.overrideUpdateTextInputHeightTransition = previous
            } else {
                self.textInputPanelNode?.updateKeepSendButtonEnabled(keepSendButtonEnabled: keepSendButtonEnabled, extendedSearchLayout: extendedSearchLayout, animated: transition.isAnimated)
            }
            
            var restrictionText: String?
            if let peer = chatPresentationInterfaceState.renderedPeer?.peer, let restrictionTextValue = peer.restrictionText(platform: "ios", contentSettings: self.context.currentContentSettings.with { $0 }), !restrictionTextValue.isEmpty {
                restrictionText = restrictionTextValue
            } else if chatPresentationInterfaceState.isNotAccessible {
                if case .replyThread = self.chatLocation {
                    restrictionText = chatPresentationInterfaceState.strings.CommentsGroup_ErrorAccessDenied
                } else if let peer = chatPresentationInterfaceState.renderedPeer?.peer as? TelegramChannel, case .broadcast = peer.info {
                    restrictionText = chatPresentationInterfaceState.strings.Channel_ErrorAccessDenied
                } else {
                    restrictionText = chatPresentationInterfaceState.strings.Group_ErrorAccessDenied
                }
            }
            
            if let restrictionText = restrictionText {
                if self.restrictedNode == nil {
                    let restrictedNode = ChatRecentActionsEmptyNode(theme: chatPresentationInterfaceState.theme, chatWallpaper: chatPresentationInterfaceState.chatWallpaper, chatBubbleCorners: chatPresentationInterfaceState.bubbleCorners)
                    self.historyNodeContainer.supernode?.insertSubnode(restrictedNode, aboveSubnode: self.historyNodeContainer)
                    self.restrictedNode = restrictedNode
                }
                self.restrictedNode?.setup(title: "", text: processedPeerRestrictionText(restrictionText))
                self.historyNodeContainer.isHidden = true
                self.navigateButtons.isHidden = true
                self.loadingNode.isHidden = true
                self.emptyNode?.isHidden = true
            } else if let restrictedNode = self.restrictedNode {
                self.restrictedNode = nil
                restrictedNode.removeFromSupernode()
                self.historyNodeContainer.isHidden = false
                self.navigateButtons.isHidden = false
                self.loadingNode.isHidden = false
                self.emptyNode?.isHidden = false
            }
            
            var showNavigateButtons = true
            if let _ = chatPresentationInterfaceState.inputTextPanelState.mediaRecordingState {
                showNavigateButtons = false
            }
            transition.updateAlpha(node: self.navigateButtons, alpha: showNavigateButtons ? 1.0 : 0.0)
            
            if let openStickersDisposable = self.openStickersDisposable {
                if case .media = chatPresentationInterfaceState.inputMode {
                } else {
                    openStickersDisposable.dispose()
                    self.openStickersDisposable = nil
                }
            }
            
            let layoutTransition: ContainedViewLayoutTransition = transition
            
            let transitionIsAnimated: Bool
            if case .immediate = transition {
                transitionIsAnimated = false
            } else {
                transitionIsAnimated = true
            }
            
            if let _ = self.chatPresentationInterfaceState.search, let interfaceInteraction = self.interfaceInteraction {
                var activate = false
                if self.searchNavigationNode == nil {
                    activate = true
                    self.searchNavigationNode = ChatSearchNavigationContentNode(theme: self.chatPresentationInterfaceState.theme, strings: self.chatPresentationInterfaceState.strings, chatLocation: self.chatPresentationInterfaceState.chatLocation, interaction: interfaceInteraction)
                }
                self.navigationBar?.setContentNode(self.searchNavigationNode, animated: transitionIsAnimated)
                self.searchNavigationNode?.update(presentationInterfaceState: self.chatPresentationInterfaceState)
                if activate {
                    self.searchNavigationNode?.activate()
                }
            } else if let _ = self.searchNavigationNode {
                self.searchNavigationNode = nil
                self.navigationBar?.setContentNode(nil, animated: transitionIsAnimated)
            }
            
            var waitForKeyboardLayout = false
            if let textView = self.textInputPanelNode?.textInputNode?.textView {
                let updatedInputView = self.chatPresentationInterfaceStateInputView(chatPresentationInterfaceState)
                if textView.inputView !== updatedInputView {
                    textView.inputView = updatedInputView
                    if textView.isFirstResponder {
                        if self.chatPresentationInterfaceStateRequiresInputFocus(chatPresentationInterfaceState) {
                            waitForKeyboardLayout = true
                        }
                        textView.reloadInputViews()
                    }
                }
            }
            
            if updatedInputFocus {
                if !self.ignoreUpdateHeight && !waitForKeyboardLayout {
                    self.scheduleLayoutTransitionRequest(layoutTransition)
                }
                
                if self.chatPresentationInterfaceStateRequiresInputFocus(chatPresentationInterfaceState) {
                    self.ensureInputViewFocused()
                } else {
                    if let inputPanelNode = self.inputPanelNode as? ChatTextInputPanelNode {
                        if inputPanelNode.isFocused {
                            self.context.sharedContext.mainWindow?.simulateKeyboardDismiss(transition: .animated(duration: 0.5, curve: .spring))
                        }
                    }
                }
            } else {
                if !self.ignoreUpdateHeight {
                    if interactive {
                        if let scheduledLayoutTransitionRequest = self.scheduledLayoutTransitionRequest {
                            switch scheduledLayoutTransitionRequest.1 {
                                case .immediate:
                                    self.scheduleLayoutTransitionRequest(layoutTransition)
                                default:
                                    break
                            }
                        } else {
                            self.scheduleLayoutTransitionRequest(layoutTransition)
                        }
                    } else {
                        if let scheduledLayoutTransitionRequest = self.scheduledLayoutTransitionRequest {
                            switch scheduledLayoutTransitionRequest.1 {
                                case .immediate:
                                    self.requestLayout(layoutTransition)
                                case .animated:
                                    self.scheduleLayoutTransitionRequest(scheduledLayoutTransitionRequest.1)
                            }
                        } else {
                            self.requestLayout(layoutTransition)
                        }
                    }
                }
            }
        } else {
            completion(.immediate)
        }
    }
    
    func updateAutomaticMediaDownloadSettings(_ settings: MediaAutoDownloadSettings) {
        self.historyNode.forEachItemNode { itemNode in
            if let itemNode = itemNode as? ChatMessageItemView {
                itemNode.updateAutomaticMediaDownloadSettings()
            }
        }
        self.historyNode.prefetchManager.updateAutoDownloadSettings(settings)
    }
    
    func updateStickerSettings(_ settings: ChatInterfaceStickerSettings, forceStopAnimations: Bool) {
        self.historyNode.forEachItemNode { itemNode in
            if let itemNode = itemNode as? ChatMessageItemView {
                itemNode.updateStickerSettings(forceStopAnimations: forceStopAnimations)
            }
        }
    }
    
    var isInputViewFocused: Bool {
        if let inputPanelNode = self.inputPanelNode as? ChatTextInputPanelNode {
            return inputPanelNode.isFocused
        } else {
            return false
        }
    }
    
    func ensureInputViewFocused() {
        if let inputPanelNode = self.inputPanelNode as? ChatTextInputPanelNode {
            inputPanelNode.ensureFocused()
        }
    }
    
    @objc func tapGesture(_ recognizer: UITapGestureRecognizer) {
        if recognizer.state == .ended {
            self.dismissInput()
        }
    }
    
    func dismissInput() {
        if let _ = self.chatPresentationInterfaceState.inputTextPanelState.mediaRecordingState {
            return
        }
        
        switch self.chatPresentationInterfaceState.inputMode {
        case .none:
            break
        case .inputButtons:
            if let peer = self.chatPresentationInterfaceState.renderedPeer?.peer as? TelegramUser, peer.botInfo != nil {
            } else {
                self.interfaceInteraction?.updateInputModeAndDismissedButtonKeyboardMessageId({ state in
                    return (.none, state.keyboardButtonsMessage?.id ?? state.interfaceState.messageActionsState.closedButtonKeyboardMessageId)
                })
            }
        default:
            self.interfaceInteraction?.updateInputModeAndDismissedButtonKeyboardMessageId({ state in
                return (.none, state.interfaceState.messageActionsState.closedButtonKeyboardMessageId)
            })
        }
        self.searchNavigationNode?.deactivate()
        
        self.view.window?.endEditing(true)
    }
    
    func dismissTextInput() {
        self.view.window?.endEditing(true)
    }
    
    func collapseInput() {
        if self.inputPanelContainerNode.expansionFraction != 0.0 {
            self.inputPanelContainerNode.collapse()
            if let inputNode = self.inputNode {
                inputNode.hideInput = false
                inputNode.adjustLayoutForHiddenInput = false
                if let inputNode = inputNode as? ChatEntityKeyboardInputNode {
                    inputNode.markInputCollapsed()
                }
            }
        }
    }
    
    private func scheduleLayoutTransitionRequest(_ transition: ContainedViewLayoutTransition) {
        let requestId = self.scheduledLayoutTransitionRequestId
        self.scheduledLayoutTransitionRequestId += 1
        self.scheduledLayoutTransitionRequest = (requestId, transition)
        (self.view as? UITracingLayerView)?.schedule(layout: { [weak self] in
            if let strongSelf = self {
                if let (currentRequestId, currentRequestTransition) = strongSelf.scheduledLayoutTransitionRequest, currentRequestId == requestId {
                    strongSelf.scheduledLayoutTransitionRequest = nil
                    strongSelf.requestLayout(currentRequestTransition)
                }
            }
        })
        self.setNeedsLayout()
    }
    
    private func makeMediaInputNode() -> ChatInputNode? {
        guard let inputMediaNodeData = self.inputMediaNodeData else {
            return nil
        }
        
        var peerId: PeerId?
        if case let .peer(id) = self.chatPresentationInterfaceState.chatLocation {
            peerId = id
        }
        
        let inputNode = ChatEntityKeyboardInputNode(
            context: self.context,
            currentInputData: inputMediaNodeData,
            updatedInputData: self.inputMediaNodeDataPromise.get(),
            defaultToEmojiTab: !self.chatPresentationInterfaceState.interfaceState.effectiveInputState.inputText.string.isEmpty || self.openStickersBeginWithEmoji,
            controllerInteraction: self.controllerInteraction,
            interfaceInteraction: self.interfaceInteraction,
            chatPeerId: peerId
        )
        self.openStickersBeginWithEmoji = false
        
        return inputNode
    }
    
    func loadInputPanels(theme: PresentationTheme, strings: PresentationStrings, fontSize: PresentationFontSize) {
        if !self.didInitializeInputMediaNodeDataPromise, let interfaceInteraction = self.interfaceInteraction {
            self.didInitializeInputMediaNodeDataPromise = true
            
            let areCustomEmojiEnabled = self.chatPresentationInterfaceState.customEmojiAvailable
            
            self.inputMediaNodeDataPromise.set(ChatEntityKeyboardInputNode.inputData(context: self.context, interfaceInteraction: interfaceInteraction, controllerInteraction: self.controllerInteraction, chatPeerId: self.chatLocation.peerId, areCustomEmojiEnabled: areCustomEmojiEnabled))
        }
        
        if self.inputMediaNode == nil && !"".isEmpty {
            let peerId: PeerId? = self.chatPresentationInterfaceState.chatLocation.peerId
            let inputNode = ChatMediaInputNode(context: self.context, peerId: peerId, chatLocation: self.chatPresentationInterfaceState.chatLocation, controllerInteraction: self.controllerInteraction, chatWallpaper: self.chatPresentationInterfaceState.chatWallpaper, theme: theme, strings: strings, fontSize: fontSize, gifPaneIsActiveUpdated: { [weak self] value in
                if let strongSelf = self, let interfaceInteraction = strongSelf.interfaceInteraction {
                    interfaceInteraction.updateInputModeAndDismissedButtonKeyboardMessageId { state in
                        if case let .media(_, expanded, focused) = state.inputMode {
                            if value {
                                return (.media(mode: .gif, expanded: expanded, focused: focused), nil)
                            } else {
                                return (.media(mode: .other, expanded: expanded, focused: focused), nil)
                            }
                        } else {
                            return (state.inputMode, nil)
                        }
                    }
                }
            })
            inputNode.interfaceInteraction = interfaceInteraction
            inputNode.requestDisableStickerAnimations = { [weak self] disabled in
                self?.controller?.disableStickerAnimations = disabled
            }
            self.inputMediaNode = inputNode
            if let (validLayout, _) = self.validLayout {
                let _ = inputNode.updateLayout(width: validLayout.size.width, leftInset: validLayout.safeInsets.left, rightInset: validLayout.safeInsets.right, bottomInset: validLayout.intrinsicInsets.bottom, standardInputHeight: validLayout.standardInputHeight, inputHeight: validLayout.inputHeight ?? 0.0, maximumHeight: validLayout.standardInputHeight, inputPanelHeight: 44.0, transition: .immediate, interfaceState: self.chatPresentationInterfaceState, deviceMetrics: validLayout.deviceMetrics, isVisible: false, isExpanded: self.inputPanelContainerNode.stableIsExpanded)
            }
        }
        
        self.textInputPanelNode?.loadTextInputNodeIfNeeded()
    }
    
    func currentInputPanelFrame() -> CGRect? {
        return self.inputPanelNode?.frame
    }
    
    func sendButtonFrame() -> CGRect? {
        if let mediaPreviewNode = self.inputPanelNode as? ChatRecordingPreviewInputPanelNode {
            return mediaPreviewNode.convert(mediaPreviewNode.sendButton.frame, to: self)
        } else if let frame = self.textInputPanelNode?.actionButtons.frame {
            return self.textInputPanelNode?.convert(frame, to: self)
        } else {
            return nil
        }
    }
    
    func textInputNode() -> EditableTextNode? {
        return self.textInputPanelNode?.textInputNode
    }
    
    func updateRecordedMediaDeleted(_ isDeleted: Bool) {
        self.textInputPanelNode?.isMediaDeleted = isDeleted
    }
    
    func frameForVisibleArea() -> CGRect {
        var rect = CGRect(origin: CGPoint(x: self.visibleAreaInset.left, y: self.visibleAreaInset.top), size: CGSize(width: self.bounds.size.width - self.visibleAreaInset.left - self.visibleAreaInset.right, height: self.bounds.size.height - self.visibleAreaInset.top - self.visibleAreaInset.bottom))
        if let inputContextPanelNode = self.inputContextPanelNode, let topItemFrame = inputContextPanelNode.topItemFrame {
            rect.size.height = topItemFrame.minY
        }
        if let containerNode = self.containerNode {
            return containerNode.view.convert(rect, to: self.view)
        } else {
            return rect
        }
    }
    
    func frameForInputPanelAccessoryButton(_ item: ChatTextInputAccessoryItem) -> CGRect? {
        if let textInputPanelNode = self.textInputPanelNode, self.inputPanelNode === textInputPanelNode {
            return textInputPanelNode.frameForAccessoryButton(item).flatMap {
                return $0.offsetBy(dx: textInputPanelNode.frame.minX, dy: textInputPanelNode.frame.minY)
            }
        }
        return nil
    }
    
    func frameForInputActionButton() -> CGRect? {
        if let textInputPanelNode = self.textInputPanelNode, self.inputPanelNode === textInputPanelNode {
            return textInputPanelNode.frameForInputActionButton().flatMap {
                return $0.offsetBy(dx: textInputPanelNode.frame.minX, dy: textInputPanelNode.frame.minY)
            }
        } else if let recordingPreviewPanelNode = self.inputPanelNode as? ChatRecordingPreviewInputPanelNode {
            return recordingPreviewPanelNode.frameForInputActionButton().flatMap {
                return $0.offsetBy(dx: recordingPreviewPanelNode.frame.minX, dy: recordingPreviewPanelNode.frame.minY)
            }
        }
        return nil
    }
    
    func frameForAttachmentButton() -> CGRect? {
        if let textInputPanelNode = self.textInputPanelNode, self.inputPanelNode === textInputPanelNode {
            return textInputPanelNode.frameForAttachmentButton().flatMap {
                return $0.offsetBy(dx: textInputPanelNode.frame.minX, dy: textInputPanelNode.frame.minY)
            }
        }
        return nil
    }
    
    func frameForMenuButton() -> CGRect? {
        if let textInputPanelNode = self.textInputPanelNode, self.inputPanelNode === textInputPanelNode {
            return textInputPanelNode.frameForMenuButton().flatMap {
                return $0.offsetBy(dx: textInputPanelNode.frame.minX, dy: textInputPanelNode.frame.minY)
            }
        }
        return nil
    }
    
    func frameForStickersButton() -> CGRect? {
        if let textInputPanelNode = self.textInputPanelNode, self.inputPanelNode === textInputPanelNode {
            return textInputPanelNode.frameForStickersButton().flatMap {
                return $0.offsetBy(dx: textInputPanelNode.frame.minX, dy: textInputPanelNode.frame.minY)
            }
        }
        return nil
    }
    
    func frameForEmojiButton() -> CGRect? {
        if let textInputPanelNode = self.textInputPanelNode, self.inputPanelNode === textInputPanelNode {
            return textInputPanelNode.frameForEmojiButton().flatMap {
                return $0.offsetBy(dx: textInputPanelNode.frame.minX, dy: textInputPanelNode.frame.minY)
            }
        }
        return nil
    }
    
    var isTextInputPanelActive: Bool {
        return self.inputPanelNode is ChatTextInputPanelNode
    }
    
    var currentTextInputLanguage: String? {
        return self.textInputPanelNode?.effectiveInputLanguage
    }
    
    func getWindowInputAccessoryHeight() -> CGFloat {
        var height = self.inputPanelBackgroundNode.bounds.size.height
        if case .overlay = self.chatPresentationInterfaceState.mode {
            height += 8.0
        }
        return height
    }
    
    func animateInAsOverlay(from fromNode: ASDisplayNode?, completion: @escaping () -> Void) {
        if let inputPanelNode = self.inputPanelNode as? ChatTextInputPanelNode, let fromNode = fromNode {
            if inputPanelNode.isFocused {
                self.performAnimateInAsOverlay(from: fromNode, transition: .animated(duration: 0.4, curve: .spring))
                completion()
            } else {
                self.animateInAsOverlayCompletion = completion
                self.bounds = CGRect(origin: CGPoint(x: -self.bounds.size.width * 2.0, y: 0.0), size: self.bounds.size)
                self.scheduledAnimateInAsOverlayFromNode = fromNode
                self.scheduleLayoutTransitionRequest(.immediate)
                inputPanelNode.ensureFocused()
            }
        } else {
            self.performAnimateInAsOverlay(from: fromNode, transition: .animated(duration: 0.4, curve: .spring))
            completion()
        }
    }
    
    private func performAnimateInAsOverlay(from fromNode: ASDisplayNode?, transition: ContainedViewLayoutTransition) {
        if let containerBackgroundNode = self.containerBackgroundNode, let fromNode = fromNode {
            let fromFrame = fromNode.view.convert(fromNode.bounds, to: self.view)
            containerBackgroundNode.supernode?.insertSubnode(fromNode, aboveSubnode: containerBackgroundNode)
            fromNode.frame = fromFrame
            
            fromNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.3, removeOnCompletion: false, completion: { [weak fromNode] _ in
                fromNode?.removeFromSupernode()
            })
            
            transition.animateFrame(node: containerBackgroundNode, from: CGRect(origin: fromFrame.origin.offsetBy(dx: -8.0, dy: -8.0), size: CGSize(width: fromFrame.size.width + 8.0 * 2.0, height: fromFrame.size.height + 8.0 + 20.0)))
            containerBackgroundNode.layer.animateSpring(from: 0.99 as NSNumber, to: 1.0 as NSNumber, keyPath: "transform.scale", duration: 0.5, initialVelocity: 1.0, damping: 10.0, removeOnCompletion: true, additive: false, completion: nil)
            
            if let containerNode = self.containerNode {
                containerNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)
                transition.animateFrame(node: containerNode, from: fromFrame)
                transition.animatePositionAdditive(node: self.backgroundNode, offset: CGPoint(x: 0.0, y: -containerNode.bounds.size.height))
                transition.animatePositionAdditive(node: self.historyNodeContainer, offset: CGPoint(x: 0.0, y: -containerNode.bounds.size.height))
                
                transition.updateFrame(node: fromNode, frame: CGRect(origin: containerNode.frame.origin, size: fromNode.frame.size))
            }
            
            self.backgroundEffectNode?.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.3)
            
            let inputPanelsOffset = self.bounds.size.height - self.inputPanelBackgroundNode.frame.minY
            transition.animateFrame(node: self.inputPanelBackgroundNode, from: self.inputPanelBackgroundNode.frame.offsetBy(dx: 0.0, dy: inputPanelsOffset))
            transition.animateFrame(node: self.inputPanelBackgroundSeparatorNode, from: self.inputPanelBackgroundSeparatorNode.frame.offsetBy(dx: 0.0, dy: inputPanelsOffset))
            if let inputPanelNode = self.inputPanelNode {
                transition.animateFrame(node: inputPanelNode, from: inputPanelNode.frame.offsetBy(dx: 0.0, dy: inputPanelsOffset))
            }
            if let accessoryPanelNode = self.accessoryPanelNode {
                transition.animateFrame(node: accessoryPanelNode, from: accessoryPanelNode.frame.offsetBy(dx: 0.0, dy: inputPanelsOffset))
            }
            
            if let _ = self.scrollContainerNode {
                containerBackgroundNode.layer.animateSpring(from: 0.99 as NSNumber, to: 1.0 as NSNumber, keyPath: "transform.scale", duration: 0.8, initialVelocity: 100.0, damping: 80.0, removeOnCompletion: true, additive: false, completion: nil)
                self.containerNode?.layer.animateSpring(from: 0.99 as NSNumber, to: 1.0 as NSNumber, keyPath: "transform.scale", duration: 0.8, initialVelocity: 100.0, damping: 80.0, removeOnCompletion: true, additive: false, completion: nil)
            }
            
            self.navigateButtons.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.3)
        } else {
            self.backgroundEffectNode?.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.3)
            if let containerNode = self.containerNode {
                containerNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)
            }
        }
        
        if let animateInAsOverlayCompletion = self.animateInAsOverlayCompletion {
            self.animateInAsOverlayCompletion = nil
            animateInAsOverlayCompletion()
        }
    }
    
    func animateDismissAsOverlay(completion: @escaping () -> Void) {
        if let containerNode = self.containerNode {
            self.dismissedAsOverlay = true
            self.dismissAsOverlayLayout = self.validLayout?.0
            
            self.backgroundEffectNode?.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.27, removeOnCompletion: false)
            
            self.containerBackgroundNode?.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.27, removeOnCompletion: false)
            self.containerBackgroundNode?.layer.animateScale(from: 1.0, to: 0.6, duration: 0.29, removeOnCompletion: false)
            
            containerNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.27, removeOnCompletion: false)
            containerNode.layer.animateScale(from: 1.0, to: 0.6, duration: 0.29, removeOnCompletion: false)
            
            self.navigateButtons.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.25, removeOnCompletion: false)
            
            self.dismissAsOverlayCompletion = completion
            self.scheduleLayoutTransitionRequest(.animated(duration: 0.4, curve: .spring))
            self.dismissInput()
        } else {
            completion()
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if let scrollContainerNode = self.scrollContainerNode, scrollView === scrollContainerNode.view {
            if abs(scrollView.contentOffset.y) > 50.0 {
                scrollView.isScrollEnabled = false
                self.dismissAsOverlay()
            }
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if let scrollContainerNode = self.scrollContainerNode, scrollView === scrollContainerNode.view {
            if self.hapticFeedback == nil {
                self.hapticFeedback = HapticFeedback()
            }
            self.hapticFeedback?.prepareImpact()
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let scrollContainerNode = self.scrollContainerNode, scrollView === scrollContainerNode.view {
            let dismissStatus = abs(scrollView.contentOffset.y) > 50.0
            if dismissStatus != self.scrollViewDismissStatus {
                self.scrollViewDismissStatus = dismissStatus
                if !self.dismissedAsOverlay {
                    self.hapticFeedback?.impact()
                }
            }
        }
    }
        
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let inputMediaNode = self.inputMediaNode, self.inputNode === inputMediaNode {
            let convertedPoint = self.view.convert(point, to: inputMediaNode.view)
            if inputMediaNode.point(inside: convertedPoint, with: event) {
                return inputMediaNode.hitTest(convertedPoint, with: event)
            }
        }
        switch self.chatPresentationInterfaceState.mode {
        case .standard(previewing: true):
            if let result = self.historyNode.view.hitTest(self.view.convert(point, to: self.historyNode.view), with: event), let node = result.asyncdisplaykit_node, node is ChatMessageSelectionNode || node is GridMessageSelectionNode {
                return result
            }
            if let result = self.navigateButtons.hitTest(self.view.convert(point, to: self.navigateButtons.view), with: event) {
                return result
            }
            if self.bounds.contains(point) {
                return self.historyNode.view
            }
        default:
            break
        }
        
        var maybeDismissOverlayContent = true
        if let inputNode = self.inputNode, inputNode.bounds.contains(self.view.convert(point, to: inputNode.view)) {
            if let externalTopPanelContainer = inputNode.externalTopPanelContainer {
                if externalTopPanelContainer.hitTest(self.view.convert(point, to: externalTopPanelContainer), with: nil) != nil {
                    maybeDismissOverlayContent = true
                } else {
                    maybeDismissOverlayContent = false
                }
            } else {
                maybeDismissOverlayContent = false
            }
        }
        
        if let inputPanelNode = self.inputPanelNode, let viewForOverlayContent = inputPanelNode.viewForOverlayContent {
            if let result = viewForOverlayContent.hitTest(self.view.convert(point, to: viewForOverlayContent), with: event) {
                return result
            }
            if maybeDismissOverlayContent {
                viewForOverlayContent.maybeDismissContent(point: self.view.convert(point, to: viewForOverlayContent))
            }
        }
        
        return nil
    }
    
    @objc func topDimNodeTapGesture(_ recognizer: UITapGestureRecognizer) {
        if case .ended = recognizer.state {
            self.interfaceInteraction?.updateInputModeAndDismissedButtonKeyboardMessageId { state in
                if case let .media(mode, expanded, focused) = state.inputMode, expanded != nil {
                    return (.media(mode: mode, expanded: nil, focused: focused), nil)
                } else {
                    return (state.inputMode, nil)
                }
            }
        }
    }
    
    func scrollToTop() {
        if case let .media(_, maybeExpanded, _) = self.chatPresentationInterfaceState.inputMode, maybeExpanded != nil {
            self.interfaceInteraction?.updateInputModeAndDismissedButtonKeyboardMessageId { state in
                if case let .media(mode, expanded, focused) = state.inputMode, expanded != nil {
                    return (.media(mode: mode, expanded: expanded, focused: focused), nil)
                } else {
                    return (state.inputMode, nil)
                }
            }
        } else {
            self.historyNode.scrollScreenToTop()
        }
    }
    
    @objc func backgroundEffectTap(_ recognizer: UITapGestureRecognizer) {
        if case .ended = recognizer.state {
            self.dismissAsOverlay()
        }
    }
    
    func updateDropInteraction(isActive: Bool) {
        if isActive {
            if self.dropDimNode == nil {
                let dropDimNode = ASDisplayNode()
                dropDimNode.backgroundColor = self.chatPresentationInterfaceState.theme.chatList.backgroundColor.withAlphaComponent(0.35)
                self.dropDimNode = dropDimNode
                self.contentContainerNode.addSubnode(dropDimNode)
                if let (layout, _) = self.validLayout {
                    dropDimNode.frame = CGRect(origin: CGPoint(), size: layout.size)
                    dropDimNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.25)
                }
            }
        } else if let dropDimNode = self.dropDimNode {
            self.dropDimNode = nil
            dropDimNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.3, removeOnCompletion: false, completion: { [weak dropDimNode] _ in
                dropDimNode?.removeFromSupernode()
            })
        }
    }
    
    private func updateLayoutInternal(transition: ContainedViewLayoutTransition) {
        if let (layout, navigationHeight) = self.validLayout {
            self.containerLayoutUpdated(layout, navigationBarHeight: navigationHeight, transition: transition, listViewTransaction: { updateSizeAndInsets, additionalScrollDistance, scrollToTop, completion in
                self.historyNode.updateLayout(transition: transition, updateSizeAndInsets: updateSizeAndInsets, additionalScrollDistance: additionalScrollDistance, scrollToTop: scrollToTop, completion: completion)
            }, updateExtraNavigationBarBackgroundHeight: { _, _ in
            })
        }
    }
    
    private func panGestureBegan(location: CGPoint) {
        guard let derivedLayoutState = self.derivedLayoutState, let (validLayout, _) = self.validLayout else {
            return
        }
        if self.upperInputPositionBound != nil {
            return
        }
        if let inputHeight = validLayout.inputHeight {
            if !inputHeight.isZero {
                return
            }
        }
        
        let keyboardGestureBeginLocation = location
        let accessoryHeight = self.getWindowInputAccessoryHeight()
        if let inputHeight = derivedLayoutState.inputNodeHeight, !inputHeight.isZero, keyboardGestureBeginLocation.y < validLayout.size.height - inputHeight - accessoryHeight, !self.inputPanelContainerNode.stableIsExpanded {
            var enableGesture = true
            if let view = self.view.hitTest(location, with: nil) {
                if doesViewTreeDisableInteractiveTransitionGestureRecognizer(view) {
                    enableGesture = false
                }
            }
            
            if let peer = self.chatPresentationInterfaceState.renderedPeer?.peer as? TelegramUser, peer.botInfo != nil, case .inputButtons = self.chatPresentationInterfaceState.inputMode {
                enableGesture = false
            }
            
            if enableGesture {
                self.keyboardGestureBeginLocation = keyboardGestureBeginLocation
                self.keyboardGestureAccessoryHeight = accessoryHeight
            }
        }
    }
    
    private func panGestureMoved(location: CGPoint) {
        if let keyboardGestureBeginLocation = self.keyboardGestureBeginLocation {
            let currentLocation = location
            let deltaY = keyboardGestureBeginLocation.y - location.y
            if deltaY * deltaY >= 3.0 * 3.0 || self.upperInputPositionBound != nil {
                self.upperInputPositionBound = currentLocation.y + (self.keyboardGestureAccessoryHeight ?? 0.0)
                self.updateLayoutInternal(transition: .immediate)
            }
        }
    }
    
    private func panGestureEnded(location: CGPoint, velocity: CGPoint?) {
        guard let derivedLayoutState = self.derivedLayoutState, let (validLayout, _) = self.validLayout else {
            return
        }
        if self.keyboardGestureBeginLocation == nil {
            return
        }
        
        self.keyboardGestureBeginLocation = nil
        let currentLocation = location
        
        let accessoryHeight = (self.keyboardGestureAccessoryHeight ?? 0.0)
        
        var canDismiss = false
        if let upperInputPositionBound = self.upperInputPositionBound, upperInputPositionBound >= validLayout.size.height - accessoryHeight {
            canDismiss = true
        } else if let velocity = velocity, velocity.y > 100.0 {
            canDismiss = true
        }
        
        if canDismiss, let inputHeight = derivedLayoutState.inputNodeHeight, currentLocation.y + (self.keyboardGestureAccessoryHeight ?? 0.0) > validLayout.size.height - inputHeight {
            self.upperInputPositionBound = nil
            self.dismissInput()
        } else {
            self.upperInputPositionBound = nil
            self.updateLayoutInternal(transition: .animated(duration: 0.25, curve: .spring))
        }
    }
    
    func cancelInteractiveKeyboardGestures() {
        self.panRecognizer?.isEnabled = false
        self.panRecognizer?.isEnabled = true
        
        if self.upperInputPositionBound != nil {
            self.updateLayoutInternal(transition: .animated(duration: 0.25, curve: .spring))
        }
        
        if self.keyboardGestureBeginLocation != nil {
            self.keyboardGestureBeginLocation = nil
        }
    }
    
    func openStickers(beginWithEmoji: Bool) {
        self.openStickersBeginWithEmoji = beginWithEmoji
        
        if let inputMediaNode = self.inputMediaNode {
            if self.openStickersDisposable == nil {
                self.openStickersDisposable = (inputMediaNode.ready
                |> take(1)
                |> deliverOnMainQueue).start(next: { [weak self] in
                    self?.openStickersDisposable = nil
                    self?.interfaceInteraction?.updateInputModeAndDismissedButtonKeyboardMessageId({ state in
                        return (.media(mode: .other, expanded: nil, focused: false), state.interfaceState.messageActionsState.closedButtonKeyboardMessageId)
                    })
                })
            }
        } else {
            if self.openStickersDisposable == nil {
                self.openStickersDisposable = (self.inputMediaNodeDataPromise.get()
                |> take(1)
                |> deliverOnMainQueue).start(next: { [weak self] _ in
                    guard let strongSelf = self else {
                        return
                    }
                    
                    strongSelf.interfaceInteraction?.updateInputModeAndDismissedButtonKeyboardMessageId({ state in
                        return (.media(mode: .other, expanded: nil, focused: false), state.interfaceState.messageActionsState.closedButtonKeyboardMessageId)
                    })
                })
            }
        }
    }
    
    func sendCurrentMessage(silentPosting: Bool? = nil, scheduleTime: Int32? = nil, completion: @escaping () -> Void = {}) {
        if let textInputPanelNode = self.inputPanelNode as? ChatTextInputPanelNode {
            self.historyNode.justSentTextMessage = true
            
            if let textInputNode = textInputPanelNode.textInputNode, textInputNode.isFirstResponder() {
                Keyboard.applyAutocorrection(textView: textInputNode.textView)
            }
            
            var effectivePresentationInterfaceState = self.chatPresentationInterfaceState
            if let textInputPanelNode = self.textInputPanelNode {
                effectivePresentationInterfaceState = effectivePresentationInterfaceState.updatedInterfaceState { $0.withUpdatedEffectiveInputState(textInputPanelNode.inputTextState) }
            }
            
            if let _ = effectivePresentationInterfaceState.interfaceState.editMessage {
                self.interfaceInteraction?.editMessage()
            } else {
                var isScheduledMessages = false
                if case .scheduledMessages = effectivePresentationInterfaceState.subject {
                    isScheduledMessages = true
                }
                
                if let _ = effectivePresentationInterfaceState.slowmodeState, !isScheduledMessages && scheduleTime == nil {
                    if let rect = self.frameForInputActionButton() {
                        self.interfaceInteraction?.displaySlowmodeTooltip(self.view, rect)
                    }
                    return
                }
                
                var messages: [EnqueueMessage] = []
                
                let effectiveInputText = effectivePresentationInterfaceState.interfaceState.composeInputState.inputText
                
                var inlineStickers: [MediaId: Media] = [:]
                var firstLockedPremiumEmoji: TelegramMediaFile?
                var bubbleUpEmojiOrStickersetsById: [Int64: ItemCollectionId] = [:]
                effectiveInputText.enumerateAttribute(ChatTextInputAttributes.customEmoji, in: NSRange(location: 0, length: effectiveInputText.length), using: { value, _, _ in
                    if let value = value as? ChatTextInputTextCustomEmojiAttribute {
                        if let file = value.file {
                            inlineStickers[file.fileId] = file
                            if let packId = value.interactivelySelectedFromPackId {
                                bubbleUpEmojiOrStickersetsById[file.fileId.id] = packId
                            }
                            if file.isPremiumEmoji && !self.chatPresentationInterfaceState.isPremium && self.chatPresentationInterfaceState.chatLocation.peerId != self.context.account.peerId {
                                if firstLockedPremiumEmoji == nil {
                                    firstLockedPremiumEmoji = file
                                }
                            }
                        }
                    }
                })
                
                if let firstLockedPremiumEmoji = firstLockedPremiumEmoji {
                    let presentationData = self.context.sharedContext.currentPresentationData.with { $0 }
                    self.controllerInteraction.displayUndo(.sticker(context: context, file: firstLockedPremiumEmoji, title: nil, text: presentationData.strings.EmojiInput_PremiumEmojiToast_Text, undoText: presentationData.strings.EmojiInput_PremiumEmojiToast_Action, customAction: { [weak self] in
                        guard let strongSelf = self else {
                            return
                        }
                        strongSelf.dismissTextInput()
                        
                        var replaceImpl: ((ViewController) -> Void)?
                        let controller = PremiumDemoScreen(context: strongSelf.context, subject: .animatedEmoji, action: {
                            let controller = PremiumIntroScreen(context: strongSelf.context, source: .animatedEmoji)
                            replaceImpl?(controller)
                        })
                        replaceImpl = { [weak controller] c in
                            controller?.replace(with: c)
                        }
                        strongSelf.controller?.present(controller, in: .window(.root), with: nil)
                    }))
                    
                    return
                }
                
                let timestamp = CACurrentMediaTime()
                if self.lastSendTimestamp + 0.15 > timestamp {
                    return
                }
                self.lastSendTimestamp = timestamp
                
                self.updateTypingActivity(false)
                
                let trimmedInputText = effectiveInputText.string.trimmingCharacters(in: .whitespacesAndNewlines)
                let peerId = effectivePresentationInterfaceState.chatLocation.peerId
                if peerId?.namespace != Namespaces.Peer.SecretChat, let interactiveEmojis = self.interactiveEmojis, interactiveEmojis.emojis.contains(trimmedInputText) {
                    messages.append(.message(text: "", attributes: [], inlineStickers: [:], mediaReference: AnyMediaReference.standalone(media: TelegramMediaDice(emoji: trimmedInputText)), replyToMessageId: self.chatPresentationInterfaceState.interfaceState.replyMessageId, localGroupingKey: nil, correlationId: nil, bubbleUpEmojiOrStickersets: []))
                } else {
                    let inputText = convertMarkdownToAttributes(effectiveInputText)
                    
                    for text in breakChatInputText(trimChatInputText(inputText)) {
                        if text.length != 0 {
                            var attributes: [MessageAttribute] = []
                            let entities = generateTextEntities(text.string, enabledTypes: .all, currentEntities: generateChatInputTextEntities(text, maxAnimatedEmojisInText: 0))
                            if !entities.isEmpty {
                                attributes.append(TextEntitiesMessageAttribute(entities: entities))
                            }
                            var webpage: TelegramMediaWebpage?
                            if self.chatPresentationInterfaceState.interfaceState.composeDisableUrlPreview != nil {
                                attributes.append(OutgoingContentInfoMessageAttribute(flags: [.disableLinkPreviews]))
                            } else {
                                webpage = self.chatPresentationInterfaceState.urlPreview?.1
                            }
                            
                            var bubbleUpEmojiOrStickersets: [ItemCollectionId] = []
                            for entity in entities {
                                if case let .CustomEmoji(_, fileId) = entity.type {
                                    if let packId = bubbleUpEmojiOrStickersetsById[fileId] {
                                        if !bubbleUpEmojiOrStickersets.contains(packId) {
                                            bubbleUpEmojiOrStickersets.append(packId)
                                        }
                                    }
                                }
                            }
                            
                            if bubbleUpEmojiOrStickersets.count > 1 {
                                bubbleUpEmojiOrStickersets.removeAll()
                            }

                            messages.append(.message(text: text.string, attributes: attributes, inlineStickers: inlineStickers, mediaReference: webpage.flatMap(AnyMediaReference.standalone), replyToMessageId: self.chatPresentationInterfaceState.interfaceState.replyMessageId, localGroupingKey: nil, correlationId: nil, bubbleUpEmojiOrStickersets: bubbleUpEmojiOrStickersets))
                        }
                    }

                    var forwardingToSameChat = false
                    if case let .peer(id) = self.chatPresentationInterfaceState.chatLocation, id.namespace == Namespaces.Peer.CloudUser, id != self.context.account.peerId, let forwardMessageIds = self.chatPresentationInterfaceState.interfaceState.forwardMessageIds, forwardMessageIds.count == 1 {
                        for messageId in forwardMessageIds {
                            if messageId.peerId == id {
                                forwardingToSameChat = true
                            }
                        }
                    }
                    if !messages.isEmpty && forwardingToSameChat {
                        self.controllerInteraction.displaySwipeToReplyHint()
                    }
                }
                
                if !messages.isEmpty || self.chatPresentationInterfaceState.interfaceState.forwardMessageIds != nil {
                    if let forwardMessageIds = self.chatPresentationInterfaceState.interfaceState.forwardMessageIds {
                        var attributes: [MessageAttribute] = []
                        attributes.append(ForwardOptionsMessageAttribute(hideNames: self.chatPresentationInterfaceState.interfaceState.forwardOptionsState?.hideNames == true, hideCaptions: self.chatPresentationInterfaceState.interfaceState.forwardOptionsState?.hideCaptions == true))

                        var replyThreadId: Int64?
                        if case let .replyThread(replyThreadMessage) = self.chatPresentationInterfaceState.chatLocation {
                            replyThreadId = Int64(replyThreadMessage.messageId.id)
                        }
                        
                        for id in forwardMessageIds.sorted() {
                            messages.append(.forward(source: id, threadId: replyThreadId, grouping: .auto, attributes: attributes, correlationId: nil))
                        }
                    }
                    
                    var usedCorrelationId: Int64?

                    if !messages.isEmpty, case .message = messages[messages.count - 1] {
                        let correlationId = Int64.random(in: 0 ..< Int64.max)
                        messages[messages.count - 1] = messages[messages.count - 1].withUpdatedCorrelationId(correlationId)

                        var replyPanel: ReplyAccessoryPanelNode?
                        if let accessoryPanelNode = self.accessoryPanelNode as? ReplyAccessoryPanelNode {
                            replyPanel = accessoryPanelNode
                        }
                        if self.shouldAnimateMessageTransition, let inputPanelNode = self.inputPanelNode as? ChatTextInputPanelNode, let textInput = inputPanelNode.makeSnapshotForTransition() {
                            usedCorrelationId = correlationId
                            let source: ChatMessageTransitionNode.Source = .textInput(textInput: textInput, replyPanel: replyPanel)
                            self.messageTransitionNode.add(correlationId: correlationId, source: source, initiated: {
                            })
                        }
                    }

                    self.setupSendActionOnViewUpdate({ [weak self] in
                        if let strongSelf = self, let textInputPanelNode = strongSelf.inputPanelNode as? ChatTextInputPanelNode {
                            strongSelf.collapseInput()
                            
                            strongSelf.ignoreUpdateHeight = true
                            textInputPanelNode.text = ""
                            strongSelf.requestUpdateChatInterfaceState(.immediate, true, { $0.withUpdatedReplyMessageId(nil).withUpdatedForwardMessageIds(nil).withUpdatedForwardOptionsState(nil).withUpdatedComposeDisableUrlPreview(nil) })
                            strongSelf.ignoreUpdateHeight = false
                        }
                    }, usedCorrelationId)
                    completion()
                    
                    self.sendMessages(messages, silentPosting, scheduleTime, messages.count > 1)
                }
            }
        }
    }
    
    func animateIn(completion: (() -> Void)? = nil) {
        self.layer.animatePosition(from: CGPoint(x: self.layer.position.x, y: self.layer.position.y + self.layer.bounds.size.height), to: self.layer.position, duration: 0.5, timingFunction: kCAMediaTimingFunctionSpring, completion: { _ in
            completion?()
        })
    }
    
    func animateOut(completion: (() -> Void)? = nil) {
        self.layer.animatePosition(from: self.layer.position, to: CGPoint(x: self.layer.position.x, y: self.layer.position.y + self.layer.bounds.size.height), duration: 0.2, timingFunction: CAMediaTimingFunctionName.easeInEaseOut.rawValue, removeOnCompletion: false, completion: { _ in
            completion?()
        })
    }
    
    func setEnablePredictiveTextInput(_ value: Bool) {
        self.textInputPanelNode?.enablePredictiveInput = value
    }
    
    func updatePlainInputSeparatorAlpha(_ value: CGFloat, transition: ContainedViewLayoutTransition) {
        if self.plainInputSeparatorAlpha != value {
            let immediate = self.plainInputSeparatorAlpha == nil
            self.plainInputSeparatorAlpha = value
            self.updatePlainInputSeparator(transition: immediate ? .immediate : transition)
        }
    }
    
    func updatePlainInputSeparator(transition: ContainedViewLayoutTransition) {
        var resolvedValue: CGFloat
        if self.accessoryPanelNode != nil {
            resolvedValue = 1.0
        } else if self.usePlainInputSeparator {
            resolvedValue = self.plainInputSeparatorAlpha ?? 0.0
        } else {
            resolvedValue = 1.0
        }
        
        resolvedValue = resolvedValue * (1.0 - self.inputPanelContainerNode.expansionFraction)
        
        if resolvedValue != self.inputPanelBackgroundSeparatorNode.alpha {
            transition.updateAlpha(node: self.inputPanelBackgroundSeparatorNode, alpha: resolvedValue, beginWithCurrentState: true)
        }
    }
    
    func animateQuizCorrectOptionSelected() {
        self.view.insertSubview(ConfettiView(frame: self.view.bounds), aboveSubview: self.historyNode.view)
    }
    
    func willNavigateAway() {
    }
    
    func updateIsBlurred(_ isBlurred: Bool) {
        if isBlurred {
            if self.blurredHistoryNode == nil {
                let unscaledSize = self.historyNode.frame.size
                let image = generateImage(CGSize(width: floor(unscaledSize.width), height: floor(unscaledSize.height)), opaque: true, scale: 1.0, rotatedContext: { size, context in
                    context.clear(CGRect(origin: CGPoint(), size: size))
                    
                    UIGraphicsPushContext(context)
                    
                    let backgroundFrame = self.backgroundNode.view.convert(self.backgroundNode.bounds, to: self.historyNode.supernode?.view)
                    self.backgroundNode.view.drawHierarchy(in: backgroundFrame, afterScreenUpdates: false)
                    
                    context.translateBy(x: size.width / 2.0, y: size.height / 2.0)
                    context.scaleBy(x: -1.0, y: -1.0)
                    context.translateBy(x: -size.width / 2.0, y: -size.height / 2.0)
                    
                    self.historyNode.view.drawHierarchy(in: CGRect(origin: CGPoint(), size: unscaledSize), afterScreenUpdates: false)
                    
                    context.translateBy(x: size.width / 2.0, y: size.height / 2.0)
                    context.scaleBy(x: -1.0, y: -1.0)
                    context.translateBy(x: -size.width / 2.0, y: -size.height / 2.0)
                    
                    if let emptyNode = self.emptyNode {
                        emptyNode.view.drawHierarchy(in: CGRect(origin: CGPoint(), size: unscaledSize), afterScreenUpdates: false)
                    }
                    
                    UIGraphicsPopContext()
                }).flatMap(applyScreenshotEffectToImage)
                let blurredHistoryNode = ASImageNode()
                blurredHistoryNode.image = image
                blurredHistoryNode.frame = self.historyNode.frame
                self.blurredHistoryNode = blurredHistoryNode
                if let emptyNode = self.emptyNode {
                    emptyNode.supernode?.insertSubnode(blurredHistoryNode, aboveSubnode: emptyNode)
                } else {
                    self.historyNode.supernode?.insertSubnode(blurredHistoryNode, aboveSubnode: self.historyNode)
                }
            }
        } else {
            if let blurredHistoryNode = self.blurredHistoryNode {
                self.blurredHistoryNode = nil
                blurredHistoryNode.removeFromSupernode()
            }
        }
        self.historyNode.isHidden = isBlurred
    }

    var shouldAnimateMessageTransition: Bool {
        if (self.context.sharedContext.currentPresentationData.with({ $0 })).reduceMotion {
            return false
        }
        
        if self.chatPresentationInterfaceState.showCommands {
            return false
        }

        var hasAd = false
        self.historyNode.forEachVisibleItemNode { itemNode in
            if let itemNode = itemNode as? ChatMessageItemView {
                if let _ = itemNode.item?.message.adAttribute {
                    hasAd = true
                }
            }
        }

        if hasAd {
            return false
        }

        switch self.historyNode.visibleContentOffset() {
        case let .known(value) where value < 20.0:
            return true
        case .none:
            return true
        default:
            return false
        }
    }

    var shouldUseFastMessageSendAnimation: Bool {
        var hasAd = false
        self.historyNode.forEachVisibleItemNode { itemNode in
            if let itemNode = itemNode as? ChatMessageItemView {
                if let _ = itemNode.item?.message.adAttribute {
                    hasAd = true
                }
            }
        }

        if hasAd {
            return false
        }

        return true
    }

    var shouldAllowOverscrollActions: Bool {
        if let inputHeight = self.validLayout?.0.inputHeight, inputHeight > 0.0 {
            return false
        }
        if self.chatPresentationInterfaceState.inputTextPanelState.mediaRecordingState != nil {
            return false
        }
        if let inputPanelNode = self.inputPanelNode as? ChatTextInputPanelNode {
            if inputPanelNode.isFocused {
                return false
            }
            if !inputPanelNode.text.isEmpty {
                return false
            }
        }
        return true
    }

    final class SnapshotState {
        fileprivate let historySnapshotState: ChatHistoryListNode.SnapshotState
        let titleViewSnapshotState: ChatTitleView.SnapshotState?
        let avatarSnapshotState: ChatAvatarNavigationNode.SnapshotState?
        let navigationButtonsSnapshotState: ChatHistoryNavigationButtons.SnapshotState
        let titleAccessoryPanelSnapshot: UIView?
        let navigationBarHeight: CGFloat
        let inputPanelNodeSnapshot: UIView?
        let inputPanelOverscrollNodeSnapshot: UIView?

        fileprivate init(
            historySnapshotState: ChatHistoryListNode.SnapshotState,
            titleViewSnapshotState: ChatTitleView.SnapshotState?,
            avatarSnapshotState: ChatAvatarNavigationNode.SnapshotState?,
            navigationButtonsSnapshotState: ChatHistoryNavigationButtons.SnapshotState,
            titleAccessoryPanelSnapshot: UIView?,
            navigationBarHeight: CGFloat,
            inputPanelNodeSnapshot: UIView?,
            inputPanelOverscrollNodeSnapshot: UIView?
        ) {
            self.historySnapshotState = historySnapshotState
            self.titleViewSnapshotState = titleViewSnapshotState
            self.avatarSnapshotState = avatarSnapshotState
            self.navigationButtonsSnapshotState = navigationButtonsSnapshotState
            self.titleAccessoryPanelSnapshot = titleAccessoryPanelSnapshot
            self.navigationBarHeight = navigationBarHeight
            self.inputPanelNodeSnapshot = inputPanelNodeSnapshot
            self.inputPanelOverscrollNodeSnapshot = inputPanelOverscrollNodeSnapshot
        }
    }

    func prepareSnapshotState(
        titleViewSnapshotState: ChatTitleView.SnapshotState?,
        avatarSnapshotState: ChatAvatarNavigationNode.SnapshotState?
    ) -> SnapshotState {
        var titleAccessoryPanelSnapshot: UIView?
        if let titleAccessoryPanelNode = self.titleAccessoryPanelNode, let snapshot = titleAccessoryPanelNode.view.snapshotView(afterScreenUpdates: false) {
            snapshot.frame = titleAccessoryPanelNode.frame
            titleAccessoryPanelSnapshot = snapshot
        }
        var inputPanelNodeSnapshot: UIView?
        if let inputPanelNode = self.inputPanelNode, let snapshot = inputPanelNode.view.snapshotView(afterScreenUpdates: false) {
            snapshot.frame = inputPanelNode.frame
            inputPanelNodeSnapshot = snapshot
        }
        var inputPanelOverscrollNodeSnapshot: UIView?
        if let inputPanelOverscrollNode = self.inputPanelOverscrollNode, let snapshot = inputPanelOverscrollNode.view.snapshotView(afterScreenUpdates: false) {
            snapshot.frame = inputPanelOverscrollNode.frame
            inputPanelOverscrollNodeSnapshot = snapshot
        }
        return SnapshotState(
            historySnapshotState: self.historyNode.prepareSnapshotState(),
            titleViewSnapshotState: titleViewSnapshotState,
            avatarSnapshotState: avatarSnapshotState,
            navigationButtonsSnapshotState: self.navigateButtons.prepareSnapshotState(),
            titleAccessoryPanelSnapshot: titleAccessoryPanelSnapshot,
            navigationBarHeight: self.navigationBar?.backgroundNode.bounds.height ?? 0.0,
            inputPanelNodeSnapshot: inputPanelNodeSnapshot,
            inputPanelOverscrollNodeSnapshot: inputPanelOverscrollNodeSnapshot
        )
    }

    func animateFromSnapshot(_ snapshotState: SnapshotState, completion: @escaping () -> Void) {
        self.historyNode.animateFromSnapshot(snapshotState.historySnapshotState, completion: completion)
        self.navigateButtons.animateFromSnapshot(snapshotState.navigationButtonsSnapshotState)

        if let titleAccessoryPanelSnapshot = snapshotState.titleAccessoryPanelSnapshot {
            self.titleAccessoryPanelContainer.view.addSubview(titleAccessoryPanelSnapshot)
            if let _ = self.titleAccessoryPanelNode {
                titleAccessoryPanelSnapshot.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.3, removeOnCompletion: false, completion: { [weak titleAccessoryPanelSnapshot] _ in
                    titleAccessoryPanelSnapshot?.removeFromSuperview()
                })
                titleAccessoryPanelSnapshot.layer.animatePosition(from: CGPoint(), to: CGPoint(x: 0.0, y: -10.0), duration: 0.5, timingFunction: kCAMediaTimingFunctionSpring, removeOnCompletion: false, additive: true)
            } else {
                titleAccessoryPanelSnapshot.layer.animatePosition(from: CGPoint(), to: CGPoint(x: 0.0, y: -titleAccessoryPanelSnapshot.bounds.height), duration: 0.5, timingFunction: kCAMediaTimingFunctionSpring, removeOnCompletion: false, additive: true, completion: { [weak titleAccessoryPanelSnapshot] _ in
                    titleAccessoryPanelSnapshot?.removeFromSuperview()
                })
            }
        }

        if let titleAccessoryPanelNode = self.titleAccessoryPanelNode {
            if let _ = snapshotState.titleAccessoryPanelSnapshot {
                titleAccessoryPanelNode.layer.animatePosition(from: CGPoint(x: 0.0, y: 10.0), to: CGPoint(), duration: 0.5, timingFunction: kCAMediaTimingFunctionSpring, removeOnCompletion: true, additive: true)
                titleAccessoryPanelNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.3, removeOnCompletion: true)
            } else {
                titleAccessoryPanelNode.layer.animatePosition(from: CGPoint(x: 0.0, y: -titleAccessoryPanelNode.bounds.height), to: CGPoint(), duration: 0.5, timingFunction: kCAMediaTimingFunctionSpring, removeOnCompletion: true, additive: true)
            }
        }

        if let navigationBar = self.navigationBar {
            let currentFrame = navigationBar.backgroundNode.frame
            var previousFrame = currentFrame
            previousFrame.size.height = snapshotState.navigationBarHeight
            if previousFrame != currentFrame {
                navigationBar.backgroundNode.update(size: previousFrame.size, transition: .immediate)
                navigationBar.backgroundNode.update(size: currentFrame.size, transition: .animated(duration: 0.5, curve: .spring))
            }
        }

        if let inputPanelNode = self.inputPanelNode, let inputPanelNodeSnapshot = snapshotState.inputPanelNodeSnapshot {
            inputPanelNode.view.superview?.insertSubview(inputPanelNodeSnapshot, belowSubview: inputPanelNode.view)

            inputPanelNodeSnapshot.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.3, removeOnCompletion: false, completion: { [weak inputPanelNodeSnapshot] _ in
                inputPanelNodeSnapshot?.removeFromSuperview()
            })
            inputPanelNodeSnapshot.layer.animatePosition(from: CGPoint(), to: CGPoint(x: 0.0, y: -5.0), duration: 0.5, timingFunction: kCAMediaTimingFunctionSpring, removeOnCompletion: false, additive: true)

            if let inputPanelOverscrollNodeSnapshot = snapshotState.inputPanelOverscrollNodeSnapshot {
                inputPanelNode.view.superview?.insertSubview(inputPanelOverscrollNodeSnapshot, belowSubview: inputPanelNode.view)

                inputPanelOverscrollNodeSnapshot.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.3, removeOnCompletion: false, completion: { [weak inputPanelOverscrollNodeSnapshot] _ in
                    inputPanelOverscrollNodeSnapshot?.removeFromSuperview()
                })
                inputPanelOverscrollNodeSnapshot.layer.animatePosition(from: CGPoint(), to: CGPoint(x: 0.0, y: -5.0), duration: 0.5, timingFunction: kCAMediaTimingFunctionSpring, removeOnCompletion: false, additive: true)
            }

            inputPanelNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.3)
            inputPanelNode.layer.animatePosition(from: CGPoint(x: 0.0, y: 5.0), to: CGPoint(), duration: 0.5, timingFunction: kCAMediaTimingFunctionSpring, additive: true)
        }
    }

    private var preivousChatInputPanelOverscrollNodeTimestamp: Double = 0.0

    func setChatInputPanelOverscrollNode(overscrollNode: ChatInputPanelOverscrollNode?) {
        let directionUp: Bool
        if let overscrollNode = overscrollNode {
            if let current = self.inputPanelOverscrollNode {
                directionUp = current.priority > overscrollNode.priority
            } else {
                directionUp = true
            }
        } else {
            directionUp = false
        }

        let transition: ContainedViewLayoutTransition = .animated(duration: 0.15, curve: .easeInOut)

        let timestamp = CFAbsoluteTimeGetCurrent()
        if self.preivousChatInputPanelOverscrollNodeTimestamp > timestamp - 0.05 {
            if let inputPanelOverscrollNode = self.inputPanelOverscrollNode {
                self.inputPanelOverscrollNode = nil
                inputPanelOverscrollNode.removeFromSupernode()
            }
        }
        self.preivousChatInputPanelOverscrollNodeTimestamp = timestamp

        if let inputPanelOverscrollNode = self.inputPanelOverscrollNode {
            self.inputPanelOverscrollNode = nil
            inputPanelOverscrollNode.layer.animatePosition(from: CGPoint(), to: CGPoint(x: 0.0, y: directionUp ? -5.0 : 5.0), duration: 0.15, timingFunction: CAMediaTimingFunctionName.easeInEaseOut.rawValue, removeOnCompletion: false, additive: true)
            inputPanelOverscrollNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.15, removeOnCompletion: false, completion: { [weak inputPanelOverscrollNode] _ in
                inputPanelOverscrollNode?.removeFromSupernode()
            })
        }

        if let inputPanelNode = self.inputPanelNode, let overscrollNode = overscrollNode {
            self.inputPanelOverscrollNode = overscrollNode
            inputPanelNode.supernode?.insertSubnode(overscrollNode, aboveSubnode: inputPanelNode)

            overscrollNode.frame = inputPanelNode.frame
            overscrollNode.update(size: overscrollNode.bounds.size)

            overscrollNode.layer.animatePosition(from: CGPoint(x: 0.0, y: directionUp ? 5.0 : -5.0), to: CGPoint(), duration: 0.15, timingFunction: CAMediaTimingFunctionName.easeInEaseOut.rawValue, additive: true)
            overscrollNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.15)
        }

        if let inputPanelNode = self.inputPanelNode {
            transition.updateAlpha(node: inputPanelNode, alpha: overscrollNode == nil ? 1.0 : 0.0)
            transition.updateSublayerTransformOffset(layer: inputPanelNode.layer, offset: CGPoint(x: 0.0, y: overscrollNode == nil ? 0.0 : -5.0))
        }
    }
}
