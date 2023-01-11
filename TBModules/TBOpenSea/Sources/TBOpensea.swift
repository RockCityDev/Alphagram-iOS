import Foundation
import Alamofire
import HandyJSON

public enum TBOpenSeaError {
    case normal(Int?, String)
}

public class TBOpensea {

    public init() {
    }
    
    public func retrieveAssets(host: String = "https://api.opensea.io/api/v1/assets" ,apiKey:String, fields:[String:String], completion: @escaping (TBAssetsEntity?, TBOpenSeaError?) -> Void) {
        let headers = HTTPHeaders(["X-API-KEY":apiKey, "Accept":"application/json"])
        AF.request(host,
                   method: .get,
                   parameters: fields,
                   encoder: URLEncodedFormParameterEncoder.default,
                   headers: headers).response(responseSerializer: JSONResponseSerializer()) { response in
            switch response.result {
            case .success(let bin):
                if let dic = bin as? Dictionary<String, Any>, let assets = TBAssetsEntity.deserialize(from: dic) {
                    completion(assets, nil)
                }else{
                    completion(nil, TBOpenSeaError.normal(0, ""))
                }
            case .failure(let error):
                completion(nil, TBOpenSeaError.normal(error.responseCode, error.localizedDescription))
                debugPrint("[tb assets] error: \(error.localizedDescription)")
            }
        }
    }
}
