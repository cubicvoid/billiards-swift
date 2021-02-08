import Foundation

public struct SimpleCycleFeasibilityResult<k: Field & Comparable & Numeric> {
	public let apex: BilliardsContext<k>
	public let turnPath: TurnPath
	public let margin: k

	public var feasible: Bool {
		return margin > k.zero
	}

	/*public func color() -> CGColor {
		let expectedMargin = apex.coords.y / k(turnPath.turns.count)

		var hue: Vec3<Double>
		var ratio: k
		if margin > k.zero {
			hue = Vec3(0.0, 0.0, 0.5)
			ratio = margin / expectedMargin
		} else {
			hue = Vec3(0.4, 0.4, 0.0)
			ratio = -margin / expectedMargin
		}
		let r = ratio.asDouble()
		let saturation = min(r / (r + 15.0), 0.8)
		let white = Vec3(1.0, 1.0, 1.0)
		let color = hue + saturation * (white - hue)
		return CGColor(
			red: CGFloat(color.x),
			green: CGFloat(color.y),
			blue: CGFloat(color.z),
			alpha: 0.6)
	}*/
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
	/*var edge = DiscPathEdge(
		context: context,
		coords: BaseValues(
			b0: Vec2<k>.origin,
			b1: Vec2(k.one, k.zero)),
		orientation: turnPath.initialOrientation)*/

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
		if (turnSign == .positive) == (turn.singularity == .B0) {
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
	let offset = leftBoundaries.last! - leftBoundaries[0]

	// the vector orthogonal to the offset. higher inner product with this
	// vector means further left relative to the offset trajectory.
	let offsetNorm = Vec2(-offset.y, offset.x)

	let leftHeights = leftBoundaries.map(offsetNorm.dot)
	let rightHeights = rightBoundaries.map(offsetNorm.dot)

	return SimpleCycleFeasibilityResult(
		apex: context, turnPath: turnPath,
		margin: leftHeights.min()! - rightHeights.max()!)
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
