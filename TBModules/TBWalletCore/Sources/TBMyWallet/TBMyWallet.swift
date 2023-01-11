






import Foundation
import Web3swift
import Web3swiftCore
import BigInt

public enum TBMyWalletModel: Equatable {

    case eth(EthereumKeystoreV3, name:String)
    
    public static func == (lhs: TBMyWalletModel, rhs: TBMyWalletModel) -> Bool {
        switch lhs {
        case let .eth(lhsEthereumKeystoreV3,lhsName):
            if case let .eth(rhsEthereumKeystoreV3, rhsName) = rhs, lhsEthereumKeystoreV3.getAddress() == rhsEthereumKeystoreV3.getAddress(), lhsName == rhsName{
                return true
            } else {
                return false
            }
        }
    }
    
    public func walletAddress() -> String {
        switch self {
        case let .eth(ethereumKeystoreV3, _):
            return ethereumKeystoreV3.getAddress()?.address ?? ""
        }
    }
    
    public func walletName() -> String {
        switch self {
        case let .eth(_, name):
            return name
        }
    }
}

private let __keystorePath  = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] + "/keyStore."

private let __key_name_prefix  = "__name_for_wallet_account__"

public class TBMyWallet {
    
    public static func genMnemonics() -> String?{
        let tempMnemonics = try? BIP39.generateMnemonics(bitsOfEntropy: 256, language: .english)
        guard let tMnemonics = tempMnemonics else {
            return ""
        }
        return tMnemonics
    }
    
    public static func getPrivateKey(account:TBMyWalletModel,password:String!) -> (key:String?,error:Error?){
        do {
            switch account {
                case .eth(let keystore,_):
                    
                let keyaccount = keystore.addresses?[0]
                let privatekey = try keystore.UNSAFE_getPrivateKeyData(password: password, account: keyaccount!)
                let keyString = privatekey.toHexString() 

                return (keyString,nil)
            }
        }catch{
            print("getPrivateKey err: \(error).")
            return ("",error)
        }
        return ("",fatalError("unkown error"))
    }
    
    
    public static func createAccountWithPrivateKey(privateKey:String!,password:String!,tbUserId:String!,name:String!) -> Bool{
        
        let privateKeyData = Data(hex: privateKey)
        guard privateKeyData != nil else {
            return false
        }
        
        do {
            let tempWalletAddress = try? EthereumKeystoreV3(privateKey: privateKeyData, password: password)
                        
            guard let walletAddress = tempWalletAddress?.addresses?.first else {
                return false
            }

            let userDir = __keystorePath + tbUserId
            let userPath = userDir + "/" + walletAddress.address
        
            self.createUserDic(dirPath:userDir)
            
            let keyData = try? JSONEncoder().encode(tempWalletAddress?.keystoreParams)
            FileManager.default.createFile(atPath: userPath + ".key.json", contents: keyData, attributes: nil)
            
            let nameKey = __key_name_prefix + walletAddress.address
            UserDefaults.standard.setValue(name, forKey: nameKey)
            return true
            
        }catch {
            print("createAccountWithPrivateKey err: \(error).")
            return false
        }
        return false
    }
    
    
    
    public static func createAccountWithMnemonics(mnemonics:String!,password:String!,tbUserId:String!,name:String!) -> Bool{
                
        let tempWalletAddress = try! BIP32Keystore(mnemonics: mnemonics, password: password)
        
        print(tempWalletAddress?.addresses?.first?.address as Any)
                
        guard let walletAddress = tempWalletAddress?.addresses?.first else {
            return false
        }
        
        do {
            guard let privateKey = try tempWalletAddress?.UNSAFE_getPrivateKeyData(password: password, account: walletAddress) else { return false}
            let evmAccount =  try EthereumKeystoreV3(privateKey: privateKey,password: password)


            let userDir = __keystorePath + tbUserId
            let userPath = userDir + "/" + walletAddress.address
        
            self.createUserDic(dirPath:userDir)
            
            let keyData = try? JSONEncoder().encode(evmAccount?.keystoreParams)
            FileManager.default.createFile(atPath: userPath + ".key.json", contents: keyData, attributes: nil)
            
            let nameKey = __key_name_prefix + walletAddress.address
            UserDefaults.standard.setValue(name, forKey: nameKey)
        }catch {
            print("createAccountWithMnemonics err: \(error).")
        }
        let nameKey = __key_name_prefix + walletAddress.address
        UserDefaults.standard.setValue(name, forKey: nameKey)
        return true
    }
    
    public static func createUserDic(dirPath:String){
        if(!FileManager.default.fileExists(atPath: dirPath)){
            do {
                try FileManager.default.createDirectory(atPath: dirPath, withIntermediateDirectories: true)
            }catch {
                print("createUserDic err: \(error).")
            }
        }
    }
    
    public static func getAccounts(tbUserId:String!,password:String!)-> [TBMyWalletModel]{
        var keyStoreList = [TBMyWalletModel]()
        
        let userKeyPath = __keystorePath  + tbUserId + "/"
        let keyFiles = self.allFilesInPath(path:userKeyPath)
        
        for keyPath in keyFiles {
            let keyJson = FileManager.default.contents(atPath: keyPath)
            guard let jsonString = keyJson else {
                continue
            }
            let keystore = EthereumKeystoreV3(jsonString)
            if let  account = keystore?.addresses?[0] {
                do {
                    if let model = keystore {
                        var name : String
                        let nameKey = __key_name_prefix + account.address
                        if let tmpname = UserDefaults.standard.value(forKey: nameKey) {
                            name = tmpname as! String
                        }else {
                            name = "my wallet"
                        }
                        let tmpKeyStore = TBMyWalletModel.eth(model,name: name)
                        keyStoreList.append(tmpKeyStore)
                    }
                }catch {
                    print("getAccounts err: \(error).")
                    continue
                }
            }
        }
        
        return keyStoreList
    }
        
    
    public static func getGasPrice(chainInfo:TBWCParamType) async->NSDecimalNumber{
        do {
            if let rpcUrl = URL(string: chainInfo.rpcUrls[0])  {
            
                if let provider = await Web3HttpProvider((rpcUrl), network: .Mainnet,keystoreManager:nil){
                    let ethWeh3 = Web3(provider: provider)
                    
                    let gaspriceNum = try await ethWeh3.eth.gasPrice();
                    guard let decimals = Utilities.parseToBigUInt("1",decimals: chainInfo.nativeCurrency.decimals) else { return NSDecimalNumber(value: 0)}
                    
                    let gasString = String(gaspriceNum)
                    let decimasString = String(decimals)

                    let dec_gasprice = NSDecimalNumber(string: gasString)
                    let dec_decimal = NSDecimalNumber(string: decimasString)
                    
                    if dec_decimal.isEqual(to: NSNumber(value: 0)) { return NSDecimalNumber(string: "0") }
                    
                    return dec_gasprice.dividing(by: dec_decimal)
                }
            }
        }catch {
            print("getGasPrice err: \(error).")
        }
        return 0
    }


    
    public static func transaction(toAddress:String,chainInfo:TBWCParamType,account:TBMyWalletModel,password:String!,value:String) async->(hash:String?,error:Error?){
        do {
            switch account {
                case .eth(let keystore,_):
                    
                        if let rpcUrl = URL(string: chainInfo.rpcUrls[0])  {
                            

//                            let privatekey = try keystore.UNSAFE_getPrivateKeyData(password: "", account: account!)
//                            let tmpkeystore =  try EthereumKeystoreV3(privateKey: privatekey,password: "")
                            
                            let keymanager = KeystoreManager.init([keystore])
                            if let provider = await Web3HttpProvider((rpcUrl), network: .Mainnet,keystoreManager:keymanager){
                                
                                let ethWeh3 = Web3(provider: provider)
                                
                                if let fromAddressModel = keystore.addresses?[0]  , let toAddressModel = EthereumAddress.init(toAddress ,type: .normal){
                                    
                                    let chanIdString = self.transform16To10(str:chainInfo.chainId)
                                    let chainId = (chanIdString as NSString).intValue
                                    
                                    
                                    let nonceNum = try await ethWeh3.eth.getTransactionCount(for: fromAddressModel)

                                    


                                    
                                    let gaspriceNum = try await ethWeh3.eth.gasPrice();

                                    var trans = CodableTransaction.init(type: .legacy,
                                                                        to: toAddressModel,
                                                                        nonce: nonceNum,
                                                                        chainID: BigUInt(chainId),
                                                                        value:Utilities.parseToBigUInt(value,decimals: chainInfo.nativeCurrency.decimals)!,
                                                                        gasLimit:BigUInt(210000),
                                                                        gasPrice: gaspriceNum
                                    )
                                    
                                    trans.from = fromAddressModel
                                    ethWeh3.addKeystoreManager(keymanager);
                                    
                                    let web3Wallet = Web3.Web3Wallet(provider: provider, web3: ethWeh3)
                                    _ = try web3Wallet.signTX(transaction: &trans, account: fromAddressModel, password: password)
                                    let res =  try await ethWeh3.eth.send(raw:trans.encode()!);
                                    return (res.hash,nil)
                                }
                        }
                }
            }
        }catch{
            print("transaction err: \(error).")
            return ("",error)
        }
        return ("",fatalError("unkown error"))
    }
    
    
    public static func transform16To10(str :String) -> String {
        if str == "0x" {
            return "0"
        }
        var fStr:String
        if str.hasPrefix("0x") {
            let start = str.index(str.startIndex, offsetBy: 2);
            let str1 = String(str[start...])
            fStr = str1.uppercased()
        }else{
            fStr = str.uppercased()
        }
        var sum: Double = 0
        for i in fStr.utf8 {
            sum = sum * Double(16) + Double(i) - 48
            if i >= 65 {
                sum -= 7
            }
        }
        return String(sum)
    }

    
    
    
    
    static private func currentTimeStr() -> String {
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd_HH:mm:ss"
        return format.string(from:Date(timeIntervalSinceNow: 0))
    }
    
    
    static private func allFilesInPath(path:String) -> [String]{
        
        do{
            let files = try FileManager.default.contentsOfDirectory(atPath: path)
            var resFiles  = [String]()
            for tmpPath in files {
                let fullPath = path + tmpPath
                resFiles.append(fullPath)
            }
            
            self.sortFileArray(sort: &resFiles)
            
            return resFiles
        }catch {
            print("allFilesInPath err: \(error).")

            return []

        }
    }
    
    
    static private func sortFileArray(sort array:inout [String]){
        for i in 0 ..< array.count {
            for j in i + 1 ..< array.count {
                let fullPath = array[i]
                let nextPath = array[j]
                do {
                    if let fileDate = try FileManager.default.attributesOfItem(atPath: fullPath)[.creationDate] as? Date
                    ,let nextDate = try FileManager.default.attributesOfItem(atPath: nextPath)[.creationDate] as? Date,
                       fileDate.compare(nextDate) == .orderedAscending{
                        exchangeValue(&array, i, j)
                    }
                } catch let error as NSError {
                    print("error  \(error)")
                }
            }
        }
    }
    static private func exchangeValue<T>(_ nums:inout [T],_ a:Int,_ b:Int){
        (nums[a],nums[b]) = (nums[b],nums[a])
    }
}


