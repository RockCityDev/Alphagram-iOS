






import Foundation



public final class ImageAsset: Asset {

  

  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: ImageAsset.CodingKeys.self)
    name = try container.decode(String.self, forKey: .name)
    directory = try container.decode(String.self, forKey: .directory)
    width = try container.decode(Double.self, forKey: .width)
    height = try container.decode(Double.self, forKey: .height)
    try super.init(from: decoder)
  }

  required init(dictionary: [String: Any]) throws {
    name = try dictionary.value(for: CodingKeys.name)
    directory = try dictionary.value(for: CodingKeys.directory)
    width = try dictionary.value(for: CodingKeys.width)
    height = try dictionary.value(for: CodingKeys.height)
    try super.init(dictionary: dictionary)
  }

  

  
  public let name: String

  
  public let directory: String

  
  public let width: Double

  public let height: Double

  override public func encode(to encoder: Encoder) throws {
    try super.encode(to: encoder)
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(name, forKey: .name)
    try container.encode(directory, forKey: .directory)
    try container.encode(width, forKey: .width)
    try container.encode(height, forKey: .height)
  }

  

  enum CodingKeys: String, CodingKey {
    case name = "p"
    case directory = "u"
    case width = "w"
    case height = "h"
  }
}

extension Data {

  

  
  
  
  
  internal init?(imageAsset: ImageAsset) {
    self.init(dataString: imageAsset.name)
  }

  
  
  
  
  
  internal init?(dataString: String, options: DataURLReadOptions = []) {
    guard
      dataString.hasPrefix("data:"),
      let url = URL(string: dataString)
    else {
      return nil
    }
    
    
    
    if
      let base64Range = dataString.range(of: ";base64,"),
      !options.contains(DataURLReadOptions.legacy)
    {
      let encodedString = String(dataString[base64Range.upperBound...])
      self.init(base64Encoded: encodedString)
    } else {
      try? self.init(contentsOf: url)
    }
  }

  

  internal struct DataURLReadOptions: OptionSet {
    let rawValue: Int

    
    static let legacy = DataURLReadOptions(rawValue: 1 << 0)
  }

}
