







import UIKit

open class JXSegmentedTitleOrImageCell: JXSegmentedTitleCell {
    public let imageView = UIImageView()
    private var currentImageInfo: String?

    open override func prepareForReuse() {
        super.prepareForReuse()

        currentImageInfo = nil
    }

    open override func commonInit() {
        super.commonInit()

        imageView.contentMode = .scaleAspectFit
        contentView.addSubview(imageView)
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        imageView.center = contentView.center
    }

    open override func reloadData(itemModel: JXSegmentedBaseItemModel, selectedType: JXSegmentedViewItemSelectedType) {
        super.reloadData(itemModel: itemModel, selectedType: selectedType )

        guard let myItemModel = itemModel as? JXSegmentedTitleOrImageItemModel else {
            return
        }

        if myItemModel.isSelected && myItemModel.selectedImageInfo != nil {
            titleLabel.isHidden = true
            imageView.isHidden = false
        }else {
            titleLabel.isHidden = false
            imageView.isHidden = true
        }

        imageView.bounds = CGRect(x: 0, y: 0, width: myItemModel.imageSize.width, height: myItemModel.imageSize.height)

        
        if myItemModel.isSelected &&
            myItemModel.selectedImageInfo != nil &&
            myItemModel.selectedImageInfo != currentImageInfo {
            currentImageInfo = myItemModel.selectedImageInfo
            if myItemModel.loadImageClosure != nil {
                myItemModel.loadImageClosure!(imageView, myItemModel.selectedImageInfo!)
            }else {
                imageView.image = UIImage(named: myItemModel.selectedImageInfo!)
            }
        }

        setNeedsLayout()
    }

    open override func preferredTitleZoomAnimateClosure(itemModel: JXSegmentedTitleItemModel, baseScale: CGFloat) -> JXSegmentedCellSelectedAnimationClosure {
        guard let myItemModel = itemModel as? JXSegmentedTitleOrImageItemModel else {
            return super.preferredTitleZoomAnimateClosure(itemModel: itemModel, baseScale: baseScale)
        }
        if myItemModel.selectedImageInfo == nil && myItemModel.isSelected {
            
            return super.preferredTitleZoomAnimateClosure(itemModel: itemModel, baseScale: baseScale)
        }else {
            let closure: JXSegmentedCellSelectedAnimationClosure = {[weak self] (percent) in
                if itemModel.isSelected {
                    
                    itemModel.titleCurrentZoomScale = itemModel.titleSelectedZoomScale
                }else {
                    
                    itemModel.titleCurrentZoomScale = itemModel.titleNormalZoomScale
                }
                let currentTransform = CGAffineTransform(scaleX: baseScale*itemModel.titleCurrentZoomScale, y: baseScale*itemModel.titleCurrentZoomScale)
                self?.titleLabel.transform = currentTransform
                self?.maskTitleLabel.transform = currentTransform
            }
            
            closure(0)
            return closure
        }
    }

    open override func preferredTitleStrokeWidthAnimateClosure(itemModel: JXSegmentedTitleItemModel, attriText: NSMutableAttributedString) -> JXSegmentedCellSelectedAnimationClosure {
        guard let myItemModel = itemModel as? JXSegmentedTitleOrImageItemModel else {
            return super.preferredTitleStrokeWidthAnimateClosure(itemModel: itemModel, attriText: attriText)
        }
        if myItemModel.selectedImageInfo == nil && myItemModel.isSelected {
            
            return super.preferredTitleStrokeWidthAnimateClosure(itemModel: itemModel, attriText: attriText)
        }else {
            let closure: JXSegmentedCellSelectedAnimationClosure = {[weak self] (percent) in
                if itemModel.isSelected {
                    
                    itemModel.titleCurrentStrokeWidth = itemModel.titleSelectedStrokeWidth
                }else {
                    
                    itemModel.titleCurrentStrokeWidth = itemModel.titleNormalStrokeWidth
                }
                attriText.addAttributes([NSAttributedString.Key.strokeWidth: itemModel.titleCurrentStrokeWidth], range: NSRange(location: 0, length: attriText.string.count))
                self?.titleLabel.attributedText = attriText
            }
            
            closure(0)
            return closure
        }
    }

    open override func preferredTitleColorAnimateClosure(itemModel: JXSegmentedTitleItemModel) -> JXSegmentedCellSelectedAnimationClosure {
        guard let myItemModel = itemModel as? JXSegmentedTitleOrImageItemModel else {
            return super.preferredTitleColorAnimateClosure(itemModel: itemModel)
        }
        if myItemModel.selectedImageInfo == nil && myItemModel.isSelected {
            
            return super.preferredTitleColorAnimateClosure(itemModel: itemModel)
        }else {
            let closure: JXSegmentedCellSelectedAnimationClosure = {[weak self] (percent) in
                if itemModel.isSelected {
                    
                    itemModel.titleCurrentColor = itemModel.titleSelectedColor
                }else {
                    
                    itemModel.titleCurrentColor = itemModel.titleNormalColor
                }
                self?.titleLabel.textColor = itemModel.titleCurrentColor
            }
            
            closure(0)
            return closure
        }
    }
    
}
