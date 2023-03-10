






import Foundation
import CoreGraphics

protocol Interpolatable {

  func interpolateTo(_ to: Self,
                     amount: CGFloat,
                     spatialOutTangent: CGPoint?,
                     spatialInTangent: CGPoint?) -> Self
  
}
