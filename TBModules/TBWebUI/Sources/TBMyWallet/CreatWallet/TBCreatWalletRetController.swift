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
import SwiftEntryKit
import TBDisplay
import ProgressHUD

public class TBCreatWalletRetController: ViewController {
    
    public struct Params {
        let wallet: TBMyWalletModel
    }
    
    public let context: AccountContext
    private let hideNetworkActivityStatus: Bool
    private var presentationData: PresentationData
    private let presentationDataValue = Promise<PresentationData>()
    private var presentationDataDisposable: Disposable?
    private let params:Params
    
    private var contentView: TBCreatWalletRetNodeView?
    
    public init(context: AccountContext, params:Params, hideNetworkActivityStatus: Bool = false) {
        self.context = context
        self.params = params
        self.hideNetworkActivityStatus = hideNetworkActivityStatus
        
        self.presentationData = (context.sharedContext.currentPresentationData.with { $0 })
        self.presentationDataValue.set(.single(self.presentationData))
        
        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData))
        self.displayNavigationBar = false
        self.title = ""
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    deinit {
        self.presentationDataDisposable?.dispose()
        TBMyWalletManager.shared.cacheCreatMyWalletMnemonic = nil
    }
    
    
    
    
    
    
    public override func displayNodeDidLoad() {
        super.displayNodeDidLoad()
        let contentView = TBCreatWalletRetNodeView(context: self.context, controller: self, params: self.params)
        self.displayNode.view.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        contentView.outAction = {[weak self] type in
            guard let strongSelf = self else {
                return
            }
            switch type {
            case let .copy(myWallet):
                UIPasteboard.general.string = myWallet.walletAddress()
                ProgressHUD.showSucceed("")
            case let .exportPrivateKey(myWallet):
                let controller = TBExportPrivateKeyController(context: strongSelf.context, params: .init(wallet: .mine(myWallet)))
                strongSelf.push(controller)
            case let .backUpMnemonic(myWallet):
                if let latestMnemonic = TBMyWalletManager.shared.cacheCreatMyWalletMnemonic, !latestMnemonic.isEmpty {
                    let controller = TBStartBackUpMnemonicController(context: strongSelf.context, params: .init(wallet: myWallet, mnemonic: latestMnemonic))
                    strongSelf.push(controller)
                }else{
                    debugPrint("")
                }
            case .returnHome:
                strongSelf.dismiss(animated: true)
            case .close:
                strongSelf.dismiss(animated: true)
            }
        }
        self.contentView = contentView
    }
    
    private func importWalletResultHandle(ret: Bool) {
        if ret {
            let entryView = TBEntryRetView(status: .import_wallet_success)
            entryView.btnAction = { [weak self] in
                SwiftEntryKit.dismiss()
                self?.dismiss()
            }
            SwiftEntryKit.display(entry: entryView, using: .tb_center_fade_alert)
        }else{
            let entryView = TBEntryRetView(status: .import_wallet_failed)
            entryView.btnAction = { [weak self] in
                SwiftEntryKit.dismiss()
            }
            SwiftEntryKit.display(entry: entryView, using: .tb_center_fade_alert)
        }
    }
    
    
    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        self.contentView?.containerLayoutUpdated(layout, transition: transition)
        
    }
    
    
}

