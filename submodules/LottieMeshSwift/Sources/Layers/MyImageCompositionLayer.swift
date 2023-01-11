import Foundation
import CoreGraphics
import QuartzCore

final class MyImageCompositionLayer: MyCompositionLayer {

    var image: CGImage? = nil {
        didSet {
            
            
        }
    }

    let imageReferenceID: String

    init(imageLayer: ImageLayerModel, size: CGSize) {
        self.imageReferenceID = imageLayer.referenceID
        super.init(layer: imageLayer, size: size)

        
        
        
    }

    override func captureDisplayItem() -> CapturedGeometryNode.DisplayItem? {
        preconditionFailure()
    }

    override func captureChildren() -> [CapturedGeometryNode] {
        return []
    }
}
