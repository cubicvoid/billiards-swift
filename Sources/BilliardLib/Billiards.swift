import Foundation

public enum EdgePathDirection: Int, Codable {
  case Left
  case Right

  public func sign() -> Int {
    switch self {
    case .Left:
      return -1
    case .Right:
      return 1
    }
  }
}


public final class EdgePath: Codable {
  var directions: [EdgePathDirection]

  public init() {
    self.directions = []
  }

  public init(_ directions: [EdgePathDirection]) {
    self.directions = directions
  }

  public init(fromString str: String) {
    directions = []
    for c in str {
      if c == "L" {
        directions.append(.Left)
      } else if c == "R" {
        directions.append(.Right)
      }
    }
  }

  public var length: Int {
    get {
      return directions.count
    }
  }

  subscript(index: Int) -> EdgePathDirection {
    get {
      return directions[index]
    }
    set (direction) {
      directions[index] = direction
    }
  }

  public func append(_ d: EdgePathDirection) {
    directions.append(d)
  }

  public func asString() -> String {
    let strings = directions.map {(d: EdgePathDirection) -> String in
      if d == .Left {
        return "L"
      }
      return "R"
    }
    return strings.joined()
  }

  public convenience init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let str = try container.decode(String.self)
    self.init(fromString: str)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(self.asString())
  }
}

//"RRLLLRLLLRRRLR",
public let knownPaths = [
  //"LLLLRRRRLLRRLLLRLLLLLRRRRLLLLRRLLRRRLRRRRR", // unchecked (23/512, 27/512)
  //"LRLRLR",
  //"LRLLLRLRRR",
  //"LRLLLRLRRRRRRLRLLLRL",
  "LRLLLLLRRLLRLRRRRRLLLRLRLRRR", // (6,7)
  /*
   // 7, 8:
   "RRLLLRLLLRRRLR", // 7,8
  "RRRLRRRLLLRLLL", // 7,8
  "RLRLLLRLLRLLLRLRRRRR", // 7,8
  "RLRRRLLLLLRLLLRRRR", // 7,8
  "RRRRLLLLLRLLLLLRRRRRLR", // 7,8
  //"LLLRLLLRRLLRLRRRRR", // (7, 8)
  "LLLRLLLLLLLRRRLRRRRRRR", // 7,8
  */
  //"RRLLLRLLLRRRLR",
  /*
   V low coverage:
   "RRLLLRLLLLLLLRRRLRRRRR",
  "RRRRLLLRLLLLLLLRRRLRRR",
  "RRRRRRLLLRLLLLLLLRRRLR",
  "RRRRRRRLRRRLLLLLLLRLLL",*/

  //7,8:
  /*
  "RLRLLRRLLLRLLLRRRR", // (6,7)
  "RRLLRRLLLRLLLRRLLRRRLR", // (6, 7)
  "RLRRRLLLLLLLRLLLRRRRRR", // (6,7)
  "RLRLLRRLLLLLRLLLRRRRRR", // (6,7)
  "RLRLLRRLLLLLRLRRLLRRRR", // (6,7)
  "RLRRRLLRRLLLRLLLLLRRRR", // (6,7)
  "LLLRLRLRRRRLRLLRRLLLRLRR",
  "RLRRRLLLLLLLLLRLLLRRRRRRRR", // (6,7)
  "LLRRLRLLLLLLLRRLLRLRRRRRRR", // (6,7)
  "LLLLLRLLLLLLLRRRRRLRRRRRRR",
 */
  //"LRLLLLLRRLLRLRRRRRLLLRLRLRRR", // (6,7)
  //"RLRRRLLLLLLLLLLLRLLLRRRRRRRRRR", // (6, 7)
  //"LRLLLLRLLRLRLRRRRLRLLRLRRRRLRLRL", // (6, 7)
  //"RLRRRLLLLLLLLLLLLLRLLLRRRRRRRRRRRR", // (6, 7)
  //"RRRRRRLLRRRRLRLLLLLLLLLRRLLLLRLRRR", // (6, 7)
  //"LRLLLLLRRRRLLLLRRRRRLRRRRRLLLLRRRRLLLL", // (6, 7) (no results, might need higher granularity)
  //"LLRRLRLLLLLLLLLLLRRLLLLRLRRRRRRRRRRRRR", // (7, 8)
  //"LRLLLLLLRLRRRLRRLRRLRRLRRRLRLLLLLLRLRRRR", // 7, 8
  /*"LRLLLLLLLLLRRRLRRRRRRRLLRRRRLLRRRRRRRLRRRLLLLLLLLLRL",
  "LLRRLRLLLLRLRRLLRRRLRRLRLRLLLRRLLRRLLRLRRR",
  */
]

public let apexes : [Vec2<Double>] = [
    Vec2(x: 0.5, y: 0.54),
    Vec2(x: 0.5, y: 0.42)
]

// VerifiedRadiusForPath checks whether the given edge path is a billiard cycle
// for the triangle with the given apex, and if so, returns the positive radius
// to which it can be verified.
// If annotations is non-nil, a visualization of the path is added to it.
public func VerifiedRadiusForPath<k : Field & Comparable>(
    _ path: EdgePath,
    withApex apex: Vec2<k>,
    annotations: AnnotatedList? = nil) -> k? {
  if apex.y == k.zero {
    // Degenerate case, bail out before we hit division by zero or something.
    return nil
  }
  let t = Triangle(Vec2<k>(x: k.zero, y: k.zero),
                   Vec2<k>(x: k.one, y: k.zero),
                   apex)
  var edgeIndex = 0
  var edgeDelta = 1
  let curTriangle = t.copy()
  var leftBoundary = [t.v[0]]
  var rightBoundary = [t.v[1]]
  //NSLog("Initial triangle: \(t)")
  for i in 0..<path.length {
    annotations?.append(Annotated(curTriangle.copy(), "triangle"))
    let apexIndex = (edgeIndex + 2) % 3
    let apex = curTriangle.v[apexIndex]
    let nextEdge = Mod3(edgeIndex + path[i].sign() * edgeDelta)
    if path[i] == .Left {
      rightBoundary.append(apex)
    } else {
      leftBoundary.append(apex)
    }
    //curTriangle.reflectThrough(edgeIndex: nextEdge)
    let vertexIndex = (nextEdge + 2) % 3
    let edgeVector = curTriangle.edge(index: nextEdge)
    let vertexVector = -curTriangle.edge(index: nextEdge-1)
    let projectionCoeff =
        vertexVector.dot(edgeVector) / edgeVector.dot(edgeVector)
    let delta = projectionCoeff * edgeVector - vertexVector
    curTriangle.v[vertexIndex] = curTriangle.v[vertexIndex] + delta + delta
    //NSLog("Reflected triangle: \(curTriangle)")

    edgeIndex = nextEdge
    edgeDelta = -edgeDelta
  }
  annotations?.append(Annotated(leftBoundary, "boundary", "leftBoundary"))
  annotations?.append(Annotated(rightBoundary, "boundary", "rightBoundary"))

  if !PathIsAbstractCycle(path) {
    // It would be more efficient to do this check first, but we do it here so
    // even a non-cycle can still get useful annotations.
    return nil
  }

  // Get the final vector from the first to last triangle.
  let cycleVector = leftBoundary[leftBoundary.count - 1] - leftBoundary[0]
  let heightVector = Vec2<k>(x: -cycleVector.y, y: cycleVector.x)
  //NSLog("CheckPath cycleVector: \(cycleVector)")

  // The leftBoundary must be entirely above cycleVector,
  // rightBoundary below it, as measured along heightVector.
  let origin = leftBoundary[0]
  var upper: [k] = []
  var lower: [k] = []
  for b in leftBoundary {
    upper.append((b - origin).dot(heightVector))
  }
  for b in rightBoundary {
    lower.append((b - origin).dot(heightVector))
  }
  let upperBound = upper.min()!
  let lowerBound = lower.max()!

  if upperBound > lowerBound {
    if annotations != nil {
      // Add a visualization of the successful cycle.
      let center = (upperBound + lowerBound) / k(2)
      // Coefficient of the first left boundary is always 0, since it's the origin
      let baseEdge = rightBoundary[0] - leftBoundary[0]
      let rightCoeff = baseEdge.dot(heightVector)
      let coeff = center / rightCoeff
      let basePoint = leftBoundary[0] + coeff * baseEdge
      let endPoint = basePoint + cycleVector
      annotations!.append(
          Annotated([basePoint, endPoint], "path"))
    }
    return WorstCaseRadiusForCycle(triangleApex: apex,
                                   cycleLength: path.length,
                                   boundsMargin: upperBound - lowerBound)
  }
  return nil
}

// Returns the left and right boundary vertices of the triangle unfolding
// of the gien path, as polynomials in the x,y coordinate of the triangle
// apex.
// The ring element is arbitrary and unused, it is only there to make the
// template have the right return value (since function's can't be explicitly
// specialized).
public func PathBoundaryPolynomials<R: Ring>(path: EdgePath, ringElement _: R)
    -> ([Vec2<Polynomial<R>>], [Vec2<Polynomial<R>>]) {
  let apex: Vec2<Polynomial<R>> = Vec2(
      x: Polynomial<R>(fromVarIndex: 0),
      y: Polynomial<R>(fromVarIndex: 1))
  return PathBoundariesRing(path: path, apex: apex)
}


// Returns the renormalized left and right boundary vertices of the unfolding
// of the triangle with the given apex along the given path.
// Renormalized means the whole vertex set has been rescaled by some value
// (depending on path and apex) to avoid division.
public func PathBoundariesRing<R>(
  path: EdgePath, apex: Vec2<R>) -> ([Vec2<R>], [Vec2<R>]) {
  typealias Poly = Polynomial<R>

  let b: Vec2<R> = apex - Vec2(x: R.one, y: R.zero)
  let c: Vec2<R> = Vec2<R>.origin - apex
  let squaredEdgeLengths = [R.one, b.dot(b), c.dot(c)]
  // The first edge is always normalized to length 1, so cancel it out.
  // The other lengths can be computed in terms of apex, but involve
  // inverses, so we use placeholder variables so we can cancel
  // them all out together at the end.
  let inverseSquaredEdgeLengths =
    [Poly.one, Poly(fromVarIndex: 0), Poly(fromVarIndex: 1)]

  let polyApex: Vec2<Poly> = Vec2(x: Poly(fromScalar: apex.x),
                                          y: Poly(fromScalar: apex.y))
  let (leftBoundary, rightBoundary) = PathBoundaries(
    path: path, apex: polyApex,
    inverseSquaredEdgeLengths: inverseSquaredEdgeLengths)

  let termMax = DegreeList(degrees: [0, 0])
  for b: Vec2<Poly> in leftBoundary {
    termMax.mergeMax(b.x.termCeiling())
    termMax.mergeMax(b.y.termCeiling())
  }
  for b: Vec2<Poly> in rightBoundary {
    termMax.mergeMax(b.x.termCeiling())
    termMax.mergeMax(b.y.termCeiling())
  }
  NSLog("termMax: \(termMax.degrees)")

  NSLog("Initial boundaries found, substituting for inverses...")
  var boundCount = 1
  let vars = [squaredEdgeLengths[1], squaredEdgeLengths[2]]
  NSLog("B: \(b)")
  NSLog("Squared edge B: \(vars[0])")
  NSLog("Squared edge C: \(vars[1])")
  let leftSub: [Vec2<R>] =
      leftBoundary.map {(b: Vec2<Poly>) -> Vec2<R> in
    NSLog("Substituting bound \(boundCount)")
    boundCount += 1
    let x = b.x.invertThrough(zeroTerm: termMax).evaluate(vars: vars)
    let y = b.y.invertThrough(zeroTerm: termMax).evaluate(vars: vars)
    return Vec2(x: x, y: y)
  }
  let rightSub: [Vec2<R>] =
      rightBoundary.map {(b: Vec2<Poly>) -> Vec2<R> in
    NSLog("Substituting bound \(boundCount)")
    boundCount += 1
    let x = b.x.invertThrough(zeroTerm: termMax).evaluate(vars: vars)
    let y = b.y.invertThrough(zeroTerm: termMax).evaluate(vars: vars)
    return Vec2(x: x, y: y)
  }

  return (leftSub, rightSub)
}

// Returns the left and right boundary vertices of the unfolding
// of the triangle with the given apex along the given path.
public func PathBoundariesField<k: Field>(
    path: EdgePath, apex: Vec2<k>) -> ([k], [k]) {
  let b = apex - Vec2(x: k(1), y: k(0))
  let c = Vec2<k>.origin - apex
  let inverseSquaredLengths = [k(1), b.dot(b).inverse(), c.dot(c).inverse()]
  let (leftBoundary, rightBoundary) =
      PathBoundaries(path: path, apex: apex,
                     inverseSquaredEdgeLengths: inverseSquaredLengths)
  return BoundsForPathBoundaries(
      leftBoundary: leftBoundary, rightBoundary: rightBoundary)
}

// inverseSquaredEdgeLengths should have the inverse squared lengths of the
// three triangle edges, in counterclockwise order starting from the base.
// (This means the first element must always equal R.one. Shrug.)
public func PathBoundaries<R: Ring>(
    path: EdgePath, apex: Vec2<R>,
    inverseSquaredEdgeLengths: [R]) -> ([Vec2<R>], [Vec2<R>]) {
 
  var v: [Vec2<R>] = [
    Vec2<R>.origin,
    Vec2<R>(x: R.one, y: R.zero),
    apex]

  var edgeCoeffs: [R] = []
  for i in 0..<3 {
    // The i-th edge coefficient measures how far along the edge from
    // vertex i to vertex (i+1) the projection of vertex (i-1) is.

    // The vector for the edge being reflected through.
    let edgeTCoords: Vec2<R> = v[Mod3(i+1)] - v[i]
    // The vector from the base of the reflection edge to the vertex being
    // reflected.
    let vertTCoords: Vec2<R> = v[Mod3(i-1)] - v[i]

    let edgeCoeff: R =
        edgeTCoords.dot(vertTCoords) * inverseSquaredEdgeLengths[i]
    edgeCoeffs.append(edgeCoeff)
  }

  var edgeIndex = 0
  var edgeDelta = 1
  var leftBoundary: [Vec2<R>] = [v[0]]
  var rightBoundary: [Vec2<R>] = [v[1]]
  for i in 0..<path.length {
    NSLog("Starting reflection \(i+1) of \(path.length)")
    let apexIndex = (edgeIndex + 2) % 3
    let apex = v[apexIndex]
    //NSLog("Apex \(apex)")
    let nextEdge = Mod3(edgeIndex + path[i].sign() * edgeDelta)
    if path[i] == .Left {
      rightBoundary.append(apex)
    } else {
      leftBoundary.append(apex)
    }

    let edgeVector: Vec2<R> = v[(nextEdge + 1) % 3] - v[nextEdge]
    let vertexVector: Vec2<R> = v[(nextEdge + 2) % 3] - v[nextEdge]
    let projectionCoeff: R = edgeCoeffs[nextEdge]
    let delta: Vec2<R> = projectionCoeff * edgeVector - vertexVector
    let v0: Vec2<R> = v[(nextEdge + 2) % 3]
    let tv: Vec2<R> = v0 + delta + delta
    v[(nextEdge + 2) % 3] = tv

    edgeIndex = nextEdge
    edgeDelta = -edgeDelta
  }
  return (leftBoundary, rightBoundary)
}

public func BoundsForPathBoundaries<R>(
  leftBoundary: [Vec2<R>], rightBoundary: [Vec2<R>]) -> ([R], [R]) {
  // Get the final vector from the first to last triangle.
  let cycleVector = leftBoundary[leftBoundary.count - 1] - leftBoundary[0]
  //NSLog("PathBoundaries cycleVector: \(cycleVector)")
  let heightVector = Vec2<R>(x: -cycleVector.y, y: cycleVector.x)
  NSLog("heightVector \(heightVector)")

  // The leftBoundary must be entirely above cycleVector,
  // rightBoundary below it, as measured along heightVector.
  var boundaryCount = 0
  let upper: [R] = leftBoundary.map {(coords: Vec2<R>) -> R in
    boundaryCount += 1
    NSLog("BoundsForPathBoundaries #\(boundaryCount)")
    let xv = coords.x * heightVector.x
    let yv = coords.y * heightVector.y
    let v: R = xv + yv
    return v
  }
  let lower: [R] = rightBoundary.map {(coords: Vec2<R>) -> R in
    boundaryCount += 1
    NSLog("BoundsForPathBoundaries #\(boundaryCount)")
    let xv = coords.x * heightVector.x
    let yv = coords.y * heightVector.y
    let v: R = xv + yv
    return v
  }
  return (lower, upper)
}

// Given:
// - a triangle apex
// - the length of a known cycle on that triangle
// - the smallest margin attained by the linear inequalities defining the
//   valid region of the cycle
// returns the positive radius (if any) around the apex within which the cycle
// is guaranteed to remain valid, based on worst-case estimation of the change
// in the defining linear equalities.
func WorstCaseRadiusForCycle<k: Field & Comparable>(
  triangleApex apex: Vec2<k>, cycleLength: Int, boundsMargin: k) -> k {
  // Trivial rational lower bound on the length of edge 2 (the shortest edge).
  let minLength = max(apex.x, apex.y)
  let n = k(cycleLength + 2)
  return k(8) * minLength * boundsMargin / (n * n * n)
}
