/*class Trajectory<k: Field & Comparable> {

  // Create a trajectory centered on a flip. The coefficients represent
  // the intersection points of the trajectory along each ascending edge
  // of the triangle, scaled so that 0 is the base vertex and 1 is the
  // apex.
  public init(billiards: BilliardsData<k>, riseCoeffs: Singularities<k>) {
    let leftCoords = Vec2(
      x: billiards.apex.x * riseCoeffs[.S0],
      y: billiards.apex.y * riseCoeffs[.S0])
    let rightCoords = Vec2(
      x: k.one + (billiards.apex.x - k.one) * riseCoeffs[.S1],
      y: billiards.apex.y * riseCoeffs[.S1])
    let offset = rightCoords - leftCoords
    let normal = offset.cross()


  }
}*/

// Returns a trajectory in the xy plane expressed as its normal in the
// containing xyz spherical space.
func RandomFlipTrajectory<k: Field & Comparable>(billiards: BilliardsData<k>) -> Vec3<k> {
  let leftNum = Int(try! RandomInt(bits: 32))
  let leftCoeff = k(leftNum, over: 1 << 32)
  let rightNum = Int(try! RandomInt(bits: 32))
  let rightCoeff = k(rightNum, over: 1 << 32)

  let leftCoords = Vec2(
    x: billiards.apex.x * leftCoeff,
    y: billiards.apex.y * leftCoeff)
  let rightCoords = Vec2(
    x: k.one + (billiards.apex.x - k.one) * rightCoeff,
    y: billiards.apex.y * rightCoeff)
  let offset = rightCoords - leftCoords
  let normal = offset.cross()
  return Vec3(
    x: normal.x,
    y: normal.y,
    z: -normal.x * leftCoords.x - normal.y * leftCoords.y)
}

public class TrajectorySearch<k: Field & Comparable & Numeric> {
  let options: Options

  public init(options: Options? = nil) {
    self.options = options ?? Options()
    print("Initialized TrajectorySearch")
  }

  //public func search(trajectory: Trajectory<k>) -> TurnPath? {
  public func search(billiards: BilliardsData<k>) -> TurnPath? {
    let attemptCount = 2
    // one step is two turns, one around each singularity.
    let stepCount = 5
    let startingCoords = Singularities(
      s0: Vec2<k>.origin,
      s1: Vec2(x: k.one, y: k.zero))
    attemptLoop: for _ in 1...attemptCount {
      // choose random trajectory
      let trajectory = RandomFlipTrajectory(billiards: billiards)
      var turns: [Int] = []
      // the base (center) edge in the current quad
      var edge = DiscPathEdge(billiards: billiards, coords: startingCoords)
      print("trajectory: \(trajectory)")
      var angles = Singularities(s0: 0, s1: 0)
      for _ in 1...stepCount {
        // All our paths are listed with turns around S1 first.
        for s in [Singularity.S1, Singularity.S0] {
          guard let turnDegree = edge.nextTurnForTrajectory(trajectory)
          else { continue attemptLoop }
          let newAngle = angles[s] + turnDegree

          edge = edge.turnedBy(turnDegree)
          angles = angles.withValue(newAngle, forSingularity: s)
          turns.append(turnDegree)
        }
        if angles[.S0] == 0 && angles[.S1] == 0 {
          // possible cycle
          let feasibility = SimpleCycleFeasibility(path: turns)
          guard let _ = feasibility.forData(billiards)
          else { continue }
          return try! TurnPath(turns: turns)
        }
      }
    }
    print("Searching apex: \(billiards.apex)")
    return nil
  }

  public class Options {
    public init() {

    }
  }

  class Result {
    public let paths: [TurnPath]

    init(paths: [TurnPath]) {
      self.paths = paths
    }
  }

}
