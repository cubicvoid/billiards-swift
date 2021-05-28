import Foundation

// the "standard" coordinates for the vertices of the
// kite are (in widdershins order):
//   (-cot theta[.B0], 0)
//   (0, -1)
//   (cot theta[.B1], 0)
//   (0, 1)
// in particular the domain of a transformation on the kite depends
// on the input apex.
// A KiteEmbedding gives a complex linear map from this polygon into
// the Euclidean plane. It is acted on by Path, (the fundamental group of
// the kite, although it is usually safe to think of a "path" as being the
// sequence of kite edges crossed by an unfolding) by applying the rotations
// around v0 and v1 induced by unfolding along it. (this action preserves
// scale.)
public class KiteEmbedding<k: Field & Comparable & Signed> {
	private var _ctx: BilliardsContext<k>
	
	// The image of the origin (0, 0) under this embedding.
	private var _origin: Vec2<k>
	
	// The (complex) scale factor for this embedding.
	private var _scale: Vec2<k>
	
	private init(context: BilliardsContext<k>, origin: Vec2<k>, scale: Vec2<k>) {
		_ctx = context
		_origin = origin
		_scale = scale
	}
	
	public init(context: BilliardsContext<k>) {
		_ctx = context
		_origin = Vec2(k.zero, k.zero)
		_scale = Vec2(k.one, k.zero)
	}
	
	public subscript(_ s: Singularity) -> Vec2<k> {
		switch s {
		case .B0:
			return _origin + _scale.complexMul(Vec2(-_ctx.r[.B0], k.zero))
		case .B1:
			return _origin + _scale.complexMul(Vec2(_ctx.r[.B1], k.zero))
		case .A0:
			return _origin + _scale.complexMul(Vec2(k.zero, k.one))
		case .A1:
			return _origin + _scale.complexMul(Vec2(k.zero, -k.one))
		}
	}
	
	public subscript(_ b: BaseSingularity) -> Vec2<k> {
		switch b {
		case .B0: return self[Singularity.B0]
		case .B1: return self[Singularity.B1]
		}
	}
	
	public subscript(_ a: ApexSingularity) -> Vec2<k> {
		switch a {
		case .A0: return self[Singularity.A0]
		case .A1: return self[Singularity.A1]
		}
	}
	
	public subscript(_ v: Vec2<k>) -> Vec2<k> {
		return _origin + _scale.complexMul(v)
	}
	
	public static func *(k: KiteEmbedding, t: TurnPath.Turn) -> KiteEmbedding {
		let rot = k._ctx.rotation[t.singularity]
		let rotationCoeff = rot.pow(t.degree)
		let centerCoords = k[t.singularity]
		let delta = k._origin - centerCoords
		let newOrigin = centerCoords + delta.complexMul(rotationCoeff)
		let newScale = k._scale.complexMul(rotationCoeff)
		return KiteEmbedding(context: k._ctx, origin: newOrigin, scale: newScale)
	}
	
	public static func *(k: KiteEmbedding, p: TurnPath) -> KiteEmbedding {
		var kite = k
		for turn in p {
			kite = kite * turn
		}
		return kite
	}
}

public extension KiteEmbedding {
	// The KiteEmbedding lives in the xy plane (represented with Vec2).
	// Trajectories t are represented as lines on the xyz sphere, as the
	// collection of points p with (t.x * p.x + t.y * p.y + t.z == 0),
	// via the inclusion sending the xy plane to the sphere by setting z=1 and
	// normalizing.
	func nextTurnForTrajectory(_ t: Vec3<k>) -> TurnPath.Turn? {
		let a0 = self[Singularity.A0]
		let a1 = self[Singularity.A1]
		guard let sign0 = Sign(of: t.x * a0.x + t.y * a0.y + t.z)
		else { return nil }
		guard let sign1 = Sign(of: t.x * a1.x + t.y * a1.y + t.z)
		else { return nil }
		if sign0 == sign1 {
			// right now we only define an action on trajectories that pass between
			// the two apexes. we could extend it to also work on trajectories
			// that pass between the two base vertices as well, if we ever find a
			// reason we'd want to.
			return nil
		}
		
		// If A0 has positive orthogonal offset from the trajectory, it means
		// A0 is on the left and the next turn will be around B1.
		let center: BaseSingularity = (sign0 == .positive) ? .B1 : .B0
		let centerCoords = self[center]
		// is centerCoords to the left or right of the trajectory?
		guard let innerSide: Side = PointSide(centerCoords, ofTrajectory: t)
		else { return nil }
		// if the center of the disc is on our left, then the disc's outer
		// boundary will be on our right
		let outerSide = -innerSide
		let turnSign: Sign = (innerSide == .left) ? .positive : .negative
		
		let entering = BaseOrientation.to(center)
		// apex is the base point we will use to find the
		// rest of the disc boundaries
		let apex = entering.apexForSide(outerSide)
		let rotation = _ctx.rotation[center]

		// degreeMin and degreeMax are the lowest / highest degrees the turn could
		// possibly be given the sign checks we've made so far
		var degreeMin = 1
		var degreeMax = rotation.maxTurnMagnitudeForBound(.pi)

		let delta = self[apex] - centerCoords
		while degreeMax > degreeMin {
			let testDegree = degreeMin + (degreeMax - degreeMin) / 2
			let rotCoeff = rotation.pow(turnSign * testDegree)
			let point = centerCoords + delta.complexMul(rotCoeff)
			let side = PointSide(point, ofTrajectory: t)
			if side == innerSide {
				degreeMax = testDegree
			} else {
				degreeMin = testDegree + 1
			}
		}
		if degreeMax != degreeMin {
			print("something is broken in KiteEmbedding.nextTurnForTrajectory")
		}
		return TurnPath.Turn(degree: turnSign * degreeMin, singularity: center)
	}

	func turnsForTrajectory(_ t: Vec3<k>) -> TurnIterator {
		return TurnIterator(embedding: self, trajectory: t)
	}

	class TurnIterator: Sequence, IteratorProtocol {
		public typealias Element = TurnPath.Turn
		
		private var embedding: KiteEmbedding
		private let trajectory: Vec3<k>

		init(embedding: KiteEmbedding, trajectory: Vec3<k>) {
			self.embedding = embedding
			self.trajectory = trajectory
		}

		public func next() -> TurnPath.Turn? {
			if let turn = embedding.nextTurnForTrajectory(trajectory) {
				embedding = embedding * turn
				return turn
			}
			return nil
		}
	}
}




public class DiscPathEdge<k: Field & Comparable> {
	public var coords: BaseValues<Vec2<k>>
	public var orientation: BaseOrientation
	public var rotationCounts: BaseValues<Int>
	
	let ctx: BilliardsContext<k>
	
	public init(
		context: BilliardsContext<k>,
		coords: BaseValues<Vec2<k>>,
		orientation: BaseOrientation,
		rotationCounts: BaseValues<Int>
	) {
		self.ctx = context
		self.coords = coords
		self.orientation = orientation
		self.rotationCounts = rotationCounts
	}
	
	public convenience init(
		context: BilliardsContext<k>,
		coords: BaseValues<Vec2<k>>,
		orientation: BaseOrientation = .forward
	) {
		self.init(
			context: context,
			coords: coords,
			orientation: orientation,
			rotationCounts: BaseValues(0, 0))
	}
	
	public func fromCoords() -> Vec2<k> {
		return coords[orientation.from]
	}
	
	public func toCoords() -> Vec2<k> {
		return coords[orientation.to]
	}
	
	private func _apexCoordsForSide(
		_ side: Side,
		orientation: BaseOrientation
	) -> Vec2<k> {
		if orientation == .backward {
			return _apexCoordsForSide(-side, orientation: .forward)
		}
		let baseCoords = coords[.B0]
		let offset = coords[.B1] - coords[.B0]
		var apexCoeff = ctx.coords
		if side == .right {
			apexCoeff = apexCoeff.complexConjugate()
		}
		return baseCoords + offset.complexMul(apexCoeff)
	}
	
	public func apexCoordsForSide(_ side: Side) -> Vec2<k> {
		return _apexCoordsForSide(side, orientation: orientation)
	}

	public func turnedBy(_ turnDegree: Int) -> DiscPathEdge<k> {
		return self.turnedBy(turnDegree, angleBound: nil)!
	}
	
	// result is guaranteed to be non-nil if angleBound is nil
	public func turnedBy(
		_ turnDegree: Int,
		angleBound: AngleBound?
	) -> DiscPathEdge? {
		let rotation = ctx.rotation[orientation.from]

		guard let rotationCoeff = rotation.pow(turnDegree, angleBound: angleBound)
		else { return nil }
		let initialOffset = coords[orientation.to] - coords[orientation.from]
		let newOffset = initialOffset.complexMul(rotationCoeff)
		let newCoords = coords.withValue(
			coords[orientation.from] + newOffset,
			forSingularity: orientation.to)
		
		let newCount = rotationCounts[orientation.from] + turnDegree
		let newRotationCounts =
			rotationCounts.withValue(newCount, forSingularity: orientation.from)
		
		return DiscPathEdge(
			context: ctx,
			coords: newCoords,
			orientation: orientation,
			rotationCounts: newRotationCounts)
	}
	
	public func reversed() -> DiscPathEdge<k> {
		return DiscPathEdge(
			context: ctx,
			coords: coords,
			orientation: -orientation,
			rotationCounts: rotationCounts)
	}
	
	public func isAngleZero() -> Bool {
		return (rotationCounts[.B0] == 0 && rotationCounts[.B1] == 0)
	}

	// a "real" trajectory should always point between self.coords in the
	// direction self.orientation, traevlling in between the left and right
	// apex boundaries. however we do not require this as long as the trajectory
	// exits the disc with a well-defined turn when restricted to the
	// disc nearest the entering edge (i.e. as long as we can follow it
	// geometrically along the covering slice whose discontinuity is the line
	// exiting the target singularity in the direction from the source one).
	public func nextTurnForTrajectory(_ trajectory: Vec3<k>) -> Int? {
		let center = self.toCoords()
		guard let centerSide = PointSide(center, ofTrajectory: trajectory)
		else { return nil }

		let rotation = ctx.rotation[orientation.to]
		let maxTurnMagnitude = rotation.maxTurnMagnitudeForBound(.pi)
		// The offset of the starting boundary apex from the center of the
		// target disc.
		var vZero: Vec2<k>
	
		// The tightest indices we know for the boundary points on each side
		// of the trajectory; i.e. leftBound is the lowest index that is
		// definitely on the left of the trajectory, rightBound is the
		// highest index that is definitely on the right.
		var leftBound, rightBound: Int
	
		if centerSide == .left {
			// widdershins, a positive turn
			vZero = self.apexCoordsForSide(.right) - center
			leftBound = maxTurnMagnitude
			rightBound = 0
		} else {
			// clockwise, a negative turn
			vZero = self.apexCoordsForSide(.left) - center
			leftBound = 0
			rightBound = -maxTurnMagnitude
		}

		while leftBound - rightBound > 1 {
			// testIndex is guaranteed to be strictly between leftBound and
			// rightBound.
			let testIndex = rightBound + (leftBound - rightBound) / 2
			let point = center + vZero.complexMul(rotation.pow(testIndex))
			guard let side = PointSide(point, ofTrajectory: trajectory)
			else { return nil }
			if side == .left {
				leftBound = testIndex
			} else {
				rightBound = testIndex
			}
		}
		// return the bound with highest absolute value
		if centerSide == .left {
			return leftBound
		}
		return rightBound
	}

	public func stepsForTrajectory(_ t: Vec3<k>) -> StepIterator {
		return StepIterator(firstEdge: self, trajectory: t)
	}

	public class Step {
		public let incomingEdge: DiscPathEdge
		public let outgoingEdge: DiscPathEdge
		public let turnDegree: Int

		init(incomingEdge: DiscPathEdge, outgoingEdge: DiscPathEdge, turnDegree: Int) {
			self.incomingEdge = incomingEdge
			self.outgoingEdge = outgoingEdge
			self.turnDegree = turnDegree
		}
	}

	public class StepIterator: Sequence, IteratorProtocol {
		public typealias Element = Step
		
		private let trajectory: Vec3<k>
		private var currentEdge: DiscPathEdge

		init(firstEdge: DiscPathEdge, trajectory: Vec3<k>) {
			self.trajectory = trajectory
			self.currentEdge = firstEdge
		}

		public func next() -> Step? {
			guard let turnDegree = currentEdge.nextTurnForTrajectory(trajectory)
			else { return nil }
			guard let nextEdge = currentEdge.reversed().turnedBy(turnDegree, angleBound: .pi)
			else {
				print("Error (StepIterator): turnedBy should never fail when the input came from nextTurnForTrajectory")
				return nil
			}
			let step = Step(incomingEdge: currentEdge, outgoingEdge: nextEdge, turnDegree: turnDegree)
			self.currentEdge = nextEdge
			return step
		}
	}
}

func OffsetOfCoords<k: Field>(_ v: Vec2<k>, fromTrajectory t: Vec3<k>) -> k {
	return v.x * t.x + v.y * t.y + t.z
}

public func PointSide<k: Field & Comparable>(_ p: Vec2<k>, ofTrajectory t: Vec3<k>) -> Side? {
	let offset = OffsetOfCoords(p, fromTrajectory: t)
	if offset.isZero() {
		return nil
	}
	if offset > k.zero {
		return .left
	}
	return .right
}

public func PointSign<k: Field & Comparable & Signed>(
	_ p: Vec2<k>, forTrajectory t: Vec3<k>) -> Sign?
{
	let offset = OffsetOfCoords(p, fromTrajectory: t)
	return Sign(of: offset)
}
