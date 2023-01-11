






import CoreGraphics
import Foundation

extension Animation {

  
  public typealias DownloadClosure = (Animation?) -> Void

  
  public var duration: TimeInterval {
    Double(endFrame - startFrame) / framerate
  }

  
  public var bounds: CGRect {
    CGRect(x: 0, y: 0, width: width, height: height)
  }

  
  public var size: CGSize {
    CGSize(width: width, height: height)
  }

  

  
  
  /// - Parameter name: The name of the json file without the json extension. EG "StarAnimation"
  
  
  
  
  
  public static func named(
    _ name: String,
    bundle: Bundle = Bundle.main,
    subdirectory: String? = nil,
    animationCache: AnimationCacheProvider? = nil)
    -> Animation?
  {
    
    let cacheKey = bundle.bundlePath + (subdirectory ?? "") + "/" + name

    
    if
      let animationCache = animationCache,
      let animation = animationCache.animation(forKey: cacheKey)
    {
      
      return animation
    }

    do {
      
      guard let json = try bundle.getAnimationData(name, subdirectory: subdirectory) else {
        return nil
      }
      let animation = try Animation.from(data: json)
      animationCache?.setAnimation(animation, forKey: cacheKey)
      return animation
    } catch {
      
      LottieLogger.shared.warn("Error when decoding animation \"\(name)\": \(error)")
      return nil
    }
  }

  
  /// - Parameter filepath: The absolute filepath of the animation to load. EG "/User/Me/starAnimation.json"
  
  
  
  public static func filepath(
    _ filepath: String,
    animationCache: AnimationCacheProvider? = nil)
    -> Animation?
  {

    
    if
      let animationCache = animationCache,
      let animation = animationCache.animation(forKey: filepath)
    {
      return animation
    }

    do {
      
      let json = try Data(contentsOf: URL(fileURLWithPath: filepath))
      let animation = try Animation.from(data: json)
      animationCache?.setAnimation(animation, forKey: filepath)
      return animation
    } catch {
      
      return nil
    }
  }

  
  ///    - Parameter name: The name of the json file in the asset catalog. EG "StarAnimation"
  
  
  
  public static func asset(
    _ name: String,
    bundle: Bundle = Bundle.main,
    animationCache: AnimationCacheProvider? = nil)
    -> Animation?
  {
    
    let cacheKey = bundle.bundlePath + "/" + name

    
    if
      let animationCache = animationCache,
      let animation = animationCache.animation(forKey: cacheKey)
    {
      
      return animation
    }

    
    guard let json = Data.jsonData(from: name, in: bundle) else {
      return nil
    }

    do {
      
      let animation = try Animation.from(data: json)
      animationCache?.setAnimation(animation, forKey: cacheKey)
      return animation
    } catch {
      
      return nil
    }
  }

  
  
  
  
  
  
  public static func from(
    data: Data,
    strategy: DecodingStrategy = LottieConfiguration.shared.decodingStrategy) throws
    -> Animation
  {
    switch strategy {
    case .codable:
      return try JSONDecoder().decode(Animation.self, from: data)
    case .dictionaryBased:
      let json = try JSONSerialization.jsonObject(with: data)
      guard let dict = json as? [String: Any] else {
        throw InitializableError.invalidInput
      }
      return try Animation(dictionary: dict)
    }
  }

  
  
  
  
  
  
  public static func loadedFrom(
    url: URL,
    closure: @escaping Animation.DownloadClosure,
    animationCache: AnimationCacheProvider?)
  {

    if let animationCache = animationCache, let animation = animationCache.animation(forKey: url.absoluteString) {
      closure(animation)
    } else {
      let task = URLSession.shared.dataTask(with: url) { data, _, error in
        guard error == nil, let jsonData = data else {
          DispatchQueue.main.async {
            closure(nil)
          }
          return
        }
        do {
          let animation = try Animation.from(data: jsonData)
          DispatchQueue.main.async {
            animationCache?.setAnimation(animation, forKey: url.absoluteString)
            closure(animation)
          }
        } catch {
          DispatchQueue.main.async {
            closure(nil)
          }
        }

      }
      task.resume()
    }
  }

  

  
  
  
  
  
  
  
  
  public func progressTime(forMarker named: String) -> AnimationProgressTime? {
    guard let markers = markerMap, let marker = markers[named] else {
      return nil
    }
    return progressTime(forFrame: marker.frameTime)
  }

  
  
  
  
  
  
  
  
  public func frameTime(forMarker named: String) -> AnimationFrameTime? {
    guard let markers = markerMap, let marker = markers[named] else {
      return nil
    }
    return marker.frameTime
  }

  
  
  public func progressTime(
    forFrame frameTime: AnimationFrameTime,
    clamped: Bool = true)
    -> AnimationProgressTime
  {
    let progressTime = ((frameTime - startFrame) / (endFrame - startFrame))

    if clamped {
      return progressTime.clamp(0, 1)
    } else {
      return progressTime
    }
  }

  
  public func frameTime(forProgress progressTime: AnimationProgressTime) -> AnimationFrameTime {
    ((endFrame - startFrame) * progressTime) + startFrame
  }

  
  public func time(forFrame frameTime: AnimationFrameTime) -> TimeInterval {
    Double(frameTime - startFrame) / framerate
  }

  
  public func frameTime(forTime time: TimeInterval) -> AnimationFrameTime {
    CGFloat(time * framerate) + startFrame
  }
}
