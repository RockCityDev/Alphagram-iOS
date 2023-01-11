
import Foundation
import HandyJSON

public class TBSystemCheckData: HandyJSON {
    
    public var testerphones = [String]()
    public var openseaapikey = ""
    public var bot_username = ""
    public var bot_nickname = ""
    public var zapper = ""
    public var eth_api_key = ""
    public var polygon_api_key = ""
    public var tt_api_key = ""
    public var wallet_address = ""
    public var h5_domain = ""
    public var wallet_way = ""
    public required init() {
        
    }
}

public class TBUser: HandyJSON {
    
    public var name = ""
    public var sticker = ""
    public var avatar = ""
    public var tg_user_id: Int64 = 0 
    public var id = 0 
    public var user_id = 0 
    public var region = 0
    public var nft_contract = ""
    public var nft_contract_image = ""
    public var nft_token_id = ""
    public var nft_photo_id = ""
    public var nft_name = ""
    public required init() {}
    
    public func updateNftInfo(info:TBUser) {
        self.nft_contract = info.nft_contract
        self.nft_contract_image = info.nft_contract_image
        self.nft_token_id = info.nft_token_id
        self.nft_photo_id = info.nft_photo_id
        self.nft_name = info.nft_name
    }
}


public class TBPhoneCode: HandyJSON {
    public var phone = ""
    public var code = ""
    public required init() {}
}

public class TBLoginData: HandyJSON {
    public var newer = false
    public var token = ""
    public var user = TBUser()
    public required init() {}
    
    public func isLogin() -> Bool {
        return self.user.id > 0 && self.token.count > 0
    }
}



