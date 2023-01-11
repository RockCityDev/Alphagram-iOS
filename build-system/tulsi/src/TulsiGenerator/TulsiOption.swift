

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Foundation



public class TulsiOption: Equatable, CustomStringConvertible {

  
  public static let BooleanTrueValue = "YES"
  
  public static let BooleanFalseValue = "NO"

  
  
  public static let InheritKeyword = "$(inherited)"

  
  public enum ValueType: Equatable {
    case bool, string
    case stringEnum(Set<String>)

    public static func ==(lhs: ValueType, rhs: ValueType) -> Bool {
      switch (lhs, rhs) {
        case (.bool, .bool): return true
        case (.string, .string): return true
        case (.stringEnum(let a), .stringEnum(let b)): return a == b
        default: return false
      }
    }
  }

  
  public struct OptionType: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
      self.rawValue = rawValue
    }

    
    static let Generic = OptionType([])

    
    static let BuildSetting = OptionType(rawValue: 1 << 0)

    
    static let TargetSpecializable = OptionType(rawValue: 1 << 1)

    
    
    static let TargetSpecializableBuildSetting = OptionType([BuildSetting, TargetSpecializable])

    
    static let Hidden = OptionType(rawValue: 1 << 16)

    
    static let PerUserOnly = OptionType(rawValue: 1 << 17)

    
    static let SupportsInheritKeyword = OptionType(rawValue: 1 << 18)
  }

  
  public let displayName: String
  
  public let userDescription: String
  
  public let valueType: ValueType
  
  public let optionType: OptionType

  
  public let defaultValue: String?
  
  public var projectValue: String? = nil
  
  public var targetValues: [String: String]?

  
  public var commonValue: String? {
    if projectValue != nil { return projectValue }
    return defaultValue
  }

  
  
  public var commonValueAsBool: Bool? {
    guard let val = commonValue else {
      return nil
    }
    return val == TulsiOption.BooleanTrueValue
  }

  
  static let ProjectValueKey = "p"
  
  static let TargetValuesKey = "t"
  typealias PersistenceType = [String: AnyObject]

  init(displayName: String,
       userDescription: String,
       valueType: ValueType,
       optionType: OptionType,
       defaultValue: String? = nil) {
    self.displayName = displayName
    self.userDescription = userDescription
    self.valueType = valueType
    self.optionType = optionType
    self.defaultValue = defaultValue

    if optionType.contains(.TargetSpecializable) {
      self.targetValues = [String: String]()
    } else {
      self.targetValues = nil
    }
  }

  
  
  init(resolvingValuesFrom opt: TulsiOption, byInheritingFrom parent: TulsiOption) {
    displayName = opt.displayName
    userDescription = opt.userDescription
    valueType = opt.valueType
    optionType = opt.optionType
    defaultValue = parent.commonValue
    projectValue = opt.projectValue
    targetValues = opt.targetValues

    let inheritValue = defaultValue ?? ""
    func resolveInheritKeyword(_ value: String?) -> String? {
      guard let value = value else { return nil }
      let newValue = value.replacingOccurrences(of: TulsiOption.InheritKeyword,
                                                with: inheritValue)
      return newValue.isEmpty ? nil : newValue
    }
    if optionType.contains(.SupportsInheritKeyword) {
      projectValue = resolveInheritKeyword(projectValue)
      if targetValues != nil {
        for (key, value) in targetValues! {
          targetValues![key] = resolveInheritKeyword(value)
        }
      }
    }
  }

  
  public func valueForTarget(_ target: String, inherit: Bool = true) -> String? {
    if let val = targetValues?[target] {
      return val
    }

    if inherit {
      return commonValue
    }
    return nil
  }

  
  public func appendProjectValue(_ value: String) {
    guard !value.isEmpty else { return }
    guard let previous = projectValue ?? defaultValue, !previous.isEmpty else {
      projectValue = value
      return
    }
    projectValue = "\(previous) \(value)"
  }

  public func sanitizeValue(_ value: String?) -> String? {
    switch (valueType) {
      case .bool:
        if value != TulsiOption.BooleanTrueValue {
          return TulsiOption.BooleanFalseValue
        }
        return value
      case .string:
        return value?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
      case .stringEnum(let values):
        guard let curValue = value else { return defaultValue }
        guard values.contains(curValue) else { return defaultValue }
        return curValue
    }
  }

  
  
  func serialize() -> PersistenceType? {
    var serialized = PersistenceType()
    if let value = projectValue {
      serialized[TulsiOption.ProjectValueKey] = value as AnyObject?
    }

    if let values = targetValues, !values.isEmpty {
      serialized[TulsiOption.TargetValuesKey] = values as AnyObject?
    }
    if serialized.isEmpty { return nil }
    return serialized
  }

  func deserialize(_ serialized: PersistenceType) {
    if let value = serialized[TulsiOption.ProjectValueKey] as? String {
      projectValue = sanitizeValue(value)
    } else {
      projectValue = nil
    }

    if let values = serialized[TulsiOption.TargetValuesKey] as? [String: String] {
      var validValues = [String: String]()
      for (key, value) in values {
        if let sanitized = sanitizeValue(value) {
          validValues[key] = sanitized
        }
      }
      targetValues = validValues
    } else if optionType.contains(.TargetSpecializable) {
      self.targetValues = [String: String]()
    } else {
      self.targetValues = nil
    }
  }

  

  public var description: String {
    return "\(displayName) - \(String(describing: commonValue)):\(String(describing: targetValues))"
  }
}

public func ==(lhs: TulsiOption, rhs: TulsiOption) -> Bool {
  if !(lhs.displayName == rhs.displayName &&
      lhs.userDescription == rhs.userDescription &&
      lhs.valueType == rhs.valueType &&
      lhs.optionType == rhs.optionType) {
    return false
  }

  func optionalsAreEqual<T>(_ a: T?, _ b: T?) -> Bool where T: Equatable {
    if a == nil { return b == nil }
    if b == nil { return false }
    return a! == b!
  }
  func optionalDictsAreEqual<K, V>(_ a: [K: V]?, _ b: [K: V]?) -> Bool where V: Equatable {
    if a == nil { return b == nil }
    if b == nil { return false }
    return a! == b!
  }
  return optionalsAreEqual(lhs.defaultValue, rhs.defaultValue) &&
      optionalsAreEqual(lhs.projectValue, rhs.projectValue) &&
      optionalDictsAreEqual(lhs.targetValues, rhs.targetValues)
}
