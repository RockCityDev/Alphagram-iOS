

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Foundation

public func dontCallMeShared() {
    _ = 0;
}

public func anotherFunctionShared() {
    _ = 0;
}

public func anticipatedDeadCode() {
    _ = 0;
}

public func doSomethingShared() {
    print("Doing something shared")
}

public class Transitives {
    public init() {}
    public func doSomethingShared() { print("Something shared from transitives") }
    public func doSomethingCommon() { print("Something common from transitives") }
}
