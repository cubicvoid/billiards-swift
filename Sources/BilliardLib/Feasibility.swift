import Foundation

public struct SimpleCycleFeasibilityResult<k: Field & Comparable & Numeric> {
	public let apex: BilliardsContext<k>
	public let turnPath: TurnPath
	public let margin: k

	public var feasible: Bool {
		return margin > k.zero
	}
}

// SimpleCycleFeasibility computes "cycle feasibility" of a path: whether a
// given combinatorial path induces a periodic billiard trajectory on a given
// triangle.
// this is a reference implementation using completely "constructive" methods
// (meaning no explicit use of phase space): compute the coordinates of all
// boundary vertices, project them all orthogonally to the path offset, check
// whether the upper and lower boundaries have a positive separation.
public func SimpleCycleFeasibilityForPath<
	k: Field & Comparable & Numeric & Signed
>(
	_ turnPath: TurnPath,
	context: BilliardsContext<k>
) -> SimpleCycleFeasibilityResult<k>? {
	if turnPath.count == 0 || turnPath.count % 2 != 0 {
		return nil
	}
	var totals = BaseValues(0, 0)
	for turn in turnPath {
		totals[turn.singularity] += turn.degree
	}
	if totals[.B0] != 0 || totals[.B1] != 0 {
		return nil
	}
	var kite = KiteEmbedding(context: context)

	var leftBoundaries: [Vec2<k>] = []
	var rightBoundaries: [Vec2<k>] = []

	let initialOrientation = BaseOrientation.to(turnPath[0].singularity)
	leftBoundaries.append(kite[initialOrientation.apexForSide(.left)])
	rightBoundaries.append(kite[initialOrientation.apexForSide(.right)])
	//leftBoundaries.append(edge.apexCoordsForSide(.left))
	//rightBoundaries.append(edge.apexCoordsForSide(.right))
	for turn in turnPath {
		// we don't use the turn coefficient directly; this is just a short
		// circuit check, to make sure the turn isn't too big to possibly be
		// feasible (since computing everything in that case can be very expensive)
		let turnCoeff =
			context.rotation[turn.singularity].pow(turn.degree, angleBound: .pi)
		if turnCoeff == nil {
			return nil
		}
		// the center (pivot) of the rotation. A positive turn means B0 on
		// the left, B1 on the right, negative is vice versa.
		// we might want to make this construction implicit in the API, with
		// something like an ApexOrientation to complement the BaseOrientation?
		let turnCenter = kite[turn.singularity]
		let turnSign = Sign.of(turn.degree)!
		if turnSign == .positive {
			leftBoundaries.append(turnCenter)
		} else {
			rightBoundaries.append(turnCenter)
		}
		
		// Advance the kite's position and add the exit boundaries
		kite = kite * turn
		let orientation = BaseOrientation.from(turn.singularity)
		leftBoundaries.append(kite[orientation.apexForSide(.left)])
		rightBoundaries.append(kite[orientation.apexForSide(.right)])
	}
	//print("left: \(leftBoundaries.map { $0.asDoubleVec() })")
	//print("right: \(rightBoundaries.map { $0.asDoubleVec() })")
	let offset = leftBoundaries.last! - leftBoundaries[0]
	//print("offset: \(offset.asDoubleVec())")

	// the vector orthogonal to the offset. higher inner product with this
	// vector means further left relative to the offset trajectory.
	let offsetNorm = Vec2(-offset.y, offset.x)

	let leftHeights = leftBoundaries.map(offsetNorm.dot)
	let rightHeights = rightBoundaries.map(offsetNorm.dot)

	return SimpleCycleFeasibilityResult(
		apex: context, turnPath: turnPath,
		margin: leftHeights.min()! - rightHeights.max()!)
}

enum ConstraintPosition<k: Field & Comparable & Numeric & Signed>: Comparable {
	case left(k)
	case right(k)

	func position() -> k {
		switch self {
			case .left(let x):
				return x
			case .right(let x):
				return x
		}
	}

	static func <(lhs: ConstraintPosition, rhs: ConstraintPosition) -> Bool {
		return lhs.position() < rhs.position()
	}
}

public func UnsatisfiedConstraintCountForPath<
	k: Field & Comparable & Numeric & Signed
>(
	_ turnPath: TurnPath,
	context: BilliardsContext<k>
) -> Int? {
	if turnPath.count == 0 || turnPath.count % 2 != 0 {
		return nil
	}
	var totals = BaseValues(0, 0)
	for turn in turnPath {
		totals[turn.singularity] += turn.degree
	}
	if totals[.B0] != 0 || totals[.B1] != 0 {
		return nil
	}
	var kite = KiteEmbedding(context: context)

	var leftBoundaries: [Vec2<k>] = []
	var rightBoundaries: [Vec2<k>] = []

	let initialOrientation = BaseOrientation.to(turnPath[0].singularity)
	leftBoundaries.append(kite[initialOrientation.apexForSide(.left)])
	rightBoundaries.append(kite[initialOrientation.apexForSide(.right)])
	for turn in turnPath {
		// we don't use the turn coefficient directly; this is just a short
		// circuit check, to make sure the turn isn't too big to possibly be
		// feasible (since computing everything in that case can be very expensive)
		let turnCoeff =
			context.rotation[turn.singularity].pow(turn.degree, angleBound: .none)!
		/*if turnCoeff == nil {
			return nil
		}*/
		// the center (pivot) of the rotation. A positive turn means B0 on
		// the left, B1 on the right, negative is vice versa.
		// we might want to make this construction implicit in the API, with
		// something like an ApexOrientation to complement the BaseOrientation?
		let turnCenter = kite[turn.singularity]
		let turnSign = Sign.of(turn.degree)!
		if turnSign == .positive {
			leftBoundaries.append(turnCenter)
		} else {
			rightBoundaries.append(turnCenter)
		}
		
		// Advance the kite's position and add the exit boundaries
		kite = kite * turn
		let orientation = BaseOrientation.from(turn.singularity)
		leftBoundaries.append(kite[orientation.apexForSide(.left)])
		rightBoundaries.append(kite[orientation.apexForSide(.right)])
	}
	//print("left: \(leftBoundaries.map { $0.asDoubleVec() })")
	//print("right: \(rightBoundaries.map { $0.asDoubleVec() })")
	let offset = leftBoundaries.last! - leftBoundaries[0]
	//print("offset: \(offset.asDoubleVec())")

	// the vector orthogonal to the offset. higher inner product with this
	// vector means further left relative to the offset trajectory.
	let offsetNorm = Vec2(-offset.y, offset.x)

	let leftHeights = leftBoundaries.map(offsetNorm.dot)
	let rightHeights = rightBoundaries.map(offsetNorm.dot)

	let leftPositions = leftHeights.map(ConstraintPosition.left)
	let rightPositions = rightHeights.map(ConstraintPosition.right)

	var positions = leftPositions + rightPositions
	positions.sort()
	
	// the "fully ordered" case is when all .right are < all .left, so
	// we measure deviations from that.
	var leftCount = 0
	var misorderedCount = 0
	for p in positions {
		switch p {
			case .right(_):
			misorderedCount += leftCount
			case .left(_):
			leftCount += 1
		}
	}

	return misorderedCount
}



/*
public func Thingie<k: Field & Comparable & Numeric & Signed>(
	_ turnPath: Path,
	context: BilliardsContext<k>
) -> SimpleCycleFeasibilityResult<k>? {
	if turnPath.count % 2 != 0 {
		return nil
	}
	/*var edge = DiscPathEdge(
		context: context,
		coords: BaseValues(
			b0: Vec2<k>.origin,
			b1: Vec2(k.one, k.zero)),
		orientation: turnPath.initialOrientation)*/
	var kite = KiteEmbedding(context: context)

	var leftBoundaries: [Vec2<k>] = []
	var rightBoundaries: [Vec2<k>] = []

	for turn in turnPath {
		let center = kite[turn.singularity]
		let turnSign = Sign.of(turn.degree)!
		let apexOrientation = ApexOrientation.fromTurnSign(turnSign)
		switch apexOrientation.sideForBase(turn.singularity) {
		case .left:
			leftBoundaries.append(center)
		case .right:
			rightBoundaries.append(center)
		}
		
		kite = kite * turn
		let baseOrientation = BaseOrientation.from(turn.singularity)
		leftBoundaries.append(kite[baseOrientation.apexForSide(.left)])
		rightBoundaries.append(kite[baseOrientation.apexForSide(.right)])
	}
	let offset = kite[Vec2(k.zero, k.zero)]

	// the vector orthogonal to the offset. higher inner product with this
	// vector means further left relative to the offset trajectory.
	let offsetNorm = Vec2(-offset.y, offset.x)

	let leftHeights = leftBoundaries.map(offsetNorm.dot)
	let rightHeights = rightBoundaries.map(offsetNorm.dot)

	return SimpleCycleFeasibilityResult(
		apex: context, turnPath: turnPath,
		margin: leftHeights.min()! - rightHeights.max()!)
}
*/
