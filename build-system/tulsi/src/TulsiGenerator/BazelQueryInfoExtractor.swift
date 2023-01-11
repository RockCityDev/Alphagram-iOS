

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Foundation




final class BazelQueryInfoExtractor: QueuedLogging {

  enum ExtractorError: Error {
    
    case invalidBazelPath
  }

  
  var bazelURL: URL
  
  let workspaceRootURL: URL
  
  private let bazelUniversalFlags: BazelFlags

  private let localizedMessageLogger: LocalizedMessageLogger
  private var queuedInfoMessages = [String]()

  private typealias CompletionHandler = (Process, Data, String?, String) -> Void

  init(bazelURL: URL,
       workspaceRootURL: URL,
       bazelUniversalFlags: BazelFlags,
       localizedMessageLogger: LocalizedMessageLogger) {
    self.bazelURL = bazelURL
    self.workspaceRootURL = workspaceRootURL
    self.bazelUniversalFlags = bazelUniversalFlags
    self.localizedMessageLogger = localizedMessageLogger
  }

  func extractTargetRulesFromPackages(_ packages: [String]) -> [RuleInfo] {
    guard !packages.isEmpty else {
      return []
    }

    let profilingStart = localizedMessageLogger.startProfiling("fetch_rules",
                                                               message: "Fetching rules for packages \(packages)")
    var infos = [RuleInfo]()
    let query = packages.map({ "kind(rule, \($0):all)"}).joined(separator: "+")
    do {
      let (process, data, stderr, debugInfo) =
          try self.bazelSynchronousQueryProcess(query,
                                                outputKind: "xml",
                                                loggingIdentifier: "bazel_query_fetch_rules")
      if process.terminationStatus != 0 {
        showExtractionError(debugInfo, stderr: stderr, displayLastLineIfNoErrorLines: true)
      } else if let entries = self.extractRuleInfosFromBazelXMLOutput(data) {
        infos = entries
      }
    } catch {
      
      return []
    }

    localizedMessageLogger.logProfilingEnd(profilingStart)
    return infos
  }

  
  func extractBuildfiles<T: Collection>(_ targets: T) -> Set<BuildLabel> where T.Iterator.Element == BuildLabel {
    if targets.isEmpty { return Set() }

    let profilingStart = localizedMessageLogger.startProfiling("extracting_skylark_files",
                                                               message: "Finding Skylark files for \(targets.count) rules")

    let joinedLabels = targets.map { $0.value }.joined(separator: " + ")
    let query = "buildfiles(deps(\(joinedLabels)))"
    let buildFiles: Set<BuildLabel>
    do {
      
      
      let (_, data, _, debugInfo) = try self.bazelSynchronousQueryProcess(query,
                                                                          outputKind: "xml",
                                                                          additionalArguments: ["--keep_going"],
                                                                          loggingIdentifier: "bazel_query_extracting_skylark_files")
      self.queuedInfoMessages.append(debugInfo)

      if let labels = extractSourceFileLabelsFromBazelXMLOutput(data) {
        buildFiles = Set(labels)
      } else {
        localizedMessageLogger.warning("BazelBuildfilesQueryFailed",
                                       comment: "Bazel 'buildfiles' query failed to extract information.")
        buildFiles = Set()
      }

      localizedMessageLogger.logProfilingEnd(profilingStart)
    } catch {
      
      return Set()
    }

    return buildFiles
  }

  

  private func showExtractionError(_ debugInfo: String,
                                   stderr: String?,
                                   displayLastLineIfNoErrorLines: Bool = false) {
    localizedMessageLogger.infoMessage(debugInfo)
    let details: String?
    if let stderr = stderr {
      if displayLastLineIfNoErrorLines {
        details = BazelErrorExtractor.firstErrorLinesOrLastLinesFromString(stderr)
      } else {
        details = BazelErrorExtractor.firstErrorLinesFromString(stderr)
      }
    } else {
      details = nil
    }
    localizedMessageLogger.error("BazelInfoExtractionFailed",
                                 comment: "Error message for when a Bazel extractor did not complete successfully. Details are logged separately.",
                                 details: details)
  }

  
  
  private func bazelQueryProcess(_ query: String,
                                 outputKind: String? = nil,
                                 additionalArguments: [String] = [],
                                 message: String = "",
                                 loggingIdentifier: String? = nil,
                                 terminationHandler: @escaping CompletionHandler) throws -> Process {
    guard FileManager.default.fileExists(atPath: bazelURL.path) else {
      localizedMessageLogger.error("BazelBinaryNotFound",
                                   comment: "Error to show when the bazel binary cannot be found at the previously saved location %1$@.",
                                   values: bazelURL as NSURL)
      throw ExtractorError.invalidBazelPath
    }

    var arguments = [
        "--max_idle_secs=60",
    ]
    arguments.append(contentsOf: bazelUniversalFlags.startup)
    arguments.append("query")
    arguments.append(contentsOf: bazelUniversalFlags.build)
    arguments.append(contentsOf: [
        "--announce_rc",  
        "--noimplicit_deps",
        "--order_output=no",
        "--noshow_loading_progress",
        "--noshow_progress",
        query
    ])
    arguments.append(contentsOf: additionalArguments)
    if let kind = outputKind {
      arguments.append(contentsOf: ["--output", kind])
    }

    var message = message
    if message != "" {
      message = "\(message)\n"
    }

    let process = TulsiProcessRunner.createProcess(bazelURL.path,
                                                   arguments: arguments,
                                                   messageLogger: localizedMessageLogger,
                                                   loggingIdentifier: loggingIdentifier) {
      completionInfo in
        let debugInfoFormatString = NSLocalizedString("DebugInfoForBazelCommand",
                                                      bundle: Bundle(for: type(of: self)),
                                                      comment: "Provides general information about a Bazel failure; a more detailed error may be reported elsewhere. The Bazel command is %1$@, exit code is %2$d, stderr %3$@.")
        let stderr = NSString(data: completionInfo.stderr, encoding: String.Encoding.utf8.rawValue)
        let debugInfo = String(format: debugInfoFormatString,
                               completionInfo.commandlineString,
                               completionInfo.terminationStatus,
                               stderr ?? "<No STDERR>")

      terminationHandler(completionInfo.process,
                         completionInfo.stdout,
                         stderr as String?,
                         debugInfo)
    }

    return process
  }

  
  private func bazelSynchronousQueryProcess(_ query: String,
                                            outputKind: String? = nil,
                                            additionalArguments: [String] = [],
                                            message: String = "",
                                            loggingIdentifier: String? = nil) throws -> (bazelProcess: Process,
                                                                                         returnedData: Data,
                                                                                         stderrString: String?,
                                                                                         debugInfo: String) {
    let semaphore = DispatchSemaphore(value: 0)
    var data: Data! = nil
    var stderr: String? = nil
    var info: String! = nil

    let process = try bazelQueryProcess(query,
                                        outputKind: outputKind,
                                        additionalArguments: additionalArguments,
                                        message: message,
                                        loggingIdentifier: loggingIdentifier) {
      (_: Process, returnedData: Data, stderrString: String?, debugInfo: String) in
        data = returnedData
        stderr = stderrString
        info = debugInfo
      semaphore.signal()
    }

    process.currentDirectoryPath = workspaceRootURL.path
    process.launch()

    _ = semaphore.wait(timeout: DispatchTime.distantFuture)
    return (process, data, stderr, info)
  }

  private func extractRuleInfosWithRuleInputsFromBazelXMLOutput(_ bazelOutput: Data) -> [RuleInfo: Set<BuildLabel>]? {
    do {
      var infos = [RuleInfo: Set<BuildLabel>]()
      let doc = try XMLDocument(data: bazelOutput, options: XMLNode.Options(rawValue: 0))
      let rules = try doc.nodes(forXPath: "/query/rule")
      for ruleNode in rules {
        guard let ruleElement = ruleNode as? XMLElement else {
          localizedMessageLogger.error("BazelResponseXMLNonElementType",
                                       comment: "General error to show when the XML parser returns something other " +
                                               "than an NSXMLElement. This should never happen in practice.")
          continue
        }
        guard let ruleLabel = ruleElement.attribute(forName: "name")?.stringValue else {
          localizedMessageLogger.error("BazelResponseMissingRequiredAttribute",
                                       comment: "Bazel response XML element %1$@ was found but was missing an attribute named %2$@.",
                                       values: ruleElement, "name")
          continue
        }
        guard let ruleType = ruleElement.attribute(forName: "class")?.stringValue else {
          localizedMessageLogger.error("BazelResponseMissingRequiredAttribute",
                                       comment: "Bazel response XML element %1$@ was found but was missing an attribute named %2$@.",
                                       values: ruleElement, "class")
          continue
        }

        func extractLabelsFromXpath(_ xpath: String) throws -> Set<BuildLabel> {
          var labelSet = Set<BuildLabel>()
          let nodes = try ruleElement.nodes(forXPath: xpath)
          for node in nodes {
            guard let label = node.stringValue else {
              localizedMessageLogger.error("BazelResponseLabelAttributeInvalid",
                                           comment: "Bazel response XML element %1$@ should have a valid string value but does not.",
                                           values: node)
              continue
            }
            labelSet.insert(BuildLabel(label))
          }
          return labelSet
        }

        
        
        var linkedTargetLabels = Set<BuildLabel>()
        linkedTargetLabels.formUnion(
            try extractLabelsFromXpath("./label[@name='test_host']/@value"))

        let entry = RuleInfo(label: BuildLabel(ruleLabel),
                             type: ruleType,
                             linkedTargetLabels: linkedTargetLabels)

        infos[entry] = try extractLabelsFromXpath("./rule-input/@name")
      }
      return infos
    } catch let e as NSError {
      localizedMessageLogger.error("BazelResponseXMLParsingFailed",
                                   comment: "Extractor Bazel output failed to be parsed as XML with error %1$@. This may be a Bazel bug or a bad BUILD file.",
                                   values: e.localizedDescription)
      return nil
    }
  }

  private func extractRuleInfosFromBazelXMLOutput(_ bazelOutput: Data) -> [RuleInfo]? {
    if let infoMap = extractRuleInfosWithRuleInputsFromBazelXMLOutput(bazelOutput) {
      return [RuleInfo](infoMap.keys)
    }
    return nil
  }

  private func extractSourceFileLabelsFromBazelXMLOutput(_ bazelOutput: Data) -> Set<BuildLabel>? {
    do {
      let doc = try XMLDocument(data: bazelOutput, options: XMLNode.Options(rawValue: 0))
      let fileLabels = try doc.nodes(forXPath: "/query/source-file/@name")
      var extractedLabels = Set<BuildLabel>()
      for labelNode in fileLabels {
        guard let value = labelNode.stringValue else {
          localizedMessageLogger.error("BazelResponseLabelAttributeInvalid",
                                       comment: "Bazel response XML element %1$@ should have a valid string value but does not.",
                                       values: labelNode)
          continue
        }
        extractedLabels.insert(BuildLabel(value))
      }
      return extractedLabels
    } catch let e as NSError {
      localizedMessageLogger.error("BazelResponseXMLParsingFailed",
                                   comment: "Extractor Bazel output failed to be parsed as XML with error %1$@. This may be a Bazel bug or a bad BUILD file.",
                                   values: e.localizedDescription)
      return nil
    }
  }

  

  func logQueuedInfoMessages() {
    guard !self.queuedInfoMessages.isEmpty else {
      return
    }
    localizedMessageLogger.debugMessage("Log of Bazel query output follows:")
    for message in self.queuedInfoMessages {
      localizedMessageLogger.debugMessage(message)
    }
    self.queuedInfoMessages.removeAll()
  }

  var hasQueuedInfoMessages: Bool {
    return !self.queuedInfoMessages.isEmpty
  }
}
