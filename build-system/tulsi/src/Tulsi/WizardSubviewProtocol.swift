

// Licensed under the Apache License, Version 2.0 (the "License");






// distributed under the License is distributed on an "AS IS" BASIS,




import Foundation


@objc
protocol WizardSubviewProtocol {
  
  var presentingWizardViewController: ConfigEditorWizardViewController? { get set }

  /// Invoked when the wizard subview is about to become active due to a "next" navigation.
  @objc optional func wizardSubviewWillActivateMovingForward()

  /// Invoked when the wizard subview is about to become active due to a "previous" navigation.
  @objc optional func wizardSubviewWillActivateMovingBackward()

  /// Invoked when the wizard subview is about to become inactive due to a "next" navigation. If the
  
  @objc optional func shouldWizardSubviewDeactivateMovingForward() -> Bool

  /// Invoked when the wizard subview is about to become inactive due to a "previous" navigation. If
  
  @objc optional func shouldWizardSubviewDeactivateMovingBackward() -> Bool

  
  @objc optional func wizardSubviewDidDeactivate()
}
