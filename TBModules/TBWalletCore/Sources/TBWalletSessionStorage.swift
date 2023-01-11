import Foundation
import WalletConnectSwift
import TBStorage
import AccountContext
import SwiftSignalKit
import UIKit
import CryptoKit


struct TBWalletStorageSession: Codable, Equatable {
    
    struct Key: Codable, Equatable {
        let platform: String
        let walletAccountId: String
        static func == (lhs: Key, rhs: Key) -> Bool {
            if lhs.platform != rhs.platform {
                return false
            }
            if lhs.walletAccountId.lowercased() != rhs.walletAccountId.lowercased() {
                return false
            }
            return true
        }
        
    }
    let session: Session
    let key: Key
    
    init(session: Session, key: Key) {
        self.session = session
        self.key = key
    }
    
    static func == (lhs: TBWalletStorageSession, rhs: TBWalletStorageSession) -> Bool {
        
        return lhs.key == rhs.key
    }
}



extension UserDefaults {
    
    
    func getAllSessionList(context:AccountContext, ignorePlatform:TBWalletConnect.Platform = .qrCode) -> [TBWalletStorageSession] {
        let ret = self.tb_data(for: .accountPeerWallletSessionList(peerId: context.account.peerId.id._internalGetInt64Value()))
        if let ret = ret, let sessionList = try? JSONDecoder().decode([TBWalletStorageSession].self, from: ret) {
            return sessionList.filter({$0.key.platform != ignorePlatform.rawValue})
        }
        return [TBWalletStorageSession]()
    }
    

    
    func updateSession(context:AccountContext, platForm:TBWalletConnect.Platform, session:Session, ignorePlatform: TBWalletConnect.Platform = .qrCode){
        if ignorePlatform == platForm {
            return
        }
        guard let updateKey = self.sessionKey(session: session, platfom: platForm) else {
            return
        }
        var sessionList = self.getAllSessionList(context: context).filter({$0.key != updateKey})
        sessionList.append(TBWalletStorageSession(session: session, key: updateKey))
        self.save(context: context, sessionList: sessionList)
    }
    
    
    func getSession(context: AccountContext, key:TBWalletStorageSession.Key) ->TBWalletStorageSession? {
        let sessionList = self.getAllSessionList(context: context)
        for session in sessionList {
            if session.key == key {
                return session
            }
        }
        return nil
    }
    
    func getSessionList(context: AccountContext, platform:TBWalletConnect.Platform) ->[TBWalletStorageSession] {
        var ret = [TBWalletStorageSession]()
        for session in self.getAllSessionList(context: context) {
            if session.key.platform == platform.rawValue {
                ret.append(session)
            }
        }
        return ret
    }
    
    
    func removeSession(context: AccountContext, key:TBWalletStorageSession.Key) {
        let sessionList = self.getAllSessionList(context: context).filter({$0.key != key})
        self.save(context: context, sessionList: sessionList)
    }
    
    
    func removeSession(context:AccountContext, platForm:TBWalletConnect.Platform, session:Session) {
        if let sessionKey = self.sessionKey(session: session, platfom: platForm) {
            self.removeSession(context: context, key: sessionKey)
        }
    }
    
    private func save(context:AccountContext, sessionList:[TBWalletStorageSession]){
        if let sessionListData = try? JSONEncoder().encode(sessionList) {
            self.tb_set(value: sessionListData, for: .accountPeerWallletSessionList(peerId: context.account.peerId.id._internalGetInt64Value()))
        }
    }
    
    private func sessionKey(session:Session, platfom:TBWalletConnect.Platform)-> TBWalletStorageSession.Key? {
        if let accountId = session.walletInfo?.accounts.first {
            return TBWalletStorageSession.Key(platform: platfom.rawValue, walletAccountId: accountId)
        }
        return nil
    }
}
