public struct TurnPath: Hashable {
	public let initialOrientation: Singularity.Orientation
	public let turns: [Int]

	public init(
		initialOrientation: Singularity.Orientation,
		turns: [Int]
	) {
		self.initialOrientation = initialOrientation
		self.turns = turns
	}
}

extension TurnPath: CustomStringConvertible {
	public var description: String {
		return "\(initialOrientation.from)->\(turns)"
	}
}

public class TurnPathBuilder {
	private let initialOrientation: Singularity.Orientation
	private var turns: [Int] = []

	public init(initialOrientation: Singularity.Orientation) {
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