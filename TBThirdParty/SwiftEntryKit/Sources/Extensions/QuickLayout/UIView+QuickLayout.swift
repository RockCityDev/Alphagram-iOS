






import Foundation
import UIKit

public extension QLView {
    
    
    @discardableResult
    func set(_ edge: QLAttribute, of value: CGFloat, relation: QLRelation = .equal,
             ratio: CGFloat = 1.0, priority: QLPriority = .required) -> NSLayoutConstraint {
        if translatesAutoresizingMaskIntoConstraints {
            translatesAutoresizingMaskIntoConstraints = false
        }
        let constraint = NSLayoutConstraint(item: self, attribute: edge, relatedBy: relation, toItem: nil, attribute: .notAnAttribute, multiplier: ratio, constant: value)
        constraint.priority = priority
        addConstraint(constraint)
        return constraint
    }
    
    
    @discardableResult
    func set(_ edges: QLAttribute..., of value: CGFloat, relation: QLRelation = .equal,
             ratio: CGFloat = 1.0, priority: QLPriority = .required) -> QLMultipleConstraints {
        return set(edges, to: value, relation: relation, ratio: ratio, priority: priority)
    }
    
    
    @discardableResult
    func set(_ edges: [QLAttribute], to value: CGFloat, relation: QLRelation = .equal,
             ratio: CGFloat = 1.0, priority: QLPriority = .required) -> QLMultipleConstraints {
        var constraints: QLMultipleConstraints = [:]
        let uniqueEdges = Set(edges)
        for edge in uniqueEdges {
            let constraint = set(edge, of: value, priority: priority)
            constraints[edge] = constraint
        }
        return constraints
    }
    
    
    @discardableResult
    func layout(_ edge: QLAttribute? = nil, to otherEdge: QLAttribute, of view: QLView,
                relation: QLRelation = .equal, ratio: CGFloat = 1.0, offset: CGFloat = 0,
                priority: QLPriority = .required) -> NSLayoutConstraint? {
        guard isValidForQuickLayout else {
            print("\(String(describing: self)) Error in func: \(#function)")
            return nil
        }
        let constraint = NSLayoutConstraint(item: self, attribute: edge ?? otherEdge, relatedBy: relation, toItem: view, attribute: otherEdge, multiplier: ratio, constant: offset)
        constraint.priority = priority
        superview!.addConstraint(constraint)
        return constraint
    }
    
    
    @discardableResult
    func layout(_ edges: QLAttribute..., to view: QLView, relation: QLRelation = .equal,
                ratio: CGFloat = 1.0, offset: CGFloat = 0,
                priority: QLPriority = .required) -> QLMultipleConstraints {
        var constraints: QLMultipleConstraints = [:]
        guard isValidForQuickLayout else {
            print("\(String(describing: self)) Error in func: \(#function)")
            return constraints
        }
        let uniqueEdges = Set(edges)
        for edge in uniqueEdges {
            let constraint = NSLayoutConstraint(item: self, attribute: edge, relatedBy: relation, toItem: view, attribute: edge, multiplier: ratio, constant: offset)
            constraint.priority = priority
            superview!.addConstraint(constraint)
            constraints[edge] = constraint
        }
        return constraints
    }
    
    
    @discardableResult
    func layoutToSuperview(_ edge: QLAttribute, relation: QLRelation = .equal,
                           ratio: CGFloat = 1, offset: CGFloat = 0,
                           priority: QLPriority = .required) -> NSLayoutConstraint? {
        guard isValidForQuickLayout else {
            print("\(String(describing: self)) Error in func: \(#function)")
            return nil
        }
        let constraint = NSLayoutConstraint(item: self, attribute: edge, relatedBy: relation, toItem: superview, attribute: edge, multiplier: ratio, constant: offset)
        constraint.priority = priority
        superview!.addConstraint(constraint)
        return constraint
    }
    
    
    @discardableResult
    func layoutToSuperview(_ edges: QLAttribute..., relation: QLRelation = .equal,
                           ratio: CGFloat = 1, offset: CGFloat = 0,
                           priority: QLPriority = .required) -> QLMultipleConstraints {
        var constraints: QLMultipleConstraints = [:]
        guard !edges.isEmpty && isValidForQuickLayout else {
            return constraints
        }
        let uniqueEdges = Set(edges)
        for edge in uniqueEdges {
            let constraint = NSLayoutConstraint(item: self, attribute: edge, relatedBy: relation, toItem: superview, attribute: edge, multiplier: ratio, constant: offset)
            constraint.priority = priority
            superview!.addConstraint(constraint)
            constraints[edge] = constraint
        }
        return constraints
    }
    
    
    @discardableResult
    func layoutToSuperview(axis: QLAxis, offset: CGFloat = 0,
                           priority: QLPriority = .required) -> QLAxisConstraints? {
        let attributes = axis.attributes
        guard let first = layoutToSuperview(attributes.first, offset: offset, priority: priority) else {
            return nil
        }
        guard let second = layoutToSuperview(attributes.second, offset: -offset, priority: priority) else {
            return nil
        }
        return QLAxisConstraints(first: first, second: second)
    }
    
    
    @discardableResult
    func sizeToSuperview(withRatio ratio: CGFloat = 1, offset: CGFloat = 0,
                         priority: QLPriority = .required) -> QLSizeConstraints? {
        let size = layoutToSuperview(.width, .height, ratio: ratio, offset: offset, priority: priority)
        guard !size.isEmpty else {
            return nil
        }
        return QLSizeConstraints(width: size[.width]!, height: size[.height]!)
    }
    
    
    @discardableResult
    func centerInSuperview(offset: CGFloat = 0, priority: QLPriority = .required) -> QLCenterConstraints? {
        let center = layoutToSuperview(.centerX, .centerY, offset: offset)
        guard !center.isEmpty else {
            return nil
        }
        return QLCenterConstraints(x: center[.centerX]!, y: center[.centerY]!)
    }
    
    
    @discardableResult
    func fillSuperview(withSizeRatio ratio: CGFloat = 1, offset: CGFloat = 0,
                       priority: QLPriority = .required) -> QLFillConstraints? {
        guard let center = centerInSuperview(priority: priority) else {
            return nil
        }
        guard let size = sizeToSuperview(withRatio: ratio, offset: offset, priority: priority) else {
            return nil
        }
        return QLFillConstraints(center: center, size: size)
    }
    
    
    var isValidForQuickLayout: Bool {
        guard superview != nil else {
            print("\(String(describing: self)):\(#function) - superview is unexpectedly nullified")
            return false
        }
        if translatesAutoresizingMaskIntoConstraints {
            translatesAutoresizingMaskIntoConstraints = false
        }
        return true
    }
}
