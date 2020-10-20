public struct TurnPath: Codable, Hashable, Sequence {
	public let initialOrientation: BaseOrientation
	public let turns: [Int]

	public init(
		initialOrientation: BaseOrientation,
		turns: [Int]
	) {
		self.initialOrientation = initialOrientation
		self.turns = turns
	}
	
	public func makeIterator() -> TurnPathIterator {
		return TurnPathIterator(self)
	}
	
	public func weight() -> BaseValues<Int> {
		var result = BaseValues(0, 0)
		for step in self {
			result[step.singularity] += abs(step.turn)
		}
		return result
	}
	
	public func totalWeight() -> Int {
		let w = self.weight()
		return w[.B0] + w[.B1]
	}
}

public struct TurnStep {
	// The turn, positive for widdershins and negative for clockwise
	let turn: Int
	
	// The singularity the turn is around
	let singularity: BaseSingularity
}

public struct TurnPathIterator: IteratorProtocol {
	private let path: TurnPath
	private var index: Int = 0
	private var orientation: BaseOrientation
	
	init(_ path: TurnPath) {
		self.path = path
		self.orientation = path.initialOrientation
	}
	
	public mutating func next() -> TurnStep? {
		if index >= path.turns.count {
			return nil
		}
		let result = TurnStep(turn: path.turns[index], singularity: orientation.to)
		index += 1
		orientation = -orientation
		return result
	}
}


extension TurnPath: CustomStringConvertible {
	public var description: String {
		return "\(initialOrientation.from)->\(turns)"
	}
}

public class TurnPathBuilder {
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
			turns: turns)
	}
}

extension TurnPath {
	public func compareTo(_ path: TurnPath) -> Comparison {
		let lengthComparison =
			Compare(turns.count, to: path.turns.count)
		if lengthComparison != .equal {
			return lengthComparison
		}

		let totalTurnsSelf = turns.map(abs).reduce(0, +)
		let totalTurnsPath = path.turns.map(abs).reduce(0, +)
		let totalComparison =
			Compare(totalTurnsSelf, to: totalTurnsPath)
		if totalComparison != .equal {
			return totalComparison
		}

		for i in 0..<turns.count {
			let turnComparison = Compare(turns[i], to: path.turns[i])
			if turnComparison != .equal {
				return turnComparison
			}
		}

		if initialOrientation == path.initialOrientation {
			return .equal
		}
		if initialOrientation == .forward {
			// forward precedes backward
			return .less
		}
		return .greater
	}
}
