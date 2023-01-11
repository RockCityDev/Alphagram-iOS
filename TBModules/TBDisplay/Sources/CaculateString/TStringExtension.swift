
import Foundation

public extension String {
    
    func decimalString() -> String {
        return self.count > 0 ? self : "0"
    }
    
    func simpleAddress() -> String {
        if self.count > 13 {
            return self.xSubString(from: 0, to: 5)! + "..." + self.xSubString(from: self.count - 5, to: self.count - 1)!
        }
        return self
    }
    
    
    func xIndex(_ offset: Int) -> String.Index? {
        if self.count > 0, offset <= self.count {
            return self.index(self.startIndex, offsetBy: offset)
        } else {
            return nil
        }
    }
    
    func xSubString(from fIndex: Int, to tIndex: Int) -> String? {
        if fIndex == 0 {
            return self.xSubString(to: tIndex)
        }
        if tIndex <= self.count {
            let fromIndex =  self.xIndex(fIndex)!
            let toIndex = self.xIndex(tIndex)!
            return "\(self[fromIndex ... toIndex])"
        } else {
            return nil
        }
    }
    
    func xSubString(to index: Int) -> String? {
        if index <= self.count {
            return "\(self[self.startIndex ... self.xIndex(index)!])"
        } else {
            return nil
        }
    }
    
    func transform16To10() -> String {
        if self == "0x" {
            return "0"
        }
        var fStr:String
        if self.hasPrefix("0x") {
            let start = self.index(self.startIndex, offsetBy: 2);
            let str1 = String(self[start...])
            fStr = str1.uppercased()
        }else{
            fStr = self.uppercased()
        }
        var sum: Double = 0
        for i in fStr.utf8 {
            sum = sum * Double(16) + Double(i) - 48
            if i >= 65 {
                sum -= 7
            }
        }
        return String(sum)
    }
    
    func decimal(digits: Int) -> String {
        let format = NumberFormatter()
        format.maximumFractionDigits = digits
        return format.string(from: NSDecimalNumber(string: self.decimalString())) ?? ""
    }
}
