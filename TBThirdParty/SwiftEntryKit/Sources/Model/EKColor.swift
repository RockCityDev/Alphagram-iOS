







import UIKit


public struct EKColor: Equatable {
    
    
    
    public private(set) var dark: UIColor
    public private(set) var light: UIColor
    
    
    
    public init(light: UIColor, dark: UIColor) {
        self.light = light
        self.dark = dark
    }
    
    public init(_ unified: UIColor) {
        self.light = unified
        self.dark = unified
    }
    
    public init(rgb: Int) {
        dark = UIColor(rgb: rgb)
        light = UIColor(rgb: rgb)
    }
    
    public init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        let color = UIColor(red: CGFloat(red) / 255.0,
                            green: CGFloat(green) / 255.0,
                            blue: CGFloat(blue) / 255.0,
                            alpha: 1.0)
        light = color
        dark = color
    }
    
    
    public func color(for traits: UITraitCollection,
                      mode: EKAttributes.DisplayMode) -> UIColor {
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
}

public extension EKColor {
    
    
    var inverted: EKColor {
        return EKColor(light: dark, dark: light)
    }
    
    
    func with(alpha: CGFloat) -> EKColor {
        return EKColor(light: light.withAlphaComponent(alpha),
                       dark: dark.withAlphaComponent(alpha))
    }
    
    
    static var white: EKColor {
        return EKColor(.white)
    }
    
    
    static var black: EKColor {
        return EKColor(.black)
    }
    
    
    static var clear: EKColor {
        return EKColor(.clear)
    }
    
    
    static var standardBackground: EKColor {
        return EKColor(light: .white, dark: .black)
    }
    
    
    static var standardContent: EKColor {
        return EKColor(light: .black, dark: .white)
    }
}
