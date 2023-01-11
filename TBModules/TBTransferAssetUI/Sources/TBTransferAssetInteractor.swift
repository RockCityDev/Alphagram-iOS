import Foundation
import HandyJSON
import TBNetwork
import SwiftSignalKit
import Alamofire
import TBWeb3Core

public typealias Dict = Dictionary<String, Any>



public struct TBUserTransferListEntity: HandyJSON {
    
    public struct Item: HandyJSON, Equatable {
        public var id:Int64 = 0
        public var payment_tg_user_id = ""
        public var payment_account = ""
        public var receipt_tg_user_id = ""
        public var receipt_account = ""
        public var tx_hash = ""
        public var amount = ""
        public var chain_id:Int = 0
        public var chain_name = ""
        public var currency_id:Int = 0
        public var currency_name = ""
        public var created_at = ""
        public var updated_at = ""
        public init() {}
        
        public static func == (lhs: Item, rhs: Item) -> Bool {
            if lhs.id != rhs.id {
                return false
            }
            return true
        }
    }
    
    var current_page: Int = 0
    var data: [Item] = [Item]()
    var first_page_url = ""
    var from: Int = 0
    var last_page = 0
    var last_page_url = ""
    var next_page_url = ""
    var path = ""
    var per_page: Int = 0
    var prev_page_url = ""
    var to:Int = 0
    var total: Int = 0

    public init() {}
}

public struct CurrencyPrice: HandyJSON {
    public var usd: String = "0"
    
    public init() {}
}


public class TBTransferAssetInteractor {
    
    
   public class func fetchNetworkInfo(by tgUserId: String) -> Signal<NetworkInfo, TBNetError> {
        return Signal { subscriber in
            TBNetwork.request(api: TransferAsset.infoFromTGUser.rawValue,
                              paramsFillter: ["tg_user_id" : tgUserId],
                              successHandle: { data, message in
                if let dic = data as? Dictionary<String, Any>, let info = NetworkInfo.deserialize(from: dic) {
                    subscriber.putNext(info)
                } else {
                    subscriber.putError(TBNetError.normal(code: -999, message: "Invalid Data"))
                }
                subscriber.putCompletion()
            }, failHandle: { code, message in
                subscriber.putError(TBNetError.normal(code: code, message: message))
                subscriber.putCompletion()
            })
            return EmptyDisposable
        }
    }
    
    public class func fetchNetworkInfoList(by tgUserIds: [String]) -> Signal<[NetworkInfo], TBNetError> {
         return Signal { subscriber in
             TBNetwork.request(api: TransferAsset.infoFromTGUser.rawValue,
                               paramsFillter: ["tg_user_id" : tgUserIds],
                               successHandle: { data, message in
                 if let list = data as? [Dictionary<String, Any>], let info = [NetworkInfo].deserialize(from: list) {
                     subscriber.putNext(info.compactMap{$0})
                 } else {
                     subscriber.putError(TBNetError.normal(code: -999, message: "Invalid Data"))
                 }
                 subscriber.putCompletion()
             }, failHandle: { code, message in
                 subscriber.putError(TBNetError.normal(code: code, message: message))
                 subscriber.putCompletion()
             })
             return EmptyDisposable
         }
     }
    
    public class func fetchNetworkInfoMap(by tgUserIds: [String]) -> Signal<[Int64: NetworkInfo], TBNetError> {
        return self.fetchNetworkInfoList(by: tgUserIds) |> map({ list in
            var ret = [Int64 : NetworkInfo]()
            for item in list {
                if let key = Int64(item.tg_user_id), !item.wallet_info.isEmpty{
                    ret[key] = item
                }
            }
            return ret
        })
     }
    
    public class func fetchUserTransferInfo() -> Signal<TBUserTransferListEntity, TBNetError> {
         return Signal { subscriber in
             TBNetwork.request(api: TransferAsset.user_transfer.rawValue,
                               paramsFillter: nil,
                               successHandle: { data, message in
                 if let dict = data as? Dictionary<String, Any>, let info = TBUserTransferListEntity.deserialize(from: dict) {
                     subscriber.putNext(info)
                 } else {
                     subscriber.putError(TBNetError.normal(code: -999, message: "Invalid Data"))
                 }
                 subscriber.putCompletion()
             }, failHandle: { code, message in
                 subscriber.putError(TBNetError.normal(code: code, message: message))
                 subscriber.putCompletion()
             })
             return EmptyDisposable
         }
     }
    
    public class func fetchUserTransferInfo_() -> Signal<TBUserTransferListEntity?, NoError> {
        return self.fetchUserTransferInfo() |> map({ entry in
            let ret: TBUserTransferListEntity? = entry
            return ret
        }) |> `catch`({ error in
            return Signal { subscriber in
                subscriber.putNext(nil)
                subscriber.putCompletion()
                return EmptyDisposable
            }
        })
     }

    public class func fetchCurrencyPrice(by coinId: String) -> Signal<CurrencyPrice, NoError> {
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
    
    public class func updateTransfer(payment_tg_user_id: String, payment_account: String, receipt_tg_user_id: String, receipt_account: String, chain_id: String, chain_name: String, amount: String, currency_id: String, currency_name: String, tx_hash: String) -> Signal<Bool, NoError> {
        return Signal { subscriber in
            TBNetwork.request(api: TransferAsset.transfer.rawValue,
                              paramsFillter: ["payment_tg_user_id" : payment_tg_user_id,
                                              "payment_account" : payment_account,
                                              "receipt_tg_user_id" : receipt_tg_user_id,
                                              "receipt_account" : receipt_account,
                                              "chain_id" : chain_id,
                                              "chain_name" : chain_name,
                                              "amount" : amount,
                                              "currency_id" : currency_id,
                                              "currency_name" : currency_name,
                                              "tx_hash" : tx_hash],
                              successHandle: { data, message in
                subscriber.putCompletion()
            }, failHandle: { code, message in
                subscriber.putCompletion()
            })
            return EmptyDisposable
        }
     }
}



public struct TTOSAssetsItem: HandyJSON, Equatable {
    
    public var id: Int = 0
    public var coin_id = ""
    public var decimal: Int = 0
    public var is_main_currency = false
    public var icon = ""
    public var price: String = "0"
    public var symbol: String = ""
    public var balance: String = "0"
    public var balanceUSD: String = "0"
    public var network = ""
    public init() {}
    
    public static func == (lhs: TTOSAssetsItem, rhs: TTOSAssetsItem) -> Bool {
        return lhs.symbol == rhs.symbol
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
