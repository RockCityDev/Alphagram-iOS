







import UIKit
import JXSegmentedView

open class TBSegmentedNumberItemModel: JXSegmentedNumberItemModel {
    
    open var accessoryBorderWidth: CGFloat = 1.0
    open var accessoryWidthIncrement: CGFloat = 16
    open var accessoryHeight:CGFloat = 34
    
    open var normalAccessoryBorderColor:UIColor = UIColor(rgb: 0xE7E8EB)
    open var normalAccessoryColor:UIColor = .white
    
    open var selectAccessoryBorderColor: UIColor = UIColor(rgb: 0x4B5BFF)
    open var selectAccessoryColor:UIColor = UIColor(rgb: 0x4B5BFF)
    
    open var currentAccessoryBorderColor:UIColor = UIColor(rgb: 0xE7E8EB)
    open var currentAccessoryColor:UIColor = .white
    
}
