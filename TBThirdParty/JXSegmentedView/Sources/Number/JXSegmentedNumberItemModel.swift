







import Foundation
import UIKit

open class JXSegmentedNumberItemModel: JXSegmentedTitleItemModel {
    open var number: Int = 0
    open var numberString: String = "0"
    open var numberBackgroundColor: UIColor = .red
    open var numberTextColor: UIColor = .white
    open var numberWidthIncrement: CGFloat = 0
    open var numberFont: UIFont = UIFont.systemFont(ofSize: 11)
    open var numberOffset: CGPoint = CGPoint.zero
    open var numberHeight: CGFloat = 14
}
