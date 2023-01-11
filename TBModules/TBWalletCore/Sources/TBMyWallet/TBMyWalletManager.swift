






import Foundation
import Web3swift
import Web3swiftCore
import BigInt
import SwiftSignalKit

private let TB_QUEUE: Queue = .concurrentDefaultQueue()


public class TBMyWalletManager {
    
    public static var password:String {
        return ""
    }
    
    public static let shared = TBMyWalletManager()
    
    private var _allWallets = [TBMyWalletModel]() {
        didSet {
            self._allWalletsPromise.set(self._allWallets)
        }
    }
    private let _allWalletsPromise = ValuePromise([TBMyWalletModel](), ignoreRepeated: true)
    public var allWalletsSignal: Signal<[TBMyWalletModel], NoError> {
        return self._allWalletsPromise.get()
    }
    
    public var cacheCreatMyWalletMnemonic: String?
    
    public init() {
        
    }
    
    
    public func pureGetAllAccounts(tgUserId:Int64, password:String)-> Signal<[TBMyWalletModel], NoError> {
        return Signal { subscriber in
            TB_QUEUE.async {
                let start = CFAbsoluteTimeGetCurrent()
                let accounts = TBMyWallet.getAccounts(tbUserId: String(tgUserId), password: password)
                self._allWallets = accounts
                debugPrint("[TBMyWallet] getAllAccounts took \(CFAbsoluteTimeGetCurrent() - start), result:\(accounts.count)")
                subscriber.putNext(accounts)
                subscriber.putCompletion()
            }
            return EmptyDisposable
        }
    }
    
    
    
    public func pureCreatAccount(tgUserId:Int64, password:String, name:String, isAuto: Bool = false) -> Signal<Bool, NoError> {
        return Signal{ subscriber in
            TB_QUEUE.async {
                let start = CFAbsoluteTimeGetCurrent()
                let mnemonics = TBMyWallet.genMnemonics()
                self.cacheCreatMyWalletMnemonic = mnemonics
                 let ret = TBMyWallet.createAccountWithMnemonics(mnemonics: mnemonics, password: password, tbUserId: String(tgUserId),name: name)
                subscriber.putNext(ret)
                subscriber.putCompletion()
                debugPrint("[TBMyWallet] pureCreatAccount took \(CFAbsoluteTimeGetCurrent() - start), result:\(ret)")
                let accounts = TBMyWallet.getAccounts(tbUserId: String(tgUserId), password: password)
                self._allWallets = accounts
                if let currentModel = accounts.first {
                    UserDefaults.standard.tb_updateWalletStoreWithMyWalletModel(currentModel, group: isAuto ? .mineAuto : .manualCreat, peerId: tgUserId)
                }
            }
            return EmptyDisposable
        }
    }
    
    public func creatAccount(tgUserId:Int64, password:String, name:String?) -> Signal<Bool, NoError> {
        if let name = name {
            return self.pureCreatAccount(tgUserId: tgUserId, password: password, name: name)
        }else{
            return self.pureGetAllAccounts(tgUserId: tgUserId, password: password) |> mapToSignal({ allWallets in
                let autoName = "Account(auto) \(allWallets.count + 1)"
                return self.pureCreatAccount(tgUserId: tgUserId, password: password, name: autoName, isAuto: true)
            })
        }
    }
    
    public func creatAccountIfNoExsit(tgUserId:Int64, password:String, name:String?=nil) -> Signal<Bool, NoError> {
        return self.pureGetAllAccounts(tgUserId: tgUserId, password: password) |> mapToSignal({ allWallets in
            if allWallets.count > 0 {
                return .single(false)
            }else{
                return self.pureCreatAccount(tgUserId: tgUserId, password: password, name: name ?? "Account(auto) 0", isAuto: true)
            }
        })
    }
    
    
    
    
    public func pureCreateAccountWithPrivateKey(privateKey: String, password:String, tgUserId:Int64, name:String) -> Signal<Bool, NoError>  {
        
        return Signal { subscriber in
            TB_QUEUE.async {
                let start = CFAbsoluteTimeGetCurrent()
                let ret = TBMyWallet.createAccountWithPrivateKey(privateKey: privateKey, password: password, tbUserId: String(tgUserId), name: name)
                subscriber.putNext(ret)
                subscriber.putCompletion()
                debugPrint("[TBMyWallet] pureCreateAccountWithPrivateKey took \(CFAbsoluteTimeGetCurrent() - start), result:\(ret)")
                let accounts = TBMyWallet.getAccounts(tbUserId: String(tgUserId), password: password)
                self._allWallets = accounts
                if let currentModel = accounts.first {
                    UserDefaults.standard.tb_updateWalletStoreWithMyWalletModel(currentModel, group: .minePrivateKey, peerId: tgUserId)
                }
            }
            return EmptyDisposable
        }
    }
    
    public func createAccountWithPrivateKey(privateKey: String, password:String, tgUserId:Int64, name:String?) -> Signal<Bool, NoError> {
        
        if let name = name {
            return self.pureCreateAccountWithPrivateKey(privateKey: privateKey, password: password, tgUserId: tgUserId, name: name)
        }else{
            return self.pureGetAllAccounts(tgUserId: tgUserId, password: password)
            |> mapToSignal({ allWallets in
                let autoName = "Account(From Private Key) \(allWallets.count + 1)"
                return self.pureCreateAccountWithPrivateKey(privateKey: privateKey, password: password, tgUserId: tgUserId, name: autoName)
            })
        }
    }
    
    
    
    public func pureCreateAccountWithMnemonics(mnemonics:String,password:String,tgUserId:Int64,name:String) -> Signal<Bool, NoError> {
        return Signal { subscriber in
            TB_QUEUE.async {
                let start = CFAbsoluteTimeGetCurrent()
                let ret = TBMyWallet.createAccountWithMnemonics(mnemonics: mnemonics, password: password, tbUserId: String(tgUserId), name: name)
                subscriber.putNext(ret)
                subscriber.putCompletion()
                debugPrint("[TBMyWallet] pureCreateAccountWithMnemonics took \(CFAbsoluteTimeGetCurrent() - start), result:\(ret)")
                let accounts = TBMyWallet.getAccounts(tbUserId: String(tgUserId), password: password)
                self._allWallets = accounts
                if let currentModel = accounts.first {
                    UserDefaults.standard.tb_updateWalletStoreWithMyWalletModel(currentModel, group: .mineMnemonic, peerId: tgUserId)
                }
            }
            return EmptyDisposable
        }
    }
    
    public func createAccountWithMnemonics(mnemonics:String,password:String,tgUserId:Int64,name:String?) -> Signal<Bool, NoError> {
        
        if let name = name {
            return self.pureCreateAccountWithMnemonics(mnemonics: mnemonics, password: password, tgUserId: tgUserId, name: name)
        }else{
            return self.pureGetAllAccounts(tgUserId: tgUserId, password: password)
            |> mapToSignal({ allWallets in
                let autoName = "Account(From Mnemonics Key) \(allWallets.count + 1)"
                return self.pureCreateAccountWithMnemonics(mnemonics: mnemonics, password: password, tgUserId: tgUserId, name: autoName)
            })
        }
    }
    
    
    
    public func pureExportPrivateKey(account:TBMyWalletModel,password:String) -> Signal<String, Error>{
        return Signal { subscriber in
            TB_QUEUE.async {
                let start = CFAbsoluteTimeGetCurrent()
                let (string, error) = TBMyWallet.getPrivateKey(account: account, password: password)
                if let string = string, !string.isEmpty {
                    subscriber.putNext(string)
                    subscriber.putCompletion()
                }else if let error = error {
                    subscriber.putError(error)
                }else{
                    subscriber.putError(fatalError("unknown error"))
                }
                debugPrint("[TBMyWallet] pureCreateAccountWithMnemonics took \(CFAbsoluteTimeGetCurrent() - start), result:\(String(describing: string)), \(String(describing: error))")
            }
            return EmptyDisposable
        }
    }
    
    public func exportPrivateKey(account: TBMyWalletModel,password: String) -> Signal<String, NoError> {
        return self.pureExportPrivateKey(account: account, password: password) |> `catch`{
            error in
            return .single("")
        }
    }
       
}
