import Foundation
import UIKit

public final class Switch: Component {
    
    
    public let thumbTintColor: UIColor?
    
    public let tintColor: UIColor?
    
    public let onTintColor: UIColor?
    
    public var isOn = false
    
    public let valueChange: ((Bool) -> Void)?

    public init(
        tintColor: UIColor? = nil,
        thumbTintColor: UIColor? = nil,
        onTintColor: UIColor? = nil,
        isOn:Bool = false,
        valueChange:((Bool) -> Void)? = nil
    ) {
        self.tintColor = tintColor
        self.thumbTintColor = thumbTintColor
        self.onTintColor = onTintColor
        self.valueChange = valueChange
        self.isOn = isOn
    }
    
    @objc public func valueDidChange() {
        self.isOn = !isOn
        self.valueChange?(self.isOn)
    }

    public static func ==(lhs: Switch, rhs: Switch) -> Bool {
        if lhs.thumbTintColor !== rhs.thumbTintColor {
            return false
        }
        if lhs.onTintColor !== rhs.onTintColor {
            return false
        }
        if lhs.tintColor != rhs.tintColor {
            return false
        }
        return true
    }

    public final class View: UISwitch {
        init() {
            super.init(frame: CGRect())
        }

        required init?(coder aDecoder: NSCoder) {
            preconditionFailure()
        }

        func update(component: Switch, availableSize: CGSize, environment: Environment<Empty>, transition: Transition) -> CGSize {
            self.thumbTintColor = component.thumbTintColor
            self.tintColor = component.tintColor
            self.onTintColor = component.onTintColor
            self.isOn = component.isOn
            self.addTarget(component, action: #selector(component.valueDidChange), for: .valueChanged)
            return availableSize
        }
    }

    public func makeView() -> View {
        return View()
    }

    public func update(view: View, availableSize: CGSize, state: EmptyComponentState, environment: Environment<Empty>, transition: Transition) -> CGSize {
        return view.update(component: self, availableSize: availableSize, environment: environment, transition: transition)
    }
}
