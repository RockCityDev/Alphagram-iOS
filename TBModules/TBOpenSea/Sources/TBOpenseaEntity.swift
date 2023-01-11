import Foundation
import HandyJSON

public class TBAssetsEntity : HandyJSON{
    
    public class Item : HandyJSON{
        public class AssetsContract : HandyJSON {
            public var address = ""
            public var symbol = ""
            public var schema_name = ""
            required public init() {
            }
        }
        public class SeaportSellOrder : HandyJSON {
            public var current_price = ""
            required public init() {
            }
        }
        public class LastPrice : HandyJSON {
            public var total_price = ""
            required public init() {
            }
        }
        public class Collection : HandyJSON {
            public var name = ""
            public var hidden: Bool = false
            required public init() {
            }
        }
        
        public var id : Int64 = 0
        public var name = ""
        public var token_id = ""
        public var image_url = ""
        public var image_preview_url = ""
        public var image_thumbnail_url = ""
        public var asset_contract = AssetsContract()
        public var seaport_sell_orders = [SeaportSellOrder]()
        public var last_sale = LastPrice()
        public var collection = Collection()
        required public init() {
        }
    }
    
    public var next = ""
    public var previous = ""
    public var assets = [Item]()
    public var results = [Item]()
    required public init() {
    }
    
    
}


