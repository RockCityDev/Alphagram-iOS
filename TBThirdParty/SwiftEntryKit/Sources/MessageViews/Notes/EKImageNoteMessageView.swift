






import UIKit

public class EKImageNoteMessageView: EKAccessoryNoteMessageView {
    
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public init(with content: EKProperty.LabelContent, imageContent: EKProperty.ImageContent) {
        super.init(frame: UIScreen.main.bounds)
        setup(with: content, imageContent: imageContent)
    }
    
    private func setup(with content: EKProperty.LabelContent, imageContent: EKProperty.ImageContent) {
        let imageView = UIImageView()
        imageView.imageContent = imageContent
        accessoryView = imageView
        super.setup(with: content)
    }
}
