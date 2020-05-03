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

public func TrajectorySearchForApex(
    _ apex: Vec2<GmpRational>, options opts: TrajectorySearchOptions? = nil
) -> TrajectorySearchResult {
  let options = opts ?? TrajectorySearchOptions()
  var paths: [TurnPath] = []
  let apexApprox = apex.asDoubleVec()
  print("search(apex = \(apexApprox))")
  let billiards = BilliardsData(apex: apex)
  let billiardsApprox = BilliardsData(apex: apexApprox)
    
  for _ in 1...options.attemptCount {
    // choose random trajectory
    let trajectory = RandomFlipTrajectory(apex: apexApprox)
    if let path = SearchTrajectory(trajectory,
        withBilliardsData: billiardsApprox,
        forSteps: options.maxPathLength) {
      if options.skipExactCheck {
        paths.append(path)
      } else if let result = SimpleCycleFeasibilityForTurns(path.turns, billiardsData: billiards) {
        if result.feasible {
          print("path found: \(path.turns)")
          let path = try! TurnPath(turns: path.turns)
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

public class TrajectorySearchResult {
  public let paths: [TurnPath]

  init(paths: [TurnPath]) {
    self.paths = paths
  }
}

public class TrajectorySearchOptions {
  public var stopAfterSuccess: Bool = true
  public var skipExactCheck: Bool = false
  public var attemptCount: Int = 100
  public var maxPathLength: Int = 100

  public init() { }
}


func SearchTrajectory<k: Field & Comparable & Numeric>(
    _ trajectory: Vec3<k>,
    withBilliardsData billiards: BilliardsData<k>,
    forSteps stepCount: Int
) -> TurnPath? {
  
  let startingCoords = Singularities(
    s0: Vec2<k>.origin,
    s1: Vec2(x: k.one, y: k.zero))
  let firstEdge: DiscPathEdge<k> = DiscPathEdge(billiards: billiards, coords: startingCoords)

  var turns: [Int] = []
  var angles = Singularities(s0: 0, s1: 0)

  for step in firstEdge.stepsForTrajectory(trajectory) {
    // the current center singularity is the one that the
    // incoming edge points to
    let singularity = step.incomingEdge.orientation.to
    let newAngle = angles[singularity] + step.turnDegree
    angles = angles.withValue(newAngle, forSingularity: singularity)
    turns.append(step.turnDegree)

    if angles[.S0] == 0 && angles[.S1] == 0 {
      // possible cycle
      print("possible cycle")
      let feasibility = SimpleCycleFeasibility(turns: turns)
      guard let result = feasibility.forData(billiards)
      else { continue }
      if result.margin > k.zero {
        print("candidate found: \(turns)")
        return try! TurnPath(turns: turns)
      }
    }

    if turns.count >= stepCount {
      break
    }
  }
  return nil
}