


import QuartzCore

extension CGColor {
  
  static func rgb(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat) -> CGColor {
    if #available(iOS 13.0, tvOS 13.0, macOS 10.5, *) {
      return CGColor(red: red, green: green, blue: blue, alpha: 1)
    } else {
      return CGColor(
        colorSpace: CGColorSpaceCreateDeviceRGB(),
        components: [red, green, blue])!
    }
  }

  
  static func rgba(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat) -> CGColor {
    CGColor.rgb(red, green, blue).copy(alpha: alpha)!
  }
}
