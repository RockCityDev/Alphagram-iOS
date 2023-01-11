
import TBStorage
import TBNetwork
import SwiftSignalKit
import Foundation
import Alamofire
import HandyJSON
import TBWeb3Core

enum EtherscanResult {
    case success(activities: [Any])
    case failure(code: String, message: String)
}

struct Etherscan: Encodable {
    let address: String
    let page: Int
    let offset: Int
    let apikey: String
    let startblock: String
    let endblock: String
}

class TBActivityInteractor {
    
    class func getTransactions(url: String, apikey: String, address: String, page: Int, offset: Int = 10, startblock: String = "0", endblock: String = "99999999") -> Signal<[EtherscanActivity], NoError> {
        let etherscan = Etherscan(address: address, page: page, offset: offset, apikey: apikey, startblock: startblock, endblock: endblock)
        var headers = HTTPHeaders.default
        headers.add(name: "Accept", value: "application/json")
        return Signal { subscriber in
            AF.request(url,
                       method: .get,
                       parameters: etherscan,
                       headers: headers).response(responseSerializer: StringResponseSerializer()) { response in
                switch response.result {
                case .success(let bin):
                    let data = bin.data(using: String.Encoding.utf8)
                    if let d = data, let result = try? JSONSerialization.jsonObject(with: d, options: .mutableContainers) as? Dict,
                       let status = result["status"] as? String,
                       status == "1",
                       let a = result["result"] as? [Any],
                       let res = JSONDeserializer<EtherscanActivity>.deserializeModelArrayFrom(array: a) as? [EtherscanActivity] {
                        subscriber.putNext(res)
                    } else {
                        subscriber.putNext([])
                    }
                case .failure(_):
                    subscriber.putNext([])
                }
                subscriber.putCompletion()
            }
            return EmptyDisposable
        }
    }
    
    class func getTTActivity(address: String, apikey: String, page: Int) -> Signal<[TTActivity], NoError> {
        return Signal { subscriber in
            let url = "https://api.viewblock.io/v1/thundercore/addresses/" + address + "/txs?page=" + "\(page)"
            var headers = HTTPHeaders.default
            headers.add(name: "Accept", value: "application/json")
            headers.add(name: "X-APIKEY", value: apikey)
            AF.request(url,
                       method: .get,
                       headers: headers).response(responseSerializer: JSONResponseSerializer()) { response in
                switch response.result {
                case .success(let bin):
                    if let arr = bin as? [Dict],
                    let rs = JSONDeserializer<TTActivity>.deserializeModelArrayFrom(array: arr) as? [TTActivity] {
                        subscriber.putNext(rs)
                    } else {
                        subscriber.putNext([])
                    }
                case .failure(_):
                    subscriber.putNext([])
                }
                subscriber.putCompletion()
            }
            return EmptyDisposable
        }
    }
}


struct TTActivity: HandyJSON {
    var blockHeight: String = ""
    var hash: String = ""
    var from: String = ""
    var value: String = "0"
    var fee: String = "0"
    var to: String = ""
    var timestamp: Double = 0
    var direction: String = "in"
    
    var price: String = "0"
    
    func bitCostNum() -> String {
        let decimal = getMainCurrencyDecimalBy(type: .TT) ?? 0
        let bitCostStr = NSDecimalNumber(string: self.value.decimalString()).dividing(by: NSDecimalNumber(decimal: pow(10, decimal))).description
        return bitCostStr
    }
}

extension TTActivity: TBActivityItem {
    func getActTypeA() -> ActType {
        return self.direction == "in" ? .receive : .sent
    }
    
    func getDateStrA() -> String {
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd HH:mm"
        return format.string(from:Date(timeIntervalSince1970: self.timestamp))
    }
    
    func getTitleA() -> String {
        if self.direction != "in" {
            return "Send to " + (self.to)
        } else {
            return "Received from " + (self.from)
        }
    }
    
    func getStatusA() -> String {
        return ""
    }
    
    func getBitCostA() -> String {
        let bitCost = self.bitCostNum().decimal(digits: 5)
        let t1 = self.getActTypeA() == .sent ? "- " : "+ "
        let t2 = (bitCost.isEmpty || bitCost == "0") ? "0" : t1 + bitCost
        let t3 = self.getSymbolA().isEmpty ? t2 : t2 + " " + self.getSymbolA()
        return t3
    }
    
    func getSymbolA() -> String {
        return getMainCurrencySymbolBy(type: .TT) ?? ""
    }
    
    func getBitCostTotalA() -> String? {
        let relCostNum = NSDecimalNumber(string: self.bitCostNum().decimalString())
        let totalStr = relCostNum.multiplying(by: NSDecimalNumber(string: self.price)).description.decimal(digits: 8)
        if !totalStr.isEmpty {
            return  "$" + totalStr
        }
        return ""
    }
}
