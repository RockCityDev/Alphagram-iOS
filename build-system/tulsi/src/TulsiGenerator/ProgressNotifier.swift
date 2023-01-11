

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Foundation



final class ProgressNotifier {
  private let name: String
  private let maxValue: Int
  private let indeterminate: Bool

  var value: Int = 0 {
    didSet {
      Thread.doOnMainQueue() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.post(name: Notification.Name(rawValue: ProgressUpdatingTaskProgress),
                                                object: self,
                                                userInfo: [
                                                    ProgressUpdatingTaskProgressValue: self.value,
                                                ])
      }
    }
  }

  
  init(name: String, maxValue: Int, indeterminate: Bool = false, suppressStart: Bool = false) {
    self.name = name
    self.maxValue = maxValue
    self.indeterminate = indeterminate

    if !suppressStart {
      start()
    }
  }

  func start() {
    Thread.doOnMainQueue() {
      let notificationCenter = NotificationCenter.default
      notificationCenter.post(name: Notification.Name(rawValue: ProgressUpdatingTaskDidStart),
                                              object: self,
                                              userInfo: [
                                                  ProgressUpdatingTaskName: self.name,
                                                  ProgressUpdatingTaskMaxValue: self.maxValue,
                                                  ProgressUpdatingTaskStartIndeterminate: self.indeterminate,
                                              ])
    }
  }

  func incrementValue() {
    Thread.doOnMainQueue() {
      self.value += 1
    }
  }
}
