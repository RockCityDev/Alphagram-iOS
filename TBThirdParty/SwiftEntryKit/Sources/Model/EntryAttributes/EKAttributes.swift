







import Foundation
import UIKit

public struct EKAttributes {
    
    
    
    
    public var name: String?
    
    
    
    
    public var windowLevel = WindowLevel.statusBar
    
    
    public var position = Position.top

    
    public var precedence = Precedence.override(priority: .normal, dropEnqueuedEntries: false)
    
    
    public var displayDuration: DisplayDuration = 2 
    
    
    public var positionConstraints = PositionConstraints()
    
    
    
    
    public var screenInteraction = UserInteraction.forward
    
    
    public var entryInteraction = UserInteraction.dismiss

    
    public var scroll = Scroll.enabled(swipeable: true, pullbackAnimation: .jolt)
    
    
    public var hapticFeedbackType = NotificationHapticFeedback.none
    
    
    public var lifecycleEvents = LifecycleEvents()
    
    
    
    
    public var displayMode = DisplayMode.inferred
    
    
    public var entryBackground = BackgroundStyle.clear
    
    
    public var screenBackground = BackgroundStyle.clear
    
    
    public var shadow = Shadow.none
    
    
    public var roundCorners = RoundCorners.none
    
    
    public var border = Border.none
    
    
    public var statusBar = StatusBar.inferred
    
    
    
    
    public var entranceAnimation = Animation.translation
    
    
    public var exitAnimation = Animation.translation
    
    
    public var popBehavior = PopBehavior.animated(animation: .translation) {
        didSet {
            popBehavior.validate()
        }
    }

    
    public init() {}
}
