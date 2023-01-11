






import Foundation
import CryptoSwift


public func checkIfHexString(inStr: String) -> Bool{
    let pattern = "[0-9A-Fa-f]{1,}"
    let result = NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: inStr)
    return result
}


public func isWalletMessage (str:String ) -> Bool {
    
    if str.count < 20 {
        return false
    }
    
    if checkIfHexString(inStr:str) {
        let trueString = str
        let decodeString = decode_AES_ECB(strToDecode:trueString)
        
        if decodeString!.count > 1 {
            if decodeString!.hasPrefix("$$") {
                
                





                return true
            }
        }
    }
    
    
    if isWalletMessage_ta(str: str) {
        return true
    }
    

    return false
}

















public struct TBRedPackModel: Equatable {
    public var header: String? 
    public var fromTgId: String? 
    public var toTgId: String? 
    public var symbol: String? 
    public var transHash:String? 
    public var fromAddress:String? 
    public var toAddress:String? 
    public var count:String? 
    public var gassFee:String? 
    public var total:String? 
    public var price:String? 
    public var chainId:String? 
    
    public init(header: String? = nil, fromTgId: String? = nil, toTgId: String? = nil, symbol: String? = nil, transHash: String? = nil, fromAddress: String? = nil, toAddress: String? = nil, count: String? = nil, gassFee: String? = nil, total: String? = nil, price: String? = nil, chainId: String? = nil) {
        self.header = header
        self.fromTgId = fromTgId
        self.toTgId = toTgId
        self.symbol = symbol
        self.transHash = transHash
        self.fromAddress = fromAddress
        self.toAddress = toAddress
        self.count = count
        self.gassFee = gassFee
        self.total = total
        self.price = price
        self.chainId = chainId
    }
}



public func tb_encode_redPack_message(modelToDecode:TBRedPackModel) -> String {
    let fullString = modelToDecode.header!+","
    + modelToDecode.fromTgId!+","
    + modelToDecode.toTgId! + ","
    + modelToDecode.symbol!+","
    + modelToDecode.transHash!+","
    + modelToDecode.fromAddress!+","
    + modelToDecode.toAddress!+","
    + modelToDecode.count!+","
    + modelToDecode.gassFee!+","
    + modelToDecode.total!+","
    + modelToDecode.price!+","
    + modelToDecode.chainId!
    
    
    let encryptedStr = encode_AES_ECB(toEncodeString: fullString)
    
    return encryptedStr
}



public func tb_decode_redPack_message(strToDecode:String)->TBRedPackModel!{
    let decodeString = decode_AES_ECB(strToDecode:strToDecode)
    let fullArr = decodeString?.components(separatedBy: ",")
    
    let model = TBRedPackModel(header: fullArr?[0], fromTgId: fullArr?[1], toTgId: fullArr?[2], symbol: fullArr?[3], transHash: fullArr?[4], fromAddress: fullArr?[5], toAddress: fullArr?[6], count: fullArr?[7], gassFee: fullArr?[8], total: fullArr?[9], price: fullArr?[10], chainId: fullArr?[11])
    
    return model
}



public func encode_AES_ECB(toEncodeString:String) -> String {

    


    let encryptedByte :[UInt8] = Array(toEncodeString.utf8)
    let keyByte: [UInt8] = Array("".utf8)
    let ivByte: [UInt8] = Array("".utf8)


    
    var str = ""
    do {
        let encrypted = try AES(key: keyByte, blockMode: CBC(iv: ivByte), padding: .pkcs5).encrypt(encryptedByte)
//        str  = String(bytes: encrypted, encoding: .utf8) ?? ""
        let bytes = encrypted
        var hexStr = ""
        for idx in 0..<encrypted.count {
            let newHex = String(format: "%x", bytes[idx]&0xff)
            if newHex.count == 1 {
                hexStr = String(format: "%@0%@", hexStr,newHex)
            }else{
                hexStr = hexStr + newHex
            }
        }
        str = hexStr
    } catch {
        print("err = \(error)")
    }
    return str
}



public func decode_AES_ECB(strToDecode:String)->String! {

    

    let encrypted: [UInt8] = strToDecode.tb_hexaToBytes
    let keyByte: [UInt8] = Array("".utf8)
    let ivByte: [UInt8] = Array("".utf8)


    
    var str = ""
    do {
        let decrypted = try AES(key: keyByte, blockMode: CBC(iv: ivByte), padding: .pkcs5).decrypt(encrypted)
        str  = String(bytes: decrypted, encoding: .utf8) ?? ""
    } catch {
        print("err = \(error)")
    }
    return str
}
