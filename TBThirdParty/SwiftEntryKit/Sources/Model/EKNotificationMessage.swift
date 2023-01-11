







import UIKit

public struct EKNotificationMessage {
    
    
    public struct Insets {
        
        
        public var contentInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        
        
        public var titleToDescription: CGFloat = 5
        
        public static var `default` = Insets()
    }
    
    
    public let simpleMessage: EKSimpleMessage
    
    
    public let auxiliary: EKProperty.LabelContent?
    
    
    public let insets: Insets
        
    public init(simpleMessage: EKSimpleMessage,
                auxiliary: EKProperty.LabelContent? = nil,
                insets: Insets = .default) {
        self.simpleMessage = simpleMessage
        self.auxiliary = auxiliary
        self.insets = insets
    }
}
