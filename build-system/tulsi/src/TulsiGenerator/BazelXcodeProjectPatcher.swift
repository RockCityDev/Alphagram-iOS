

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Foundation





final class BazelXcodeProjectPatcher {

  
  let fileManager: FileManager

  init(fileManager: FileManager) {
    self.fileManager = fileManager
  }

  
  
  private func patchFileReference(xcodeProject: PBXProject, file: PBXFileReference, url: URL, workspaceRootURL: URL) {
    
    guard !fileManager.fileExists(atPath: url.path) else { return }

    
    guard file.sourceTree == .Group else { return }

    
    
    let parent = file.parent as! PBXGroup

    
    
    
    
    
    
    
    
    //     "You don’t have permission to save the file “Contents.json” in the folder <X>."
    
    guard !url.path.hasSuffix(".xcassets") else {
      parent.removeChild(file)
      return
    }

    
    
    
    let newPath = "\(xcodeProject.name).xcodeproj/\(PBXTargetGenerator.TulsiExecutionRootSymlinkPath)/\(file.path!)"
    parent.updatePathForChildFile(file, toPath: newPath, sourceTree: .SourceRoot)
  }

  
  
  func patchBazelRelativeReferences(_ xcodeProject: PBXProject,
                                    _ workspaceRootURL : URL) {
    
    var queue = xcodeProject.mainGroup.children.filter{ $0.name != "external" }

    while !queue.isEmpty {
      let ref = queue.remove(at: 0)
      if let group = ref as? PBXGroup {
        
        queue.append(contentsOf: group.children)
      } else if let file = ref as? PBXFileReference,
                let fileURL = URL(string: file.path!, relativeTo: workspaceRootURL) {
        self.patchFileReference(xcodeProject: xcodeProject, file: file, url: fileURL,
                                workspaceRootURL: workspaceRootURL)
      }
    }
  }

  // Handles patching any groups that were generated under Bazel's magical "external" container to
  
  func patchExternalRepositoryReferences(_ xcodeProject: PBXProject) {
    let mainGroup = xcodeProject.mainGroup
    guard let externalGroup = mainGroup.childGroupsByName["external"] else { return }

    
    let childGroups = externalGroup.children.filter { $0 is PBXGroup } as! [PBXGroup]

    for child in childGroups {
      
      
      
      
      let resolvedPath = "\(xcodeProject.name).xcodeproj/\(PBXTargetGenerator.TulsiOutputBaseSymlinkPath)/external/\(child.name)"
      let newChild = mainGroup.getOrCreateChildGroupByName("@\(child.name)",
                                                           path: resolvedPath,
                                                           sourceTree: .SourceRoot)
      newChild.migrateChildrenOfGroup(child)
    }
    mainGroup.removeChild(externalGroup)
  }
}
