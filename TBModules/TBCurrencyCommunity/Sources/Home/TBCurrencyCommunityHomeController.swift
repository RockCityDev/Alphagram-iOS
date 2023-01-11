
import UIKit
import Postbox
import SwiftSignalKit
import AsyncDisplayKit
import Display
import TelegramCore
import TelegramPresentationData
import AccountContext
import SnapKit
import TBLanguage

public class TBCurrencyCommunityHomeController: ViewController {
    
    public let context: AccountContext
    private let hideNetworkActivityStatus: Bool
    private var presentationData: PresentationData
    private let presentationDataValue = Promise<PresentationData>()
    private var presentationDataDisposable: Disposable?
    private let implController: TBCurrencyCommunityHomeImplController
    
    public init(context: AccountContext, hideNetworkActivityStatus: Bool = false) {
        self.context = context
        self.hideNetworkActivityStatus = hideNetworkActivityStatus
        
        self.presentationData = (context.sharedContext.currentPresentationData.with { $0 })
        self.presentationDataValue.set(.single(self.presentationData))
        self.implController = TBCurrencyCommunityHomeImplController(context: self.context)
        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData))
        self.tabBarItem.title = nil
        self.navigationBar?.isHidden = true
        let _ = (context.sharedContext.presentationData |> deliverOnMainQueue).start {[weak self] data in
            guard let strongSelf = self else { return }
            strongSelf.presentationData = data
            strongSelf.presentationDataValue.set(.single(data))
            let text = TBLanguage.sharedInstance.localizable(TBLankey.asset_home_tab_asset)
            strongSelf.tabBarItem.title = text
        }
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
        let y = (layout.statusBarHeight ?? 20)
        let bottomH = layout.intrinsicInsets.bottom
        self.implController.view.frame = CGRect(origin:CGPoint(x: 0, y: y), size: CGSize(width: layout.size.width, height: layout.size.height - y - bottomH))
    }
}

    
    


