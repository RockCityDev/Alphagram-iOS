

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,








// NOTE: Do not run this target using "bazel run". Instead, build it and then



import Dispatch
#if os(Linux)
import Glibc
#else
import Darwin
#endif

extension DispatchQueue {
  
  
  
  
  
  
  
  
  
  
  
  func asyncAfter(
    deadline: DispatchTime,
    group: DispatchGroup,
    execute work: @escaping () -> Void
  ) {
    group.enter()
    asyncAfter(deadline: deadline) {
      work()
      group.leave()
    }
  }
}

let mainQueue = DispatchQueue.main
let group = DispatchGroup()



for (index, argument) in CommandLine.arguments.enumerated() {
  mainQueue.asyncAfter(deadline: .now() + .seconds(index), group: group) {
    print("Hello, \(argument)!")
  }
}




group.notify(queue: mainQueue) {
  print("Goodbye!")
  exit(0)
}



dispatchMain()
