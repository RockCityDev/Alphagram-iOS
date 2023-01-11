







import UIKit

extension UIImageView {
    func setImage(_ image: UIImage?, animated: Bool) {
        if self.image != image {
            if animated {
                let animation = CATransition()
                animation.timingFunction = CAMediaTimingFunction.init(name: .linear)
                animation.type = .fade
                animation.duration = .defaultDuration
                self.layer.add(animation, forKey: "kCATransitionImageFade")
            }
            self.image = image
        }
    }
}
