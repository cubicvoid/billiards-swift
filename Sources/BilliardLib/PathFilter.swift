import Foundation

public struct SimpleCycleFeasibilityResult<k: Field & Comparable & Numeric> {
	public let apex: ApexData<k>
	public let turnPath: TurnPath
	public let margin: k

	public var feasible: Bool {
		return margin > k.zero
	}

	public func color() -> CGColor {
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
	}
}

// SimpleCycleFeasibility computes "cycle feasibility" of a path: whether a
// given combinatorial path induces a periodic billiard trajectory on a given
// triangle.
// this is a reference implementation using completely "constructive" methods
// (meaning no explicit use of phase space): compute the coordinates of all
// boundary vertices, project them all orthogonally to the path offset, check
// whether the upper and lower boundaries have a positive separation.
public func SimpleCycleFeasibilityForTurnPath<k: Field & Comparable & Numeric>(
	_ turnPath: TurnPath,
	apex: ApexData<k>
) -> SimpleCycleFeasibilityResult<k>? {
	if turnPath.turns.count % 2 != 0 {
		return nil
	}
	var edge = DiscPathEdge(
		apex: apex,
		coords: Singularities(
			s0: Vec2<k>.origin,
			s1: Vec2(k.one, k.zero)),
		orientation: turnPath.initialOrientation)

	var leftBoundaries: [Vec2<k>] = []
	var rightBoundaries: [Vec2<k>] = []

	for turn in turnPath.turns {
		let turnSign = Sign.of(turn)!
		guard let newEdge = edge.reversed().turnedBy(turn, angleBound: .pi)
		else {
			// no feasible path can cover more than pi of a disc boundary
			return nil
		}
		edge = newEdge
		switch turnSign {
			case .positive:
				leftBoundaries.append(edge.fromCoords())
			case .negative:
				rightBoundaries.append(edge.fromCoords())
		}
		leftBoundaries.append(edge.apexCoordsForSide(.left))
		rightBoundaries.append(edge.apexCoordsForSide(.right))
	}
	let offset = edge.fromCoords()

	// the vector orthogonal to the offset. higher inner product with this
	// vector means further left relative to the offset trajectory.
	let offsetNorm = Vec2(-offset.y, offset.x)

	let leftHeights = leftBoundaries.map(offsetNorm.dot)
	let rightHeights = rightBoundaries.map(offsetNorm.dot)

	return SimpleCycleFeasibilityResult(
		apex: apex, turnPath: turnPath,
		margin: leftHeights.min()! - rightHeights.max()!)
}
