// Given a line in the XY plane (ah + bv + c = 0), returns the coordinates of
// that line in the dual space used by FeasibleVectorRange.
public func DualForLineCoefficients<k: Field & Comparable>(
    _ a: k, _ b: k, _ c: k) -> Vec2<k> {
  let h = (c - a) / b
  let v = a / b
  return Vec2(x: h, y: v)
}

// Given a line in the XY plane (y = slope * x + intercept), returns the
// coordinates of that line in the dual space used by FeasibleVectorRange.
public func DualForSlopeIntercept<k: Field & Comparable>(
slope: k, intercept: k) -> Vec2<k> {
  let constraint =  AffineConstraint2d(fromSlope: slope, intercept: intercept)
  return DualForLineCoefficients(constraint.a, constraint.b, constraint.c)
}

/*public func TryFeasibleVectorRange() -> FeasibleVectorRange<GmpRational> {
  typealias k = GmpRational
  let apex = Vec2(x: k(1, over: 2), y: k(2, over: 5))
  let params = BilliardsParamsDeprecated(apex: apex)
  let vr = FeasibleVectorRange(fromParams: params, orientation: .forward)

  let containedCoords = DualForLineCoefficients(k(0), k(1), k(-3, over: 10))
  if !vr.containsCoords(containedCoords) {
    print("Didn't contain point? \(containedCoords)")
    return vr
  }
  let exteriorCoords = DualForLineCoefficients(k(0), k(1), k(-1, over: 2))
  if vr.containsCoords(exteriorCoords) {
    print("Contained point? \(exteriorCoords)")
    return vr;
  }
  var reachableCoords = Vec2(x: k(4), y: k(2, over: 5))
  if !vr.areCoordsReachable(reachableCoords) {
    print("Coords not reachable? \(reachableCoords)")
  }

  vr.addBoundaryVertex(coords: Vec2(x: k(4), y: k(7, over: 20)), side: .left)
  if !vr.containsCoords(containedCoords) {
    print("Didn't contain point? \(containedCoords)")
    return vr
  }
  if vr.containsCoords(exteriorCoords) {
    print("Contained point? \(exteriorCoords)")
    return vr
  }
  if vr.areCoordsReachable(reachableCoords) {
    print("Coords reachable? \(reachableCoords)")
  }

  vr.addBoundaryVertex(coords: Vec2(x: k(8), y: k(1, over: 4)), side: .right)
  if !vr.containsCoords(containedCoords) {
    print("Didn't contain point? \(containedCoords)")
    return vr
  }
  if vr.containsCoords(exteriorCoords) {
    print("Contained point? \(exteriorCoords)")
    return vr
  }

  reachableCoords = Vec2(x: k(9), y: k(1, over: 5))
  if vr.areCoordsReachable(reachableCoords) {
    print("Coords reachable? \(reachableCoords)")
    return vr
  }
  reachableCoords = Vec2(x: k(11), y: k(13, over: 50))
  if !vr.areCoordsReachable(reachableCoords) {
    print("Coords not reachable? \(reachableCoords)")
    return vr
  }
  let crossedEdge = [
      Vec2(x: k(10), y: k(-1)), Vec2(x: k(11), y: k(13, over: 50))]
  let nonCrossedEdge = [
      Vec2(x: k(8), y: k(1, over: 5)), Vec2(x: k(9), y: k(1, over: 5))]
  if vr.crossesSegment(lower: nonCrossedEdge[0], upper: nonCrossedEdge[1]) {
    print("Crossed segment? \(nonCrossedEdge)")
    return vr
  }
  if !vr.crossesSegment(lower: crossedEdge[0], upper: crossedEdge[1]) {
    print("Doesn't cross segment? \(crossedEdge)")
    return vr
  }
  if vr.isEmpty() {
    print("Empty?")
    return vr
  }
  vr.addBoundaryVertex(coords: Vec2(x: k(1), y: k(2)), side: .right)
  if !vr.isEmpty() {
    print("Not empty?")
    return vr
  }
  print("Passed!")
  return vr
}
*/