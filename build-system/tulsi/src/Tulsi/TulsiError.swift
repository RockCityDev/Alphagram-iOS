

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Foundation



class TulsiError: NSError {
  enum ErrorCode: NSInteger {
    
    case general

    
    
    case configNotGenerateable
    
    case configNotLoadable
    
    case configNotSaveable
  }

  convenience init(errorMessage: String) {
    let fmt = NSLocalizedString("TulsiError_General",
                                comment: "A generic exception was thrown, additional debug data is in %1$@.")
    self.init(code: .general, userInfo: [NSLocalizedDescriptionKey: String(format: fmt, errorMessage) as AnyObject])
  }

  init(code: ErrorCode, userInfo: [String: AnyObject]? = nil) {
    var userInfo = userInfo
    if userInfo == nil {
      userInfo = [NSLocalizedDescriptionKey: TulsiError.localizedErrorMessageForCode(code) as AnyObject]
    } else if userInfo?[NSLocalizedDescriptionKey] == nil {
      userInfo![NSLocalizedDescriptionKey] = TulsiError.localizedErrorMessageForCode(code) as AnyObject?
    }
    super.init(domain: "Tulsi", code: code.rawValue, userInfo: userInfo)
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  

  private static func localizedErrorMessageForCode(_ errorCode: ErrorCode) -> String {
    switch errorCode {
      case .configNotGenerateable:
        return NSLocalizedString("TulsiError_ConfigNotGenerateable",
                                 comment: "Error message for when the user tried to generate an Xcode project from an incomplete config.")
      case .configNotLoadable:
        return NSLocalizedString("TulsiError_ConfigNotLoadable",
                                 comment: "Error message for when a generator config fails to load for an unspecified reason.")
      case .configNotSaveable:
        return NSLocalizedString("TulsiError_ConfigNotSaveable",
                                 comment: "Generator config is not fully populated and cannot be saved.")

      case .general:
        let fmt = NSLocalizedString("TulsiError_General",
                                    comment: "A generic exception was thrown, additional debug data is in %1$@.")
        return String(format: fmt, "Code: \(errorCode)")
    }
  }
}
