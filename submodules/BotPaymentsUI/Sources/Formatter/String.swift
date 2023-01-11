







import Foundation

public protocol CurrencyString {
    var representsZero: Bool { get }
    var hasNumbers: Bool { get }
    var lastNumberOffsetFromEnd: Int? { get }
    func numeralFormat() -> String
    mutating func updateDecimalSeparator(decimalDigits: Int)
}


extension String: CurrencyString {

    
    
    
    public var representsZero: Bool {
        return numeralFormat().replacingOccurrences(of: "0", with: "").count == 0
    }
    
    
    public var hasNumbers: Bool {
        return numeralFormat().count > 0
    }

    
    /// e.g. For the String "123some", the last number position is 4, because from the _end index_ to the index of _3_
    /// there is an offset of 4, "e, m, o and s".
    public var lastNumberOffsetFromEnd: Int? {
        guard let indexOfLastNumber = lastIndex(where: { $0.isNumber }) else { return nil }
        let indexAfterLastNumber = index(after: indexOfLastNumber)
        return distance(from: endIndex, to: indexAfterLastNumber)
    }

    
    
    
    
    
    
    public mutating func updateDecimalSeparator(decimalDigits: Int) {
        guard decimalDigits != 0 && count >= decimalDigits else { return }
        let decimalsRange = index(endIndex, offsetBy: -decimalDigits)..<endIndex
        
        let decimalChars = self[decimalsRange]
        replaceSubrange(decimalsRange, with: "." + decimalChars)
    }
    
    
    
    
    public func numeralFormat() -> String {
        return replacingOccurrences(of:"[^0-9]", with: "", options: .regularExpression)
    }
}



extension String {
    public static let negativeSymbol = "-"
}
