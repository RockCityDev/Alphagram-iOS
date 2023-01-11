

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Foundation

if CommandLine.arguments.count == 3 {
  pruneModuleCache(
    moduleCachePath: CommandLine.arguments[1], explicitModuleMetadataFile: CommandLine.arguments[2])
} else {
  print(
    "USAGE: \(CommandLine.arguments[0]) </path/to/ModuleCache> </path/to/explicit/module/metadata.json>"
  )
}
