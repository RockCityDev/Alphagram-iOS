import Foundation
import Postbox

public struct StickerPackCollectionInfoFlags: OptionSet {
    public var rawValue: Int32
    
    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }
    
    public init() {
        self.rawValue = 0
    }
    
    public init(_ flags: StickerPackCollectionInfoFlags) {
        var rawValue: Int32 = 0
        
        if flags.contains(StickerPackCollectionInfoFlags.isMasks) {
            rawValue |= StickerPackCollectionInfoFlags.isMasks.rawValue
        }
        if flags.contains(StickerPackCollectionInfoFlags.isOfficial) {
            rawValue |= StickerPackCollectionInfoFlags.isOfficial.rawValue
        }
        if flags.contains(StickerPackCollectionInfoFlags.isAnimated) {
            rawValue |= StickerPackCollectionInfoFlags.isAnimated.rawValue
        }
        if flags.contains(StickerPackCollectionInfoFlags.isVideo) {
            rawValue |= StickerPackCollectionInfoFlags.isVideo.rawValue
        }
        if flags.contains(StickerPackCollectionInfoFlags.isEmoji) {
            rawValue |= StickerPackCollectionInfoFlags.isEmoji.rawValue
        }
        
        self.rawValue = rawValue
    }
    
    public static let isMasks = StickerPackCollectionInfoFlags(rawValue: 1 << 0)
    public static let isOfficial = StickerPackCollectionInfoFlags(rawValue: 1 << 1)
    public static let isAnimated = StickerPackCollectionInfoFlags(rawValue: 1 << 2)
    public static let isVideo = StickerPackCollectionInfoFlags(rawValue: 1 << 3)
    public static let isEmoji = StickerPackCollectionInfoFlags(rawValue: 1 << 4)
}


public final class StickerPackCollectionInfo: ItemCollectionInfo, Equatable {
    public let id: ItemCollectionId
    public let flags: StickerPackCollectionInfoFlags
    public let accessHash: Int64
    public let title: String
    public let shortName: String
    public let thumbnail: TelegramMediaImageRepresentation?
    public let thumbnailFileId: Int64?
    public let immediateThumbnailData: Data?
    public let hash: Int32
    public let count: Int32
    
    public init(id: ItemCollectionId, flags: StickerPackCollectionInfoFlags, accessHash: Int64, title: String, shortName: String, thumbnail: TelegramMediaImageRepresentation?, thumbnailFileId: Int64?, immediateThumbnailData: Data?, hash: Int32, count: Int32) {
        self.id = id
        self.flags = flags
        self.accessHash = accessHash
        self.title = title
        self.shortName = shortName
        self.thumbnail = thumbnail
        self.thumbnailFileId = thumbnailFileId
        self.immediateThumbnailData = immediateThumbnailData
        self.hash = hash
        self.count = count
    }
    
    public init(decoder: PostboxDecoder) {
        self.id = ItemCollectionId(namespace: decoder.decodeInt32ForKey("i.n", orElse: 0), id: decoder.decodeInt64ForKey("i.i", orElse: 0))
        self.accessHash = decoder.decodeInt64ForKey("a", orElse: 0)
        self.title = decoder.decodeStringForKey("t", orElse: "")
        self.shortName = decoder.decodeStringForKey("s", orElse: "")
        self.thumbnail = decoder.decodeObjectForKey("th", decoder: { TelegramMediaImageRepresentation(decoder: $0) }) as? TelegramMediaImageRepresentation
        self.thumbnailFileId = decoder.decodeOptionalInt64ForKey("tfi")
        self.immediateThumbnailData = decoder.decodeDataForKey("itd")
        self.hash = decoder.decodeInt32ForKey("h", orElse: 0)
        self.flags = StickerPackCollectionInfoFlags(rawValue: decoder.decodeInt32ForKey("f", orElse: 0))
        self.count = decoder.decodeInt32ForKey("n", orElse: 0)
    }
    
    public func encode(_ encoder: PostboxEncoder) {
        encoder.encodeInt32(self.id.namespace, forKey: "i.n")
        encoder.encodeInt64(self.id.id, forKey: "i.i")
        encoder.encodeInt64(self.accessHash, forKey: "a")
        encoder.encodeString(self.title, forKey: "t")
        encoder.encodeString(self.shortName, forKey: "s")
        if let thumbnail = self.thumbnail {
            encoder.encodeObject(thumbnail, forKey: "th")
        } else {
            encoder.encodeNil(forKey: "th")
        }
        if let thumbnailFileId = self.thumbnailFileId {
            encoder.encodeInt64(thumbnailFileId, forKey: "tfi")
        } else {
            encoder.encodeNil(forKey: "tfi")
        }
        if let immediateThumbnailData = self.immediateThumbnailData {
            encoder.encodeData(immediateThumbnailData, forKey: "itd")
        } else {
            encoder.encodeNil(forKey: "itd")
        }
        encoder.encodeInt32(self.hash, forKey: "h")
        encoder.encodeInt32(self.flags.rawValue, forKey: "f")
        encoder.encodeInt32(self.count, forKey: "n")
    }
    
    public static func ==(lhs: StickerPackCollectionInfo, rhs: StickerPackCollectionInfo) -> Bool {
        if lhs.id != rhs.id {
            return false
        }
        
        if lhs.title != rhs.title {
            return false
        }
        
        if lhs.shortName != rhs.shortName {
            return false
        }
        
        if lhs.hash != rhs.hash {
            return false
        }
        
        if lhs.immediateThumbnailData != rhs.immediateThumbnailData {
            return false
        }
        
        if lhs.thumbnailFileId != rhs.thumbnailFileId {
            return false
        }
        
        if lhs.flags != rhs.flags {
            return false
        }
        
        if lhs.count != rhs.count {
            return false
        }
        
        return true
    }
}
