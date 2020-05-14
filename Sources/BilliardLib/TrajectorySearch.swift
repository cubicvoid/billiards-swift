import Foundation

// Returns a trajectory in the xy plane expressed as its normal in the
// containing xyz spherical space.
func RandomFlipTrajectory<k: Field & Comparable & Numeric>(apex: Vec2<k>) -> Vec3<k> {
	let leftNum = Int(try! RandomInt(bits: 32))
	let leftCoeff = k(leftNum, over: 1 << 32)
	let rightNum = Int(try! RandomInt(bits: 32))
	let rightCoeff = k(rightNum, over: 1 << 32)

	let leftCoords = Vec2(
		x: apex.x * leftCoeff,
		y: apex.y * leftCoeff)
	let rightCoords = Vec2(
		x: k.one + (apex.x - k.one) * rightCoeff,
		y: apex.y * rightCoeff)
	let offset = rightCoords - leftCoords
	let normal = offset.cross()
	return Vec3(
		x: normal.x,
		y: normal.y,
		z: -normal.x * leftCoords.x - normal.y * leftCoords.y)
}

public func TrajectorySearchForApexCoords(
	_ apexCoords: Vec2<GmpRational>,
	options opts: TrajectorySearchOptions? = nil
) -> TrajectorySearchResult {
	let options = opts ?? TrajectorySearchOptions()
	var paths: [TurnPath] = []
	let apexCoordsApprox = apexCoords.asDoubleVec()
	print("search(apex = \(apexCoordsApprox))")
	let apex = ApexData(coords: apexCoords)
	let apexApprox = ApexData(coords: apexCoordsApprox)

	for _ in 1...options.attemptCount {
		// choose random trajectory
		let trajectory = RandomFlipTrajectory(apex: apexApprox.coords)
		if let path = SearchTrajectory(trajectory,
			withApex: apexApprox,
			forSteps: options.maxPathLength
		) {
			if options.skipExactCheck {
				paths.append(path)
			} else if let result = SimpleCycleFeasibilityForTurnPath(path, apex: apex) {
				if result.feasible {
					paths.append(path)
				}
			}
			if paths.count > 0 && options.stopAfterSuccess {
				return TrajectorySearchResult(paths: paths)
			}
		}
	}
	return TrajectorySearchResult(paths: paths)
}

public struct TrajectorySearchResult {
	public let paths: [TurnPath]
}

public struct TrajectorySearchOptions {
	public var stopAfterSuccess: Bool = true
	public var skipExactCheck: Bool = false
	public var attemptCount: Int = 100
	public var maxPathLength: Int = 100

	public init() { }
}


func SearchTrajectory<k: Field & Comparable & Numeric>(
	_ trajectory: Vec3<k>,
	withApex apex: ApexData<k>,
	forSteps stepCount: Int
) -> TurnPath? {
	let startingCoords = Singularities(
		s0: Vec2<k>.origin,
		s1: Vec2(x: k.one, y: k.zero))
	let firstEdge: DiscPathEdge<k> = DiscPathEdge(
		apex: apex, coords: startingCoords)

	var turns: [Int] = []
	var angles = Singularities(s0: 0, s1: 0)

	for step in firstEdge.stepsForTrajectory(trajectory) {
		// the current center singularity is the one that the
		// incoming edge points to
		let aroundSingularity = step.incomingEdge.orientation.to
		let newAngle = angles[aroundSingularity] + step.turnDegree
		angles = angles.withValue(newAngle, forSingularity: aroundSingularity)
		turns.append(step.turnDegree)

		if aroundSingularity == .S0 && angles[.S0] == 0 && angles[.S1] == 0 {
			// possible cycle
			let turnPath = TurnPath(initialOrientation: .forward, turns: turns)
			if let result = SimpleCycleFeasibilityForTurnPath(
				turnPath, apex: apex
			) {
				if result.feasible { return turnPath }
			}
		}

		if turns.count >= stepCount {
			break
		}
	}
	return nil
}