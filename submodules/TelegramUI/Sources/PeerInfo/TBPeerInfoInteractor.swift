import Foundation
import HandyJSON
import TBNetwork
import SwiftSignalKit
import TBWeb3Core

public class TBPeerInfoInteractor {
    
    public class func fetchNetworkInfo(by tgUserId: String) -> Signal<NetworkInfo, TBNetError> {
        return Signal { subscriber in
            TBNetwork.request(api: TransferAsset.infoFromTGUser.rawValue,
                              paramsFillter: ["tg_user_id" : tgUserId],
                              successHandle: { data, message in
                if let dic = data as? Dictionary<String, Any>, let info = NetworkInfo.deserialize(from: dic) {
                    subscriber.putNext(info)
                } else {
                    subscriber.putError(TBNetError.normal(code: -999, message: "Invalid Data"))
                }
                subscriber.putCompletion()
            }, failHandle: { code, message in
                subscriber.putError(TBNetError.normal(code: code, message: message))
                subscriber.putCompletion()
            })
            return EmptyDisposable
        }
    }
}
