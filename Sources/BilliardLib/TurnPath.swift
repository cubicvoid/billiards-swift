

/*func Mod(_ a: Int, by n: Int) -> Int {
	return ((a % n) + n) % n
}*/

infix operator **: BitwiseShiftPrecedence

// A Path is an element of the group of paths on the kite K.
// It is represented as
public struct Path:
	Codable, Hashable, CustomStringConvertible {

	// A Turn is an element of
	public struct Turn: Codable, Hashable, CustomStringConvertible {
		let degree: Int

		let singularity: BaseSingularity
		
		/*init(degree: Int, singularity: BaseSingularity) {
			self.degree = degree
			self.singularity = singularity
		}*/
		
		// A semi-arbitrary ordering on turns: sort first by absolute degree,
		// then by center singularity, then by reverse sign.
		// This ordering has no particular theoretical justification other
		// than grouping together paths that we tend to want grouped together;
		// other choices would work, we just need something consistent to use for
		// cycle canonicalization.
		public func compareTo(_ t: Turn) -> Comparison {
			let absComparison = Compare(abs(degree), to: abs(t.degree))
			if absComparison != .equal {
				return absComparison
			}
			if singularity == .B0 && t.singularity == .B1 {
				return .less
			}
			if singularity == .B1 && t.singularity == .B0 {
				return .greater
			}
			if degree == t.degree {
				return .equal
			}
			if degree > 0 {
				return .less
			}
			return .greater
		}

		public var description: String {
			return "\(singularity):\(degree)"
		}
		
		static func **(turn: Turn, n: Int) -> Turn {
			return Turn(degree: turn.degree * n, singularity: turn.singularity)
		}
	}


	// The generators of the group, corresponding to widdershins
	// rotation around B0 and clockwise rotation around B1
	public static let g: BaseValues<Path> = BaseValues(
		b0: Path(turns: [Turn(degree: 1, singularity: BaseSingularity.B0)]),
		b1: Path(turns: [Turn(degree: 1, singularity: BaseSingularity.B1)]))
	public static let empty: Path = Path(turns: [])
	private var turns: [Turn]
	
	/*public init(
		initialOrientation: BaseOrientation,
		turnDegrees: [Int]
	) {
		var turns: [Turn] = [];
		var orientation = initialOrientation
		for degree in turnDegrees {
			turns.append(Turn(degree: degree, singularity: orientation.to))
			orientation = -orientation
		}
		self.turns = turns
	}*/
	
	private init(turns: [Turn]) {
		self.turns = turns
	}
	/*
		var reduced: [Turn] = []
		for turn in turns {
			// If both turns are around the same singularity, merge them instead
			// of adding a new one.
			if let last = reduced.last, last.singularity == turn.singularity {
				let degreeSum = last.degree + turn.degree
				// If the degrees cancel each other out, remove the turn entirely.
				if degreeSum == 0 {
					reduced.removeLast()
				} else {
					reduced[reduced.count - 1] =
						Turn(degree: degreeSum, singularity: turn.singularity)
				}
			}
		}
		self.turns = reduced
	}*/

	// returns the rotation in which turns[0] appears at the given index
	public func rotatedBy(_ index: Int) -> Path {
		if index == 0 {
			return self
		}
		let start = Mod(index, by: turns.count)
		let split = turns.count - start
		return Path(turns: Array(turns[split...] + turns[..<split]))
	}

	public func inverse() -> Path {
		if turns.count == 0 {
			return self
		}
		return Path(turns: turns.reversed().map { $0 ** -1 })
	}

	public func transpose() -> Path {
		return Path(turns: turns.map { $0 ** -1 })
	}

	public func pow(_ n: Int) -> Path {
		if n == 0 || turns.count == 0 {
			return Path.empty
		}
		if n < 0 {
			return self.inverse().pow(-n)
		}
		if n == 1 {
			return self
		}
		// special case single-turn paths since paths are assembled
		// by combining turns that are powers of the generators.
		if turns.count == 1 {
			let t = Turn(
				degree: turns[0].degree * n,
				singularity: turns[0].singularity)
			return Path(turns: [t])
		}
		let half = n / 2
		let root = pow(half)
		let rootSquared = root * root
		return (n % 2 == 0)
			? rootSquared
			: rootSquared * self
	}
	
	public static func **(p: Path, n: Int) -> Path {
		return p.pow(n)
	}

	public func degree() -> BaseValues<Int> {
		var result = BaseValues(0, 0)
		for turn in turns {
			result[turn.singularity] += turn.degree
		}
		return result
	}
	
	public func weight() -> BaseValues<Int> {
		var result = BaseValues(0, 0)
		for turn in turns {
			result[turn.singularity] += abs(turn.degree)
		}
		return result
	}
	
	public func totalWeight() -> Int {
		let w = self.weight()
		return w[.B0] + w[.B1]
	}

	public var description: String {
		return "\(turns)"
	}
}


extension Path: Collection {
	public var startIndex: Array<Turn>.Index {
		return turns.startIndex
	}
	
	public var endIndex: Array<Turn>.Index {
		return turns.endIndex
	}
	
	public var count: Int {
		return turns.count
	}
	
	public func index(after i: Int) -> Int {
		return turns.index(after: i)
	}
	
	public subscript(position: Int) -> Turn {
		return turns[position]
	}
}

extension Path {
	static func *(_ left: Path, _ right: Path) -> Path {
		return Path(turns: left.turns + right.turns)
	}
}

/*public class PathBuilder {
	private let initialOrientation: BaseOrientation
	private var turns: [Int] = []

	public init(initialOrientation: BaseOrientation) {
		self.initialOrientation = initialOrientation
	}

	public func appendTurn(_ turn: Int) {
		turns.append(turn)
	}

	public func build() -> Path {
		return Path(
			initialOrientation: initialOrientation,
			turnDegrees: turns)
	}
}*/

extension Path {
	public func compareTo(_ path: Path) -> Comparison {
		let lengthComparison =
			Compare(turns.count, to: path.turns.count)
		if lengthComparison != .equal {
			return lengthComparison
		}
		if turns.count == 0 {
			return .equal
		}

		let totalTurnsSelf = turns.map { abs($0.degree) }.reduce(0, +)
		let totalTurnsPath = path.turns.map { abs($0.degree) }.reduce(0, +)
		let totalComparison =
			Compare(totalTurnsSelf, to: totalTurnsPath)
		if totalComparison != .equal {
			return totalComparison
		}

		for i in 0..<turns.count {
			let turnComparison = turns[i].compareTo(path.turns[i])
			if turnComparison != .equal {
				return turnComparison
			}
		}
		return .equal
	}

	public func monotonicComponents() -> [Path] {
		var components: [Path] = []
		let boundaries = signBoundariesForTurns(turns)
		for i in 1..<boundaries.count {
			let start = boundaries[i-1]
			let end = boundaries[i]
			components.append(Path(turns: Array(turns[start..<end])))
		}
		return components
	}
}

fileprivate func signBoundariesForTurns(_ turns: [Path.Turn]) -> [Int] {
	var boundaries: [Int] = [];
	var lastSign: Sign? = nil
	for (i, turn) in turns.enumerated() {
		let sign = Sign.of(turn.degree)!
		if sign != lastSign {
			boundaries.append(i)
		}
		lastSign = sign
	}
	boundaries.append(turns.count)
	return boundaries
}

