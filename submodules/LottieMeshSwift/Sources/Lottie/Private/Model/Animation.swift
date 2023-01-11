






import Foundation

public enum CoordinateSpace: Int, Codable {
  case type2d
  case type3d
}


public final class Animation: Codable {
  
  
  let version: String
  
  
  let type: CoordinateSpace
  
  
  public let startFrame: AnimationFrameTime
  
  
  public let endFrame: AnimationFrameTime
  
  
  public let framerate: Double
  
  
  let width: Int
  
  
  let height: Int
  
  
  let layers: [LayerModel]
  
  
  let glyphs: [Glyph]?
  
  
  let fonts: FontList?
  
  
  let assetLibrary: AssetLibrary?
  
  
  let markers: [Marker]?
  let markerMap: [String : Marker]?
  
  
  public var markerNames: [String] {
    guard let markers = markers else { return [] }
    return markers.map { $0.name }
  }
  
  enum CodingKeys : String, CodingKey {
    case version = "v"
    case type = "ddd"
    case startFrame = "ip"
    case endFrame = "op"
    case framerate = "fr"
    case width = "w"
    case height = "h"
    case layers = "layers"
    case glyphs = "chars"
    case fonts = "fonts"
    case assetLibrary = "assets"
    case markers = "markers"
  }
  
  required public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: Animation.CodingKeys.self)
    self.version = try container.decode(String.self, forKey: .version)
    self.type = try container.decodeIfPresent(CoordinateSpace.self, forKey: .type) ?? .type2d
    self.startFrame = try container.decode(AnimationFrameTime.self, forKey: .startFrame)
    self.endFrame = try container.decode(AnimationFrameTime.self, forKey: .endFrame)
    self.framerate = try container.decode(Double.self, forKey: .framerate)
    self.width = try container.decode(Int.self, forKey: .width)
    self.height = try container.decode(Int.self, forKey: .height)
    self.layers = try container.decode([LayerModel].self, ofFamily: LayerType.self, forKey: .layers)
    self.glyphs = try container.decodeIfPresent([Glyph].self, forKey: .glyphs)
    self.fonts = try container.decodeIfPresent(FontList.self, forKey: .fonts)
    self.assetLibrary = try container.decodeIfPresent(AssetLibrary.self, forKey: .assetLibrary)
    self.markers = try container.decodeIfPresent([Marker].self, forKey: .markers)
    
    if let markers = markers {
      var markerMap: [String : Marker] = [:]
      for marker in markers {
        markerMap[marker.name] = marker
      }
      self.markerMap = markerMap
    } else {
      self.markerMap = nil
    }
  }

}
