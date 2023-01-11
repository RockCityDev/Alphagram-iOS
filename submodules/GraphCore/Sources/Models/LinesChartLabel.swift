







import Foundation
#if os(macOS)
import Cocoa
#else
import UIKit
#endif

struct LinesChartLabel: Hashable {
    let value: CGFloat
    let text: String
}

class AnimatedLinesChartLabels {
    var labels: [LinesChartLabel]
    var isAppearing: Bool = false
    let alphaAnimator: AnimationController<CGFloat>
    
    init(labels: [LinesChartLabel], alphaAnimator: AnimationController<CGFloat>) {
        self.labels = labels
        self.alphaAnimator = alphaAnimator
    }
}
