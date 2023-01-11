import Foundation
import HandyJSON
import TBNetwork
import SwiftSignalKit
import Alamofire
import TBAccount
import AppBundle

public struct CurrencyBalance: Equatable {
    
    public var id: Int = 0
    public var name: String = ""
    public var icon: String = ""
    public var symbol: String = ""
    public var balance: String = ""
    public var unitPrice: String = ""
    public var balanceUsd: String = ""
    public var decimals: Int = 0
    public var address: String?
    public var network: String = ""
    
    public static func == (lhs: CurrencyBalance, rhs: CurrencyBalance) -> Bool {
        return lhs.symbol == rhs.symbol && lhs.name == rhs.name && lhs.network == rhs.network
    }
}

public struct NetworkBalance: Equatable {
    
    public var id: Int = 0
    public var name: String = ""
    public var icon: String = ""
    public var currencyBalances = [CurrencyBalance]()
    public var balanceUsd: String = ""
    
    public static let emptyBalance = NetworkBalance()
    
    public static func == (lhs: NetworkBalance, rhs: NetworkBalance) -> Bool {
        return lhs.name == rhs.name && lhs.id == rhs.id
    }
    
    public func isEmpty() -> Bool {
        return self.id == 0 && self.name.isEmpty
    }
}


public enum ZapperNetworkType {
    case Eth
    case Polygon
}

public class Web3NetworkBalanceApi {
    
    
    public class func fetchEthOrPolygonBalance(type: ZapperNetworkType, address: String) -> Signal<NetworkBalance, NoError> {
        let appid = TBAccount.shared.systemCheckData.zapper
        return combineLatest(TBWeb3Config.shared.configSignal,
                             ZapperBalance.getAppsBalances(appId: appid, type: type, addresses: [address]))
        |> mapToSignal({ a -> Signal<NetworkBalance, NoError> in
            return Signal { subscriber in
                let id = type == .Eth ? 1 : 137
                if let config = a.0, let chain = config.chainType.filter({$0.id == id}).first {
                    var network = NetworkBalance()
                    network.id = chain.id
                    network.name = chain.name
                    network.icon = chain.icon
                    var balanceUsdNum = NSDecimalNumber(string: "0")
                    for item in a.1 {
                        var currencyBalance = item.transformToCurrencyBalance()
                        if let currency = chain.currency.filter({$0.name == item.getRelSymbol()}).first {
                            currencyBalance.id = currency.id
                        }
                        network.currencyBalances.append(currencyBalance)
                        balanceUsdNum = balanceUsdNum.adding(NSDecimalNumber(string: item.balanceUSD.decimalString()))
                    }
                    network.balanceUsd = balanceUsdNum.description
                    subscriber.putNext(network)
                } else {
                    subscriber.putNext(NetworkBalance.emptyBalance)
                }
                return EmptyDisposable
            }
        })
    }
    
    
    public class func fetchTTBalance(address: String) -> Signal<NetworkBalance, NoError> {
        return (combineLatest(TBRPCNetwork.getAppsBalances(address: address),
                              TBWeb3CurrencyPrice.shared.currencyPricePromise.get(),
                              TBRPCNetwork.getTokensPrice()))
        |> take(1)
        |> mapToSignal({ (tokens, mPrices, tPrices) -> Signal<NetworkBalance, NoError> in
            return Signal { subscriber in
                let mainP = mPrices.filter({$0.currencyId == "thunder-token"}).first?.price.usd ?? "0"
                var relTokens = tokens
                var balanceUsd = NSDecimalNumber(string: "0")
                for (index, token) in relTokens.enumerated() {
                    var balance_usd = NSDecimalNumber(string: "0")
                    var price = "0"
                    if token.symbol == "TT" {
                        price = mainP
                    }
                    if let p = tPrices.filter({$0.symbol == token.symbol}).first?.price {
                        price = p
                    }
                    balance_usd = NSDecimalNumber(string: token.balance.decimalString()).multiplying(by: NSDecimalNumber(string: price.decimalString()))
                    balanceUsd = balanceUsd.adding(balance_usd)
                    relTokens[index].price = price
                    relTokens[index].balance_usd = balance_usd.decimalValue.description
                }
                var network = NetworkBalance()
                network.id = 108
                network.name = "ThunderCore"
                network.icon = "https://d3l1ioscvnrz88.cloudfront.net/system/web3/chain/chain_logo_thundercore.png"
                network.currencyBalances = relTokens.map({$0.transformToCurrencyBalance()})
                network.balanceUsd = balanceUsd.description
                subscriber.putNext(network)
                return EmptyDisposable
            }
        })
    }
    
    public class func fetchOasisBalance(address: String) -> Signal<NetworkBalance, NoError> {
        return combineLatest(TBOSNetwork.getAppsTokens(address: address),
                              TBOSNetwork.getAppsBalances(address: address),
                      TBOSNetwork.getTokensPrices()) |> mapToSignal({ (tokens, balance, priceDic) -> Signal<NetworkBalance, NoError> in
            return Signal { subscriber in
                var relTokens = tokens.filter({ !$0.isNFT()})
                if let b = balance {
                    var rose = TBOSNetwork.TBOSToken()
                    rose.balance = b
                    rose.decimals = 18
                    rose.name = "oasis-network"
                    rose.symbol = "ROSE"
                    relTokens.insert(rose, at: 0)
                }
                for (index, token) in relTokens.enumerated() {
                    relTokens[index].price = priceDic[token.symbol] ?? "0"
                }
                var network = NetworkBalance()
                network.id = 42262
                network.name = "Oasis"
                network.icon = "https://d3l1ioscvnrz88.cloudfront.net/system/web3/currency/coin_logo_oasis.png"
                network.currencyBalances = relTokens.map({$0.transformToCurrencyBalance()})
                network.balanceUsd = network.currencyBalances.reduce("0", { partialResult, balance in
                    return NSDecimalNumber(string: partialResult.decimalString()).adding(NSDecimalNumber(string: balance.balanceUsd.decimalString())).description
                })
                subscriber.putNext(network)
                return EmptyDisposable
            }
        })
    }
}


class TBRPCNetwork {
    
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
    
    class func getAppsBalances(address: String) -> Signal<Array<TTToken>, NoError> {
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
    
    class func getTokensPrice()  -> Signal<Array<TTTokenPrice>, NoError> {
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
}


class ZapperBalance {

    struct Zapper: Encodable {
        let network: String
        let addresses: [String]
    }

    
    struct TokenModel: HandyJSON {
        
        struct Product: HandyJSON {
            struct Assets: HandyJSON, Equatable {
                
                struct DisplayProp: HandyJSON {
                    public var label: String = ""
                    public var images: [String]?
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
                
                static func == (lhs: Assets, rhs: Assets) -> Bool {
                    return lhs.symbol == rhs.symbol
                }
            }
            var label: String = ""
            var assets = [Assets]()
        }

        struct Meta: HandyJSON {
            var label: String?
            var value: CGFloat = 0.0
            var type: String?
        }
        
        var products = [Product]()
        var meta = [Meta]()
    }
    
    class func getAppsBalances(appId: String, type: ZapperNetworkType, addresses: [String]) -> Signal<[TokenModel.Product.Assets], NoError>  {
        let url = "https://api.zapper.fi/v2/apps/tokens/balances"
        let network = type == .Eth ? "ethereum" : "polygon"
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
                        var assets = [TokenModel.Product.Assets]()
                        if let tokenModels = JSONDeserializer<TokenModel>.deserializeModelArrayFrom(array: tokens) as? [TokenModel] {
                            assets = tokenModels.flatMap{ $0.products.flatMap{ $0.assets} }
                        }
                        subscriber.putNext(assets)
                    } else {
                        subscriber.putNext([])
                    }
                case .failure(_):
                    subscriber.putNext([])
                }
                subscriber.putCompletion()
            }
            return EmptyDisposable
        }
    }
}



extension TBOSNetwork.TBOSToken {
    
    func transformToCurrencyBalance() -> CurrencyBalance {
        var balance = CurrencyBalance()
        balance.name = self.name
        balance.icon = self.iconName() ?? ""
        balance.symbol = self.symbol
        balance.balance = self.displayBalance()
        balance.balanceUsd = self.balanceUsd()
        balance.unitPrice = self.price
        balance.decimals = self.decimals
        balance.address = self.contractAddress
        balance.network = "Oasis"
        return balance
    }
    
}


class TBOSNetwork {
    
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
        
        func displayBalance() -> String {
            return NSDecimalNumber(string: self.balance.decimalString()).dividing(by: NSDecimalNumber(decimal: Decimal(pow(10, Double(self.decimals))))).description
        }
        
        func balanceUsd() -> String {
            let balance = NSDecimalNumber(string: self.balance.decimalString()).dividing(by: NSDecimalNumber(decimal: Decimal(pow(10, Double(self.decimals)))))
            return balance.multiplying(by: NSDecimalNumber(string: self.price.decimalString())).description
        }
    }
    
    class func getAppsBalances(address: String) -> Signal<String?, NoError> {
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
    
    class func getAppsTokens(address: String) -> Signal<Array<TBOSToken>, NoError> {
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
    
    class func getTokensPrices() -> Signal<[String : String], NoError> {
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
}





extension TBRPCNetwork.TTToken {
    
    func transformToCurrencyBalance() -> CurrencyBalance {
        var balance = CurrencyBalance()
        balance.name = self.name
        balance.icon = self.image
        balance.symbol = self.symbol
        balance.balance = self.balance
        balance.balanceUsd = self.balance_usd
        balance.unitPrice = self.price
        balance.decimals = self.decimals
        balance.address = self.contractAddress
        balance.network = "ThunderCore"
        return balance
    }
}

func ttTokens() -> Array<TBRPCNetwork.TTToken> {
    if let path = getAppBundle().path(forResource: "TTTokens", ofType: "json") {
        let url = URL(fileURLWithPath: path)
        do {
            let data = try Data(contentsOf: url)
            let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers)
            if let arr = json as? Array<Dict> {
                var tokens = Array<TBRPCNetwork.TTToken>()
                for item in arr {
                    if let token = TBRPCNetwork.TTToken.deserialize(from: item) {
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


extension ZapperBalance.TokenModel.Product.Assets {
    
    func getRelSymbol() -> String {
        return self.displayProps?.label ?? self.symbol
    }
    
    func transformToCurrencyBalance() -> CurrencyBalance {
        var balance = CurrencyBalance()
        balance.name = self.getRelSymbol()
        balance.icon = self.displayProps?.images?.first ?? ""
        balance.symbol = self.symbol
        balance.balance = self.balance
        balance.balanceUsd = self.balanceUSD
        balance.unitPrice = self.price
        balance.decimals = self.decimals
        balance.address = self.address
        balance.network = self.network
        return balance
    }
}


extension String {
    
    func decimalString() -> String {
        return self.isEmpty ? "0" : self
    }
    
    func transform16To10() -> String {
        if self == "0x" {
            return "0"
        }
        var fStr:String
        if self.hasPrefix("0x") {
            let start = self.index(self.startIndex, offsetBy: 2);
            let str1 = String(self[start...])
            fStr = str1.uppercased()
        }else{
            fStr = self.uppercased()
        }
        var sum: Double = 0
        for i in fStr.utf8 {
            sum = sum * Double(16) + Double(i) - 48
            if i >= 65 {
                sum -= 7
            }
        }
        return String(sum)
    }
}

extension NSDecimalNumber {
    
    func tb_decimal(digits: Int) -> String {
        let format = NumberFormatter()
        format.maximumFractionDigits = digits
        return format.string(from: self) ?? ""
    }
    
}

func base64Encoding(str: String) -> String {
    if let strData = str.data(using: String.Encoding.utf8) {
        return strData.base64EncodedString()
    }
    return ""
}

