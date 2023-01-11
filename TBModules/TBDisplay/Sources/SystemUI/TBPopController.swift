
import UIKit
import UIKit
import Postbox
import SwiftSignalKit
import AsyncDisplayKit
import Display
import TelegramCore
import TelegramPresentationData
import AccountContext

open class TBPopController: ViewController {
    
    public let context: AccountContext
    public var contentItem: (node: ASDisplayNode, frame: CGRect)?
    private let canCloseByTouches: Bool
    
    private var popDisplayNode: TBPopControllerNode {
        return super.displayNode as! TBPopControllerNode
    }
    
    public init(context: AccountContext, backgroundColor: UIColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.6), canCloseByTouches: Bool = false) {
        self.context = context
        let presentationData = (context.sharedContext.currentPresentationData.with { $0 })
        self.canCloseByTouches = canCloseByTouches
        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationData: presentationData))
        self.navigationBar?.isHidden = true
        self.displayNode.backgroundColor = backgroundColor
        if canCloseByTouches {
            let tap = UITapGestureRecognizer(target: self, action: #selector(tapEvent(tap:)))
            tap.delegate = self
            self.displayNode.view.addGestureRecognizer(tap)
        }
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
    }
    
    override public func loadDisplayNode() {
        self.displayNode = TBPopControllerNode(context: self.context)
        self.displayNodeDidLoad()
    }
   
   
   open override func displayNodeDidLoad() {
       super.displayNodeDidLoad()
   }
    
    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        
    }
    
    @objc func tapEvent(tap: UITapGestureRecognizer) {
        self.dismiss(animated: true)
    }
    
    public func setContentNode(_ node: ASDisplayNode, frame: CGRect) {
        var preframe = frame
        preframe.origin.y = UIScreen.main.bounds.maxY
        node.frame = preframe
        self.displayNode.addSubnode(node)
        self.contentItem = (node, frame)
        self.popDisplayNode.contentNode = node
    }
    
    public func replaceContentNode(_ node: ASDisplayNode,
                                   frame: CGRect,
                                   transition: ContainedViewLayoutTransition = .animated(duration: 0.23, curve: .linear)) {
        if let item = self.contentItem {
            item.node.removeFromSupernode()
        }
        self.displayNode.addSubnode(node)
        self.contentItem = (node, frame)
        self.popDisplayNode.contentNode = node
        var preframe = frame
        preframe.origin.y = UIScreen.main.bounds.maxY
        node.frame = preframe
        transition.updateFrame(node: node, frame: frame)
    }
    
    open func pop(from controller: ViewController, transition: ContainedViewLayoutTransition = .animated(duration: 0.23, curve: .easeInOut)) {
        guard let item = self.contentItem else { return }
        controller.present(self, in: .window(.root))
        
        transition.updateFrame(node: item.node, frame: item.frame)
    }
}

extension TBPopController: UIGestureRecognizerDelegate {
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let point = touch.location(in: self.view)
        if let item = self.contentItem, self.canCloseByTouches {
            let contains = item.node.frame.contains(point)
            return !contains
        }
        return false
    }
    
}

class TBPopControllerNode: ASDisplayNode {
    private let context: AccountContext
    
    var contentNode: ASDisplayNode?
    
    init(context: AccountContext) {
        self.context = context
        super.init()
    }
    
    
    override func didLoad() {
        super.didLoad()
    }
}
