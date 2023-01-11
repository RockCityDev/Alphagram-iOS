

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Foundation
import BasicFramework
import DirectDependencyTest

public class TransitiveDependencyTest {
    public init() {}
    public func TransitiveDependencyTest() { 
        print("TransitiveDependencyTest") 
        let framework = BasicFramework()
        framework.HelloWorld()
        let framework2 = DirectDependencyTest()
        framework2.directDependencyTest()
    }
}
