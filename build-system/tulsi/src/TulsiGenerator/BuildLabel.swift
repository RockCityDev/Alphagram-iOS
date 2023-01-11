

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Foundation


public class BuildLabel: Comparable, Equatable, Hashable, CustomStringConvertible {
  public let value: String

  public lazy var targetName: String? = { [unowned self] in
    let components = self.value.components(separatedBy: ":")
    if components.count > 1 {
      return components.last
    }

    let lastPackageComponent = self.value.components(separatedBy: "/").last!
    if lastPackageComponent.isEmpty {
      return nil
    }
    return lastPackageComponent
  }()

  public lazy var packageName: String? = { [unowned self] in
    guard var package = self.value.components(separatedBy: ":").first else {
      return nil
    }

    if package.hasPrefix("//") {
      package.removeSubrange(package.startIndex ..< package.index(package.startIndex, offsetBy: 2))
    }
    if package.isEmpty || package.hasSuffix("/") {
      return ""
    }
    return package
  }()

  public lazy var asFileName: String? = { [unowned self] in
    guard var package = self.packageName, let target = self.targetName else {
      return nil
    }
    
    
    if package.starts(with: "@") {
      package = "external/" + 
        package.suffix(from: package.index(package.startIndex, offsetBy: 1)) 
          .replacingOccurrences(of: "//", with: "/") 
    }
    return "\(package)/\(target)"
  }()

  public lazy var asFullPBXTargetName: String? = { [unowned self] in
    guard let package = self.packageName, let target = self.targetName else {
      return nil
    }
    
    
    return "\(package)/\(target)".replacingOccurrences(of: "/", with: "-")
  }()

  public lazy var hashValue: Int = { [unowned self] in
    return self.value.hashValue
  }()

  public init(_ label: String, normalize: Bool = false) {
    var value = label
    if normalize && !value.hasPrefix("//") {
      value = "//\(value)"
    }
    self.value = value
  }

  

  public var description: String {
    return self.value
  }
}



public func <(lhs: BuildLabel, rhs: BuildLabel) -> Bool {
  return lhs.value < rhs.value
}



public func ==(lhs: BuildLabel, rhs: BuildLabel) -> Bool {
  return lhs.value == rhs.value
}
