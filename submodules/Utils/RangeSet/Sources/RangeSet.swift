


























public struct RangeSet<Bound: Comparable> {
  internal var _ranges = _RangeSetStorage<Bound>()
  
  
  public init() {}
  
  
  
  
  public init(_ range: Range<Bound>) {
    if !range.isEmpty {
      self._ranges = _RangeSetStorage(range)
    }
  }
  
  
  
  
  
  
  
  
  
  public init<S: Sequence>(_ ranges: S) where S.Element == Range<Bound> {
    for range in ranges {
      insert(contentsOf: range)
    }
  }
  
  
  
  
  
  
  
  
  internal func _checkInvariants() {
    for (a, b) in zip(ranges, ranges.dropFirst()) {
      precondition(!a.isEmpty && !b.isEmpty, "Empty range in range set")
      precondition(
        a.upperBound < b.lowerBound,
        "Out of order/overlapping ranges in range set")
    }
  }
  
  
  
  internal init(_orderedRanges ranges: [Range<Bound>]) {
    self._ranges = _RangeSetStorage(ranges)
    _checkInvariants()
  }
  
  
  public var isEmpty: Bool {
    _ranges.isEmpty
  }
  
  
  
  
  
  
  
  
  
  
  public func contains(_ value: Bound) -> Bool {
    let i = _ranges._partitioningIndex { $0.upperBound > value }
    return i == _ranges.endIndex
      ? false
      : _ranges[i].lowerBound <= value
  }
    
  public func intersects(_ range: Range<Bound>) -> Bool {
    if _ranges.isEmpty {
      return false
    }
    if range.isEmpty {
      return false
    }
    if range.lowerBound > _ranges.last!.upperBound {
      return false
    }
    if range.upperBound < _ranges.first!.lowerBound {
      return false
    }
    return !_indicesOfRange(range).isEmpty
  }
  
  
  
  
  
  
  
  
  
  
  func _indicesOfRange(_ range: Range<Bound>) -> Range<Int> {
    precondition(!range.isEmpty)
    precondition(!_ranges.isEmpty)
    precondition(range.lowerBound <= _ranges.last!.upperBound)
    precondition(range.upperBound >= _ranges.first!.lowerBound)
    
    
    
    
    let beginningIndex = _ranges
      ._partitioningIndex { $0.upperBound >= range.lowerBound }
    
    
    
    
    
    
    
    let endingIndex = _ranges[beginningIndex...]
      ._partitioningIndex { $0.lowerBound > range.upperBound }
    
    return beginningIndex ..< endingIndex
  }
  
  
  
  
  
  
  
  internal mutating func _append(_ range: Range<Bound>) {
    precondition(_ranges.isEmpty
      || _ranges.last!.upperBound <= range.lowerBound)
    precondition(!range.isEmpty)
    if _ranges.isEmpty {
      _ranges.append(range)
    } else if _ranges.last!.upperBound == range.lowerBound {
      _ranges[_ranges.count - 1] =
        _ranges[_ranges.count - 1].lowerBound ..< range.upperBound
    } else {
      _ranges.append(range)
    }
  }
  
  
  
  
  
  
  
  public mutating func insert(contentsOf range: Range<Bound>) {
    
    if range.isEmpty { return }
    guard !_ranges.isEmpty else {
      _ranges.append(range)
      return
    }
    guard range.lowerBound < _ranges.last!.upperBound else {
      _append(range)
      return
    }
    guard range.upperBound >= _ranges.first!.lowerBound else {
      _ranges.insert(range, at: 0)
      return
    }
    
    let indices = _indicesOfRange(range)
    
    
    guard !indices.isEmpty else {
      _ranges.insert(range, at: indices.lowerBound)
      return
    }
    
    
    let newLowerBound = Swift.min(
      _ranges[indices.lowerBound].lowerBound,
      range.lowerBound)
    let newUpperBound = Swift.max(
      _ranges[indices.upperBound - 1].upperBound,
      range.upperBound)
    _ranges.replaceSubrange(
      indices,
      with: CollectionOfOne(newLowerBound..<newUpperBound))
  }
  
  
  
  
  
  
  
  public mutating func remove(contentsOf range: Range<Bound>) {
    
    if range.isEmpty
      || _ranges.isEmpty
      || range.lowerBound >= _ranges.last!.upperBound
      || range.upperBound < _ranges.first!.lowerBound
    { return }
    
    let indices = _indicesOfRange(range)
    
    
    if indices.isEmpty { return }
    
    let overlapsLowerBound =
      range.lowerBound > _ranges[indices.lowerBound].lowerBound
    let overlapsUpperBound =
      range.upperBound < _ranges[indices.upperBound - 1].upperBound
    
    switch (overlapsLowerBound, overlapsUpperBound) {
    case (false, false):
      _ranges.removeSubrange(indices)
    case (false, true):
      let newRange =
        range.upperBound..<_ranges[indices.upperBound - 1].upperBound
      _ranges.replaceSubrange(indices, with: CollectionOfOne(newRange))
    case (true, false):
      let newRange = _ranges[indices.lowerBound].lowerBound..<range.lowerBound
      _ranges.replaceSubrange(indices, with: CollectionOfOne(newRange))
    case (true, true):
      _ranges.replaceSubrange(indices, with: Pair(
        _ranges[indices.lowerBound].lowerBound..<range.lowerBound,
        range.upperBound..<_ranges[indices.upperBound - 1].upperBound
      ))
    }
  }
}

extension RangeSet: Equatable {}

extension RangeSet: Hashable where Bound: Hashable {}



extension RangeSet {
  
  public struct Ranges: RandomAccessCollection {
    var _ranges: _RangeSetStorage<Bound>
    
    public var startIndex: Int { _ranges.startIndex }
    public var endIndex: Int { _ranges.endIndex }
    
    public subscript(i: Int) -> Range<Bound> {
      _ranges[i]
    }
  }
  
  
  
  
  
  public var ranges: Ranges {
    Ranges(_ranges: _ranges)
  }
}



extension RangeSet {
  
  
  
  
  
  
  
  public init<S, C>(_ indices: S, within collection: C)
    where S: Sequence, C: Collection, S.Element == C.Index, C.Index == Bound
  {
    for i in indices {
      self.insert(i, within: collection)
    }
  }
  
  
  
  
  
  
  
  
  
  
  
  public mutating func insert<C>(_ index: Bound, within collection: C)
    where C: Collection, C.Index == Bound
  {
    insert(contentsOf: index ..< collection.index(after: index))
  }
  
  
  
  
  
  
  
  
  
  
  
  public mutating func remove<C>(_ index: Bound, within collection: C)
    where C: Collection, C.Index == Bound
  {
    remove(contentsOf: index ..< collection.index(after: index))
  }
  
  
  
  
  
  
  
  
  
  
  
  internal func _inverted<C>(within collection: C) -> RangeSet
    where C: Collection, C.Index == Bound
  {
    return _gaps(
      boundedBy: collection.startIndex..<collection.endIndex)
  }
  
  
  
  internal func _gaps(boundedBy bounds: Range<Bound>) -> RangeSet {
    guard !_ranges.isEmpty else { return RangeSet(bounds) }
    guard let start = _ranges.firstIndex(where: { $0.lowerBound >= bounds.lowerBound })
      else { return RangeSet() }
    guard let end = _ranges.lastIndex(where: { $0.upperBound <= bounds.upperBound })
      else { return RangeSet() }
    
    var result = RangeSet()
    var low = bounds.lowerBound
    for range in _ranges[start...end] {
      result.insert(contentsOf: low..<range.lowerBound)
      low = range.upperBound
    }
    result.insert(contentsOf: low..<bounds.upperBound)
    return result
  }
}





extension RangeSet {
  
  
  
  public mutating func formUnion(_ other: __owned RangeSet<Bound>) {
    for range in other._ranges {
      insert(contentsOf: range)
    }
  }
  
  
  
  
  
  public mutating func formIntersection(_ other: RangeSet<Bound>) {
    self = self.intersection(other)
  }
  
  
  
  
  
  
  public mutating func formSymmetricDifference(
    _ other: __owned RangeSet<Bound>
  ) {
    self = self.symmetricDifference(other)
  }
  
  
  
  
  public mutating func subtract(_ other: RangeSet<Bound>) {
    for range in other._ranges {
      remove(contentsOf: range)
    }
  }
  
  
  
  
  
  
  public __consuming func union(
    _ other: __owned RangeSet<Bound>
  ) -> RangeSet<Bound> {
    var result = self
    result.formUnion(other)
    return result
  }
  
  
  
  
  
  
  public __consuming func intersection(
    _ other: RangeSet<Bound>
  ) -> RangeSet<Bound> {
    var otherRangeIndex = 0
    var result: [Range<Bound>] = []
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    for currentRange in _ranges {
      
      
      while otherRangeIndex < other._ranges.endIndex &&
        other._ranges[otherRangeIndex].upperBound <= currentRange.lowerBound
      {
        otherRangeIndex += 1
      }
      
      
      
      while otherRangeIndex < other._ranges.endIndex &&
        other._ranges[otherRangeIndex].lowerBound < currentRange.upperBound
      {
        let lower = Swift.max(
          other._ranges[otherRangeIndex].lowerBound,
          currentRange.lowerBound)
        let upper = Swift.min(
          other._ranges[otherRangeIndex].upperBound,
          currentRange.upperBound)
        result.append(lower..<upper)
        
        
        
        
        guard
          currentRange.upperBound > other._ranges[otherRangeIndex].upperBound
          else {
            break
        }
        otherRangeIndex += 1
      }
    }
    
    return RangeSet(_orderedRanges: result)
  }
  
  
  
  
  
  
  public __consuming func symmetricDifference(
    _ other: __owned RangeSet<Bound>
  ) -> RangeSet<Bound> {
    return union(other).subtracting(intersection(other))
  }
  
  
  
  
  
  
  public func subtracting(_ other: RangeSet<Bound>) -> RangeSet<Bound> {
    var result = self
    result.subtract(other)
    return result
  }
  
  
  
  
  
  
  
  public func isSubset(of other: RangeSet<Bound>) -> Bool {
    self.intersection(other) == self
  }
  
  
  
  
  
  
  
  public func isSuperset(of other: RangeSet<Bound>) -> Bool {
    other.isSubset(of: self)
  }
  
  
  
  
  
  
  
  public func isStrictSubset(of other: RangeSet<Bound>) -> Bool {
    self != other && isSubset(of: other)
  }
  
  
  
  
  
  
  
  public func isStrictSuperset(of other: RangeSet<Bound>) -> Bool {
    other.isStrictSubset(of: self)
  }
}

extension RangeSet: CustomStringConvertible {
  public var description: String {
    let rangesDescription = _ranges
      .map { r in "\(r.lowerBound)..<\(r.upperBound)" }
      .joined(separator: ", ")
    return "RangeSet(\(rangesDescription))"
  }
}
