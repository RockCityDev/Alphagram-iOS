
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

public class TBVipGroupInfoViewController: ViewController {
    
    public let context: AccountContext
    private let hideNetworkActivityStatus: Bool
    private var presentationData: PresentationData
    private let presentationDataValue = Promise<PresentationData>()
    private var presentationDataDisposable: Disposable?
    private let implController: TBVipGroupInfoImplController
    
    public init(context: AccountContext,
                configEntry:TBWeb3ConfigEntry,
                groupInfo:TBWeb3GroupInfoEntry,
                walletConnect:TBWalletConnect,
                hideNetworkActivityStatus: Bool = false) {
        self.context = context
        self.hideNetworkActivityStatus = hideNetworkActivityStatus
        
        self.presentationData = (context.sharedContext.currentPresentationData.with { $0 })
        self.presentationDataValue.set(.single(self.presentationData))
        self.implController = TBVipGroupInfoImplController(
            context: self.context,
            configEntry: configEntry,
            groupInfo: groupInfo,
            walletConnect: walletConnect)
        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData))
        self.title = "vip"
        self.tabBarItem.title = nil
        self.navigationBar?.isHidden = true
        self.navigationPresentation = .modal
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
       
    }
    
    
    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        self.implController.containerLayoutUpdated(layout, transition: transition)
        self.implController.view.frame = CGRect(origin: .zero, size: layout.size)
    }
}

    
    


