import Foundation
import UIKit
import AsyncDisplayKit
import Display
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import AppBundle
import AccountContext
import PresentationDataUtils
import TBWeb3Core
import Web3swift
import Web3swiftCore
import TBWalletCore
import ProgressHUD

class TBAddWalletController: ViewController {
    
    public struct Params {
    }
    
    public let context: AccountContext
    private let params: Params
    private let hideNetworkActivityStatus: Bool
    private var presentationData: PresentationData
    private let presentationDataValue = Promise<PresentationData>()
    private var presentationDataDisposable: Disposable?
    private var contentView: TBAddWalletView?
    
    public init(context: AccountContext, hideNetworkActivityStatus: Bool = false, params:Params) {
        self.context = context
        self.params = params
        self.hideNetworkActivityStatus = hideNetworkActivityStatus
        
        self.presentationData = (context.sharedContext.currentPresentationData.with { $0 })
        self.presentationDataValue.set(.single(self.presentationData))
        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData))
        self.displayNavigationBar = false
        self.navigationPresentation = .default
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.presentationDataDisposable?.dispose()
    }
    
    
    
    
    
    
    public override func displayNodeDidLoad() {
        super.displayNodeDidLoad()
        let contentView = TBAddWalletView(context: self.context, params: self.params)
        contentView.backgroundColor = .white
        
        contentView.action = { [weak self] type in
            guard let strongSelf = self else{ return }
            switch type {
            case .creatWallet:
                let controller = TBCreatWalletController(context: strongSelf.context, params: .init())
                strongSelf.push(controller)
            case .importWallet:
                let controller = TBImportWalletController(context: strongSelf.context, params: .init())
                strongSelf.push(controller)
            case .connectWallet(let c):
                if let c = c {
                    TBWalletConnectManager.shared.disconnect(connect: c)
                    TBWalletConnectManager.shared.connectToPlatform(platform: .metaMask)
                }else{
                    TBWalletConnectManager.shared.connectToPlatform(platform: .metaMask)
                }
                break
            case .focusWallet:
                ProgressHUD.showError("")
            case .close, .back, .cancel:
                strongSelf.dismiss(animated: true)
            }
        }
        self.displayNode.view.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(self.displayNode.view)
        }
        self.contentView = contentView
    }
    
    
    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        
    }
    
    
}

