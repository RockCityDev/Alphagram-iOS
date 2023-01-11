import Foundation
import QuartzCore


class MyCompositionLayer {
    var bounds: CGRect = CGRect()

    let transformNode: LayerTransformNode

    

    let maskLayer: MyMaskContainerLayer?

    let matteType: MatteType?

    var matteLayer: MyCompositionLayer? {
        didSet {
            
            
        }
    }

    let inFrame: CGFloat
    let outFrame: CGFloat
    let startFrame: CGFloat
    let timeStretch: CGFloat

    init(layer: LayerModel, size: CGSize) {
        self.transformNode = LayerTransformNode(transform: layer.transform)
        if let masks = layer.masks {
            maskLayer = MyMaskContainerLayer(masks: masks)
        } else {
            maskLayer = nil
        }
        self.matteType = layer.matte
        self.inFrame = layer.inFrame.cgFloat
        self.outFrame = layer.outFrame.cgFloat
        self.timeStretch = layer.timeStretch.cgFloat
        self.startFrame = layer.startTime.cgFloat

        
        

        
        
    }

    private(set) var isHidden = false

    final func displayWithFrame(frame: CGFloat, forceUpdates: Bool) {
        transformNode.updateTree(frame, forceUpdates: forceUpdates)
        let layerVisible = frame.isInRangeOrEqual(inFrame, outFrame)
        
        if layerVisible {
            displayContentsWithFrame(frame: frame, forceUpdates: forceUpdates)
            maskLayer?.updateWithFrame(frame: frame, forceUpdates: forceUpdates)
        }
        self.isHidden = !layerVisible
        
        
    }

    func displayContentsWithFrame(frame: CGFloat, forceUpdates: Bool) {
        
    }

    func captureGeometry() -> CapturedGeometryNode {
        return CapturedGeometryNode(
            transform: self.transformNode.globalTransform,
            alpha: CGFloat(self.transformNode.opacity),
            isHidden: self.isHidden,
            displayItem: self.captureDisplayItem(),
            subnodes: self.captureChildren()
        )
    }

    func captureDisplayItem() -> CapturedGeometryNode.DisplayItem? {
        preconditionFailure()
    }

    func captureChildren() -> [CapturedGeometryNode] {
        preconditionFailure()
    }
}
