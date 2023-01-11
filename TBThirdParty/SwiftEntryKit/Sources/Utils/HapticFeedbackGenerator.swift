







import UIKit

struct HapticFeedbackGenerator {
    @available(iOS 10.0, *)
    static func notification(type: EKAttributes.NotificationHapticFeedback) {
        guard let value = type.value else {
            return
        }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(value)
    }
}
