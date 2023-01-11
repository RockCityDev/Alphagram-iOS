
import Foundation

public extension NSDecimalNumber {
    convenience init(string: String, base: Int) {
        guard base >= 2 && base <= 16 else { fatalError("Invalid base") }
        let digits = "0123456789ABCDEF"
        let baseNum = NSDecimalNumber(value: base)
        var res = NSDecimalNumber(value: 0)
        for ch in string {
            let index = digits.firstIndex(of: ch)!
            let digit = digits.distance(from: digits.startIndex, to: index)
            res = res.multiplying(by: baseNum).adding(NSDecimalNumber(value: digit))
        }
        self.init(decimal: res.decimalValue)
    }

    func toBase(_ base: Int) -> String {
        guard base >= 2 && base <= 16 else { fatalError("Invalid base") }
        let digits = "0123456789ABCDEF"
        let rounding = NSDecimalNumberHandler(roundingMode: .down, scale: 0, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)
        let baseNum = NSDecimalNumber(value: base)
        var res = ""
        var val = self
        while val.compare(0) == .orderedDescending {
            let next = val.dividing(by: baseNum, withBehavior: rounding)
            let round = next.multiplying(by: baseNum)
            let diff = val.subtracting(round)
            let digit = diff.intValue
            let index = digits.index(digits.startIndex, offsetBy: digit)
            res.insert(digits[index], at: res.startIndex)
            val = next
        }
        return res
    }
}


public func km_transfrom(number: NSDecimalNumber, maximumFractionDigits: Int = 2) -> String {
    let formatter = NumberFormatter()
    formatter.maximumFractionDigits = maximumFractionDigits
    let kNumber = NSDecimalNumber(decimal: pow(10, 3))
    if number.compare(kNumber) == .orderedAscending {
        return formatter.string(from: number) ?? "0"
    }
    let mNumber = NSDecimalNumber(decimal: pow(10, 6))
    if number.compare(mNumber) == .orderedAscending {
        return (formatter.string(from: number.dividing(by: kNumber)) ?? "0") + "k"
    }
    return (formatter.string(from: number.dividing(by: mNumber)) ?? "0") + "m"
}
