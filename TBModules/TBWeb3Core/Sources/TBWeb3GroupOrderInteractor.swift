
import Foundation
import HandyJSON
import TBBusinessNetwork
import SwiftSignalKit
import TBLanguage

public class TBWeb3GroupOrderInteractor {
    
    public init(){}
    
    public func web3OrderPostSignal_(tx_hash: String, group_id: String, payment_account:String) ->Signal<TBWeb3GroupOrderEntry, TBNetError>  {
        return TBWeb3Network().web3OrderPostSignal(tx_hash: tx_hash, group_id: group_id, payment_account:payment_account) |> mapToSignal({ data in
            return  Signal { subscriber in
                if let info = TBWeb3GroupOrderEntry.deserialize(from: data) {
                    subscriber.putNext(info)
                    subscriber.putCompletion()
                }else{
                    subscriber.putError(TBNetError.normal(code: 0, message: ""))
                }
                return EmptyDisposable
            }
        })
    }
    
    
    public func web3OrderPostSignal(tx_hash: String, group_id: String, payment_account:String) ->Signal<TBWeb3GroupOrderEntry?, NoError>  {
        return self.web3OrderPostSignal_(tx_hash: tx_hash, group_id: group_id, payment_account:payment_account) |> map({ info in
            let aInfo:TBWeb3GroupOrderEntry? = info
            return aInfo
        }) |> `catch`({ _ in
            return Signal { subscriber in
                subscriber.putNext(nil)
                subscriber.putCompletion()
                return EmptyDisposable
            }
        })
    }
    
    public func web3OrderResultSignal_(tx_hash: String) ->Signal<TBWeb3GroupOrderEntry, TBNetError>  {
        return TBWeb3Network().web3OrderResultSignal(tx_hash: tx_hash) |> mapToSignal({ data in
            return  Signal { subscriber in
                if let info = TBWeb3GroupOrderEntry.deserialize(from: data) {
                    subscriber.putNext(info)
                    subscriber.putCompletion()
                }else{
                    subscriber.putError(TBNetError.normal(code: 0, message: ""))
                }
                return EmptyDisposable
            }
        })
    }
    
    public func web3OrderResultSignal(tx_hash: String) ->Signal<TBWeb3GroupOrderEntry?, NoError>  {
        return self.web3OrderResultSignal_(tx_hash: tx_hash) |> map({ info in
            let aInfo:TBWeb3GroupOrderEntry? = info
            return aInfo
        }) |> `catch`({ _ in
            return Signal { subscriber in
                subscriber.putNext(nil)
                subscriber.putCompletion()
                return EmptyDisposable
            }
        })
    }
    
    
    private func web3OrderResultRetrySignal_(tx_hash: String) ->Signal<TBWeb3GroupOrderEntry, TBNetError> {
        return self.web3OrderResultSignal_(tx_hash: tx_hash) |> mapToSignal({ orderEntry in
            return Signal { subscriber in
                if orderEntry.ship.url.isEmpty {
                    let message = TBLanguage.sharedInstance.localizable(TBLankey.uplink_verification_title)
                    subscriber.putError(.normal(code: -10000, message: message))
                }else{
                    subscriber.putNext(orderEntry)
                    subscriber.putCompletion()
                }
                return EmptyDisposable
            }
        })
    }
    

    public func cycleRequestOrderResultSignal(tx_hash:String) -> Signal<TBWeb3GroupOrderEntry, TBNetError> {
       return self.web3OrderResultRetrySignal_(tx_hash: tx_hash)
        |> retry(
            retryOnError: { error in
                switch error {
                case   .normal(code: let code, message: let message):
                    if code == -10000 {
                        return true
                    }else{
                        return false
                    }
                }
        },
            delayIncrement: 5,
            maxDelay: 5,
            maxRetries: 6,
            onQueue: .mainQueue())
    }
}
