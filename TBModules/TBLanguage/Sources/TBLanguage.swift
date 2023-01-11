






import Foundation
import SwiftSignalKit


public class TBLanguage {
    
    public let supportLanguages:[[String:String]]
    =
    [
        ["login_language_text_tw":"taiwan"],
        ["login_language_text_hk":"hongkong"],
        ["login_language_text_cn":"zhcncc"],
        ["login_language_text_en":"en"],
        ["login_language_text_por":"pt-br"],
        ["login_language_text_baml":"ms"],
        ["login_language_text_bain":"id"],
        ["login_language_text_esp":"es"]
    ]
    
    public static let sharedInstance = TBLanguage()
    
    let languageSaveKey:String = "__TB_languageSaveKey__"

    public var languageCode: String? = nil

    var currentLanguageDic = [String: String]()
    
    
    public func setup() {
        
        self.languageCode = UserDefaults.standard.string(forKey: languageSaveKey)
        guard let code = self.languageCode, !code.isEmpty else{
            TBLanguage.sharedInstance.setLanguage(language: self.getCurrentSystemLanguageCode())
            return
        }
    }
    
    
    public func localizable(_ string:String)->(String) {
        
        
        if self.languageCode == "en" {
            self.currentLanguageDic = self.dic_en()
        } else if self.languageCode == "zhcncc"{
            self.currentLanguageDic = self.dic_zh_cn()
        } else if self.languageCode == "hongkong" {
            self.currentLanguageDic = self.idc_zh_hk()
        }else if self.languageCode == "taiwan" {
            self.currentLanguageDic = self.dic_zh_tw()
        }else if self.languageCode == "pt-br" {
            self.currentLanguageDic = self.dic_pt()
        }else if self.languageCode == "ms" {
            self.currentLanguageDic = self.dic_ms()
        }else if self.languageCode == "id" {
            self.currentLanguageDic = self.dic_in()
        }else if self.languageCode == "es" {
            self.currentLanguageDic = self.dic_es()
        }else {
            self.currentLanguageDic = self.dic_en()
        }
                
        
        if let outString = self.currentLanguageDic[string] {
            return outString
        }else {
            self.currentLanguageDic = self.dic_en()
            if let outString = self.currentLanguageDic[string] {
                return outString
            }
        }
        return ""
    }
    
    public func setLanguage(language: String) {
        print("current language is \(language)")
        if !language.isEmpty{
            
            if language != self.languageCode {
                self.languageCode = language
                UserDefaults.standard.setValue(TBLanguage.sharedInstance.languageCode, forKey: languageSaveKey)
                
            }
        }
    }
    
    
    public func getCurrentSystemLanguageCode() ->(String) {
        if let preferredLanguage = UserDefaults.standard.array(forKey: "AppleLanguages")?.first {
            
                if preferredLanguage as! String == "zh-Hans-CN" {
                    return "zhcncc"
                }else if preferredLanguage as! String == "zh-Hans" {
                    return "zhcncc"
                }else if preferredLanguage as! String == "zh-Hant-HK" {
                    return "hongkong"
                }else if preferredLanguage as! String == "zh-Hant-TW" {
                    return "taiwan"
                }else if let preferredLanguage = preferredLanguage  as? String, preferredLanguage.lowercased().hasPrefix("zh-han") {
                    return "taiwan"
                }else if preferredLanguage as! String == "pt" {
                    return "pt"
                }else if preferredLanguage as! String == "ms" {
                    return "ms"
                }else if preferredLanguage as! String == "in" {
                    return "in"
                }else if preferredLanguage as! String == "es" {
                    return "es"
                }
            }
        return "en"
    }
    
    public func localizedString(baseLanCode:String, for lanCode:String)->String? {
        if lanCode == "zh-Hans-CN" {
            return self.localizable(TBLankey.login_language_text_cn).capitalized
        }
        if lanCode == "zh-Hant-TW" {
            return self.localizable(TBLankey.login_language_text_tw).capitalized
        }
        if lanCode == "zh-Hant-HK" {
            return self.localizable(TBLankey.login_language_text_hk).capitalized
        }
        let interfaceLocale = Locale(identifier: baseLanCode)
        if let title = interfaceLocale.localizedString(forLanguageCode: lanCode) {
            return title.capitalized
        }else{ 
            let enLocale = Locale(identifier: "en")
            if let title = enLocale.localizedString(forLanguageCode: lanCode){
                return title.capitalized
            }
        }
        return nil
    }
    
    public func fixTranslateLanCode(lanCode:String) -> String {
        if lanCode.lowercased().hasPrefix("zh-hans") {
            return "zh-CN"
        }
        
        if lanCode.lowercased().hasPrefix("zh-hant") {
            return "zh-TW"
        }
        return lanCode
    }
}






