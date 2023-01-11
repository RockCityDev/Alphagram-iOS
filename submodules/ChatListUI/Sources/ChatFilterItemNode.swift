import Foundation
import UIKit
import AsyncDisplayKit
import Display
import Postbox
import TelegramCore
import TelegramPresentationData

private final class ItemNodeDeleteButtonNode: HighlightableButtonNode {
    private let pressed: () -> Void
    
    private let contentImageNode: ASImageNode
    
    private var theme: PresentationTheme?
    
    init(pressed: @escaping () -> Void) {
        self.pressed = pressed
        
        self.contentImageNode = ASImageNode()
        
        super.init()
        
        self.addSubnode(self.contentImageNode)
        
        self.addTarget(self, action: #selector(self.pressedEvent), forControlEvents: .touchUpInside)
    }
    
    @objc private func pressedEvent() {
        self.pressed()
    }
    
    func update(theme: PresentationTheme) -> CGSize {
        let size = CGSize(width: 18.0, height: 18.0)
        if self.theme !== theme {
            self.theme = theme
            self.contentImageNode.image = generateImage(size, rotatedContext: { size, context in
                context.clear(CGRect(origin: CGPoint(), size: size))
                context.setFillColor(theme.rootController.navigationBar.clearButtonBackgroundColor.cgColor)
                context.fillEllipse(in: CGRect(origin: CGPoint(), size: size))
                context.setStrokeColor(theme.rootController.navigationBar.clearButtonForegroundColor.cgColor)
                context.setLineWidth(1.5)
                context.setLineCap(.round)
                context.move(to: CGPoint(x: 6.38, y: 6.38))
                context.addLine(to: CGPoint(x: 11.63, y: 11.63))
                context.strokePath()
                context.move(to: CGPoint(x: 6.38, y: 11.63))
                context.addLine(to: CGPoint(x: 11.63, y: 6.38))
                context.strokePath()
            })
        }
        
        self.contentImageNode.frame = CGRect(origin: CGPoint(), size: size)
        
        return size
    }
}

final class FilterItemNode: ASDisplayNode {
    private let pressed: (Bool) -> Void
    private let requestedDeletion: () -> Void
    
    private let extractedContainerNode: ContextExtractedContentContainingNode
    private let containerNode: ContextControllerSourceNode
    
    private let extractedBackgroundNode: ASImageNode
    private let titleContainer: ASDisplayNode
    private let titleNode: ImmediateTextNode
    private let titleActiveNode: ImmediateTextNode
    private let shortTitleContainer: ASDisplayNode
    private let shortTitleNode: ImmediateTextNode
    private let shortTitleActiveNode: ImmediateTextNode
    private let badgeContainerNode: ASDisplayNode
    private let badgeTextNode: ImmediateTextNode
    private let badgeBackgroundActiveNode: ASImageNode
    private let badgeBackgroundInactiveNode: ASImageNode
    
    private var deleteButtonNode: ItemNodeDeleteButtonNode?
    private let buttonNode: HighlightTrackingButtonNode
    
    private let activateArea: AccessibilityAreaNode
    
    private var selectionFraction: CGFloat = 0.0
    private(set) var unreadCount: Int = 0
    
    private var isReordering: Bool = false
    private var isEditing: Bool = false
    private var isDisabled: Bool = false
    
    private var theme: PresentationTheme?
    
    init(pressed: @escaping (Bool) -> Void, requestedDeletion: @escaping () -> Void, contextGesture: @escaping (ContextExtractedContentContainingNode, ContextGesture, Bool) -> Void) {
        self.pressed = pressed
        self.requestedDeletion = requestedDeletion
        
        self.extractedContainerNode = ContextExtractedContentContainingNode()
        self.containerNode = ContextControllerSourceNode()
        
        self.extractedBackgroundNode = ASImageNode()
        self.extractedBackgroundNode.alpha = 0.0
        
        let titleInset: CGFloat = 4.0
        
        self.titleContainer = ASDisplayNode()
        
        self.titleNode = ImmediateTextNode()
        self.titleNode.displaysAsynchronously = false
        self.titleNode.insets = UIEdgeInsets(top: titleInset, left: 0.0, bottom: titleInset, right: 0.0)
        
        self.titleActiveNode = ImmediateTextNode()
        self.titleActiveNode.displaysAsynchronously = false
        self.titleActiveNode.insets = UIEdgeInsets(top: titleInset, left: 0.0, bottom: titleInset, right: 0.0)
        self.titleActiveNode.alpha = 0.0
        
        self.shortTitleContainer = ASDisplayNode()
        
        self.shortTitleNode = ImmediateTextNode()
        self.shortTitleNode.displaysAsynchronously = false
        self.shortTitleNode.alpha = 0.0
        self.shortTitleNode.insets = UIEdgeInsets(top: titleInset, left: 0.0, bottom: titleInset, right: 0.0)
        
        self.shortTitleActiveNode = ImmediateTextNode()
        self.shortTitleActiveNode.displaysAsynchronously = false
        self.shortTitleActiveNode.alpha = 0.0
        self.shortTitleActiveNode.insets = UIEdgeInsets(top: titleInset, left: 0.0, bottom: titleInset, right: 0.0)
        self.shortTitleActiveNode.alpha = 0.0
        
        self.badgeContainerNode = ASDisplayNode()
        
        self.badgeTextNode = ImmediateTextNode()
        self.badgeTextNode.displaysAsynchronously = false
        
        self.badgeBackgroundActiveNode = ASImageNode()
        self.badgeBackgroundActiveNode.displaysAsynchronously = false
        self.badgeBackgroundActiveNode.displayWithoutProcessing = true
        
        self.badgeBackgroundInactiveNode = ASImageNode()
        self.badgeBackgroundInactiveNode.displaysAsynchronously = false
        self.badgeBackgroundInactiveNode.displayWithoutProcessing = true
        
        self.buttonNode = HighlightTrackingButtonNode()
        
        self.activateArea = AccessibilityAreaNode()
        
        super.init()
        
        self.isAccessibilityElement = true
        
        self.extractedContainerNode.contentNode.addSubnode(self.extractedBackgroundNode)
        self.extractedContainerNode.contentNode.addSubnode(self.titleContainer)
        self.titleContainer.addSubnode(self.titleNode)
        self.titleContainer.addSubnode(self.titleActiveNode)
        self.extractedContainerNode.contentNode.addSubnode(self.shortTitleContainer)
        self.shortTitleContainer.addSubnode(self.shortTitleNode)
        self.shortTitleContainer.addSubnode(self.shortTitleActiveNode)
        self.badgeContainerNode.addSubnode(self.badgeBackgroundInactiveNode)
        self.badgeContainerNode.addSubnode(self.badgeBackgroundActiveNode)
        self.badgeContainerNode.addSubnode(self.badgeTextNode)
        self.extractedContainerNode.contentNode.addSubnode(self.badgeContainerNode)
        self.extractedContainerNode.contentNode.addSubnode(self.buttonNode)
        
        self.containerNode.addSubnode(self.extractedContainerNode)
        self.containerNode.targetNodeForActivationProgress = self.extractedContainerNode.contentNode
        self.addSubnode(self.containerNode)
    
        self.addSubnode(self.activateArea)
        
        self.buttonNode.addTarget(self, action: #selector(self.buttonPressed), forControlEvents: .touchUpInside)
        
        self.containerNode.activated = { [weak self] gesture, _ in
            guard let strongSelf = self else {
                return
            }
            contextGesture(strongSelf.extractedContainerNode, gesture, strongSelf.isDisabled)
        }
        
        self.extractedContainerNode.willUpdateIsExtractedToContextPreview = { [weak self] isExtracted, transition in
            guard let strongSelf = self else {
                return
            }
            
            if isExtracted, let theme = strongSelf.theme {
                strongSelf.extractedBackgroundNode.image = generateStretchableFilledCircleImage(diameter: 28.0, color: theme.contextMenu.backgroundColor)
            }
            transition.updateAlpha(node: strongSelf.extractedBackgroundNode, alpha: isExtracted ? 1.0 : 0.0, completion: { _ in
                if !isExtracted {
                    self?.extractedBackgroundNode.image = nil
                }
            })
        }
    }
    
    @objc private func buttonPressed() {
        self.pressed(self.isDisabled)
    }
    
    func updateSelectedStatus(_ isSelected: Bool, transition: ContainedViewLayoutTransition) {
        let title = self.titleNode.attributedText?.string ?? ""
        let titleColor = isSelected ? UIColor.white : UIColor(rgb: 0x56565C)
        self.titleNode.attributedText = NSAttributedString(string: title, font: Font.medium(14.0), textColor: titleColor)
        let unreadCount = self.badgeTextNode.attributedText?.string ?? ""
        let badgeTextColor = isSelected ? UIColor(hexString: "#FF46BDFE")! : UIColor.white
        self.badgeTextNode.attributedText = NSAttributedString(string: unreadCount, font: Font.regular(14.0), textColor: badgeTextColor)
        let _ = self.badgeTextNode.updateLayout(CGSize(width: 200.0, height: .greatestFiniteMagnitude))
        let badgeBgColor = isSelected ? UIColor.white : UIColor(hexString: "#FF707070")!
        self.badgeBackgroundActiveNode.image = generateStretchableFilledCircleImage(diameter: 18.0, color: badgeBgColor)
        self.badgeBackgroundInactiveNode.image = generateStretchableFilledCircleImage(diameter: 18.0, color: badgeBgColor)
    }
    
    func updateText(strings: PresentationStrings, title: String, shortTitle: String, unreadCount: Int, unreadHasUnmuted: Bool, isNoFilter: Bool, selectionFraction: CGFloat, isEditing: Bool, isReordering: Bool, canReorderAllChats: Bool, isDisabled: Bool, presentationData: PresentationData, transition: ContainedViewLayoutTransition) {
        self.isEditing = isEditing
        self.isDisabled = isDisabled
        
        if self.theme !== presentationData.theme {
            self.theme = presentationData.theme
            self.badgeBackgroundActiveNode.image = generateStretchableFilledCircleImage(diameter: 18.0, color: UIColor(hexString: "#FF707070")!)
            self.badgeBackgroundInactiveNode.image = generateStretchableFilledCircleImage(diameter: 18.0, color: UIColor(hexString: "#FF707070")!)
        }
        
        self.activateArea.accessibilityLabel = title
        if unreadCount > 0 {
            self.activateArea.accessibilityValue = strings.VoiceOver_Chat_UnreadMessages(Int32(unreadCount))
        } else {
            self.activateArea.accessibilityValue = ""
        }
        
        self.containerNode.isGestureEnabled = !isEditing && !isReordering
        self.buttonNode.isUserInteractionEnabled = !isEditing && !isReordering
        
        self.selectionFraction = selectionFraction
        self.unreadCount = unreadCount
        
        transition.updateAlpha(node: self.containerNode, alpha: (isReordering && isNoFilter && !canReorderAllChats) ? 0.5 : 1.0)
        
        if isReordering && !isNoFilter {
            if self.deleteButtonNode == nil {
                let deleteButtonNode = ItemNodeDeleteButtonNode(pressed: { [weak self] in
                    self?.requestedDeletion()
                })
                self.extractedContainerNode.contentNode.addSubnode(deleteButtonNode)
                self.deleteButtonNode = deleteButtonNode
                if case .animated = transition {
                    deleteButtonNode.layer.animateScale(from: 0.1, to: 1.0, duration: 0.25)
                    deleteButtonNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.25)
                }
            }
        } else if let deleteButtonNode = self.deleteButtonNode {
            self.deleteButtonNode = nil
            transition.updateTransformScale(node: deleteButtonNode, scale: 0.1)
            transition.updateAlpha(node: deleteButtonNode, alpha: 0.0, completion: { [weak deleteButtonNode] _ in
                deleteButtonNode?.removeFromSupernode()
            })
        }
        
        transition.updateAlpha(node: self.badgeContainerNode, alpha: (isEditing || isDisabled || isReordering || unreadCount == 0) ? 0.0 : 1.0)
        
        let selectionAlpha: CGFloat = selectionFraction * selectionFraction
        let deselectionAlpha: CGFloat = isDisabled ? 0.5 : 1.0
        
        transition.updateAlpha(node: self.titleNode, alpha: deselectionAlpha)
        transition.updateAlpha(node: self.titleActiveNode, alpha: selectionAlpha)
        transition.updateAlpha(node: self.shortTitleNode, alpha: deselectionAlpha)
        transition.updateAlpha(node: self.shortTitleActiveNode, alpha: selectionAlpha)
        
        self.titleNode.attributedText = NSAttributedString(string: title, font: Font.medium(14.0), textColor: UIColor(rgb: 0x56565C))
        self.titleActiveNode.attributedText = NSAttributedString(string: title, font: Font.medium(14.0), textColor: UIColor.white)
        self.shortTitleNode.attributedText = NSAttributedString(string: shortTitle, font: Font.medium(14.0), textColor: UIColor(rgb: 0x56565C))
        self.shortTitleActiveNode.attributedText = NSAttributedString(string: shortTitle, font: Font.medium(14.0), textColor: UIColor.white)
        if unreadCount != 0 {
            self.badgeTextNode.attributedText = NSAttributedString(string: "\(unreadCount)", font: Font.regular(14.0), textColor: presentationData.theme.list.itemCheckColors.foregroundColor)
            let badgeSelectionFraction: CGFloat = unreadHasUnmuted ? 1.0 : selectionFraction
            
            let badgeSelectionAlpha: CGFloat = badgeSelectionFraction
            
            
            transition.updateAlpha(node: self.badgeBackgroundActiveNode, alpha: badgeSelectionAlpha * badgeSelectionAlpha)
            
            self.badgeBackgroundInactiveNode.alpha = 1.0
        }
        
        if self.isReordering != isReordering {
            self.isReordering = isReordering
            if self.isReordering && (!isNoFilter || canReorderAllChats) {
                self.startShaking()
            } else {
                self.layer.removeAnimation(forKey: "shaking_position")
                self.layer.removeAnimation(forKey: "shaking_rotation")
            }
        }
    }
    
    func updateLayout(height: CGFloat, transition: ContainedViewLayoutTransition) -> (width: CGFloat, shortWidth: CGFloat) {
        let minWidth = 60.0
        
        let titleSize = self.titleNode.updateLayout(CGSize(width: 160.0, height: .greatestFiniteMagnitude))
        let badgeSize = self.badgeTextNode.updateLayout(CGSize(width: 200.0, height: .greatestFiniteMagnitude))
        let badgeInset: CGFloat = 4.0
        let badgeWidth = max(18.0, badgeSize.width + badgeInset * 2.0)
        let isContainBadge = self.unreadCount == 0 || self.isReordering || self.isEditing || self.isDisabled
        let totalWidth: CGFloat
        let titleFrame: CGRect
        if isContainBadge {
            totalWidth = titleSize.width - self.titleNode.insets.left - self.titleNode.insets.right + 12
            titleFrame = CGRect(x: (max(minWidth, totalWidth) - totalWidth) / 2.0 - self.titleNode.insets.left + 6, y: floor((height - titleSize.height) / 2.0), width: titleSize.width, height: titleSize.height)
        } else {
            totalWidth = titleSize.width - self.titleNode.insets.left - self.titleNode.insets.right + badgeWidth + badgeInset + 12
            titleFrame = CGRect(x: (max(minWidth, totalWidth) - totalWidth) / 2.0 - self.titleNode.insets.left + 6, y: floor((height - titleSize.height) / 2.0), width: titleSize.width, height: titleSize.height)
        }
        
        let _ = self.titleActiveNode.updateLayout(CGSize(width: 160.0, height: .greatestFiniteMagnitude))
        self.titleContainer.frame = titleFrame
        self.titleNode.frame = CGRect(origin: CGPoint(), size: titleFrame.size)
        self.titleActiveNode.frame = CGRect(origin: CGPoint(), size: titleFrame.size)
        
        let shortTitleSize = self.shortTitleNode.updateLayout(CGSize(width: 160.0, height: .greatestFiniteMagnitude))
        let shortTitleWidth = max(shortTitleSize.width - self.shortTitleNode.insets.left - self.shortTitleNode.insets.right, minWidth)
        let _ = self.shortTitleActiveNode.updateLayout(CGSize(width: 160.0, height: .greatestFiniteMagnitude))
        let shortTitleFrame = CGRect(origin: CGPoint(x:(shortTitleWidth - shortTitleSize.width) / 2.0 - self.shortTitleNode.insets.left, y: floor((height - shortTitleSize.height) / 2.0)), size: shortTitleSize)
        self.shortTitleContainer.frame = shortTitleFrame
        self.shortTitleNode.frame = CGRect(origin: CGPoint(), size: shortTitleFrame.size)
        self.shortTitleActiveNode.frame = CGRect(origin: CGPoint(), size: shortTitleFrame.size)
        
        if let deleteButtonNode = self.deleteButtonNode {
            if let theme = self.theme {
                let deleteButtonSize = deleteButtonNode.update(theme: theme)
                deleteButtonNode.frame = CGRect(origin: CGPoint(x: -deleteButtonSize.width + 3.0, y: 5.0), size: deleteButtonSize)
            }
        }
        
        let badgeBackgroundFrame = CGRect(origin: CGPoint(x: titleFrame.maxX + badgeInset, y: floor((height - 18.0) / 2.0)), size: CGSize(width: badgeWidth, height: 18.0))
        self.badgeContainerNode.frame = badgeBackgroundFrame
        self.badgeBackgroundActiveNode.frame = CGRect(origin: CGPoint(), size: badgeBackgroundFrame.size)
        self.badgeBackgroundInactiveNode.frame = CGRect(origin: CGPoint(), size: badgeBackgroundFrame.size)
        self.badgeTextNode.frame = CGRect(origin: CGPoint(x: floorToScreenPixels((badgeBackgroundFrame.width - badgeSize.width) / 2.0), y: floor((badgeBackgroundFrame.height - badgeSize.height) / 2.0)), size: badgeSize)
        
        if isContainBadge {
            if !self.isReordering {
                self.badgeContainerNode.alpha = 0.0
            }
        } else {
            if !self.isReordering {
                self.badgeContainerNode.alpha = 1.0
            }
        }
        
        return (max(totalWidth, minWidth), shortTitleWidth)
    }
    
    func updateArea(size: CGSize, sideInset: CGFloat, useShortTitle: Bool, transition: ContainedViewLayoutTransition) {
        transition.updateAlpha(node: self.titleContainer, alpha: useShortTitle ? 0.0 : 1.0)
        transition.updateAlpha(node: self.shortTitleContainer, alpha: useShortTitle ? 1.0 : 0.0)
        
        self.buttonNode.frame = CGRect(origin: CGPoint(x: -sideInset, y: 0.0), size: CGSize(width: size.width + sideInset * 2.0, height: size.height))
                
        self.extractedContainerNode.frame = CGRect(origin: CGPoint(), size: size)
        self.extractedContainerNode.contentNode.frame = CGRect(origin: CGPoint(), size: size)
        self.extractedContainerNode.contentRect = CGRect(origin: CGPoint(x: self.extractedBackgroundNode.frame.minX, y: 0.0), size: CGSize(width:self.extractedBackgroundNode.frame.width, height: size.height))
        self.containerNode.frame = CGRect(origin: CGPoint(), size: size)
        self.activateArea.frame = CGRect(origin: CGPoint(), size: size)
        
        self.hitTestSlop = UIEdgeInsets(top: 0.0, left: -sideInset, bottom: 0.0, right: -sideInset)
        self.extractedContainerNode.hitTestSlop = self.hitTestSlop
        self.extractedContainerNode.contentNode.hitTestSlop = self.hitTestSlop
        self.containerNode.hitTestSlop = self.hitTestSlop
        let extractedBackgroundHeight: CGFloat = 36.0
        let extractedBackgroundInset: CGFloat = 14.0
        self.extractedBackgroundNode.frame = CGRect(origin: CGPoint(x: -extractedBackgroundInset, y: floor((size.height - extractedBackgroundHeight) / 2.0)), size: CGSize(width: size.width + extractedBackgroundInset * 2.0, height: extractedBackgroundHeight))
    }
    
    func animateBadgeIn() {
        if !self.isReordering {
            let transition: ContainedViewLayoutTransition = .animated(duration: 0.4, curve: .spring)
            self.badgeContainerNode.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.25)
            ContainedViewLayoutTransition.immediate.updateSublayerTransformScale(node: self.badgeContainerNode, scale: 0.1)
            transition.updateSublayerTransformScale(node: self.badgeContainerNode, scale: 1.0)
        }
    }
    
    func animateBadgeOut() {
        if !self.isReordering {
            let transition: ContainedViewLayoutTransition = .animated(duration: 0.4, curve: .spring)
            self.badgeContainerNode.layer.animateAlpha(from: 1.0, to: 0.0, duration: 0.25)
            ContainedViewLayoutTransition.immediate.updateSublayerTransformScale(node: self.badgeContainerNode, scale: 1.0)
            transition.updateSublayerTransformScale(node: self.badgeContainerNode, scale: 0.1)
        }
    }
    
    private func startShaking() {
        func degreesToRadians(_ x: CGFloat) -> CGFloat {
            return .pi * x / 180.0
        }

        let duration: Double = 0.4
        let displacement: CGFloat = 1.0
        let degreesRotation: CGFloat = 2.0
        
        let negativeDisplacement = -1.0 * displacement
        let position = CAKeyframeAnimation.init(keyPath: "position")
        position.beginTime = 0.8
        position.duration = duration
        position.values = [
            NSValue(cgPoint: CGPoint(x: negativeDisplacement, y: negativeDisplacement)),
            NSValue(cgPoint: CGPoint(x: 0, y: 0)),
            NSValue(cgPoint: CGPoint(x: negativeDisplacement, y: 0)),
            NSValue(cgPoint: CGPoint(x: 0, y: negativeDisplacement)),
            NSValue(cgPoint: CGPoint(x: negativeDisplacement, y: negativeDisplacement))
        ]
        position.calculationMode = .linear
        position.isRemovedOnCompletion = false
        position.repeatCount = Float.greatestFiniteMagnitude
        position.beginTime = CFTimeInterval(Float(arc4random()).truncatingRemainder(dividingBy: Float(25)) / Float(100))
        position.isAdditive = true

        let transform = CAKeyframeAnimation.init(keyPath: "transform")
        transform.beginTime = 2.6
        transform.duration = 0.3
        transform.valueFunction = CAValueFunction(name: CAValueFunctionName.rotateZ)
        transform.values = [
            degreesToRadians(-1.0 * degreesRotation),
            degreesToRadians(degreesRotation),
            degreesToRadians(-1.0 * degreesRotation)
        ]
        transform.calculationMode = .linear
        transform.isRemovedOnCompletion = false
        transform.repeatCount = Float.greatestFiniteMagnitude
        transform.isAdditive = true
        transform.beginTime = CFTimeInterval(Float(arc4random()).truncatingRemainder(dividingBy: Float(25)) / Float(100))

        self.layer.add(position, forKey: "shaking_position")
        self.layer.add(transform, forKey: "shaking_rotation")
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let deleteButtonNode = self.deleteButtonNode {
            if deleteButtonNode.frame.insetBy(dx: -4.0, dy: -4.0).contains(point) {
                return deleteButtonNode.view
            }
        }
        return super.hitTest(point, with: event)
    }
}
