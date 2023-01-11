
import TBStorage
import TBNetwork
import SwiftSignalKit
import Foundation
import Alamofire
import HandyJSON
import AppBundle
import TBDisplay
import TBWeb3Core

public typealias Dict = Dictionary<String, Any>

struct DisplayProps: HandyJSON {
    var label: String?
    var images: [String]?
    var statsItems: String?
}

struct Assets: HandyJSON {
    var type: String?
    var appId: String?
    var groupId: String?
    var supply: Int = 0
    var network: String?
    var price: String = ""
    var address: String?
    var decimals: Int = 0
    var symbol: String?
    var balance: String = ""
    var balanceRaw: String?
    var balanceUSD: String = ""
    var displayProps: DisplayProps?
    
}

extension Assets: TokenItem {
    func getIconUrl() -> String? {
        return self.displayProps?.images?.first ?? ""
    }
    
    func getTokenName() -> String {
        return (self.displayProps?.label ?? self.symbol) ?? ""
    }
    
    func getTokenPrice() -> String {
        return "$" + self.price.decimal(digits: 8)
    }
    
    func getBalance() -> String {
        return self.balance.decimal(digits: 8)
    }
    
    func getTotalAssets() -> String {
        self.balanceUSD.decimal(digits: 8)
    }
}

struct Product: HandyJSON {
    var label: String!
    var assets = [Assets]()
}

struct Meta: HandyJSON {
    var label: String?
    var value: CGFloat = 0.0
    var type: String?
}

struct TokenModel: HandyJSON {
    var products = [Product]()
    var meta = [Meta]()
}

class TBZapperNetwork {
    
    
    
    struct Zapper: Encodable {
        let network: String
        let addresses: [String]
    }
    
    public enum ZapperResult {
        case success(tokens: [Dict])
        case failure(code: Int, message: String)
    }
    
    public class func getAppsBalances(network: String = "ethereum", appId: String, addresses: [String]) -> Signal<ZapperResult, NoError>  {
        let url = Web3.token.rawValue + "/v2/apps/tokens/balances"
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



struct TBOSToken: HandyJSON {
    
    var balance: String = "0"
    var contractAddress: String = ""
    var decimals: Int = 0
    var name: String = ""
    var symbol: String = ""
    var type: String = ""
    var price: String = "0"
    
    func isNFT() -> Bool {
        return type != "ERC-20"
    }
    
    func iconName() -> String? {
        let list = ["celr", "ceusdc", "ftp", "luna", "mebtc", "rose", "weth", "weusdt", "wrose", "yuzu"]
        if list.contains(self.symbol.lowercased()) {
            return "TBWebPage/ic_os_" + self.symbol.lowercased()
        } else {
            return nil
        }
    }
}

extension TBOSToken: TBNFTItem {
    func nftContract() -> String {
        return self.contractAddress
    }
    
    func nftContractImage() -> String {
        return ""
    }
    
    func nftTokenId() -> String {
        return ""
    }
    
    func nftAssetName() -> String? {
        return self.name
    }
    
    func nftChainId() -> String? {
        return "42262"
    }
    
    func nftPrice() -> String? {
        return self.price
    }
    
    func nftTokenStandard() -> String? {
        return self.type
    }
    
    
    func getNFTName() -> String {
        return self.symbol
    }
}

extension TBOSToken: TokenItem {
    func getIconUrl() -> String? {
        return self.iconName()
    }
    
    func getTokenName() -> String {
        return self.symbol
    }
    
    func getTokenPrice() -> String {
        return "$" + self.price.decimal(digits: 8)
    }
    
    func getBalance() -> String {
        return NSDecimalNumber(string: self.balance.decimalString()).dividing(by: NSDecimalNumber(decimal: Decimal(pow(10, Double(self.decimals))))).decimalValue.description.decimal(digits: 8)
    }
    
    func getTotalAssets() -> String {
        let balance = NSDecimalNumber(string: self.balance.decimalString()).dividing(by: NSDecimalNumber(decimal: Decimal(pow(10, Double(self.decimals)))))
        return balance.multiplying(by: NSDecimalNumber(string: self.price.decimalString())).decimalValue.description.decimal(digits: 8)
    }
    
    
}

struct TBOSActivity: HandyJSON {
    var blockHash: String = ""
    var blockNumber: String = ""
    var confirmations: String = ""
    var contractAddress: String = ""
    var cumulativeGasUsed: String = ""
    var from: String = ""
    var gas: String = ""
    var gasPrice: String = ""
    var gasUsed: String = ""
    var hash: String = ""
    var input: String = ""
    var isError: String = "0"
    var nonce: String = ""
    var timeStamp: Double = 0
    var to: String = ""
    var transactionIndex: String = ""
    var txreceipt_status: String = ""
    var value: String = ""
    
    var currentAddress: String?
    var price: String = "0"
    
    func bitCostNum() -> String {
        let decimal = getMainCurrencyDecimalBy(type: .OS) ?? 0
        let bitCostStr = NSDecimalNumber(string: self.value.decimalString()).dividing(by: NSDecimalNumber(decimal: pow(10, decimal))).description
        return bitCostStr
    }
}

extension TBOSActivity: TBActivityItem {
    func getActTypeA() -> ActType {
        let isReceived = (self.currentAddress ?? "").lowercased() == self.to
        return isReceived ? .receive : .sent
    }
    
    func getDateStrA() -> String {
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd HH:mm"
        return format.string(from:Date(timeIntervalSince1970: self.timeStamp))
    }
    
    func getTitleA() -> String {
        let isReceived = (self.currentAddress ?? "").lowercased() == self.to
        if !isReceived {
            return "Send to " + (self.to)
        } else {
            return "Received from " + (self.from)
        }
    }
    
    func getStatusA() -> String {
        return self.isError == "0" ? "Confirmed" : "Fail"
    }
    
    func getBitCostA() -> String {
        let bitCost = self.bitCostNum().decimal(digits: 5)
        let t1 = self.getActTypeA() == .sent ? "- " : "+ "
        let t2 = (bitCost.isEmpty || bitCost == "0") ? "0" : t1 + bitCost
        let t3 = self.getSymbolA().isEmpty ? t2 : t2 + " " + self.getSymbolA()
        return t3
    }
    
    func getSymbolA() -> String {
        return getMainCurrencySymbolBy(type: .OS) ?? ""
    }
    
    func getBitCostTotalA() -> String? {
        let relCostNum = NSDecimalNumber(string: self.bitCostNum().decimalString())
        let totalStr = relCostNum.multiplying(by: NSDecimalNumber(string: self.price)).description.decimal(digits: 8)
        if !totalStr.isEmpty {
            return  "$" + totalStr
        }
        return ""
    }
    
    
}

class TBOSNetwork {
    
    public class func getAppsBalances(address: String) -> Signal<String?, NoError> {
        return Signal { subscriber in
            let url = "https://explorer.emerald.oasis.doorgod.io/api?address=" + address + "&module=account&action=balance"
            AF.request(url,
                       method: .get).response(responseSerializer: JSONResponseSerializer()) { response in
                switch response.result {
                case let .success(result):
                    if let r = result as? Dict, let balance = r["result"] as? String {
                        subscriber.putNext(balance)
                    } else {
                        subscriber.putNext(nil)
                    }
                    subscriber.putCompletion()
                case .failure(_):
                    subscriber.putNext(nil)
                    subscriber.putCompletion()
                    break
                }
            }
            return EmptyDisposable
        }
    }
    
    public class func getAppsTokens(address: String) -> Signal<Array<TBOSToken>, NoError> {
        return Signal { subscriber in
            let url = "https://explorer.emerald.oasis.doorgod.io/api?address=" + address + "&module=account&action=tokenlist"
            AF.request(url,
                       method: .get).response(responseSerializer: JSONResponseSerializer()) { response in
                switch response.result {
                case let .success(result):
                    if let r = result as? Dict, let arr = r["result"] as? [Dict], let tokens = JSONDeserializer<TBOSToken>.deserializeModelArrayFrom(array: arr) as? [TBOSToken] {
                        subscriber.putNext(tokens)
                    } else {
                        subscriber.putNext([])
                    }
                    subscriber.putCompletion()
                case .failure(_):
                    subscriber.putNext([])
                    subscriber.putCompletion()
                    break
                }
            }
            return EmptyDisposable
        }
    }
    
    public class func getTokensPrices() -> Signal<[String : String], NoError> {
        return Signal { subscriber in
            let url = "https://app.yuzu-swap.com/api/prices"
            AF.request(url,
                       method: .get).response(responseSerializer: JSONResponseSerializer()) { response in
                switch response.result {
                case let .success(result):
                    if let r = result as? Dict, let data = r["data"] as? [String : Any] {
                        var rel: [String : String] = [:]
                        for (key, value) in data {
                            rel[key] = "\(value)"
                        }
                        subscriber.putNext(rel)
                    } else {
                        subscriber.putNext([:])
                    }
                    subscriber.putCompletion()
                case .failure(_):
                    subscriber.putNext([:])
                    subscriber.putCompletion()
                    break
                }
            }
            return EmptyDisposable
        }
    }
    
    public class func getAppsActivity(address: String, page: Int) -> Signal<Array<TBOSActivity>, NoError> {
        return Signal { subscriber in
            let url = "https://explorer.emerald.oasis.doorgod.io/api?address=" + address + "&module=account&action=txlist&sort=desc&page=" + "\(page)"
            AF.request(url,
                       method: .get).response(responseSerializer: JSONResponseSerializer()) { response in
                switch response.result {
                case let .success(result):
                    if let r = result as? Dict, let arr = r["result"] as? [Dict], let rels = JSONDeserializer<TBOSActivity>.deserializeModelArrayFrom(array: arr) as? [TBOSActivity] {
                        subscriber.putNext(rels)
                    } else {
                        subscriber.putNext([])
                    }
                    subscriber.putCompletion()
                case .failure(_):
                    subscriber.putNext([])
                    subscriber.putCompletion()
                    break
                }
            }
            return EmptyDisposable
        }
    }
}

class TBRPCNetwork {
    
    public class func getAppsBalances(address: String) -> Signal<Array<TTToken>, NoError> {
        return Signal { subscriber in
            let url = "https://mainnet-rpc.thundercore.com"
            let tsm = NSInteger(Date().timeIntervalSince1970)
            var parameters = Array<Any>()
            parameters.append(tt_getBanlance(address: address, roundNum: tsm))
            let ttjson = ttTokens()
            for (index, item) in ttjson.enumerated() {
                parameters.append(tt_eth_call(address: address, to: item.contractAddress, roundNum: tsm + index + 1))
            }
            AF.request(url,
                       method: .post,
                       parameters: parameters.asParameters(),
                       encoding: ArrayEncoding()).response(responseSerializer: JSONResponseSerializer()) { response in
                switch response.result {
                case let .success(result):
                    var tokens = ttjson
                    tokens.insert(TTToken.mainToken(), at: 0)
                    if let arr = result as? Array<Dict> {
                        for (index, item) in arr.enumerated() {
                            if let balance = item["result"] as? String {
                                let b10 = balance.transform16To10()
                                tokens[index].balance = NSDecimalNumber(string: b10.decimalString()).dividing(by: NSDecimalNumber(decimal: pow(10, tokens[index].decimals))).decimalValue.description
                            }
                        }
                    }
                    subscriber.putNext(tokens.filter({$0.balance != "0"}))
                    subscriber.putCompletion()
                case .failure(_):
                    subscriber.putNext([])
                    subscriber.putCompletion()
                    break
                }
            }
            return EmptyDisposable
        }
    }
    
    public class func getTokensPrice()  -> Signal<Array<TTTokenPrice>, NoError> {
        return Signal { subscriber in
        let url = "https://ttswap.space/api/tokens"
        AF.request(url, method: .get).response(responseSerializer: JSONResponseSerializer()) { response in
            switch response.result {
            case let .success(result):
                if let r = result as? Dict,
                   let dic = r["data"] as? Dict,
                   let arr = dic["tokenList"] as? [Dict],
                   let prices = JSONDeserializer<TTTokenPrice>.deserializeModelArrayFrom(array: arr) as? [TTTokenPrice] {
                    subscriber.putNext(prices)
                } else {
                    subscriber.putNext([])
                }
                subscriber.putCompletion()
                break
            case .failure(_):
                subscriber.putNext([])
                subscriber.putCompletion()
                break
            }
        }
            return EmptyDisposable
        }
    }
    
    public class func getTTNFT(address: String) -> Signal<Array<TTNFT>, NoError> {
        return Signal { subscriber in
            let url = "https://tokenmanager.thundercore.com/json-rpc"
            let tsm = NSInteger(Date().timeIntervalSince1970)
            let parameters = tt_nft(address: address, roundNum: tsm)
            AF.request(url,
                       method: .post,
                       parameters: parameters,
                       encoding: JSONEncoding.default).response(responseSerializer: JSONResponseSerializer()) { response in
                switch response.result {
                case let .success(result):
                    if let r = result as? Dict,
                       let arr = r["result"] as? [Any],
                       let nfts = JSONDeserializer<TTNFT>.deserializeModelArrayFrom(array: arr) as? [TTNFT] {
                        subscriber.putNext(nfts)
                    } else {
                        subscriber.putNext([])
                    }
                    subscriber.putCompletion()
                case .failure(_):
                    subscriber.putNext([])
                    subscriber.putCompletion()
                    break
                }
            }
            return EmptyDisposable
        }
    }
    
    public class func getTTNFTPath(nfts: [TTNFT]) -> Signal<Array<TTNFT>, NoError> {
        return Signal { subscriber in
            let url = "https://mainnet-rpc.thundercore.com"
            let tsm = NSInteger(Date().timeIntervalSince1970)
            var reqNFTs = nfts
            var parameters = Array<Any>()
            for (index, item) in reqNFTs.enumerated() {
                reqNFTs[index].requestId = tsm + index
                parameters.append(tt_nftDetail(nft: item, roundNum: tsm + index))
            }
            AF.request(url,
                       method: .post,
                       parameters: parameters.asParameters(),
                       encoding: ArrayEncoding()).response(responseSerializer: JSONResponseSerializer()) { response in
                switch response.result {
                case let .success(result):
                    if let arr = result as? Array<Dict> {
                        for item in arr {
                            if let balance = item["result"] as? String,
                            let id = item["id"] as? NSInteger {
                                let a = balance.replacingOccurrences(of: "0x00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000082", with: "")
                                let a1 = a.replacingOccurrences(of: "0x000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000", with: "")
                                if let b = String(data: Data(hex: a1), encoding: .ascii) {
                                    let c = b.replacingOccurrences(of: "\0", with: "")
                                    let d = c.replacingOccurrences(of: "Cipfs://", with: "https://ipfs.io/ipfs/")
                                    for (index, item) in reqNFTs.enumerated() {
                                        if item.requestId == id {
                                            reqNFTs[index].imageUrl = d
                                            break
                                        }
                                    }
                                }
                            }}
                        subscriber.putNext(reqNFTs)
                    } else {
                        subscriber.putNext(reqNFTs)
                    }
                    subscriber.putCompletion()
                case .failure(_):
                    subscriber.putNext(reqNFTs)
                    subscriber.putCompletion()
                    break
                }
            }
            return EmptyDisposable
        }
    }
    
    public class func getTTNFTDetails(nfts: [TTNFT]) -> Signal<[TTNFT], NoError> {
        var signals = [Signal<TTNFT, NoError>]()
        for nft in nfts {
            signals.append(TBRPCNetwork.getTTNFTDetail(nft: nft))
        }
        return combineLatest(signals)
    }
    
    public class func getTTNFTDetail(nft: TTNFT) -> Signal<TTNFT, NoError> {
        var relNFT = nft
        return Signal { subscriber in
            AF.request(nft.imageUrl,
                       method: .get).response(responseSerializer: JSONResponseSerializer()) { response in
                switch response.result {
                case let .success(result):
                    if let r = result as? Dict, let detail = TTNFTDtail.deserialize(from: r) {
                        relNFT.detail = detail
                        subscriber.putNext(relNFT)
                    } else {
                        subscriber.putNext(relNFT)
                    }
                    subscriber.putCompletion()
                case .failure(_):
                    subscriber.putNext(relNFT)
                    subscriber.putCompletion()
                    break
                }
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




func tt_getBanlance(address: String, roundNum: NSInteger) -> Dict {
    return ["id" : roundNum,
        "jsonrpc" : "2.0",
        "method" : "eth_getBalance",
        "params":[address, "latest"]]
}

func tt_eth_call(address: String, to: String, roundNum: NSInteger) -> Dict {
    let methodCode = "0x70a08231000000000000000000000000"
    let data = methodCode + address.replacingOccurrences(of: "0x", with: "")
    var params = Array<Any>()
    params.append(["data" : data, "to" : to])
    params.append("latest")
    return ["id" : roundNum,
            "jsonrpc" : "2.0",
            "method" : "eth_call",
            "params" : params]
}

func tt_nft(address: String, roundNum: NSInteger) -> Dict {
    return ["id" : roundNum,
            "jsonrpc" : "2.0",
            "method" : "tokenManager.NftOf",
            "params" : [address]]
}

func tt_nftDetail(nft: TTNFT, roundNum: NSInteger) -> Dict {
    let methodCode = nft.ercType() == .erc721 ? "0xc87b56dd" : "0x0e89341c"
    let data = methodCode + nft.id.replacingOccurrences(of: "0x", with: "")
    var params = Array<Any>()
    params.append(["data" : data, "to" : nft.contractAddress])
    params.append("latest")
    return ["id" : roundNum,
            "jsonrpc" : "2.0",
            "method" : "eth_call",
            "params" : params]
}

func ttTokens() -> Array<TTToken> {
    if let path = getAppBundle().path(forResource: "TTTokens", ofType: "json") {
        let url = URL(fileURLWithPath: path)
        do {
            let data = try Data(contentsOf: url)
            let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers)
            if let arr = json as? Array<Dict> {
                var tokens = Array<TTToken>()
                for item in arr {
                    if let token = TTToken.deserialize(from: item) {
                        tokens.append(token)
                    }
                }
                return tokens
            }
        } catch {
            return []
        }
    }
    return []
}

struct TTToken: HandyJSON {
    
    var contractAddress: String = ""
    var name: String = ""
    var symbol: String = ""
    var decimals: Int = 0
    var image: String = ""
    var balance: String = "0"
    var balance_usd: String = "0"
    var price: String = "0"
    
    static func mainToken() -> TTToken {
        return TTToken(name: "thunder-token",
                       symbol: "TT",
                       decimals: 18,
                       image: "https://ttswap.space/static/media/tt.e15cb968.png")
    }
}

extension TTToken: TokenItem {
    func getIconUrl() -> String? {
        return self.image
    }
    
    func getTokenName() -> String {
        return self.symbol
    }
    
    func getTokenPrice() -> String {
        return "$" + self.price.decimal(digits: 8)
    }
    
    func getBalance() -> String {
        return self.balance.decimal(digits: 8)
    }
    
    func getTotalAssets() -> String {
        return self.balance_usd.decimal(digits: 8)
    }
}

struct TTTokenPrice: HandyJSON {
    var name: String = ""
    var symbol: String = ""
    var price: String = ""
    var priceDelta24H: String = ""
    var tokenAddress: String = ""
    var circulatingSupply: Int = 0
    var tradingVol24H: CGFloat = 0.0
    var totalValueLocked: CGFloat = 0.0
    var website: String = ""
    var blockExplorer: String = ""
}

struct TTNFT: HandyJSON {
    
    enum ERCType {
        case unknow
        case erc721
        case erc1155
    }
    
    var id: String = ""
    var contractAddress: String = ""
    var mintedTime: String = ""
    var transactionHash: String = ""
    var value: String = ""
    var totalIssue: String = ""
    var type: String = ""
    
    var requestId: NSInteger = 0
    var imageUrl: String = ""
    var detail: TTNFTDtail = TTNFTDtail()
    
    func ercType() -> ERCType {
        switch self.type {
        case "ERC1155":
            return .erc1155
        case "ERC721":
            return .erc721
        default:
            return .unknow
        }
    }
}

struct TTNFTDtail: HandyJSON {
    var name: String = ""
    var description: String = ""
    var image: String = ""
    var attributes: Array<Dict>?
    var external_url: String?
}

extension TTNFT: TBNFTItem {
    
    func nftContract() -> String {
        return self.contractAddress
    }
    
    func nftContractImage() -> String {
        return self.detail.image.replacingOccurrences(of: "ipfs://", with: "https://ipfs.io/ipfs/")
    }
    
    func nftTokenId() -> String {
        return self.id
    }
    
    func nftAssetName() -> String? {
        return self.detail.name
    }
    
    func nftChainId() -> String? {
        return "108"
    }
    
    func nftPrice() -> String? {
        return "0"
    }
    
    func nftTokenStandard() -> String? {
        return self.type
    }
    
    func getNFTName() -> String {
        return self.detail.description
    }
}
