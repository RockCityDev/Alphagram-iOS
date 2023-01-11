






import TBStorage
import TBNetwork
import SwiftSignalKit
import Foundation

public class TBWeb3Network {
    public init(){}
    public func web3ConfigSignal() -> Signal<[String:Any], TBNetError> {
        return Signal { subscriber in
            TBNetwork.request(api: Web3.config.rawValue, method: .post, paramsFillter: nil, successHandle: { (result, message) in
                if let data = result as? Dictionary<String, Any> {
                    subscriber.putNext(data)
                    subscriber.putCompletion()
                }else{
                    subscriber.putError(.normal(code: 0, message: ""))
                }
            }, failHandle: { (code, message) in
                subscriber.putError(.normal(code: code, message: message))
            })
            
            return EmptyDisposable
        }
    }
    
    
    public struct UpdateGroupEntry {
        public enum GType:String {
            case group = "group"
            case channel = "channel"
            case supergroup = "supergroup"
            case locatedGroup = "locatedGroup"
        }
        public enum JoinType: Int {
            case noLimit = 1
            case conditionLimit = 2
            case payLimit = 3
        }
        public struct Tag {
            public let id: String
            public let name: String
            
            public func transforToJson() -> [String:String] {
                var ret = [String:String]()
                if !self.id.isEmpty {
                    ret["id"] = self.id
                }
                if !self.name.isEmpty {
                    ret["name"] = name
                }
                return ret
            }
            public init(id: String, name: String) {
                self.id = id
                self.name = name
            }
        }
        
        public let id: String
        
        public let chat_id: String
        
        public let type: GType
        
        public let title: String
        
        public let des: String
        
        public let join_type: JoinType
        
        public let wallet_id: String
        
        public let wallet_name: String
        
        public let chain_id: String
        
        public let chain_name: String
        
        public let token_id: String
        
        public let token_name: String
        
        public let amount: String
        
        public let currency_id: String
        
        public let currency_name: String
        
        public let token_address: String
        
        public let receipt_account: String
        
        public var avatar: String
        public var avatarData:Data?
        
        public let tags: [Tag]
        
        public init(id: String,
                    chat_id: String,
                    type: GType,
                    title: String,
                    des: String,
                    join_type: JoinType = .noLimit,
                    wallet_id: String = "",
                    wallet_name: String = "",
                    chain_id: String = "",
                    chain_name: String = "",
                    token_id: String = "",
                    token_name: String = "",
                    amount: String = "",
                    currency_id: String = "",
                    currency_name: String = "",
                    token_address: String = "",
                    receipt_account: String = "",
                    avatar: String = "",
                    avatarData: Data? = nil,
                    tags: [Tag] = [Tag]())
        {
            self.id = id
            self.chat_id = chat_id
            self.type = type
            self.title = title
            self.des = des
            self.join_type = join_type
            self.wallet_id = wallet_id
            self.wallet_name = wallet_name
            self.chain_id = chain_id
            self.chain_name = chain_name
            self.token_id = token_id
            self.token_name = token_name
            self.amount = amount
            self.currency_id = currency_id
            self.currency_name = currency_name
            self.token_address = token_address
            self.receipt_account = receipt_account
            self.avatar = avatar
            self.avatarData = avatarData
            self.tags = tags
        }
        
        func transforToRequestParams(isCreat:Bool) -> [String: Any] {
            var ret = [String: Any]()
            if !self.id.isEmpty {
                ret["id"] = self.id
            }
            ret["chat_id"] = self.chat_id
            ret["type"] = self.type.rawValue
            ret["title"] = self.title
            if !self.des.isEmpty {
                ret["description"] = self.des
            }
            ret["join_type"] = String(self.join_type.rawValue)
            if !self.wallet_id.isEmpty {
                ret["wallet_id"] = self.wallet_id
            }
            if !self.wallet_name.isEmpty {
                ret["wallet_name"] = self.wallet_name
            }
            if !self.chain_id.isEmpty {
                ret["chain_id"] = self.chain_id
            }
            if !self.chain_name.isEmpty {
                ret["chain_name"] = self.chain_name
            }
            if !self.token_id.isEmpty {
                ret["token_id"] = self.token_id
            }
            if !self.token_name.isEmpty {
                ret["token_name"] = self.token_name
            }
            if !self.amount.isEmpty {
                ret["amount"] = self.amount
            }
            
            if !self.currency_id.isEmpty {
                ret["currency_id"] = self.currency_id
            }
            if !self.currency_name.isEmpty {
                ret["currency_name"] = self.currency_name
            }
            if !self.token_address.isEmpty {
                ret["token_address"] = self.token_address
            }
            if !self.receipt_account.isEmpty {
                ret["receipt_account"] = self.receipt_account
            }
            if !self.avatar.isEmpty {
                ret["avatar"] = self.avatar
            }else{
                if isCreat {
                    ret["avatar"] = "https://d3l1ioscvnrz88.cloudfront.net/default-avatar.png"
                }
            }
            
            if !self.tags.isEmpty {
                var tagsJsonList = [[String: String]]()
                for item in self.tags {
                    tagsJsonList.append(item.transforToJson())
                }
                ret["tags"] = tagsJsonList
            }
            return ret
        }
    }
    
    public func web3UploadImage(data: Data) -> Signal<String, TBNetError> {
        return Signal { subscriber in
            TBNetwork.uploadImage(
                api: Upload.image.rawValue,
                paramsFillter: ["folder":"avatar"],
                data: data,
                successHandle: {(result, message) in
                    if let data = result as? String {
                        subscriber.putNext(data)
                        subscriber.putCompletion()
                    }else{
                        subscriber.putError(.normal(code: 0, message: ""))
                    }
                },
                failHandle: { (code, message) in
                    subscriber.putError(.normal(code: code, message: message))
                }
            )
            return EmptyDisposable
        }
    }
    
    public func web3UpdateGroupSignal(requestInfo:UpdateGroupEntry, isCreat:Bool = true) ->Signal<[String:Any], TBNetError> {
        
        return Signal { subscriber in
            TBNetwork.request(api: isCreat ? Web3.creatGroup.rawValue : Web3.updateGroup.rawValue, method: .post, paramsFillter: requestInfo.transforToRequestParams(isCreat: isCreat), successHandle: { (result, message) in
                if let data = result as? Dictionary<String, Any> {
                    subscriber.putNext(data)
                    subscriber.putCompletion()
                }else{
                    subscriber.putError(.normal(code: 0, message: ""))
                }
            }, failHandle: { (code, message) in
                subscriber.putError(.normal(code: code, message: message))
            })
            return EmptyDisposable
        }
    }
    
    
    public func web3HotTagsSignal() -> Signal<[[String:Any]], TBNetError> {
        return Signal { subscriber in
            TBNetwork.request(api: Web3.hotTags.rawValue, method: .post, paramsFillter: nil, successHandle: { (result, message) in
                if let data = result as? Array<[String: Any]> {
                    subscriber.putNext(data)
                    subscriber.putCompletion()
                }else{
                    subscriber.putError(.normal(code: 0, message: ""))
                }
            }, failHandle: { (code, message) in
                subscriber.putError(.normal(code: code, message: message))
            })
            return EmptyDisposable
        }
    }
    
    public func web3GroupInfoSignal(group_id:String) ->Signal<[String:Any], TBNetError> {
        return Signal { subscriber in
            TBNetwork.request(api:Web3.groupInfo.rawValue, method: .post, paramsFillter: ["group_id": group_id], successHandle: { (result, message) in
                if let data = result as? Dictionary<String, Any> {
                    subscriber.putNext(data)
                    subscriber.putCompletion()
                }else{
                    subscriber.putError(.normal(code: 0, message: ""))
                }
            }, failHandle: { (code, message) in
                subscriber.putError(.normal(code: code, message: message))
            })
            return EmptyDisposable
        }
    }
    
    public func web3GroupInfoByChatIdSignal(chat_id:String) ->Signal<[String:Any], TBNetError> {
        return Signal { subscriber in
            TBNetwork.request(api:Web3.groupInfoByChatId.rawValue, method: .post, paramsFillter: ["chat_id": chat_id], successHandle: { (result, message) in
                if let data = result as? Dictionary<String, Any> {
                    subscriber.putNext(data)
                    subscriber.putCompletion()
                }else{
                    subscriber.putError(.normal(code: 0, message: ""))
                }
            }, failHandle: { (code, message) in
                subscriber.putError(.normal(code: code, message: message))
            })
            return EmptyDisposable
        }
    }
    
    public func web3GroupListSignal(tag_id:String = "", hot_tag_id:String = "", chain_id:String = "", page: Int) ->Signal<[String:Any], TBNetError> {
        
        var params = [String:Any]()
        if !tag_id.isEmpty {
            params["tag_id"] = tag_id
        }
        if !hot_tag_id.isEmpty {
            params["hot_tag_id"] = hot_tag_id
        }
        if !chain_id.isEmpty {
            params["chain_id"] = chain_id
        }
        params["page"] = page > 0 ? page : 1
        return Signal { subscriber in
            TBNetwork.request(api:Web3.groupList.rawValue, method: .post, paramsFillter: params, successHandle: { (result, message) in
                if let data = result as? Dictionary<String, Any> {
                    subscriber.putNext(data)
                    subscriber.putCompletion()
                }else{
                    subscriber.putError(.normal(code: 0, message: ""))
                }
            }, failHandle: { (code, message) in
                subscriber.putError(.normal(code: code, message: message))
            })
            return EmptyDisposable
        }
    }
    
    public func web3CurrencyPriceSignal(coin_ids:[String]? = nil) ->Signal<[String:Any], TBNetError>  {
        var params = [String: Any]()
        if let coin_ids = coin_ids {
            params["coin_id"] = coin_ids
        }
        return Signal { subscriber in
            TBNetwork.request(api:Web3.currency_price.rawValue, method: .post, paramsFillter: params, successHandle: { (result, message) in
                if let data = result as? Dictionary<String, Any> {
                    subscriber.putNext(data)
                    subscriber.putCompletion()
                }else{
                    subscriber.putError(.normal(code: 0, message: ""))
                }
            }, failHandle: { (code, message) in
                subscriber.putError(.normal(code: code, message: message))
            })
            return EmptyDisposable
        }
    }
    
    public func web3OrderPostSignal(tx_hash: String, group_id: String, payment_account:String) ->Signal<[String:Any], TBNetError>  {
        var params = [String: Any]()
        params["tx_hash"] = tx_hash
        params["group_id"] = group_id
        params["payment_account"] = payment_account
        return Signal { subscriber in
            TBNetwork.request(api:Web3.orderPost.rawValue, method: .post, paramsFillter: params, successHandle: { (result, message) in
                if let data = result as? Dictionary<String, Any> {
                    subscriber.putNext(data)
                    subscriber.putCompletion()
                }else{
                    subscriber.putError(.normal(code: 0, message: ""))
                }
            }, failHandle: { (code, message) in
                subscriber.putError(.normal(code: code, message: message))
            })
            return EmptyDisposable
        }
    }
    
    public func web3OrderResultSignal(tx_hash: String) ->Signal<[String:Any], TBNetError>  {
        var params = [String: Any]()
        params["tx_hash"] = tx_hash
        return Signal { subscriber in
            TBNetwork.request(api:Web3.orderResult.rawValue, method: .post, paramsFillter: params, successHandle: { (result, message) in
                if let data = result as? Dictionary<String, Any> {
                    subscriber.putNext(data)
                    subscriber.putCompletion()
                }else{
                    subscriber.putError(.normal(code: 0, message: ""))
                }
            }, failHandle: { (code, message) in
                subscriber.putError(.normal(code: code, message: message))
            })
            return EmptyDisposable
        }
    }
}
