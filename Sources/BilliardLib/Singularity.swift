public enum Singularity: Hashable {
	case S0
	case S1
	
	public static let all: [Singularity] = [.S0, .S1]

	public func turnBy(_ turnDegree: Int) -> Turn {
		return Turn(around: self, by: turnDegree)
	}

	public func next() -> Singularity {
		switch self {
			case .S0: return .S1
			case .S1: return .S0
		}
	}

	public enum Orientation: CanonicalSign & Hashable {
		case forward
		case backward

		static public prefix func -(orientation: Orientation) -> Orientation {
			switch orientation {
				case .forward: return .backward
				case .backward: return .forward
			}
		}

		public static func from(_ s: Singularity) -> Orientation {
			switch s {
				case .S0: return .forward
				case .S1: return .backward
			}
		}

		public static func to(_ s: Singularity) -> Orientation {
			switch s {
				case .S0: return .backward
				case .S1: return .forward
			}
		}

		public var from: Singularity {
			switch self {
				case .forward: return S0
				case .backward: return S1
			}
		}

		public var to: Singularity {
			switch self {
				case .forward: return S1
				case .backward: return S0
			}
		}

		public func canonicalSign() -> Sign {
			switch self {
				case .forward: return .positive
				case .backward: return .negative
			}
		}

		public var description: String {
			switch self {
				case .forward: return "forward"
				case .backward: return "backward"
			}
		}
	}

	public class Turn: Hashable {
		public let singularity: Singularity
		public let degree: Int

		public init(around singularity: Singularity, by degree: Int) {
			self.singularity = singularity
			self.degree = degree
		}

		public static func == (lhs: Singularity.Turn, rhs: Singularity.Turn) -> Bool {
			return lhs.singularity == rhs.singularity && lhs.degree == rhs.degree
		}
		
		public func hash(into hasher: inout Hasher) {
			singularity.hash(into: &hasher)
			degree.hash(into: &hasher)
		}
	}
}

public final class Singularities<k> {
	private let v0, v1: k

	public init(_ v0: k, _ v1: k) {
		self.v0 = v0
		self.v1 = v1
	}

	public init(s0: k, s1: k) {
		v0 = s0
		v1 = s1
	}
	
	public init(_ builder: (Singularity) -> k) {
		v0 = builder(.S0)
		v1 = builder(.S1)
	}

	public func withValue(
		_ v: k, 
		forSingularity s: Singularity
	) -> Singularities<k> {
		switch s {
			case .S0: return Singularities(v, self[.S1])
			case .S1: return Singularities(self[.S0], v)
		}
	}

	public subscript(index: Singularity) -> k {
		switch index {
			case .S0: return v0
			case .S1: return v1
		}
	}
	
	public func map<T>(_ f: (k) -> T) -> Singularities<T> {
		return Singularities<T>(f(v0), f(v1))
	}
}

extension Singularities: CustomStringConvertible where k: CustomStringConvertible {
	public var description: String {
		return "(S0 -> \(self[.S0]), S1 -> \(self[.S1]))"
	}
}