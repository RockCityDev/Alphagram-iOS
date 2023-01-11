

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Cocoa
import TulsiGenerator


final class AppDelegate: NSObject, NSApplicationDelegate {

  var splashScreenWindowController: SplashScreenWindowController! = nil

  @IBAction func fileBugReport(_ sender: NSMenuItem) {
    BugReporter.fileBugReport()
  }

  

  func applicationWillFinishLaunching(_ notification: Notification) {
    
    let _ = TulsiDocumentController()

    let version = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    LogMessage.postSyslog("Tulsi UI: version \(version)")
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    splashScreenWindowController = SplashScreenWindowController()
    splashScreenWindowController.showWindow(self)
  }

  func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
    return false
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }
}
