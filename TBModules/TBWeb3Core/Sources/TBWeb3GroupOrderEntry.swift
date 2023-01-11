
import Foundation
import HandyJSON


public struct TBWeb3GroupOrderEntry : HandyJSON {
    
    public struct Ship: HandyJSON, Equatable {
        public let url = ""
        public init() {}
    }
    
    
    public var id: Int64 = 0
    public var order_no = ""
    public var group_id:Int64 = 0
    public var user_id:Int64 = 0
    public var join_type: Int = 0
    public var status: Int = 0
    public var ship = Ship()
    public var chain_id: Int = 0
    public var chain_name = ""
    public var currency_id:Int = 0
    public var currency_name = ""
    public var tx_hash = ""
    public var payment_account = ""
    public var receipt_account = ""
    public var amount = ""
    public var amount_balance = ""
    public var created_at = ""
    public var updated_at = ""
    public init() {}
}
