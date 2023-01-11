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

public class TBCreatWalletController: ViewController {
    
    public struct Params {
        
    }
    
    public let context: AccountContext
    private let hideNetworkActivityStatus: Bool
    private var presentationData: PresentationData
    private let presentationDataValue = Promise<PresentationData>()
    private var presentationDataDisposable: Disposable?
    private let params:Params
    
    private var contentView: TBCreatWalletNodeView?
    
    public init(context: AccountContext, params:Params, hideNetworkActivityStatus: Bool = false) {
        self.context = context
        self.params = params
        self.hideNetworkActivityStatus = hideNetworkActivityStatus
        
        self.presentationData = (context.sharedContext.currentPresentationData.with { $0 })
        self.presentationDataValue.set(.single(self.presentationData))
        
        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData))
        
        self.title = ""
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    deinit {
        self.presentationDataDisposable?.dispose()
    }
    
    
    
    
    
    
    public override func displayNodeDidLoad() {
        super.displayNodeDidLoad()
        let contentView = TBCreatWalletNodeView(context: self.context, controller: self, params: self.params)
        self.displayNode.view.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        contentView.outAction = {[weak self] type in
            guard let strongSelf = self else {
                return
            }
            switch type {
            case let .confirm(accountName):
                let entryView = TBEntryIndicatorView(status: .creat_wallet_creating)
                SwiftEntryKit.display(entry: entryView, using:.tb_center_fade_alert_indicator)
                
                
                let creatSignal: Signal<TBMyWalletModel?, NoError> = TBMyWalletManager.shared.creatAccount(tgUserId: strongSelf.context.account.peerId.id._internalGetInt64Value(), password: TBMyWalletManager.password, name: accountName) |> mapToSignal({ ret in
                    if ret {
                        return TBMyWalletManager.shared.pureGetAllAccounts(tgUserId: strongSelf.context.account.peerId.id._internalGetInt64Value(), password: TBMyWalletManager.password) |> map({$0.first})
                    }else{
                        return .single(nil)
                    }
                })

                let _ = (creatSignal |> deliverOnMainQueue).start(next: {
                    [weak self] wallet in
                    SwiftEntryKit.dismiss()
                    guard let strongSelf = self, let wallet = wallet else {
                        return
                    }
                    strongSelf.replace(with: TBCreatWalletRetController(context: strongSelf.context, params: .init(wallet: wallet)))
                })
            }
        }
        self.contentView = contentView
    }
    
    
    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        self.contentView?.containerLayoutUpdated(layout, transition: transition)
        
    }
    
    
}

