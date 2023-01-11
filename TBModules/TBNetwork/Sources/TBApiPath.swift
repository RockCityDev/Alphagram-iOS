import Foundation


public enum Logging: String {
    
    case systemCheck = "/system/check"
    
    case passportLogin = "/passport/login"
    
    case systemGetCode = "/system/getcode"
    
    case updateUserNftInfo = "/user/nftInfo"
    
    case userBindWallet = "/user/bind/wallet"
}


public enum Recommend: String {
    
    case tgchatRecommend = "/tgchat/recommend"
}

public enum Web3: String {
    case token = "https://api.zapper.fi"
    case activity = "https://api.etherscan.io/api?module=account&action=txlist&sort=asc"
    case coinGecko = "https://api.coingecko.com/api/v3"
    
    case config = "/web3/config"
    
    case creatGroup = "/web3/create/group"
    
    case groupList = "/web3/group/list"
    
    case orderPost = "/web3/order/post"
    
    case groupInfo = "/web3/group/info"
    
    case updateGroup = "/web3/update/group"
    
    case orderResult = "/web3/order/result"
    
    case groupAccredit = "/web3/group/accredit"
    
    case hotTags = "/web3/hot/tags"
    
    case currency_price = "/web3/currency/price"
    
    case groupInfoByChatId = "/web3/group/infobychatid"
    
    case bonusConfig = "/bonus/config"
    
    case bonusCreate = "/bonus/create"
    
    case bonusStatus = "/bonus/status"
    
    case bonusGet = "/bonus/get"
    
    case bonusDetail = "/bonus/detail"
}

public enum TransferAsset: String {
    case infoFromTGUser = "/nftInfo/tguserid"
    case user_transfer = "/user/transfer"
    case currencyPrice = "/web3/currency/price"
    case transfer = "/web3/transfer"
}

public enum Upload: String {
    case image = "/upload/file"
}
