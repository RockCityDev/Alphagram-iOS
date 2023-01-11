import Foundation
import Flurry_iOS_SDK


private class FlurryDemo {
    
    private func startSessionDemo() {
        func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
            let sb = FlurrySessionBuilder()
                  .build(logLevel: FlurryLogLevel.all)
                  .build(crashReportingEnabled: true)
                  .build(appVersion: "1.0")
                  .build(iapReportingEnabled: true)
              
            Flurry.startSession(apiKey: "YOUR_API_KEY", sessionBuilder: sb)
            return true
        }
    }
    
    private func logEventsDemo_ios_tvos() {
        
        Flurry.log(eventName: "Event", parameters: ["Key": "Value"])
              
        
        Flurry.log(eventName: "Event", parameters: ["Key": "Value"], timed: true)
        Flurry.endTimedEvent(eventName: "Event", parameters: ["Key": "Value"])
              
        
        let param = FlurryParamBuilder()
            .set(doubleVal: 34.99, param: FlurryParamBuilder.totalAmount())
            .set(booleanVal: true, param: FlurryParamBuilder.success())
            .set(stringVal: "book 1", param: FlurryParamBuilder.itemName())
            .set(stringVal: "This is an awesome book to purchase !!!", key: "note")
              
        Flurry.log(standardEvent: FlurryEvent.purchased, param: param)
    }
    
    private func logEventsDemo_watchos() {
        //FlurryWatch.logWatchEvent("Event", withParameters: ["Key": "Value"])
    }
    
    private func logErrorDemo() {
        //Flurry.log(errorId: "ERROR_NAME", message: "ERROR_MESSAGE", exception: e)
    }
    
    private func trackUserDemographicsDemo() {
        Flurry.set(userId: "USER_ID")
        Flurry.set(age: 20)
        Flurry.set(gender: "f") // "f" for female and "m" for male
    }
    
    private func sessionOriginsAndAttributesDemo() {
        Flurry.add(sessionOriginName: "SESSION_ORIGIN")
        Flurry.add(sessionOriginName: "SESSION_ORIGIN", deepLink: "DEEP_LINK")
        Flurry.sessionProperties(["key": "value"])
        Flurry.add(originName: "ORIGIN_NAME", originVersion: "ORIGIN_VERSION")
        Flurry.add(originName: "ORIGIN_NAME", originVersion: "ORIGIN_VERSION", parameters: ["key": "value"])
    }
}


