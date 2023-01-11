
import Alamofire
import Foundation
import CommonCrypto
import UIKit
import CryptoKit

let isTB: Bool = false

public enum TBNetError {
    case normal(code:Int, message:String?)
}

class TBEnvironment {
    
    enum Environment {
        case develop
        case test
        case release
    }
    
    static let shared = TBEnvironment()
    
    var currentEnv: Environment
    
    init() {
        #if DEBUG
        self.currentEnv = .develop
        #else
        self.currentEnv = .release
        #endif
    }
    
    func fullUrl(_ apiPath: String) -> String {
        switch self.currentEnv {
        case .develop:
            if isTB {
                return ""
            }
            return ""
        case .test:
            return ""
        case .release:
            return ""
        }
    }
}



public class TBNetwork {
    
    public class func uploadImage(api: String,
                                  method: HTTPMethod = .post,
                                  paramsFillter:[String : String]? = nil,
                                  data: Data,
                                  successHandle: ((_ data: Any?, _ message: String?) -> ())? = nil,
                                  failHandle:((_ code: NSInteger, _ message: String) -> ())? = nil) {

        var requiredHeaders = HTTPHeaders()
        if let token = getTokenFromStorage() {
            requiredHeaders.add(name: "Authorization", value: "Bearer \(token)")
        }
        
        var requiredParams: [String : String] = requiredParams()
        if let fillter = paramsFillter {
            for (key, value) in fillter {
                requiredParams[key] = value
            }
        }
        
        let urlString = TBEnvironment.shared.fullUrl(api)
        
        AF.upload(
            multipartFormData: { formData in
                formData.append(data, withName: "file", fileName: "avatar", mimeType: "image/jpeg")
                for (key, value) in requiredParams {
                    if let data = value.data(using: .utf8) {
                        formData.append(data, withName: key)
                    }
                }
            },
            to: urlString,
            usingThreshold: UInt64.max,
            method: method,
            headers: requiredHeaders)
        .response(
            responseSerializer: JSONResponseSerializer()) { response in
                switch response.result {
                case .success(let bin):
                    guard let rel = bin as? Dictionary<String, Any> else {
                        if let handle = failHandle {
                            handle(-9999, "")
                        }
                        return
                    }
                    let code = (rel["code"] as? NSInteger) ?? -9999
                    let message = rel["message"] as? String
                    if code == 200 {
                        if let handle = successHandle  {
                            handle(rel["data"], message)
                        }
                    } else {
                        if let handle = failHandle {
                            handle(code, message ?? "")
                        }
                    }
                case .failure(let error):
                    if let handle = failHandle {
                        handle(error.responseCode ?? -9999, error.errorDescription ?? "")
                    }
                }
            }
    }
    
    public class func request(api: String,
                              method: HTTPMethod = .post,
                              paramsFillter: [String : Any]? = nil,
                              headersFillter: HTTPHeaders? = nil,
                              successHandle: @escaping ((_ data: Any?, _ message: String?) -> ()),
                              failHandle: @escaping ((_ code: NSInteger, _ message: String) -> ())) {
        var requiredHeaders = headersFillter ?? HTTPHeaders()
        if let token = getTokenFromStorage() {
            requiredHeaders.add(name: "Authorization", value: "Bearer \(token)")
        }
        var requiredParams: [String : Any] = requiredParams()
        if let fillter = paramsFillter {
            for (key, value) in fillter {
                requiredParams[key] = value
            }
        }
        debugPrint("[TB]requiredParams \(requiredParams)")
        debugPrint("[TB]url \(TBEnvironment.shared.fullUrl(api))")
        AF.request(TBEnvironment.shared.fullUrl(api),
                   method: method,
                   parameters: requiredParams,
                   encoding: JSONEncoding.default,
                   headers: requiredHeaders).response(responseSerializer: StringResponseSerializer()) { response in
            switch response.result {
            case .success(let bin):

                func resultCallBack(result: Dictionary<String, Any>) {
                    let code = (result["code"] as? NSInteger) ?? -9999
                    let message = result["message"] as? String
                    if code == 200 {
                        successHandle(result["data"], message)
                    } else {
                        failHandle(code, message ?? "")
                    }
                }
                let jsonData = bin.data(using: String.Encoding.utf8)
                if let a = jsonData, let b = try? JSONSerialization.jsonObject(with: a, options: .mutableContainers) as? Dictionary<String, Any> {
                    resultCallBack(result: b)
                    return
                }
                let stringData = aesDecrypt(key: "", iv: "", dataStr: bin)
                if let a = stringData, let b = try? JSONSerialization.jsonObject(with: a, options: .mutableContainers) as? Dictionary<String, Any> {
                    resultCallBack(result: b)
                    return
                }
            case .failure(let error):
                failHandle(error.responseCode ?? -9999, error.errorDescription ?? "")
            }
        }
    }
    
}


private let kToken = "TBBlock_token"
public func getTokenFromStorage() -> String? {
    return UserDefaults.standard.string(forKey: kToken)
}

public func storageToken(_ token: String) {
    UserDefaults.standard.set(token, forKey: kToken)
}


private func currentTimeStr() -> String {
    let format = DateFormatter()
    format.dateFormat = "yyyy-MM-dd HH:mm:ss"
    return format.string(from:Date(timeIntervalSinceNow: 0))
}


private func requiredParams() -> [String : String] {
    if isTB {
        let wg_key = ""
        let wg_time = currentTimeStr()
        let wg_name = ""
        let sign_str = ""
        var requiredParams = 
        if let uuid = UIDevice.current.identifierForVendor?.uuidString {
            requiredParams["device"] = uuid
        }
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            requiredParams["version"] = version
        }
        if let token = getTokenFromStorage() {
            requiredParams["token"] = token
        }
        requiredParams["channel"] = "official"
        requiredParams["platform"] = "1"
        requiredParams["region"] = "1"
        return requiredParams
    } else {
        let wg_key = ""
        let wg_time = currentTimeStr()
        let wg_name = "alphagram"
        let sign_str = ""
        var requiredParams = 
        if let uuid = UIDevice.current.identifierForVendor?.uuidString {
            requiredParams["device"] = uuid
        }
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            requiredParams["version"] = version
        }
        if let token = getTokenFromStorage() {
            requiredParams["token"] = token
        }
        requiredParams["channel"] = "official"
        requiredParams["platform"] = "1"
        requiredParams["region"] = "1"
        return requiredParams
    }
}


extension String {
    
    enum MD5EncryptType {
        
        case lowercase32
        
        case uppercase32
    }
    
    
    func DDMD5Encrypt(_ md5Type: MD5EncryptType = .lowercase32) -> String {
        guard self.count > 0 else { return "" }
        
        let cCharArray = self.cString(using: .utf8)
        
        var uint8Array = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        
        CC_MD5(cCharArray, CC_LONG(cCharArray!.count - 1), &uint8Array)
        switch md5Type {
            
        case .lowercase32:
            return uint8Array.reduce("") { $0 + String(format: "%02x", $1)}
            
        case .uppercase32:
            return uint8Array.reduce("") { $0 + String(format: "%02X", $1)}
        }
    }
}


public func aesDecrypt(key: String, iv: String, dataStr: String, options: Int = kCCOptionPKCS7Padding) -> Data? {
    if let keyData = key.data(using: String.Encoding.utf8) as? NSData,
       let ivData = iv.data(using: String.Encoding.utf8) as? NSData,
       let data = Data(base64Encoded: dataStr, options: .ignoreUnknownCharacters) as? NSData,
       let cryptData    = NSMutableData(length: Int((data.length)) + kCCBlockSizeAES128) {
        
        let keyLength = size_t(kCCKeySizeAES128)
        let operation: CCOperation = UInt32(kCCDecrypt)
        let algoritm: CCAlgorithm = UInt32(kCCAlgorithmAES128)
        let options: CCOptions = UInt32(options)

        var numBytesEncrypted :size_t = 0

        let cryptStatus = CCCrypt(operation,
                                  algoritm,
                                  options,
                                  keyData.bytes, keyLength,
                                  ivData.bytes,
                                  data.bytes, data.length,
                                  cryptData.mutableBytes, cryptData.length,
                                  &numBytesEncrypted)

        if UInt32(cryptStatus) == UInt32(kCCSuccess) {
            cryptData.length = Int(numBytesEncrypted)
            return cryptData as Data
        }
        else {
            return nil
        }
    }
    return nil
}


private let arrayParametersKey = ""

public extension Array {
    func asParameters() -> Parameters {
        return [arrayParametersKey : self]
    }
}

public struct ArrayEncoding: ParameterEncoding {
 
    public let options: JSONSerialization.WritingOptions
 
    public init(options: JSONSerialization.WritingOptions = []) {
        self.options = options
    }
 
    public func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        var urlRequest = try urlRequest.asURLRequest()
 
        guard let parameters = parameters,
            let array = parameters[arrayParametersKey] else {
                return urlRequest
        }
 
        do {
            let data = try JSONSerialization.data(withJSONObject: array, options: options)
 
            if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
                urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
 
            urlRequest.httpBody = data
 
        } catch {
            throw AFError.parameterEncodingFailed(reason: .jsonEncodingFailed(error: error))
        }
 
        return urlRequest
    }
}
