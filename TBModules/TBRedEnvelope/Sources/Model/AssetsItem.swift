
import Foundation
import HandyJSON


protocol TBTokenItem {
    func tokenIcon() -> String
    func tokenName() ->  String
    func tokenMarketPrice() ->  String
    func tokenCount() ->  String
    func tokenTotal() ->  String
}



struct AssetsItem: HandyJSON, Equatable {
    
    struct DisplayProp: HandyJSON {
        var label: String = ""
        var images: [String]?
        public init() {  }
    }
    
    var type: String = ""
    var appId: String = ""
    var groupId: String = ""
    var supply: Int = 0
    var network: String = ""
    var price: String = ""
    var address: String = ""
    var decimals: Int = 0
    var symbol: String = ""
    var balance: String = ""
    var balanceRaw: String = ""
    var balanceUSD: String = ""
    var displayProps: DisplayProp?
    
    static func == (lhs: AssetsItem, rhs: AssetsItem) -> Bool {
        return lhs.symbol == rhs.symbol
    }
}

extension AssetsItem: TBTokenItem {
    public func tokenIcon() -> String {
        return self.displayProps?.images?.first ?? ""
    }
    
    public func tokenName() -> String {
        return self.displayProps?.label ?? ""
    }
    
    public func tokenMarketPrice() -> String {
        return self.price
    }
    
    public func tokenCount() -> String {
        return self.balance
    }
    
    public func tokenTotal() -> String {
        return self.balanceUSD
    }
}


struct TTOSAssetsItem: HandyJSON, Equatable {
    
    var id: Int = 0
    var coin_id = ""
    var decimal: Int = 0
    var is_main_currency = false
    var icon = ""
    var price: String = "0"
    var symbol: String = ""
    var balance: String = "0"
    var balanceUSD: String = "0"
    var network = ""
    
    static func == (lhs: TTOSAssetsItem, rhs: TTOSAssetsItem) -> Bool {
        return lhs.symbol == rhs.symbol
    }
}

extension TTOSAssetsItem: TBTokenItem {
    public func tokenIcon() -> String {
        return self.icon
    }
    
    public func tokenName() -> String {
        return self.symbol
    }
    
    public func tokenMarketPrice() -> String {
        return self.price
    }
    
    public func tokenCount() -> String {
        return self.balance
    }
    
    public func tokenTotal() -> String {
        return self.balanceUSD
    }
}




