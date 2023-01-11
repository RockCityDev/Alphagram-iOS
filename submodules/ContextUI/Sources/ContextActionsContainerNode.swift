import Foundation
import AsyncDisplayKit
import Display
import TelegramCore
import TelegramPresentationData
import TextSelectionNode
import Markdown
import AppBundle
import TextFormat
import TextNodeWithEntities
import SwiftSignalKit

private final class ContextActionsSelectionGestureRecognizer: UIPanGestureRecognizer {
    var updateLocation: ((CGPoint, Bool) -> Void)?
    var completed: ((Bool) -> Void)?
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        
        self.updateLocation?(touches.first!.location(in: self.view), false)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        
        self.updateLocation?(touches.first!.location(in: self.view), true)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        
        self.completed?(true)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
        
        self.completed?(false)
    }
}

private enum ContextItemNode {
    case action(ContextActionNode)
    case custom(ContextMenuCustomNode)
    case itemSeparator(ASDisplayNode)
    case separator(ASDisplayNode)
}

private final class InnerActionsContainerNode: ASDisplayNode {
    private let blurBackground: Bool
    private let presentationData: PresentationData
    private let containerNode: ASDisplayNode
    private var effectView: UIVisualEffectView?
    private var itemNodes: [ContextItemNode]
    private let feedbackTap: () -> Void
    
    private(set) var gesture: UIGestureRecognizer?
    private var currentHighlightedActionNode: ContextActionNodeProtocol?
    
    var panSelectionGestureEnabled: Bool = true {
        didSet {
            if self.panSelectionGestureEnabled != oldValue, let gesture = self.gesture {
                gesture.isEnabled = self.panSelectionGestureEnabled
                
                self.itemNodes.forEach({ itemNode in
                    switch itemNode {
                    case let .action(actionNode):
                        actionNode.isUserInteractionEnabled = !self.panSelectionGestureEnabled
                    default:
                        break
                    }
                })
            }
        }
    }
    
    init(presentationData: PresentationData, items: [ContextMenuItem], getController: @escaping () -> ContextControllerProtocol?, actionSelected: @escaping (ContextMenuActionResult) -> Void, requestLayout: @escaping () -> Void, feedbackTap: @escaping () -> Void, blurBackground: Bool) {
        self.presentationData = presentationData
        self.feedbackTap = feedbackTap
        self.blurBackground = blurBackground
        
        self.containerNode = ASDisplayNode()
        self.containerNode.clipsToBounds = true
        self.containerNode.cornerRadius = 14.0
        self.containerNode.backgroundColor = presentationData.theme.contextMenu.backgroundColor

        var requestUpdateAction: ((AnyHashable, ContextMenuActionItem) -> Void)?
        
        var itemNodes: [ContextItemNode] = []
        for i in 0 ..< items.count {
            switch items[i] {
            case let .action(action):
                itemNodes.append(.action(ContextActionNode(presentationData: presentationData, action: action, getController: getController, actionSelected: actionSelected, requestLayout: requestLayout, requestUpdateAction: { id, action in
                    requestUpdateAction?(id, action)
                })))
                if i != items.count - 1 {
                    switch items[i + 1] {
                    case .action, .custom:
                        let separatorNode = ASDisplayNode()
                        separatorNode.backgroundColor = presentationData.theme.contextMenu.itemSeparatorColor
                        itemNodes.append(.itemSeparator(separatorNode))
                    default:
                        break
                    }
                }
            case let .custom(item, _):
                itemNodes.append(.custom(item.node(presentationData: presentationData, getController: getController, actionSelected: actionSelected)))
                if i != items.count - 1 {
                    switch items[i + 1] {
                    case .action, .custom:
                        let separatorNode = ASDisplayNode()
                        separatorNode.backgroundColor = presentationData.theme.contextMenu.itemSeparatorColor
                        itemNodes.append(.itemSeparator(separatorNode))
                    default:
                        break
                    }
                }
            case .separator:
                let separatorNode = ASDisplayNode()
                separatorNode.backgroundColor = presentationData.theme.contextMenu.sectionSeparatorColor
                itemNodes.append(.separator(separatorNode))
            }
        }
        
        self.itemNodes = itemNodes
        
        super.init()

        requestUpdateAction = { [weak self] id, action in
            guard let strongSelf = self else {
                return
            }
            loop: for itemNode in strongSelf.itemNodes {
                switch itemNode {
                case let .action(contextActionNode):
                    if contextActionNode.action.id == id {
                        contextActionNode.updateAction(item: action)
                        break loop
                    }
                default:
                    break
                }
            }
        }

        self.addSubnode(self.containerNode)
        
        self.itemNodes.forEach({ itemNode in
            switch itemNode {
            case let .action(actionNode):
                actionNode.isUserInteractionEnabled = false
                self.containerNode.addSubnode(actionNode)
            case let .custom(itemNode):
                self.containerNode.addSubnode(itemNode)
            case let .itemSeparator(separatorNode):
                self.containerNode.addSubnode(separatorNode)
            case let .separator(separatorNode):
                self.containerNode.addSubnode(separatorNode)
            }
        })
        
        let gesture = ContextActionsSelectionGestureRecognizer(target: nil, action: nil)
        self.gesture = gesture
        gesture.updateLocation = { [weak self] point, moved in
            guard let strongSelf = self else {
                return
            }
            var actionNode = strongSelf.actionNode(at: point)
            if let actionNodeValue = actionNode, !actionNodeValue.isActionEnabled {
                actionNode = nil
            }
            if actionNode !== strongSelf.currentHighlightedActionNode {
                if actionNode != nil, moved {
                    strongSelf.feedbackTap()
                }
                strongSelf.currentHighlightedActionNode?.setIsHighlighted(false)
            }
            strongSelf.currentHighlightedActionNode = actionNode
            actionNode?.setIsHighlighted(true)
        }
        gesture.completed = { [weak self] performAction in
            guard let strongSelf = self else {
                return
            }
            if let currentHighlightedActionNode = strongSelf.currentHighlightedActionNode {
                strongSelf.currentHighlightedActionNode = nil
                currentHighlightedActionNode.setIsHighlighted(false)
                if performAction {
                    currentHighlightedActionNode.performAction()
                }
            }
        }
        self.view.addGestureRecognizer(gesture)
        gesture.isEnabled = self.panSelectionGestureEnabled
    }
    
    func updateLayout(widthClass: ContainerViewLayoutSizeClass, constrainedWidth: CGFloat, constrainedHeight: CGFloat, minimalWidth: CGFloat?, transition: ContainedViewLayoutTransition) -> CGSize {
        var minActionsWidth: CGFloat = 250.0
        if let minimalWidth = minimalWidth, minimalWidth > minActionsWidth {
            minActionsWidth = minimalWidth
        }
        
        switch widthClass {
        case .compact:
            minActionsWidth = max(minActionsWidth, floor(constrainedWidth / 3.0))
            if let effectView = self.effectView {
                self.effectView = nil
                effectView.removeFromSuperview()
            }
        case .regular:
            if self.effectView == nil {
                let effectView: UIVisualEffectView
                if #available(iOS 13.0, *) {
                    if self.presentationData.theme.rootController.keyboardColor == .dark {
                        effectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterialDark))
                    } else {
                        effectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterialLight))
                    }
                } else if #available(iOS 10.0, *) {
                    effectView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
                } else {
                    effectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
                }
                self.effectView = effectView
                self.containerNode.view.insertSubview(effectView, at: 0)
            }
        }
        minActionsWidth = min(minActionsWidth, constrainedWidth)
        let separatorHeight: CGFloat = 8.0
        
        var maxWidth: CGFloat = 0.0
        var contentHeight: CGFloat = 0.0
        var heightsAndCompletions: [(CGFloat, (CGSize, ContainedViewLayoutTransition) -> Void)?] = []
        for i in 0 ..< self.itemNodes.count {
            switch self.itemNodes[i] {
            case let .action(itemNode):
                let previous: ContextActionSibling
                let next: ContextActionSibling
                if i == 0 {
                    previous = .none
                } else if case .separator = self.itemNodes[i - 1] {
                    previous = .separator
                } else {
                    previous = .item
                }
                if i == self.itemNodes.count - 1 {
                    next = .none
                } else if case .separator = self.itemNodes[i + 1] {
                    next = .separator
                } else {
                    next = .item
                }
                let (minSize, complete) = itemNode.updateLayout(constrainedWidth: constrainedWidth, previous: previous, next: next)
                maxWidth = max(maxWidth, minSize.width)
                heightsAndCompletions.append((minSize.height, complete))
                contentHeight += minSize.height
            case let .custom(itemNode):
                let (minSize, complete) = itemNode.updateLayout(constrainedWidth: constrainedWidth, constrainedHeight: constrainedHeight)
                maxWidth = max(maxWidth, minSize.width)
                heightsAndCompletions.append((minSize.height, complete))
                contentHeight += minSize.height
            case .itemSeparator:
                heightsAndCompletions.append(nil)
                contentHeight += UIScreenPixel
            case .separator:
                heightsAndCompletions.append(nil)
                contentHeight += separatorHeight
            }
        }
        
        maxWidth = max(maxWidth, minActionsWidth)
        
        var verticalOffset: CGFloat = 0.0
        for i in 0 ..< heightsAndCompletions.count {
            switch self.itemNodes[i] {
            case let .action(itemNode):
                if let (itemHeight, itemCompletion) = heightsAndCompletions[i] {
                    let itemSize = CGSize(width: maxWidth, height: itemHeight)
                    transition.updateFrame(node: itemNode, frame: CGRect(origin: CGPoint(x: 0.0, y: verticalOffset), size: itemSize))
                    itemCompletion(itemSize, transition)
                    verticalOffset += itemHeight
                }
            case let .custom(itemNode):
                if let (itemHeight, itemCompletion) = heightsAndCompletions[i] {
                    let itemSize = CGSize(width: maxWidth, height: itemHeight)
                    transition.updateFrame(node: itemNode, frame: CGRect(origin: CGPoint(x: 0.0, y: verticalOffset), size: itemSize))
                    itemCompletion(itemSize, transition)
                    verticalOffset += itemHeight
                }
            case let .itemSeparator(separatorNode):
                transition.updateFrame(node: separatorNode, frame: CGRect(origin: CGPoint(x: 0.0, y: verticalOffset), size: CGSize(width: maxWidth, height: UIScreenPixel)))
                verticalOffset += UIScreenPixel
            case let .separator(separatorNode):
                transition.updateFrame(node: separatorNode, frame: CGRect(origin: CGPoint(x: 0.0, y: verticalOffset), size: CGSize(width: maxWidth, height: separatorHeight)))
                verticalOffset += separatorHeight
            }
        }
        
        let size = CGSize(width: maxWidth, height: verticalOffset)
        let bounds = CGRect(origin: CGPoint(), size: size)
        
        transition.updateFrame(node: self.containerNode, frame: bounds)
        if let effectView = self.effectView {
            transition.updateFrame(view: effectView, frame: bounds)
        }
        return size
    }
    
    func updateTheme(presentationData: PresentationData) {
        for itemNode in self.itemNodes {
            switch itemNode {
            case let .action(action):
                action.updateTheme(presentationData: presentationData)
            case let .custom(item):
                item.updateTheme(presentationData: presentationData)
            case let .separator(separator):
                separator.backgroundColor = presentationData.theme.contextMenu.sectionSeparatorColor
            case let .itemSeparator(itemSeparator):
                itemSeparator.backgroundColor = presentationData.theme.contextMenu.itemSeparatorColor
            }
        }
        
        self.containerNode.backgroundColor = presentationData.theme.contextMenu.backgroundColor
    }
    
    func actionNode(at point: CGPoint) -> ContextActionNodeProtocol? {
        for itemNode in self.itemNodes {
            switch itemNode {
            case let .action(actionNode):
                if actionNode.frame.contains(point) {
                    return actionNode
                }
            case let .custom(node):
                if let node = node as? ContextActionNodeProtocol, node.frame.contains(point) {
                    return node.actionNode(at: self.convert(point, to: node))
                }
            default:
                break
            }
        }
        return nil
    }
}

final class InnerTextSelectionTipContainerNode: ASDisplayNode {
    private let presentationData: PresentationData
    let shadowNode: ASImageNode
    private let backgroundNode: ASDisplayNode
    private var effectView: UIVisualEffectView?
    private let highlightBackgroundNode: ASDisplayNode
    private let buttonNode: HighlightTrackingButtonNode
    private let textNode: TextNodeWithEntities
    private var textSelectionNode: TextSelectionNode?
    private let iconNode: ASImageNode
    private let placeholderNode: ASDisplayNode
    
    var tip: ContextController.Tip
    
    private let text: String
    private var arguments: TextNodeWithEntities.Arguments?
    private var file: TelegramMediaFile?
    private let targetSelectionIndex: Int?
    
    private var hapticFeedback: HapticFeedback?
    
    private var action: (() -> Void)?
    var requestDismiss: (@escaping () -> Void) -> Void = { _ in }
    
    init(presentationData: PresentationData, tip: ContextController.Tip) {
        self.tip = tip
        self.presentationData = presentationData
        
        self.shadowNode = ASImageNode()
        self.shadowNode.displaysAsynchronously = false
        self.shadowNode.displayWithoutProcessing = true
        self.shadowNode.image = UIImage(bundleImageName: "Components/Context Menu/Shadow")?.stretchableImage(withLeftCapWidth: 60, topCapHeight: 60)
        self.shadowNode.contentMode = .scaleToFill
        self.shadowNode.isHidden = true
        
        self.backgroundNode = ASDisplayNode()
        
        self.highlightBackgroundNode = ASDisplayNode()
        self.highlightBackgroundNode.isAccessibilityElement = false
        self.highlightBackgroundNode.alpha = 0.0
        
        self.buttonNode = HighlightTrackingButtonNode()
        
        self.textNode = TextNodeWithEntities()
        self.textNode.textNode.displaysAsynchronously = false
        self.textNode.textNode.isUserInteractionEnabled = false

        var isUserInteractionEnabled = false
        var icon: UIImage?
        switch tip {
        case .textSelection:
            var rawText = self.presentationData.strings.ChatContextMenu_TextSelectionTip
            
            if let range = rawText.range(of: "|") {
                let _rawText = rawText
                rawText.removeSubrange(range)
                self.text = rawText
                self.targetSelectionIndex = NSRange(range, in: _rawText).lowerBound
            } else {
                self.text = rawText
                self.targetSelectionIndex = 1
            }
            icon = UIImage(bundleImageName: "Chat/Context Menu/Tip")
        case .messageViewsPrivacy:
            self.text = self.presentationData.strings.ChatContextMenu_MessageViewsPrivacyTip
            self.targetSelectionIndex = nil
            icon = UIImage(bundleImageName: "Chat/Context Menu/Tip")
        case let .messageCopyProtection(isChannel):
            self.text = isChannel ? self.presentationData.strings.Conversation_CopyProtectionInfoChannel : self.presentationData.strings.Conversation_CopyProtectionInfoGroup
            self.targetSelectionIndex = nil
            icon = UIImage(bundleImageName: "Chat/Context Menu/ReportCopyright")
        case let .animatedEmoji(text, arguments, file, action):
            self.action = action
            self.text = text ?? ""
            self.arguments = arguments
            self.file = file
            self.targetSelectionIndex = nil
            icon = nil
            isUserInteractionEnabled = text != nil
        case let .notificationTopicExceptions(text, action):
            self.action = action
            self.text = text
            self.targetSelectionIndex = nil
            icon = nil
            isUserInteractionEnabled = action != nil
        }
        
        self.iconNode = ASImageNode()
        self.iconNode.displaysAsynchronously = false
        self.iconNode.displayWithoutProcessing = true
        self.iconNode.image = generateTintedImage(image: icon, color: presentationData.theme.contextMenu.primaryColor)
        
        self.placeholderNode = ASDisplayNode()
        self.placeholderNode.clipsToBounds = true
        self.placeholderNode.cornerRadius = 4.0
        self.placeholderNode.isUserInteractionEnabled = false
        
        super.init()
        
        self.backgroundNode.backgroundColor = presentationData.theme.contextMenu.backgroundColor
        self.backgroundNode.clipsToBounds = true
        self.backgroundNode.cornerRadius = 14.0
        
        self.highlightBackgroundNode.clipsToBounds = true
        self.highlightBackgroundNode.cornerRadius = 14.0
        
        let textSelectionNode = TextSelectionNode(theme: TextSelectionTheme(selection: presentationData.theme.contextMenu.primaryColor.withAlphaComponent(0.15), knob: presentationData.theme.contextMenu.primaryColor, knobDiameter: 8.0), strings: presentationData.strings, textNode: self.textNode.textNode, updateIsActive: { _ in
        }, present: { _, _ in
        }, rootNode: self, performAction: { _, _ in
        })
        self.textSelectionNode = textSelectionNode
        
        self.addSubnode(self.backgroundNode)
        self.addSubnode(self.highlightBackgroundNode)
        self.addSubnode(self.textNode.textNode)
        self.addSubnode(self.iconNode)
        self.addSubnode(self.placeholderNode)
        
        self.textSelectionNode.flatMap(self.addSubnode)
        
        self.addSubnode(textSelectionNode.highlightAreaNode)
        
        self.addSubnode(self.buttonNode)
        
        self.buttonNode.highligthedChanged = { [weak self] highlighted in
            guard let strongSelf = self else {
                return
            }
            strongSelf.isButtonHighlighted = highlighted
            strongSelf.updateHighlight(animated: false)
        }
        
        self.buttonNode.addTarget(self, action: #selector(self.pressed), forControlEvents: .touchUpInside)
        
        let shimmeringForegroundColor: UIColor
        if presentationData.theme.overallDarkAppearance {
            let backgroundColor = presentationData.theme.contextMenu.backgroundColor.blitOver(presentationData.theme.list.plainBackgroundColor, alpha: 1.0)
            shimmeringForegroundColor = presentationData.theme.contextMenu.primaryColor.blitOver(backgroundColor, alpha: 0.1)
        } else {
            shimmeringForegroundColor = presentationData.theme.contextMenu.primaryColor.withMultipliedAlpha(0.07)
        }
        
        self.placeholderNode.backgroundColor = shimmeringForegroundColor
        
        self.isUserInteractionEnabled = isUserInteractionEnabled
    }
    
    @objc func pressed() {
        self.requestDismiss({
            self.action?()
        })
    }
    
    func animateTransitionInside(other: InnerTextSelectionTipContainerNode) {
        let nodes: [ASDisplayNode] = [
            self.textNode.textNode,
            self.iconNode,
            self.placeholderNode
        ]
        
        for node in nodes {
            other.addSubnode(node)
            node.layer.animateAlpha(from: node.alpha, to: 0.0, duration: 0.2, removeOnCompletion: false, completion: { [weak node] _ in
                node?.removeFromSupernode()
            })
        }
    }
    
    func animateContentIn() {
        let nodes: [ASDisplayNode] = [
            self.textNode.textNode,
            self.iconNode
        ]
        
        for node in nodes {
            node.layer.animateAlpha(from: 0.0, to: node.alpha, duration: 0.25)
        }
    }
    
    func updateLayout(widthClass: ContainerViewLayoutSizeClass, presentation: ContextControllerActionsStackNode.Presentation, width: CGFloat, transition: ContainedViewLayoutTransition) -> CGSize {
        var needsBlur = false
        if case .regular = widthClass {
            needsBlur = true
        } else if case .inline = presentation {
            needsBlur = true
        }
        
        if !needsBlur {
            if let effectView = self.effectView {
                self.effectView = nil
                effectView.removeFromSuperview()
            }
        } else {
            if self.effectView == nil {
                let effectView: UIVisualEffectView
                if #available(iOS 13.0, *) {
                    if self.presentationData.theme.overallDarkAppearance {
                        effectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterialDark))
                    } else {
                        effectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterialLight))
                    }
                } else if #available(iOS 10.0, *) {
                    effectView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
                } else {
                    effectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
                }
                effectView.clipsToBounds = true
                effectView.layer.cornerRadius = self.backgroundNode.cornerRadius
                self.effectView = effectView
                self.view.insertSubview(effectView, at: 0)
            }
        }
        
        let verticalInset: CGFloat = 10.0
        let horizontalInset: CGFloat = 16.0
        let standardIconWidth: CGFloat = 32.0
        let iconSideInset: CGFloat = 12.0
        
        let textFont = Font.regular(floor(presentationData.listsFontSize.baseDisplaySize * 14.0 / 17.0))
        let boldTextFont = Font.bold(floor(presentationData.listsFontSize.baseDisplaySize * 14.0 / 17.0))
        let textColor = self.presentationData.theme.contextMenu.primaryColor
        let accentColor = self.presentationData.theme.contextMenu.badgeFillColor
        
        let iconSize = self.iconNode.image?.size ?? CGSize(width: 16.0, height: 16.0)
                
        let text = self.text.replacingOccurrences(of: "#", with: "# ")
        let attributedText = NSMutableAttributedString(attributedString: parseMarkdownIntoAttributedString(text, attributes: MarkdownAttributes(body: MarkdownAttributeSet(font: textFont, textColor: textColor), bold: MarkdownAttributeSet(font: boldTextFont, textColor: textColor), link: MarkdownAttributeSet(font: boldTextFont, textColor: accentColor), linkAttribute: { _ in
            return nil
        })))
        if let file = self.file {
            let range = (attributedText.string as NSString).range(of: "#")
            if range.location != NSNotFound {
                attributedText.addAttribute(ChatTextInputAttributes.customEmoji, value: ChatTextInputTextCustomEmojiAttribute(interactivelySelectedFromPackId: nil, fileId: file.fileId.id, file: file), range: range)
            }
        }
        
        let shimmeringForegroundColor: UIColor
        if presentationData.theme.overallDarkAppearance {
            let backgroundColor = presentationData.theme.contextMenu.backgroundColor.blitOver(presentationData.theme.list.plainBackgroundColor, alpha: 1.0)
            shimmeringForegroundColor = presentationData.theme.contextMenu.primaryColor.blitOver(backgroundColor, alpha: 0.1)
        } else {
            shimmeringForegroundColor = presentationData.theme.contextMenu.primaryColor.withMultipliedAlpha(0.07)
        }
        
        let textRightInset: CGFloat
        if let _ = self.iconNode.image {
            textRightInset = iconSize.width - 8.0
        } else {
            textRightInset = 0.0
        }
        
        let makeTextLayout = TextNodeWithEntities.asyncLayout(self.textNode)
        let (textLayout, textApply) = makeTextLayout(TextNodeLayoutArguments(attributedString: attributedText, backgroundColor: nil, minimumNumberOfLines: 0, maximumNumberOfLines: 0, truncationType: .end, constrainedSize: CGSize(width: width - horizontalInset * 2.0 - textRightInset, height: .greatestFiniteMagnitude), alignment: .left, lineSpacing: 0.0, cutout: nil, insets: UIEdgeInsets(), lineColor: nil, textShadowColor: nil, textStroke: nil))
        let _ = textApply(self.arguments?.withUpdatedPlaceholderColor(shimmeringForegroundColor))
        
        let textFrame = CGRect(origin: CGPoint(x: horizontalInset, y: verticalInset), size: textLayout.size)
        transition.updateFrame(node: self.textNode.textNode, frame: textFrame)
        if textFrame.size.height.isZero {
            self.textNode.textNode.alpha = 0.0
        } else if self.textNode.textNode.alpha.isZero {
            self.textNode.textNode.alpha = 1.0
            self.textNode.textNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.2)
            self.placeholderNode.layer.animateAlpha(from: self.placeholderNode.alpha, to: 1.0, duration: 0.2)
        }
        self.textNode.visibilityRect = CGRect.infinite
        
        var contentHeight = textLayout.size.height
        if contentHeight.isZero {
            contentHeight = 32.0
        }
        
        let size = CGSize(width: width, height: contentHeight + verticalInset * 2.0)
        
        let lineHeight: CGFloat = 8.0
        transition.updateFrame(node: self.placeholderNode, frame: CGRect(origin: CGPoint(x: horizontalInset, y: floorToScreenPixels((size.height - lineHeight) / 2.0)), size: CGSize(width: width - horizontalInset * 2.0, height: lineHeight)))
        transition.updateAlpha(node: self.placeholderNode, alpha: textFrame.height.isZero ? 1.0 : 0.0)
        
        let iconFrame = CGRect(origin: CGPoint(x: size.width - standardIconWidth - iconSideInset + floor((standardIconWidth - iconSize.width) / 2.0), y: floor((size.height - iconSize.height) / 2.0)), size: iconSize)
        transition.updateFrame(node: self.iconNode, frame: iconFrame)
        
        if let textSelectionNode = self.textSelectionNode {
            transition.updateFrame(node: textSelectionNode, frame: textFrame)
            textSelectionNode.highlightAreaNode.frame = textFrame
        }
        
        switch presentation {
        case .modal:
            self.shadowNode.isHidden = true
        case .inline:
            self.shadowNode.isHidden = false
        }
        
        if let effectView = self.effectView {
            transition.updateFrame(view: effectView, frame: CGRect(origin: CGPoint(), size: size))
        }
        
        self.highlightBackgroundNode.backgroundColor = presentationData.theme.contextMenu.itemHighlightedBackgroundColor
        
        return size
    }
    
    func setActualSize(size: CGSize, transition: ContainedViewLayoutTransition) {
        transition.updateFrame(node: self.backgroundNode, frame: CGRect(origin: CGPoint(), size: size))
        self.highlightBackgroundNode.frame = CGRect(origin: CGPoint(), size: size)
        self.buttonNode.frame = CGRect(origin: CGPoint(), size: size)
    }
    
    func updateTheme(presentationData: PresentationData) {
        self.backgroundColor = presentationData.theme.contextMenu.backgroundColor
    }
    
    func animateIn() {
        if let textSelectionNode = self.textSelectionNode, let targetSelectionIndex = self.targetSelectionIndex {
            textSelectionNode.pretendInitiateSelection()
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5, execute: { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.textSelectionNode?.pretendExtendSelection(to: targetSelectionIndex)
            })
        }
    }
    
    func updateHighlight(animated: Bool) {
        if self.isButtonHighlighted || self.isHighlighted {
            self.highlightBackgroundNode.alpha = 1.0
        } else {
            if animated {
                let previousAlpha = self.highlightBackgroundNode.alpha
                self.highlightBackgroundNode.alpha = 0.0
                self.highlightBackgroundNode.layer.animateAlpha(from: previousAlpha, to: 0.0, duration: 0.2)
            } else {
                self.highlightBackgroundNode.alpha = 0.0
            }
        }
    }
    
    private var isButtonHighlighted = false
    private var isHighlighted = false
    func setHighlighted(_ highlighted: Bool) {
        guard self.isHighlighted != highlighted else {
            return
        }
        self.isHighlighted = highlighted
        
        if highlighted {
            if self.hapticFeedback == nil {
                self.hapticFeedback = HapticFeedback()
            }
            self.hapticFeedback?.tap()
        }
        
        self.updateHighlight(animated: false)
    }
    
    func highlightGestureMoved(location: CGPoint) {
        if self.bounds.contains(location) && self.isUserInteractionEnabled {
            self.setHighlighted(true)
        } else {
            self.setHighlighted(false)
        }
    }
    
    func highlightGestureFinished(performAction: Bool) {
        if self.isHighlighted {
            self.setHighlighted(false)
            if performAction {
                self.pressed()
            }
        }
    }
}

final class ContextActionsContainerNode: ASDisplayNode {
    private let presentationData: PresentationData
    private let getController: () -> ContextControllerProtocol?
    private let blurBackground: Bool
    private let shadowNode: ASImageNode
    private let additionalShadowNode: ASImageNode?
    private let additionalActionsNode: InnerActionsContainerNode?
    private let actionsNode: InnerActionsContainerNode
    private let scrollNode: ASScrollNode
    
    private var tip: ContextController.Tip?
    private var textSelectionTipNode: InnerTextSelectionTipContainerNode?
    private var textSelectionTipNodeDisposable: Disposable?
    
    var panSelectionGestureEnabled: Bool = true {
        didSet {
            if self.panSelectionGestureEnabled != oldValue {
                self.actionsNode.panSelectionGestureEnabled = self.panSelectionGestureEnabled
            }
        }
    }
    
    var hasAdditionalActions: Bool {
        return self.additionalActionsNode != nil
    }
    
    init(presentationData: PresentationData, items: ContextController.Items, getController: @escaping () -> ContextControllerProtocol?, actionSelected: @escaping (ContextMenuActionResult) -> Void, requestLayout: @escaping () -> Void, feedbackTap: @escaping () -> Void, blurBackground: Bool) {
        self.presentationData = presentationData
        self.getController = getController
        self.blurBackground = blurBackground
        self.shadowNode = ASImageNode()
        self.shadowNode.displaysAsynchronously = false
        self.shadowNode.displayWithoutProcessing = true
        self.shadowNode.image = UIImage(bundleImageName: "Components/Context Menu/Shadow")?.stretchableImage(withLeftCapWidth: 60, topCapHeight: 60)
        self.shadowNode.contentMode = .scaleToFill
        self.shadowNode.isHidden = true
        
        var items = items
        if case var .list(itemList) = items.content, let firstItem = itemList.first, case let .custom(_, additional) = firstItem, additional {
            let additionalShadowNode = ASImageNode()
            additionalShadowNode.displaysAsynchronously = false
            additionalShadowNode.displayWithoutProcessing = true
            additionalShadowNode.image = self.shadowNode.image
            additionalShadowNode.contentMode = .scaleToFill
            additionalShadowNode.isHidden = true
            self.additionalShadowNode = additionalShadowNode
            
            self.additionalActionsNode = InnerActionsContainerNode(presentationData: presentationData, items: [firstItem], getController: getController, actionSelected: actionSelected, requestLayout: requestLayout, feedbackTap: feedbackTap, blurBackground: blurBackground)
            itemList.removeFirst()
            items.content = .list(itemList)
        } else {
            self.additionalShadowNode = nil
            self.additionalActionsNode = nil
        }
        
        var itemList: [ContextMenuItem] = []
        if case let .list(list) = items.content {
            itemList = list
        }
        
        self.actionsNode = InnerActionsContainerNode(presentationData: presentationData, items: itemList, getController: getController, actionSelected: actionSelected, requestLayout: requestLayout, feedbackTap: feedbackTap, blurBackground: blurBackground)
        
        self.tip = items.tip
        
        self.scrollNode = ASScrollNode()
        self.scrollNode.canCancelAllTouchesInViews = true
        self.scrollNode.view.delaysContentTouches = false
        self.scrollNode.view.showsVerticalScrollIndicator = false
        if #available(iOS 11.0, *) {
            self.scrollNode.view.contentInsetAdjustmentBehavior = .never
        }
        
        super.init()
        
        self.addSubnode(self.shadowNode)
        self.additionalShadowNode.flatMap(self.addSubnode)
        self.additionalActionsNode.flatMap(self.scrollNode.addSubnode)
        self.scrollNode.addSubnode(self.actionsNode)
        self.addSubnode(self.scrollNode)
        
        if let tipSignal = items.tipSignal {
            self.textSelectionTipNodeDisposable = (tipSignal
            |> deliverOnMainQueue).start(next: { [weak self] tip in
                guard let strongSelf = self else {
                    return
                }
                
                strongSelf.tip = tip
                requestLayout()
            })
        }
    }
    
    deinit {
        self.textSelectionTipNodeDisposable?.dispose()
    }
    
    func updateLayout(widthClass: ContainerViewLayoutSizeClass, presentation: ContextControllerActionsStackNode.Presentation, constrainedWidth: CGFloat, constrainedHeight: CGFloat, transition: ContainedViewLayoutTransition) -> CGSize {
        var widthClass = widthClass
        if !self.blurBackground {
            widthClass = .regular
        }
        
        var contentSize = CGSize()
        let actionsSize = self.actionsNode.updateLayout(widthClass: widthClass, constrainedWidth: constrainedWidth, constrainedHeight: constrainedHeight, minimalWidth: nil, transition: transition)
            
        if let additionalActionsNode = self.additionalActionsNode, let additionalShadowNode = self.additionalShadowNode {
            let additionalActionsSize = additionalActionsNode.updateLayout(widthClass: widthClass, constrainedWidth: actionsSize.width, constrainedHeight: constrainedHeight, minimalWidth: actionsSize.width, transition: transition)
            contentSize = additionalActionsSize
            
            let bounds = CGRect(origin: CGPoint(), size: additionalActionsSize)
            transition.updateFrame(node: additionalShadowNode, frame: bounds.insetBy(dx: -30.0, dy: -30.0))
            additionalShadowNode.isHidden = widthClass == .compact
            
            transition.updateFrame(node: additionalActionsNode, frame: CGRect(origin: CGPoint(), size: additionalActionsSize))
            contentSize.height += 8.0
        }
        
        let bounds = CGRect(origin: CGPoint(x: 0.0, y: contentSize.height), size: actionsSize)
        transition.updateFrame(node: self.shadowNode, frame: bounds.insetBy(dx: -30.0, dy: -30.0))
        self.shadowNode.isHidden = widthClass == .compact
        
        contentSize.width = max(contentSize.width, actionsSize.width)
        contentSize.height += actionsSize.height
        
        transition.updateFrame(node: self.actionsNode, frame: bounds)
        
        if let tip = self.tip {
            if let textSelectionTipNode = self.textSelectionTipNode, textSelectionTipNode.tip == tip {
            } else {
                if let textSelectionTipNode = self.textSelectionTipNode {
                    self.textSelectionTipNode = nil
                    textSelectionTipNode.removeFromSupernode()
                }
                
                let textSelectionTipNode = InnerTextSelectionTipContainerNode(presentationData: self.presentationData, tip: tip)
                let getController = self.getController
                textSelectionTipNode.requestDismiss = { completion in
                    getController()?.dismiss(completion: completion)
                }
                self.textSelectionTipNode = textSelectionTipNode
                self.scrollNode.addSubnode(textSelectionTipNode)
            }
        } else {
            if let textSelectionTipNode = self.textSelectionTipNode {
                self.textSelectionTipNode = nil
                textSelectionTipNode.removeFromSupernode()
            }
        }
        
        if let textSelectionTipNode = self.textSelectionTipNode {
            contentSize.height += 8.0
            let textSelectionTipSize = textSelectionTipNode.updateLayout(widthClass: widthClass, presentation: presentation, width: actionsSize.width, transition: transition)
            transition.updateFrame(node: textSelectionTipNode, frame: CGRect(origin: CGPoint(x: 0.0, y: contentSize.height), size: textSelectionTipSize))
            textSelectionTipNode.setActualSize(size: textSelectionTipSize, transition: transition)
            contentSize.height += textSelectionTipSize.height
        }
        
        return contentSize
    }
    
    func updateSize(containerSize: CGSize, contentSize: CGSize) {
        self.scrollNode.view.contentSize = contentSize
        self.scrollNode.frame = CGRect(origin: CGPoint(), size: containerSize)
    }
    
    func actionNode(at point: CGPoint) -> ContextActionNodeProtocol? {
        return self.actionsNode.actionNode(at: self.view.convert(point, to: self.actionsNode.view))
    }
    
    func updateTheme(presentationData: PresentationData) {
        self.actionsNode.updateTheme(presentationData: presentationData)
        self.textSelectionTipNode?.updateTheme(presentationData: presentationData)
    }
    
    func animateIn() {
        self.textSelectionTipNode?.animateIn()
    }
    
    func animateOut(offset: CGFloat, transition: ContainedViewLayoutTransition) {
        guard let additionalActionsNode = self.additionalActionsNode, let additionalShadowNode = self.additionalShadowNode else {
            return
        }
        
        transition.animatePosition(node: additionalActionsNode, to: CGPoint(x: 0.0, y: offset / 2.0), additive: true)
        transition.animatePosition(node: additionalShadowNode, to: CGPoint(x: 0.0, y: offset / 2.0), additive: true)
        additionalActionsNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.15, removeOnCompletion: false)
        additionalShadowNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.15, removeOnCompletion: false)
        additionalActionsNode.layer.animateScale(from: 1.0, to: 0.75, duration: 0.15, removeOnCompletion: false)
        additionalShadowNode.layer.animateScale(from: 1.0, to: 0.75, duration: 0.15, removeOnCompletion: false)
    }
}
