






import TBStorage
import TBNetwork
import SwiftSignalKit
import Foundation
import Alamofire
import HandyJSON


public struct NFTAvatarSettingConfig {
    let nft_contract: String
    let nft_contract_image: String
    let nft_token_id: String
    let nft_photo_id: String?
    let nft_name: String?
    let nft_chain_id: String?
    let nft_price: String?
    let nft_token_standard: String?
    
    public init(nft_contract: String, nft_contract_image: String, nft_token_id: String, nft_photo_id: String?, nft_name: String?, nft_chain_id: String?, nft_price: String?, nft_token_standard: String?) {
        self.nft_contract = nft_contract
        self.nft_contract_image = nft_contract_image
        self.nft_token_id = nft_token_id
        self.nft_photo_id = nft_photo_id
        self.nft_name = nft_name
        self.nft_chain_id = nft_chain_id
        self.nft_price = nft_price
        self.nft_token_standard = nft_token_standard
    }
}


public class TBNFTAvatarNetwork {
    
    public init(){}
    
    public func userUpdateNftInfoSignal(config: NFTAvatarSettingConfig) -> Signal<[String : Any], TBNetError>  {
        
        var params = ["nft_contract" : config.nft_contract, "nft_contract_image" : config.nft_contract_image, "nft_token_id" : config.nft_token_id]
        
        if let nft_photo_id = config.nft_photo_id, !nft_photo_id.isEmpty {
            params["nft_photo_id"] = nft_photo_id
        }
        if let nft_name = config.nft_name, !nft_name.isEmpty {
            params["nft_name"] = nft_name
        }
        if let nft_chain_id = config.nft_chain_id, !nft_chain_id.isEmpty {
            params["nft_chain_id"] = nft_chain_id
        }
        if let nft_price = config.nft_price, !nft_price.isEmpty {
            params["nft_price"] = nft_price
        }
        if let nft_token_standard = config.nft_token_standard, !nft_token_standard.isEmpty {
            params["nft_token_standard"] = nft_token_standard
        }
        return Signal { subsciber in
            TBNetwork.request(api: Logging.updateUserNftInfo.rawValue, method: .post, paramsFillter: params, successHandle: { (result, message) in
                if let data = result as? Dictionary<String, Any> {
                    subsciber.putNext(data)
                    subsciber.putCompletion()
                }else{
                    subsciber.putError(.normal(code: 0, message: ""))
                }
            }, failHandle: { (code, message) in
                subsciber.putError(.normal(code: code, message: message))
            })
            return EmptyDisposable
        }
    }
    
    public func userBindWalletSignal(wallet_type:String, wallet_address:String,chainId:Int) -> Signal<[String : Any], TBNetError>  {
        
        let params = ["wallet_type":wallet_type, "wallet_address":wallet_address,"chain_id":chainId] as [String : Any]
        
        return Signal { subsciber in
            TBNetwork.request(api: Logging.userBindWallet.rawValue, method: .post, paramsFillter: params, successHandle: { (result, message) in
                if let data = result as? Dictionary<String, Any> {
                    subsciber.putNext(data)
                    subsciber.putCompletion()
                }else{
                    subsciber.putError(.normal(code: 0, message: ""))
                }
            }, failHandle: { (code, message) in
                subsciber.putError(.normal(code: code, message: message))
            })
            return EmptyDisposable
        }
    }
    
}




func base64Encoding(str: String) -> String {
    if let strData = str.data(using: String.Encoding.utf8) {
        return strData.base64EncodedString()
    }
    return ""
}


public struct Coin: HandyJSON {
    var id: String?
    var symbol: String?
    var name: String?
    
    public init() { }
}

extension String {
    func isEqualIgnalCased(_ otherStr: String) -> Bool {
        if self == otherStr {
            return true
        } else if self.lowercased() == otherStr.lowercased() {
            return true
        } else if self.uppercased() == otherStr.uppercased() {
            return true
        }
        return false
    }
}

public class CoinGeckoNetwork {
    
    public static let sharedCoinGecko = CoinGeckoNetwork()
    
    public let coinPromise: Promise<[Coin]> = Promise<[Coin]>.init()
    
    private var coinListFetchDispoble: Disposable?
    
    init() {
        self.refreshCoinList()
    }
    
    deinit {
        self.coinListFetchDispoble?.dispose()
    }
    
    private func fetchCoinList() -> Signal<[Coin], NoError> {
        let url = Web3.coinGecko.rawValue + "/coins/list"
        var headers = HTTPHeaders.default
        headers.add(name: "Accept", value: "application/json")
        return Signal { subscriber in
            AF.request(url,
                       method: .get,
                       headers: headers).response(responseSerializer: StringResponseSerializer()) { response in
                switch response.result {
                case .success(let bin):
                    let data = bin.data(using: String.Encoding.utf8)
                    if let d = data, let result = try? JSONSerialization.jsonObject(with: d, options: .mutableContainers) as? [Any] {
                        if let items = JSONDeserializer<Coin>.deserializeModelArrayFrom(array: result) as? [Coin] {
                            subscriber.putNext(items)
                            break
                        }
                    }
                    subscriber.putNext([])
                case .failure(_):
                    subscriber.putNext([])
                }
                subscriber.putCompletion()
            }
            return EmptyDisposable
        }
    }
    
    public func refreshCoinList() {
        self.coinListFetchDispoble = self.fetchCoinList().start(next: {[weak self] coins in
            guard let strongSelf = self else { return }
            if coins.count > 0 {
                strongSelf.coinPromise.set(.single(coins))
            }
        })
    }
    
    struct SimplePriceParam: Encodable {
        let ids: String
        let vs_currencies: String
    }
    
    public func fetchPrice(network: String, symbol: String) -> Signal<String, NoError> {
        return self.fetchCoinList() |> mapToSignal({[weak self] coins -> Signal<String, NoError> in
            if let strongSelf = self, let ethCoin = coins.filter({ coin in
                if let sb = coin.symbol, let name = coin.name {
                    return sb.isEqualIgnalCased(symbol) && name.isEqualIgnalCased(network)
                }
                return false
            }).first{
                return strongSelf.fetchSimplePrice(coin: ethCoin)
            }
            return .single("")
        })
    }
    
    public func fetchSimplePrice(coin: Coin, vs: String = "usd") -> Signal<String, NoError> {
        let url = Web3.coinGecko.rawValue + "/simple/price"
        var headers = HTTPHeaders.default
        headers.add(name: "Accept", value: "application/json")
        let params = SimplePriceParam(ids: coin.id ?? "", vs_currencies: vs)
        return Signal { subscriber in
            AF.request(url,
                       method: .get,
                       parameters: params,
                       headers: headers).response(responseSerializer: StringResponseSerializer()) { response in
                switch response.result {
                case .success(let bin):
                    let data = bin.data(using: String.Encoding.utf8)
                    if let d = data,
                       let result = try? JSONSerialization.jsonObject(with: d, options: .mutableContainers) as? [String : Any],
                       let vsDic = result[coin.id ?? ""] as? [String : Any],
                       let price = vsDic[vs] {
                        subscriber.putNext("\(price)")
                    }
                case .failure(_):
                    break
                }
                subscriber.putCompletion()
            }
            return EmptyDisposable
        }
        
    }
    
}
