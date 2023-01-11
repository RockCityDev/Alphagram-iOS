
import Foundation
import HandyJSON
import TBAccount
import TBLanguage

extension TBWeb3GroupInfoEntry {
    public func getShareUrl() -> String {
        let data = TBAccount.shared.systemCheckData
        return "\(data.h5_domain)" + "?id=\(self.id)"
    }
}


public struct TBWeb3GroupInfoEntry : HandyJSON, Equatable {
    
    public enum GType:String {
        case group = "group"
        case channel = "channel"
        case supergroup = "supergroup"
        
        public static func transferFrom(string: String) -> GType {
            if string == GType.group.rawValue {
                return .group
            }else if string == GType.supergroup.rawValue {
                return .supergroup
            }else if string == GType.channel.rawValue {
                return .channel
            }
            return .group
        }
    }
    
    public enum LimitType: Int, Equatable {
        case noLimit = 1
        case conditionLimit = 2
        case payLimit = 3
        
        public static func == (lhs: LimitType, rhs: LimitType) -> Bool {
           return lhs.rawValue == rhs.rawValue
        }
        public static func transferFrom(int: Int) -> LimitType {
            if int == LimitType.noLimit.rawValue {
                return .noLimit
            }else if int == LimitType.conditionLimit.rawValue {
                return .conditionLimit
            }else if int == LimitType.payLimit.rawValue {
                return .payLimit
            }
            return .noLimit
        }
    }
    
    public struct Tag: HandyJSON, Equatable{
        public var id:String = ""
        public var name: String = ""
        public var selected = false


        public init() {
        }
        public static func == (lhs: Tag, rhs: Tag) -> Bool {
            if lhs.id == rhs.id, lhs.name == rhs.name {
                return true
            }
            return false
        }
    }
    
    public struct OrderInfo: HandyJSON, Equatable {
        public var tx_hash = ""
        public var ship = TBWeb3GroupOrderEntry.Ship()
        public init() {}
    }
    
    
    public var id: Int64 = 0
    
    private var chat_id: Int64 = 0
    ///    "group",  "channel", "supergroup"
    public var type: String = ""
    
    public var title: String = ""
    
    public var description: String = ""
    
    public var avatar :String = ""
    public var creator_id: Int64 = 0
    public var ship: Int64 = 0
    
    public var join_type: Int = 1
    
    public var receipt_account: String = ""
    
    public var wallet_id: Int64 = 0
    
    public var wallet_name: String = ""
    
    public var chain_id: Int64 = 0
    
    public var chain_name: String = ""
    
    public var token_id: Int64 = 0
    
    public var token_name: String = ""
    
    public var amount: String = ""
    
    public var currency_id: Int64 = 0
    
    public var currency_name: String = ""
    
    public var token_address: String = ""
    
    public var status: Int = 0
    
    public var audit_status: Int = 0
    
    public var audit_opinion: String = ""
    
    
    public var created_at: String = ""
    
    
    public var updated_at: String = ""
    
    
    public var amount_to_wei: String = ""
    
    
    public var tags: [Tag] = [Tag]()
    
    public var contract_address = ""
    
    public var order_info = [OrderInfo]()
    
    public init() {
    }
    
    public static func == (lhs: TBWeb3GroupInfoEntry, rhs: TBWeb3GroupInfoEntry) -> Bool {
        if lhs.id != rhs.id {
            return false
        }
        if lhs.chain_id != rhs.id {
            return false
        }
        return true
    }
    
    public func transferGType() -> GType {
        return .transferFrom(string: self.type)
    }
    
    public func transferJoinType() -> LimitType {
        return .transferFrom(int: self.join_type)
    }
    
    
    public func abs_tg_group_id() -> Int64 {
        return abs(self.chat_id)
    }
    
    public func ori_tg_chat_id() -> Int64 {
        return self.chat_id
    }
}

extension TBWeb3GroupInfoEntry.LimitType {
    public var des: String {
        switch self {
        case .noLimit:
            return TBLanguage.sharedInstance.localizable(TBLankey.create_group_join_group)
        case .conditionLimit:
            return  TBLanguage.sharedInstance.localizable(TBLankey.create_group_conditionjoin_group)
        case .payLimit:
            return TBLanguage.sharedInstance.localizable(TBLankey.create_group_paytojoin_group)
        }
    }
}

