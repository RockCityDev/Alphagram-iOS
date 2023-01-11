







import Foundation
import UIKit

public protocol JXSegmentedIndicatorProtocol {
    
    
    
    var isIndicatorConvertToItemFrameEnabled: Bool { get }
    
    
    
    
    
    
    func refreshIndicatorState(model: JXSegmentedIndicatorSelectedParams)

    
    
    
    
    
    
    
    
    func contentScrollViewDidScroll(model: JXSegmentedIndicatorTransitionParams)

    
    
    
    
    
    func selectItem(model: JXSegmentedIndicatorSelectedParams)
}
