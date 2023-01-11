import Foundation
import UIKit
import Display
import AsyncDisplayKit
import TelegramPresentationData
import SwiftSignalKit
import PhotosUI

final class TBLoginViewController: ViewController {
    
    private let theme: PresentationTheme
    public var startMessaging: (() -> (Void))?
    
    init(theme: PresentationTheme) {
        self.theme = theme
        
        super.init(navigationBarPresentationData: nil)
        
        self.supportedOrientations = ViewControllerSupportedOrientations(regularSize: .all, compactSize: .portrait)
        
        self.statusBar.statusBarStyle = theme.intro.statusBarStyle.style
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
    }
    
    override public func loadDisplayNode() {
        let node = TBLoginViewControllerNode(theme: self.theme)
        node.loginButtonNode.addTarget(self, action: #selector(self.loginButtonClick), forControlEvents: .touchUpInside)
        self.displayNode = node
        self.displayNodeDidLoad()
    }
    
    override func displayNodeDidLoad() {
        super.displayNodeDidLoad()
        
    }
    
    
    @objc func loginButtonClick() {
        if let block = self.startMessaging {
            block()
        }
    }
}

