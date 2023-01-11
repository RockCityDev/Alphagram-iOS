






import CoreGraphics
import Foundation


public final class GradientValueProvider: ValueProvider {

  

  
  public init(
    block: @escaping ColorsValueBlock,
    locations: ColorLocationsBlock? = nil)
  {
    self.block = block
    locationsBlock = locations
    colors = []
    self.locations = []
  }

  
  public init(
    _ colors: [Color],
    locations: [Double] = [])
  {
    self.colors = colors
    self.locations = locations
    updateValueArray()
    hasUpdate = true
  }

  

  
  public typealias ColorsValueBlock = (CGFloat) -> [Color]
  
  public typealias ColorLocationsBlock = (CGFloat) -> [Double]

  
  public var colors: [Color] {
    didSet {
      updateValueArray()
      hasUpdate = true
    }
  }

  
  public var locations: [Double] {
    didSet {
      updateValueArray()
      hasUpdate = true
    }
  }

  

  public var valueType: Any.Type {
    [Double].self
  }

  public var storage: ValueProviderStorage<[Double]> {
    .closure { [self] frame in
      hasUpdate = false

      if let block = block {
        let newColors = block(frame)
        let newLocations = locationsBlock?(frame) ?? []
        value = value(from: newColors, locations: newLocations)
      }

      return value
    }
  }

  public func hasUpdate(frame _: CGFloat) -> Bool {
    if block != nil || locationsBlock != nil {
      return true
    }
    return hasUpdate
  }

  

  private var hasUpdate = true

  private var block: ColorsValueBlock?
  private var locationsBlock: ColorLocationsBlock?
  private var value: [Double] = []

  private func value(from colors: [Color], locations: [Double]) -> [Double] {

    var colorValues = [Double]()
    var alphaValues = [Double]()
    var shouldAddAlphaValues = false

    for i in 0..<colors.count {

      if colors[i].a < 1 { shouldAddAlphaValues = true }

      let location = locations.count > i
        ? locations[i]
        : (Double(i) / Double(colors.count - 1))

      colorValues.append(location)
      colorValues.append(colors[i].r)
      colorValues.append(colors[i].g)
      colorValues.append(colors[i].b)

      alphaValues.append(location)
      alphaValues.append(colors[i].a)
    }

    return colorValues + (shouldAddAlphaValues ? alphaValues : [])
  }

  private func updateValueArray() {
    value = value(from: colors, locations: locations)
  }
}
