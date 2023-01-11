





// of this software and associated documentation files (the "Software"), to deal








// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR








import Foundation
import sqlcipher

public final class Database {
    internal var handle: OpaquePointer? = nil

    public init?(_ location: String, readOnly: Bool) {
        if location != ":memory:" {
            let _ = open(location + "-guard", O_WRONLY | O_CREAT | O_APPEND, S_IRUSR | S_IWUSR)
        }
        let flags: Int32
        if readOnly {
            flags = SQLITE_OPEN_READONLY
        } else {
            flags = SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX
        }
        let res = sqlite3_open_v2(location, &self.handle, flags, nil)
        if res != SQLITE_OK {
            postboxLog("sqlite3_open_v2: \(res)")
            return nil
        }
    }

    deinit {
        sqlite3_close(self.handle)
    } 

    public func execute(_ SQL: String) -> Bool {
        let res = sqlite3_exec(self.handle, SQL, nil, nil, nil)
        if res == SQLITE_OK {
            return true
        } else {
            if let error = sqlite3_errmsg(self.handle), let str = NSString(utf8String: error) {
                print("SQL error \(res): \(str) on SQL")
            } else {
                print("SQL error \(res) on SQL")
            }
            return false
        }
    }
    
    public func currentError() -> String? {
        if let error = sqlite3_errmsg(self.handle), let str = NSString(utf8String: error) {
            return "SQL error \(str)"
        } else {
            return nil
        }
    }
}
