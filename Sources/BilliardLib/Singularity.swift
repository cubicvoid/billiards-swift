public enum BaseSingularity: String, Codable {
	case B0
	case B1
}

// apologies for the vocabulary here, maybe you can think of something
// better. but:
// BaseOrientation is a direction either from B0 to B1, or B1 to B0.
// We call the former "forward" and the latter "backward." we do this
// because these are complementary "directions" that have no specific
// geometric connotation (like left or right, up or down, etc).
// "forward" in the default coordinate system we're currently using
// means left-to-right, but since left and right have actual
// important geometric meaning in KiteEmbedding, we don't want to
// overload them, so we prefer a neutral alternative. See also
// ApexOrientation below.
public enum BaseOrientation: Int, Codable, Negatable, Hashable {
	case forward
	case backward

	public static let all: [BaseOrientation] = [.forward, .backward]

	static public prefix func -(
		orientation: BaseOrientation
	) -> BaseOrientation {
		switch orientation {
			case .forward: return .backward
			case .backward: return .forward
		}
	}

	public static func from(_ s: BaseSingularity) -> BaseOrientation {
		switch s {
			case .B0: return .forward
			case .B1: return .backward
		}
	}

	public static func to(_ s: BaseSingularity) -> BaseOrientation {
		switch s {
			case .B0: return .backward
			case .B1: return .forward
		}
	}

	public var from: BaseSingularity {
		switch self {
			case .forward: return .B0
			case .backward: return .B1
		}
	}

	public var to: BaseSingularity {
		switch self {
			case .forward: return .B1
			case .backward: return .B0
		}
	}
	
	public func apexForSide(_ s: Side) -> ApexSingularity {
		switch (s, self) {
		case (.left, .forward): return .A0
		case (.left, .backward): return .A1
		case (.right, .forward): return .A1
		case (.right, .backward): return .A0
		}
	}

	public var description: String {
		switch self {
			case .forward: return "forward"
			case .backward: return "backward"
		}
	}
}

// A0 is the "upper" apex and A1 is its complex conjugate.
public enum ApexSingularity: Hashable {
	case A0
	case A1
}

// ApexOrientation indicates a direction between A0 and A1, either
// A1 to A0 (positive) or A0 to A1 (negative). As with BaseOrientation,
// we use terms that don't connote any specific geometric constraints
// (otherwise we might call this "up" and "down"). Instead, the link is
// to our sign convention for the generators of Path: a turn whose degree
// is positive (around either base vertex) moves the kite (to first order)
// in the geometric direction from A1 to A1, that is, up in the default
// embedding, while a negative-degree turn does the reverse.
public enum ApexOrientation: Int, Codable, Negatable, Hashable {
	case positive
	case negative

	public static let all: [BaseOrientation] = [.forward, .backward]

	static public prefix func -(
		orientation: ApexOrientation
	) -> ApexOrientation {
		switch orientation {
			case .positive: return .negative
			case .negative: return .positive
		}
	}

	public static func from(_ s: ApexSingularity) -> ApexOrientation {
		switch s {
			case .A0: return .negative
			case .A1: return .positive
		}
	}

	public static func to(_ s: ApexSingularity) -> ApexOrientation {
		switch s {
			case .A0: return .positive
			case .A1: return .negative
		}
	}
	
	public static func fromTurnSign(_ sign: Sign) -> ApexOrientation {
		switch sign {
			case .positive: return .positive
			case .negative: return .negative
		}
	}

	public var from: ApexSingularity {
		switch self {
			case .positive: return .A1
			case .negative: return .A0
		}
	}

	public var to: ApexSingularity {
		switch self {
			case .positive: return .A0
			case .negative: return .A1
		}
	}
	
	public func baseForSide(_ s: Side) -> BaseSingularity {
		switch (s, self) {
		case (.left, .positive): return .B0
		case (.left, .negative): return .B1
		case (.right, .positive): return .B1
		case (.right, .negative): return .B0
		}
	}
	
	public func sideForBase(_ b: BaseSingularity) -> Side {
		switch (b, self) {
		case (.B0, .positive): return .left
		case (.B0, .negative): return .right
		case (.B1, .positive): return .right
		case (.B1, .negative): return .left
		}
	}

	public var description: String {
		switch self {
			case .positive: return "positive"
			case .negative: return "negative"
		}
	}
}

public enum Singularity: Hashable {
	case B0
	case B1
	case A0
	case A1
}

public struct BaseValues<T> {
	private var v0, v1: T

	public init(_ v0: T, _ v1: T) {
		self.v0 = v0
		self.v1 = v1
	}

	public init(b0: T, b1: T) {
		v0 = b0
		v1 = b1
	}
	
	public init(_ builder: (BaseSingularity) -> T) {
		v0 = builder(.B0)
		v1 = builder(.B1)
	}

	public func withValue(
		_ value: T, 
		forSingularity s: BaseSingularity
	) -> BaseValues<T> {
		switch s {
			case .B0: return BaseValues(value, self[.B1])
			case .B1: return BaseValues(self[.B0], value)
		}
	}

	public subscript(index: BaseSingularity) -> T {
		get {
			switch index {
				case .B0: return v0
				case .B1: return v1
			}
		}
		set(newValue) {
			switch index {
				case .B0: v0 = newValue
				case .B1: v1 = newValue
			}
		}
	}
	
	public func map<U>(_ f: (T) -> U) -> BaseValues<U> {
		return BaseValues<U>(f(v0), f(v1))
	}
}

extension BaseValues: Codable where T: Codable {
}

extension BaseValues: CustomStringConvertible where T: CustomStringConvertible {
	public var description: String {
		return "(B0: \(self[.B0]), B1: \(self[.B1]))"
	}
}
