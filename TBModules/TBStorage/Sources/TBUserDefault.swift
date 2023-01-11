
import Foundation
import CoreFoundation
import HandyJSON


extension UserDefaults {
    
    public enum TBKey {
        case systemCheck
        case coinIncognitoMode
        case dontShowMyPhoneOnMyInterface
        case dontShowMyPhone
        case tbSettingTranslateTo
        case tbShowTranslateBubbble
        case accountPeerChannelCountMap(peerId: Int64)
        case accountPeerWallletSessionList(peerId:Int64)
        case web3Config
        case accountWalletGroupList(peerId: Int64)
        var rawValue: String {
            get {
                switch self{
                case .systemCheck:
                    return "tb_user_default_key_systemCheck"
                case .coinIncognitoMode:
                    return "CoinIncognitoMode"
                case .dontShowMyPhoneOnMyInterface:
                    return "DontShowMyPhoneOnMyInterface"
                case .dontShowMyPhone:
                    return "DontShowMyPhone"
                case .tbSettingTranslateTo:
                    return "tb_setting_translateTo"
                case .tbShowTranslateBubbble:
                    return "tb_show_translate_bubbble"
                case .accountPeerChannelCountMap(peerId: let peerId):
                    return "accountPeerChannelCountMap_\(peerId)"
                case .accountPeerWallletSessionList(peerId: let peerId):
                    return "accountPeerWallletSessionList_\(peerId)"
                case .web3Config:
                    return "tb_web3_config_entry"
                case .accountWalletGroupList(peerId: let peerId):
                    return "tb_accountWalletGroupList_\(peerId)"
                }
            }
        }
    }
    
    
     public func tb_set(value:Any?, for key:UserDefaults.TBKey) {
        self.set(value, forKey: key.rawValue)
        self.synchronize()
    }
    
     public func tb_value(for key: UserDefaults.TBKey) -> Any? {
        return self.value(forKey:key.rawValue)
    }
    
    
     public func tb_set(bool: Bool, for key: UserDefaults.TBKey) {
         self.set(bool, forKey: key.rawValue)
         self.synchronize()
    }
    
    public func tb_bool(for key: UserDefaults.TBKey, default:Bool = false)  -> Bool {
        
        if let _ = self.tb_value(for: key) {
            return self.bool(forKey: key.rawValue)
        }else{
            return `default`
        }
      
   }
    
    
    
    public func tb_string(for key:UserDefaults.TBKey) -> String? {
        return self.string(forKey: key.rawValue)
    }
    
    public func tb_data(for key:UserDefaults.TBKey) -> Data? {
        return self.data(forKey: key.rawValue)
    }
    
    public func tb_dict<T>(for key:UserDefaults.TBKey) -> [String : T]? {
        if let ret = self.dictionary(forKey: key.rawValue), let ret = ret as? [String : T] {
            return ret
        }
       return nil
    }
    
    
    public func tb_array(for key:UserDefaults.TBKey) -> [Any]? {
        return self.array(forKey: key.rawValue)
    }
    
    
    public func tb_object<T:HandyJSON>(for key: UserDefaults.TBKey) -> T? {
        guard let jsonString = self.tb_string(for: key) else {
            return nil
        }
        return T.deserialize(from: jsonString)
    }
    
    public func tb_set<T:HandyJSON>(object:T, for key:UserDefaults.TBKey) {
        guard let jsonString = object.toJSONString() else {
            return
        }
        self.tb_set(value: jsonString, for: key)
    }
    
    
    public func tb_objectArray<T:HandyJSON>(for key: UserDefaults.TBKey) -> [T?]? {
        guard let jsonString = self.tb_string(for: key) else {
            return nil
        }
        return [T].deserialize(from: jsonString)
    }
    
    public func tb_set<T:HandyJSON>(objectArray:[T], for key:UserDefaults.TBKey) {
        guard let jsonString = objectArray.toJSONString() else {
            return
        }
        self.tb_set(value: jsonString, for: key)
    }
    
    public func tb_removeObject(for key: UserDefaults.TBKey) {
        self.removeObject(forKey: key.rawValue)
    }
    
}



