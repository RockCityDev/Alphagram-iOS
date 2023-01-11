






import Foundation

public extension EKAttributes {
    
    
    static var `default` = EKAttributes()
    
    
    static var toast: EKAttributes {
        var attributes = EKAttributes()
        attributes.positionConstraints = .fullWidth
        attributes.positionConstraints.safeArea = .empty(fillSafeArea: true)
        attributes.windowLevel = .statusBar
        attributes.scroll = .edgeCrossingDisabled(swipeable: true)
        attributes.popBehavior = .animated(animation: .translation)
        return attributes
    }
    
    
    static var float: EKAttributes {
        var attributes = EKAttributes()
        attributes.positionConstraints = .float
        attributes.roundCorners = .all(radius: 10)
        attributes.positionConstraints.safeArea = .empty(fillSafeArea: false)
        attributes.windowLevel = .statusBar
        return attributes
    }
    
    
    static var topFloat: EKAttributes {
        var attributes = float
        attributes.position = .top
        return attributes
    }
    
    
    static var bottomFloat: EKAttributes {
        var attributes = float
        attributes.position = .bottom
        return attributes
    }
    
    
    static var centerFloat: EKAttributes {
        var attributes = float
        attributes.position = .center
        return attributes
    }
    
    
    static var bottomToast: EKAttributes {
        var attributes = toast
        attributes.position = .bottom
        return attributes
    }
    
    
    static var topToast: EKAttributes {
        var attributes = toast
        attributes.position = .top
        return attributes
    }
    
    
    static var topNote: EKAttributes {
        var attributes = topToast
        attributes.scroll = .disabled
        attributes.windowLevel = .normal
        attributes.entryInteraction = .absorbTouches
        return attributes
    }
    
    
    static var bottomNote: EKAttributes {
        var attributes = bottomToast
        attributes.scroll = .disabled
        attributes.windowLevel = .normal
        attributes.entryInteraction = .absorbTouches
        return attributes
    }
    
    
    static var statusBar: EKAttributes {
        var attributes = topToast
        attributes.windowLevel = .statusBar
        attributes.entryInteraction = .absorbTouches
        attributes.positionConstraints.safeArea = .overridden
        return attributes
    }
}
