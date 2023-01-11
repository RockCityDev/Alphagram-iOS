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



class TBMyWalletListController: ViewController {
    
    public struct Params {
        public let initialWallets: [TBWallet] 
        public let initialSelectWallet: TBWallet? 
        public let selectWallet:((TBWallet)->Void)? 
        public let importWallet:(()->Void)?
    }
    
    public let context: AccountContext
    private let params: Params
    private var contentView: TBMyWalletListView?
    private let hideNetworkActivityStatus: Bool
    private var presentationData: PresentationData
    private let presentationDataValue = Promise<PresentationData>()
    private var presentationDataDisposable: Disposable?
    
    public init(context: AccountContext, hideNetworkActivityStatus: Bool = false, params:Params) {
        self.context = context
        self.hideNetworkActivityStatus = hideNetworkActivityStatus
        
        self.presentationData = (context.sharedContext.currentPresentationData.with { $0 })
        self.presentationDataValue.set(.single(self.presentationData))
        self.params = params
        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData))
        self.displayNavigationBar = false
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
        let contentView = TBMyWalletListView(context: self.context, params: self.params)
        contentView.backgroundColor = .white
        contentView.action = { [weak self] type in
            guard let strongSelf = self else{ return }
            switch type {
            case .edit(let wallet):
                let controller = TBWalletSettingController(context: strongSelf.context, params: .init(wallet: wallet))
                strongSelf.push(controller)
            case .sort:
                ProgressHUD.showError("")
            case .close:
                strongSelf.dismiss(animated: true)
            case .importWallet:
                strongSelf.params.importWallet?()
            case .copyAddress(let wallet):
                UIPasteboard.general.string = wallet.walletAddress()
                ProgressHUD.showSucceed("")
            case let .selectWallet(wallet):
                strongSelf.dismiss(animated: false)
                strongSelf.params.selectWallet?(wallet)
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




