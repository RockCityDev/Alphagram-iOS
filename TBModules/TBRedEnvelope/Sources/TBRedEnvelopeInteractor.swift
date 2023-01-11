import Foundation
import HandyJSON
import TBNetwork
import SwiftSignalKit
import Alamofire
import TBWeb3Core

public typealias Dict = Dictionary<String, Any>

public struct CurrencyPrice: HandyJSON {
    public var usd: String = "0"
    
    public init() {}
}

public enum BonusGetStatus {
    case success
    case empty
    case invalid
}

public enum BonusStatus {
    case unkonw
    case waitOnline
    case online
    case deadline
    case unusualClose
    case complete
}

public struct RedEnvelopeStatus: HandyJSON {
    
    public var id: Int = 0
    public var user_id: Int = 0
    public var tg_user_id: String = ""
    
    public var secret_num: String = ""
    
    public var tx_hash: String = ""
    
    public var payment_account: String = ""
    public var chain_id: Int = 0
    public var chain_name: String = ""
    public var currency_id: Int = 0
    public var currency_name: String = ""
    public var amount: String = ""
    public var gas_amount: String = ""
    
    public var num: Int = 0
    
    public var num_exec: Int = 0
    public var receive_user_id: Int = 0
    
    public var status: Int = 0
    
    public var source: Int = 0
    
    public var created_at: Double = 0
    
    public var is_get: Bool = false
    
    public init() { }

}

public func formatedStatus(status: Int) -> BonusStatus {
    switch status {
    case 1:
        return .waitOnline
    case 2:
        return .online
    case 3:
        return .deadline
    case 4:
        return .unusualClose
    case 5:
        return .complete
    default:
        return .unkonw
    }
}

public struct RecordItem: HandyJSON {
    
    public enum PayStatus {
        case waitPay
        case waitOnline
        case payYet
        case payFault
    }
    
    public var tx_hash: String = ""
    public var tg_user_id: String = ""
    
    public var receipt_account: String = ""
    
    public var amount: String = ""
    
    public var status: Int = 0
    
    public var type: Int = 0
    
    public var created_at: Int = 0
    
    public var usd_amount: String = ""
    
    public init() {}
    
    public func payStatus() -> PayStatus {
        switch self.status {
        case 1:
            return .waitPay
        case 2:
            return .waitOnline
        case 3:
            return .payYet
        default:
            return .payFault
        }
    }
}

public struct RedEnvelopeDetail: HandyJSON {
    
    public var id: Int = 0
    public var user_id: Int = 0
    public var tg_user_id: String = ""
    public var secret_num: String = ""
    public var tx_hash: String = ""
    public var payment_account: String = ""
    public var chain_id: Int = 0
    public var chain_name: String = ""
    public var currency_id: Int = 0
    public var currency_name: String = ""
    public var amount: String = ""
    public var gas_amount: String = ""
    public var num: Int = 0
    public var num_exec: Int = 0
    public var receive_user_id: Int = 0
    
    public var status: Int = 4
    public var source: Int = 0
    public var created_at: Int = 0
    public var message: String = ""
    public var usd_amount: String = ""
    public var record = [RecordItem]()
    public var is_get: Bool = false
    
    public init() {}
}

struct RedEnvelopeConfig: HandyJSON, Equatable  {
    
    struct Currency: HandyJSON, Equatable {
        var id: NSInteger = 0
        var icon: String = ""
        var name: String = ""
        var decimal: NSInteger = 0
        var min_price: String = ""
        var max_num: String = ""
        var gas_price: String = ""
        var is_main_currency: Bool = false
        
        static func == (lhs: Currency, rhs: Currency) -> Bool {
            return lhs.id == rhs.id
        }
    }
    
    struct Config: HandyJSON, Equatable  {
        var id: NSInteger = 0
        var icon: String = ""
        var name: String = ""
        var currency = [Currency]()
        
        static func == (lhs: Config, rhs: Config) -> Bool {
            return lhs.id == rhs.id
        }
    }
    
    var address: String = ""
    var config = [Config]()
    
    static func == (lhs: RedEnvelopeConfig, rhs: RedEnvelopeConfig) -> Bool {
        return lhs.address == rhs.address
    }
    
    static let emptyConfig = RedEnvelopeConfig()
    
    func isEmpty() -> Bool {
        return self.address.isEmpty || self.config.isEmpty
    }
}

struct CreateResult: HandyJSON, Equatable {
    
    var user_id: Int = 0
    var tg_user_id: String = ""
    var secret_num: String = ""
    var tx_hash: String = ""
    var payment_account: String = ""
    var chain_id: String = ""
    var chain_name: String = ""
    var currency_id: String = ""
    var currency_name: String = ""
    var amount: String = ""
    var gas_amount: String = ""
    var num: String = ""
    var receive_user_id: Int = 0
    var source: Int = 0
    var created_at: Int = 0
    var id: Int = 0
    
    static func == (lhs: CreateResult, rhs: CreateResult) -> Bool {
        return lhs.id == rhs.id
    }
    
    static let errorResult = CreateResult()
    
    func isError() -> Bool {
        return self.id <= 0
    }
}


public class TBRedEnvelopeInteractor {
    
    class func fetchCurrencyPrice(by coinId: String) -> Signal<CurrencyPrice, NoError> {
         return Signal { subscriber in
             TBNetwork.request(api: TransferAsset.currencyPrice.rawValue,
                               paramsFillter: ["coin_id" : coinId],
                               successHandle: { data, message in
                 if let dic = data as? Dictionary<String, Any>, let info = CurrencyPrice.deserialize(from: dic) {
                     subscriber.putNext(info)
                 } else {
                     subscriber.putNext(CurrencyPrice())
                 }
                 subscriber.putCompletion()
             }, failHandle: { code, message in
                 subscriber.putNext(CurrencyPrice())
                 subscriber.putCompletion()
             })
             return EmptyDisposable
         }
     }
    
    class func fetchRedEnvelopeConfig() -> Signal<RedEnvelopeConfig, NoError> {
        return Signal { subscriber in
            TBNetwork.request(api: Web3.bonusConfig.rawValue, successHandle: { data, message in
                if let c = data as? Dict, let config = RedEnvelopeConfig.deserialize(from: c) {
                    subscriber.putNext(config)
                } else {
                    subscriber.putNext(RedEnvelopeConfig.emptyConfig)
                }
            }, failHandle: { code, message in
                subscriber.putNext(RedEnvelopeConfig.emptyConfig)
            })
            return EmptyDisposable
        }
    }
    
    class func ceateRedEnvelop(tx_hash: String, amount: String, num: String,
                               chain_id: String, chain_name: String,
                               currency_id: String, currency_name: String,
                               payment_account: String, gas_amount: String, source: String) -> Signal<CreateResult, NoError> {
        return Signal { subscriber in
            TBNetwork.request(api: Web3.bonusCreate.rawValue,
                              paramsFillter: ["tx_hash" : tx_hash,
                                              "amount" : amount,
                                              "num" : num,
                                              "chain_id" : chain_id,
                                              "chain_name" : chain_name,
                                              "currency_id" : currency_id,
                                              "currency_name" : currency_name,
                                              "payment_account" : payment_account,
                                              "gas_amount" : gas_amount,
                                              "source" : source],
                              successHandle: { data, message in
                if let c = data as? Dict, let result = CreateResult.deserialize(from: c) {
                    subscriber.putNext(result)
                } else {
                    subscriber.putNext(CreateResult.errorResult)
                }
            }, failHandle: { code, message in
                subscriber.putNext(CreateResult.errorResult)
            })
            return EmptyDisposable
        }
    }
    
    class func fetchRedEnvelopeStatusForceOnline(secret_num: String) -> Signal<RedEnvelopeStatus, BonusStatus> {
        return self.fetchRedEnvelopeStatus(secret_num: secret_num) |> mapToSignalPromotingError({ status in
            return Signal<RedEnvelopeStatus, BonusStatus>{ subscriber in
                let bonusStatus = formatedStatus(status: status.status)
                if bonusStatus == .online {
                    subscriber.putNext(status)
                } else {
                    subscriber.putError(bonusStatus)
                }
                return EmptyDisposable
            }
        })
    }
    
    public class func fetchRedEnvelopeStatus(secret_num: String) -> Signal<RedEnvelopeStatus, NoError> {
        return Signal { subscriber in
            TBNetwork.request(api: Web3.bonusStatus.rawValue,
                              paramsFillter: ["secret_num" : secret_num],
                              successHandle: { data, message in
                if let c = data as? Dict, let state = RedEnvelopeStatus.deserialize(from: c) {
                    subscriber.putNext(state)
                } else {
                    subscriber.putNext(RedEnvelopeStatus())
                }
            }, failHandle: { code, message in
                subscriber.putNext(RedEnvelopeStatus())
            })
            return EmptyDisposable
        }
    }
    
    public class func bonusGet(secret_num: String, receipt_account: String) -> Signal<BonusGetStatus, NoError> {
        return Signal { subscriber in
            TBNetwork.request(api: Web3.bonusGet.rawValue,
                              paramsFillter: ["secret_num" : secret_num,
                                              "receipt_account" : receipt_account],
                              successHandle: { data, message in
                subscriber.putNext(.success)
            }, failHandle: { code, message in
                subscriber.putNext(self.transformCodeToBonusGetStatus(code: code))
            })
            return EmptyDisposable
        }
    }
    
    private class func transformCodeToBonusGetStatus(code: Int) -> BonusGetStatus {
        switch code {
        case 200, 10012:
            return .success
        case 10011:
            return .empty
        default:
            return .invalid
        }
    }
    
    public class func bonusDetail(secret_num: String) -> Signal<RedEnvelopeDetail, NoError> {
        return Signal { subscriber in
            TBNetwork.request(api: Web3.bonusDetail.rawValue,
                              paramsFillter: ["secret_num" : secret_num],
                              successHandle: { data, message in
                if let c = data as? Dict, let detail = RedEnvelopeDetail.deserialize(from: c) {
                    subscriber.putNext(detail)
                } else {
                    subscriber.putNext(RedEnvelopeDetail())
                }
            }, failHandle: { code, message in
                subscriber.putNext(RedEnvelopeDetail())
            })
            return EmptyDisposable
        }
    }
    
    public class func bonusTransaction(secret_num: String) -> Signal<RedEnvelopeDetail, NoError> {
        return Signal { subscriber in
            TBNetwork.request(api: Web3.bonusDetail.rawValue,
                              paramsFillter: ["secret_num" : secret_num],
                              successHandle: { data, message in
                if let c = data as? Dict, let detail = RedEnvelopeDetail.deserialize(from: c) {
                    subscriber.putNext(detail)
                } else {
                    subscriber.putNext(RedEnvelopeDetail())
                }
            }, failHandle: { code, message in
                subscriber.putNext(RedEnvelopeDetail())
            })
            return EmptyDisposable
        }
    }
}


public struct TBZapperToken: HandyJSON {
    public struct ProductsItem: HandyJSON {
        var label: String!
        var assets: [AssetsItem]?
        var meta: [MetaItem]?
        public init() {}
    }

    public struct MetaItem: HandyJSON {
        var label: String = ""
        var value: CGFloat = 0.0
        var type: String = ""
        public init() {}
    }
    
    var products: [ProductsItem]?
    var meta: [MetaItem]?
    
    public init() {}
}

public class TBZapperNetworkBalance {

    struct Zapper: Encodable {
        let network: String
        let addresses: [String]
    }
    
    public enum ZapperResult {
        case success(tokens: [Dict])
        case failure(code: Int, message: String)
    }
    
    public enum ZapperNetworkType {
        case Eth
        case Polygon
    }
    
    public class func getAppsBalances(appId: String, type: ZapperNetworkType, addresses: [String]) -> Signal<ZapperResult, NoError>  {
        let url = "https://api.zapper.fi/v2/apps/tokens/balances"
        let network = type == .Eth ? "ethereum" : "polygon"
        let zapper = Zapper(network: network, addresses: addresses)
        var headers = HTTPHeaders.default
        headers.add(name: "Accept", value: "application/json")
        headers.add(name: "Authorization", value: "Basic " + base64Encoding(str: appId))
        return Signal { subscriber in
            AF.request(url,
                       method: .get,
                       parameters: zapper,
                       headers: headers).response(responseSerializer: StringResponseSerializer()) { response in
                switch response.result {
                case .success(let bin):
                    let data = bin.data(using: String.Encoding.utf8)
                    if let d = data, let result = try? JSONSerialization.jsonObject(with: d, options: .mutableContainers) as? Dict, let balances = result["balances"] as? Dict {
                        var tokens = [Dict]()
                        for value in balances.values {
                            if let d = value as? Dict {
                                tokens.append(d)
                            }
                        }
                        subscriber.putNext(ZapperResult.success(tokens: tokens))
                    } else {
                        subscriber.putNext(ZapperResult.success(tokens: [Dict]()))
                    }
                case .failure(let error):
                    subscriber.putNext(ZapperResult.failure(code: error.responseCode ?? -999, message: error.errorDescription ?? ""))
                }
                subscriber.putCompletion()
            }
            return EmptyDisposable
        }
    }
}


public class TBTTNetworkBalance {
    
    struct Zapper: Encodable {
        let network: String
        let addresses: [String]
    }
    
    public class func getAppsBalances(appId: String, address: String) -> Signal<String, NoError>  {
        let url = "https://api.viewblock.io/v1/thundercore/addresses/" + address
        var headers = HTTPHeaders.default
        headers.add(name: "Accept", value: "application/json")
        headers.add(name: "X-APIKEY", value: appId)
        return Signal { subscriber in
            AF.request(url,
                       method: .get,
                       headers: headers).response(responseSerializer: StringResponseSerializer()) { response in
                switch response.result {
                case .success(let bin):
                    let data = bin.data(using: String.Encoding.utf8)
                    if let d = data, let result = try? JSONSerialization.jsonObject(with: d, options: .mutableContainers) as? Array<Dict>, let balance = result.first?["balance"] as? String {
                        subscriber.putNext(balance)
                    } else {
                        subscriber.putNext("0")
                    }
                case .failure(_):
                    subscriber.putNext("0")
                }
                subscriber.putCompletion()
            }
            return EmptyDisposable
        }
    }
}



public class TBOasisNetworkBalance {
    
    struct Zapper: Encodable {
        let module: String = "account"
        let action: String = "balance"
        let address: String
    }
    
    public class func getAppsBalances(address: String) -> Signal<String, NoError>  {
        let url = "https://explorer.emerald.oasis.doorgod.io/api"
        var headers = HTTPHeaders.default
        headers.add(name: "Accept", value: "application/json")
        let zapper = Zapper(address: address)
        return Signal { subscriber in
            AF.request(url,
                       method: .get,
                       parameters: zapper,
                       headers: headers).response(responseSerializer: StringResponseSerializer()) { response in
                switch response.result {
                case .success(let bin):
                    let data = bin.data(using: String.Encoding.utf8)
                    if let d = data, let result = try? JSONSerialization.jsonObject(with: d, options: .mutableContainers) as? Dict, let balance = result["result"] as? String {
                        subscriber.putNext(balance)
                    } else {
                        subscriber.putNext("0")
                    }
                case .failure(_):
                    subscriber.putNext("0")
                }
                subscriber.putCompletion()
            }
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
