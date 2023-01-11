






import Foundation
import Web3swift
import Web3swiftCore
import BigInt
import SwiftSignalKit
import HandyJSON

 struct TBWalletGroupStoreEntry: HandyJSON, Equatable {
    
     struct MyEntry: HandyJSON, Equatable{
         enum Group: Int {
            case mineAuto = 1
            case manualCreat
            case minePrivateKey
            case mineMnemonic
        }
        
         var walletAddress: String = ""
         var intGroup: Int = 0
        
         func group() -> Group? {
            return Group(rawValue: self.intGroup)
        }
        
         func isValid() -> Bool {
            if self.group() == nil {
                return false
            }
            if walletAddress.isEmpty {
                return false
            }
            return true
        }
        
         static func == (lhs: MyEntry, rhs: MyEntry) -> Bool {
            if lhs.walletAddress != rhs.walletAddress {
                return false
            }
            if lhs.intGroup != rhs.intGroup {
                return false
            }
            return true
        }
        
         static func creat(_ myWalletModel: TBMyWalletModel, group: Group) -> MyEntry? {
            
            let ret = MyEntry(walletAddress: myWalletModel.walletAddress(), intGroup: group.rawValue)
            if ret.isValid() {
                return ret
            }else{
                return nil
            }
        }
        
    }
    
     struct ConnectEntry: HandyJSON, Equatable {
         var walletAddress: String = ""
         var platString: String = ""
         var name: String = ""
         func platform() -> TBWalletConnect.Platform? {
            return .init(rawValue: platString)
        }
        
         func isValid() -> Bool {
            if self.platform() == nil {
                return false
            }
            if walletAddress.isEmpty {
                return false
            }
            return true
        }
        
         static func == (lhs: ConnectEntry, rhs: ConnectEntry) -> Bool {
            if lhs.name != rhs.name {
                return false
            }
            if lhs.walletAddress != rhs.walletAddress {
                return false
            }
            if lhs.platString != rhs.platString {
                return false
            }
            return true
        }
        
         static func creat(_ connect: TBWalletConnect, name: String? = nil) -> ConnectEntry? {
            let ret = ConnectEntry(walletAddress: connect.getAccountId(), platString: connect.platForm.rawValue, name: name ?? "")
            if ret.isValid() {
                return ret
            }else{
                return nil
            }
        }
    }
    
     var myEntryList = [MyEntry]()
     var connectEntryList = [ConnectEntry]()
    
     static func == (lhs: TBWalletGroupStoreEntry, rhs: TBWalletGroupStoreEntry) -> Bool {
        if lhs.myEntryList != rhs.myEntryList {
            return false
        }
        if lhs.connectEntryList != rhs.connectEntryList {
            return false
        }
        return true
    }
    
}


extension TBWalletGroupStoreEntry {
    
    func updateConnect(_ connect: TBWalletConnect) -> TBWalletGroupStoreEntry {
        guard let entry = ConnectEntry.creat(connect) else {
            return self
        }
        if let _ = self.connectEntryList.filter({$0.walletAddress == entry.walletAddress && $0.platString == entry.platString}).first { 
            return self
        }else{
            var ret = self
            ret.connectEntryList.append(entry)
            return ret
        }
    }
    
    func updateConnect(_ connect: TBWalletConnect, name: String) -> TBWalletGroupStoreEntry {
        guard let entry = ConnectEntry.creat(connect, name: name) else {
            return self
        }
        var update = false
        let list = self.connectEntryList.map { item in
            if item.walletAddress == entry.walletAddress && item.platString == entry.platString {
                update = true
                return entry
            }else{
                return item
            }
        }
        if update {
            var ret = self
            ret.connectEntryList = list
            return ret
        }else{
            var ret = self
            ret.connectEntryList.append(entry)
            return ret
        }
    }
    
    func getConnectName(_ connect: TBWalletConnect) -> String {
        guard let entry = ConnectEntry.creat(connect) else {
            return ""
        }
        if let ret = self.connectEntryList.filter({$0.walletAddress == entry.walletAddress && $0.platString == entry.platString}).first {
            return ret.name
        }else{
            return ""
        }
    }
}


extension TBWalletGroupStoreEntry {
    func updateMyWallet(_ myWallet: TBMyWalletModel, group: MyEntry.Group) -> TBWalletGroupStoreEntry {
        guard let entry = MyEntry.creat(myWallet, group: group) else {
            return self
        }
        if self.myEntryList.contains(entry) {
            return self
        }else{
            var ret = self
            ret.myEntryList.append(entry)
            return ret
        }
    }
}


