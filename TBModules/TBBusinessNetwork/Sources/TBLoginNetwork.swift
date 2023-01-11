






import TBStorage
import TBNetwork
import SwiftSignalKit
import Foundation

public class TBLoginNetwork {
    
    public init(){}
    
    public func loginSignal(tg_user_id:Int64, is_tg_new:Bool = false) -> Signal<[String : Any], TBNetError>{
        let params = ["tg_user_id" : String(tg_user_id),
                       "is_tg_new" : (is_tg_new ? "1" : "0")]
        return Signal { subsciber in
            TBNetwork.request(api: Logging.passportLogin.rawValue, method: .post, paramsFillter: params, successHandle: { (result, message) in
                if let data = result as? Dictionary<String, Any> {
                    subsciber.putNext(data)
                    subsciber.putCompletion()
                }else{
                    subsciber.putError(.normal(code: 0, message: ""))
                }
            }, failHandle: { (code, message) in
                subsciber.putError(.normal(code: code, message: message))
            })
            return EmptyDisposable
        }
    }
    
    public func getPhoneCodeSignal(phone: String) -> Signal<[String : Any], TBNetError>{
        
        return Signal { subsciber in
            TBNetwork.request(api: Logging.systemGetCode.rawValue, method: .post, paramsFillter: ["phone":phone], headersFillter: nil, successHandle: { (result, message) in
                if let data = result as? Dictionary<String, Any> {
                    subsciber.putNext(data)
                    subsciber.putCompletion()
                }else{
                    subsciber.putError(.normal(code: 0, message: ""))
                }
            }, failHandle: { (code, message) in
                subsciber.putError(.normal(code: code, message: message))
            })
            return EmptyDisposable
        }
    }
    
    
    

}
