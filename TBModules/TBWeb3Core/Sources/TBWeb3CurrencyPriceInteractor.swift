
import Foundation
import HandyJSON
import TBBusinessNetwork
import SwiftSignalKit

public class TBWeb3CurrencyPriceInteractor {
    public init(){}
    
    public func web3CurrencyPriceSignal_(coin_ids:[String]? = nil) ->Signal<TBWeb3CurrencyPriceEntry, TBNetError> {
        return TBWeb3Network().web3CurrencyPriceSignal(coin_ids: coin_ids) |> mapToSignal({ data in
            return  Signal { subscriber in
                if let info = TBWeb3CurrencyPriceEntry.deserialize(from: data) {
                    subscriber.putNext(info)
                    subscriber.putCompletion()
                }else{
                    subscriber.putError(TBNetError.normal(code: 0, message: ""))
                }
               return EmptyDisposable
            }
        })
    }

    public func web3CurrencyPriceSignal(coin_ids:[String]? = nil) ->Signal<TBWeb3CurrencyPriceEntry?, NoError> {
        return self.web3CurrencyPriceSignal_(coin_ids: coin_ids) |> map({ info in
            let aInfo:TBWeb3CurrencyPriceEntry? = info
            return aInfo
        }) |> `catch`({ _ in
            return Signal { subscriber in
                subscriber.putNext(nil)
                subscriber.putCompletion()
                return EmptyDisposable
            }
        })
    }
}
