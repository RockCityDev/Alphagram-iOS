












extension Collection {
  
  
  
  
  
  
  
  
  public subscript(subranges: RangeSet<Index>) -> DiscontiguousSlice<Self> {
    DiscontiguousSlice(base: self, subranges: subranges)
  }
}

extension MutableCollection {
  
  
  
  
  
  
  
  
  
  
  public subscript(subranges: RangeSet<Index>) -> DiscontiguousSlice<Self> {
    get {
      DiscontiguousSlice(base: self, subranges: subranges)
    }
    set {
      for i in newValue.indices where subranges.contains(i.base) {
        self[i.base] = newValue[i]
      }
    }
  }
}



extension MutableCollection {
  
  
  
  
  /// moves them to between `"i"` and `"j"`.
  
  ///     var letters = Array("ABCdeFGhijkLMNOp")
  
  
  ///     // String(letters) == "dehiABCFGLMNOjkp"
  
  
  
  
  
  
  
  
  @discardableResult
  public mutating func moveSubranges(
    _ subranges: RangeSet<Index>, to insertionPoint: Index
  ) -> Range<Index> {
    let lowerCount = distance(from: startIndex, to: insertionPoint)
    let upperCount = distance(from: insertionPoint, to: endIndex)
    let start = _indexedStablePartition(
      count: lowerCount,
      range: startIndex..<insertionPoint,
      by: { subranges.contains($0) })
    let end = _indexedStablePartition(
      count: upperCount,
      range: insertionPoint..<endIndex,
      by: { !subranges.contains($0) })
    return start..<end
  }
}



extension RangeReplaceableCollection {
  
  
  
  
  
  ///     var str = "The rain in Spain stays mainly in the plain."
  ///     let vowels: Set<Character> = ["a", "e", "i", "o", "u"]
  
  
  
  ///     // str == "Th rn n Spn stys mnly n th pln."
  
  
  
  
  public mutating func removeSubranges(_ subranges: RangeSet<Index>) {
    guard !subranges.isEmpty else {
      return
    }
    
    let inversion = subranges._inverted(within: self)
    var result = Self()
    for range in inversion.ranges {
      result.append(contentsOf: self[range])
    }
    self = result
  }
}

extension MutableCollection where Self: RangeReplaceableCollection {
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  public mutating func removeSubranges(_ subranges: RangeSet<Index>) {
    guard let firstRange = subranges.ranges.first else {
      return
    }
    
    var endOfElementsToKeep = firstRange.lowerBound
    var firstUnprocessed = firstRange.upperBound
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    for range in subranges.ranges.dropFirst() {
      let nextLow = range.lowerBound
      while firstUnprocessed != nextLow {
        swapAt(endOfElementsToKeep, firstUnprocessed)
        formIndex(after: &endOfElementsToKeep)
        formIndex(after: &firstUnprocessed)
      }
      
      firstUnprocessed = range.upperBound
    }
    
    
    
    while firstUnprocessed != endIndex {
      swapAt(endOfElementsToKeep, firstUnprocessed)
      formIndex(after: &endOfElementsToKeep)
      formIndex(after: &firstUnprocessed)
    }
    
    removeSubrange(endOfElementsToKeep..<endIndex)
  }
}

extension Collection {
  
  
  
  
  
  
  
  ///     let str = "The rain in Spain stays mainly in the plain."
  ///     let vowels: Set<Character> = ["a", "e", "i", "o", "u"]
  
  
  
  
  ///     // Prints "Th rn n Spn stys mnly n th pln."
  
  
  
  
  
  
  public func removingSubranges(
    _ subranges: RangeSet<Index>
  ) -> DiscontiguousSlice<Self> {
    let inversion = subranges._inverted(within: self)
    return self[inversion]
  }
}



extension Collection {
  
  
  
  
  
  ///     let str = "Fresh cheese in a breeze"
  ///     let vowels: Set<Character> = ["a", "e", "i", "o", "u"]
  
  
  
  
  
  
  
  
  
  
  public func subranges(where predicate: (Element) throws -> Bool) rethrows
    -> RangeSet<Index>
  {
    if isEmpty { return RangeSet() }
    
    var result = RangeSet<Index>()
    var i = startIndex
    while i != endIndex {
      let next = index(after: i)
      if try predicate(self[i]) {
        result._append(i..<next)
      }
      i = next
    }
    
    return result
  }
}

extension Collection where Element: Equatable {
  
  
  
  
  
  
  ///     let str = "Fresh cheese in a breeze"
  ///     let allTheEs = str.subranges(of: "e")
  
  
  
  
  
  
  
  public func subranges(of element: Element) -> RangeSet<Index> {
    subranges(where: { $0 == element })
  }
}

