import Foundation

extension Vec3 where R: Numeric {
	public func asDouble() -> Vec3<Double> {
		return Vec3<Double>(x: x.asDouble(), y: y.asDouble(), z: z.asDouble())
	}
}

extension Vec3 where R == Double {
	public func normalized() -> Vec3<Double> {
		let norm = sqrt(x * x + y * y + z * z)
		return Vec3(x: x / norm, y: y / norm, z: z / norm)
	}
}

// invariant: for all i, constraints[i].cross(constraints[i+1]) != k.zero
//
// returns nil if the constraint list is unchanged, otherwise returns the new
// polygon.
func mergeConstraint<k: Field & Comparable>(
	_ newConstraint: Vec3<k>,
	withList constraints: [Vec3<k>]
) -> SphericalPolygon<k>? {

	let n = constraints.count
	if n == 0 {
		return .constraints([newConstraint])
	}
	if n == 1 {
		let oldConstraint = constraints.first!
		if oldConstraint.cross(newConstraint) == Vec3<k>.origin {
			// The two constraints are scalar multiples of each other; if they have
			// the same sign, the new one can be discarded, otherwise they cover the
			// whole sphere.
			if oldConstraint.dot(newConstraint) > k.zero {
				return nil
			}
			return .empty
		}
		// In all other cases, the two constraints are distinct and non-redundant.
		return .constraints([constraints.first!, newConstraint])
	}
	// from now on, n >= 2
	let vertexOffsets: [k] = (0..<n).map { i in
		let current = constraints[i]
		let next = constraints[(i+1) % n]
		let vertex = current.cross(next)
		return newConstraint.dot(vertex)
	}
	if !vertexOffsets.contains(where: { offset in offset != k.zero }) {
		// this special case can only happen when there are exactly two existing
		// constraints, and their intersection points lie on the new one.
		// this is a surprisingly complicated subcase; see the logs on
		// 2019/09/06-07 for derivation.
		let axis = constraints[0].cross(constraints[1])
		let products = [
			constraints[0].cross(newConstraint).dot(axis),
			newConstraint.cross(constraints[1]).dot(axis)
		]
		let positive = products.map { x in x > k.zero }
		if positive[0] && positive[1] {
			// no change, the existing constraints are already extremal
			return nil
		}
		if positive[0] {
			// only constraints[0] is extremal
			return .constraints([constraints[0], newConstraint])
		}
		if positive[1] {
			// only constraints[1] is extremal
			return .constraints([newConstraint, constraints[1]])
		}
		// neither is extremal, the whole region is constrained
		return .empty
	}
	// Start at a vertex with negative offset (which is therefore definitely
	// altered by the insertion).
	guard let firstNegative =
			vertexOffsets.firstIndex(where: { offset in offset < k.zero })
	else {
		// If there isn't an index with negative product with the constraint,
		// then the entire boundary is already contained in it.
		return nil
	}
	guard let firstPositive = (firstNegative..<firstNegative+n).first(where: {
		i in vertexOffsets[i % n] > k.zero
	}) else {
		// the new constraint masks all existing vertices
		return .empty
	}
	let nextNonPositive = (firstPositive..<firstPositive+n).first(
		where: { i in vertexOffsets[i % n] <= k.zero })!

	var newConstraints = (firstPositive...nextNonPositive).map {
		i in constraints[i % n]
	}
	newConstraints.append(newConstraint)
	return .constraints(newConstraints)
}

func mergeConstraints<k: Field & Comparable>(
	_ newConstraints: [Vec3<k>],
	withList constraintList: [Vec3<k>]
) -> SphericalPolygon<k>? {
	var curConstraints: [Vec3<k>]? = nil
	for c in newConstraints {
		guard let merged =
				mergeConstraint(c, withList: curConstraints ?? constraintList)
		else { continue }
		if merged == .empty {
			return .empty
		}
		curConstraints = merged.constraints
	}
	guard let result = curConstraints
	else { return nil }
	return .constraints(result)
}


public enum SphericalPolygon<
		k: Field & Comparable & CustomStringConvertible>: Equatable {
	case empty
	case fullSphere
	case constraints([Vec3<k>])
	
	public var constraints: [Vec3<k>] {
		switch self {
		case .constraints(let constraints): return constraints
		default: return []
		}
	}
	
	public static func fromConstraints(
		_ constraints: [Vec3<k>]
	) -> SphericalPolygon {
		return SphericalPolygon.fullSphere.withConstraints(constraints)
	}

	public static func *(
			_ m: Matrix3x3<k>, _ polygon: SphericalPolygon) -> SphericalPolygon {
		switch polygon {
		case .constraints(let constraints):
			return .constraints(constraints.map { c in m * c })
		default:
			return polygon
		}
	}

	public func containsCoords(_ coords: Vec3<k>) -> Bool {
		switch self {
		case .fullSphere: return true
		case .empty: return false
		case .constraints(let constraints):
			for c in constraints {
				if c.dot(coords) <= k.zero {
					return false
				}
			}
			return true
		}
	}
	
	public func withConstraint(_ constraint: Vec3<k>) -> SphericalPolygon {
		switch self {
		case .empty: return .empty
		case .fullSphere: return .constraints([constraint])
		case .constraints(let constraints):
			guard let newPolygon = mergeConstraint(constraint, withList: constraints)
			else { return self }
			return newPolygon
		}
	}

	public func withConstraints(_ constraints: [Vec3<k>]) -> SphericalPolygon {
		return constraints.reduce(self) { (polygon, constraint) in
			polygon.withConstraint(constraint)
		}
	}

	public func intersect(_ polygon: SphericalPolygon) -> SphericalPolygon {
		switch polygon {
		case .empty: return .empty
		case .fullSphere: return self
		case .constraints(let constraints):
			return self.withConstraints(constraints)
		}
	}

	public func isEmpty() -> Bool {
		switch self {
			case .empty: return true
			default: return false
		}
	}
	
	// Two polygons are equal if and only if every constraint of either of them
	// is redundant with respect to the other.
	public static func ==(
			_ p0: SphericalPolygon, _ p1: SphericalPolygon) -> Bool {
		switch (p0, p1) {
			case (.empty, .empty): return true
			case (.fullSphere, .fullSphere): return true
			case (let .constraints(c0), let .constraints(c1)):
				// merging either with the other should leave it unchanged
				return (mergeConstraints(c0, withList: c1) == nil) &&
					(mergeConstraints(c1, withList: c0) == nil)
			default: return false
		}
	}

	public func contains(_ polygon: SphericalPolygon) -> Bool {
		switch (polygon, self) {
			case (_, .fullSphere): return true
			case (.empty, _): return true
			case (let .constraints(c0), let .constraints(c1)):
				return mergeConstraints(c0, withList: c1) == nil
			default: return false
		}
	}

	public var description: String {
		switch self {
		case .empty:
			return "Empty"
		case .fullSphere:
			return "Sphere"
		case .constraints(let constraints):
			let cstr = constraints
				.map { $0.description }
				.joined(separator: ", ")
			return "Constraints[\(cstr)]"
		}
	}
}

public extension SphericalPolygon where k: Numeric {
	func approximateArea() -> Double {
		switch self {
		case .empty:
			return 0.0
		case .fullSphere:
			return 4.0 * Double.pi
		case .constraints(let constraints):
			let angles = (0..<constraints.count).map { i -> Double in
				let c0 = constraints[i]
				let c1 = constraints[(i + 1) % constraints.count]
				let norm = sqrt((c0.dot(c0) * c1.dot(c1)).asDouble())
				let dotProduct = c0.dot(c1).asDouble() / norm
				return abs(acos(dotProduct))
			}
			return 2.0 * Double.pi - angles.reduce(0.0, +)
		}
	}
}

private func chooseBasisForPlane<k: Field>(
	normal: Vec3<k>
) -> [Vec3<k>] {
	let canonical: [Vec3<k>] = [
		Vec3(x: k.zero, y: k.one, z: k.zero),
		Vec3(x: k.zero, y: k.zero, z: k.one)
	]
	let ortho: [Vec3<k>?] = canonical.map { $0.cross(normal) }
	let b0 = ortho[0] != nil ? ortho[0]! : ortho[1]!
	let b1 = normal.cross(b0)
	return [b0, b1]
}

private func greatCircle<k: Field & Numeric>(
		normal: Vec3<k>, vertexCount: Int) -> [Vec3<Double>] {
	let basis = chooseBasisForPlane(normal: normal)
	let numericBasis = basis.map { v in v.asDouble() }
	return (0..<vertexCount).map { i in
		let angle = 2.0 * Double.pi * Double(i) / Double(vertexCount)
		let c = cos(angle)
		let s = sin(angle)
		return Vec3(
			x: c * numericBasis[0].x + s * numericBasis[1].x,
			y: c * numericBasis[0].y + s * numericBasis[1].y,
			z: c * numericBasis[0].z + s * numericBasis[1].z)
	}
}

// boundaries should be exactly three elements
private func approximateLineSegment<k: Field & Numeric>(
	boundaries: [Vec3<k>],
	anglePrecision: Double
) -> [Vec3<Double>] {

	let intersections = [
		boundaries[0].cross(boundaries[1]),
		boundaries[1].cross(boundaries[2])]

	let endpoints: [Vec3<Double>] =
		intersections.map { point in point.asDouble().normalized() }
	let line = boundaries[1].asDouble().normalized()

	// the basis to use in the plane of the disc
	let basis = [endpoints[0], line.cross(endpoints[0])]
	let endCoords = [
		basis[0].dot(endpoints[1]),
		basis[1].dot(endpoints[1])
	]
	var totalAngle = atan2(endCoords[1], endCoords[0])
	if totalAngle < 0.0 {
		totalAngle += 2.0 * Double.pi
	}

	let pointCount = Int(ceil(totalAngle / anglePrecision))
	return (0..<pointCount).map { i in
		let angle = totalAngle * Double(i) / Double(pointCount)
		let c = cos(angle)
		let s = sin(angle)
		return Vec3(
			x: c * basis[0].x + s * basis[1].x,
			y: c * basis[0].y + s * basis[1].y,
			z: c * basis[0].z + s * basis[1].z).normalized()
	}
}

private func approximateSegmentsForConstraints<k: Field & Numeric>(
		_ constraints: [Vec3<k>],
		anglePrecision: Double) -> [Vec3<Double>] {
	let n = constraints.count
	let edges = (0..<n).map { i -> [Vec3<Double>] in
		let constraints =
			[constraints[i], constraints[(i+1) % n], constraints[(i+2) % n]]
		return approximateLineSegment(
			boundaries: constraints,
			anglePrecision: anglePrecision)
	}
	return Array(edges.joined())
}

public extension SphericalPolygon where k: Numeric {
	func approximateBoundary(anglePrecision: Double) -> [Vec3<Double>]? {
		switch self {
		case .constraints(let constraints):
			return approximateSegmentsForConstraints(
				constraints, anglePrecision: anglePrecision)
		default:
			return nil
		}
	}
}
