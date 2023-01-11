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

public class TBStartBackUpMnemonicController: ViewController {
    
    public struct Params {
        let wallet: TBMyWalletModel
        let mnemonic: String
    }
    
    public let context: AccountContext
    private let hideNetworkActivityStatus: Bool
    private var presentationData: PresentationData
    private let presentationDataValue = Promise<PresentationData>()
    private var presentationDataDisposable: Disposable?
    private let params:Params
    
    private var contentView: TBStartBackUpMnemonicNodeView?
    
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
    }
    
    
    
    
    
    
    public override func displayNodeDidLoad() {
        super.displayNodeDidLoad()
        let contentView = TBStartBackUpMnemonicNodeView(context: self.context, controller: self, params: self.params)
        self.displayNode.view.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        contentView.outAction = { [weak self] type in
            guard let strongSelf = self else {
                return
            }
            switch type {
            case .back:
                strongSelf.dismiss(animated: true)
            case .start:
                let controller = TBConfirmBackUpMnemonicController(context: strongSelf.context, params: .init(wallet: strongSelf.params.wallet, mnemonic: strongSelf.params.mnemonic))
                strongSelf.push(controller)
            }
        }
        self.contentView = contentView
    }
    
    
    override public func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        self.contentView?.containerLayoutUpdated(layout, transition: transition)
        
    }
    
    
}

