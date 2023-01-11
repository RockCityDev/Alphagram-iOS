

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,






enum HeadlessModeError: Error {
  
  case missingBazelPath
  
  case invalidConfigPath(String)
  
  case invalidConfigFileContents(String)
  
  case invalidProjectFileContents(String)
  
  case explicitOutputOptionRequired
  
  case generationFailed
  
  case invalidBazelPath
  
  case invalidWorkspaceRootOverride
  
  case missingWORKSPACEFile(String)
  
  case missingBuildTargets
  
  case invalidProjectBundleName
  
  case bazelTargetProcessingFailed
}
