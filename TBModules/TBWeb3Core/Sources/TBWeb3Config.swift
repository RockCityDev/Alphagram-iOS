
import Foundation
import HandyJSON
import SwiftSignalKit
import TBBusinessNetwork
import TBAccount

public enum TBChainType {
    case unkonw
    case ETH
    case Polygon
    case TT
    case OS
}

public func getNetworkName(id: String) -> String? {
    switch id {
    case "108":
        return "ThunderCore"
    case "1":
        return "Ethereum"
    case "137":
        return "Polygon"
    case "42262":
        return "Oasis"
    default:
        return nil
    }
}

public struct WalletInfoItem: HandyJSON {
    public var user_id: Int64 = -1
    public var wallet_type: String = ""
    public var wallet_address: String = ""
    
    public init() {}
}

public struct ChainRecordItem: HandyJSON {
    public var chain_id: Int = -1
    public var chain_icon: String = ""
    
    public init() {}
}

public struct NetworkInfo: HandyJSON, Equatable{
    public var id: Int = -1
    public var tg_user_id: String = ""
    public var nft_photo_id: String = ""
    public var nft_contract: String = ""
    public var nft_name: String = ""
    public var nft_contract_image: String = ""
    public var nft_token_id: String = ""
    public var chain_id: Int = -1
    public var is_show_wallet: Int = -1
    public var is_bind_wallet: Int = -1
    public var wallet_info = [WalletInfoItem]()
    public var chain_icon: String = ""
    public var chain_name: String = ""
    public var chain_record = [ChainRecordItem]()
    
    public init() {}
    
    public static func == (lhs: NetworkInfo, rhs: NetworkInfo) -> Bool {
        if lhs.tg_user_id != rhs.tg_user_id {
            return false
        }
        if lhs.id != rhs.id {
            return false
        }
        return true
    }
}

public func getMainCurrencyDecimalBy(type: TBChainType) -> Int? {
    if let chains = TBWeb3Config.shared.config?.chainType {
        let chainId: Int?
        switch type {
        case .unkonw:
            chainId = nil
        case .TT:
            chainId = 108
        case .ETH:
            chainId = 1
        case .Polygon:
            chainId = 137
        case .OS:
            chainId = 42262
        }
        if let cid = chainId, let chain = chains.filter({$0.id == cid}).first {
            return chain.currency.filter({$0.id == chain.main_currency_id}).first?.decimal
        } else {
            return nil
        }
    } else {
        return nil
    }
}

public func getMainCurrencySymbolBy(type: TBChainType) -> String? {
    if let chains = TBWeb3Config.shared.config?.chainType {
        let chainId: Int?
        switch type {
        case .unkonw:
            chainId = nil
        case .TT:
            chainId = 108
        case .ETH:
            chainId = 1
        case .Polygon:
            chainId = 137
        case .OS:
            chainId = 42262
        }
        if let cid = chainId, let chain = chains.filter({$0.id == cid}).first {
            return chain.currency.filter({$0.id == chain.main_currency_id}).first?.name
        } else {
            return nil
        }
    } else {
        return nil
    }
}




public func tb_isInviteGroupUrl(url: String) -> Int64? {
    
    let configDomain = TBAccount.shared.systemCheckData.h5_domain
    if url.isEmpty {
        return nil
    }else{
        if !configDomain.isEmpty && url.hasPrefix(configDomain) {
            
            if let queryItems =  URLComponents(string: url.replacingOccurrences(of: "#", with: ""))?.queryItems {
                var groupId:Int64? = nil
                for item in queryItems {
                    if item.name == "id", let id = item.value, let int64Id = Int64(id), int64Id > 0 {
                        groupId = int64Id
                        break
                    }
                }
                if let groupId = groupId {
                    return groupId
                }else{
                   return nil
                }
            }else{
               return nil
            }
        }else{
           return nil
        }
    }
}


public class TBWeb3Config {
    static public let shared = TBWeb3Config()
    public var config: TBWeb3ConfigEntry? {
        didSet {
            if let config = self.config {
                UserDefaults.standard.tb_set(object: config, for: .web3Config)
                self.configPromise.set(.single(self.config))
            }
        }
    }
    private let configPromise: Promise<TBWeb3ConfigEntry?>
    
    public var configSignal:Signal<TBWeb3ConfigEntry?, NoError> {
        get {
            return self.configPromise.get() |> filter({ config in
                return config == nil ? false : true
            })
        }
    }
    
    public init() {
        let config: TBWeb3ConfigEntry? = UserDefaults.standard.tb_object(for: .web3Config)
        if let config = config {
            self.configPromise = Promise(config)
        }else{
            self.configPromise = Promise(nil)
        }
    }
    
    public func updateConfig() {
        let _ = TBWeb3ConfigInteractor().web3ConfigSignal().start(
            next: { config in
                if let config = config {
                    self.config = config
                }
            }
        )
    }
}

