
import Foundation
import SwiftSignalKit
import HandyJSON
import TBBusinessNetwork


class TBCycleRequestPhoneCode {
    private let totalCount = 10
    var completion:((TBPhoneCode?, Bool)->Void)?
    private var currentTryCount = 0
    private let phone: String
    init(phone:String) {
        self.phone = phone
    }
    
    
    func stopCycle(){
        self.completion = nil
    }
    
    
    func startCycle() {
        guard let com = self.completion else {
            return
        }
        self.getPhoneCode { phoneCode, finished in
            if finished {
                com(phoneCode, finished)
            }else{
                if self.currentTryCount > self.totalCount{
                    com(nil, false)
                    return
                }
                self.currentTryCount += 1
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5) {
                    self.startCycle()
                }
            }
        }
    }
    
    
    
    private func getPhoneCode(completion:@escaping (TBPhoneCode?, Bool)->Void) {
        let _ = self.phoneCode().start { p in
            completion(p, true)
        } error: { _ in
            completion(nil, false)
        } completed: {}
    }
    
    
    
    func phoneCode() -> Signal<TBPhoneCode, TBNetError> {
        if TBAccount.shared.systemCheckData.testerphones.contains(self.phone) == false {
            return Signal { subsciber in
                subsciber.putError(TBNetError.normal(code: 0, message: ""))
                return EmptyDisposable
            }
        }else{
            return TBLoginNetwork().getPhoneCodeSignal(phone: self.phone) |> mapToSignal({ data -> Signal<TBPhoneCode, TBNetError> in
                return Signal{ subscriber in
                    if let obj = TBPhoneCode.deserialize(from: data), obj.code.count > 0 {
                        subscriber.putNext(obj)
                        subscriber.putCompletion()
                    }else{
                        subscriber.putError(TBNetError.normal(code: 0, message: ""))
                    }
                    return EmptyDisposable
                }
            })
        }
    }
}
