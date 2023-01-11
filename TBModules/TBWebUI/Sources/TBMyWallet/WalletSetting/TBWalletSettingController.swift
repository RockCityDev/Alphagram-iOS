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

class TBWalletSettingController: ViewController {
    
    public struct Params {
        let wallet: TBWallet
    }
    
    public let context: AccountContext
    private let params: Params
    private let hideNetworkActivityStatus: Bool
    private var presentationData: PresentationData
    private let presentationDataValue = Promise<PresentationData>()
    private var presentationDataDisposable: Disposable?
    private var contentView: TBWalletSettingView?
    
    public init(context: AccountContext, hideNetworkActivityStatus: Bool = false, params:Params) {
        self.context = context
        self.params = params
        self.hideNetworkActivityStatus = hideNetworkActivityStatus
        
        self.presentationData = (context.sharedContext.currentPresentationData.with { $0 })
        self.presentationDataValue.set(.single(self.presentationData))
        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData))
        self.displayNavigationBar = true
        self.title = ""
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
        let contentView = TBWalletSettingView(context: self.context, params: self.params)
        contentView.backgroundColor = UIColor(rgb: 0xF0F1F4)
        
        contentView.action = { [weak self] type in
            guard let strongSelf = self else{ return }
            switch type {
            case .changeWalletName(let wallet):
                let controller = TBEditWalletNameController(context: strongSelf.context, params: .init(wallet: wallet))
                strongSelf.push(controller)
            case .exportPrivateKey(let wallet):
                let controller = TBExportPrivateKeyController(context: strongSelf.context, params: .init(wallet: wallet))
                strongSelf.push(controller)
            case .exportMnemonic(let wallet):
                ProgressHUD.showError("")
            case .disconnecWallet(let c):
                TBWalletConnectManager.shared.disconnect(connect: c)
                strongSelf.dismiss(animated: true)
            case .deleteWallet(let mine):
                ProgressHUD.showError("")
            }
        }
        self.displayNode.view.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.top.leading.trailing.bottom.equalTo(self.displayNode.view)
        }
        self.contentView = contentView
    }
    
    
    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        let navLayout = navigationLayout(layout: layout)
        self.contentView?.snp.updateConstraints({ make in
            make.top.equalTo(self.displayNode.view).offset(navLayout.navigationFrame.maxY)
        })
    }

}

