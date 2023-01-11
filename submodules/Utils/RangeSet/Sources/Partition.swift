












extension MutableCollection {
  
  
  
  
  
  
  @discardableResult
  internal mutating func _rotate(in subrange: Range<Index>, shiftingToStart middle: Index) -> Index {
    var m = middle, s = subrange.lowerBound
    let e = subrange.upperBound
    
    
    if s == m { return e }
    if m == e { return s }
    
    
    
    
    
    
    
    
    
    
    var ret = e 
    while true {
      
      
      
      
      
      
      
      
      
      let (s1, m1) = _swapNonemptySubrangePrefixes(s..<m, m..<e)
      
      if m1 == e {
        
        
        
        
        
        
        
        if ret == e { ret = s1 }
        
        
        if s1 == m { break }
      }
      
      
      
      
      
      
      
      s = s1
      if s == m { m = m1 }
    }
    
    return ret
  }
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  mutating func _swapNonemptySubrangePrefixes(
    _ lhs: Range<Index>, _ rhs: Range<Index>
  ) -> (Index, Index) {
    assert(!lhs.isEmpty)
    assert(!rhs.isEmpty)
    
    var p = lhs.lowerBound
    var q = rhs.lowerBound
    repeat {
      swapAt(p, q)
      formIndex(after: &p)
      formIndex(after: &q)
    }
      while p != lhs.upperBound && q != rhs.upperBound
    return (p, q)
  }
}



extension MutableCollection {
  
  
  
  
  
  
  
  internal mutating func _stablePartition(
    count n: Int,
    range: Range<Index>,
    by belongsInSecondPartition: (Element) throws-> Bool
  ) rethrows -> Index {
    if n == 0 { return range.lowerBound }
    if n == 1 {
      return try belongsInSecondPartition(self[range.lowerBound])
        ? range.lowerBound
        : range.upperBound
    }
    let h = n / 2, i = index(range.lowerBound, offsetBy: h)
    let j = try _stablePartition(
      count: h,
      range: range.lowerBound..<i,
      by: belongsInSecondPartition)
    let k = try _stablePartition(
      count: n - h,
      range: i..<range.upperBound,
      by: belongsInSecondPartition)
    return _rotate(in: j..<k, shiftingToStart: i)
  }
  
  
  
  
  
  
  
  
  internal mutating func _indexedStablePartition(
    count n: Int,
    range: Range<Index>,
    by belongsInSecondPartition: (Index) throws-> Bool
  ) rethrows -> Index {
    if n == 0 { return range.lowerBound }
    if n == 1 {
      return try belongsInSecondPartition(range.lowerBound)
        ? range.lowerBound
        : range.upperBound
    }
    let h = n / 2, i = index(range.lowerBound, offsetBy: h)
    let j = try _indexedStablePartition(
      count: h,
      range: range.lowerBound..<i,
      by: belongsInSecondPartition)
    let k = try _indexedStablePartition(
      count: n - h,
      range: i..<range.upperBound,
      by: belongsInSecondPartition)
    return _rotate(in: j..<k, shiftingToStart: i)
  }
}



extension Collection {
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  internal func _partitioningIndex(
    where predicate: (Element) throws -> Bool
  ) rethrows -> Index {
    var n = count
    var l = startIndex
    
    while n > 0 {
      let half = n / 2
      let mid = index(l, offsetBy: half)
      if try predicate(self[mid]) {
        n = half
      } else {
        l = index(after: mid)
        n -= half + 1
      }
    }
    return l
  }
}

