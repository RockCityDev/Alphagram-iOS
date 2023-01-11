

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Cocoa




class FilteredOpenPanel: NSOpenPanel, NSOpenSavePanelDelegate {
  typealias FilterFunc = (_ sender: FilteredOpenPanel, _ shouldEnableURL: URL) -> Bool

  var filterFunc: FilterFunc? = nil

  static func filteredOpenPanel(_ filter: FilterFunc?) -> FilteredOpenPanel {
    let panel = FilteredOpenPanel()
    panel.filterFunc = filter
    panel.delegate = panel
    return panel
  }

  
  
  static func filteredOpenPanelAcceptingNonPackageDirectoriesAndFilesNamed(_ names: [String]) -> FilteredOpenPanel {
    return filteredOpenPanel(filterNonPackageDirectoriesOrFilesMatchingNames(names))
  }

  

  func panel(_ sender: Any, shouldEnable url: URL) -> Bool {
    return filterFunc?(self, url) ?? true
  }

  

  static func filterNonPackageDirectoriesOrFilesMatchingNames(_ validFiles: [String]) -> FilterFunc {
    return { (sender: AnyObject, url: URL) -> Bool in
      var isDir: AnyObject?
      var isPackage: AnyObject?
      do {
        try (url as NSURL).getResourceValue(&isDir, forKey: URLResourceKey.isDirectoryKey)
        try (url as NSURL).getResourceValue(&isPackage, forKey: URLResourceKey.isPackageKey)
        if let isDir = isDir as? NSNumber, let isPackage = isPackage as? NSNumber, !isPackage.boolValue {
          if isDir.boolValue { return true }
          return validFiles.contains(url.lastPathComponent)
        }
      } catch _ {
        
      }
      return false
    }
  }
}

