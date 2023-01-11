





public struct LottieConfiguration: Hashable {

  public init(
    renderingEngine: RenderingEngineOption = .mainThread,
    decodingStrategy: DecodingStrategy = .codable)
  {
    self.renderingEngine = renderingEngine
    self.decodingStrategy = decodingStrategy
  }

  
  
  public static var shared = LottieConfiguration()

  
  public var renderingEngine: RenderingEngineOption

  
  public var decodingStrategy: DecodingStrategy

}



public enum RenderingEngineOption: Hashable {
  
  
  
  case automatic

  
  case specific(RenderingEngine)

  
  
  
  public static var mainThread: RenderingEngineOption { .specific(.mainThread) }

  
  
  
  public static var coreAnimation: RenderingEngineOption { .specific(.coreAnimation) }
}




public enum RenderingEngine: Hashable {
  
  
  
  case mainThread

  
  
  
  case coreAnimation
}



extension RenderingEngineOption: RawRepresentable, CustomStringConvertible {

  

  public init?(rawValue: String) {
    if rawValue == "Automatic" {
      self = .automatic
    } else if let engine = RenderingEngine(rawValue: rawValue) {
      self = .specific(engine)
    } else {
      return nil
    }
  }

  

  public var rawValue: String {
    switch self {
    case .automatic:
      return "Automatic"
    case .specific(let engine):
      return engine.rawValue
    }
  }

  public var description: String {
    rawValue
  }

}



extension RenderingEngine: RawRepresentable, CustomStringConvertible {

  

  public init?(rawValue: String) {
    switch rawValue {
    case "Main Thread":
      self = .mainThread
    case "Core Animation":
      self = .coreAnimation
    default:
      return nil
    }
  }

  

  public var rawValue: String {
    switch self {
    case .mainThread:
      return "Main Thread"
    case .coreAnimation:
      return "Core Animation"
    }
  }

  public var description: String {
    rawValue
  }
}




public enum DecodingStrategy: Hashable {
  
  case codable

  
  
  
  case dictionaryBased
}
