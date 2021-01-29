public enum BaseSingularity: Codable, Hashable {
	case B0
	case B1
}

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

	public var description: String {
		switch self {
			case .forward: return "forward"
			case .backward: return "backward"
		}
	}
}

public enum ApexSingularity: Hashable {
	case A0
	case A1
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
