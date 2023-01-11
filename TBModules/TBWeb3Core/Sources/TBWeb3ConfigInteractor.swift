
import Foundation
import HandyJSON
import TBBusinessNetwork
import SwiftSignalKit


public class TBWeb3ConfigInteractor {
    public init(){}
    public func web3ConfigSignal_() -> Signal<TBWeb3ConfigEntry, TBNetError> {
      return TBWeb3Network().web3ConfigSignal() |> mapToSignal({ data in
            return Signal { subscriber in
                if let obj = TBWeb3ConfigEntry.deserialize(from: data) {
                    subscriber.putNext(obj)
                    subscriber.putCompletion()
                }else{
                    subscriber.putError(TBNetError.normal(code: 0, message: ""))
                }
                return EmptyDisposable
            }
        })
    }
    
    public func web3ConfigSignal() -> Signal<TBWeb3ConfigEntry?, NoError> {
        
        return self.web3ConfigSignal_() |> map({ config in
            let aConfig:TBWeb3ConfigEntry? = config
            return aConfig
        }) |> `catch`({ _ in
            return Signal { subscriber in
                subscriber.putNext(nil)
                subscriber.putCompletion()
                return EmptyDisposable
            }
        })
    }
}

