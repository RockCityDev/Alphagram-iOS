






import Foundation

fileprivate extension Int {
    var isValidDisplayPriority: Bool {
        return self >= EKAttributes.Precedence.Priority.minRawValue && self <= EKAttributes.Precedence.Priority.maxRawValue
    }
}

public extension EKAttributes {
    
    
    enum Precedence {
        
        
        public struct Priority: Hashable, Equatable, RawRepresentable, Comparable {
            public var rawValue: Int
            
            public var hashValue: Int {
                return rawValue
            }
            
            public init(_ rawValue: Int) {
                assert(rawValue.isValidDisplayPriority, "Display Priority must be in range [\(Priority.minRawValue)...\(Priority.maxRawValue)]")
                self.rawValue = rawValue
            }
            
            public init(rawValue: Int) {
                assert(rawValue.isValidDisplayPriority, "Display Priority must be in range [\(Priority.minRawValue)...\(Priority.maxRawValue)]")
                self.rawValue = rawValue
            }
            
            public static func == (lhs: Priority, rhs: Priority) -> Bool {
                return lhs.rawValue == rhs.rawValue
            }
            
            public static func < (lhs: Priority, rhs: Priority) -> Bool {
                return lhs.rawValue < rhs.rawValue
            }
        }
        
        
        public enum QueueingHeuristic {
            
            
            public static var value = QueueingHeuristic.priority
            
            
            case chronological
            
            
            case priority
            
            
            var heuristic: EntryCachingHeuristic {
                switch self {
                case .chronological:
                    return EKEntryChronologicalQueue()
                case .priority:
                    return EKEntryPriorityQueue()
                }
            }
        }
        
        
        case override(priority: Priority, dropEnqueuedEntries: Bool)
        
        
        case enqueue(priority: Priority)
        
        var isEnqueue: Bool {
            switch self {
            case .enqueue:
                return true
            default:
                return false
            }
        }
        
        
        public var priority: Priority {
            set {
                switch self {
                case .enqueue(priority: _):
                    self = .enqueue(priority: newValue)
                case .override(priority: _, dropEnqueuedEntries: let dropEnqueuedEntries):
                    self = .override(priority: newValue, dropEnqueuedEntries: dropEnqueuedEntries)
                }
            }
            get {
                switch self {
                case .enqueue(priority: let priority):
                    return priority
                case .override(priority: let priority, dropEnqueuedEntries: _):
                    return priority
                }
            }
        }
    }
}


public extension EKAttributes.Precedence.Priority {
    static let maxRawValue = 1000
    static let highRawValue = 750
    static let normalRawValue = 500
    static let lowRawValue = 250
    static let minRawValue = 0

    
    static let max = EKAttributes.Precedence.Priority(rawValue: maxRawValue)
    static let high = EKAttributes.Precedence.Priority(rawValue: highRawValue)
    static let normal = EKAttributes.Precedence.Priority(rawValue: normalRawValue)
    static let low = EKAttributes.Precedence.Priority(rawValue: lowRawValue)
    static let min = EKAttributes.Precedence.Priority(rawValue: minRawValue)
}

