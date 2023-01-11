

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Foundation

let XcodeProjectArchiveVersion = "1"


protocol PBXProjSerializable: AnyObject {
  func serializeInto(_ serializer: PBXProjFieldSerializer) throws
}



protocol PBXProjFieldSerializer {
  func addField(_ name: String, _ obj: PBXObjectProtocol?, rawID: Bool) throws
  func addField(_ name: String, _ val: Int) throws
  func addField(_ name: String, _ val: Bool) throws
  func addField(_ name: String, _ val: String?) throws
  func addField(_ name: String, _ val: [String: Any]?) throws
  func addField<T: PBXObjectProtocol>(_ name: String, _ values: [T]) throws
  func addField(_ name: String, _ values: [String]) throws

  
  
  func serializeObject(_ object: PBXObjectProtocol, returnRawID: Bool) throws -> String
}

extension PBXProjFieldSerializer {
  func addField(_ name: String, _ obj: PBXObjectProtocol?) throws {
    try addField(name, obj, rawID: false)
  }
}


extension NSMutableData {
  enum EncodingError: Error {
    
    case stringUTF8EncodingError
  }

  func tulsi_appendString(_ str: String) throws {
    guard let encoded = str.data(using: String.Encoding.utf8) else {
      throw EncodingError.stringUTF8EncodingError
    }
    self.append(encoded)
  }
}



final class OpenStepSerializer: PBXProjFieldSerializer {

  private enum SerializationError: Error {
    
    case referencedObjectNotFoundError
  }

  
  private static let CompactPBXTypes = Set<String>(["PBXBuildFile", "PBXFileReference"])

  private let rootObject: PBXProject
  private let gidGenerator: GIDGeneratorProtocol
  private var objects = [String: TypedDict]()

  private class GIDHolder {
    var gids: [String] = []
  }
  
  
  
  
  private var typedObjectIndex = [String: GIDHolder]()

  
  private var currentDict: RawDict!

  init(rootObject: PBXProject, gidGenerator: GIDGeneratorProtocol) {
    self.rootObject = rootObject
    self.gidGenerator = gidGenerator
  }

  func serialize() -> Data? {
    do {
      let rootObjectID = try serializeObject(rootObject)
      return serializeObjectDictionaryWithRoot(rootObjectID)
    } catch {
      return nil
    }
  }

  
  func serializeObject(_ obj: PBXObjectProtocol, returnRawID: Bool = false) throws -> String {
    if let typedObject = objects[obj.globalID] {
      if !returnRawID {
        return "\(obj.globalID)\(typedObject.comment)"
      }
      return obj.globalID
    }

    
    if obj.globalID.isEmpty {
      obj.globalID = gidGenerator.generate(obj)
    }

    let globalID = obj.globalID
    let isa = obj.isa
    let serializationDict = TypedDict(gid: globalID, isa: isa, comment: obj.comment)
    let stack = currentDict
    currentDict = serializationDict

    
    
    
    objects[globalID] = serializationDict

    try obj.serializeInto(self)

    var objectGIDHolder = typedObjectIndex[isa]
    if objectGIDHolder == nil {
      objectGIDHolder = GIDHolder()
      typedObjectIndex[isa] = objectGIDHolder
    }
    objectGIDHolder!.gids.append(globalID)

    currentDict = stack

    if returnRawID {
      return globalID
    }
    return "\(globalID)\(serializationDict.comment)"
  }

  func addField(_ name: String, _ obj: PBXObjectProtocol?, rawID: Bool) throws {
    guard let local = obj else {
      return
    }

    let gid = try serializeObject(local, returnRawID: rawID)
    currentDict.dict[name] = gid as AnyObject?
  }

  func addField(_ name: String, _ val: Int) throws {
    currentDict.dict[name] = val as AnyObject?
  }

  func addField(_ name: String, _ val: Bool) throws {
    let intVal = val ? 1 : 0
    currentDict.dict[name] = intVal as AnyObject?
  }

  func addField(_ name: String, _ val: String?) throws {
    guard let stringValue = val else {
      return
    }

    currentDict.dict[name] = escapeString(stringValue) as AnyObject?
  }

  func addField(_ name: String, _ val: [String: Any]?) throws {
    
    
    guard let dict = val else {
      return
    }

    let stack = currentDict
    currentDict = RawDict(compact: (stack?.compact)!)
    for (key, value) in dict {
      if let stringValue = value as? String {
        currentDict.dict[key] = escapeString(stringValue) as AnyObject?
      } else if let dictValue = value as? [String: AnyObject] {
        try addField(key, dictValue)
      } else if let arrayValue = value as? [String] {
        try addField(key, arrayValue)
      } else {
        assertionFailure("Unsupported complex object \(value) in nested dictionary type")
      }
    }
    stack?.dict[name] = currentDict
    currentDict = stack

  }

  func addField<T: PBXObjectProtocol>(_ name: String, _ values: [T]) throws {
    currentDict.dict[name] = try values.map() { try serializeObject($0) }
  }

  func addField(_ name: String, _ values: [String]) throws {
    currentDict.dict[name] = values.map() { escapeString($0) }
  }

  func getGlobalIDForObject(_ object: PBXObjectProtocol) throws -> String {
    return try serializeObject(object)
  }

  

  private func serializeObjectDictionaryWithRoot(_ rootObjectID: String) -> Data? {
    let data = NSMutableData()
    do {
      try data.tulsi_appendString("// !$*UTF8*$!\n{\n")
      var indent = "\t"

      func appendIndentedString(_ value: String) throws {
        try data.tulsi_appendString(indent + value)
      }

      try appendIndentedString("archiveVersion = \(XcodeProjectArchiveVersion);\n")
      try appendIndentedString("classes = {\n\(indent)};\n")
      try appendIndentedString("objectVersion = \(XcodeVersionInfo.objectVersion);\n")

      try appendIndentedString("objects = {\n")
      let oldIndent = indent
      indent += "\t"

      try encodeSerializedPBXObjectArray("PBXBuildFile", into: data, indented: indent)
      try encodeSerializedPBXObjectArray("PBXContainerItemProxy", into: data, indented: indent)
      try encodeSerializedPBXObjectArray("PBXFileReference", into: data, indented: indent)
      try encodeSerializedPBXObjectArray("PBXGroup", into: data, indented: indent)
      try encodeSerializedPBXObjectArray("PBXLegacyTarget", into: data, indented: indent)
      try encodeSerializedPBXObjectArray("PBXNativeTarget", into: data, indented: indent)
      try encodeSerializedPBXObjectArray("PBXProject", into: data, indented: indent)
      try encodeSerializedPBXObjectArray("PBXShellScriptBuildPhase", into: data, indented: indent)
      try encodeSerializedPBXObjectArray("PBXSourcesBuildPhase", into: data, indented: indent)
      try encodeSerializedPBXObjectArray("PBXVariantGroup", into: data, indented: indent)
      try encodeSerializedPBXObjectArray("PBXTargetDependency", into: data, indented: indent)
      try encodeSerializedPBXObjectArray("XCBuildConfiguration", into: data, indented: indent)
      try encodeSerializedPBXObjectArray("XCConfigurationList", into: data, indented: indent)
      try encodeSerializedPBXObjectArray("XCVersionGroup", into: data, indented: indent)

      assert(typedObjectIndex.isEmpty, "Failed to encode objects of type(s) \(typedObjectIndex.keys)")

      indent = oldIndent
      try appendIndentedString("};\n")
      try appendIndentedString("rootObject = \(rootObjectID);\n")
      try data.tulsi_appendString("}")
    } catch {
      return nil
    }

    return data as Data
  }

  private func encodeSerializedPBXObjectArray(_ key: String,
                                              into data: NSMutableData,
                                              indented indent: String) throws {
    guard let entries = typedObjectIndex[key]?.gids else {
      return
    }

    
    typedObjectIndex.removeValue(forKey: key)

    try data.tulsi_appendString("\n\n")

    for gid in entries.sorted() {
      guard let obj = objects[gid] else {
        throw SerializationError.referencedObjectNotFoundError
      }

      try obj.appendToData(data, indent: indent)
    }

    try data.tulsi_appendString("\n")
  }

  
  private class RawDict {
    var dict = [String: Any]()
    let compact: Bool

    init(compact: Bool = false) {
      self.compact = compact
    }

    func appendToData(_ data: NSMutableData, indent: String) throws {
      try data.tulsi_appendString("{")

      let (closingSpacer, spacer) = spacersForIndent(indent)
      if !compact {
        try data.tulsi_appendString(spacer)
      }

      try appendContentsToData(data, indent: indent, spacer: spacer)
      try data.tulsi_appendString("\(closingSpacer)};")
    }

    

    func appendContentsToData(_ data: NSMutableData, indent: String, spacer: String) throws {
      let newIndent = indent + "\t"
      var leadingSpacer = ""
      for (key, value) in dict.sorted(by: { $0.0 < $1.0 }) {
        let key = escapeString(key)
        if let rawDictValue = value as? RawDict {
          try data.tulsi_appendString("\(leadingSpacer)\(key) = ")
          try rawDictValue.appendToData(data, indent: newIndent)
        } else if let arrayValue = value as? [String] {
          try data.tulsi_appendString("\(leadingSpacer)\(key) = (")
          let itemSpacer = spacer + (compact ? "" : "\t")
          try arrayValue.forEach() { try data.tulsi_appendString("\(itemSpacer)\($0),") }
          try data.tulsi_appendString("\(spacer));")
        } else {
          try data.tulsi_appendString("\(leadingSpacer)\(key) = \(value);")
        }
        leadingSpacer = spacer
      }
    }

    func spacersForIndent(_ indent: String) -> (String, String) {
      let closingSpacer: String
      let spacer: String
      if compact {
        spacer = " "
        closingSpacer = spacer
      } else {
        closingSpacer = "\n\(indent)"
        spacer = "\(closingSpacer)\t"
      }
      return (closingSpacer, spacer)
    }
  }


  
  private final class TypedDict: RawDict {
    let gid: String
    let isa: String
    let comment: String

    init(gid: String, isa: String, comment: String? = nil) {
      self.gid = gid
      self.isa = isa
      if let comment = comment {
        self.comment = " "
      } else {
        self.comment = ""
      }
      super.init(compact: OpenStepSerializer.CompactPBXTypes.contains(isa))
    }

    override func appendToData(_ data: NSMutableData, indent: String) throws {
      try data.tulsi_appendString("\(indent)\(gid)\(comment) = {")

      let (closingSpacer, spacer) = spacersForIndent(indent)
      if !compact {
        try data.tulsi_appendString(spacer)
      }

      try data.tulsi_appendString("isa = \(isa);\(spacer)")
      try appendContentsToData(data, indent: indent, spacer: spacer)
      try data.tulsi_appendString("\(closingSpacer)};\n")
    }
  }
}



private let unquotedSerializableStringRegex = try! NSRegularExpression(pattern: "^[A-Z0-9._/]+$",
                                                                       options: [.caseInsensitive])

private func escapeString(_ val: String) -> String {
  var val = val
  
  
  
  
  
  
  let valueRange = NSMakeRange(0, val.count)
  if unquotedSerializableStringRegex.firstMatch(in: val, options: NSRegularExpression.MatchingOptions.anchored, range: valueRange) != nil {
    return val
  } else {
    val = val.replacingOccurrences(of: "\\", with: "\\\\")
    val = val.replacingOccurrences(of: "\"", with: "\\\"")
    val = val.replacingOccurrences(of: "\n", with: "\\n")
    return "\"\(val)\""
  }
}
