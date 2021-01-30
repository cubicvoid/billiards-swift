import Foundation

// calculates the minimum length of all conjugates of the given path by
// cancelling out any complementary prefix / suffix
func reducedLength(_ path: Path) -> Int {
	var suffixLength = 0
	while (suffixLength+1) * 2 <= path.count {
		let before = path[suffixLength]
		let after = path[path.count - 1 - suffixLength]
		if before != after.inverse() {
			break
		}
		suffixLength += 1
	}
	return path.count - 2 * suffixLength
}

// A TurnCycle represents the quotient of a Path by conjugation,
// exponentiation and involution (through the homomorphism sending
// the two generators to their inverses).
// It is meant to represent the cycle
// induced by infinitely repeating a given path.
// Any turn path p naturally induces a cycle as the (bidirectional)
// limit of p^n. conversely, for any cycle we can choose a minimum-length
// path p such that every p' generating the same cycle has a unique
// expression in terms of p, parameterized by a TurnCycle.Generator.
// Specifically:
//   p' = transpose * (conjugate.inverse() * p^power * conjugate)
// where the transpose product indicates the elementwise inverse, i.e.
// the automorphism that sends each turn to its inverse.
public struct TurnCycle: Codable, Hashable {
	public struct PathSpec {
		let power: Int
		let conjugate: Path

		let transpose: Bool
	}

	public enum CycleError: Error {
		case identityCycle
		case oddLengthPath
		case zeroLengthPath
		case zeroTurn
		case monotonicPath
		case nonzeroRotation
	}

	// A turn path selected consistently but semi-arbitrarily from
	// the set of paths generating this cycle under exponentiation
	let path: Path

	private init(canonicalPath: Path) {
		path = canonicalPath
	}

	public static func fromPath(_ path: Path) -> (TurnCycle, PathSpec) {

	}

	public func pathForSpec(_ s: PathSpec) -> Path {
		let inner = path.pow(s.power)
		let outer = s.conjugate.inverse() * inner * s.conjugate
		if s.transpose {
			return outer.transpose()
		}
		return outer
	}
	//public let weight: Int

	/*private init(segments: [Segment]) {
		let segs = CanonicallyOrderSegments(segments)
		
		let segmentLengths = segs.map { $0.turnDegrees.count }
		self.length = segmentLengths.reduce(0, +)

		//let segmentWeights = segs.map { $0.turnDegrees.reduce(0, +) }
		//self.weight = segmentWeights.reduce(0, +)

		self.segments = segs
	}
	
	public convenience init(repeatingPath path: Path) throws {
		// Only turn paths from a singularity to itself
		// (hence even length) can be repeated.
		if path.turns.count % 2 != 0 {
			throw CycleError.oddLengthPath
		}
		
		var components = path.monotonicComponents()
		if components.count % 2 != 0 {
			let last = components.removeLast()
			// The first and last component are the same sign, merge them
			components[0] = last * components[0]
		}
		let boundaries = segmentBoundariesForPath(path)
		let initialOrientation =
			(boundaries[0] % 2 == 0)
				? path.initialOrientation
				: -path.initialOrientation
		var orientation = initialOrientation
		var segments: [Segment] = []
		for i in boundaries.indices {
			let start = boundaries[i]
			let end = boundaries[(i+1) % boundaries.count]
			let length =
				(end > start)
					? end - start
					: end + path.turns.count - start
			var turnDegrees: [Int] = []
			for j in 0..<length {
				let index = (start + j) % path.turns.count
				turnMagnitudes.append(abs(path.turns[index]))
			}
			segments.append(
				Segment(initialOrientation: orientation, turnMagnitudes: turnMagnitudes))
			if length % 2 != 0 {
				// If this segment is odd length, the next one will start on the
				// opposite orientation.
				orientation = -orientation
			}
		}
		self.init(segments: segments)
	}

	// Returns a turn path that generates this cycle. The choice of turn path
	// is arbitrary but deterministic for a given cycle.
	public func asPath() -> Path {
		let coeff = BaseValues(b0: 1, b1: -1)
		var turns: [Int] = []
		let initialOrientation = segments.first!.initialOrientation
		var orientation = initialOrientation
		var sign = 1
		for segment in segments {
			for degree in segment.turnDegrees {
				turns.append(coeff[orientation.to] * sign * degree)
				orientation = -orientation
			}
			sign = -sign
		}
		return Path(
			initialOrientation: initialOrientation,
			turnsDegrees: turns)
	}

	public final class Segment {
		public let initialOrientation: BaseOrientation
		public let turnDegrees: [Int]

		public init(
			initialOrientation: BaseOrientation, turnDegrees: [Int]
		) {
			self.initialOrientation = initialOrientation
			self.turnDegrees = turnDegrees
		}
		
		public func reversed() -> Segment {
			let newOrientation =
				(turnDegrees.count % 2) == 0 ? -initialOrientation : initialOrientation
			return Segment(
				initialOrientation: newOrientation,
				turnDegrees: turnDegrees.reversed())
		}
	}*/

}

/*
extension TurnCycle.Segment: Codable, Hashable {
	public convenience init(from: Decoder) throws {
		var container = try from.unkeyedContainer()
		let initialOrientation =
			try container.decode(BaseOrientation.self)
		let turnDegrees = try container.decode([Int].self)
		self.init(
			initialOrientation: initialOrientation,
			turnDegrees: turnDegrees)
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.unkeyedContainer()
		try container.encode(initialOrientation)
		try container.encode(turnDegrees)
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(initialOrientation)
		hasher.combine(turnDegrees)
	}
}

extension TurnCycle: Codable, Hashable {
	public convenience init(from: Decoder) throws {
		let container = try from.singleValueContainer()
		let segments = try container.decode([Segment].self)
		self.init(segments: segments)
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(segments)
	}

	public func hash(into hasher: inout Hasher) {
		for segment in segments {
			hasher.combine(segment)
		}
	}
}
*/
fileprivate func _Sun(_ str: String) -> String {
	return str
}

fileprivate func _Earth(_ str: String) -> String {
	return DarkGray(str)
}

fileprivate func _ColorString(
	_ str: String, forSingularity s: BaseSingularity
) -> String {
	switch s {
		case .B0: return _Earth(str)
		case .B1: return _Sun(str)
	}
}

fileprivate func _SubstringForPath(
	_ turnPath: Path, signStr: String
) -> String {
	var turnStrings: [String] = []
	for turn in turnPath {
		let turnString = _ColorString(
			signStr + turn.description,
			forSingularity: turn.singularity)
		turnStrings.append(turnString)
	}
	return turnStrings.joined(separator: " ")
}

/*fileprivate func _SubstringForTurnCycleSegment(
	_ segment: TurnCycle.Segment, signStr: String
) -> String {
	var turnStrings: [String] = []
	var orientation = segment.initialOrientation
	for turn in segment.turnDegrees {
		let turnString = _ColorString(
			signStr + turn.description,
			forSingularity: orientation.to)
		turnStrings.append(turnString)
		orientation = -orientation
	}
	return turnStrings.joined(separator: " ")
}*/

fileprivate func _SeparatorForOrientation(
	_ orientation: BaseOrientation
) -> String {
	switch orientation {
		//case .forward: return " 🌓 "
		case .forward: return " \(DarkGray("("))\(BrightYellow(")")) "
		//case .backward: return " 🌗 "
		case .backward: return " \(BrightYellow("("))\(DarkGray(")")) "
	}
}

/*
extension TurnCycle: CustomStringConvertible {
	public var description: String {
		let initialOrientation = segments.first!.initialOrientation
		var strs: [String] = []
		let from = initialOrientation.from
		strs.append(_ColorString("\(from)", forSingularity: from))
		for (i, segment) in segments.enumerated() {
			let signStr = (i % 2 == 1) ? "-" : ""
			strs.append(_SeparatorForOrientation(segment.initialOrientation))
			strs.append(_SubstringForTurnCycleSegment(segment, signStr: signStr))
		}
		strs.append(_SeparatorForOrientation(initialOrientation))
		let to = initialOrientation.to
		strs.append(_ColorString("\(to)", forSingularity: to))
		return strs.joined()
	}
}
*/

/*
fileprivate func CompareIndex(
	_ index0: Int, toIndex index1: Int,
	withSegments segments: [TurnCycle.Segment]
) -> Comparison {
	for offset in 0..<segments.count {
		let segment0 = segments[(index0 + offset) % segments.count]
		let segment1 = segments[(index1 + offset) % segments.count]

		let comparison = segment0.compareTo(segment1)
		if comparison != .equal {
			return comparison
		}
	}
	return .equal
}
*/

/*
extension TurnCycle: Comparable {
	public func compareTo(_ cycle: TurnCycle) -> Comparison {
		let lengthComparison = Compare(self.length, to: cycle.length)
		if lengthComparison != .equal {
			return lengthComparison
		}

		let weightComparison = Compare(
			self.asPath().totalWeight(),
			to: cycle.asPath().totalWeight())
		if weightComparison != .equal {
			return weightComparison
		}

		let segmentCountComparison =
			Compare(self.segments.count, to: cycle.segments.count)
		if segmentCountComparison != .equal {
			return segmentCountComparison
		}

		for i in 0..<segments.count {
			let segmentComparison = segments[i].compareTo(cycle.segments[i])
			if segmentComparison != .equal {
				return segmentComparison
			}
		}
		return .equal
	}

	public static func <(cycle0: TurnCycle, cycle1: TurnCycle) -> Bool {
		return cycle0.compareTo(cycle1) == .less
	}
	
	public static func ==(
		cycle0: TurnCycle, cycle1: TurnCycle
	) -> Bool {
		return cycle0.compareTo(cycle1) == .equal
	}
}
*/

/*extension TurnCycle.Segment: Comparable {
	// implements a somewhat arbitrary total order on
	// Segments,
	public func compareTo(_ s: TurnCycle.Segment) -> Comparison {
		let lengthComparison =
			Compare(turnDegrees.count, to: s.turnDegrees.count)
		if lengthComparison != .equal {
			return lengthComparison
		}

		let weightSelf = turnDegrees.reduce(0, +)
		let weightSeg = s.turnDegrees.reduce(0, +)
		let weightComparison = Compare(weightSelf, to: weightSeg)
		if weightComparison != .equal {
			return weightComparison
		}
		
		let squaredWeightSelf = turnDegrees.reduce(0) { $0 + $1 * $1 }
		let squaredWeightSeg = s.turnDegrees.reduce(0) { $0 + $1 * $1 }
		let squaredWeightComparison =
				Compare(squaredWeightSelf, to: squaredWeightSeg)
		if squaredWeightComparison != .equal {
			return squaredWeightComparison
		}
		
		// If aggregate properties fail, fall back on lexical order
		for i in 0..<turnDegrees.count {
			let turnComparison = Compare(turnDegrees[i], to: s.turnDegrees[i])
			if turnComparison != .equal {
				return turnComparison
			}
		}
		
		if initialOrientation == s.initialOrientation {
			return .equal
		}
		if initialOrientation == .forward {
			return .less
		}
		return .greater
	}
	
	public static func < (lhs: TurnCycle.Segment, rhs: TurnCycle.Segment) -> Bool {
		return lhs.compareTo(rhs) == .less
	}
	
	public static func == (lhs: TurnCycle.Segment, rhs: TurnCycle.Segment) -> Bool {
		return lhs.compareTo(rhs) == .equal
	}
}

// This helper rotates an array of monotonic segments to start
// in "canonical" order (which is just lex order on the monotonic
// segments using the Compare:(Path) to: ordering above)
fileprivate func CanonicallyOrderSegments(
	_ segments: [TurnCycle.Segment]
) -> [TurnCycle.Segment] {
	var lowestOrderedSegmentIndex = 0
	for segmentIndex in 1..<segments.count {
		let segmentComparison = CompareIndex(
			segmentIndex,
			toIndex: lowestOrderedSegmentIndex,
			withSegments: segments)
		if segmentComparison == .less {
			lowestOrderedSegmentIndex = segmentIndex
		} else if
			segmentComparison == .equal &&
			(segmentIndex - lowestOrderedSegmentIndex) % 2 == 0
		{
			// The segments repeat, we only want the range
			// from lowestOrderedSegmentIndex to segmentIndex.
			// because this is the first repetition, there is no
			// need to account for wrapping around the end of
			// the segments array.
			// we exclude "repetitions" that happen an odd
			// distance apart, because they will not be repetitions
			// in the corresponding turn path (they will repeat
			// with opposite sign). we might eventually decide to
			// collapse those as well, but for now having a
			// "canonical form" that skips some apparent turns
			// is confusing, hence this awkward parity check.
			return Array(segments[lowestOrderedSegmentIndex..<segmentIndex])
		}
	}
	return Array(
		segments[lowestOrderedSegmentIndex...] +
		segments[..<lowestOrderedSegmentIndex])
}


extension TurnCycle {
	public func isSymmetric() -> Bool {
		let path = self.asPath()
		let n = path.turns.count
		// a cycle has a reflective symmetry iff its turn path representatives do.
		centerLoop:
		for center in 0..<n {
			for offset in 1..<(n / 2) {
				let left = (center - offset + n) % n
				let right = (center + offset) % n
				if path.turns[left] != path.turns[right] {
					continue centerLoop
				}
			}
			return true
		}
		return false
	}
}

extension Path {
	public func maxDegrees() -> BaseValues<Int> {
		var result = BaseValues(0, 0)
		for step in self {
			let degree = abs(step.turn)
			result[step.singularity] = Swift.max(result[step.singularity], degree)
		}
		return result
	}
}

// The combinatorial data for a single flip within a turn cycle.
public struct TurnFlip {
	public let orientation: BaseOrientation
	public let degrees: BaseValues<Int>
}

public struct FlipIterator: Sequence, IteratorProtocol {
	private let cycle: TurnCycle
	private var segmentIndex: Int = 0
	private var prevSegment: TurnCycle.Segment
	
	init(_ cycle: TurnCycle) {
		self.cycle = cycle
		self.prevSegment = cycle.segments.last!
	}
	
	public mutating func next() -> TurnFlip? {
		if segmentIndex >= cycle.segments.count {
			return nil
		}
		let segment = cycle.segments[segmentIndex]
		let prevDegree = prevSegment.turnDegrees.last!
		let curDegree = segment.turnDegrees.first!
		let orientation = segment.initialOrientation
		let degrees = (orientation == .forward)
			? BaseValues(prevDegree, curDegree)
			: BaseValues(curDegree, prevDegree)
		prevSegment = segment
		segmentIndex += 1
		return TurnFlip(orientation: orientation, degrees: degrees)
	}
}

extension TurnCycle {
	public func flips() -> FlipIterator {
		return FlipIterator(self)
	}
}

public struct RadiusBounds {
	public let min: BaseValues<Double>
	public let max: BaseValues<Double>
}


// infers somewhat reasonable bounds on the possible range of
// input radii for which the given cycle could be feasible.
// Any feasible apex is guaranteed to be within the returned
// bounds.
public func BoundsOrSomething(cycle: TurnCycle) -> RadiusBounds {
	let maxDegrees = cycle.asPath().maxDegrees()
	let maxAngles = maxDegrees.map { Double.pi / Double(2 * ($0 - 1)) }
	let minRadii = maxAngles.map { 1.0 / tan($0) }
	
	// the angle range occluded by the apex in a flip is
	//   Pi - 2(theta0 + theta1)
	// in particular it is the same in both circles.
	// (for details see logs, electronic and paper, in the
	// vicinity of 2020/10/04)
	//let minOccluded = Double.pi - 2 * (maxAngles[.S0] + maxAngles[.S1])

	// start from the worst case: the maximum possible turn degree
	//var minAngles = maxDegrees.map { minOccluded / Double($0) }
	var minAngles = BaseValues(0.0, 0.0)
	for flip in cycle.flips() {
		for o in BaseOrientation.all {
			let s = o.from
			let t = o.to
			//minAngles[s] =
			//print("turn degree \(flip.degrees[s])")
			let bound =
				(Double.pi / 2 - maxAngles[t]) / Double(flip.degrees[s] + 1)
			if bound > minAngles[s] {
				minAngles[s] = bound
			}
		}
	}
	let maxRadii = minAngles.map { 1.0 / tan($0) }
	
	return RadiusBounds(min: minRadii, max: maxRadii)
}*/

