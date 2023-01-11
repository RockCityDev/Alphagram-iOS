



import Foundation

enum DataConversionError: Error {
    case stringToDataFailed
    case dataToStringFailed
}

struct PubSubMessage: Codable {
    
    var topic: String
    
    var type: MessageType
    
    var payload: String

    enum MessageType: String, Codable {
        case pub
        case sub
    }

    static func message(from string: String) throws -> PubSubMessage {
        guard let data = string.data(using: .utf8) else {
            throw DataConversionError.stringToDataFailed
        }
        return try JSONDecoder().decode(PubSubMessage.self, from: data)
    }

    func json() throws -> String {
        let data = try JSONEncoder.encoder().encode(self)
        guard let string = String(data: data, encoding: .utf8) else {
            throw DataConversionError.dataToStringFailed
        }
        return string
    }
}
