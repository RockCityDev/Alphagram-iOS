







import UIKit

extension UIApplication {
    
    func set(statusBarStyle: EKAttributes.StatusBar) {
        let appearance = statusBarStyle.appearance
        UIApplication.shared.isStatusBarHidden = !appearance.visible
        UIApplication.shared.statusBarStyle = appearance.style
    }
}
