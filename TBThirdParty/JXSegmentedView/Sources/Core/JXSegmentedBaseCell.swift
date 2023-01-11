







import UIKit

public typealias JXSegmentedCellSelectedAnimationClosure = (CGFloat)->()

open class JXSegmentedBaseCell: UICollectionViewCell, JXSegmentedViewRTLCompatible {
    open var itemModel: JXSegmentedBaseItemModel?
    open var animator: JXSegmentedAnimator?
    private var selectedAnimationClosureArray = [JXSegmentedCellSelectedAnimationClosure]()

    deinit {
        animator?.stop()
    }

    open override func prepareForReuse() {
        super.prepareForReuse()

        animator?.stop()
        animator = nil
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)

        commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        commonInit()
    }

    open func commonInit() {
        if segmentedViewShouldRTLLayout() {
            segmentedView(horizontalFlipForView: self)
            segmentedView(horizontalFlipForView: contentView)
        }
    }

    open func canStartSelectedAnimation(itemModel: JXSegmentedBaseItemModel, selectedType: JXSegmentedViewItemSelectedType) -> Bool {
        var isSelectedAnimatable = false
        if itemModel.isSelectedAnimable {
            if selectedType == .scroll {
                
                if !itemModel.isItemTransitionEnabled {
                    isSelectedAnimatable = true
                }
            }else if selectedType == .click || selectedType == .code {
                
                isSelectedAnimatable = true
            }
        }
        return isSelectedAnimatable
    }

    open func appendSelectedAnimationClosure(closure: @escaping JXSegmentedCellSelectedAnimationClosure) {
        selectedAnimationClosureArray.append(closure)
    }

    open func startSelectedAnimationIfNeeded(itemModel: JXSegmentedBaseItemModel, selectedType: JXSegmentedViewItemSelectedType) {
        if itemModel.isSelectedAnimable && canStartSelectedAnimation(itemModel: itemModel, selectedType: selectedType) {
            
            itemModel.isTransitionAnimating = true
            animator?.progressClosure = {[weak self] (percent) in
                guard self != nil else {
                    return
                }
                for closure in self!.selectedAnimationClosureArray {
                    closure(percent)
                }
            }
            animator?.completedClosure = {[weak self] in
                itemModel.isTransitionAnimating = false
                self?.selectedAnimationClosureArray.removeAll()
            }
            animator?.start()
        }
    }

    open func reloadData(itemModel: JXSegmentedBaseItemModel, selectedType: JXSegmentedViewItemSelectedType) {
        self.itemModel = itemModel

        if itemModel.isSelectedAnimable {
            selectedAnimationClosureArray.removeAll()
            if canStartSelectedAnimation(itemModel: itemModel, selectedType: selectedType) {
                animator = JXSegmentedAnimator()
                animator?.duration = itemModel.selectedAnimationDuration
            }else {
                animator?.stop()
                animator = nil
            }
        }
    }
}
