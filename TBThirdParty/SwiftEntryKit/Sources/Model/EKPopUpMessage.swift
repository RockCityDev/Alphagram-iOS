







import UIKit

public struct EKPopUpMessage {
    
    
    public typealias EKPopUpMessageAction = () -> ()
    
    
    public struct ThemeImage {
        
        
        public enum Position {
            case topToTop(offset: CGFloat)
            case centerToTop(offset: CGFloat)
        }
        
        
        public var image: EKProperty.ImageContent
        
        
        public var position: Position
        
        
        public init(image: EKProperty.ImageContent,
                    position: Position = .topToTop(offset: 40)) {
            self.image = image
            self.position = position
        }
    }
    
    public var themeImage: ThemeImage?
    public var title: EKProperty.LabelContent
    public var description: EKProperty.LabelContent
    public var button: EKProperty.ButtonContent
    public var action: EKPopUpMessageAction
    
    var containsImage: Bool {
        return themeImage != nil
    }
    
    public init(themeImage: ThemeImage? = nil,
                title: EKProperty.LabelContent,
                description: EKProperty.LabelContent,
                button: EKProperty.ButtonContent,
                action: @escaping EKPopUpMessageAction) {
        self.themeImage = themeImage
        self.title = title
        self.description = description
        self.button = button
        self.action = action
    }
}
