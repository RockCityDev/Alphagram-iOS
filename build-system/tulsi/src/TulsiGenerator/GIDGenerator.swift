

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,





protocol GIDGeneratorProtocol {
  
  
  
  func generate(_ item: PBXObjectProtocol) -> String
}



final class ConcreteGIDGenerator: GIDGeneratorProtocol {
  
  private var reservedIDS = [String: Int]()

  func generate(_ item: PBXObjectProtocol) -> String {
    let hash = String(format: "%08X%08X", item.isa.hashValue, item.hashValue)
    let counter = reservedIDS[hash] ?? 0
    let gid = String(format: "\(hash)%08X", counter)
    reservedIDS[hash] = counter + 1
    return gid
  }
}
