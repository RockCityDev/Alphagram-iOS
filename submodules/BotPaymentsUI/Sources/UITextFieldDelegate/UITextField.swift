






import UIKit

public extension UITextField {

    

    var selectedTextRangeOffsetFromEnd: Int {
        return offset(from: endOfDocument, to: selectedTextRange?.end ?? endOfDocument)
    }

    
    
    func setInitialSelectedTextRange() {
        
        adjustSelectedTextRange(lastOffsetFromEnd: 0) 
    }

    
    
    func updateSelectedTextRange(lastOffsetFromEnd: Int) {
        adjustSelectedTextRange(lastOffsetFromEnd: lastOffsetFromEnd)
    }

    

    
    private func adjustSelectedTextRange(lastOffsetFromEnd: Int) {
        
        if let text = text, text.isEmpty {
            return
        }

        var offsetFromEnd = lastOffsetFromEnd

        
        
        
        if let lastNumberOffsetFromEnd = text?.lastNumberOffsetFromEnd,
            case let shouldOffsetBeAdjusted = lastNumberOffsetFromEnd < offsetFromEnd,
            shouldOffsetBeAdjusted {

            offsetFromEnd = lastNumberOffsetFromEnd
        }

        updateSelectedTextRange(offsetFromEnd: offsetFromEnd)
    }

    
    private func updateSelectedTextRange(offsetFromEnd: Int) {
        if let updatedCursorPosition = position(from: endOfDocument, offset: offsetFromEnd) {
            selectedTextRange = textRange(from: updatedCursorPosition, to: updatedCursorPosition)
        }
    }
}
