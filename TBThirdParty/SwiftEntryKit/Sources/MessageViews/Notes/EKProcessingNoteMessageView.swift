







import UIKit

public class EKProcessingNoteMessageView: EKAccessoryNoteMessageView {
    
    
    private var activityIndicatorView: UIActivityIndicatorView!
    private var noteMessageView: EKNoteMessageView!
    
    
    public var isProcessing: Bool = true {
        didSet {
            if isProcessing {
                activityIndicatorView.startAnimating()
            } else {
                activityIndicatorView.stopAnimating()
            }
        }
    }
    
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public init(with content: EKProperty.LabelContent, activityIndicator: UIActivityIndicatorView.Style) {
        super.init(frame: UIScreen.main.bounds)
        setup(with: content, activityIndicator: activityIndicator)
    }
    
    private func setup(with content: EKProperty.LabelContent, activityIndicator: UIActivityIndicatorView.Style, setProcessing: Bool = true) {
        activityIndicatorView = UIActivityIndicatorView()
        activityIndicatorView.style = activityIndicator
        isProcessing = setProcessing
        accessoryView = activityIndicatorView
        super.setup(with: content)
    }
}
