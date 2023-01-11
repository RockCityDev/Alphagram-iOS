
import UIKit
import Postbox
import SwiftSignalKit
import AsyncDisplayKit
import Display
import TelegramCore
import TelegramPresentationData
import AccountContext
import SnapKit
import TBWeb3Core
import TBWalletCore

public class TBTransferToItController: ViewController {
    
    public let context: AccountContext
    private let hideNetworkActivityStatus: Bool
    private var presentationData: PresentationData
    private let presentationDataValue = Promise<PresentationData>()
    private var presentationDataDisposable: Disposable?
    private let implController: TBTransferToItImplController
    
    public init(context: AccountContext,
                wallet:TBWallet,
                inputAddress: String = "",
                hideNetworkActivityStatus: Bool = false) {
        self.context = context
        self.hideNetworkActivityStatus = hideNetworkActivityStatus
        
        self.presentationData = (context.sharedContext.currentPresentationData.with { $0 })
        self.presentationDataValue.set(.single(self.presentationData))
        self.implController = TBTransferToItImplController(
            context: self.context,
            wallet: wallet, inputAddress: inputAddress)
        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData))
        self.title = "vip"
        self.tabBarItem.title = nil
        self.navigationBar?.isHidden = true
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.presentationDataDisposable?.dispose()
    }
    
    
    
    
    
    
    public override func displayNodeDidLoad() {
        super.displayNodeDidLoad()
        self.addChild(self.implController)
        self.view.addSubview(self.implController.view)
        self.implController.didMove(toParent: self)
        self.displayNode.backgroundColor = UIColor(rgb: 0x000000, alpha: 0.5)
        self.implController.view.frame = CGRect(x: 0, y: 100, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - 100)
        self.implController.view.clipsToBounds = true
        self.implController.view.layer.cornerRadius = 8
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.implController.viewDidAppear(animated)
    }
    
    
    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        self.implController.containerLayoutUpdated(layout, transition: transition)
    }
}

    
    


