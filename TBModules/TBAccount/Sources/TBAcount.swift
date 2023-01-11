import Foundation
import UIKit
import TBStorage
import SwiftSignalKit
import HandyJSON
import TBBusinessNetwork
import AccountContext


public struct NFTSettingItem {
    public let image: UIImage
    public let config: NFTSettingConfig
    public let settingId: TimeInterval
    public init(image: UIImage, config: NFTSettingConfig, settingId: TimeInterval) {
        self.image = image
        self.config = config
        self.settingId = settingId
    }
}

public struct NFTSettingInfoItem {
    public let photoId: String
    public let config: NFTSettingConfig
    public let settingId: TimeInterval
    public init(photoId: String, config: NFTSettingConfig, settingId: TimeInterval) {
        self.photoId = photoId
        self.config = config
        self.settingId = settingId
    }
}

public class TBAccount {
    
    
    public static let shared = TBAccount()
    
    
    private var context: AccountContext?
    
    
    public var systemCheckData = TBSystemCheckData()
    
    
    public var loginData = TBLoginData()
    
    public let nftSettingPromise: Promise<NFTSettingItem> = Promise()
    
    
    public var showTranslateBubbleValue:Bool  {
        didSet {
            UserDefaults.standard.tb_set(bool: self.showTranslateBubbleValue, for: .tbShowTranslateBubbble)
            self._showTranslateBubblePromise.set(self.showTranslateBubbleValue)
        }
    }
    private let _showTranslateBubblePromise: ValuePromise<Bool> = ValuePromise(ignoreRepeated: true)
    public var showTranslateBubbleSignal:Signal<Bool, NoError> {
        return self._showTranslateBubblePromise.get()
    }
    
    
    private var cycleGetCode : TBCycleRequestPhoneCode?
    
    private init(){
        let data: TBSystemCheckData? = UserDefaults.standard.tb_object(for: .systemCheck)
        if let data = data {
            self.systemCheckData = data
        }
        self.showTranslateBubbleValue = UserDefaults.standard.tb_bool(for: .tbShowTranslateBubbble, default: true)
    }
    
    
    
    public func setup(context:AccountContext) {
        self.context = context
        guard let context = self.context else {
            return
        }
    }
    
    deinit {
        
    }
    
    
    
    public func updateSystemCheckSignal() -> Signal<TBSystemCheckData, TBNetError> {
        return TBLaunchNetwork().systemCheckSignal() |> mapToSignal({ data in
            return Signal{ subscriber in
                if let obj = TBSystemCheckData.deserialize(from: data){
                    subscriber.putNext(obj)
                    subscriber.putCompletion()
                    self.systemCheckData = obj
                }else{
                    subscriber.putError(TBNetError.normal(code: 0, message: ""))
                }
                return EmptyDisposable
            }
        })
    }
    
    
    
    
    public func getSystemCheckSignal(force:Bool) -> Signal<TBSystemCheckData, TBNetError> {
        if force == true {
            return self.updateSystemCheckSignal()
        }else{
            if self.systemCheckData.testerphones.count > 0 {
                return Signal { subscriber in
                    subscriber.putNext(self.systemCheckData)
                    subscriber.putCompletion()
                    return EmptyDisposable
                }
            }else{
                return self.updateSystemCheckSignal()
            }
        }
    }
    
    
    
    
    
    
    public func login(userId: Int64,newer: Bool = false) -> Signal<TBLoginData, TBNetError> {
        if (self.loginData.user.tg_user_id == userId && self.loginData.isLogin()) { 
            return Signal { subscriber in
                subscriber.putNext(self.loginData)
                subscriber.putCompletion()
                return EmptyDisposable
            }
        }else{
            return TBLoginNetwork().loginSignal(tg_user_id: userId, is_tg_new: newer) |> mapToSignal({ data  in
                return Signal { subscriber in
                    if let obj = TBLoginData.deserialize(from: data) {
                        subscriber.putNext(obj)
                        subscriber.putCompletion()
                        if obj.user.tg_user_id <= 0 {
                            obj.user.tg_user_id = userId
                        }
                        self.loginData = obj
                    }else{
                        subscriber.putError(TBNetError.normal(code: 0, message: ""))
                    }
                    return EmptyDisposable
                }
            })
        }
    }
    
    
    
    
    public func phoneCodeSignal(phone: String) -> Signal<TBPhoneCode, TBNetError> {
        return TBCycleRequestPhoneCode(phone: phone).phoneCode()
    }
    
    
    
    
    public func startCycleGetPhoneCode(phone: String) -> Signal<TBPhoneCode, TBNetError> {
        let filterPhone = phone.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "+", with: "")
        return Signal{
            subscriber in
            if TBAccount.shared.systemCheckData.testerphones.contains(filterPhone) {
                self.cycleGetCode?.stopCycle()
                self.cycleGetCode = TBCycleRequestPhoneCode(phone: filterPhone);
                self.cycleGetCode?.completion = {phoneCode, finished in
                    if let phoneCode = phoneCode, finished == true {
                        subscriber.putNext(phoneCode)
                        subscriber.putCompletion()
                    }else{
                        subscriber.putError(TBNetError.normal(code: 0, message: "PhoneCode"))
                    }
                }
                self.cycleGetCode?.startCycle()
            }else{
                subscriber.putCompletion()
            }
            return EmptyDisposable
        }
    }
    
    
    public func stopCycleGetCode() {
        self.cycleGetCode?.stopCycle()
    }
    
    
    public func userBindWallet(walletType:String, walletAddress:String,chainId:Int)-> Signal<TBLoginData, TBNetError> {
        return TBNFTAvatarNetwork().userBindWalletSignal(wallet_type: walletType, wallet_address: walletAddress,chainId: chainId) |> mapToSignal({ data  in
            return Signal { subscriber in
                if let obj = TBLoginData.deserialize(from: data) {
                    subscriber.putNext(obj)
                    subscriber.putCompletion()
                }else{
                    subscriber.putError(TBNetError.normal(code: 0, message: ""))
                }
                return EmptyDisposable
            }
        })
        
    }
    
    
    public func userUpdateNftInfo(info: NFTSettingInfoItem)-> Signal<TBLoginData, TBNetError> {
        let request = info.config
        let config = NFTAvatarSettingConfig(nft_contract: request.nftContract(),
                                            nft_contract_image: request.nftContractImage(),
                                            nft_token_id: request.nftTokenId(),
                                            nft_photo_id: info.photoId,
                                            nft_name: request.nftAssetName(),
                                            nft_chain_id: request.nftChainId(),
                                            nft_price: request.nftPrice(),
                                            nft_token_standard: request.nftTokenStandard())
        return TBNFTAvatarNetwork().userUpdateNftInfoSignal(config: config) |> mapToSignal({ data  in
            return Signal { subscriber in
                if let obj = TBLoginData.deserialize(from: data) {
                    subscriber.putNext(obj)
                    subscriber.putCompletion()
                    self.loginData.user.updateNftInfo(info: obj.user)
                }else{
                    subscriber.putError(TBNetError.normal(code: 0, message: ""))
                }
                return EmptyDisposable
            }
        })
        
    }
    
}

public protocol NFTSettingConfig {
    func nftContract() -> String
    func nftContractImage() -> String
    func nftTokenId() -> String
    func nftAssetName() -> String?
    func nftChainId() -> String?
    func nftPrice() -> String?
    func nftTokenStandard() -> String?
}
