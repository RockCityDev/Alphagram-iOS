

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Foundation



let bundle = Bundle.main
NSLog("Hello World from \(bundle.bundleIdentifier ?? "<none>")")
NSLog("\nHere is the entire Info.plist dictionary: \(bundle.infoDictionary ?? [:])")
