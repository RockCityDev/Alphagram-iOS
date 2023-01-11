import Foundation
import UIKit
import AsyncDisplayKit
import Display
import TelegramPresentationData

final class TBHomeWalletControllerNode: ASDisplayNode {

    init(theme: PresentationTheme) {
        super.init()
        self.setViewBlock({
            return UITracingLayerView()
        })
        self.backgroundColor = UIColor.red
        self.view.disablesInteractiveTransitionGestureRecognizer = true
    }
    
    override public func didLoad() {
        super.didLoad()
    }
    
    func containerLayoutUpdated(_ layout: ContainerViewLayout, navigationBarHeight: CGFloat, transition: ContainedViewLayoutTransition) {
        
    }
}
