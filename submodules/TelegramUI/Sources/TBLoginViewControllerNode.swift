import Foundation
import UIKit
import AsyncDisplayKit
import Display
import TelegramPresentationData
import TBLanguage

final class TBLoginViewControllerNode: ASDisplayNode {
    
    private let logoNode: ASImageNode
    public let loginButtonNode: ASButtonNode
    
    init(theme: PresentationTheme) {
        self.logoNode = ASImageNode()
        self.loginButtonNode = ASButtonNode()
        super.init()
        self.setViewBlock({
            return UITracingLayerView()
        })
        self.backgroundColor = theme.list.plainBackgroundColor
        self.view.disablesInteractiveTransitionGestureRecognizer = true
    }
    
    override public func didLoad() {
        super.didLoad()
        
        self.logoNode.image = UIImage(named: "Logging/image_logo_launch_page")
        let screenSize = UIScreen.main.bounds.size
        self.logoNode.frame = CGRect(x: 0.0, y: 0.0, width: screenSize.width, height: screenSize.width * (CGFloat(450) / CGFloat(360)));
        self.addSubnode(self.logoNode)
        
        self.loginButtonNode.setTitle(TBLanguage.sharedInstance.localizable(TBLankey.splash_btn_login), with: UIFont.boldSystemFont(ofSize: 18), with: UIColor.white, for: .normal)
        self.loginButtonNode.frame = CGRect(x: 59.0, y: screenSize.height - 160, width: screenSize.width - 118.0, height: 47.0)
        self.loginButtonNode.cornerRadius = 7.0
        self.loginButtonNode.backgroundColor = UIColor(hexString: "#03BDFF")
        self.addSubnode(self.loginButtonNode)
    }
    
    func containerLayoutUpdated(_ layout: ContainerViewLayout, navigationBarHeight: CGFloat, transition: ContainedViewLayoutTransition) {
        
    }
}
