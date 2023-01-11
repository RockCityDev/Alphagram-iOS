



import Foundation

protocol Transport {
    func send(to url: WCURL, text: String)
    func listen(on url: WCURL,
                onConnect: @escaping ((WCURL) -> Void),
                onDisconnect: @escaping ((WCURL, Error?) -> Void),
                onTextReceive: @escaping (String, WCURL) -> Void)
    func isConnected(by url: WCURL) -> Bool
    func disconnect(from url: WCURL)
}




class Bridge: Transport {
    private var connections: [WebSocketConnection] = []
    private let syncQueue = DispatchQueue(label: "org.walletconnect.swift.transport")

    
    func send(to url: WCURL, text: String) {
        dispatchPrecondition(condition: .notOnQueue(syncQueue))
        syncQueue.sync { [weak self] in
            guard let `self` = self else { return }
            if let connection = self.findConnection(url: url) {
                connection.send(text)
            }
        }
    }

    func listen(on url: WCURL,
                onConnect: @escaping ((WCURL) -> Void),
                onDisconnect: @escaping ((WCURL, Error?) -> Void),
                onTextReceive: @escaping (String, WCURL) -> Void) {
        dispatchPrecondition(condition: .notOnQueue(syncQueue))
        syncQueue.sync { [weak self] in
            guard let `self` = self else { return }
            var connection: WebSocketConnection
            if let existingConnection = self.findConnection(url: url) {
                connection = existingConnection
            } else {
                connection = WebSocketConnection(url: url,
                                                 onConnect: { onConnect(url) },
                                                 onDisconnect: { [weak self] error in
                                                    self?.releaseConnection(by: url)
                                                    onDisconnect(url, error) },
                                                 onTextReceive: { text in onTextReceive(text, url) })
                self.connections.append(connection)
            }
            if !connection.isOpen {
                connection.open()
            }
        }
    }

    func isConnected(by url: WCURL) -> Bool {
        var connection: WebSocketConnection?
        dispatchPrecondition(condition: .notOnQueue(syncQueue))
        syncQueue.sync { [weak self] in
            guard let `self` = self else { return }
            connection = self.findConnection(url: url)
        }
        return connection?.isOpen ?? false
    }
    
    func disconnect(from url: WCURL) {
        dispatchPrecondition(condition: .notOnQueue(syncQueue))
        syncQueue.sync { [weak self] in
            guard let `self` = self else { return }
            if let connection = self.findConnection(url: url) {
                connection.close()
            }
        }
    }

    private func releaseConnection(by url: WCURL) {
        dispatchPrecondition(condition: .notOnQueue(syncQueue))
        syncQueue.sync { [weak self] in
            guard let `self` = self else { return }
            if let connection = self.findConnection(url: url) {
                self.connections.removeAll { $0 === connection }
            }
        }
    }

    
    private func findConnection(url: WCURL) -> WebSocketConnection? {
        dispatchPrecondition(condition: .onQueue(syncQueue))
        return connections.first { $0.url == url }
    }
}
