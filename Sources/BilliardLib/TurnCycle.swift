public class TurnCycle: Codable {
	public enum CycleError: Error {
		case oddLengthPath
		case zeroLengthPath
		case zeroTurn
		case monotonicPath
		case nonzeroRotation
	}

	// internal invariant: all turns in these paths are positive.
	public let segments: [TurnPath]
	public let length: Int
	public let weight: Int

	private init(segments: [TurnPath]) {
		let segmentLengths = segments.map { $0.turns.count }
		self.length = segmentLengths.reduce(0, +)

		let segmentWeights = segments.map { $0.turns.reduce(0, +) }
		self.weight = segmentWeights.reduce(0, +)

		self.segments = segments
	}

	public convenience init(repeatingPath path: TurnPath) throws {
		// Only turn paths from a singularity to itself
		// (hence even length) can be repeated.
		if path.turns.count % 2 != 0 {
			throw CycleError.oddLengthPath
		}

		// We're going to scan thru all turns looking for the
		// first segment boundary, so at each iteration we need
		// to compare the sign of the current turn to the previous
		// one. The first time thru the loop, the "previous turn" is
		// the last entry of the array.
		guard let lastTurn = path.turns.last
		else { throw CycleError.zeroLengthPath }
		var previousSign = Sign(of: lastTurn)

		// The index of the first turn with the same geometric
		// sign as the previous one (indicating a boundary between
		// monotonic segments), or nil if none has been found yet.
		var firstSegmentBoundary: Int? = nil

		// The monotonic segments of the path, extracted
		// starting from startIndex
		var segments: [TurnPath] = []

		// The starting orientation and turns of the monotonic segment
		// currently being assembled
		var partialSegment: TurnPathBuilder? = nil

		// The sum of all turns so far around each singularity.
		// In order for path to be repeatable, its total rotations
		// must sum to zero.
		var totalTurns = Singularities(0, 0)

		// The current orientation. A turn applied from this state
		// rotates around orientation.to.
		var orientation = path.initialOrientation

		// The current position in path.turns
		var turnIndex = 0
		repeat {
			// Start of iteration: fetch the current turn and
			// compute its sign.
			let turn = path.turns[turnIndex % path.turns.count]
			guard let sign = Sign(of: turn)
			else { throw CycleError.zeroTurn }

			// Check for segment boundaries: if this turn has
			// the same sign as the previous one, this this index
			// is the start of a new monotonic segment.
			if sign == previousSign {
				if let newSegment = partialSegment?.build() {
					segments.append(newSegment)
				}
				// Initialize to an empty segment
				partialSegment = TurnPathBuilder(initialOrientation: orientation)

				// Set firstSegmentBoundary if it hasn't been yet
				firstSegmentBoundary = firstSegmentBoundary ?? turnIndex
			}

			// If there is a segment in progress, append the new
			// turn and add it to the total for its singularity.
			if let builder = partialSegment {
				builder.appendTurn(abs(turn))
				totalTurns[orientation.to] += turn
			}

			// End of iteration: flip orientations, update previousSign,
			// and advance to the next turn
			orientation = -orientation
			previousSign = sign
			turnIndex += 1

			// We continue until we have traversed every turn
			// after the first segment started, or until we have
			// traversed every turn without finding a segment
			// boundary.
		} while turnIndex - (firstSegmentBoundary ?? 0) < path.turns.count

		guard let lastSegment = partialSegment?.build()
		else { throw CycleError.monotonicPath }
		segments.append(lastSegment)

		// Make sure the full path is net zero rotation
		if totalTurns[.S0] != 0 || totalTurns[.S1] != 0 {
			throw CycleError.nonzeroRotation
		}

		self.init(segments: CanonicallyOrderSegments(segments))
	}

	public func turnPath() -> TurnPath {
		let coeff = Singularities(s0: 1, s1: -1)
		var turns: [Int] = []
		let initialOrientation = segments.first!.initialOrientation
		var singularity = initialOrientation.to
		var sign = 1
		for segment in segments {
			for degree in segment.turns {
				turns.append(coeff[singularity] * sign * degree)
				singularity = singularity.next()
			}
			sign = -sign
		}
		return TurnPath(
			initialOrientation: initialOrientation,
			turns: turns)
	}
}

extension TurnCycle: Hashable {
	public func hash(into hasher: inout Hasher) {
		for segment in segments {
			hasher.combine(segment)
		}
		//hasher.combine(segments)
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
		var strs: [String] = []
		for (i, segment) in segments.enumerated() {
			let signStr = (i % 2 == 1) ? "-" : ""
			strs.append(_SeparatorForOrientation(segment.initialOrientation))
			strs.append(_SubstringForTurnPath(segment, signStr: signStr))
		}
		strs.append(_SeparatorForOrientation(
			segments.first!.initialOrientation))
		return strs.joined()
	}
}

// This helper rotates an array of monotonic segments to start
// in "canonical" order (which is just lex order on the monotonic
// segments using the Compare:(TurnPath) to: ordering above)
func CanonicallyOrderSegments(_ segments: [TurnPath]) -> [TurnPath] {
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

fileprivate func CompareIndex(
	_ index0: Int, toIndex index1: Int,
	withSegments segments: [TurnPath]
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

extension TurnCycle: Equatable {
	public static func ==(
		cycle0: TurnCycle, cycle1: TurnCycle
	) -> Bool {
		let segments0 = cycle0.segments
		let segments1 = cycle1.segments
		if segments0.count != segments1.count {
			return false
		}
		for i in 0..<segments0.count {
			if segments0[i] != segments1[i] {
				return false
			}
		}
		return true
	}
}

/*extension TurnCycle: Comparable {
	public func compareTo(_ cycle: TurnCycle) -> Comparison {
		let lengthComparison = Compare(self.length, to: cycle.length)
		if lengthComparison != .equal {
			return lengthComparison
		}

		let weightComparison = Compare(self.weight, to: cycle.weight)
		if weightComparison != .equal {
			return weightComparison
		}

	}

	public static func <(cycle0: TurnCycle, cycle1: TurnCycle) {
		
	}
}*/