







public struct EKAlertMessage {
    
    public enum ImagePosition {
        case top
        case left
    }
    
    
    public let imagePosition: ImagePosition
    
    
    public let simpleMessage: EKSimpleMessage
    
    
    public let buttonBarContent: EKProperty.ButtonBarContent
    
    public init(simpleMessage: EKSimpleMessage,
                imagePosition: ImagePosition = .top,
                buttonBarContent: EKProperty.ButtonBarContent) {
        self.simpleMessage = simpleMessage
        self.imagePosition = imagePosition
        self.buttonBarContent = buttonBarContent
    }
}
