



import Foundation


protocol ResponseSerializer {
    
    
    
    
    
    
    
    func serialize(_ response: Response, topic: String) throws -> String

    
    
    
    
    
    
    
    func deserialize(_ text: String, url: WCURL) throws -> Response
}

protocol RequestSerializer {
    
    
    
    
    
    
    
    func serialize(_ request: Request, topic: String) throws -> String

    
    
    
    
    
    
    
    func deserialize(_ text: String, url: WCURL) throws -> Request
}

protocol Codec {
    func encode(plainText: String, key: String) throws -> String
    func decode(cipherText: String, key: String) throws -> String
}

enum JSONRPCSerializerError: Error {
    case wrongIncommingDecodedTextFormat(String)
}

class JSONRPCSerializer: RequestSerializer, ResponseSerializer {
    private let codec: Codec = AES_256_CBC_HMAC_SHA256_Codec()
    private let jsonrpc = JSONRPCAdapter()

    

    func serialize(_ request: Request, topic: String) throws -> String {
        let jsonText = try jsonrpc.json(from: request)
        let cipherText = try codec.encode(plainText: jsonText, key: request.url.key)
        let message = PubSubMessage(topic: topic, type: .pub, payload: cipherText)
        return try message.json()
    }

    func deserialize(_ text: String, url: WCURL) throws -> Request {
        let message = try PubSubMessage.message(from: text)
        let payloadText = try codec.decode(cipherText: message.payload, key: url.key)
        do {
            return try jsonrpc.request(from: payloadText, url: url)
        } catch {
            throw JSONRPCSerializerError.wrongIncommingDecodedTextFormat(payloadText)
        }
    }

    

    func serialize(_ response: Response, topic: String) throws -> String {
        let jsonText = try jsonrpc.json(from: response)
        let cipherText = try codec.encode(plainText: jsonText, key: response.url.key)
        let message = PubSubMessage(topic: topic, type: .pub, payload: cipherText)
        return try message.json()
    }

    func deserialize(_ text: String, url: WCURL) throws -> Response {
        let message = try PubSubMessage.message(from: text)
        let payloadText = try codec.decode(cipherText: message.payload, key: url.key)
        do {
            return try jsonrpc.response(from: payloadText, url: url)
        } catch {
            throw JSONRPCSerializerError.wrongIncommingDecodedTextFormat(payloadText)
        }
    }
}

fileprivate class JSONRPCAdapter {
    func json(from request: Request) throws -> String {
        return try request.json().string
    }

    func request(from json: String, url: WCURL) throws -> Request {
        let JSONRPCRequest = try JSONRPC_2_0.Request.create(from: JSONRPC_2_0.JSON(json))
        return Request(payload: JSONRPCRequest, url: url)
    }

    func json(from response: Response) throws -> String {
        return try response.json().string
    }

    func response(from json: String, url: WCURL) throws -> Response {
        let JSONRPCResponse = try JSONRPC_2_0.Response.create(from: JSONRPC_2_0.JSON(json))
        return Response(payload: JSONRPCResponse, url: url)
    }
}
