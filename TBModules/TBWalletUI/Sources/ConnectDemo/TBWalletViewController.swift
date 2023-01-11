






import Foundation
import Display
import AccountContext
import TelegramPresentationData
import AsyncDisplayKit
import SnapKit
import ProgressHUD
import TBWalletCore
import SwiftSignalKit


 public class TBWalletViewController:ViewController {
     private let context : AccountContext
     private let presentationData: PresentationData
     
     private let directConnectBtn: UIButton
     private let qrCodeConnectBtn: UIButton
     
     var handshakeController: TBWalletHandshakeViewController!
     var actionsController: TBWalletActionViewController!
     var walletConnect: TBWalletConnect!
     
     public init(context: AccountContext) {
         self.context = context
         self.presentationData = context.sharedContext.currentPresentationData.with { $0 }
         
         self.directConnectBtn = UIButton(type: .system)
         self.directConnectBtn.setTitle("app", for: .normal)
         self.directConnectBtn.setTitleColor(.black, for: .normal)
         self.directConnectBtn.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        
         
         self.qrCodeConnectBtn = UIButton(type: .system)
         self.qrCodeConnectBtn.setTitle("QRCode", for: .normal)
         self.qrCodeConnectBtn.setTitleColor(.black, for: .normal)
         self.qrCodeConnectBtn.titleLabel?.font = UIFont.systemFont(ofSize: 13)
         
         let baseNavigationBarPresentationData = NavigationBarPresentationData(presentationData: self.presentationData)
         
         super.init(navigationBarPresentationData: NavigationBarPresentationData(
             theme: NavigationBarTheme(
                 buttonColor: baseNavigationBarPresentationData.theme.buttonColor,
                 disabledButtonColor: baseNavigationBarPresentationData.theme.disabledButtonColor,
                 primaryTextColor: baseNavigationBarPresentationData.theme.primaryTextColor,
                 backgroundColor: .clear,
                 enableBackgroundBlur: false,
                 separatorColor: .clear,
                 badgeBackgroundColor: baseNavigationBarPresentationData.theme.badgeBackgroundColor,
                 badgeStrokeColor: baseNavigationBarPresentationData.theme.badgeStrokeColor,
                 badgeTextColor: baseNavigationBarPresentationData.theme.badgeTextColor
         ), strings: baseNavigationBarPresentationData.strings))
         
        
         self.title = ""
         self.tabBarItem.title = nil
     }
     
     public override func displayNodeDidLoad() {
         super.displayNodeDidLoad()
         
         self.directConnectBtn.addTarget(self, action: #selector(self.tapConnectAction(_:)), for: .touchUpInside)
         self.qrCodeConnectBtn.addTarget(self, action: #selector(self.tapQrCodeConnectAction(_:)), for: .touchUpInside)
         
         self.view.addSubview(self.directConnectBtn)
         self.view.addSubview(self.qrCodeConnectBtn)
         self.directConnectBtn.snp.makeConstraints { make in
             make.top.equalTo(200)
             make.centerX.equalTo(self.view.snp.centerX)
         }
         self.qrCodeConnectBtn.snp.makeConstraints { make in
             make.top.equalTo(self.directConnectBtn.snp.bottom).offset(20)
             make.centerX.equalTo(self.view.snp.centerX)
         }
         self.view.backgroundColor = .white
        
     }
     
     func onMainThread(_ closure: @escaping () -> Void) {
         if Thread.isMainThread {
             closure()
         } else {
             DispatchQueue.main.async {
                 closure()
             }
         }
     }
     
     
     @objc func tapConnectAction(_ sender: Any?) {
         
         self.walletConnect = TBWalletConnect(delegate: self, context: self.context, platForm: .metaMask)
         TBWalletConnectManager.shared.connect(c:self.walletConnect)
     }
     
     @objc func tapQrCodeConnectAction(_ sender: Any?) {
         
         self.walletConnect = TBWalletConnect(delegate: self, context: self.context, platForm: .qrCode)
         
         let wcUrl = self.walletConnect.generateConnectWCUrl()
         TBWalletConnectManager.shared.connect(c: self.walletConnect, wcUrl: wcUrl)

         
         self.handshakeController = TBWalletHandshakeViewController(context: self.context, code: wcUrl.absoluteString)
         DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
             self.present(self.handshakeController, animated: true)
         }
     }
     
     required init(coder aDecoder: NSCoder) {
         fatalError("init(coder:) has not been implemented")
     }
     
     override public func viewDidAppear(_ animated: Bool) {
         super.viewDidAppear(animated)
         let connects = TBWalletConnectManager.shared.getAllAvailabelConnecttions()
         if connects.count > 0 {
             self.walletConnect = connects.last
             self.didConnect()
         }else{
             self.walletConnect = nil
             self.didDisconnect()
         }
     }
     
    
}


extension TBWalletViewController: WalletConnectDelegate {
    
   public func failedToConnect() {
        onMainThread { [unowned self] in
            if let handshakeController = self.handshakeController {
                handshakeController.dismiss(animated: true)
                self.handshakeController = nil
            }
            UIAlertController.showFailedToConnect(from: self)
        }
    }

    public func didConnect() {
        
        
        onMainThread { [unowned self] in
            let actionsController = TBWalletActionViewController(context:self.context, walletConnect:self.walletConnect)
            if let handshakeController = self.handshakeController {
                handshakeController.dismiss(animated: false) { [unowned self] in
                    self.handshakeController = nil
                }
                self.actionsController = actionsController
                afterOnMainQueue { [unowned self] in
                    self.present(self.actionsController, animated: false)
                }
            } else if let actionVC = self.actionsController {
                self.actionsController = actionsController
                actionVC.dismiss(animated: false) {[unowned self] in
                }
                afterOnMainQueue { [unowned self] in
                    self.present(actionsController, animated: false)
                }
               
            }else{
                self.actionsController = actionsController
                self.present(actionsController, animated: false)
            }
        }
    }

    public func didDisconnect() {
        onMainThread { [unowned self] in
            
            
            
            if let controller = self.actionsController {
                controller.dismiss(animated: false)
                self.actionsController = nil
            }
            
        }
    }
}

private func afterOnMainQueue(time:CGFloat = 0.5, action:@escaping ()->Void){
    DispatchQueue.main.asyncAfter(deadline: .now() + time) {
        action()
    }

}

extension UIAlertController {
    func withCloseButton() -> UIAlertController {
        addAction(UIAlertAction(title: "Close", style: .cancel))
        return self
    }

    static func showFailedToConnect(from controller: UIViewController) {
        
        ProgressHUD.showError("Failed to connect")
//        let alert = UIAlertController(title: "Failed to connect", message: nil, preferredStyle: .alert)

    }

    static func showDisconnected(from controller: UIViewController) {
        ProgressHUD.showError("Did disconnect")
//        let alert = UIAlertController(title: "Did disconnect", message: nil, preferredStyle: .alert)

    }
}

