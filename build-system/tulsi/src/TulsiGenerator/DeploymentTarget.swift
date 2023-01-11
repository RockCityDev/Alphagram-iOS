

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Foundation


public enum CPU: String {
  case i386
  case x86_64
  case armv7
  case armv7k
  case arm64
  case arm64e
  case arm64_32
  case sim_arm64

  public static let allCases: [CPU] = [.i386, .x86_64, .armv7, .armv7k, .arm64, .arm64e, .arm64_32, .sim_arm64]

  var isARM: Bool {
    switch self {
    case .i386: return false
    case .x86_64: return false
    case .armv7: return true
    case .armv7k: return true
    case .arm64: return true
    case .arm64e: return true
    case .arm64_32: return true
    case .sim_arm64: return true
    }
  }

  var watchCPU: CPU {
    if PlatformConfiguration.use64BitWatchSimulator {
      return isARM ? .armv7k : .x86_64
    } else {
      return isARM ? .armv7k : .i386
    }
  }
}


public struct PlatformConfiguration {

  
  
  
  
  
  
  
  
  public static var use64BitWatchSimulator = false

  public let platform: PlatformType
  public let cpu: CPU

  
  public static let defaultConfiguration = PlatformConfiguration(platform: .ios, cpu: .x86_64)

  
  public static var allValidConfigurations: [PlatformConfiguration] {
    var platforms = [PlatformConfiguration]()
    for platformType in PlatformType.allCases {
      for cpu in platformType.validCPUs {
        platforms.append(PlatformConfiguration(platform: platformType, cpu: cpu))
      }
    }
    return platforms
  }

  public init(platform: PlatformType, cpu: CPU) {
    self.platform = platform
    self.cpu = cpu
  }

  
  
  public init?(identifier: String) {
    for validConfiguration in PlatformConfiguration.allValidConfigurations {
      if validConfiguration.identifier == identifier {
        self.platform = validConfiguration.platform
        self.cpu = validConfiguration.cpu
        return
      }
    }
    return nil
  }

  
  var identifier: String {
    return "\(platform.bazelPlatform)_\(cpu.rawValue)"
  }
}



public enum PlatformType: String {
  case ios
  case macos
  case tvos
  case watchos

  public static let allCases: [PlatformType] = [.ios, .macos, .tvos, .watchos]

  var validCPUs: Set<CPU> {
    switch self {
    case .ios: return [.i386, .x86_64, .armv7, .arm64, .arm64e, .sim_arm64]
    case .macos: return  [.x86_64, .arm64, .arm64e]
    case .tvos: return [.x86_64, .arm64]
    case .watchos: return [.i386, .x86_64, .armv7k, .arm64_32]
    }
  }

  var bazelCPUPlatform: String {
    switch self {
    case .macos: return "darwin"
    default: return bazelPlatform
    }
  }

  var bazelPlatform: String {
    return rawValue
  }

  var buildSettingsDeploymentTarget: String {
    switch self {
    case .ios: return "IPHONEOS_DEPLOYMENT_TARGET"
    case .macos: return "MACOSX_DEPLOYMENT_TARGET"
    case .tvos: return "TVOS_DEPLOYMENT_TARGET"
    case .watchos: return "WATCHOS_DEPLOYMENT_TARGET"
    }
  }

  var simulatorSDK: String {
    switch self {
    case .ios: return "iphonesimulator"
    case .macos: return "macosx"
    case .tvos: return "appletvsimulator"
    case .watchos: return "watchsimulator"
    }
  }

  var deviceSDK: String {
    switch self {
    case .ios: return "iphoneos"
    case .macos: return "macosx"
    case .tvos: return "appletvos"
    case .watchos: return "watchos"
    }
  }

  var userString: String {
    switch self {
    case .ios: return "iOS"
    case .macos: return "macOS"
    case .tvos: return "tvOS"
    case .watchos: return "watchOS"
    }
  }

  
  func testHostPath(hostTargetPath: String, hostTargetProductName: String) -> String? {
    switch self {
    case .ios: return "$(BUILT_PRODUCTS_DIR)/\(hostTargetPath)/\(hostTargetProductName)"
    case .macos: return "$(BUILT_PRODUCTS_DIR)/\(hostTargetPath)/Contents/MacOS/\(hostTargetProductName)"
    case .tvos: return "$(BUILT_PRODUCTS_DIR)/\(hostTargetPath)/\(hostTargetProductName)"
    case .watchos: return nil
    }
  }
}


public struct DeploymentTarget : Equatable {
  let platform: PlatformType
  let osVersion: String

  public static func ==(lhs: DeploymentTarget, rhs: DeploymentTarget) -> Bool {
    return lhs.platform == rhs.platform && lhs.osVersion == rhs.osVersion
  }
}
