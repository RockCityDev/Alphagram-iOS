import Foundation
import UIKit
import Postbox
import SwiftSignalKit
import AsyncDisplayKit
import Display
import TelegramCore
import TelegramPresentationData
import AccountContext
import AvatarNode

public class RedEnvelopeDetailController: ViewController {
    
    public let context: AccountContext
    private var presentationData: PresentationData
    private let presentationDataValue = Promise<PresentationData>()
    private var presentationDataDisposable: Disposable?
    
    private let fromUserId: String
    private let rpDetail: RedEnvelopeDetail
    
    private let segmentVC: RpDetailSegmentController
    private let alertNode: ASTextNode
    public init(context: AccountContext, fromUserId: String, detail: RedEnvelopeDetail) {
        self.context = context
        self.fromUserId = fromUserId
        self.rpDetail = detail
        
        self.presentationData = (context.sharedContext.currentPresentationData.with { $0 })
        self.presentationDataValue.set(.single(self.presentationData))
        
        self.segmentVC = RpDetailSegmentController(context: context, rpDetail: detail)
        self.alertNode = ASTextNode()
        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData))
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
        self.displayNode.backgroundColor = UIColor.white
        self.addChild(self.segmentVC)
        self.view.addSubview(self.segmentVC.view)
        self.segmentVC.didMove(toParent: self)
        self.segmentVC.headerNode.backEvent = {[weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        self.alertNode.attributedText = NSAttributedString(string: "24", font: Font.regular(14), textColor: UIColor(hexString: "#FF868686")!, paragraphAlignment: .center)
        self.displayNode.addSubnode(self.alertNode)
    }
    
    
    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        let bottomHeight = layout.intrinsicInsets.bottom
        let y = 0.0
        self.segmentVC.view.frame = CGRect(origin:CGPoint(x: 0, y: y), size: CGSize(width: layout.size.width, height: layout.size.height - bottomHeight - 20 - 20 - y - 10))
        self.segmentVC.containerLayoutUpdated(layout, transition: transition)
        transition.updateFrame(node: self.alertNode, frame: CGRect(x: 16, y: layout.size.height - bottomHeight - 20 - 20, width: layout.size.width - 32, height: 20))
    }
    
}

enum RPPageType {
    
    case waitOnline
    case onlineSuccess
    case overTime
    case empty
    case unReceived
}

extension RedEnvelopeDetail {
    
    func rpNumberStr() -> String {
        if self.num > self.num_exec {
            return "\(self.num),\(self.num - self.num_exec)"
        } else {
            return "\(self.num),"
        }
    }
    
    func getPageType(with userId: String) -> RPPageType {
        let record = self.record.filter({$0.tg_user_id == userId}).first
        if let record = record {
            
            let payStatus = record.payStatus()
            if payStatus == .waitPay || payStatus == .waitOnline {
                return .waitOnline
            } else {
                return .onlineSuccess
            }
        } else {
            switch formatedStatus(status: self.status) {
            case .online:
                return .unReceived
            case .deadline:
                return .overTime
            case .complete:
                return .empty
            default:
                return .unReceived
            }
        }
    }
}
