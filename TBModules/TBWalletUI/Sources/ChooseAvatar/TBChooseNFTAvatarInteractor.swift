






import UIKit
import TBOpenSea
import TBAccount


public class TBChooseNFTAvatarInteractor {
    public let walletAddress: String
    public var currentEntity: TBAssetsEntity?
    private var assetItemList = [TBAssetItem]()
    private var host: String?
    
    public init(walletAddress:String, host: String?) {
        self.walletAddress = walletAddress
        self.host = host
    }
    
    public func refreshPageData(callBack: @escaping([TBAssetItem], Bool) -> Void) {
        self.loadPageData(cursor: nil) {  [weak self] entity, error in
            if let strongSelf = self {
                if let entity = entity {
                    strongSelf.currentEntity = entity
                    strongSelf.assetItemList.removeAll()
                    strongSelf.assetItemList.append(contentsOf: entity.parseItems())
                    callBack(strongSelf.assetItemList, entity.next.isEmpty ? false : true)
                }else{
                    callBack(strongSelf.assetItemList, false)
                }
            }else{
                callBack([TBAssetItem](), false)
            }
        }
    }
    
    public func loadNextPageData(callBack: @escaping([TBAssetItem], Bool) -> Void) {
        
        guard let cursor = self.currentEntity?.next, !cursor.isEmpty else {
            callBack(self.assetItemList, false)
            return
        }
        
        self.loadPageData(cursor: cursor) {[weak self] entity, error in
            if let strongSelf = self {
                if let entity = entity {
                    strongSelf.currentEntity = entity
                    strongSelf.assetItemList.append(contentsOf: entity.parseItems())
                    callBack(strongSelf.assetItemList, entity.next.isEmpty ? false : true)
                }else{
                    callBack(strongSelf.assetItemList,false)
                }
            }else{
                callBack([TBAssetItem](), false)
            }
        }
    }
    
    public func loadPageData(cursor:String?, completion:@escaping (TBAssetsEntity?, TBOpenSeaError?)->Void) {
        var fields = [
           "order_direction":"desc",
           "limit":"10",
           "include_orders":"true",
//           "owner":self.walletAddress,
           "owner":"0xd31dac5aff0cdaae1e86ddcb9d8dad281d641b0d",
           //"asset_contract_address":self.walletAccount,
        ]
        if let cursor = cursor {
            fields["cursor"] = cursor
        }
        let host: String
        if let h = self.host, !h.isEmpty {
            host = h
        } else {
            host = "https://api.opensea.io/api/v1/assets"
        }
        TBOpensea().retrieveAssets(host: host, apiKey: TBAccount.shared.systemCheckData.openseaapikey, fields: fields) { assets, error in
            completion(assets, error)
        }
    }
    
}

public class TBAssetItem {
    public var asset_name : String = ""
    public var nft_name : String = ""
    public var thumb_url : String = ""
    public var original_url : String = ""
    public var token_id : String = ""
    public var contract_address : String = ""
    public var symbol : String = ""
    public var price : String = ""
    public var presentPrice: String {
        let original = NSDecimalNumber(string: self.price.isEmpty ? "0" : self.price)
        let divided = NSDecimalNumber(decimal: pow(10, 18))
        let ret = original.dividing(by: divided).doubleValue
        return String(format: "%.2f", ret)
    }
    public var token_standard : String = ""
    public var blockchain = "Ethereum"
    
    public var nft_chain_id: String? = nil
    public var nft_photo_id: String? = nil
    public init() {
    }
}

extension TBAssetsEntity {
    func parseItems() -> [TBAssetItem] {
        let ret = self.assets.map { item in
            return item.parseItem()
        }
        return ret
    }
}

extension TBAssetsEntity.Item {
    func parseItem() -> TBAssetItem {
        let nftInfo = TBAssetItem()
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
        nftInfo.blockchain = "Ethereum";
        return nftInfo
    }
}


