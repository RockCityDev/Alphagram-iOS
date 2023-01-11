

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Foundation
import Messages

class MessagesViewController: MSMessagesAppViewController {
  @IBAction func sendMessage() {
    self.activeConversation?.sendText("Hello, extension!", completionHandler: nil)
  }
}


