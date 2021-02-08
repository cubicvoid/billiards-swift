

/*func Mod(_ a: Int, by n: Int) -> Int {
	return ((a % n) + n) % n
}*/

infix operator **: BitwiseShiftPrecedence

// A Path is an element of the group of paths on the kite K.
// It is represented as
public struct TurnPath:
	Codable, Hashable, CustomStringConvertible {


	// The generators of the group, corresponding to widdershins
	// rotation around B0 and clockwise rotation around B1
	public static let g: BaseValues<TurnPath> = BaseValues(
		b0: TurnPath(sanitizedTurns: [Turn(degree: 1, singularity: BaseSingularity.B0)]),
		b1: TurnPath(sanitizedTurns: [Turn(degree: 1, singularity: BaseSingularity.B1)]))
	public static let empty: TurnPath = TurnPath(sanitizedTurns: [])
	private var turns: [Turn]
	
	private init(sanitizedTurns: [Turn]) {
		self.turns = sanitizedTurns
	}
	
	public init(turns: [Turn]) {
		self.turns = []
		for turn in turns {
			self *= turn
		}
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
		return TurnPath(sanitizedTurns: turns.reversed().map { $0 ** -1 })
	}

	public func transpose() -> TurnPath {
		return TurnPath(sanitizedTurns: turns.map { $0 ** -1 })
	}

	public func pow(_ n: Int) -> TurnPath {
		if n == 0 || turns.count == 0 {
			return TurnPath.empty
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
			return TurnPath(sanitizedTurns: [t])
		}
		let half = n / 2
		let root = pow(half)
		let rootSquared = root * root
		return (n % 2 == 0)
			? rootSquared
			: rootSquared * self
	}
	
	public static func **(p: TurnPath, n: Int) -> TurnPath {
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

	// A Turn is an element of
	public struct Turn: Codable, Hashable, CustomStringConvertible {
		public let degree: Int

		public let singularity: BaseSingularity
		
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

}


extension TurnPath: Collection {
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
	
	/*public subscript(bounds: Range<Int>) -> Slice<TurnPath> {
		return Slice(base: self, bounds: bounds)
	}*/
}

extension TurnPath {
	static func *=(p: inout TurnPath, t: Turn) {
		if let last = p.turns.last {
			if last.singularity == t.singularity {
				let newDegree = last.degree + t.degree
				if newDegree == 0 {
					p.turns.removeLast()
				} else {
					p.turns[p.turns.count - 1] =
						Turn(degree: newDegree, singularity: t.singularity)
				}
				return
			}
		}
		p.turns.append(t)
	}
	
	static func *=(p0: inout TurnPath, p1: TurnPath) {
		for turn in p1 {
			p0 *= turn
		}
	}
	
	static func *(p: TurnPath, t: Turn) -> TurnPath {
		var result = p
		result *= t
		return result
	}
	
	static func *(p0: TurnPath, p1: TurnPath) -> TurnPath {
		var result = p0
		result *= p1
		return result
	}
}

extension TurnPath {
	/*public func compareTo(_ path: TurnPath) -> Comparison {
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
	}*/

	public func monoidalComponents() -> [TurnPath] {
		var components: [TurnPath] = []
		let boundaries = signBoundariesForTurns(turns)
		for i in 0..<boundaries.count {
			let start = boundaries[i-1]
			let end = boundaries[i]
			components.append(TurnPath(turns: Array(turns[start..<end])))
		}
		return components
	}
}

fileprivate func signBoundariesForTurns(_ turns: [TurnPath.Turn]) -> [Int] {
	var boundaries: [Int] = [];
	var lastSign: Sign? = nil
	for (i, turn) in turns.enumerated() {
		let sign = Sign.of(turn.degree)!
		if sign == lastSign {
			boundaries.append(i)
		}
		lastSign = sign
	}
	boundaries.append(turns.count)
	return boundaries
}



