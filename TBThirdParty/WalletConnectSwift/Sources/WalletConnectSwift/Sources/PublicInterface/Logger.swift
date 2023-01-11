







import Foundation

public protocol Logger {
    func log(_ message: String)
}

public class ConsoleLogger: Logger {
    public func log(_ message: String) {
        print(message)
    }
}

public class NullLooger: Logger {
    public func log(_ message: String) {  }
}

public class LogService {
    public static var shared: Logger = ConsoleLogger()
}
