
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


public class TBGroupLabelController: ViewController {
    
    public let context: AccountContext
    private let hideNetworkActivityStatus: Bool
    private var presentationData: PresentationData
    private let presentationDataValue = Promise<PresentationData>()
    private var presentationDataDisposable: Disposable?
    private let implController: TBGroupLabelImplController
    
    public init(
        context: AccountContext,
        update:@escaping ([TBWeb3GroupInfoEntry.Tag]) -> Void,
        initialLabels:[TBWeb3GroupInfoEntry.Tag],
        hideNetworkActivityStatus: Bool = false
    ) {
        self.context = context
        self.hideNetworkActivityStatus = hideNetworkActivityStatus
        self.presentationData = (context.sharedContext.currentPresentationData.with { $0 })
        self.presentationDataValue.set(.single(self.presentationData))
        self.implController = TBGroupLabelImplController(context: self.context, initialLabels: initialLabels, update: update)
        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData))
        self.navigationItem.setRightBarButton(UIBarButtonItem(title: self.presentationData.strings.Common_Done, style: .done, target: self, action: #selector(self.donePressed)), animated: false)
        self.title = ""
        self.tabBarItem.title = nil
        self.navigationBar?.isHidden = false
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.presentationDataDisposable?.dispose()
    }
    
    @objc func donePressed() {
        self.navigationController?.popViewController(animated: true)
    }
    
    
    
    
    
    
    public override func displayNodeDidLoad() {
        super.displayNodeDidLoad()
        self.addChild(self.implController)
        self.view.addSubview(self.implController.view)
        self.implController.didMove(toParent: self)
    }
    
    
    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        let y = (layout.statusBarHeight ?? 20) + 44
        self.implController.view.frame = CGRect(origin:CGPoint(x: 0, y: y), size: CGSize(width: layout.size.width, height: layout.size.height - y))
        self.implController.containerLayoutUpdated(layout, transition: transition)
    }
}

    
    


