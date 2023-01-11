
import Foundation
import HandyJSON
import TBWalletCore

public struct TBWeb3ConfigEntry: HandyJSON {
    
    public struct Wallet: HandyJSON, Equatable {
        public enum WType: Int, Equatable {
            case metamask = 1
            case trust = 2
            case spot = 3
            case token_pocket = 4
            case im_token = 5
            
            public static func transform(int: Int) -> WType {
                if int == WType.metamask.rawValue {
                    return .metamask
                }
                if int == WType.trust.rawValue {
                    return .trust
                }
                if int == WType.spot.rawValue {
                    return .spot
                }
                if int == WType.token_pocket.rawValue {
                    return .token_pocket
                }
                if int == WType.im_token.rawValue {
                    return .im_token
                }
                return .metamask
            }
        }
        public var id: Int = 0
        public var name: String = ""
        public init(){}
        public static func == (lhs: Wallet, rhs: Wallet) -> Bool {
            return lhs.id == rhs.id
        }
        
        public func getType() -> WType {
            return WType.transform(int: self.id)
        }
    }
    
    public struct Chain: HandyJSON, Equatable {

        public struct Currency: HandyJSON, Equatable {
            public var id: Int = 0
            public var coin_id = ""
            public var decimal: Int = 0
            public var name = ""
            public var is_main_currency = false
            public var icon = ""
            public init(){}
            public static func == (lhs: Currency, rhs: Currency) -> Bool {
                return lhs.id == rhs.id
            }
        }
        
        public struct Button: HandyJSON, Equatable {
            public var id: Int = 0
            public var chain_id: Int = 0
            public var type = ""
            public var name = ""
            public var icon = ""
            public var link = ""
            public var sort: Int = 0
            public var icon_link = ""
            
            public init(){}
            public static func == (lhs: Button, rhs: Button) -> Bool {
                return lhs.id == rhs.id
            }
        }
        
        public var id: Int = 0
        public var name = ""
        public var icon = ""
        public var rpc_url = ""
        public var explorer_url: String?
        public var main_currency_id: Int = 0
        public var main_currency_name = ""
        public var currency = [Currency]()
        public var button = [Button]()
        
        public init(){}
        public static func == (lhs: Chain, rhs: Chain) -> Bool {
            return lhs.id == rhs.id
        }
    }
    
    public struct Token: HandyJSON, Equatable {
        public enum TokenType : Int, Equatable {
            case normal = 0
            case erc_721 = 1 
        }
        
        public var id: Int = 0
        public var name: String = ""
        public init(){}
        public static func == (lhs: Token, rhs: Token) -> Bool {
            return lhs.id == rhs.id
        }
        
    }

    public var walletType = [Wallet]()
    public var chainType = [Chain]()
    public var tokenType = [Token]()
    
    public init(){}
}

extension TBWeb3ConfigEntry {
    
    public func getConfigWallet(with type: Wallet.WType) -> Wallet? {
        return self.walletType.filter { wallet in
            return wallet.getType() == type
        }.first
    }
    
    
    public func getCofigChain(with id: Int) -> Chain? {
        return self.chainType.filter {$0.id == id}.first
    }
    
    
    public func getConfigCurrency(chainId: Int, currenyId: Int) -> Chain.Currency? {
        if let chain = self.getCofigChain(with: chainId) {
            return chain.getConfigCurrency(with: currenyId)
        }
        return nil
    }
    
    public func getConfigToken(tokenId: Int) -> Token? {
        return self.tokenType.filter {$0.id == tokenId}.first
    }
    
}

extension TBWeb3ConfigEntry.Chain {
    
    public func getConfigCurrency(with id: Int) -> Currency?  {
        return self.currency.filter {$0.id == id}.first
    }
    
    
    public func getChainType() -> TBChainType {
        switch self.id {
        case 1:
            return .ETH
        case 108:
            return .TT
        case 137:
            return .Polygon
        case 42262:
            return .OS
        default:
            return .unkonw
        }
    }
}

extension TBWeb3ConfigEntry.Token {
    public func tokenType() -> TokenType  {
        if self.id == 2 {
            return .erc_721
        }
        return .normal
    }
}

