import Foundation
import WalletConnectSwift
import TBStorage
import AccountContext
import SwiftSignalKit
import UIKit


public protocol WalletConnectDelegate {
    func failedToConnect()
    func didConnect()
    func didDisconnect()
}


public class TBWalletConnect {
    
    public enum Platform : String, Equatable {
        case qrCode = "qrCode"
        case metaMask = "metamask"
        case trust = "trust"
        case tokenpocket = "tpaps"
        case spot = "spot"
        case imtoken = "imtokenv2"
        
        static func platform(key:String) -> Platform{
            if key == Platform.metaMask.rawValue {
                return .metaMask
                
            }else if key == Platform.spot.rawValue{
                return .spot
            }else if key == Platform.trust.rawValue{
                return .trust
            }else if key == Platform.imtoken.rawValue{
                return .imtoken
            }else if key == Platform.tokenpocket.rawValue {
                return .tokenpocket
            }else{
                return .metaMask
            }
        }
    }
    
    public let platForm : Platform
    
    public let nameSpace : NameSpace
    
    private var subscriber: Subscriber<TBWalletConnect.CData, TBWalletConnect.CError>? {
        didSet {
            if let old = oldValue {
                
                old.putError(.pureFail(connect: self))
            }
        }
    }
    
    public var client: Client?
    
    public var session: Session?
    
    public var delegate: WalletConnectDelegate?
    public let context: AccountContext
    
    
    public var walletAccount: String? {
        return self.session?.walletInfo!.accounts[0]
    }
    
    public var walletName: String {
        let name = UserDefaults.standard.tb_getConnectWalletName(self, peerId: self.context.account.peerId.id._internalGetInt64Value())
        if name.isEmpty {
            return self.platForm.rawValue
        }else{
            return name
        }
    }
    
    public func changeWalletName(_ name: String) {
        UserDefaults.standard.tb_updateWalletStoreWithConnect(self, name: name, peerId: self.context.account.peerId.id._internalGetInt64Value())
    }
    
    public init(delegate: WalletConnectDelegate? = nil, context:AccountContext, platForm:Platform, session:Session? = nil) {
        self.delegate = delegate
        self.context = context
        self.platForm = platForm
        self.session = session
        
        self.nameSpace = NameSpace(peerId: self.context.account.peerId.id._internalGetInt64Value(), platform: self.platForm, mapKey:try! TBWalletConnect.randomKey(), creatTime: Date().timeIntervalSince1970)
    }
    
    deinit {
        debugPrint("[TB]TBWalletConnect ")
    }
    
    
    
    public func getAccountId() -> String {
        if let ret = self.walletAccount {
            return ret
        }else{
            return ""
        }
    }
    
    
     public func generateConnectWCUrl() -> WCURL {
        return WCURL(topic: UUID().uuidString,
//                     bridgeURL: URL(string: "https://safe-walletconnect.gnosis.io/")!,
                     bridgeURL: URL(string: "https://bridge.walletconnect.org")!,
                     key: try! TBWalletConnect.randomKey())
    }
    
    
    
    public func connect(wcUrl: WCURL? = nil) -> String {
        
        
        let realWCUrl: WCURL
        if let wcUrl = wcUrl {
            realWCUrl = wcUrl
        }else{
            realWCUrl = self.generateConnectWCUrl()
        }
        
        let clientMeta = Session.ClientMeta(name: "Alphagram",
                                            description: "WalletConnectSwift",
                                            icons: [],
                                            url: URL(string: "https://bridge.walletconnect.org")!,
                                            scheme: "alphagram"
        )
        let dAppInfo = Session.DAppInfo(peerId: UUID().uuidString, peerMeta: clientMeta)
        client = Client(delegate: self, dAppInfo: dAppInfo)
        
        print("WalletConnect URL: \(realWCUrl.absoluteString)")
        try! client?.connect(to: realWCUrl)
        
        
        switch self.platForm {
        case .imtoken:
            return realWCUrl.absoluteString_encode
        default:
            break
        }
        
        return realWCUrl.absoluteString
    }
    
    
    fileprivate func reconnectIfNeeded() {
        if let session = self.session {
            client = Client(delegate: self, dAppInfo: session.dAppInfo)
            try? client?.reconnect(to: session)
        }
    }
    
    
    private static func randomKey() throws -> String {
        var bytes = [Int8](repeating: 0, count: 32)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        if status == errSecSuccess {
            return Data(bytes: bytes, count: 32).toHexString()
        } else {
            
            enum TestError: Error {
                case unknown
            }
            throw TestError.unknown
        }
    }
    
    
    
    

    
    @objc public func TBWallet_SendTransaction(from:String ,to:String, chainType:String, value:String, contractAddress:String, callback: @escaping(String)->Void) {
        
        self.openCurrentWallet()
        
        if chainType == ETHChain {
            try? self.switchEthereumChain(url: self.session!.url, chainId: "0x1", completion: { [weak self] response in
//                 self?.handleReponse(response, expecting: "Hash")
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self?.openCurrentWallet()
                    
                    if contractAddress.count < 1 { 
                        let param = getChainParam(type:chainType)
                        let chainId = param.chainId
                        
                        self?.sendMainNetworkTransaction(to: to, value: value,chainId: chainId,callback: { respons in
                            print(respons)
                            callback(respons)
                        })
                    }else { 
                        self?.sendERC20Transaction(to: to, value: value,chainId: "0x1", contractAddress: contractAddress)
                    }
                }
            })

        }else {
            try? self.addChainForWallet(chainType: chainType) { [weak self] response in
//                 self?.handleReponse(response, expecting: "accounts")
                
                DispatchQueue.main.asyncAfter(deadline: .now()) {
                    self?.openCurrentWallet()
                }

                
                DispatchQueue.main.asyncAfter(deadline: .now()+5) {
                    let param = getChainParam(type:chainType)
                    let chainId = param.chainId
                    self?.sendMainNetworkTransaction(to: to, value: value,chainId: chainId,callback: { respons in
                        callback(respons)
                    })
                }
            }
        }
    }
    
    public func addChainForWallet(chainType:String, completion: @escaping Client.RequestResponse) throws {
        let param = getChainParam(type:chainType)
        let request = try Request(url: self.session!.url, method: "wallet_addEthereumChain", params: [param])
        try client?.send(request, completion: completion)
    }
    
    public func sendMainNetworkTransaction(to:String,value:String,chainId:String, callback:@escaping(String)->Void) {

            DispatchQueue.main.asyncAfter(deadline: .now()) {
                
                let transaction = TBWalletStub.transaction(from: self.walletAccount!, to: to, data: "", gas: "", value: value, nonce: "", chainId: chainId,gasPrice: "")
                try? self.client!.eth_sendTransaction(url: self.session!.url, transaction: transaction) { [weak self] response in
                    let hash = self?.handleReponse(response, expecting: "Hash")
                    print(hash!)
                    callback(hash!)
                }
            }

    }
    
    public func sendERC20Transaction(to:String,value:String,chainId:String,contractAddress:String) {
        


        let data = self.genERC20TranceData(from: self.walletAccount!, to: to, value: value)
        let transaction = TBWalletStub.transaction(from: self.walletAccount!, to: contractAddress, data: data, gas: "0x545c", value: "", nonce: "", chainId: chainId,gasPrice: "0x2cb417800")
                   
        try? self.client!.eth_sendTransaction(url: self.session!.url, transaction: transaction) { [weak self] response in
                self?.handleReponse(response, expecting: "Hash")
            }

    }
    
    func genERC20TranceData(from:String,to:String,value:String) -> String {

        let toAccount = self.stringCut0x(hexString: to)
        let toAddress  = self.stringPadzero(str: toAccount, number: 64)

        let valueString = self.stringCut0x(hexString: value)
        let tokenValue = self.stringPadzero(str:valueString, number:64)
        
        let data = "0xa9059cbb" + toAddress! + tokenValue!
        
        return data
    }
    
    func openCurrentWallet() {
        let platformString = self.platForm.rawValue
        let schemehead = platformString + "://"
        if UIApplication.shared.canOpenURL(URL(string: schemehead)!){
            UIApplication.shared.open(URL(string: schemehead)!)
        }
    }
    
    private func switchEthereumChain(url: WCURL, chainId: String, completion: @escaping Client.RequestResponse) throws {
        let param = ["chainId":chainId]
        let request = try Request(url: url, method: "wallet_switchEthereumChain", params: [param])
        try client?.send(request, completion: completion)
    }
    
    private func handleReponse(_ response: Response, expecting: String)->String {
        do {
            let result = try response.result(as: String.self)
            return result
        } catch{
            return ""
        }
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

}


extension TBWalletConnect: Equatable, Comparable{
    public static func == (lhs: TBWalletConnect, rhs: TBWalletConnect) -> Bool {
        return rhs.nameSpace == lhs.nameSpace
    }
    
    public static func < (lhs: TBWalletConnect, rhs: TBWalletConnect) -> Bool {
        return lhs.nameSpace < rhs.nameSpace
    }
    
    public static func > (lhs: TBWalletConnect, rhs: TBWalletConnect) -> Bool {
        return lhs.nameSpace > rhs.nameSpace
    }
    
    public struct NameSpace: Equatable, Comparable {
        public let peerId:Int64
        public let platform: Platform
        public let mapKey: String
        public let creatTime: TimeInterval
        public static func == (lhs: NameSpace, rhs: NameSpace) -> Bool {
            if lhs.peerId != rhs.peerId {
                return false
            }
            if lhs.platform != rhs.platform {
                return false
            }
            if lhs.mapKey != rhs.mapKey {
                return false
            }
            if lhs.creatTime != rhs.creatTime {
                return false
            }
            return true
        }
        
        public static func < (lhs: TBWalletConnect.NameSpace, rhs: TBWalletConnect.NameSpace) -> Bool {
            return lhs.creatTime < rhs.creatTime
        }
        
        public static func > (lhs: Self, rhs: Self) -> Bool {
            return lhs.creatTime > rhs.creatTime
        }
    }
    
}


public typealias TBWalletConnectSignal = Signal<TBWalletConnect.CData, TBWalletConnect.CError>

extension TBWalletConnect {
    
    
    public enum CData {
        case didConnectUrl(connect:TBWalletConnect, client: Client, url: WCURL)
        case didConnectSession(connect:TBWalletConnect, client: Client, session: Session)
        case didUpdateSession(connect:TBWalletConnect, client: Client, session: Session)
    }
    
    public enum CError {
        case pureFail(connect:TBWalletConnect)
        case cannotOpen(connect:TBWalletConnect)
        case didFailToConnect(connect:TBWalletConnect, client: Client, url: WCURL)
        case didDisConnectSession(connect:TBWalletConnect, client: Client, session: Session)
    }
    
    
    func connect_(wcUrl:WCURL? = nil) -> TBWalletConnectSignal {
        return Signal { subscriber in
            self.subscriber = subscriber
            let connectionUrl = self.connect(wcUrl: wcUrl)
            if self.platForm != .qrCode {
                
                
                
                let deepLinkUrl = "\(self.platForm.rawValue)://wc?uri=\(connectionUrl)"
//                let deepLinkUrl = "wc://\(self.platForm.rawValue)?uri=\(connectionUrl)"
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    if let url = URL(string: deepLinkUrl), UIApplication.shared.canOpenURL(url) {
                        print("open wc org url")
                        print(url)
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }else{
                        self.subscriber?.putError(.cannotOpen(connect: self))
                    }
                }
            }
            return EmptyDisposable
        }
    }
    
    
    func canReconnect() -> Bool {
        if let _ = self.session {
           return true
        }
        return false
    }

    
    func reConnect_() -> TBWalletConnectSignal {
        return Signal { subscriber in
            self.subscriber = subscriber
            if self.canReconnect() {
                let _ = self.reconnectIfNeeded()
            }else{
                self.subscriber?.putError(.pureFail(connect: self))
            }
            return EmptyDisposable
        }
        
    }
    
}


extension TBWalletConnect: ClientDelegate {
    public func client(_ client: Client, didFailToConnect url: WCURL) {
        self.delegate?.failedToConnect()
        self.subscriber?.putError(.didFailToConnect(connect: self, client: client, url: url))
    }
    
    public func client(_ client: Client, didConnect url: WCURL) {
        self.subscriber?.putNext(CData.didConnectUrl(connect: self, client: client, url: url))
        
    }
    
    public  func client(_ client: Client, didConnect session: Session) {
        self.session = session
        UserDefaults.standard.updateSession(context: self.context, platForm: self.platForm, session: session)
        self.delegate?.didConnect()
        self.subscriber?.putNext(CData.didConnectSession(connect: self, client: client, session: session))
       
    }
    
    public func client(_ client: Client, didDisconnect session: Session) {
        
        UserDefaults.standard.removeSession(context: self.context, platForm: self.platForm, session: session)
        self.delegate?.didDisconnect()
        self.subscriber?.putError(.didDisConnectSession(connect: self, client: client, session: session))
    }
    
    public func client(_ client: Client, didUpdate session: Session) {
        UserDefaults.standard.updateSession(context: self.context, platForm: self.platForm, session: session)
        self.subscriber?.putNext(CData.didUpdateSession(connect: self, client: client, session: session))
        
    }
    
}

fileprivate enum TBWalletStub {

    
    static func transaction(from address: String,
                            to:String,
                            data : String,
                            gas:String,
                            value:String,
                            nonce: String,
                            chainId:String,
                            gasPrice:String ) -> Client.Transaction {
        return Client.Transaction(from: address,
                                  to: to,
                                  data: data,
                                  gas: gas, 
                                  gasPrice: gasPrice, 
                                  value: value, 
                                  nonce: nonce,
                                  type: nil,
                                  accessList: nil,
                                  chainId: chainId,
                                  maxPriorityFeePerGas: nil,
                                  maxFeePerGas: nil)
    }
}
