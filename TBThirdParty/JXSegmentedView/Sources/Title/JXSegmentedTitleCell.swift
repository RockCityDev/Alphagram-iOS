







import UIKit

open class JXSegmentedTitleCell: JXSegmentedBaseCell {
    public let titleLabel = UILabel()
    public let maskTitleLabel = UILabel()
    public let titleMaskLayer = CALayer()
    public let maskTitleMaskLayer = CALayer()

    open override func commonInit() {
        super.commonInit()

        titleLabel.textAlignment = .center
        contentView.addSubview(titleLabel)

        maskTitleLabel.textAlignment = .center
        maskTitleLabel.isHidden = true
        contentView.addSubview(maskTitleLabel)

        titleMaskLayer.backgroundColor = UIColor.red.cgColor

        maskTitleMaskLayer.backgroundColor = UIColor.red.cgColor
        maskTitleLabel.layer.mask = maskTitleMaskLayer
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        
        let labelSize = titleLabel.sizeThatFits(self.contentView.bounds.size)
        let labelBounds = CGRect(x: 0, y: 0, width: labelSize.width, height: labelSize.height)
        titleLabel.bounds = labelBounds
        titleLabel.center = contentView.center

        maskTitleLabel.bounds = labelBounds
        maskTitleLabel.center = contentView.center
    }

    open override func reloadData(itemModel: JXSegmentedBaseItemModel, selectedType: JXSegmentedViewItemSelectedType) {
        super.reloadData(itemModel: itemModel, selectedType: selectedType )

        guard let myItemModel = itemModel as? JXSegmentedTitleItemModel else {
            return
        }

        titleLabel.numberOfLines = myItemModel.titleNumberOfLines
        maskTitleLabel.numberOfLines = myItemModel.titleNumberOfLines

        if myItemModel.isTitleZoomEnabled {
            
            let maxScaleFont = UIFont(descriptor: myItemModel.titleNormalFont.fontDescriptor, size: myItemModel.titleNormalFont.pointSize*CGFloat(myItemModel.titleSelectedZoomScale))
            let baseScale = myItemModel.titleNormalFont.lineHeight/maxScaleFont.lineHeight

            if myItemModel.isSelectedAnimable && canStartSelectedAnimation(itemModel: itemModel, selectedType: selectedType) {
                
                let titleZoomClosure = preferredTitleZoomAnimateClosure(itemModel: myItemModel, baseScale: baseScale)
                appendSelectedAnimationClosure(closure: titleZoomClosure)
            }else {
                titleLabel.font = maxScaleFont
                maskTitleLabel.font = maxScaleFont
                let currentTransform = CGAffineTransform(scaleX: baseScale*CGFloat(myItemModel.titleCurrentZoomScale), y: baseScale*CGFloat(myItemModel.titleCurrentZoomScale))
                titleLabel.transform = currentTransform
                maskTitleLabel.transform = currentTransform
            }
        }else {
            if myItemModel.isSelected {
                titleLabel.font = myItemModel.titleSelectedFont
                maskTitleLabel.font = myItemModel.titleSelectedFont
            }else {
                titleLabel.font = myItemModel.titleNormalFont
                maskTitleLabel.font = myItemModel.titleNormalFont
            }
        }

        let title = myItemModel.title ?? ""
        let attriText = NSMutableAttributedString(string: title)
        if myItemModel.isTitleStrokeWidthEnabled {
            if myItemModel.isSelectedAnimable && canStartSelectedAnimation(itemModel: itemModel, selectedType: selectedType) {
                
                let titleStrokeWidthClosure = preferredTitleStrokeWidthAnimateClosure(itemModel: myItemModel, attriText: attriText)
                appendSelectedAnimationClosure(closure: titleStrokeWidthClosure)
            }else {
                attriText.addAttributes([NSAttributedString.Key.strokeWidth: myItemModel.titleCurrentStrokeWidth], range: NSRange(location: 0, length: title.count))
                titleLabel.attributedText = attriText
                maskTitleLabel.attributedText = attriText
            }
        }else {
            titleLabel.attributedText = attriText
            maskTitleLabel.attributedText = attriText
        }

        if myItemModel.isTitleMaskEnabled {
            
            
            maskTitleLabel.isHidden = false
            titleLabel.textColor = myItemModel.titleNormalColor
            maskTitleLabel.textColor = myItemModel.titleSelectedColor
            let labelSize = maskTitleLabel.sizeThatFits(self.contentView.bounds.size)
            let labelBounds = CGRect(x: 0, y: 0, width: labelSize.width, height: labelSize.height)
            maskTitleLabel.bounds = labelBounds

            var topMaskFrame = myItemModel.indicatorConvertToItemFrame
            topMaskFrame.origin.y = 0
            var bottomMaskFrame = topMaskFrame
            var maskStartX: CGFloat = 0
            if maskTitleLabel.bounds.size.width >= bounds.size.width {
                topMaskFrame.origin.x -= (maskTitleLabel.bounds.size.width - bounds.size.width)/2
                bottomMaskFrame.size.width = maskTitleLabel.bounds.size.width
                maskStartX = -(maskTitleLabel.bounds.size.width - bounds.size.width)/2
            }else {
                topMaskFrame.origin.x -= (bounds.size.width - maskTitleLabel.bounds.size.width)/2
                bottomMaskFrame.size.width = bounds.size.width
                maskStartX = 0
            }
            bottomMaskFrame.origin.x = topMaskFrame.origin.x
            if topMaskFrame.origin.x > maskStartX {
                bottomMaskFrame.origin.x = topMaskFrame.origin.x - bottomMaskFrame.size.width
            }else {
                bottomMaskFrame.origin.x = topMaskFrame.maxX
            }

            CATransaction.begin()
            CATransaction.setDisableActions(true)
            if topMaskFrame.size.width > 0 && topMaskFrame.intersects(maskTitleLabel.frame) {
                titleLabel.layer.mask = titleMaskLayer
                titleMaskLayer.frame = bottomMaskFrame
                maskTitleMaskLayer.frame = topMaskFrame
            }else {
                titleLabel.layer.mask = nil
                maskTitleMaskLayer.frame = topMaskFrame
            }
            CATransaction.commit()
        }else {
            maskTitleLabel.isHidden = true
            titleLabel.layer.mask = nil
            if myItemModel.isSelectedAnimable && canStartSelectedAnimation(itemModel: itemModel, selectedType: selectedType) {
                
                let titleColorClosure = preferredTitleColorAnimateClosure(itemModel: myItemModel)
                appendSelectedAnimationClosure(closure: titleColorClosure)
            }else {
                titleLabel.textColor = myItemModel.titleCurrentColor
            }
        }

        startSelectedAnimationIfNeeded(itemModel: itemModel, selectedType: selectedType)

        setNeedsLayout()
    }

    open func preferredTitleZoomAnimateClosure(itemModel: JXSegmentedTitleItemModel, baseScale: CGFloat) -> JXSegmentedCellSelectedAnimationClosure {
        return {[weak self] (percnet) in
            if itemModel.isSelected {
                
                itemModel.titleCurrentZoomScale = JXSegmentedViewTool.interpolate(from: itemModel.titleNormalZoomScale, to: itemModel.titleSelectedZoomScale, percent: percnet)
            }else {
                
                itemModel.titleCurrentZoomScale = JXSegmentedViewTool.interpolate(from: itemModel.titleSelectedZoomScale, to:itemModel.titleNormalZoomScale , percent: percnet)
            }
            let currentTransform = CGAffineTransform(scaleX: baseScale*itemModel.titleCurrentZoomScale, y: baseScale*itemModel.titleCurrentZoomScale)
            self?.titleLabel.transform = currentTransform
            self?.maskTitleLabel.transform = currentTransform
        }
    }

    open func preferredTitleStrokeWidthAnimateClosure(itemModel: JXSegmentedTitleItemModel, attriText: NSMutableAttributedString) -> JXSegmentedCellSelectedAnimationClosure{
        return {[weak self] (percent) in
            if itemModel.isSelected {
                
                itemModel.titleCurrentStrokeWidth = JXSegmentedViewTool.interpolate(from: itemModel.titleNormalStrokeWidth, to: itemModel.titleSelectedStrokeWidth, percent: percent)
            }else {
                
                itemModel.titleCurrentStrokeWidth = JXSegmentedViewTool.interpolate(from: itemModel.titleSelectedStrokeWidth, to:itemModel.titleNormalStrokeWidth , percent: percent)
            }
            attriText.addAttributes([NSAttributedString.Key.strokeWidth: itemModel.titleCurrentStrokeWidth], range: NSRange(location: 0, length: attriText.string.count))
            self?.titleLabel.attributedText = attriText
            self?.maskTitleLabel.attributedText = attriText
        }
    }

    open func preferredTitleColorAnimateClosure(itemModel: JXSegmentedTitleItemModel) -> JXSegmentedCellSelectedAnimationClosure {
        return {[weak self] (percent) in
            if itemModel.isSelected {
                
                itemModel.titleCurrentColor = JXSegmentedViewTool.interpolateThemeColor(from: itemModel.titleNormalColor, to: itemModel.titleSelectedColor, percent: percent)
            }else {
                
                itemModel.titleCurrentColor = JXSegmentedViewTool.interpolateThemeColor(from: itemModel.titleSelectedColor, to: itemModel.titleNormalColor, percent: percent)
            }
            self?.titleLabel.textColor = itemModel.titleCurrentColor
        }
    }
}
