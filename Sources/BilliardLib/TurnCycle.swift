public struct TurnPath {
	public let initialOrientation: Singularity.Orientation
	public let turns: [Int]
}

public class TurnCycle {
	public let initialOrientation: Singularity.Orientation

	public init(repeatingPath path: TurnPath) {
		initialOrientation = path.initialOrientation
	}
}

// TurnCycle represents a homotopy class from S0 -> S0 as an even-length
// sequence of signed turns around the singularities, beginning with S1 and
// alternating each step.
/*public class TurnCycle {
	public let turns: [Int]
	public let canonical: Bool

	private weak var _canonicalCache: TurnCycle? = nil

	public enum PathError: Error {
		case oddPathLength
	}

	private init(turns: [Int], canonical: Bool) {
		self.turns = turns
		self.canonical = canonical
	}

	public init(turns: [Int]) throws {
		if turns.count % 2 != 0 {
			throw PathError.oddPathLength
		}
		self.turns = turns
		self.canonical = false
	}

	func computeCanonicalized() -> TurnCycle {
		// The index of the lowest-ordered rotation
		var minIndex = 0
		let pairCount = turns.count / 2
		for i in 1..<pairCount {
			let index = 2 * i
			guard let newMin = TurnArray(turns, minimumOfIndex: minIndex, andIndex: index)
			else {
				// this turn sequence is fixed by a nontrivial rotation
				let reducedLength = index - minIndex
				let reducedPath = try! TurnCycle(turns: Array(turns[0..<reducedLength]))
				return reducedPath.canonicalized()
			}
			minIndex = newMin
		}

		let newTurns = Array(turns[minIndex...] + turns[..<minIndex])
		return TurnCycle(turns: newTurns, canonical: true)
	}

	// canonical paths:
	// - cannot be expressed as a repetition of any shorter path
	// - over all paths arising from an (even-length) rotation, the canonical one
	//   is minimal with respect to lex order on the _signs_ of the turns, then
	//   (in case of equality) to lex order on the actual turns.
	public func canonicalized() -> TurnCycle {
		if canonical {
			return self
		}
		if let canonicalPath = _canonicalCache {
			return canonicalPath
		}
		let canonicalPath = computeCanonicalized()
		_canonicalCache = canonicalPath
		return canonicalPath
	}
}*/

// this returns reasonable values for any pair of indices, but in typical
// circumstances we expect all indices to be even
func TurnArray(_ turns: [Int], minimumOfIndex i: Int, andIndex j: Int) -> Int? {
	if let minSignLex = IntArray(turns, minSignLexForIndex: i, andIndex: j) {
		return minSignLex
	}
	return IntArray(turns, minLexForIndex: i, andIndex: j)
}

func IntArray(_ array: [Int], minSignLexForIndex i: Int, andIndex j: Int) -> Int? {
	let n = array.count
	for offset in 0..<n {
		let iVal = array[(i + offset) % n]
		let jVal = array[(j + offset) % n]
		if iVal < 0 && jVal > 0 {
			return i
		}
		if iVal > 0 && jVal < 0 {
			return j
		}
	}
	return nil
}

func IntArray(_ array: [Int], minLexForIndex i: Int, andIndex j: Int) -> Int? {
	let n = array.count
	for offset in 0..<n {
		let iVal = array[(i + offset) % n]
		let jVal = array[(j + offset) % n]
		if iVal < jVal {
			return i
		}
		if iVal > jVal {
			return j
		}
	}
	return nil
}
