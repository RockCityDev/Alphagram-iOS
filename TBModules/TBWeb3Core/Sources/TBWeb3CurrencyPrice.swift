
import Foundation
import HandyJSON
import TBNetwork
import SwiftSignalKit
import Alamofire

typealias Dict = Dictionary<String, Any>

public class TBWeb3CurrencyPrice {
    
    public struct Currency {
        public struct Price: HandyJSON {
            
            public var usd: String = ""
            public var usd_24h_change: String = ""
            
            public init() {}
        }
        
        public let  currencyId: String
        public let  price: Price
    }
    
    public static let shared = TBWeb3CurrencyPrice()
    
    private let timer: DispatchSourceTimer
    
    public let currencyPricePromise: Promise<[Currency]>
    
    public init() {
        self.currencyPricePromise = Promise()
        self.timer = DispatchSource.makeTimerSource(queue: .global())
        self.timer.schedule(deadline: .now(), repeating: .seconds(60))
        self.timer.setEventHandler(handler: {
            self.fetchCurrencyPrice()
        })
        self.timer.resume()
    }
    
    func fetchCurrencyPrice() {
        TBNetwork.request(api: TransferAsset.currencyPrice.rawValue,
                          successHandle: {[weak self] data, message in
            if let result = data as? [String : Dict] {
                var prices = [Currency]()
                for key in result.keys {
                    if let price = Currency.Price.deserialize(from: result[key]) {
                        prices.append(Currency(currencyId: key, price: price))
                    }
                }
                self?.currencyPricePromise.set(.single(prices))
            }
        }, failHandle: { code, message in
            
        })
     }
}

public func getPriceFor(type: TBChainType, in currencyPrices: [TBWeb3CurrencyPrice.Currency]) -> TBWeb3CurrencyPrice.Currency.Price? {
    switch type {
    case .unkonw:
        return nil
    case .ETH:
        return currencyPrices.filter({$0.currencyId == "ethereum"}).first?.price
    case .TT:
        return currencyPrices.filter({$0.currencyId == "thunder-token"}).first?.price
    case .OS:
        return currencyPrices.filter({$0.currencyId == "oasis-network"}).first?.price
    case .Polygon:
        return currencyPrices.filter({$0.currencyId == "matic-network"}).first?.price
    }
}
