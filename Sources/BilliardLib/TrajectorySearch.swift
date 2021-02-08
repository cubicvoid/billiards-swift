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
	options opts: TrajectorySearchOptions? = nil,
	cancel: (() -> Bool)? = nil
) -> TrajectorySearchResult {
	let options = opts ?? TrajectorySearchOptions()
	var cycles: [TurnPath] = []
	var shortestCycle: TurnPath? = nil
	let apexCoordsApprox = apexCoords.asDoubleVec()
	//print("search(apex = \(apexCoordsApprox))")
	let context = BilliardsContext(apex: apexCoords)
	let apexApprox = BilliardsContext(apex: apexCoordsApprox)

	func addCycleForPath(_ path: TurnPath) {
		if shortestCycle == nil || path.count < shortestCycle!.count {
			shortestCycle = path
			if !options.allowMultipleResults {
				// We want to keep the shortest cycle,
				// so reset the cycles list.
				cycles = []
			}
		}
		if cycles.isEmpty || options.allowMultipleResults {
			cycles.append(path)
		}
	}

	if options.maxPathLength < 4 {
		return TrajectorySearchResult(
			cycles: cycles,
			shortestCycle: shortestCycle)
	}

	for _ in 1...options.attemptCount {
		if cancel?() == true {
			break
		}
		// choose random trajectory
		let trajectory = RandomFlipTrajectory(apex: apexApprox.coords)
		var stepCount = options.maxPathLength
		// If we're only keeping the shortest cycle, then we only
		// need to search up to the depth of the shortest path
		// we've found.
		if shortestCycle != nil && !options.allowMultipleResults {
			stepCount = min(stepCount, shortestCycle!.count)
		}
		if let path = SearchTrajectory(trajectory,
			withApex: apexApprox,
			forSteps: stepCount
		) {
			// make sure it works with exact computation too
			if let result = SimpleCycleFeasibilityForPath(path, context: context) {
				if result.feasible {
					addCycleForPath(path)
				}
			}
			if cycles.count > 0 && options.stopAfterSuccess {
				return TrajectorySearchResult(
					cycles: cycles,
					shortestCycle: shortestCycle)
			}
		}
	}
	return TrajectorySearchResult(
		cycles: cycles,
		shortestCycle: shortestCycle)
}

public struct TrajectorySearchResult {
	public let cycles: [TurnPath]
	public let shortestCycle: TurnPath?
}

public struct TrajectorySearchOptions {
	public var stopAfterSuccess: Bool = true
	public var skipKnownPoints: Bool = true
	public var allowMultipleResults: Bool = false
	public var attemptCount: Int = 100
	public var maxPathLength: Int = 100

	public init() { }
}

func SearchTrajectory<k: Field & Comparable & Numeric & Signed>(
	_ trajectory: Vec3<k>,
	withApex context: BilliardsContext<k>,
	forSteps stepCount: Int
) -> TurnPath? {
	/*let startingCoords = BaseValues(
		b0: Vec2<k>.origin,
		b1: Vec2(x: k.one, y: k.zero))*/
	/*let firstEdge: DiscPathEdge<k> = DiscPathEdge(
		context: context, coords: startingCoords)*/
	var kite = KiteEmbedding(context: context)

	var path = TurnPath.empty
	var angles = BaseValues(b0: 0, b1: 0)

	for turn in kite.turnsForTrajectory(trajectory) {
		angles[turn.singularity] += turn.degree
		kite = kite * turn
		path *= turn

		if angles[.B0] == 0 && angles[.B1] == 0 {
			// possible cycle
			if let result = SimpleCycleFeasibilityForPath(
				path, context: context
			) {
				if result.feasible { return path }
			}
		}

		if path.count >= stepCount {
			break
		}
	}
	return nil
}
