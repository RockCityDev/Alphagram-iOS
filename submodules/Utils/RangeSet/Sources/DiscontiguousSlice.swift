












public struct DiscontiguousSlice<Base: Collection> {
  
  public var base: Base
  
  
  public var subranges: RangeSet<Base.Index>
}

extension DiscontiguousSlice {
  
  public struct Index: Comparable {
    
    internal var _rangeOffset: Int
    
    
    public var base: Base.Index
    
    public static func < (lhs: Index, rhs: Index) -> Bool {
      lhs.base < rhs.base
    }
  }
}

extension DiscontiguousSlice.Index: Hashable where Base.Index: Hashable {}

extension DiscontiguousSlice: Collection {
  public typealias SubSequence = Self
  
  public var startIndex: Index {
    subranges.isEmpty
      ? endIndex
      : Index(_rangeOffset: 0, base: subranges._ranges[0].lowerBound)
  }
  
  public var endIndex: Index {
    Index(_rangeOffset: subranges._ranges.endIndex, base: base.endIndex)
  }
  
  public func index(after i: Index) -> Index {
    let nextIndex = base.index(after: i.base)
    if subranges._ranges[i._rangeOffset].contains(nextIndex) {
      return Index(_rangeOffset: i._rangeOffset, base: nextIndex)
    }
    
    let nextOffset = i._rangeOffset + 1
    if nextOffset < subranges._ranges.endIndex {
      return Index(
        _rangeOffset: nextOffset,
        base: subranges._ranges[nextOffset].lowerBound)
    } else {
      return endIndex
    }
  }
  
  public subscript(i: Index) -> Base.Element {
    base[i.base]
  }
  
  public subscript(bounds: Range<Index>) -> DiscontiguousSlice<Base> {
    let baseBounds = bounds.lowerBound.base ..< bounds.upperBound.base
    let subset = subranges.intersection(RangeSet(baseBounds))
    return DiscontiguousSlice<Base>(base: base, subranges: subset)
  }
}

extension DiscontiguousSlice {
  public var count: Int {
    var c = 0
    for range in subranges._ranges {
      c += base.distance(from: range.lowerBound, to: range.upperBound)
    }
    return c
  }
  
  public __consuming func _copyToContiguousArray() -> ContiguousArray<Base.Element> {
    var result: ContiguousArray<Base.Element> = []
    for range in subranges._ranges {
      result.append(contentsOf: base[range])
    }
    return result
  }
}

extension DiscontiguousSlice: BidirectionalCollection
  where Base: BidirectionalCollection
{
  public func index(before i: Index) -> Index {
    precondition(i != startIndex, "Can't move index before startIndex")
    
    if i == endIndex || i.base == subranges._ranges[i._rangeOffset].lowerBound {
      let offset = i._rangeOffset - 1
      return Index(
        _rangeOffset: offset,
        base: base.index(before: subranges._ranges[offset].upperBound))
    }
    
    return Index(
      _rangeOffset: i._rangeOffset,
      base: base.index(before: i.base))
  }
}

extension DiscontiguousSlice: MutableCollection where Base: MutableCollection {
  public subscript(i: Index) -> Base.Element {
    get {
      base[i.base]
    }
    set {
      base[i.base] = newValue
    }
  }

  public subscript(bounds: Range<Index>) -> DiscontiguousSlice<Base> {
    get {
      let baseBounds = bounds.lowerBound.base ..< bounds.upperBound.base
      let subset = subranges.intersection(RangeSet(baseBounds))
      return DiscontiguousSlice<Base>(base: base, subranges: subset)
    }
    set {
      let baseBounds = bounds.lowerBound.base ..< bounds.upperBound.base
      let subset = subranges.intersection(RangeSet(baseBounds))
      for i in newValue.indices where subset.contains(i.base) {
        base[i.base] = newValue[i]
      }
    }
  }
}
