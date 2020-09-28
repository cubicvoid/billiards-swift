
public final class TurnCycle {
	public enum CycleError: Error {
		case oddLengthPath
		case zeroLengthPath
		case zeroTurn
		case monotonicPath
		case nonzeroRotation
	}

	public let segments: [Segment]
	public let length: Int
	public let weight: Int

	private init(segments: [Segment]) {
		let segs = CanonicallyOrderSegments(segments)
		
		let segmentLengths = segs.map { $0.turnDegrees.count }
		self.length = segmentLengths.reduce(0, +)

		let segmentWeights = segs.map { $0.turnDegrees.reduce(0, +) }
		self.weight = segmentWeights.reduce(0, +)

		self.segments = segs
	}
	
	public convenience init(repeatingPath path: TurnPath) throws {
		// Only turn paths from a singularity to itself
		// (hence even length) can be repeated.
		if path.turns.count % 2 != 0 {
			throw CycleError.oddLengthPath
		}
		
		let boundaries = segmentBoundariesForTurns(path.turns)
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
				turnDegrees.append(abs(path.turns[index]))
			}
			segments.append(
				Segment(initialOrientation: orientation, turnDegrees: turnDegrees))
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
	public func asTurnPath() -> TurnPath {
		let coeff = S2(s0: 1, s1: -1)
		var turns: [Int] = []
		let initialOrientation = segments.first!.initialOrientation
		var singularity = initialOrientation.to
		var sign = 1
		for segment in segments {
			for degree in segment.turnDegrees {
				turns.append(coeff[singularity] * sign * degree)
				singularity = singularity.next()
			}
			sign = -sign
		}
		return TurnPath(
			initialOrientation: initialOrientation,
			turns: turns)
	}

	public final class Segment {
		public let initialOrientation: Singularity.Orientation
		public let turnDegrees: [Int]

		public init(
			initialOrientation: Singularity.Orientation, turnDegrees: [Int]
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
	}
}

extension TurnCycle.Segment: Codable, Hashable {
	public convenience init(from: Decoder) throws {
		var container = try from.unkeyedContainer()
		let initialOrientation =
			try container.decode(Singularity.Orientation.self)
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

fileprivate func _Sun(_ str: String) -> String {
	return str
}

fileprivate func _Earth(_ str: String) -> String {
	return DarkGray(str)
}

fileprivate func _ColorString(
	_ str: String, forSingularity s: Singularity
) -> String {
	switch s {
		case .S0: return _Earth(str)
		case .S1: return _Sun(str)
	}
}

fileprivate func _SubstringForTurnPath(
	_ turnPath: TurnPath, signStr: String
) -> String {
	var turnStrings: [String] = []
	var orientation = turnPath.initialOrientation
	for turn in turnPath.turns {
		let turnString = _ColorString(
			signStr + turn.description,
			forSingularity: orientation.to)
		turnStrings.append(turnString)
		orientation = -orientation
	}
	return turnStrings.joined(separator: " ")
}

fileprivate func _SubstringForTurnCycleSegment(
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
}

fileprivate func _SeparatorForOrientation(
	_ orientation: Singularity.Orientation
) -> String {
	switch orientation {
		//case .forward: return " 🌓 "
		case .forward: return " \(DarkGray("("))\(BrightYellow(")")) "
		//case .backward: return " 🌗 "
		case .backward: return " \(BrightYellow("("))\(DarkGray(")")) "
	}
}

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

extension TurnCycle: Comparable {
	public func compareTo(_ cycle: TurnCycle) -> Comparison {
		let lengthComparison = Compare(self.length, to: cycle.length)
		if lengthComparison != .equal {
			return lengthComparison
		}

		let weightComparison = Compare(self.weight, to: cycle.weight)
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

extension TurnCycle.Segment: Comparable {
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

fileprivate func segmentBoundariesForTurns(_ turns: [Int]) -> [Int] {
	var boundaries: [Int] = [];
	var lastSign = Sign.of(turns.last!)!
	for (i, turn) in turns.enumerated() {
		let sign = Sign.of(turn)!
		if sign == lastSign {
			boundaries.append(i)
		}
		lastSign = sign
	}
	return boundaries
}

// This helper rotates an array of monotonic segments to start
// in "canonical" order (which is just lex order on the monotonic
// segments using the Compare:(TurnPath) to: ordering above)
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
		let path = self.asTurnPath()
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

public struct RadiusBounds {
	let min: S2<GmpRational>
	let max: S2<GmpRational>
}

/*public func BoundsOrSomething(cycle: TurnCycle) {
	func asBiphase() -> Singularities<Double> {
		let xApprox = x.asDouble()
		let yApprox = y.asDouble()
		return Singularities(
			s0: Double.pi / (2.0 * atan2(yApprox, xApprox)),
			s1: Double.pi / (2.0 * atan2(yApprox, 1.0 - xApprox)))
	}

}
*/
