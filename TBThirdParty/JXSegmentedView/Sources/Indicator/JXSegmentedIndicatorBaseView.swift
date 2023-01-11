







import UIKit

public enum JXSegmentedIndicatorPosition {
    case top
    case bottom
    case center
}

open class JXSegmentedIndicatorBaseView: UIView, JXSegmentedIndicatorProtocol {
    
    open var indicatorWidth: CGFloat = JXSegmentedViewAutomaticDimension
    open var indicatorWidthIncrement: CGFloat = 0   
    
    open var indicatorHeight: CGFloat = JXSegmentedViewAutomaticDimension
    
    open var indicatorCornerRadius: CGFloat = JXSegmentedViewAutomaticDimension
    
    open var indicatorColor: UIColor = .red
    
    open var indicatorPosition: JXSegmentedIndicatorPosition = .bottom
    
    open var verticalOffset: CGFloat = 0
    
    open var isScrollEnabled: Bool = true
    
    
    
    open var isIndicatorConvertToItemFrameEnabled: Bool = true
    
    open var scrollAnimationDuration: TimeInterval = 0.25
    
    open var isIndicatorWidthSameAsItemContent = false

    public override init(frame: CGRect) {
        super.init(frame: frame)

        commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        commonInit()
    }

    open func commonInit() {
    }

    public func getIndicatorCornerRadius(itemFrame: CGRect) -> CGFloat {
        if indicatorCornerRadius == JXSegmentedViewAutomaticDimension {
            return getIndicatorHeight(itemFrame: itemFrame)/2
        }
        return indicatorCornerRadius
    }

    public func getIndicatorWidth(itemFrame: CGRect, itemContentWidth: CGFloat) -> CGFloat {
        if indicatorWidth == JXSegmentedViewAutomaticDimension {
            if isIndicatorWidthSameAsItemContent {
                return itemContentWidth + indicatorWidthIncrement
            }else {
                return itemFrame.size.width + indicatorWidthIncrement
            }
        }
        return indicatorWidth + indicatorWidthIncrement
    }

    public func getIndicatorHeight(itemFrame: CGRect) -> CGFloat {
        if indicatorHeight == JXSegmentedViewAutomaticDimension {
            return itemFrame.size.height
        }
        return indicatorHeight
    }

    public func canHandleTransition(model: JXSegmentedIndicatorTransitionParams) -> Bool {
        if model.percent == 0 || !isScrollEnabled {
            
            
            return false
        }
        return true
    }

    public func canSelectedWithAnimation(model: JXSegmentedIndicatorSelectedParams) -> Bool {
        if isScrollEnabled && (model.selectedType == .click || model.selectedType == .code) {
            
            return true
        }
        return false
    }

    
    open func refreshIndicatorState(model: JXSegmentedIndicatorSelectedParams) {
    }

    open func contentScrollViewDidScroll(model: JXSegmentedIndicatorTransitionParams) {
    }

    open func selectItem(model: JXSegmentedIndicatorSelectedParams) {
    }
}
