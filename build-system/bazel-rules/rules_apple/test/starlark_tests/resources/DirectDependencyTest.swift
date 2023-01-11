

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Foundation
import BasicFramework

public class DirectDependencyTest {
    public init() {}
    public func directDependencyTest() { 
        print("DirectDependencyTest") 
        let framework = BasicFramework()
        framework.HelloWorld()
    }
}
