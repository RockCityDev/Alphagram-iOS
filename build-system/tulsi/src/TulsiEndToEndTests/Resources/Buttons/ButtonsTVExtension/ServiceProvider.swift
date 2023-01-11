

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Foundation
import TVServices

class ServiceProvider: NSObject, TVTopShelfProvider {

  override init() {
      super.init()
  }

  

  var topShelfStyle: TVTopShelfContentStyle {
      
      return .sectioned
  }

  var topShelfItems: [TVContentItem] {
      
      return []
  }

}

