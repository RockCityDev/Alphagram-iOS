






import Foundation
import Display
import AccountContext
import TelegramPresentationData
import AsyncDisplayKit
import SnapKit
import WalletConnectSwift
import ProgressHUD
import TBAccount
import SDWebImage
import UIKit
import TBOpenSea
import TBWalletCore
import TBWalletCore



 public class TBWalletActionViewController:ViewController {
     private let context : AccountContext
     private let presentationData: PresentationData
     
     private let disconnectButton: UIButton
     private let personalSignButton: UIButton
     private let ethSignButton: UIButton
     private let ethSignTypedDataButton: UIButton
     private let ethSendTransactionButton: UIButton
     private let ethSignTransactionButton: UIButton
     private let ethSendRawTransactionButton: UIButton
     private let ethCustomRequestButton: UIButton
     private let retrieveAssetsButton : UIButton
     private let assetsImageView: UIImageView
     
     var client: Client!
     var session: Session!
     var platform : TBWalletConnect.Platform!
     var walletConnect :TBWalletConnect?
     
     var walletAccount: String {
         return self.session.walletInfo!.accounts[0]
     }

     public init(context: AccountContext, walletConnect: TBWalletConnect) {
         
         
         self.walletConnect = walletConnect
         self.client = walletConnect.client
         self.session = walletConnect.session
         self.platform = walletConnect.platForm
         
         self.disconnectButton = UIButton(type: .system)
         self.disconnectButton.setTitle("disconnect", for: .normal)
         self.personalSignButton = UIButton(type: .system)
         self.personalSignButton.setTitle("SendTT", for: .normal)
         self.ethSignButton = UIButton(type: .system)
         self.ethSignButton.setTitle("SendOsiss", for: .normal)
         self.ethSignTypedDataButton = UIButton(type: .system)
         self.ethSignTypedDataButton.setTitle("USDT", for: .normal)
         self.ethSendTransactionButton = UIButton(type: .system)
         self.ethSendTransactionButton.setTitle("eth Send Transaction", for: .normal)
         self.ethSignTransactionButton = UIButton(type: .system)
         self.ethSignTransactionButton.setTitle("eth Sign Transaction", for: .normal)
         self.ethSendRawTransactionButton = UIButton(type: .system)
         self.ethSendRawTransactionButton.setTitle("eth Send Raw Transaction", for: .normal)
         self.ethCustomRequestButton = UIButton(type: .system)
         self.ethCustomRequestButton.setTitle("eth Custom Request", for: .normal)
         self.retrieveAssetsButton = UIButton(type: .system)
         self.retrieveAssetsButton.setTitle("", for:.normal)
         self.assetsImageView = UIImageView()
         self.assetsImageView.contentMode = .scaleAspectFit
         
         self.context = context
         self.presentationData = context.sharedContext.currentPresentationData.with { $0 }
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
         self.title = "Actions"
         self.tabBarItem.title = nil
     }
     
     public override func displayNodeDidLoad() {
         super.displayNodeDidLoad()
         self.view.backgroundColor = .white
         
         self.disconnectButton.addTarget(self, action: #selector(self.disconnect(_:)), for: .touchUpInside)
         self.personalSignButton.addTarget(self, action: #selector(self.test_TBWallet_SendTransaction_tt(_:)), for: .touchUpInside)
         self.ethSignButton.addTarget(self, action: #selector(self.test_TBWallet_SendTransaction_oasis(_:)), for: .touchUpInside)
         self.ethSignTypedDataButton.addTarget(self, action: #selector(self.test_TBWallet_SendTransaction_ERC20_USDT(_:)), for: .touchUpInside)

         self.ethSendTransactionButton.addTarget(self, action: #selector(self.eth_sendERC20Transaction(_:)), for: .touchUpInside)

         self.ethSignTransactionButton.addTarget(self, action: #selector(self.eth_signTransaction(_:)), for: .touchUpInside)
         self.ethSendRawTransactionButton.addTarget(self, action: #selector(self.eth_sendRawTransaction(_:)), for: .touchUpInside)

         
         self.ethCustomRequestButton.addTarget(self, action: #selector(self.customRequest(_:)), for: .touchUpInside)
         self.retrieveAssetsButton.addTarget(self, action: #selector(self.retrieveAssets(_:)), for: .touchUpInside)
         
         self.view.addSubview(self.disconnectButton)
         self.view.addSubview(self.personalSignButton)
         self.view.addSubview(self.ethSignButton)
         self.view.addSubview(self.ethSignTypedDataButton)
         self.view.addSubview(self.ethSendTransactionButton)
         self.view.addSubview(self.ethSignTransactionButton)
         self.view.addSubview(self.ethSendRawTransactionButton)
         self.view.addSubview(self.ethCustomRequestButton)
         self.view.addSubview(self.retrieveAssetsButton)
         self.view.addSubview(self.assetsImageView)
         
         
         self.disconnectButton.snp.makeConstraints { make in
             make.centerX.equalTo(self.view.snp.centerX)
             make.top.equalTo(100)
         }
         
         self.personalSignButton.snp.makeConstraints { make in
             make.centerX.equalTo(self.view.snp.centerX)
             make.top.equalTo(self.disconnectButton.snp.bottom).offset(10)
         }
         self.ethSignButton.snp.makeConstraints { make in
             make.centerX.equalTo(self.view.snp.centerX)
             make.top.equalTo(self.personalSignButton.snp.bottom).offset(10)
         }
         self.ethSignTypedDataButton.snp.makeConstraints { make in
             make.centerX.equalTo(self.view.snp.centerX)
             make.top.equalTo(self.ethSignButton.snp.bottom).offset(10)
         }
         self.ethSendTransactionButton.snp.makeConstraints { make in
             make.centerX.equalTo(self.view.snp.centerX)
             make.top.equalTo(self.ethSignTypedDataButton.snp.bottom).offset(10)
         }
         self.ethSignTransactionButton.snp.makeConstraints { make in
             make.centerX.equalTo(self.view.snp.centerX)
             make.top.equalTo(self.ethSendTransactionButton.snp.bottom).offset(10)
         }
         self.ethSendRawTransactionButton.snp.makeConstraints { make in
             make.centerX.equalTo(self.view.snp.centerX)
             make.top.equalTo(self.ethSignTransactionButton.snp.bottom).offset(10)
         }
         self.ethCustomRequestButton.snp.makeConstraints { make in
             make.centerX.equalTo(self.view.snp.centerX)
             make.top.equalTo(self.ethSendRawTransactionButton.snp.bottom).offset(10)
         }
         self.retrieveAssetsButton.snp.makeConstraints { make in
             make.centerX.equalTo(self.view.snp.centerX)
             make.top.equalTo(self.ethCustomRequestButton.snp.bottom).offset(10)
         }
         
         self.assetsImageView.snp.makeConstraints { make in
             make.centerY.equalTo(self.retrieveAssetsButton)
             make.leading.equalTo(self.retrieveAssetsButton.snp.trailing).offset(50)
             make.width.height.equalTo(30)
         }
     }
     
     required init(coder aDecoder: NSCoder) {
         fatalError("init(coder:) has not been implemented")
     }
     
     
     @objc func disconnect(_ sender: Any) {
         guard let session = session else { return }
         try? client.disconnect(from: session)
     }
     

     
     @objc func personal_sign(_ sender: Any) {
         try? client.personal_sign(url: session.url, message: "Hi there!", account: session.walletInfo!.accounts[0]) {
             [weak self] response in
             self?.handleReponse(response, expecting: "Signature")
         }
     }

     @objc func eth_sign(_ sender: Any) {
     // eth_sign should send a properly formed hash: keccak256("\x19Ethereum Signed Message:\n" + len(message) + message))
         if UIApplication.shared.canOpenURL(URL(string: "metamask://")!){
             UIApplication.shared.open(URL(string: "metamask://")!)
         }
         try? client.eth_sign(url: session.url, account: session.walletInfo!.accounts[0], message: "0x0123") {
             [weak self] response in
             self?.handleReponse(response, expecting: "Signature")
         }
     }

     @objc func eth_signTypedData(_ sender: Any) {
         if UIApplication.shared.canOpenURL(URL(string: "metamask://")!){
             UIApplication.shared.open(URL(string: "metamask://")!)
         }
         try? client.eth_signTypedData(url: session.url,
                                       account: session.walletInfo!.accounts[0],
                                       message: Stub.typedData) {
             [weak self] response in
             self?.handleReponse(response, expecting: "Signature") }
     }
     
     
     

     
     
     
     @objc func eth_sendTransaction_in_TT(_ sender: Any) {
         if UIApplication.shared.canOpenURL(URL(string: "metamask://")!){
             UIApplication.shared.open(URL(string: "metamask://")!)
         }
         try? client.send(nonceRequest()) { [weak self] response in
             guard let self = self, let nonce = self.nonce(from: response) else { return }

             let testTo = "0x02dEB501820bC9C37e9815b4702bAd96edf1740D"
             let value = "0x53444835ec580000" 
             let transaction = Stub.transaction(from: self.walletAccount, to: testTo, data: "", gas: "", value: value, nonce: "", chainId: "")
             try? self.client.eth_sendTransaction(url: response.url, transaction: transaction) { [weak self] response in
                 self?.handleReponse(response, expecting: "Hash")
             }
         }
     }
     
     

     
     
     @objc func eth_sendTransaction(_ sender: Any) {
         
         

         if UIApplication.shared.canOpenURL(URL(string: "metamask://")!){
             UIApplication.shared.open(URL(string: "metamask://")!)
         }
         try? client.send(nonceRequest()) { [weak self] response in
             guard let self = self, let nonce = self.nonce(from: response) else { return }

             let testTo = "0x02dEB501820bC9C37e9815b4702bAd96edf1740D"
             let value = "0x53444835ec580000" 
             let transaction = Stub.transaction(from: self.walletAccount, to: testTo, data: "", gas: "", value: value, nonce: "", chainId: "")
             try? self.client.eth_sendTransaction(url: response.url, transaction: transaction) { [weak self] response in
                 self?.handleReponse(response, expecting: "Hash")
             }
         }
     }
     
     @objc func eth_sendERC20Transaction(_ sender: Any) {
         
         

         if UIApplication.shared.canOpenURL(URL(string: "metamask://")!){
             UIApplication.shared.open(URL(string: "metamask://")!)
         }
         
         let contractAddress = "0xdAC17F958D2ee523a2206206994597C13D831ec7"
         
         try? client.send(nonceRequest()) { [weak self] response in
             guard let self = self, let nonce = self.nonce(from: response) else { return }

             let testTo = "0x02dEB501820bC9C37e9815b4702bAd96edf1740D"
             let data = self.getERC20TranceData(from: self.walletAccount, to: testTo, value: 6.0, decimals: 6)
             let transaction = Stub.transaction(from: self.walletAccount, to: contractAddress, data: data, gas: "", value: "", nonce: "", chainId: "")
                    
             try? self.client.eth_sendTransaction(url: response.url, transaction: transaction) { [weak self] response in
                 self?.handleReponse(response, expecting: "Hash")
             }
         }
     }
     
     
     func getERC20TranceData(from:String,to:String,value:Float,decimals :Float) -> String {
         let tranceValue = UInt64(value * pow(10, decimals))

//         let tokenString = String(format: "%0X", tranceValue)
         let tokenString = String(tranceValue,radix:16)
         let tokenValue = self.stringPadzero(str:tokenString, number:64)
         
         let toAccount = self.stringCut0x(hexString: to)
         let toAddress  = self.stringPadzero(str: toAccount, number: 64)
         let data = "0xa9059cbb" + toAddress! + tokenValue!
         
         return data
     }
     
     func stringPadzero(str:String, number:Int) -> String? {
         if str.count == 0 {
             return nil;
         }
         
         if (str.count >= number) {
             return str;
         }
         
         let paddingCount = number - str.count;
         var paddingStr :String = ""
         
         for _ in 0..<paddingCount {
             paddingStr.append("0")
         }
         
         paddingStr.append(str)
         
         return paddingStr;
     }
     
     func stringCut0x(hexString:String) -> String {
         
         if  hexString.hasPrefix("0x") || hexString.hasPrefix("0X") {
             let newStr = hexString.suffix(hexString.count - 2)
             return String(newStr)
         }
         return hexString
     }


     

     @objc func eth_signTransaction(_ sender: Any) {
//         let transaction = Stub.transaction(from: self.walletAccount, nonce: "0x0")

//             self?.handleReponse(response, expecting: "Signature")

     }

     @objc func eth_sendRawTransaction(_ sender: Any) {
         try? client.eth_sendRawTransaction(url: session.url, data: Stub.data) { [weak self] response in
             self?.handleReponse(response, expecting: "Hash")
         }
     }
     
     
     
     
     
     @objc func wallet_add_TTChain(_ sender: Any) {
         
//         if UIApplication.shared.canOpenURL(URL(string: "metamask://")!){
//             UIApplication.shared.open(URL(string: "metamask://")!)


//         try? self.addChainForWallet(url: session.url, chainId: "0x12") { [weak self] response in
//             self?.handleReponse(response, expecting: "Hash")

     }
     


     
     
     
     @objc func wallet_switchEthereumChain(_ sender: Any) {
         try? self.switchEthereumChain(url: session.url, chainId: "0x89") { [weak self] response in
             self?.handleReponse(response, expecting: "Hash")
         }
     }
     private func switchEthereumChain(url: WCURL, chainId: String, completion: @escaping Client.RequestResponse) throws {
         let param = ["chainId":chainId]
         let request = try Request(url: url, method: "wallet_switchEthereumChain", params: [param])
         try client?.send(request, completion: completion)
     }

     @objc func customRequest(_ sender: Any) {
         
         
         try? client.send(.eth_gasPrice(url: session.url)) { [weak self] response in
             self?.handleReponse(response, expecting: "Gas Price")
         }
     }
     
     @objc func retrieveAssets(_ sender: Any) {
         
         let fields = [
            "order_direction":"desc",
            "limit":"20",
            "include_orders":"false",
            "owner":"0xe89552758DEcfa70f60611413a848055842289fD",
            //"asset_contract_address":self.walletAccount,
         ]
         TBOpensea().retrieveAssets(apiKey: TBAccount.shared.systemCheckData.openseaapikey, fields: fields) { assets, error in
             if let assets = assets, !assets.assets.isEmpty {
                 if let item = assets.assets.first, !item.image_url.isEmpty {
                     self.assetsImageView.sd_setImage(with: URL(string: item.image_url)!)
                 }
             }
         }
     }


     @objc func close(_ sender: Any) {
         for session in client.openSessions() {
             try? client.disconnect(from: session)
         }
         dismiss(animated: true)
     }
     
     private func handleReponse(_ response: Response, expecting: String)->String {
         do {
             let result = try response.result(as: String.self)
             return result
         } catch{
             return ""
         }




////                 self.show(UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert))
//                 ProgressHUD.showError("\(error.localizedDescription)")






//                 ProgressHUD.showSucceed("title: \(expecting)\n\(result)")

//                 ProgressHUD.showError("Unexpected response type error: \(error)")
////                 self.show(UIAlertController(title: "Error",
////                                        message: "Unexpected response type error: \(error)",



     }

     private func show(_ alert: UIAlertController) {
         alert.addAction(UIAlertAction(title: "Close", style: .cancel))
         self.present(alert, animated: true)
     }

     private func nonceRequest() -> Request {
         return .eth_getTransactionCount(url: session.url, account: session.walletInfo!.accounts[0])
     }

     private func nonce(from response: Response) -> String? {
         return try? response.result(as: String.self)
     }
     
     
     
     
     @objc public func test_TBWallet_SendTransaction_tt(_ sender: Any) {
         let testTo = "0x02dEB501820bC9C37e9815b4702bAd96edf1740D"
         let value = "0x2386f26fc10000" 

         
         self.walletConnect!.TBWallet_SendTransaction(from:"", to: testTo, chainType: TTChain, value: value, contractAddress: "",callback: { respons in
             print(respons)
         })
     }
     
     
     @objc public func test_TBWallet_SendTransaction_oasis(_ sender: Any) {
         let testTo = "0x02dEB501820bC9C37e9815b4702bAd96edf1740D"
         let value = "0x3e8" 
         
         self.walletConnect!.TBWallet_SendTransaction(from:"" ,to: testTo, chainType: OasisChain, value: value, contractAddress: "",callback: { respons in
             print(respons)
         })
     }
     
     
     
     @objc public func test_TBWallet_SendTransaction_ERC20_USDT(_ sender: Any) {
         let testTo = "0x02dEB501820bC9C37e9815b4702bAd96edf1740D"
         let value = "0x3e8" 
         
         self.walletConnect!.TBWallet_SendTransaction(from:"", to: testTo, chainType: ETHChain, value: value,contractAddress: "0xdAC17F958D2ee523a2206206994597C13D831ec7",callback: { respons in
             print(respons)
         })
     }
}

extension Request {
    static func eth_getTransactionCount(url: WCURL, account: String) -> Request {
        return try! Request(url: url, method: "eth_getTransactionCount", params: [account, "latest"])
    }

    static func eth_gasPrice(url: WCURL) -> Request {
        return Request(url: url, method: "eth_gasPrice")
    }
}

fileprivate enum Stub {
    
    static let typedData = """
{
    "types": {
        "EIP712Domain": [
            {
                "name": "name",
                "type": "string"
            },
            {
                "name": "version",
                "type": "string"
            },
            {
                "name": "chainId",
                "type": "uint256"
            },
            {
                "name": "verifyingContract",
                "type": "address"
            }
        ],
        "Person": [
            {
                "name": "name",
                "type": "string"
            },
            {
                "name": "wallet",
                "type": "address"
            }
        ],
        "Mail": [
            {
                "name": "from",
                "type": "Person"
            },
            {
                "name": "to",
                "type": "Person"
            },
            {
                "name": "contents",
                "type": "string"
            }
        ]
    },
    "primaryType": "Mail",
    "domain": {
        "name": "Ether Mail",
        "version": "1",
        "chainId": 1,
        "verifyingContract": "0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC"
    },
    "message": {
        "from": {
            "name": "Cow",
            "wallet": "0xCD2a3d9F938E13CD947Ec05AbC7FE734Df8DD826"
        },
        "to": {
            "name": "Bob",
            "wallet": "0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB"
        },
        "contents": "Hello, Bob!"
    }
}
"""

    
    static func transaction(from address: String,
                            to:String,
                            data : String,
                            gas:String,
                            value:String,
                            nonce: String,
                            chainId:String) -> Client.Transaction {
        return Client.Transaction(from: address,
                                  to: to,
                                  data: data,
                                  gas: "", 
                                  gasPrice: "", 
                                  value: value, 
                                  nonce: nonce,
                                  type: nil,
                                  accessList: nil,
                                  chainId: chainId,
                                  maxPriorityFeePerGas: nil,
                                  maxFeePerGas: nil)
    }
    
    











//                                  data: "",
//                                  gas: "", 
//                                  gasPrice: "", 










    
    static let data = "0xd46e8dd67c5d32be8d46e8dd67c5d32be8058bb8eb970870f072445675058bb8eb970870f072445675"
    
    
    
    
    
    








//    //    outStr = self.stringToHexString(String(format: "%lld", value)


//        return self.stringToHexString(String(format: "%lld", value))




//        var  hexStr = String(format: "0x%llx", value.longLongValue)
//        //[NSString stringWithFormat:@"0x%llx",[string longLongValue]];





//        if (!(value.hasPrefix("0x") || value.hasPrefix("0X"))){
//            res = String(format: "0x%@", value)





}




