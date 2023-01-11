

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,






public struct TulsiParameter<T> {

  
  
  public enum Source: Int {
    
    case explicitlyProvided

    
    case options

    
    case project

    
    case fallback

    
    public func isHigherPriorityThan(_ other: Source) -> Bool {
      return self.rawValue < other.rawValue;
    }
  }

  public let value: T
  public let source: Source

  init(value: T, source: Source) {
    self.value = value
    self.source = source
  }

  init?(value: T?, source: Source) {
    guard let value = value else { return nil }
    self.init(value: value, source: source)
  }

  
  public func isHigherPriorityThan(_ other: TulsiParameter<T>) -> Bool {
    return self.source.isHigherPriorityThan(other.source)
  }

  
  
  public func reduce(_ other: TulsiParameter<T>?) -> TulsiParameter<T> {
    if let other = other, other.isHigherPriorityThan(self) {
      return other
    }
    return self
  }
}
