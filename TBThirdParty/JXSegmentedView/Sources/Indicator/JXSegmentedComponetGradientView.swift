







import UIKit

open class JXSegmentedComponetGradientView: UIView {
    open class override var layerClass: AnyClass {
        return CAGradientLayer.self
    }

    open var gradientLayer: CAGradientLayer {
        return layer as! CAGradientLayer
    }
}
