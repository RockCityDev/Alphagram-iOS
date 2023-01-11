






import Foundation
import CryptoSwift

public let _notify_set_redpack_readed_ = "_notify_set_redpack_readed_"

let _k_helloMessage_ = "\n"
let _k_app_channle_ = "A"
public let _k_redpack_read_status_prefix_ = "_tb_redpack_read_status_prefix_"



private func checkIfHexString_ta(inStr: String) -> Bool{
    let pattern = "[0-9A-Fa-f]{1,}"
    let result = NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: inStr)
    return result
}


public func simpleCheckTransAsset(str:String) -> Bool {
    let helloMessage = _k_helloMessage_
    if let deRange = str.range(of: helloMessage) {
        return true
    }
    return false
}

public func isWalletMessage_ta (str:String ) -> Bool {
    
    if str.count < 20 {
        return false
    }
    
    let helloMessage = _k_helloMessage_
    if let deRange = str.range(of: helloMessage) {
        let leftString = str.suffix(from: deRange.upperBound)
        
        
        if checkIfHexString(inStr:String(leftString)) {
            let trueString = leftString
            let decodeString = decode_AES_ECB(strToDecode:String(trueString))
            
            if decodeString!.count > 1 {
                if decodeString!.hasPrefix("$RP$,A,") {
                    
                    
    
    
    
    
    
                    return true
                }
            }
        }
    }

    return false
}




public struct TBTransferAssetModel: Equatable {
    public var helloMessage: String?
    public var header: String? 
    public let appChannel: String? 
    public var fromTgId: String! 
    public var secretKey: String! 
    
    
    public init(fromTgId: String,secretKey:String) {
        self.helloMessage = _k_helloMessage_
        self.header = "$RP$"
        self.appChannel = _k_app_channle_
        self.fromTgId = fromTgId
        self.secretKey = secretKey
    }

}



public func tb_encode_message_transferAsset(modelToDecode:TBTransferAssetModel) -> String {
    let fullString = modelToDecode.header! + ","
    + modelToDecode.appChannel! + ","
    + modelToDecode.fromTgId! + ","
    + modelToDecode.secretKey! + ","
    
    
    let encryptedStr = encode_AES_ECB(toEncodeString: fullString)
    return (_k_helloMessage_ + encryptedStr)
}



public func tb_decode_message_transferAsset(strToDecode:String)->TBTransferAssetModel?{
    let helloMessage = _k_helloMessage_
    
    guard let deRange = strToDecode.range(of: helloMessage) else { return nil }
    
    let leftString = strToDecode.suffix(from: deRange.upperBound)
    let decodeString = decode_AES_ECB(strToDecode:String(leftString))
    let fullArr = decodeString?.components(separatedBy: ",")
    
    guard let fromTgId = fullArr?[2] else { return nil }
    guard let secretKey = fullArr?[3] else {return nil}
    
    let model = TBTransferAssetModel(fromTgId: fromTgId, secretKey: secretKey)
    
    return model
}

let readStatus = "100"

public func setRedPackReadStatus(secretKey:String,tgId:String) {
    
    let key = _k_redpack_read_status_prefix_ + tgId + "_" + secretKey
    UserDefaults.standard.set("100", forKey: key)
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0) {
        NotificationCenter.default.post(name: NSNotification.Name.init(rawValue: _notify_set_redpack_readed_),
                                        object: nil,
                                        userInfo: ["secretKey":secretKey])
    }
    
}



public func getRedPackReadStatus(secretKey:String,tgId:String) -> Bool {
    let key = _k_redpack_read_status_prefix_ + tgId + "_" + secretKey
    if let res = UserDefaults.standard.value(forKey: key) as? String ,res == readStatus{
            return true
    }
    return false
}
