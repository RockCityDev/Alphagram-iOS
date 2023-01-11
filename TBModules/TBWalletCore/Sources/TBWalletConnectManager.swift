import Foundation
import TBStorage
import AccountContext
import SwiftSignalKit
import Compression
import UIKit
import WalletConnectSwift
import TBAccount
import Web3swift
import Web3swiftCore
import TBTrack

public typealias TBWalletConnectCallBack = (Bool, TBWalletConnect?) -> Void



public class TBWalletConnectManager {
    
    
    public static let shared = TBWalletConnectManager()
    
    
    private let availabelPlatforms:[TBWalletConnect.Platform] = [.metaMask]
    
    
    private var connectionsMap = [String : TBWalletConnect]()
    
    
    private var availableConnections = [TBWalletConnect]() {
        didSet {
            self._availabelConnectionsPromise.set(self.availableConnections)
        }
    }
    private let _availabelConnectionsPromise = ValuePromise([TBWalletConnect](), ignoreRepeated: true)
    public var availabelConnectionsSignal: Signal<[TBWalletConnect], NoError> {
        return self._availabelConnectionsPromise.get()
    }
    
    
    private var context: AccountContext? {
        didSet {
            if let old = oldValue, let new = self.context {
                if old.account.peerId.id._internalGetInt64Value() != new.account.peerId.id._internalGetInt64Value(){
                    self.resetAll()
                }
            }
        }
    }
    
    init() {
        self.testWeb3Swift()
    }
    
    public func getAllAvailabelConnecttions() ->[TBWalletConnect] {
        return self.availableConnections
    }
    
    public func setup(context:AccountContext) {
        self.context = context
    }
    
    
    
    
    public func canOpenWalletApp(platform:TBWalletConnect.Platform) ->Bool {
        switch platform {
        case .qrCode:
            return false
        default:
            return UIApplication.shared.canOpenURL(URL(string: "\(platform.rawValue)://")!)
        
        }
    }
    
    
    
    
    public func isConnect(platform:TBWalletConnect.Platform) -> Bool {
        return self.availabelConnections(platform: platform).count > 0
    }
    
    
    
    
    public func availabelConnections(platform:TBWalletConnect.Platform) ->[TBWalletConnect] {
        var ret = [TBWalletConnect]()
        for c in self.availableConnections {
            if c.platForm.rawValue == platform.rawValue {
                ret.append(c)
            }
        }
        return ret
    }
    
    
    
    
    
    public func availableConnect(byWalletAccount walletAddress:String) -> TBWalletConnect? {
        let ret = self.availableConnections.filter{$0.getAccountId() == walletAddress}.first
        return ret
    }
    
    
    
    public func connect(c:TBWalletConnect, callBack:TBWalletConnectCallBack? = nil, wcUrl: WCURL? = nil) {
        self.connectionsMap[c.nameSpace.mapKey] = c
        let _ = (c.connect_(wcUrl: wcUrl)|>deliverOn(.mainQueue())).start {[weak self] data in
            if let strongSelf = self {
                strongSelf.handleSuccess(data: data)
            }
            switch data {
            case .didConnectSession(connect:_ , client: _, session: _):
                TBTrack.track(TBTrackEvent.Wallet.metamask_connect_ok.rawValue)
                if let callBack = callBack {
                    callBack(true, c)
                }
            default:
                break
            }
           
        } error: {[weak self] error in
            if let strongSelf = self {
                strongSelf.handleError(error: error)
            }
            if let callBack = callBack {
                callBack(false, nil)
            }
        } completed: {
            
        }
    }
    
    public func connectWithQrCode(callBack:TBWalletConnectCallBack? = nil) ->WCURL? {
        guard let context = self.context else {
            if let callBack = callBack {
                callBack(false, nil)
            }
            return nil
        }
        let c = TBWalletConnect(context: context, platForm: .qrCode)
        let wcUrl = c.generateConnectWCUrl()
        self.connect(c: c, callBack: callBack, wcUrl: wcUrl)
        return wcUrl
    }
    
    
    
    public func connectToPlatform(platform: TBWalletConnect.Platform, callBack:TBWalletConnectCallBack? = nil) {
        
        if platform == .qrCode {
            if let callBack = callBack {
                callBack(false, nil)
            }
            return
        }
        guard let context = self.context else {
            if let callBack = callBack {
                callBack(false, nil)
            }
            return
        }
        let c = TBWalletConnect(context: context, platForm: platform)
        self.connect(c: c, callBack: callBack)
    }
    
    
    
    public func disconnect(connect: TBWalletConnect) {
        if let client = connect.client , let session = connect.session {
            try? client.disconnect(from: session)
        }
    }
    
    
    public func tryReconnectAllWallet() {
        guard let context = self.context else {
            return
        }
        var cArr = [TBWalletConnect]()
        
        
        let sessionList = UserDefaults.standard.getAllSessionList(context: context).reversed()
        for session in sessionList {
            let c = TBWalletConnect(context: context, platForm: TBWalletConnect.Platform.platform(key: session.key.platform), session: session.session)
            if c.canReconnect() {
                cArr.append(c)
            }
        }
        self.tryReconnectWallets(cArr: cArr)
    }
    
    
    
    public func tryReconnectWallets(cArr:[TBWalletConnect]) {
        for c in cArr {
            self.connectionsMap[c.nameSpace.mapKey] = c
            let _ = (c.reConnect_()|>deliverOn(.mainQueue())).start {[weak self] data in
                if let strongSelf = self {
                    strongSelf.handleSuccess(data: data)
                }
             } error: {[weak self] error in
                 if let strongSelf = self {
                     strongSelf.handleError(error: error)
                 }
             } completed: {
                 
             }
        }
    }
    
    
    
    private func handleSuccess(data: TBWalletConnect.CData) {
        switch data {
        case .didConnectUrl(connect: _, client: _, url: _):
            break
        case .didConnectSession(connect: let c, client: _, session: _):
            
            let chainId = c.session?.walletInfo?.chainId ?? 0
            let _ = TBAccount.shared.userBindWallet(walletType: c.platForm.rawValue,
                                                    walletAddress: c.getAccountId(),
                                                    chainId:chainId).start()
            if let peerId = self.context?.account.peerId.id._internalGetInt64Value() {
                UserDefaults.standard.tb_updateWalletStoreWithConnect(c, peerId: peerId)
            }
            self.refreshAvailabelConnections()
            
        case .didUpdateSession(connect: _, client: _, session: _):
            break
        }
        debugPrint("[tb, connect result]: \(data)")
    }
    
    
    
    
    private func handleError(error:TBWalletConnect.CError) {
        var c : TBWalletConnect?
        switch error {
        case .didFailToConnect(connect: let connect, client: _, url: _):
            c = connect
        case .didDisConnectSession(connect: let connect, client:_, session: _):
            c = connect
        case .cannotOpen(connect: let connect):
            c = connect
        case .pureFail(connect: let connect):
            c = connect
        }
        if let c = c {
            self.connectionsMap.removeValue(forKey: c.nameSpace.mapKey)
        }
        self.refreshAvailabelConnections()
        debugPrint("[tb, connect result]: \(error)")
    }
    
    
    private func refreshAvailabelConnections()  {
        
        var ret = [TBWalletConnect]()
        
        for (_, c) in self.connectionsMap {
            if let walletInfo = c.session?.walletInfo,  walletInfo.accounts.count > 0 {
                ret.append(c)
            }
        }
       
        
        var filterMap = [String:TBWalletConnect]()
        for c in ret.sorted(by: {$0 < $1}) {
            filterMap[c.getAccountId().lowercased()] = c
        }
        
        ret = filterMap.values.sorted(by: {$0 > $1})
        self.availableConnections = ret
    }
    
    
    private func resetAll() {
        self.connectionsMap.removeAll()
        self.refreshAvailabelConnections()
    }
    
    private func testWeb3Swift() {
//        var accounts = TBMyWallet.getAccounts(tbUserId: "5318508230",password: "")


//            TBMyWallet.createAccountWithMnemonics(mnemonics: mnemonics, password: "", tbUserId: "5318508230",name: "test")
//            accounts = TBMyWallet.getAccounts(tbUserId: "5318508230",password: "")


//        let rpcs = ["https://mainnet-rpc.thundercore.com"]
//        let chainId = "6c"
//        let chainName = "ThunderCore"
//        let nativeCurrency = NativeCurrencyType(decimals: 18, symbol: "TT",icon: "")


//        print("org address:")

//        let res = TBMyWallet.getPrivateKey(account: transUseAccount, password: "")


//        let res1 = TBMyWallet.createAccountWithPrivateKey(privateKey: res.key, password: "", tbUserId: "5318508230", name: "666")

    


//            let res = await TBMyWallet.transaction(toAddress: "0x02dEB501820bC9C37e9815b4702bAd96edf1740D", chainInfo: chainInfo, account: transUseAccount, password: "",value: "0.00001")









        
        var transaction: CodableTransaction = .emptyTransaction
        transaction.from = transaction.sender 
        
        transaction.gasLimit = 78423
        transaction.gasPrice = nil
        transaction.value = 123456
        
        
        let userDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let web3KeystoreManager = KeystoreManager.managerForPath(userDir + "/keystore")
        do {
            if (web3KeystoreManager?.addresses?.count ?? 0 >= 0) {
                let tempMnemonics = try? BIP39.generateMnemonics(bitsOfEntropy: 256, language: .english)
                guard let tMnemonics = tempMnemonics else {
                    //self.showAlertMessage(title: "", message: "We are unable to create wallet", actionName: "Ok")
                    return
                }
                
                print(tMnemonics)
            
                let tempWalletAddress = try? BIP32Keystore(mnemonics: tMnemonics, password: "", prefixPath: "m/44'/77777'/0'/0")
                
                print(tempWalletAddress?.addresses?.first?.address as Any)
                guard let walletAddress = tempWalletAddress?.addresses?.first else {
                    //self.showAlertMessage(title: "", message: "We are unable to create wallet", actionName: "Ok")
                    return
                }
                
                let privateKey = try tempWalletAddress?.UNSAFE_getPrivateKeyData(password: "", account: walletAddress)
#if DEBUG
                print(privateKey as Any, "Is the private key")
#endif
                let keyData = try? JSONEncoder().encode(tempWalletAddress?.keystoreParams)
                FileManager.default.createFile(atPath: userDir + "/keystore"+"/key.json", contents: keyData, attributes: nil)
            }
        } catch {
            
        }
    }
    
}
