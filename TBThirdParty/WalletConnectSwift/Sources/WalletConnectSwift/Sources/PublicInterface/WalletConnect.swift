



open class WalletConnect {
    var communicator = Communicator()

    public init() {}

    public enum WalletConnectError: Error {
        case tryingToConnectExistingSessionURL
        case tryingToDisconnectInactiveSession
        case missingWalletInfoInSession
    }

    
    
    
    
    
    open func connect(to url: WCURL) throws {
        guard communicator.session(by: url) == nil else {
            throw WalletConnectError.tryingToConnectExistingSessionURL
        }
        listen(on: url)
    }

    
    
    
    
    open func reconnect(to session: Session) throws {
        guard session.walletInfo != nil else {
            throw WalletConnectError.missingWalletInfoInSession
        }
        communicator.addOrUpdateSession(session)
        listen(on: session.url)
    }

    
    
    
    
    open func disconnect(from session: Session) throws {
        guard communicator.isConnected(by: session.url) else {
            throw WalletConnectError.tryingToDisconnectInactiveSession
        }
        try sendDisconnectSessionRequest(for: session)
        communicator.addOrUpdatePendingDisconnectSession(session)
        communicator.disconnect(from: session.url)
    }

    
    
    
    open func openSessions() -> [Session] {
        return communicator.openSessions()
    }

    private func listen(on url: WCURL) {
        let onConnect: ((WCURL) -> Void) = { [weak self] url in
            self?.onConnect(to: url)
        }
        let onDisconnect: ((WCURL, Error?) -> Void) = { [weak self] (url, error) in
            self?.onDisconnect(from: url, error: error)
        }
        let onTextReceive: ((String, WCURL) -> Void) = { [weak self] (text, url) in
            self?.onTextReceive(text, from: url)
        }
        communicator.listen(on: url,
                            onConnect: onConnect,
                            onDisconnect: onDisconnect,
                            onTextReceive: onTextReceive)
    }

    
    
    
    func onConnect(to url: WCURL) {
        preconditionFailure("Should be implemented in subclasses")
    }

    
    
    
    
    
    private func onDisconnect(from url: WCURL, error: Error?) {
        LogService.shared.log("WC: didDisconnect url: \(url.bridgeURL.absoluteString)")
        
        guard let session = communicator.session(by: url) else {
            failedToConnect(url)
            return
        }
        
        guard communicator.pendingDisconnectSession(by: url) != nil else {
            LogService.shared.log("WC: trying to reconnect session by url: \(url.bridgeURL.absoluteString)")
            willReconnect(session)
            try! reconnect(to: session)
            return
        }
        communicator.removeSession(by: url)
        communicator.removePendingDisconnectSession(by: url)
        didDisconnect(session)
    }

    
    
    
    
    
    func onTextReceive(_ text: String, from url: WCURL) {
        preconditionFailure("Should be implemented in subclasses")
    }

    func sendDisconnectSessionRequest(for session: Session) throws {
        preconditionFailure("Should be implemented in subclasses")
    }

    func failedToConnect(_ url: WCURL) {
        preconditionFailure("Should be implemented in subclasses")
    }

    func didDisconnect(_ session: Session) {
        preconditionFailure("Should be implemented in subclasses")
    }

    func willReconnect(_ session: Session) {
        preconditionFailure("Should be implemented in subclasses")
    }

    func log(_ request: Request) {
        guard let text = try? request.json().string else { return }
        LogService.shared.log("WC: <== [request] \(text)")
    }

    func log(_ response: Response) {
        guard let text = try? response.json().string else { return }
        LogService.shared.log("WC: <== [response] \(text)")
    }
}
