







import Foundation
import UIKit

public struct JXSegmentedIndicatorSelectedParams {
    public let currentSelectedIndex: Int
    public let currentSelectedItemFrame: CGRect
    public let selectedType: JXSegmentedViewItemSelectedType
    public let currentItemContentWidth: CGFloat
    
    public var collectionViewContentSize: CGSize?

    public init(currentSelectedIndex: Int, currentSelectedItemFrame: CGRect, selectedType: JXSegmentedViewItemSelectedType, currentItemContentWidth: CGFloat, collectionViewContentSize: CGSize?) {
        self.currentSelectedIndex = currentSelectedIndex
        self.currentSelectedItemFrame = currentSelectedItemFrame
        self.selectedType = selectedType
        self.currentItemContentWidth = currentItemContentWidth
        self.collectionViewContentSize = collectionViewContentSize
    }
}

public struct JXSegmentedIndicatorTransitionParams {
    public let currentSelectedIndex: Int
    public let leftIndex: Int
    public let leftItemFrame: CGRect
    public let rightIndex: Int
    public let rightItemFrame: CGRect
    public let leftItemContentWidth: CGFloat
    public let rightItemContentWidth: CGFloat
    public let percent: CGFloat

    public init(currentSelectedIndex: Int, leftIndex: Int, leftItemFrame: CGRect, leftItemContentWidth: CGFloat, rightIndex: Int, rightItemFrame: CGRect, rightItemContentWidth: CGFloat, percent: CGFloat) {
        self.currentSelectedIndex = currentSelectedIndex
        self.leftIndex = leftIndex
        self.leftItemFrame = leftItemFrame
        self.leftItemContentWidth = leftItemContentWidth
        self.rightIndex = rightIndex
        self.rightItemFrame = rightItemFrame
        self.rightItemContentWidth = rightItemContentWidth
        self.percent = percent
    }
}
