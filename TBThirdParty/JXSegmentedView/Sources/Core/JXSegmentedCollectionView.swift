







import UIKit

open class JXSegmentedCollectionView: UICollectionView {

    open var indicators = [JXSegmentedIndicatorProtocol & UIView]() {
        willSet {
            for indicator in indicators {
                indicator.removeFromSuperview()
            }
        }
        didSet {
            for indicator in indicators {
                addSubview(indicator)
            }
        }
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        for indicator in indicators {
            sendSubviewToBack(indicator)
            if let backgroundView = backgroundView {
                sendSubviewToBack(backgroundView)
            }
        }
    }

}
