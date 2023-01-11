
import Foundation
import UIKit



extension NSMutableString {
    
    public func tb_widthForComment(height: CGFloat = 15) -> CGFloat {
        let rect = self.boundingRect(with: CGSize(width: CGFloat(MAXFLOAT), height: height), options: .usesLineFragmentOrigin, attributes: nil, context: nil)
          return ceil(rect.width)
      }
      
      public func tb_heightForComment(width: CGFloat) -> CGFloat {
          let rect = self.boundingRect(with: CGSize(width: width, height: CGFloat(MAXFLOAT)), options: .usesLineFragmentOrigin, attributes: nil, context: nil)
          return ceil(rect.height)
      }
      
      public func tb_heightForComment(width: CGFloat, maxHeight: CGFloat) -> CGFloat {
          let height = self.tb_heightForComment(width: width)
          return ceil(height)>maxHeight ? maxHeight : ceil(height)
      }
}


extension String {
  public func tb_widthForComment(fontSize: CGFloat, height: CGFloat = 15) -> CGFloat {
        let font = UIFont.systemFont(ofSize: fontSize)
        let rect = NSString(string: self).boundingRect(with: CGSize(width: CGFloat(MAXFLOAT), height: height), options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        return ceil(rect.width)
    }
    
    public func tb_heightForComment(fontSize: CGFloat, width: CGFloat) -> CGFloat {
        let font = UIFont.systemFont(ofSize: fontSize)
        let rect = NSString(string: self).boundingRect(with: CGSize(width: width, height: CGFloat(MAXFLOAT)), options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        return ceil(rect.height)
    }
    
    public func tb_heightForComment(fontSize: CGFloat, width: CGFloat, maxHeight: CGFloat) -> CGFloat {
        let height  = self.tb_heightForComment(fontSize: fontSize, width: width)
        return ceil(height)>maxHeight ? maxHeight : ceil(height)
    }
    
    public func tb_regularExpression(regularExpress: String) -> [String] {
        do {
            let regex = try NSRegularExpression.init(pattern: regularExpress, options: [])
            let matches = regex.matches(in: self, options: [], range: NSRange(location: 0, length: self.count))
            var res: [String] = []
            for item in matches {
                let str = (self as NSString).substring(with: item.range)
                res.append(str)
            }
            return res
        } catch {
            return []
        }
    }
    
    public func tb_replace(regularExpress: String, contentStr: String) -> String {
        do {
            let regrex = try NSRegularExpression.init(pattern: regularExpress, options: [])
            let modified = regrex.stringByReplacingMatches(in: self, options: [], range: NSRange(location: 0, length: self.count), withTemplate: contentStr)
            return modified
        } catch {
            return self
        }
    }
}



