







import Foundation

public struct EKSimpleMessage {
    
    
    public let image: EKProperty.ImageContent?
    
    
    public let title: EKProperty.LabelContent
    
    
    public let description: EKProperty.LabelContent
        
    public init(image: EKProperty.ImageContent? = nil,
                title: EKProperty.LabelContent,
                description: EKProperty.LabelContent) {
        self.image = image
        self.title = title
        self.description = description
    }
}
