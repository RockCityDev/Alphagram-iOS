

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import UIKit


#if !swift(>=4.2)
extension UIApplication {
  typealias LaunchOptionsKey = UIApplicationLaunchOptionsKey
}
#endif

@UIApplicationMain
class AppDelegate: NSObject, UIApplicationDelegate {

  var window: UIWindow?

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions: [UIApplication.LaunchOptionsKey : Any]?
  ) -> Bool {
    return true
  }
}
