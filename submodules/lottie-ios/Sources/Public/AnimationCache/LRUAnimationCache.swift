






import Foundation





public class LRUAnimationCache: AnimationCacheProvider {

  

  public init() { }

  

  
  public static let sharedCache = LRUAnimationCache()

  
  public var cacheSize = 100

  
  public func clearCache() {
    cacheMap.removeAll()
    lruList.removeAll()
  }

  public func animation(forKey: String) -> Animation? {
    guard let animation = cacheMap[forKey] else {
      return nil
    }
    if let index = lruList.firstIndex(of: forKey) {
      lruList.remove(at: index)
      lruList.append(forKey)
    }
    return animation
  }

  public func setAnimation(_ animation: Animation, forKey: String) {
    cacheMap[forKey] = animation
    lruList.append(forKey)
    if lruList.count > cacheSize {
      let removed = lruList.remove(at: 0)
      if removed != forKey {
        cacheMap[removed] = nil
      }
    }
  }

  

  fileprivate var cacheMap: [String: Animation] = [:]
  fileprivate var lruList: [String] = []

}
