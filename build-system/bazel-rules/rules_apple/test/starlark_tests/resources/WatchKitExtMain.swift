

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import WatchKit

class ExtensionDelegate: NSObject, WKExtensionDelegate {

  func applicationDidFinishLaunching() {
  }

  func applicationDidBecomeActive() {
  }

  func applicationWillResignActive() {
  }

  func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
    for task in backgroundTasks {
      switch task {
      case let backgroundTask as WKApplicationRefreshBackgroundTask:
        backgroundTask.setTaskCompletedWithSnapshot(false)
      case let snapshotTask as WKSnapshotRefreshBackgroundTask:
        snapshotTask.setTaskCompleted(restoredDefaultState: true,
                                      estimatedSnapshotExpiration: Date.distantFuture,
                                      userInfo: nil)
      case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
        connectivityTask.setTaskCompletedWithSnapshot(false)
      case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
        urlSessionTask.setTaskCompletedWithSnapshot(false)
      default:
        task.setTaskCompletedWithSnapshot(false)
      }
    }
  }

}
