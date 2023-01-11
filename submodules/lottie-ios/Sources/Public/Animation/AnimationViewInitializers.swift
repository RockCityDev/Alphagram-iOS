






import Foundation

extension AnimationView {

  

  
  
  
  
  
  
  
  
  public convenience init(
    name: String,
    bundle: Bundle = Bundle.main,
    imageProvider: AnimationImageProvider? = nil,
    animationCache: AnimationCacheProvider? = LRUAnimationCache.sharedCache)
  {
    let animation = Animation.named(name, bundle: bundle, subdirectory: nil, animationCache: animationCache)
    let provider = imageProvider ?? BundleImageProvider(bundle: bundle, searchPath: nil)
    self.init(animation: animation, imageProvider: provider)
  }

  
  
  
  
  
  public convenience init(
    filePath: String,
    imageProvider: AnimationImageProvider? = nil,
    animationCache: AnimationCacheProvider? = LRUAnimationCache.sharedCache)
  {
    let animation = Animation.filepath(filePath, animationCache: animationCache)
    let provider = imageProvider ??
      FilepathImageProvider(filepath: URL(fileURLWithPath: filePath).deletingLastPathComponent().path)
    self.init(animation: animation, imageProvider: provider)
  }

  
  
  
  
  
  
  public convenience init(
    url: URL,
    imageProvider: AnimationImageProvider? = nil,
    closure: @escaping AnimationView.DownloadClosure,
    animationCache: AnimationCacheProvider? = LRUAnimationCache.sharedCache)
  {

    if let animationCache = animationCache, let animation = animationCache.animation(forKey: url.absoluteString) {
      self.init(animation: animation, imageProvider: imageProvider)
      closure(nil)
    } else {

      self.init(animation: nil, imageProvider: imageProvider)

      Animation.loadedFrom(url: url, closure: { animation in
        if let animation = animation {
          self.animation = animation
          closure(nil)
        } else {
          closure(LottieDownloadError.downloadFailed)
        }
      }, animationCache: animationCache)
    }
  }

  
  
  
  
  
  
  public convenience init(
    asset name: String,
    bundle: Bundle = Bundle.main,
    imageProvider: AnimationImageProvider? = nil,
    animationCache: AnimationCacheProvider? = LRUAnimationCache.sharedCache)
  {
    let animation = Animation.asset(name, bundle: bundle, animationCache: animationCache)
    let provider = imageProvider ?? BundleImageProvider(bundle: bundle, searchPath: nil)
    self.init(animation: animation, imageProvider: provider)
  }

  

  public typealias DownloadClosure = (Error?) -> Void

}



enum LottieDownloadError: Error {
  case downloadFailed
}
