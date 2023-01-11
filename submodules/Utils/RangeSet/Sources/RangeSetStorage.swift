










struct _RangeSetStorage<T: Comparable> {
  fileprivate enum _Storage {
    case empty
    case singleRange(high: Int, low: Int32)
    case variadic([Range<T>])
  }
  
  fileprivate var _storage: _Storage
  
  init() {
    _storage = .empty
  }
  
  init(_ range: Range<T>) {
    if let intRange = range as? Range<Int>,
      let lowerBound = Int32(exactly: intRange.lowerBound)
    {
      _storage = .singleRange(high: intRange.upperBound, low: lowerBound)
    } else {
      _storage = .variadic([range])
    }
  }
  
  init(_ ranges: [Range<T>]) {
    _storage = .variadic(ranges)
  }
  
  func unsafeRange(low: Int32, high: Int) -> Range<T> {
    unsafeBitCast(Int(low)..<high, to: Range<T>.self)
  }
}


// conformance, since the same "value" can be represented by different





extension _RangeSetStorage: Equatable {
  static func == (lhs: _RangeSetStorage, rhs: _RangeSetStorage) -> Bool {
    switch (lhs._storage, rhs._storage) {
    case (.empty, .empty):
      return true
    case (.empty, .singleRange), (.singleRange, .empty):
      return false
    case let (.empty, .variadic(ranges)),
         let (.variadic(ranges), .empty):
      return ranges.isEmpty
      
    case let (.singleRange(lhsHigh, lhsLow), .singleRange(rhsHigh, rhsLow)):
      return (lhsLow, lhsHigh) == (rhsLow, rhsHigh)
      
    case let (.singleRange(high, low), .variadic(ranges)),
         let (.variadic(ranges), .singleRange(high, low)):
      return ranges.count == 1 &&
        (ranges[0] as! Range<Int>) == Int(low)..<high
      
    case let (.variadic(lhsRanges), .variadic(rhsRanges)):
      return lhsRanges == rhsRanges
    }
  }
}

extension _RangeSetStorage: Hashable where T: Hashable {
  func hash(into hasher: inout Hasher) {
    for range in self {
      hasher.combine(range)
    }
  }
}

extension _RangeSetStorage: RandomAccessCollection, MutableCollection {
  var startIndex: Int { 0 }
  
  var endIndex: Int {
    switch _storage {
    case .empty: return 0
    case .singleRange: return 1
    case let .variadic(ranges): return ranges.count
    }
  }
  
  subscript(i: Int) -> Range<T> {
    get {
      switch _storage {
      case .empty: fatalError("Can't access elements of empty storage")
      case let .singleRange(high, low):
        assert(T.self == Int.self)
        return unsafeRange(low: low, high: high)
      case let .variadic(ranges):
        return ranges[i]
      }
    }
    set {
      switch _storage {
      case .empty: fatalError("Can't access elements of empty storage")
      case .singleRange:
        assert(T.self == Int.self)
        let intRange = newValue as! Range<Int>
        if let lowerBound = Int32(exactly: intRange.lowerBound) {
          _storage = .singleRange(high: intRange.upperBound, low: lowerBound)
        } else {
          _storage = .variadic([newValue])
        }
      case .variadic(var ranges):
        
        
        _storage = .empty
        ranges[i] = newValue
        _storage = .variadic(ranges)
      }
    }
  }
  
  var count: Int {
    switch _storage {
    case .empty: return 0
    case .singleRange: return 1
    case let .variadic(ranges): return ranges.count
    }
  }
}

extension _RangeSetStorage: RangeReplaceableCollection {
  mutating func replaceSubrange<C>(_ subrange: Range<Int>, with newElements: C) where C : Collection, C.Element == Element {
    switch _storage {
    case .empty:
      if !newElements.isEmpty {
        _storage = .variadic(Array(newElements))
      }
      
    case .singleRange(high: let high, low: let low):
      switch (subrange.isEmpty, newElements.isEmpty) {
      case (false, true):
        
        _storage = .empty
        
      case (false, false):
        
        
        _storage = .variadic(Array(newElements))
        
      case (true, true):
        
        break
        
      case (true, false):
        
        
        var ranges: [Range<T>]
        if subrange.lowerBound == 0 {
          ranges = Array(newElements)
          ranges.append(unsafeRange(low: low, high: high))
        } else {
          ranges = [unsafeRange(low: low, high: high)]
          ranges.append(contentsOf: newElements)
        }
        _storage = .variadic(ranges)
      }
      
    case .variadic(var ranges):
      
      
      _storage = .empty
      ranges.replaceSubrange(subrange, with: newElements)
      _storage = .variadic(ranges)
    }
  }
}
