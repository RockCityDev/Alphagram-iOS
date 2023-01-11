







import UIKit

public extension EKAttributes {
    
    
    enum BackgroundStyle: Equatable {
        
        
        public struct BlurStyle: Equatable {
            
            public static var extra: BlurStyle {
                return BlurStyle(light: .extraLight, dark: .dark)
            }
            
            public static var standard: BlurStyle {
                return BlurStyle(light: .light, dark: .dark)
            }
            
            @available(iOS 10.0, *)
            public static var prominent: BlurStyle {
                return BlurStyle(light: .prominent, dark: .prominent)
            }
            
            public static var dark: BlurStyle {
                return BlurStyle(light: .dark, dark: .dark)
            }
            
            let light: UIBlurEffect.Style
            let dark: UIBlurEffect.Style
            
            public init(style: UIBlurEffect.Style) {
                self.light = style
                self.dark = style
            }
            
            public init(light: UIBlurEffect.Style, dark: UIBlurEffect.Style) {
                self.light = light
                self.dark = dark
            }
            
            
            public func blurStyle(for traits: UITraitCollection,
                                  mode: EKAttributes.DisplayMode) -> UIBlurEffect.Style {
                switch mode {
                case .inferred:
                    if #available(iOS 13, *) {
                        switch traits.userInterfaceStyle {
                        case .light, .unspecified:
                            return light
                        case .dark:
                            return dark
                        @unknown default:
                            return light
                        }
                    } else {
                        return light
                    }
                case .light:
                    return light
                case .dark:
                    return dark
                }
            }
            
            public func blurEffect(for traits: UITraitCollection,
                                   mode: EKAttributes.DisplayMode) -> UIBlurEffect {
                return UIBlurEffect(style: blurStyle(for: traits, mode: mode))
            }
        }
        
        
        public struct Gradient {
            public var colors: [EKColor]
            public var startPoint: CGPoint
            public var endPoint: CGPoint
            
            public init(colors: [EKColor],
                        startPoint: CGPoint,
                        endPoint: CGPoint) {
                self.colors = colors
                self.startPoint = startPoint
                self.endPoint = endPoint
            }
        }
        
        
        case visualEffect(style: BlurStyle)
        
        
        case color(color: EKColor)
        
        
        case gradient(gradient: Gradient)
        
        
        case image(image: UIImage)
        
        
        case clear
        
        
        public static func == (lhs: EKAttributes.BackgroundStyle,
                               rhs: EKAttributes.BackgroundStyle) -> Bool {
            switch (lhs, rhs) {
            case (visualEffect(style: let leftStyle),
                  visualEffect(style: let rightStyle)):
                return leftStyle == rightStyle
            case (color(color: let leftColor),
                  color(color: let rightColor)):
                return leftColor == rightColor
            case (image(image: let leftImage),
                  image(image: let rightImage)):
                return leftImage == rightImage
            case (gradient(gradient: let leftGradient),
                  gradient(gradient: let rightGradient)):
                for (leftColor, rightColor) in zip(leftGradient.colors, rightGradient.colors) {
                    guard leftColor == rightColor else {
                        return false
                    }
                }
                return leftGradient.startPoint == rightGradient.startPoint &&
                       leftGradient.endPoint == rightGradient.endPoint
            case (clear, clear):
                return true
            default:
                return false
            }
        }
    }
}
