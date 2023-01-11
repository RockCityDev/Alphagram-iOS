






import Foundation



public struct Vector1D: Hashable {

  public init(_ value: Double) {
    self.value = value
  }

  public let value: Double

}





public struct Vector3D: Hashable {

  public let x: Double
  public let y: Double
  public let z: Double

  public init(x: Double, y: Double, z: Double) {
    self.x = x
    self.y = y
    self.z = z
  }

}
