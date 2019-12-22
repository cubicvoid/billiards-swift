
public class AffineConstraint2d<k: Field> {
  let a: k
  let b: k
  let c: k

  public init(_ a: k, _ b: k, _ c: k) {
    self.a = a
    self.b = b
    self.c = c
  }

  // Given xy coords, returns the dual constraint in the zx plane.
  // side: whether this is a left or right boundary, relative to the +
  public convenience init(
      fromBoundaryCoords coords: Vec2<k>, side: Side) {
    let sign = (side == .left) ? k(1) : k(-1)
    let a = sign
    let b = sign * coords.x//(coords.x + k.one)
    let c = sign * coords.y
    // let a = sign * coords.y
    // let b = sign
    // let c = sign * coords.x
    self.init(a, b, c)
  }

  // Given a slope and intercept in the zx plane, returns the corresponding
  // linear constraint.
  public convenience init(fromSlope slope: k, intercept: k) {
    self.init(-slope, k.one, -intercept)
  }

  // Given a pair of coords in the zx plane, returns the constraint going
  // through them.
  public convenience init(forSegmentFrom from: Vec2<k>, to: Vec2<k>) {
    let dh = to.x - from.x
    let dv = to.y - from.y
    let intercept = from.y - (dv / dh) * from.x
    self.init(-dv, dh, -intercept)
  }

  public var description: String {
    return "(\(a),\(b),\(c))"
  }

  public func intersectionWith (
      _ constraint: AffineConstraint2d<k>) -> Vec2<k> {
    // Compute the (projective) xyz of the intersection as the
    // cross product of the two line coefficients. the
    // strange-looking ordering is because (a,b,c) in the zx plane
    // corresponds to (z,x,y).
    let z = self.b * constraint.c - self.c * constraint.b
    let x = self.c * constraint.a - self.a * constraint.c
    let y = self.a * constraint.b - self.b * constraint.a

    // Convert into A^2 coords in the zx plane
    let h = z / y
    let v = x / y

    return Vec2(x: h, y: v)
  }

  public func offsetOfCoords (_ coords: Vec2<k>) -> k {
    return self.a * coords.x + b * coords.y + c
  }

  public func lastNonzeroOffset(coordsArray: [Vec2<k>]) -> k {
    var i = coordsArray.count - 1
    while i >= 0 {
      let offset = self.offsetOfCoords(coordsArray[i])
      if !offset.isZero() {
        return offset
      }
      i -= 1
    }
    return k.zero
  }

  public func reverse() -> AffineConstraint2d<k> {
    return AffineConstraint2d(-a, -b, -c)
  }
}


// Maintains a convex hull of the dual of a set of path boundaries (treating
// them as a linear program). A segment tree is feasible iff the
// FeasibleVectorRange it generates is nonempty.
public class FeasibleVectorRange<k: Field & Comparable> {
  public var constraints: [AffineConstraint2d<k>]

  // constraintIntersections[i] =
  //   constraints[i].intersect(constraints[i+1])
  public var constraintIntersections: [Vec2<k>]

  public init(
      constraints: [AffineConstraint2d<k>],
      constraintIntersections: [Vec2<k>]) {
    self.constraints = constraints
    self.constraintIntersections = constraintIntersections
  }

  /*public convenience init(
      fromParams params: BilliardsParamsDeprecated<k>,
      orientation: Singularity.Orientation) {
    self.init(fromApex: params.apex, orientation: orientation)
  }*/

  public func copy() -> FeasibleVectorRange<k> {
    return FeasibleVectorRange(constraints: constraints,
        constraintIntersections: constraintIntersections)
  }

  public convenience init(flipAroundEdge edge: FanPathEdgeDeprecated<k>) {
    let from: Vec2<k> = edge.fromCoords()
    let sign = Sign(of: edge.orientation)
    let constraints = [
        AffineConstraint2d<k>(
            fromBoundaryCoords: from,
            side: sign * Side.left),
        AffineConstraint2d(
            fromBoundaryCoords: edge.toCoords(),
            side: sign * Side.left),
        AffineConstraint2d(
            fromBoundaryCoords: edge.apexForSide(sign * Side.left),
            side: sign * Side.right)]
    let constraintIntersections = [
        constraints[0].intersectionWith(constraints[1]),
        constraints[1].intersectionWith(constraints[2]),
        constraints[2].intersectionWith(constraints[0])]
    self.init(
        constraints: constraints,
        constraintIntersections: constraintIntersections)
  }

  // Sign: whether this vertex is a right / lower (1) or left / upper (-1)
  // boundary for the vectors.
  public func addBoundaryVertex(coords: Vec2<k>, side: Side) {
    if constraintIntersections.count == 0 {
      // Empty constraints mean the whole space is infeasible.
      return
    }
    let constraint = AffineConstraint2d(fromBoundaryCoords: coords, side: side)
    var firstFeasible: Int? = nil
    var lastFeasible: Int? = nil
    let intersectionCount = constraintIntersections.count
    let intersectionOffsets = constraintIntersections.map {
      constraint.offsetOfCoords($0)
    }
    var prevOffset = intersectionOffsets.last!
    let zero = k.zero
    for (i, offset) in intersectionOffsets.enumerated() {
      if prevOffset <= zero && offset > zero {
        firstFeasible = i
      } else if prevOffset > zero && offset <= zero {
        lastFeasible = i
      }
      prevOffset = offset
    }
    if firstFeasible == nil {
      // Either all existing intersections are fully within this constraint
      // or all are outside it.
      if prevOffset <= zero {
        // Everything is masked by this constraint.
        constraints = []
        constraintIntersections = []
      }
      return
    }
    let first = firstFeasible!
    let last = lastFeasible!
    let newIntersectionCount =
        (last - first + intersectionCount) % intersectionCount + 1

    var newConstraints: [AffineConstraint2d<k>] = []
    var newConstraintIntersections: [Vec2<k>] = []
    for i in 0..<newIntersectionCount {
      let index = (first + i) % intersectionCount
      newConstraints.append(constraints[index])
      newConstraintIntersections.append(constraintIntersections[index])
    }
    // The last intersection needs to be recomputed because it now intersects
    // with the new constraint.
    newConstraintIntersections[newIntersectionCount - 1] =
      newConstraints.last!.intersectionWith(constraint)
    newConstraints.append(constraint)
    newConstraintIntersections.append(
      constraint.intersectionWith(newConstraints[0]))

    constraints = newConstraints
    constraintIntersections = newConstraintIntersections
  }

  public func isEmpty() -> Bool {
    return (constraints.count == 0)
  }

  public func crossesSegment(lower: Vec2<k>, upper: Vec2<k>) -> Bool {
    let region = self.copy()
    region.addBoundaryVertex(coords: lower, side: .right)
    region.addBoundaryVertex(coords: upper, side: .left)
    return !region.isEmpty()
  }

  // Checks whether there is a feasible line incident to coords in the xy
  // plane.
  public func areCoordsReachable(_ coords: Vec2<k>) -> Bool {
    let constraint = AffineConstraint2d(fromBoundaryCoords: coords, side: .left)

    let offset = constraint.lastNonzeroOffset(
        coordsArray: constraintIntersections)
    let zero = k.zero
    for point in constraintIntersections {
      if constraint.offsetOfCoords(point) * offset < zero {
        return true
      }
    }
    return false
  }

  // Checks whether the given zx coords are contained in the feasible region.
  public func containsCoords(_ coords: Vec2<k>) -> Bool {
    let zero = k.zero
    for c in constraints {
      if c.offsetOfCoords(coords) < zero {
        return false
      }
    }
    return true
  }

  // Given an offset in the xy plane, is there an xy line parallel to offset
  // whose zx dual point is contained in this vector range?
  public func hasElementWithOffset(_ offset: Vec2<k>) -> Bool {
    let yBoundary = -offset.y / offset.x
    var foundLess = false
    var foundGreater = false
    for coords in constraintIntersections {
      if !foundLess && coords.y < yBoundary {
        if foundGreater {
          return true
        }
        foundLess = true
      } else if !foundGreater && coords.y > yBoundary {
        if foundLess {
          return true
        }
        foundGreater = true
      }
    }
    return false
  }

  public var description: String {
    let intersections = constraintIntersections.map { $0.description }
    return "FeasibleVectorRange(" +
        intersections.joined(separator: ", ") + ")"
  }
}
