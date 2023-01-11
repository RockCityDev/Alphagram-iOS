





import Foundation

extension String {
    
    
    public var tb_toHexString:String? {
            let data = self.data(using: .utf8)
            guard let data = data else {
                return nil
            }
            let bytes = [Byte](data)
            var hexStr = ""
            for idx in 0..<data.count {
                let newHex = String(format: "%x", bytes[idx]&0xff)
                if newHex.count == 1 {
                    hexStr = String(format: "%@0%@", hexStr,newHex)
                }else{
                    hexStr = hexStr + newHex
                }
            }
            return hexStr
        }
    
    
    
    public typealias Byte = UInt8
    public var tb_hexaToBytes: [Byte] {
            var start = startIndex
            return stride(from: 0, to: count, by: 2).compactMap { _ in   
                let end = index(after: start)
                defer { start = index(after: end) }
                return Byte(self[start...end], radix: 16)
            }
        }
        
        
    public  var tb_hexToString: String {
            return tb_hexaToBytes.map {
                let binary = String($0, radix: 2)
                return repeatElement("0", count: 8-binary.count) + binary
            }.joined()
        }
}
