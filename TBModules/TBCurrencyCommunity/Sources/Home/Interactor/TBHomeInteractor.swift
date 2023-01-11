import Foundation
import HandyJSON
import TBNetwork
import SwiftSignalKit
import Alamofire

public typealias Dict = Dictionary<String, Any>

public struct CurrencyPrice: HandyJSON {
    public var usd: String = "0"
    public var usd_24h_change: String = "0"
    public init() {}
}

public struct Ship: HandyJSON {
    
    var url: String = ""
    
    public init() { }
}

public struct VerifyOrder: HandyJSON {
    
    var order_no: String = ""
    var user_id: Int = 0
    var join_type: Int = 0
    var group_id: String = ""
    var status: Int = 0
    var amount: String = ""
    var chain_id: Int = 0
    var chain_name: String = ""
    var currency_id: Int = 0
    var currency_name: String = ""
    var payment_account: String = ""
    var receipt_account: String = ""
    var tx_hash: String = ""
    var updated_at: String = ""
    var created_at: String = ""
    var id: Int = 0
    var amount_balance: Int = 0
    var ship: Ship?
    
    public init() { }
}


public class TBHomeInteractor {

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
    
    public class func fetchGroupAccredit(by group_id: String, payment_account: String) -> Signal<VerifyOrder, NoError> {
         return Signal { subscriber in
             TBNetwork.request(api: Web3.groupAccredit.rawValue,
                               paramsFillter: ["group_id" : group_id, "payment_account" : payment_account],
                               successHandle: { data, message in
                 if let dic = data as? Dictionary<String, Any>, let info = VerifyOrder.deserialize(from: dic) {
                     subscriber.putNext(info)
                 } else {
                     subscriber.putNext(VerifyOrder())
                 }
                 subscriber.putCompletion()
             }, failHandle: { code, message in
                 subscriber.putNext(VerifyOrder())
                 subscriber.putCompletion()
             })
             return EmptyDisposable
         }
     }
}
