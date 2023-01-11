
import TBStorage
import TBNetwork
import SwiftSignalKit


public enum TBLaunchNetworkError: String {
    case normal = ""
}

public class TBLaunchNetwork {
    public init() {
        
    }
    
    
    public func systemCheckSignal() -> Signal<[String : Any], TBNetError> {
        return Signal { subsciber in
            TBNetwork.request(api: Logging.systemCheck.rawValue, method: .post, successHandle: { (result, message) in
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

