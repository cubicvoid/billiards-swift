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
func RandomFlipTrajectory<k: Field & Comparable & Numeric>(billiards: BilliardsData<k>) -> Vec3<k> {
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
    print("search(apex = \(billiards.apex.asDoubleVec()))")
    let attemptCount = 100
    let maxStepCount = 100
    let startingCoords = Singularities(
      s0: Vec2<k>.origin,
      s1: Vec2(x: k.one, y: k.zero))
    let firstEdge: DiscPathEdge<k> = DiscPathEdge(billiards: billiards, coords: startingCoords)

    for _ in 1...attemptCount {
      // choose random trajectory
      let trajectory = RandomFlipTrajectory(billiards: billiards)
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
          let feasibility = SimpleCycleFeasibility(path: turns)
          guard let result = feasibility.forData(billiards)
          else { continue }
          if result.margin > k.zero {
            print("path found: \(turns)")
            return try! TurnPath(turns: turns)
          }
        }

        if turns.count >= maxStepCount {
          break
        }
      }
    }
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
