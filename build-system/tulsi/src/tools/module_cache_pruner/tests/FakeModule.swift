

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,







struct FakeModule {
  /// The name of the module. e.g. "Foundation"
  let name: String
  /// The filename of the clang module. e.g. "Foundation.swift.pcm"
  let clangName: String
  /// The filename of the swift module. e.g. "Foundation.swiftmodule"
  let swiftName: String
  
  /// e.g. "/private/var/.../bin/buttons/Foundation.swift.pcm"
  let explicitFilepath: String
  /// The filename of the implicit clang module. e.g. "Foundation-ABCDEFGH.pcm"
  
  
  
  let implicitFilename: String

  private static let hashLength = 8
  private static let outputDirectory =
    "/private/var/tmp/_bazel_<user>/<workspace-hash>/execroot/<workspace-name>/bazel-out/ios_x86_64-dbg/bin/buttons"

  init(_ name: String, hashCharacter: String) {
    self.name = name
    self.clangName = "\(name).swift.pcm"
    self.swiftName = "\(name).swiftmodule"
    self.explicitFilepath = "\(FakeModule.outputDirectory)/\(name).swift.pcm"
    self.implicitFilename =
      "\(name)-\(String(repeating: hashCharacter, count: FakeModule.hashLength)).pcm"
  }
}

struct SystemModules {
  let foundation = FakeModule("Foundation", hashCharacter: "A")
  let coreFoundation = FakeModule("CoreFoundation", hashCharacter: "B")
  let darwin = FakeModule("Darwin", hashCharacter: "C")
}

struct UserModules {
  let buttonsLib = FakeModule("ButtonsLib", hashCharacter: "1")
  let buttonsModel = FakeModule("ButtonsModel", hashCharacter: "2")
  let buttonsIdentity = FakeModule("ButtonsIdentity", hashCharacter: "3")
}


struct FakeModules {
  let system = SystemModules()
  let user = UserModules()
}
