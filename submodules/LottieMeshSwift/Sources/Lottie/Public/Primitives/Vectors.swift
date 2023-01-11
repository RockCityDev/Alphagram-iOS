






import Foundation

public struct Vector1D {
  
  public init(_ value: Double) {
    self.value = value
  }
  
  public let value: Double
  
}



public struct Vector3D {
  
  public let x: Double
  public let y: Double
  public let z: Double
  
  public init(x: Double, y: Double, z: Double) {
    self.x = x
    self.y = y
    self.z = z
  }
  
}
