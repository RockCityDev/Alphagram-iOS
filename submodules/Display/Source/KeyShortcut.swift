import UIKit

public struct KeyShortcut: Hashable {
    let title: String
    let input: String
    let modifiers: UIKeyModifierFlags
    let action: () -> Void
    
    public init(title: String = "", input: String = "", modifiers: UIKeyModifierFlags = [], action: @escaping () -> Void = {}) {
        self.title = title
        self.input = input
        self.modifiers = modifiers
        self.action = action
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.input)
        hasher.combine(self.modifiers)
    }
    
    public static func ==(lhs: KeyShortcut, rhs: KeyShortcut) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

extension UIKeyModifierFlags: Hashable {
    public var hashValue: Int {
        return self.rawValue
    }
}

extension KeyShortcut {
    var uiKeyCommand: UIKeyCommand {
        let command = UIKeyCommand(input: self.input, modifierFlags: self.modifiers, action: #selector(KeyShortcutsController.handleKeyCommand(_:)), discoverabilityTitle: self.title)
        if #available(iOS 15.0, *), ["\t", UIKeyCommand.inputUpArrow, UIKeyCommand.inputDownArrow, UIKeyCommand.inputLeftArrow, UIKeyCommand.inputRightArrow].contains(command.input) && self.modifiers.isEmpty {
            command.wantsPriorityOverSystemBehavior = true
        }
        return command
    }
    
    func isEqual(to command: UIKeyCommand) -> Bool {
        return self.input == command.input && self.modifiers == command.modifierFlags
    }
}
