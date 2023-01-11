







public func crop<Type>(_ lower: Type, _ val: Type, _ upper: Type) -> Type where Type : Comparable {
    assert(lower < upper, "Invalid lover and upper values")
    return max(lower, min(upper, val))
}
