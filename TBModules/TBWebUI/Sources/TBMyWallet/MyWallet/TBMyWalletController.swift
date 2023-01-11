import UIKit
import SwiftSignalKit
import AsyncDisplayKit
import Display
import TelegramCore
import TelegramPresentationData
import AccountContext
import SegementSlide
import TBWeb3Core
import TBWalletCore
import TBDisplay
import Postbox
import TBNetwork
import HandyJSON
import AvatarNode
import ProgressHUD
import SDWebImage
import TBLanguage
import TBAccount
import TBTransferAssetUI
import TBQrCode
import QrCodeUI

private struct State:Equatable {
    var config: TBWeb3ConfigEntry?
    var currentChain: TBWeb3ConfigEntry.Chain?
    var allWallets = [TBWallet]()
    var currentWallet: TBWallet?
    
    static func == (lhs: State, rhs: State) -> Bool {
        if lhs.currentChain != rhs.currentChain {
            return false
        }
        
        if lhs.currentChain != rhs.currentChain {
            return false
        }
        
        if !lhs.allWallets.elementsEqual(rhs.allWallets) {
            return false
        }
        if lhs.currentWallet != rhs.currentWallet {
            return false
        }
        return true
    }
}

public class TBMyWalletController: ViewController {
    
    public let context: AccountContext
    private var presentationData: PresentationData
    private let presentationDataValue = Promise<PresentationData>()
    private var presentationDataDisposable: Disposable?
    private let segmentVC: TBMyWalletSegmentController

    private let statePromise: ValuePromise<State>
    private let stateValue: Atomic<State>
    private let updateState: ((State) -> State) -> Void
    private var stateDisposable: Disposable?
    
    public init(context: AccountContext) {
        self.context = context
        self.presentationData = (context.sharedContext.currentPresentationData.with { $0 })
        self.presentationDataValue.set(.single(self.presentationData))
        
        self.segmentVC = TBMyWalletSegmentController(context: context, presentationData: presentationData)
        
        let initialState = State()
        let statePromise = ValuePromise(initialState, ignoreRepeated: true)
        let stateValue = Atomic(value: initialState)
        let updateState: ((State) -> State) -> Void = { f in
            statePromise.set(stateValue.modify { f($0) })
        }
        self.statePromise = statePromise
        self.stateValue = stateValue
        self.updateState = updateState
        
        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData))
        self.navigationBar?.isHidden = true
        
        let configSignal = TBWeb3Config.shared.configSignal
        let allWalletSignal = TBWalletWrapper.getAllWalletsSignal(context: context, password: "")
        
        let _ = (combineLatest(configSignal, allWalletSignal)
                 |> deliverOnMainQueue).start(next: {[weak self] config, wallet in
            self?.updateState { current in
                var current = current
                current.config = config
                if let chain = current.currentChain, let config = current.config, config.chainType.contains(chain) {
                } else {
                    current.currentChain = current.config?.chainType.first
                }
                
                current.allWallets = wallet
                if current.currentWallet == nil {
                    current.currentWallet = current.allWallets.first
                }
                return current
            }
        })
        
        self.stateDisposable = self.statePromise.get().start(next: {
            [weak self] state in
            
            if let wallet = state.currentWallet {
                self?.segmentVC.myHeaderView.updateAddress(wallet.walletAddress())
                self?.segmentVC.myHeaderView.updateAccount(wallet)
            }
            
            if let chain = state.currentChain {
                self?.segmentVC.myHeaderView.updateNetwork(chain)
            }
            
            if let wallet = state.currentWallet, let chain = state.currentChain {
                self?.segmentVC.updateConfig(chain: chain, address: wallet.walletAddress())
            }
            
        })
        
        debugPrint("[tbMyWalletController init]")
    }
    
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.presentationDataDisposable?.dispose()
        self.stateDisposable?.dispose()
    }
    
    public override func displayNodeDidLoad() {
        super.displayNodeDidLoad()
        self.addChild(self.segmentVC)
        self.view.addSubview(self.segmentVC.view)
        self.segmentVC.didMove(toParent: self)
        self.segmentVC.myHeaderView.event = { [weak self] eventType in
            guard let strongSelf = self else { return }
            switch eventType {
            case .chain:
                strongSelf.popNetwork()
            case .account:
                let state = strongSelf.stateValue.with{$0}
                let params = TBMyWalletListController.Params(
                    initialWallets: state.allWallets,
                    initialSelectWallet: state.currentWallet,
                    selectWallet: {[weak self] wallet in
                        guard let strongSelf = self else {return}
                        strongSelf.updateState { current in
                            var current = current
                            current.currentWallet = wallet
                            return current
                        }
                    },
                    importWallet: {[weak self] in
                        guard let strongSelf = self else {return}
                        let addWalletListController =  TBAddWalletController(context: strongSelf.context, params: .init())
                        strongSelf.push(addWalletListController)
                    })
                let walletListController = TBMyWalletListController(context: strongSelf.context, params: params)
                
                strongSelf.push(walletListController)
                break
            case let .copyAddress(address):
                UIPasteboard.general.string = address
                ProgressHUD.showSucceed("")
                break
            case .explore:
                break
            case .transfer:
                if let wallet = self?.stateValue.with({$0.currentWallet}) {
                    let controller = TBTransferToItController(context: strongSelf.context, wallet:wallet)
                    self?.present(controller, in: .window(.root))
                }
            case .receive:
                guard let strongSelf = self else { return }
                let vc = QrCodeController(context: strongSelf.context, code: "ethereum:0x352e40B46ec304B929bfC492d9FD7fA2B2E33356@108")
                strongSelf.present(vc, in: .window(.root))
            case .exchange:
                break
            case .qrCode:
                guard let strongSelf = self else { return }
                let controller = TBQrCodeScanScreen(context: strongSelf.context, subject: .wallet, callBack: { address in
                    // "ethereum:0x352e40B46ec304B929bfC492d9FD7fA2B2E33356@108"
                    if let achain = address.components(separatedBy: ":").last, let rAddress = achain.components(separatedBy: "@").first {

//                        if achain.contains("@") {
//                            chainId = achain.components(separatedBy: "@").last

                        if let c = TBWalletConnectManager.shared.getAllAvailabelConnecttions().first{
                            let controller = TBTransferToItController(context: strongSelf.context, wallet: .connect(c), inputAddress: rAddress)
                            strongSelf.push(controller)
                        }else{
                            TBWalletConnectManager.shared.connectToPlatform(platform: .metaMask, callBack: { ret, c in
                                if let c = c, ret {
                                    let controller = TBTransferToItController(context: strongSelf.context, wallet: .connect(c), inputAddress: rAddress)
                                    strongSelf.push(controller)
                                }
                            })
                        }
                    }
                })
                strongSelf.push(controller)
                break
            case .exportPrivateKey:
                if let wallet = self?.stateValue.with({$0.currentWallet}) {
                    let controller = TBExportPrivateKeyController(context: strongSelf.context, params: .init(wallet: wallet))
                    self?.push(controller)
                }
            case .creatWallet:
                strongSelf.push(TBCreatWalletController(context: strongSelf.context, params: .init()))
            }
        }
        
        self.segmentVC.headPercent = { [weak self] percent in
            guard let strongSelf = self else { return }
        }
    }
    
    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        let y:CGFloat = layout.statusBarHeight ?? 0
        self.segmentVC.view.frame = CGRect(origin:CGPoint(x: 0, y: y), size: CGSize(width: layout.size.width, height: layout.size.height - y))
    }
    
    func popNetwork() {
        
        let state = self.stateValue.with{$0}
        guard let config = state.config,
            let currentChain = state.currentChain,
            let index = config.chainType.firstIndex(of: currentChain) else { return }
        let popVc = TBPopController(context: self.context, canCloseByTouches: true)
        let node = TBSegmentNode()
        let size = node.updateSegment(title: "Networks", items: config.chainType, selectedIndex: index)
        node.cornerRadius = 12
        node.backgroundColor = UIColor.white
        node.closeEvent = {[weak popVc] in
            popVc?.dismiss(animated: true)
        }
        node.selectedSegmentEvent = {[weak popVc, weak self] chain in
            self?.updateState { current in
               var current = current
                current.currentChain = chain as? TBWeb3ConfigEntry.Chain
                return current
            }
            popVc?.dismiss(animated: true)
        }
        let screenSize = UIScreen.main.bounds.size
        popVc.setContentNode(node, frame: CGRect(origin: CGPoint(x: (screenSize.width - size.width) / 2, y: (screenSize.height - size.height) / 2), size: size))
        popVc.pop(from: self, transition: .immediate)
        DispatchQueue.main.async {
            node.updateLayout(size: size)
            node.updateData()
        }
    }
}
