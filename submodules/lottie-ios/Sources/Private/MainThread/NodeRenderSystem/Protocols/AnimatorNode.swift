






import Foundation
import QuartzCore





protocol NodeOutput {

  
  var parent: NodeOutput? { get }

  
  func hasOutputUpdates(_ forFrame: CGFloat) -> Bool

  var outputPath: CGPath? { get }

  var isEnabled: Bool { get set }
}















protocol AnimatorNode: AnyObject, KeypathSearchable {

  
  
  
  
  
  
  var propertyMap: NodePropertyMap & KeypathSearchable { get }

  
  var parentNode: AnimatorNode? { get }

  
  var outputNode: NodeOutput { get }

  
  func rebuildOutputs(frame: CGFloat)

  
  var isEnabled: Bool { get set }
  var hasLocalUpdates: Bool { get set }
  var hasUpstreamUpdates: Bool { get set }
  var lastUpdateFrame: CGFloat? { get set }

  

  
  func localUpdatesPermeateDownstream() -> Bool
  func forceUpstreamOutputUpdates() -> Bool

  
  func performAdditionalLocalUpdates(frame: CGFloat, forceLocalUpdate: Bool) -> Bool
  func performAdditionalOutputUpdates(_ frame: CGFloat, forceOutputUpdate: Bool)

  
  func shouldRebuildOutputs(frame: CGFloat) -> Bool
}


extension AnimatorNode {

  func shouldRebuildOutputs(frame _: CGFloat) -> Bool {
    hasLocalUpdates
  }

  func localUpdatesPermeateDownstream() -> Bool {
    
    true
  }

  func forceUpstreamOutputUpdates() -> Bool {
    
    false
  }

  func performAdditionalLocalUpdates(frame _: CGFloat, forceLocalUpdate: Bool) -> Bool {
    
    forceLocalUpdate
  }

  func performAdditionalOutputUpdates(_: CGFloat, forceOutputUpdate _: Bool) {
    
  }

  @discardableResult
  func updateOutputs(_ frame: CGFloat, forceOutputUpdate: Bool) -> Bool {
    guard isEnabled else {
      
      lastUpdateFrame = frame
      return parentNode?.updateOutputs(frame, forceOutputUpdate: forceOutputUpdate) ?? false
    }

    if forceOutputUpdate == false && lastUpdateFrame != nil && lastUpdateFrame! == frame {
      
      return hasUpstreamUpdates || hasLocalUpdates
    }

    
    let forceUpstreamUpdates = forceOutputUpdate || forceUpstreamOutputUpdates()

    
    hasUpstreamUpdates = (
      parentNode?
        .updateOutputs(frame, forceOutputUpdate: forceUpstreamUpdates) ?? false || hasUpstreamUpdates)

    
    performAdditionalOutputUpdates(frame, forceOutputUpdate: forceUpstreamUpdates)

    
    if forceUpstreamUpdates || shouldRebuildOutputs(frame: frame) {
      lastUpdateFrame = frame
      rebuildOutputs(frame: frame)
    }
    return hasUpstreamUpdates || hasLocalUpdates
  }

  
  @discardableResult
  func updateContents(_ frame: CGFloat, forceLocalUpdate: Bool) -> Bool {
    guard isEnabled else {
      
      return parentNode?.updateContents(frame, forceLocalUpdate: forceLocalUpdate) ?? false
    }

    if forceLocalUpdate == false && lastUpdateFrame != nil && lastUpdateFrame! == frame {
      
      return localUpdatesPermeateDownstream() ? hasUpstreamUpdates || hasLocalUpdates : hasUpstreamUpdates
    }

    
    hasLocalUpdates = forceLocalUpdate ? forceLocalUpdate : propertyMap.needsLocalUpdate(frame: frame)

    
    hasUpstreamUpdates = parentNode?.updateContents(frame, forceLocalUpdate: forceLocalUpdate) ?? false

    
    if hasLocalUpdates {
      
      propertyMap.updateNodeProperties(frame: frame)
    }

    
    hasUpstreamUpdates = performAdditionalLocalUpdates(frame: frame, forceLocalUpdate: forceLocalUpdate) || hasUpstreamUpdates

    
    return localUpdatesPermeateDownstream() ? hasUpstreamUpdates || hasLocalUpdates : hasUpstreamUpdates
  }

  func updateTree(_ frame: CGFloat, forceUpdates: Bool = false) {
    updateContents(frame, forceLocalUpdate: forceUpdates)
    updateOutputs(frame, forceOutputUpdate: forceUpdates)
  }

}

extension AnimatorNode {
  
  

  var keypathName: String {
    propertyMap.keypathName
  }

  var keypathProperties: [String: AnyNodeProperty] {
    propertyMap.keypathProperties
  }

  var childKeypaths: [KeypathSearchable] {
    propertyMap.childKeypaths
  }

  var keypathLayer: CALayer? {
    nil
  }

}
