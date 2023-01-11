







import UIKit

open class JXSegmentedTitleOrImageItemModel: JXSegmentedTitleItemModel {
    open var selectedImageInfo: String?
    open var loadImageClosure: LoadImageClosure?
    open var imageSize: CGSize = CGSize.zero
}
