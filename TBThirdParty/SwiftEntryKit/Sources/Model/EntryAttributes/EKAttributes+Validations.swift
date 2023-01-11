






import Foundation

extension EKAttributes {
    
    private static var minDisplayDuration: DisplayDuration {
        return 0
    }
    
    var validateDisplayDuration: Bool {
        guard displayDuration >= EKAttributes.minDisplayDuration else {
            return false
        }
        return true
    }
    
    var validateWindowLevel: Bool {
        return windowLevel.value >= .normal
    }
    
    var isValid: Bool {
        return validateDisplayDuration && validateWindowLevel
    }
}
