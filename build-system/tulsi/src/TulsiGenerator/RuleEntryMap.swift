

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Foundation







public class RuleEntryMap {
  private var labelToEntries = [BuildLabel: [RuleEntry]]()
  private var allEntries = [RuleEntry]()
  private var labelsWithWarning = Set<BuildLabel>()

  private let localizedMessageLogger: LocalizedMessageLogger?

  init(localizedMessageLogger: LocalizedMessageLogger? = nil) {
    self.localizedMessageLogger = localizedMessageLogger
  }

  init(_ ruleEntryMap: RuleEntryMap) {
    localizedMessageLogger = ruleEntryMap.localizedMessageLogger
    allEntries = ruleEntryMap.allEntries
    labelToEntries = ruleEntryMap.labelToEntries
  }

  public var allRuleEntries: [RuleEntry] {
    return allEntries
  }

  public func insert(ruleEntry: RuleEntry) {
    allEntries.append(ruleEntry)
    labelToEntries[ruleEntry.label, default: []].append(ruleEntry)
  }

  public func hasAnyRuleEntry(withBuildLabel buildLabel: BuildLabel) -> Bool {
    return anyRuleEntry(withBuildLabel: buildLabel) != nil
  }

  
  public func anyRuleEntry(withBuildLabel buildLabel: BuildLabel) -> RuleEntry? {
    guard let ruleEntries = labelToEntries[buildLabel] else {
      return nil
    }
    return ruleEntries.last
  }

  
  public func ruleEntries(buildLabel: BuildLabel) -> [RuleEntry] {
    guard let ruleEntries = labelToEntries[buildLabel] else {
      return [RuleEntry]()
    }
    return ruleEntries
  }

  
  public func ruleEntry(buildLabel: BuildLabel, depender: RuleEntry) -> RuleEntry? {
    guard let deploymentTarget = depender.deploymentTarget else {
      localizedMessageLogger?.warning("DependentRuleEntryHasNoDeploymentTarget",
                                      comment: "Error when a RuleEntry with deps does not have a DeploymentTarget. RuleEntry's label is in %1$@, dep's label is in %2$@.",
                                      values: depender.label.description,
                                              buildLabel.description)
      return anyRuleEntry(withBuildLabel: buildLabel)
    }
    return ruleEntry(buildLabel: buildLabel, deploymentTarget: deploymentTarget)
  }

  
  public func ruleEntry(buildLabel: BuildLabel, deploymentTarget: DeploymentTarget) -> RuleEntry? {
    guard let ruleEntries = labelToEntries[buildLabel] else {
      return nil
    }
    guard !ruleEntries.isEmpty else {
      return nil
    }

    
    if ruleEntries.count == 1 {
      return ruleEntries.first
    }

    for ruleEntry in ruleEntries {
      if deploymentTarget == ruleEntry.deploymentTarget {
        return ruleEntry
      }
    }

    if labelsWithWarning.insert(buildLabel).inserted {
      
      localizedMessageLogger?.warning("AmbiguousRuleEntryReference",
                                      comment: "Warning when unable to resolve a RuleEntry for a given DeploymentTarget. RuleEntry's label is in %1$@.",
                                      values: buildLabel.description)
    }

    return ruleEntries.last
  }
}
