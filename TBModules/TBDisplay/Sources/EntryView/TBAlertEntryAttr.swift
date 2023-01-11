import Foundation
import UIKit
import SwiftEntryKit


public extension EKAttributes {
   
    static var tb_center_fade_alert: EKAttributes {
        var attr = EKAttributes()
        attr.windowLevel = .alerts
        attr.screenBackground = .color(color: .black.with(alpha: 0.7))
        attr.entryBackground = .color(color: .white)
        attr.position = .center
        attr.precedence = .override(priority: .normal, dropEnqueuedEntries: true)
        attr.displayDuration = .infinity
        attr.screenInteraction = .dismiss
        attr.entryInteraction = .dismiss
        attr.positionConstraints = .init(size:.init(width: .offset(value: 40), height: .intrinsic))
        attr.scroll = .disabled
        attr.roundCorners = .all(radius: 12)
        attr.entranceAnimation = .init(fade: .init(from: 0, to: 1, duration: 0.3))
        attr.exitAnimation = .init(fade: .init(from: 1, to: 0, duration: 0.3))
        attr.popBehavior = .animated(animation: .init(fade: .init(from: 1, to: 0, duration: 0.3)))
        return attr
    }
    
    static var tb_center_fade_alert_indicator: EKAttributes {
        var attr = self.tb_center_fade_alert
        attr.screenInteraction = .absorbTouches
        attr.entryInteraction = .absorbTouches
        return attr
    }
}


