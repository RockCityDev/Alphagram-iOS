

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Foundation


extension Thread {
  
  public class func doOnMainQueue(_ closure: @escaping () -> Void ) {
    DispatchQueue.main.async(execute: closure)
  }

  
  public class func doOnQOSUserInitiatedThread(_ closure: @escaping () -> Void ) {
    DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async(execute: closure)
  }
}
