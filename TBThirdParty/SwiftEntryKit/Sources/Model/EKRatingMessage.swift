







import Foundation

public struct EKRatingMessage {
    
    
    class SelectedIndex {
        var selectedIndex: Int!
    }
    
    
    public typealias Selection = (Int) -> Void

    
    public var initialTitle: EKProperty.LabelContent
    
    
    public var initialDescription: EKProperty.LabelContent
    
    
    public var ratingItems: [EKProperty.EKRatingItemContent]
    
    
    public var buttonBarContent: EKProperty.ButtonBarContent
    
    
    public var selection: Selection!

    let selectedIndexRef = SelectedIndex()
    
    
    public var selectedIndex: Int? {
        get {
            return selectedIndexRef.selectedIndex
        }
        set {
            selectedIndexRef.selectedIndex = newValue
        }
    }
    
    
    public init(initialTitle: EKProperty.LabelContent,
                initialDescription: EKProperty.LabelContent,
                ratingItems: [EKProperty.EKRatingItemContent],
                buttonBarContent: EKProperty.ButtonBarContent,
                selection: Selection? = nil) {
        self.initialTitle = initialTitle
        self.initialDescription = initialDescription
        self.ratingItems = ratingItems
        self.buttonBarContent = buttonBarContent
        self.selection = selection
    }
}
