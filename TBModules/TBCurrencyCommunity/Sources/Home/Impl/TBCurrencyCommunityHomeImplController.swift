
import UIKit
import Postbox
import SwiftSignalKit
import AsyncDisplayKit
import Display
import TelegramCore
import TelegramPresentationData
import AccountContext
import TBSegementSlide
import SegementSlide
import SnapKit
import TBWeb3Core
import JXSegmentedView
import TBTrack

class TBCurrencyCommunityHomeImplController: TBSegementImageTitleController {
    
    let context: AccountContext
    private var presentationData: PresentationData
    private let presentationDataValue = Promise<PresentationData>()
    private var presentationDataDisposable: Disposable?
    func _parentViewController() -> TBCurrencyCommunityHomeController {
        return self.parent as! TBCurrencyCommunityHomeController
    }

    private var configDisposabel: Disposable?
    private var configEntry: TBWeb3ConfigEntry?
    private var chains: [TBWeb3ConfigEntry.Chain] {
        get {
            return self.configEntry?.chainType ?? [TBWeb3ConfigEntry.Chain]()
        }
    }
    private var contentControllers = [Int : TBCurrencyCommunityContentController]()

    
    init(context: AccountContext) {
        self.context = context
        self.presentationData = (context.sharedContext.currentPresentationData.with { $0 })
        self.presentationDataValue.set(.single(self.presentationData))
        super.init(nibName: nil, bundle: nil)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .red
        
        
        self.configDisposabel = (TBWeb3Config.shared.configSignal
                                 |> take(1)
                                 |> deliverOnMainQueue).start(next: {[weak self] config in
            if let strongSelf = self, let config = config{
                strongSelf.configEntry = config
                if !strongSelf.chains.isEmpty {
                    strongSelf.defaultSelectedIndex = 0
                }
                strongSelf.reloadData()
            }
        })
        self.reloadData()
    }
    
    func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition){
        
    }
    
    deinit {
        self.presentationDataDisposable?.dispose()
        self.configDisposabel?.dispose()
    }
    
    
    
    override var bouncesType: BouncesType {
        return .child
    }
    
    
    override func segementSlideHeaderView() -> UIView? {
        return nil
    }
    
    override var titlesInSwitcher: [String] {
        var ret = [String]()
        for chain in self.chains {
            ret.append(chain.name)
        }
        return ret
    }
    
    override var normalImageInfosSwitcher: [String] {
        var list = [String]()
        for chain in self.chains {
            list.append(chain.icon)
        }
       return list
    }
    
    override func segementSlideContentViewController(at index: Int) -> SegementSlideContentScrollViewDelegate? {
        if let config = self.configEntry, self.chains.count > index {
            let chain = self.chains[index]
            return self.contentControllerWithChain(chain, config)
        }else{
            return nil
        }
    }
    
    override func segmentedView(_ segmentedView: JXSegmentedView, didSelectedItemAt index: Int) {
        super.segmentedView(segmentedView, didSelectedItemAt: index)
        if self.chains.count > index {
            switch self.chains[index].getChainType() {
            case .OS:
                TBTrack.track(TBTrackEvent.Asset.profile_oasis_click.rawValue)
            case .Polygon:
                TBTrack.track(TBTrackEvent.Asset.profile_polygon_click.rawValue)
            case .TT:
                TBTrack.track(TBTrackEvent.Asset.profile_tt_click.rawValue)
            case .ETH:
                TBTrack.track(TBTrackEvent.Asset.profile_eth_click.rawValue)
            case .unkonw:
                break
            }
        }
    }
    
    
    private func contentControllerWithChain(_ chain:TBWeb3ConfigEntry.Chain, _ config: TBWeb3ConfigEntry) -> TBCurrencyCommunityContentController {
        if let c = self.contentControllers[chain.id] {
            return c
        }else{
            let c = TBCurrencyCommunityContentController(context: self.context, config: config, chain: chain)
            self.contentControllers[chain.id] = c
            return c
        }
    }
    
    
    override var headerStickyHeightOffset: CGFloat {
        return 0.1
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView, isParent: Bool) {
        super.scrollViewDidScroll(scrollView, isParent: isParent)
    }

}







