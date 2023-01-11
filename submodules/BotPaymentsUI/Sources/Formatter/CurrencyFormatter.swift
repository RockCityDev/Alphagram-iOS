






import Foundation

import TelegramStringFormatting



public protocol CurrencyFormatting {
    var maxDigitsCount: Int { get }
    var decimalDigits: Int { get set }
    var maxValue: Double? { get set }
    var minValue: Double? { get set }
    var initialText: String { get }
    var currencySymbol: String { get set }
    
    func string(from double: Double) -> String?
    func unformatted(string: String) -> String?
    func double(from string: String) -> Double?
}

public protocol CurrencyAdjusting {
    func formattedStringWithAdjustedDecimalSeparator(from string: String) -> String?
    func formattedStringAdjustedToFitAllowedValues(from string: String) -> String?
}



public class CurrencyFormatter: CurrencyFormatting {
    
    
    
    
    public var locale: LocaleConvertible {
        set { self.numberFormatter.locale = newValue.locale }
        get { self.numberFormatter.locale }
    }
    
    
    
    
    
    
    
    public var currency: Currency {
        set { numberFormatter.currencyCode = newValue.rawValue }
        get { Currency(rawValue: numberFormatter.currencyCode) ?? .dollar }
    }
    
    
    
    public var showCurrencySymbol: Bool = true {
        didSet {
            numberFormatter.currencySymbol = showCurrencySymbol ? numberFormatter.currencySymbol : ""
        }
    }
    
    
    
    
    
    public var currencySymbol: String {
        set {
            guard showCurrencySymbol else { return }
            numberFormatter.currencySymbol = newValue
        }
        get { numberFormatter.currencySymbol }
    }
    
    
    
    
    public var minValue: Double? {
        set {
            guard let newValue = newValue else { return }
            numberFormatter.minimum = NSNumber(value: newValue)
        }
        get {
            if let minValue = numberFormatter.minimum {
                return Double(truncating: minValue)
            }
            return nil
        }
    }
    
    
    
    
    public var maxValue: Double? {
        set {
            guard let newValue = newValue else { return }
            numberFormatter.maximum = NSNumber(value: newValue)
        }
        get {
            if let maxValue = numberFormatter.maximum {
                return Double(truncating: maxValue)
            }
            return nil
        }
    }
    
    
    
    /// * Example: With decimal digits set to 3, if the value to represent is "1",
    /// the formatted text in the fractions will be ",001".
    /// Other than that with the value as 1, the formatted text fractions will be ",1".
    public var decimalDigits: Int {
        set {
            numberFormatter.minimumFractionDigits = newValue
            numberFormatter.maximumFractionDigits = newValue
        }
        get { numberFormatter.minimumFractionDigits }
    }
    
    
    
    
    
    
    
    
    public var hasDecimals: Bool {
        set {
            self.decimalDigits = newValue ? 2 : 0
            self.numberFormatter.alwaysShowsDecimalSeparator = newValue ? true : false
        }
        get { decimalDigits != 0 }
    }
    
    
    
    
    public var decimalSeparator: String {
        set { self.numberFormatter.currencyDecimalSeparator = newValue }
        get { numberFormatter.currencyDecimalSeparator }
    }
    
    
    public var currencyCode: String {
        set { self.numberFormatter.currencyCode = newValue }
        get { numberFormatter.currencyCode }
    }
    
    
    
    public var alwaysShowsDecimalSeparator: Bool {
        set { self.numberFormatter.alwaysShowsDecimalSeparator = newValue }
        get { numberFormatter.alwaysShowsDecimalSeparator }
    }
    
    
    
    
    public var groupingSize: Int {
        set { self.numberFormatter.groupingSize = newValue }
        get { numberFormatter.groupingSize }
    }
    
    
    
    
    
    
    public var secondaryGroupingSize: Int {
        set { self.numberFormatter.secondaryGroupingSize = newValue }
        get { numberFormatter.secondaryGroupingSize }
    }
    
    
    
    /// separator == "." is represented as `1.000` *.
    
    public var groupingSeparator: String {
        set {
            self.numberFormatter.currencyGroupingSeparator = newValue
            self.numberFormatter.usesGroupingSeparator = true
        }
        get { self.numberFormatter.currencyGroupingSeparator }
    }
    
    
    
    /// is represented by tight numbers "1000000". Otherwise if set
    
    
    public var hasGroupingSeparator: Bool {
        set { self.numberFormatter.usesGroupingSeparator = newValue }
        get { self.numberFormatter.usesGroupingSeparator }
    }
    
    
    
    public var zeroSymbol: String? {
        set { numberFormatter.zeroSymbol = newValue }
        get { numberFormatter.zeroSymbol }
    }
    
    
    /// is empty. The default is "" - empty string
    public var nilSymbol: String {
        set { numberFormatter.nilSymbol = newValue }
        get { return numberFormatter.nilSymbol }
    }
    
    
    let numberFormatter: NumberFormatter
    
    
    public var maxIntegers: Int? {
        set {
            guard let maxIntegers = newValue else { return }
            numberFormatter.maximumIntegerDigits = maxIntegers
        }
        get { return numberFormatter.maximumIntegerDigits }
    }
    
    
    public var maxDigitsCount: Int {
        numberFormatter.maximumIntegerDigits + numberFormatter.maximumFractionDigits
    }
    
    
    public var initialText: String {
        numberFormatter.string(from: 0) ?? "0.0"
    }
    
    
    
    
    public typealias InitHandler = ((CurrencyFormatter) -> (Void))
    
    
    
    

    public init(currency: String, _ handler: InitHandler? = nil) {
        numberFormatter = setupCurrencyNumberFormatter(currency: currency)

        numberFormatter.alwaysShowsDecimalSeparator = false
        
        
        handler?(self)
    }
}


extension CurrencyFormatter {
    
    
    
    
    
    public func string(from double: Double) -> String? {
        let validValue = valueAdjustedToFitAllowedValues(from: double)
        return numberFormatter.string(from: validValue)
    }
    
    
    
    
    
    public func double(from string: String) -> Double? {
        Double(string)
    }
    
    
    
    
    
    
    public func unformatted(string: String) -> String? {
        string.numeralFormat()
    }
}



extension CurrencyFormatter: CurrencyAdjusting {

    
    
    
    /// E.g. "$ 23.24" after users taps an additional number, is equal = "$ 23.247".
    /// Which gets updated to "$ 232.47".
    
    
    
    public func formattedStringWithAdjustedDecimalSeparator(from string: String) -> String? {
        let adjustedString = numeralStringWithAdjustedDecimalSeparator(from: string)
        guard let value = double(from: adjustedString) else { return nil }

        return self.numberFormatter.string(from: value)
    }

    
    
    
    
    public func formattedStringAdjustedToFitAllowedValues(from string: String) -> String? {
        let adjustedString = numeralStringWithAdjustedDecimalSeparator(from: string)
        guard let originalValue = double(from: adjustedString) else { return nil }

        return self.string(from: originalValue)
    }

    
    
    /// E.g. "$ 23.24", after users taps an additional number, get equal as "$ 23.247". The returned value would be "232.47".
    
    
    
    private func numeralStringWithAdjustedDecimalSeparator(from string: String) -> String {
        var updatedString = string.numeralFormat()
        let isNegative: Bool = string.contains(String.negativeSymbol)

        updatedString = isNegative ? .negativeSymbol + updatedString : updatedString
        updatedString.updateDecimalSeparator(decimalDigits: decimalDigits)

        return updatedString
    }

    
    
    
    
    
    private func valueAdjustedToFitAllowedValues(from value: Double) -> Double {
        if let minValue = minValue, value < minValue {
            return minValue
        } else if let maxValue = maxValue, value > maxValue {
            return maxValue
        }

        return value
    }
}
