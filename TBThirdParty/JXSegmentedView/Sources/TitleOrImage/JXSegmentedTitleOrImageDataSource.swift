







import UIKit

open class JXSegmentedTitleOrImageDataSource: JXSegmentedTitleDataSource {
    
    open var selectedImageInfos: [String?]?
    
    open var loadImageClosure: LoadImageClosure?
    
    open var imageSize: CGSize = CGSize(width: 30, height: 30)

    open override func preferredItemModelInstance() -> JXSegmentedBaseItemModel {
        return JXSegmentedTitleOrImageItemModel()
    }

    open override func reloadData(selectedIndex: Int) {
        selectedAnimationDuration = 0.1

        super.reloadData(selectedIndex: selectedIndex)
    }

    open override func preferredRefreshItemModel( _ itemModel: JXSegmentedBaseItemModel, at index: Int, selectedIndex: Int) {
        super.preferredRefreshItemModel(itemModel, at: index, selectedIndex: selectedIndex)

        guard let itemModel = itemModel as? JXSegmentedTitleOrImageItemModel else {
            return
        }

        itemModel.selectedImageInfo = selectedImageInfos?[index]
        itemModel.loadImageClosure = loadImageClosure
        itemModel.imageSize = imageSize
    }

    
    open override func registerCellClass(in segmentedView: JXSegmentedView) {
        segmentedView.collectionView.register(JXSegmentedTitleOrImageCell.self, forCellWithReuseIdentifier: "cell")
    }

    open override func segmentedView(_ segmentedView: JXSegmentedView, cellForItemAt index: Int) -> JXSegmentedBaseCell {
        let cell = segmentedView.dequeueReusableCell(withReuseIdentifier: "cell", at: index)
        return cell
    }

}
