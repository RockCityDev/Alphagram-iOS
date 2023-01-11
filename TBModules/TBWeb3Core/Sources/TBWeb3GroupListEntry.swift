
import Foundation
import HandyJSON


public struct TBWeb3GroupListEntry : HandyJSON {
    
    public struct Item : HandyJSON, Equatable {
       
        
        
        
        public var id : Int64 = 0
        private var chat_id : Int64 = 0
        
        public var type = ""
        public var title = ""
        public var description = ""
        public var avatar = ""
        public var creator_id: Int64 = 0
        public var ship: Int64 = 0
        
        public var join_type: Int = 0
        public var receipt_account = ""
        
        
        public var wallet_id : Int = 0
        public var wallet_name = ""
        public var chain_id: Int = 0
        public var chain_name = ""
        public var token_id: Int = 0
        public var token_name = ""
        public var currency_id: Int = 0
        public var currency_name = ""
        
        public var amount = ""
        public var token_address = ""
        public var status : Int = 0
        public var audit_status: Int = 0
        public var audit_opinion = ""
        public var created_at = ""
        public var updated_at = ""
        public var tags = [String]()
        public var contract_address = ""
        public var currency_icon = ""
        
        public var amount_to_wei: String = ""
        
        public init() {}
        
        public static func == (lhs: Item, rhs: Item) -> Bool {
            if lhs.id != rhs.id {
                return false
            }
            
            if lhs.chat_id != rhs.chat_id {
                return false
            }
            
            return true
        }
        
        
        public func abs_tg_group_id() -> Int64 {
            return abs(self.chat_id)
        }
        
        public func ori_tg_chat_id() -> Int64 {
            return self.chat_id
        }
    }
    public var current_page: Int64 = 0
    public var data = [Item]()
    
    public init() {}
}
