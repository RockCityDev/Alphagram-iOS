

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,











extension PlatformConfiguration {
  public var bazelFlags: [String] {
    var flags = ["--apple_platform_type=\(platform.bazelPlatform)"]
    let physicalWatchCPUs = "\(CPU.armv7k.rawValue),\(CPU.arm64_32.rawValue)"

    switch platform {
    case .ios, .macos:
      flags.append("--cpu=\(platform.bazelCPUPlatform)_\(cpu.rawValue)")
    case .tvos:
      flags.append("--\(platform.bazelCPUPlatform)_cpus=\(cpu.rawValue)")
    case .watchos:
      if (cpu == .armv7k || cpu == .arm64_32) {
        
        
        flags.append("--\(platform.bazelCPUPlatform)_cpus=\(physicalWatchCPUs)")
      } else {
        flags.append("--\(platform.bazelCPUPlatform)_cpus=\(cpu.watchCPU.rawValue)")
      }
    }

    if case .ios = platform {
      if cpu == .arm64 || cpu == .arm64e {
        
        
        
        
        
        flags.append("--\(PlatformType.watchos.bazelCPUPlatform)_cpus=\(physicalWatchCPUs)")
      } else {
        flags.append("--\(PlatformType.watchos.bazelCPUPlatform)_cpus=\(cpu.watchCPU.rawValue)")
      }
    }

    return flags
  }
}

public class BazelBuildSettingsFeatures {
  public static func enabledFeatures(options: TulsiOptionSet) -> Set<BazelSettingFeature> {
    
    
    
    
    
    
    
    
    
    
    var features: Set<BazelSettingFeature> = [.DebugPathNormalization]
    if options[.SwiftForcesdSYMs].commonValueAsBool ?? false {
      features.insert(.SwiftForcesdSYMs)
    }
    if options[.TreeArtifactOutputs].commonValueAsBool ?? true {
      features.insert(.TreeArtifactOutputs)
    }
    return features
  }
}
