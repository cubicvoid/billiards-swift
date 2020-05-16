
public enum Comparison {
	case less
	case equal
	case greater
}

public func Compare<T: Comparable>(
	_ value0: T, to value1: T
) -> Comparison {
	if value0 < value1 {
		return .less
	}
	if value0 > value1 {
		return .greater
	}
	return .equal
}
