






import Foundation
import UIKit


public extension Array where Element: QLView {
    
    
    @discardableResult
    func set(_ edge: QLAttribute, of value: CGFloat,
             priority: QLPriority = .required) -> [NSLayoutConstraint] {
        var constraints: [NSLayoutConstraint] = []
        for view in self {
            let constraint = view.set(edge, of: value)
            constraints.append(constraint)
        }
        return constraints
    }
    
    
    @discardableResult
    func set(_ edges: QLAttribute..., of value: CGFloat,
             priority: QLPriority = .required) -> [QLMultipleConstraints] {
        var constraintsArray: [QLMultipleConstraints] = []
        for view in self {
            let constraints = view.set(edges, to: value, priority: priority)
            constraintsArray.append(constraints)
        }
        return constraintsArray
    }
    
    
    @discardableResult
    func spread(_ axis: QLAxis, stretchEdgesToSuperview: Bool = false, offset: CGFloat = 0,
                priority: QLPriority = .required) -> [NSLayoutConstraint] {
        guard isValidForQuickLayout else {
            return []
        }
        let attributes = axis.attributes
        var constraints: [NSLayoutConstraint] = []
        
        if stretchEdgesToSuperview {
            let constraint = first!.layoutToSuperview(attributes.first, offset: offset)!
            constraints.append(constraint)
        }
        
        for (index, view) in enumerated() {
            guard index > 0 else {
                continue
            }
            let previousView = self[index - 1]
            let constraint = view.layout(attributes.first, to: attributes.second, of: previousView, offset: offset, priority: priority)!
            constraints.append(constraint)
        }
        
        if stretchEdgesToSuperview {
            let constraint = last!.layoutToSuperview(attributes.second, offset: -offset)!
            constraints.append(constraint)
        }
        
        return constraints
    }
    
    
    @discardableResult
    func layoutToSuperview(axis: QLAxis, offset: CGFloat = 0,
                           priority: QLPriority = .required) -> [QLAxisConstraints] {
        
        let attributes = axis.attributes
        
        let firstConstraints = layoutToSuperview(attributes.first, offset: offset, priority: priority)
        guard !firstConstraints.isEmpty else {
            return []
        }
        
        let secondConstraints = layoutToSuperview(attributes.second, offset: -offset, priority: priority)
        guard !secondConstraints.isEmpty else {
            return []
        }
        
        var constraints: [QLAxisConstraints] = []
        for (first, second) in zip(firstConstraints, secondConstraints) {
            constraints.append(QLAxisConstraints(first: first, second: second))
        }
        
        return constraints
    }
    
    
    @discardableResult
    func layoutToSuperview(_ edge: QLAttribute, ratio: CGFloat = 1, offset: CGFloat = 0,
                           priority: QLPriority = .required) -> [NSLayoutConstraint] {
        guard isValidForQuickLayout else {
            return []
        }
        return layout(to: edge, of: first!.superview!, ratio: ratio, offset: offset, priority: priority)
    }
    
    
    @discardableResult
    func layout(_ firstEdge: QLAttribute? = nil, to anchorEdge: QLAttribute,
                of anchorView: QLView, ratio: CGFloat = 1, offset: CGFloat = 0,
                priority: QLPriority = .required) -> [NSLayoutConstraint] {
        guard isValidForQuickLayout else {
            return []
        }
        
        let edge: QLAttribute
        if let firstEdge = firstEdge {
            edge = firstEdge
        } else {
            edge = anchorEdge
        }
        
        var result: [NSLayoutConstraint] = []
        for view in self {
            let constraint = view.layout(edge, to: anchorEdge, of: anchorView, ratio: ratio, offset: offset, priority: priority)!
            result.append(constraint)
        }
        return result
    }
    
    
    @discardableResult
    func layout(_ edges: QLAttribute..., to anchorView: QLView,
                ratio: CGFloat = 1, offset: CGFloat = 0,
                priority: QLPriority = .required) -> [QLMultipleConstraints] {
        guard !edges.isEmpty && isValidForQuickLayout else {
            return []
        }
        
        let uniqueEdges = Set(edges)
        var result: [QLMultipleConstraints] = []
        for view in self {
            var multipleConstraints: QLMultipleConstraints = [:]
            for edge in uniqueEdges {
                let constraint = view.layout(to: edge, of: anchorView, ratio: ratio, offset: offset, priority: priority)!
                multipleConstraints[edge] = constraint
            }
            result.append(multipleConstraints)
        }
        return result
    }
    
    
    var isValidForQuickLayout: Bool {
        guard !isEmpty else {
            print("\(String(describing: self)) Error in func: \(#function), Views collection is empty!")
            return false
        }
        
        for view in self {
            guard view.isValidForQuickLayout else {
                print("\(String(describing: self)) Error in func: \(#function)")
                return false
            }
        }
        return true
    }
}
