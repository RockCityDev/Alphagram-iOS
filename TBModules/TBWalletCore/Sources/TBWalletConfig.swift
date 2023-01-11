






import Foundation

public struct NativeCurrencyType : Encodable {
    public let decimals: Int
    public let symbol: String
    public let icon: String
    public init(decimals: Int, symbol: String, icon: String) {
        self.decimals = decimals
        self.symbol = symbol
        self.icon = icon
    }
}

public struct TBWCParamType: Encodable {
    public var chainId: String
    public var chainName: String
    public var rpcUrls: [String]
    public var nativeCurrency: NativeCurrencyType

    public init(chainId: String, chainName: String, rpcUrls: [String], nativeCurrency: NativeCurrencyType) {
        self.chainId = chainId
        self.chainName = chainName
        self.rpcUrls = rpcUrls
        self.nativeCurrency = nativeCurrency
    }
}

public enum TBWalletTransactionChain:String, Equatable  {
    case ETH = "eth"
    case TT = "TT"
    case TT_Test = "TT_test"
    case Oasis = "Oasis"
    case Oasis_Test = "Oasis_test"
    case Polygon = "polygon"
    
    public static func transfer(from string: String) -> TBWalletTransactionChain? {
        switch string.uppercased() { 
        case "ETHEREUM":
            return .ETH
        case "POLYGON":
            return .Polygon
        case "THUNDERCORE":
            return .TT
        case "OASIS":
            return .Oasis
        default:
            return nil
        }
    }
    
    public static func transfer(from chainId: Int) -> TBWalletTransactionChain? {
        if chainId == 1 {
            return .ETH
        }
        if chainId == 108 {
            return .TT
        }
        if chainId == 137 {
            return .Polygon
        }
        if chainId == 42262 {
            return .Oasis
        }
        return nil
    }
}


public let ETHChain = "eth"
public let TTChain = "TT"
public let TTChain_Test = "TT_test"
public let OasisChain = "Oasis"
public let OasisChain_Test = "Oasis_test"
public let PolygonChain = "polygon"




public let ERC20_USDT = "erc20_usdt"



public func getChainParam(type:String) -> TBWCParamType {
    if type == TTChain_Test {
        let rpcs = ["https://testnet-rpc.thundercore.com"]
        let chainId = "0x12"
        let chainName = "ThunderCore Testnet"
        let nativeCurrency = NativeCurrencyType(decimals: 18, symbol: "TT",icon: "")
        return  TBWCParamType(chainId: chainId, chainName: chainName, rpcUrls: rpcs ,nativeCurrency: nativeCurrency)
    } else if type == TTChain {
        let rpcs = ["https://mainnet-rpc.thundercore.com"]
        let chainId = "0x6c"
        let chainName = "ThunderCore"
        let nativeCurrency = NativeCurrencyType(decimals: 18, symbol: "TT",icon: "")
        return  TBWCParamType(chainId: chainId, chainName: chainName, rpcUrls: rpcs ,nativeCurrency: nativeCurrency)
    }else if type == OasisChain {
        let rpcs = ["https://emerald.oasis.dev"]
        let chainId = "0xa516"
        let chainName = "Emerald Paratime"
        let nativeCurrency = NativeCurrencyType(decimals: 18, symbol: "ROSE",
                                                icon: "https://d3l1ioscvnrz88.cloudfront.net/system/web3/currency/coin_logo_oasis.png")
        return  TBWCParamType(chainId: chainId, chainName: chainName, rpcUrls: rpcs ,nativeCurrency: nativeCurrency)
    }else if type == OasisChain_Test {
        let rpcs = ["https://testnet.emerald.oasis.dev"]
        let chainId = "0xa515"
        let chainName = "Emerald Paratime Test"
        let nativeCurrency = NativeCurrencyType(decimals: 18, symbol: "ROSE",
                                                icon: "https://d3l1ioscvnrz88.cloudfront.net/system/web3/currency/coin_logo_oasis.png")
        return  TBWCParamType(chainId: chainId, chainName: chainName, rpcUrls: rpcs ,nativeCurrency: nativeCurrency)
    } else if type == ETHChain {
        let rpcs = ["https://api.infura.io/v1/jsonrpc/mainnet"]
        let chainId = "0x1"
        let nativeCurrency = NativeCurrencyType(decimals: 18, symbol: "ETH",icon: "")
        return  TBWCParamType(chainId: chainId, chainName: "", rpcUrls: rpcs ,nativeCurrency: nativeCurrency)
    } else if type == PolygonChain {
        let rpcs = ["https://polygon-rpc.com"]
        let chainId = "0x89"
        let chainName = "Polygon"
        let nativeCurrency = NativeCurrencyType(decimals: 18, symbol: "MATIC",
                                                icon: "")
        return  TBWCParamType(chainId: chainId, chainName: chainName, rpcUrls: rpcs ,nativeCurrency: nativeCurrency)
    }
    
    
        
        
    return  TBWCParamType(chainId: "0x6c", chainName: "ThunderCore", rpcUrls: ["https://mainnet-rpc.thundercore.com"] ,nativeCurrency: NativeCurrencyType(decimals: 18, symbol: "TT",icon: ""))
}






