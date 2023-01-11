
import Foundation
import TBNetwork

public class TBTrack {
    
    public class func track(_ event: TBTrackEvent.Event, params: [String : String]? = nil) {
        self.sendToServer(event, params: params)
        self.sendToFlurry(event, params: params)
        self.sendToFirebase(event, params: params)
    }
    
    private class func sendToServer(_ event: TBTrackEvent.Event, params: [String : String]? = nil) {
        var fillter = ["key" : event.key, "name" : event.name]
        if let param = params {
            for (key, value) in param {
                fillter[key] = value
            }
        }
        TBNetwork.request(api: "/app/track", paramsFillter: fillter, successHandle: {_,_ in}, failHandle: {_,_ in})
    }
    
    private class func sendToFlurry(_ event: TBTrackEvent.Event, params: [String : String]? = nil) {
        
    }
    
    private class func sendToFirebase(_ event: TBTrackEvent.Event, params: [String : String]? = nil) {
        
    }
    
}
