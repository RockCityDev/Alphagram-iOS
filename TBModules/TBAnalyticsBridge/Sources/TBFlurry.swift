import Foundation
import Flurry_iOS_SDK
import AccountContext

public class TBFlurry {
    public static let appKey = "QPDRY5HXHGQ9D4HDBHV8"
    public static let shared = TBFlurry()
    init() {
    }
    public func startMonitor() {
        
        let info = Bundle.main.infoDictionary
        let appVersion = info?["CFBundleShortVersionString"] as? String ?? "Unknown"
        
        let sessionBuilder = FlurrySessionBuilder()
            .build(logLevel: FlurryLogLevel.all)
            .build(crashReportingEnabled: true)
            .build(appVersion: appVersion)
            .build(iapReportingEnabled: true)
#if DEBUG
        
#else
        Flurry.startSession(apiKey:TBFlurry.appKey, sessionBuilder: sessionBuilder)
#endif
        
    }
    
    public func setUserId(_ userId: String) {
        Flurry.set(userId: userId)
    }
}

