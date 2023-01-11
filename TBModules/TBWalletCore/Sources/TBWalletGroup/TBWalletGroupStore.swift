






import Foundation
import Web3swift
import Web3swiftCore
import BigInt
import SwiftSignalKit
import TBStorage
import AccountContext

public enum TBWalletGroupEntrySection: Int {
    case autoCreat = 1
    case fromPrivateKey
    case fromMnemonic
    case manualCreat
    case connect
    
}

public typealias TBWalletGroupMap = [TBWalletGroupEntrySection: [TBWallet]]

extension TBWalletGroupMap {
    func validSortKeys() -> [TBWalletGroupEntrySection] {
        let map = self.compactMapValues { $0.isEmpty ? nil : $0}
        return map.keys.sorted{$0.rawValue < $1.rawValue}
    }
    public func allSortList() -> [TBWallet] {
        var allList = [TBWallet]()
        for section in self.validSortKeys() {
            if let list = self[section] {
                allList.append(contentsOf: list)
            }
        }
        return allList
    }
    
    public func isEqualToOther(_ other: Self)  -> Bool {
        return self.allSortList() == other.allSortList()
    }
}

fileprivate struct State: Equatable {
    var entry: TBWalletGroupStoreEntry
    static func == (lhs: Self, rhs: Self) -> Bool {
        if lhs.entry != rhs.entry {
            return false
        }
        return true
    }
}

public class TBWalletGroupManager {
    
    private let statePromise: ValuePromise<State>
    private let stateValue: Atomic<State>
    fileprivate let updateState: ((State) -> State) -> Void
    
    init() {
        let initialState = State(entry: .init(myEntryList: [TBWalletGroupStoreEntry.MyEntry](), connectEntryList: [TBWalletGroupStoreEntry.ConnectEntry]()))
        let statePromise = ValuePromise(initialState, ignoreRepeated: true)
        let stateValue = Atomic(value: initialState)
        let updateState: ((State) -> State) -> Void = { f in
            statePromise.set(stateValue.modify { f($0) })
        }
        self.statePromise = statePromise
        self.stateValue = stateValue
        self.updateState = updateState
        
    }
    
    public func setup(tgUserId:Int64) {
        self.updateState { current in
            var current = current
            current.entry = UserDefaults.standard.tb_getWalletStore(peerId: tgUserId)
            return current
        }
    }
    
    public func storeEntryDidChangeSignal() -> Signal<Bool, NoError> {
        return self.statePromise.get() |> map({ state in
            return true
        })
    }
    
    public func walletGroupMapSignal(context: AccountContext) -> Signal<TBWalletGroupMap, NoError> {
        
        return combineLatest(self.statePromise.get(), TBMyWalletManager.shared.allWalletsSignal, TBWalletConnectManager.shared.availabelConnectionsSignal) |> map({ state, myWallets, connects in
            var autoList = [TBWallet]()
            var fromPrivateKeyList = [TBWallet]()
            var fromMnemonicList = [TBWallet]()
            var manualCreatList = [TBWallet]()
            for entry in state.entry.myEntryList {
                if let group = entry.group(), let item = myWallets.filter({$0.walletAddress() == entry.walletAddress}).first {
                    switch group {
                    case .mineAuto:
                        autoList.append(.mine(item))
                    case .manualCreat:
                        manualCreatList.append(.mine(item))
                    case .minePrivateKey:
                        fromPrivateKeyList.append(.mine(item))
                    case .mineMnemonic:
                        fromMnemonicList.append(.mine(item))
                    }
                }
            }
            var map = TBWalletGroupMap()
            if let c = connects.first {
                map[.connect] = [.connect(c)]
            }
            
            
            
            map[.autoCreat] = autoList
            map[.fromPrivateKey] = fromPrivateKeyList
            map[.fromMnemonic] = fromMnemonicList
            map[.manualCreat] = manualCreatList
            
            return map
        }) |> distinctUntilChanged(isEqual: { lhs, rhs in
            return lhs.isEqualToOther(rhs)
        })
    }
    
    public static let shared = TBWalletGroupManager()
    
    
    
}

extension UserDefaults {
    func tb_savaWalletStoreEntry(_ entry: TBWalletGroupStoreEntry, peerId: Int64) {
        let exsitEntry = self.tb_getWalletStore(peerId: peerId)
        if exsitEntry != entry {
            self.tb_set(object: entry, for: .accountWalletGroupList(peerId: peerId))
        }
        TBWalletGroupManager.shared.updateState { current in
            var current = current
            current.entry = entry
            return current
        }
    }
    
    func tb_getWalletStore(peerId: Int64) -> TBWalletGroupStoreEntry {
        let ret:TBWalletGroupStoreEntry? = self.tb_object(for: .accountWalletGroupList(peerId: peerId))
        if let ret = ret {
            return ret
        }else{
            return TBWalletGroupStoreEntry()
        }
    }
    
    func tb_updateWalletStoreWithConnect(_ connect: TBWalletConnect, peerId: Int64) {
        if connect.getAccountId().isEmpty { return }
        let exsitEntry = self.tb_getWalletStore(peerId: peerId)
        let ret = exsitEntry.updateConnect(connect)
        self.tb_savaWalletStoreEntry(ret, peerId: peerId)
    }
    
    func tb_updateWalletStoreWithConnect(_ connect: TBWalletConnect, name: String, peerId: Int64) {
        if connect.getAccountId().isEmpty {
            return
        }
        let exsitEntry = self.tb_getWalletStore(peerId: peerId)
        let ret = exsitEntry.updateConnect(connect, name: name)
        self.tb_savaWalletStoreEntry(ret, peerId: peerId)
    }
    
    func tb_getConnectWalletName(_ connect: TBWalletConnect, peerId: Int64) -> String {
        let exsitEntry = self.tb_getWalletStore(peerId: peerId)
        return exsitEntry.getConnectName(connect)
    }
    
    func tb_updateWalletStoreWithMyWalletModel(_ myWalletModel: TBMyWalletModel, group: TBWalletGroupStoreEntry.MyEntry.Group, peerId: Int64) {
        let exsitEntry = self.tb_getWalletStore(peerId: peerId)
        let ret = exsitEntry.updateMyWallet(myWalletModel, group: group)
        self.tb_savaWalletStoreEntry(ret, peerId: peerId)
    }
    
}

