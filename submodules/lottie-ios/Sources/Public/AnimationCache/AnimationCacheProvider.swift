






import Foundation





public protocol AnimationCacheProvider {

  func animation(forKey: String) -> Animation?

  func setAnimation(_ animation: Animation, forKey: String)

  func clearCache()

}
