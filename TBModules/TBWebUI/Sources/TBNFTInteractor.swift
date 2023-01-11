
import TBStorage
import TBNetwork
import SwiftSignalKit
import Foundation
import Alamofire
import HandyJSON
import TBOpenSea
import TBAccount

class TBNFTInteractor {
    
    private let walletAddress: String
    private var currentEntity: TBAssetsEntity?
    private var assetItemList = [TBNFTAssetItem]()
    private let host: String
    private let isEth: Bool
    
    public init(walletAddress:String, isEth: Bool) {
        self.walletAddress = walletAddress
        self.isEth = isEth
        self.host = isEth ? "https://api.opensea.io/api/v1/assets" : "https://api.opensea.io/api/v2/assets/matic"
    }
    
    public func refreshPageData(callBack: @escaping([TBNFTAssetItem], Bool) -> Void) {
        self.loadPageData(cursor: nil) {  [weak self] entity, error in
            guard let strongSelf = self else { return }
            strongSelf.assetItemList.removeAll()
            if let entity = entity {
                strongSelf.currentEntity = entity
                strongSelf.assetItemList.append(contentsOf: entity.parseItems(isEth: strongSelf.isEth))
                callBack(strongSelf.assetItemList, entity.next.isEmpty ? false : true)
            }else{
                callBack(strongSelf.assetItemList, false)
            }
        }
    }
    
    public func loadNextPageData(callBack: @escaping([TBNFTAssetItem], Bool) -> Void) {
        
        guard let cursor = self.currentEntity?.next, !cursor.isEmpty else {
            callBack(self.assetItemList, false)
            return
        }
        
        self.loadPageData(cursor: cursor) {[weak self] entity, error in
            if let strongSelf = self {
                if let entity = entity {
                    strongSelf.currentEntity = entity
                    strongSelf.assetItemList.append(contentsOf: entity.parseItems(isEth: strongSelf.isEth))
                    callBack(strongSelf.assetItemList, entity.next.isEmpty ? false : true)
                }else{
                    callBack(strongSelf.assetItemList,false)
                }
            }else{
                callBack([TBNFTAssetItem](), false)
            }
        }
    }
    
    public func loadPageData(cursor:String?, completion:@escaping (TBAssetsEntity?, TBOpenSeaError?)->Void) {
        var fields = [
           "order_direction" : "desc",
           "limit" : "20",
           "include_orders" : "true"
        ]
        if self.isEth {
            fields["owner"] = self.walletAddress
        } else {
            fields["owner_address"] = self.walletAddress
        }
        if let cursor = cursor {
            fields["cursor"] = cursor
        }
        TBOpensea().retrieveAssets(host: self.host, apiKey: TBAccount.shared.systemCheckData.openseaapikey, fields: fields) { assets, error in
            completion(assets, error)
        }
    }
    
}

class TBNFTAssetItem {
    public var asset_name : String = ""
    public var nft_name : String = ""
    public var thumb_url : String = ""
    public var original_url : String = ""
    public var token_id : String = ""
    public var contract_address : String = ""
    public var symbol : String = ""
    public var price : String = ""
    public var presentPrice: String {
        let original = NSDecimalNumber(string: self.price.decimalString())
        let divided = NSDecimalNumber(decimal: pow(10, 18))
        let ret = original.dividing(by: divided).doubleValue
        return String(format: "%.2f", ret)
    }
    public var token_standard : String = ""
    public var blockchain = "Ethereum"
    public var chainId: String?
    public init() {
    }
}

extension TBNFTAssetItem: TBNFTItem {
    func getNFTName() -> String {
        return self.nft_name
    }
    
    func nftAssetName() -> String? {
        return self.asset_name
    }
    
    func nftContract() -> String {
        return self.contract_address
    }
    
    func nftContractImage() -> String {
        return self.thumb_url
    }
    
    func nftTokenId() -> String {
        return self.token_id
    }
    
    func nftChainId() -> String? {
        return self.chainId
    }
    
    func nftPrice() -> String? {
        self.presentPrice
    }
    
    func nftTokenStandard() -> String? {
        return self.token_standard
    }
}

extension TBAssetsEntity {
    func parseItems(isEth: Bool) -> [TBNFTAssetItem] {
        if isEth {
            let ret = self.assets.filter({$0.collection.hidden == false}).map { item in
                return item.parseItem(isEth: true)
            }
            return ret
        } else {
            let ret = self.results.filter({$0.collection.hidden == false}).map { item in
                return item.parseItem(isEth: false)
            }
            return ret
        }
    }
}

extension TBAssetsEntity.Item {
    func parseItem(isEth: Bool) -> TBNFTAssetItem {
        let nftInfo = TBNFTAssetItem()
        nftInfo.asset_name = self.collection.name;
        nftInfo.nft_name = self.name.isEmpty ? self.token_id : self.name;
    
        nftInfo.thumb_url = self.image_thumbnail_url;
        nftInfo.original_url = self.image_url;
        nftInfo.token_id = self.token_id;
        nftInfo.contract_address = self.asset_contract.address;
        nftInfo.symbol = self.asset_contract.symbol;
        if !self.seaport_sell_orders.isEmpty {
            nftInfo.price = (self.seaport_sell_orders.first)!.current_price;
        } else if !self.last_sale.total_price.isEmpty {
            nftInfo.price = self.last_sale.total_price;
        }
        nftInfo.token_standard = self.asset_contract.schema_name;
        if isEth {
            nftInfo.blockchain = "Ethereum";
            nftInfo.chainId = "1"
        } else {
            nftInfo.blockchain = "Polygon";
            nftInfo.chainId = "137"
        }
        
        return nftInfo
    }
}
