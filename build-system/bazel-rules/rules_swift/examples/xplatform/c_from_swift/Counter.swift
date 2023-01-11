

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,





import CCounter


public class Counter {

  private let counter: counter_t

  public var value: Int {
    
    return Int(counter_get(counter))
  }

  public init() {
    self.counter = counter_create()
  }

  deinit {
    counter_release(counter)
  }

  public func increment() {
    counter_increment(counter)
  }
}
