






import Foundation
import Web3swift
import Web3swiftCore
import BigInt
import WalletConnectSwift
import SwiftSignalKit
import AccountContext

let TB_PATTERN_wallet_mnemonic = "^[A-Za-z0-9\\s]+$"
let TB_PATTERN_wallet_private_key = "^[A-Fa-f0-9x]+$"

extension String {
    
    public func tb_is_match_pattern(_ pattern: String) -> Bool {
        if self.isEmpty {
            return false
        }
        if pattern.isEmpty {
            return false
        }
        if NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: self) {
            return true
        }
        return false
    }
    
    public func tb_is_mnemonic() -> Bool {
        var ret = self.tb_is_match_pattern(TB_PATTERN_wallet_mnemonic) && self.contains(" ")
        return ret
    }
    
    public func tb_is_privateKey() -> Bool {
        let ret = self.tb_is_match_pattern(TB_PATTERN_wallet_private_key)
        return ret
    }
}


public enum TBWallet: Equatable {
    
    case connect(TBWalletConnect)
    case mine(TBMyWalletModel)
    
    public func walletAddress() ->String {
        switch self {
        case .connect(let tBWalletConnect):
            return tBWalletConnect.getAccountId()
        case .mine(let tBMyWalletModel):
            return tBMyWalletModel.walletAddress()
        }
    }
    
    public func walletName() -> String {
        switch self {
        case .connect(let tBWalletConnect):
            return  tBWalletConnect.walletName
        case .mine(let mine):
            return mine.walletName()
        }
    }
    
    public static func ==(lhs: TBWallet, rhs: TBWallet) -> Bool {
        switch lhs {
        case .connect(let a):
            if case let .connect(b)  = rhs {
                return a == b
            } else {
                return false
            }
        case .mine(let a):
            if case let .mine(b) = rhs {
                return a == b
            } else {
                return false
            }
        }
    }
}

public class TBWalletWrapper {
    
    public static func getAllWalletsSignal(context: AccountContext, password:String) -> Signal<[TBWallet], NoError> {
        TBWalletConnectManager.shared.setup(context: context)
        return combineLatest(TBWalletConnectManager.shared.availabelConnectionsSignal, TBMyWalletManager.shared.allWalletsSignal)
        |> mapToSignal({ (connects, myWallets) in
           var ret = [TBWallet]()
           for w in myWallets {
               ret.append(.mine(w))
           }
           for c in connects {
               ret.append(.connect(c))
           }
           return .single(ret)
        }) |> distinctUntilChanged
    }

}
