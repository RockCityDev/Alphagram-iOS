
import Foundation
import HandyJSON
import TBBusinessNetwork
import SwiftSignalKit


public class TBWeb3GroupListInteractor {
    public init(){}
    
    
    public func web3GroupListSignal_(tag_id:String = "", hot_tag_id:String = "", chain_id:String = "", page: Int) ->Signal<TBWeb3GroupListEntry, TBNetError> {
        return TBWeb3Network().web3GroupListSignal(tag_id: tag_id, hot_tag_id: hot_tag_id, chain_id: chain_id, page: page) |> mapToSignal({ data in
            return  Signal { subscriber in
                if let info = TBWeb3GroupListEntry.deserialize(from: data) {
                    subscriber.putNext(info)
                    subscriber.putCompletion()
                }else{
                    subscriber.putError(TBNetError.normal(code: 0, message: ""))
                }
               return EmptyDisposable
            }
        })
    }
    
    
    public func web3GroupListSignal(tag_id:String = "", hot_tag_id:String = "", chain_id:String = "", page: Int) ->Signal<TBWeb3GroupListEntry?, NoError> {
        return self.web3GroupListSignal_(tag_id: tag_id, hot_tag_id: hot_tag_id, chain_id: chain_id, page: page) |> map({ info in
            let aInfo:TBWeb3GroupListEntry? = info
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
