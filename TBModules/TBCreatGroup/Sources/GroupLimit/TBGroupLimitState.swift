import Foundation
import TBAccount
import TBWeb3Core
import TBWalletCore
import TBBusinessNetwork
import TelegramCore
import Postbox

public struct TBGroupLimitState: Equatable {
    
    public struct NoLimit: Equatable {
        public static func ==(lhs: NoLimit, rhs: NoLimit) -> Bool {
            return true
        }
    }
    
    public struct ConditionLimit: Equatable {
        public var chainType: TBWeb3ConfigEntry.Chain?
        public var tokenType: TBWeb3ConfigEntry.Token?
        public var currencyType: TBWeb3ConfigEntry.Chain.Currency? 
        public var address = "" 
        public var tokenId = "" 
        public var minToken = "" 
        public var maxToken = "" 
        
        public static func ==(lhs: ConditionLimit, rhs: ConditionLimit) -> Bool {
            
            if lhs.chainType != rhs.chainType {
                return false
            }
            if lhs.tokenType != rhs.tokenType {
                return false
            }
            if lhs.currencyType != rhs.currencyType {
                return false
            }
            if lhs.address != rhs.address {
                return false
            }
            if lhs.tokenId != rhs.tokenId {
                return false
            }
            if lhs.minToken != rhs.minToken {
                return false
            }
            if lhs.maxToken != rhs.maxToken {
                return false
            }
            
            return true
        }
    }
    
    public struct PayLimit: Equatable {
        
        public var wallet: TBWalletConnect?
        public var chainType: TBWeb3ConfigEntry.Chain?
        public var tokenType: TBWeb3ConfigEntry.Token? 
        public var coinType: TBWeb3ConfigEntry.Chain.Currency?
        public var amount = ""
        public static func ==(lhs: PayLimit, rhs: PayLimit) -> Bool {
            if lhs.wallet?.nameSpace != rhs.wallet?.nameSpace {
                return false
            }
            if lhs.chainType != rhs.chainType {
                return false
            }
            if lhs.tokenType != rhs.tokenType {
                return false
            }
            if lhs.coinType != rhs.coinType {
                return false
            }
            if lhs.amount != rhs.amount {
                return false
            }
            
            return true
        }
    }
    public let config: TBWeb3ConfigEntry
    public var groupLimit: TBWeb3GroupInfoEntry.LimitType
    public var noLimitState: NoLimit
    public var conditionLimitState: ConditionLimit
    public var payLimitState: PayLimit
    public var groupId: Int64
    public var peerId: PeerId?
    
    public static func ==(lhs: TBGroupLimitState, rhs: TBGroupLimitState) -> Bool {
        
        if lhs.groupLimit != rhs.groupLimit {
            return false
        }
        
        if lhs.groupLimit == .noLimit {
            if lhs.noLimitState != rhs.noLimitState {
                return false
            }
        }
        
        if lhs.groupLimit == .conditionLimit {
            if lhs.conditionLimitState != rhs.conditionLimitState {
                return false
            }
        }
        
        if lhs.groupLimit == .payLimit {
            if lhs.payLimitState != rhs.payLimitState {
                return false
            }
        }
        if lhs.peerId != rhs.peerId{
            return false
        }
        if lhs.groupId != rhs.groupId {
            return false
        }
        return true
    }
    
    public init(config: TBWeb3ConfigEntry, limit:TBWeb3GroupInfoEntry.LimitType, groupId:Int64 = 0, peerId:PeerId? = nil){
        self.groupId = groupId
        self.peerId = peerId
        self.config = config
        self.groupLimit = limit
        self.noLimitState = NoLimit()
        
        var initialConditionState = ConditionLimit()
        initialConditionState.chainType = config.chainType.first
        initialConditionState.tokenType = config.tokenType.first
        if let tokenType = initialConditionState.tokenType, tokenType.tokenType() != .erc_721 {
            initialConditionState.currencyType = initialConditionState.chainType?.currency.first
        }
        self.conditionLimitState = initialConditionState
        
        var initialPayLimitState = PayLimit()
        initialPayLimitState.chainType = config.chainType.first
        initialPayLimitState.tokenType = config.tokenType.filter({$0.tokenType() != .erc_721}).first
        initialPayLimitState.coinType = initialConditionState.chainType?.currency.first
        initialPayLimitState.wallet = TBWalletConnectManager.shared.getAllAvailabelConnecttions().first

        self.payLimitState = initialPayLimitState
        
    }
    
}



extension TBGroupLimitState {
    public func currentSelectToken() -> TBWeb3ConfigEntry.Token? {
        switch self.groupLimit {
        case .noLimit:
            return nil
        case .conditionLimit:
            return self.conditionLimitState.tokenType
        case .payLimit:
            return self.payLimitState.tokenType
        }
    }
    
    public func currentSelectChain() -> TBWeb3ConfigEntry.Chain? {
        switch self.groupLimit {
        case .noLimit:
            return nil
        case .conditionLimit:
            return self.conditionLimitState.chainType
        case .payLimit:
            return self.payLimitState.chainType
        }
    }
    
    public func currentSelectCurrency() -> TBWeb3ConfigEntry.Chain.Currency? {
        switch self.groupLimit {
        case .noLimit:
            return nil
        case .conditionLimit:
            return self.conditionLimitState.currencyType
        case .payLimit:
            return self.payLimitState.coinType
        }
    }
}


extension TBGroupLimitState {
    public static func changeSelectToken(_ token: TBWeb3ConfigEntry.Token?, state:TBGroupLimitState) -> TBGroupLimitState {
        var state = state
        switch state.groupLimit {
        case .noLimit:
            break
        case .conditionLimit:
            state.conditionLimitState.tokenType = token
        case .payLimit:
            state.payLimitState.tokenType = token
        }
        return state
    }
    
    public static func changeSelectChain(_ chain: TBWeb3ConfigEntry.Chain?, state:TBGroupLimitState) -> TBGroupLimitState {
        var state = state
        switch state.groupLimit {
        case .noLimit:
            break
        case .conditionLimit:
            state.conditionLimitState.chainType = chain
            state.conditionLimitState.currencyType = chain?.currency.first
        case .payLimit:
            state.payLimitState.chainType = chain
            state.payLimitState.coinType = chain?.currency.first
        }
        return state
    }
    
    public static func changeSelectChainCurrency(_ currency: TBWeb3ConfigEntry.Chain.Currency?, state:TBGroupLimitState) -> TBGroupLimitState {
        var state = state
        switch state.groupLimit {
        case .noLimit:
            break
        case .conditionLimit:
            state.conditionLimitState.currencyType = currency
            break
        case .payLimit:
            state.payLimitState.coinType = currency
        }
        return state
    }
}



extension TBGroupLimitState {
    
    
    public enum CheckResult: Int, Equatable {
        case pass
        case notPass
    }
    
    
    public func checkInfo() -> CheckResult {
        return TBGroupLimitState.checkInfo(state: self)
    }
    
    
    public static func checkInfo(state: TBGroupLimitState) -> CheckResult {
        switch state.groupLimit {
        case .noLimit:
            return .pass
        case .conditionLimit:
            let conditionState = state.conditionLimitState
            
            if conditionState.chainType == nil {
                return .notPass
            }
            
            guard let token = conditionState.tokenType else {
                return .notPass
            }
            
            if token.tokenType() == .erc_721 {
                if conditionState.address.isEmpty {
                    return .notPass
                }
            }else{
                if conditionState.currencyType == nil {
                    return .notPass
                }
                if conditionState.minToken.isEmpty {
                    return .notPass
                }
                
            }
            return .pass
        case .payLimit:
            let payState = state.payLimitState
            
            if payState.wallet == nil {
                return .notPass
            }
            if payState.chainType == nil {
                return .notPass
            }
            if payState.tokenType == nil {
                return .notPass
            }
            if payState.coinType == nil {
                return .notPass
            }
            if payState.amount.isEmpty {
                return .notPass
            }
            return .pass
        }
    }
}


extension TBGroupLimitState {
    
    
    public static func transformFromGroupInfo(_ groupInfo: TBWeb3GroupInfoEntry?, config: TBWeb3ConfigEntry, peerId: PeerId) -> TBGroupLimitState {
        guard let groupInfo = groupInfo else {
            return TBGroupLimitState(config: config, limit: .noLimit, peerId: peerId)
        }
        var ret = TBGroupLimitState(config: config, limit: .transferFrom(int: groupInfo.join_type), groupId: groupInfo.id, peerId: peerId)
        switch ret.groupLimit {
        case .noLimit:
            break
        case .conditionLimit:
            ret = TBGroupLimitState.changeSelectChain(config.getCofigChain(with: Int(groupInfo.chain_id)), state: ret)
            ret = TBGroupLimitState.changeSelectChainCurrency(config.getConfigCurrency(chainId: Int(groupInfo.chain_id), currenyId: Int(groupInfo.currency_id)), state: ret)
            ret  = TBGroupLimitState.changeSelectToken(config.getConfigToken(tokenId: Int(groupInfo.token_id)), state: ret)
            ret.conditionLimitState.address = groupInfo.token_address
            #warning("tokenId, ")
            //ret.conditionLimitState.tokenId = ""  
            ret.conditionLimitState.minToken = groupInfo.amount
        case .payLimit:
            ret = TBGroupLimitState.changeSelectChain(config.getCofigChain(with: Int(groupInfo.chain_id)), state: ret)
            ret = TBGroupLimitState.changeSelectChainCurrency(config.getConfigCurrency(chainId: Int(groupInfo.chain_id), currenyId: Int(groupInfo.currency_id)), state: ret)
            ret  = TBGroupLimitState.changeSelectToken(config.getConfigToken(tokenId: Int(groupInfo.token_id)), state: ret)
            ret.payLimitState.amount = groupInfo.amount
          #warning("wallet")
            ret.payLimitState.wallet = TBWalletConnectManager.shared.availableConnect(byWalletAccount: groupInfo.receipt_account)
        }
        return ret
    }
    
    public static func transform(
        id: String,
        chat_id:String,
        type:TBWeb3Network.UpdateGroupEntry.GType,
        title: String,
        des:String,
        avatar:String,
        avatarData:Data?,
        tags:[TBWeb3GroupInfoEntry.Tag],
        state: TBGroupLimitState? = nil,
        noLimitChainName: String?,
        noLimitChainId: String?) -> TBWeb3Network.UpdateGroupEntry
    {
        guard let state = state else {
            return TBWeb3Network.UpdateGroupEntry(
                id:id,
                chat_id: chat_id,
                type: type,
                title: title,
                des: des,
                avatarData: avatarData)
        }
        
        let join_type = state.groupLimit.transformTo()
        
        let wallet_id: String
        let wallet_name: String
        if let walletConnect = state.payLimitState.wallet, let configWallet = walletConnect.platForm.transform(config: state.config) {
            wallet_id = String(configWallet.id)
            wallet_name = configWallet.name
        }else{
            wallet_id = ""
            wallet_name = ""
        }
       
        let chainId: String
        let chainName: String
        if let chain = state.currentSelectChain() {
            chainId = String(chain.id)
            chainName = chain.name
        }else{
            chainId = noLimitChainId ?? ""
            chainName = noLimitChainName ?? ""
        }
        let tokenId: String
        let tokenName: String
        if let token = state.currentSelectToken() {
            tokenId = String(token.id)
            tokenName = token.name
        }else{
            tokenId = ""
            tokenName = ""
        }
        let currency_id: String
        let currency_name: String
        if let currency = state.currentSelectCurrency() {
            currency_id = String(currency.id)
            currency_name = currency.name
        }else{
            currency_id = ""
            currency_name = ""
        }
        
        let amount: String
        if state.groupLimit == .conditionLimit {
            amount = state.conditionLimitState.minToken
        }else {
            amount = state.payLimitState.amount
        }
        
        let receipt_account = state.payLimitState.wallet?.getAccountId() ?? ""
        
        let retTags = TBWeb3GroupInfoEntry.Tag.transform(tags: tags)
        
        let ret = TBWeb3Network.UpdateGroupEntry(
            id:id,
            chat_id: chat_id,
            type: type,
            title: title,
            des: des,
            join_type: join_type,
            wallet_id: wallet_id,
            wallet_name: wallet_name,
            chain_id: chainId,
            chain_name: chainName,
            token_id: tokenId,
            token_name: tokenName,
            amount: amount,
            currency_id: currency_id,
            currency_name: currency_name,
            token_address: state.conditionLimitState.address,
            receipt_account: receipt_account,
            avatar: avatar,
            avatarData: avatarData,
            tags: retTags)
        return ret
    }
    
}
extension TBWeb3GroupInfoEntry.Tag {
    
    
    public static func transform(tags:[TBWeb3GroupInfoEntry.Tag]) -> [TBWeb3Network.UpdateGroupEntry.Tag] {
        var retTags = [TBWeb3Network.UpdateGroupEntry.Tag]()
        for item in tags {
            let aTag = TBWeb3Network.UpdateGroupEntry.Tag(id: item.id, name: item.name)
            retTags.append(aTag)
        }
        return retTags
    }
}

extension TBWeb3GroupInfoEntry.LimitType {
    
    public func transformTo() -> TBWeb3Network.UpdateGroupEntry.JoinType {
        switch self {
        case .noLimit:
            return .noLimit
        case .conditionLimit:
            return .conditionLimit
        case .payLimit:
            return .payLimit
        }
    }
}
extension TBWalletConnect.Platform {
    
    public func transform() ->TBWeb3ConfigEntry.Wallet.WType {
        switch self {
        case .metaMask:
            return .metamask
        case .imtoken:
            return .im_token
        case .trust:
            return .trust
        case .spot:
            return .spot
        case .tokenpocket:
            return .token_pocket
        case .qrCode:
            return .metamask
        }
    }
    
    
    
    
    public func transform(config:TBWeb3ConfigEntry) -> TBWeb3ConfigEntry.Wallet? {
        return config.getConfigWallet(with: self.transform())
    }
}

