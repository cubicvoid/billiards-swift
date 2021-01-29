public struct Turn: Codable, Hashable, CustomStringConvertible {
	let degree: Int

	let singularity: BaseSingularity

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

	public func inverse() -> Turn {
		return Turn(degree: -degree, singularity: singularity)
	}

	public var description: String {
		return "\(singularity):\(degree)"
	}
}

func Mod(_ a: Int, by n: Int) -> Int {
	return ((a % n) + n) % n
}

public struct TurnPath: Codable, Hashable, CustomStringConvertible {
	//public let initialOrientation: BaseOrientation
	//public let turns: [Int]
	public let turns: [Turn]


	public init(
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
	}

	public init(turns: [Turn]) {
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
	}

	static func empty() -> TurnPath {
		return TurnPath(turns: [])
	}

	// returns the rotation in which turns[0] appears at the given index
	public func rotatedBy(_ index: Int) -> TurnPath {
		if index == 0 {
			return self
		}
		let start = Mod(index, by: turns.count)
		let split = turns.count - start
		return TurnPath(turns: Array(turns[split...] + turns[..<split]))
	}

	public func inverse() -> TurnPath {
		if turns.count == 0 {
			return self
		}
		return TurnPath(turns: turns.reversed().map { $0.inverse() })
	}

	public func transpose() -> TurnPath {
		return TurnPath(turns: turns.map { $0.inverse() })
	}

	public func pow(_ n: Int) -> TurnPath {
		if n == 0 {
			return empty()
		}
		if n < 0 {
			return self.inverse().pow(-n)
		}
		if n == 1 {
			return self
		}
		let half = n / 2
		let root = pow(half)
		let rootSquared = root * root
		return (n % 2 == 0)
			? rootSquared
			: rootSquared * self
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

extension TurnPath {
	static func *(_ left: TurnPath, _ right: TurnPath) -> TurnPath {
		return TurnPath(turns: left.turns + right.turns)
	}
}

/*public class TurnPathBuilder {
	private let initialOrientation: BaseOrientation
	private var turns: [Int] = []

	public init(initialOrientation: BaseOrientation) {
		self.initialOrientation = initialOrientation
	}

	public func appendTurn(_ turn: Int) {
		turns.append(turn)
	}

	public func build() -> TurnPath {
		return TurnPath(
			initialOrientation: initialOrientation,
			turnDegrees: turns)
	}
}*/

extension TurnPath {
	public func compareTo(_ path: TurnPath) -> Comparison {
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

	public func monotonicComponents() -> [TurnPath] {
		var components: [TurnPath] = []
		let boundaries = signBoundariesForTurns(turns)
		for i in 1..<boundaries.count {
			let start = boundaries[i-1]
			let end = boundaries[i]
			components.append(TurnPath(turns: Array(turns[start..<end])))
		}
		return components
	}
}

fileprivate func signBoundariesForTurns(_ turns: [Turn]) -> [Int] {
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

