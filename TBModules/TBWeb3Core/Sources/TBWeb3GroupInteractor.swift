
import Foundation
import HandyJSON
import TBBusinessNetwork
import SwiftSignalKit


public class TBWeb3GroupInteractor {
    public init(){}
    
    private func web3HotTagsSignal_() -> Signal<[TBWeb3GroupInfoEntry.Tag], TBNetError> {
        return TBWeb3Network().web3HotTagsSignal() |> mapToSignal({ data in
            return Signal { subscriber in
                if let array = [TBWeb3GroupInfoEntry.Tag].deserialize(from: data) {
                    let ret = array.compactMap {$0}
                    subscriber.putNext(ret)
                    subscriber.putCompletion()
                }else{
                    subscriber.putError(TBNetError.normal(code: 0, message: ""))
                }
                return EmptyDisposable
            }
        })
    }
    
    public func web3HotTagsSignal() -> Signal<[TBWeb3GroupInfoEntry.Tag], NoError> {
        return self.web3HotTagsSignal_() |> `catch`({ error in
            return Signal { subscriber in
                subscriber.putNext([TBWeb3GroupInfoEntry.Tag]())
                subscriber.putCompletion()
                return EmptyDisposable
            }
        })
    }
    
    private func web3UpdateGroupSignal_(requestInfo:TBWeb3Network.UpdateGroupEntry, isCreat:Bool = true) ->Signal<[String:Any], TBNetError> {
        return TBWeb3Network().web3UpdateGroupSignal(requestInfo: requestInfo, isCreat: isCreat)
    }
    
    private func web3UploadImage_(data: Data) -> Signal<String, NoError> {
        return TBWeb3Network().web3UploadImage(data: data) |> `catch`({ error in
            return Signal {subscriber in
                subscriber.putNext("")
                subscriber.putCompletion()
                return EmptyDisposable
            }
        })
    }
    
    public func web3UpdateGroupSignal(requestInfo:TBWeb3Network.UpdateGroupEntry, isCreat:Bool = true) ->Signal<[String:Any], NoError> {
        
        if let  avatarData =  requestInfo.avatarData {
            return self.web3UploadImage_(data: avatarData) |> mapToSignal({ urlStr in
                var requestInfo = requestInfo
                requestInfo.avatar = urlStr
                return self.web3UpdateGroupSignal_(requestInfo: requestInfo, isCreat: isCreat) |> `catch`({ error in
                    return Signal {subscriber in
                        subscriber.putNext([String:Any]())
                        subscriber.putCompletion()
                        return EmptyDisposable
                    }
                })
            })
        }else{
            return self.web3UpdateGroupSignal_(requestInfo: requestInfo, isCreat: isCreat) |> `catch`({ error in
                return Signal {subscriber in
                    subscriber.putNext([String:Any]())
                    subscriber.putCompletion()
                    return EmptyDisposable
                }
            })
        }
    }
    
    
    public func web3GroupInfoSignal_(group_id:String) ->Signal<TBWeb3GroupInfoEntry, TBNetError> {
        return TBWeb3Network().web3GroupInfoSignal(group_id: group_id) |> mapToSignal({ data in

            return  Signal { subscriber in
                if let info = TBWeb3GroupInfoEntry.deserialize(from: data) {
                    subscriber.putNext(info)
                    subscriber.putCompletion()
                }else{
                    subscriber.putError(TBNetError.normal(code: 0, message: ""))
                }
               return EmptyDisposable
            }
        })
    }
    
    public func web3GroupInfoSignal(group_id:String) ->Signal<TBWeb3GroupInfoEntry?, NoError> {
        return self.web3GroupInfoSignal_(group_id: group_id) |> map({ info in
            let aInfo:TBWeb3GroupInfoEntry? = info
            return aInfo
        }) |> `catch`({ _ in
            return Signal { subscriber in
                subscriber.putNext(nil)
                subscriber.putCompletion()
                return EmptyDisposable
            }
        })
    }
    
    public func web3GroupInfoByChatIdSignal_(chat_id:String) ->Signal<TBWeb3GroupInfoEntry, TBNetError> {
        return TBWeb3Network().web3GroupInfoByChatIdSignal(chat_id: chat_id) |> mapToSignal({ data in
            return  Signal { subscriber in
                if let info = TBWeb3GroupInfoEntry.deserialize(from: data) {
                    subscriber.putNext(info)
                    subscriber.putCompletion()
                }else{
                    subscriber.putError(TBNetError.normal(code: 0, message: ""))
                }
               return EmptyDisposable
            }
        })
    }
    
    public func web3GroupInfoByChatIdSignal(chat_id:String) ->Signal<TBWeb3GroupInfoEntry?, NoError> {
        return self.web3GroupInfoByChatIdSignal_(chat_id: chat_id) |> map({ info in
            let aInfo:TBWeb3GroupInfoEntry? = info
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
