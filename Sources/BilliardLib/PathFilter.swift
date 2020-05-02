import Foundation

public class SimpleCycleFeasibilityResult<k: Field & Comparable & Numeric> {
  private let turns: [Int]
  private let billiardsData: BilliardsData<k>
  public let margin: k

  public var feasible: Bool {
    return margin > k.zero
  }

  init(margin: k, turns: [Int], billiardsData: BilliardsData<k>) {
    self.margin = margin
    self.turns = turns
    self.billiardsData = billiardsData
  }

  public func color() -> CGColor {
    let expectedMargin = billiardsData.apex.y / k(turns.count)

    var hue: Vec3<Double>
    var ratio: k
    if margin > k.zero {
      hue = Vec3(0.0, 0.0, 0.5)
      ratio = margin / expectedMargin
    } else {
      hue = Vec3(0.4, 0.4, 0.0)
      ratio = -margin / expectedMargin
    }
    let r = ratio.asDouble()
    let saturation = min(r / (r + 15.0), 0.8)
    //let white = Vec3(0.85, 0.85, 0.85)
    let white = Vec3(1.0, 1.0, 1.0)
    let color = hue + saturation * (white - hue)
    return CGColor(
      red: CGFloat(color.x),
      green: CGFloat(color.y),
      blue: CGFloat(color.z),
      alpha: 0.6)
    //let saturation = 
    //return hue
  }
}

// SimpleCycleFeasibility computes "cycle feasibility" of a path: whether a
// given combinatorial path induces a periodic billiard trajectory on a given
// triangle.
// this is a reference implementation using completely "constructive" methods
// (meaning no explicit use of phase space): compute the coordinates of all
// boundary vertices, project them all orthogonally to the path offset, check
// whether the upper and lower boundaries have a positive separation.

public func SimpleCycleFeasibilityForTurns<k: Field & Comparable & Numeric>(
    _ turns: [Int], billiardsData billiards: BilliardsData<k>
) -> SimpleCycleFeasibilityResult<k>? {
  var edge = DiscPathEdge(
    billiards: billiards,
    coords: Singularities(s0: Vec2<k>.origin, s1: Vec2(k.one, k.zero)))

  var leftBoundaries: [Vec2<k>] = []
  var rightBoundaries: [Vec2<k>] = []

  for degree in turns {
    let turnSign = Sign.of(degree)!
    guard let newEdge = edge.reversed().turnedBy(degree, angleBound: .pi)
    else {
      // no feasible path can cover more than pi of a disc boundary
      return nil
    }
    edge = newEdge
    switch turnSign {
      case .positive:
      leftBoundaries.append(edge.fromCoords())
      case .negative:
      rightBoundaries.append(edge.fromCoords())
    }
    leftBoundaries.append(edge.apexForSide(.left))
    rightBoundaries.append(edge.apexForSide(.right))
  }
  let offset = edge.fromCoords()

  // the vector orthogonal to the offset. higher inner product with this
  // vector means further left relative to the offset trajectory.
  let offsetNorm = Vec2(-offset.y, offset.x)

  let leftHeights = leftBoundaries.map(offsetNorm.dot)
  let rightHeights = rightBoundaries.map(offsetNorm.dot)

  return SimpleCycleFeasibilityResult(
    margin: leftHeights.min()! - rightHeights.max()!,
    turns: turns, billiardsData: billiards)
}

public class SimpleCycleFeasibility {
  let turns: [Int]

  public init(turns: [Int]) {
    self.turns = turns
  }

  public func forData<k: Field & Comparable & Numeric>(_ billiards: BilliardsData<k>) -> Result<k>? {
    var edge = DiscPathEdge(
      billiards: billiards,
      coords: Singularities(s0: Vec2<k>.origin, s1: Vec2(k.one, k.zero)))

    var leftBoundaries: [Vec2<k>] = []
    var rightBoundaries: [Vec2<k>] = []

    for degree in turns {
      let turnSign = Sign.of(degree)!
      guard let newEdge = edge.reversed().turnedBy(degree, angleBound: .pi)
      else {
        // no feasible path can cover more than pi of a disc boundary
        return nil
      }
      edge = newEdge
      switch turnSign {
        case .positive:
        leftBoundaries.append(edge.fromCoords())
        case .negative:
        rightBoundaries.append(edge.fromCoords())
      }
      leftBoundaries.append(edge.apexForSide(.left))
      rightBoundaries.append(edge.apexForSide(.right))
    }
    let offset = edge.fromCoords()

    // the vector orthogonal to the offset. higher inner product with this
    // vector means further left relative to the offset trajectory.
    let offsetNorm = Vec2(-offset.y, offset.x)

    let leftHeights = leftBoundaries.map(offsetNorm.dot)
    let rightHeights = rightBoundaries.map(offsetNorm.dot)

    return Result(
      margin: leftHeights.min()! - rightHeights.max()!,
      turns: turns, data: billiards)
  }

  public class Result<k: Field & Comparable & Numeric> {
    private let turns: [Int]
    private let data: BilliardsData<k>
    public let margin: k

    public var feasible: Bool {
      return margin > k.zero
    }

    init(margin: k, turns: [Int], data: BilliardsData<k>) {
      self.margin = margin
      self.turns = turns
      self.data = data
    }

    public func color() -> CGColor {
      let expectedMargin = data.apexOverBase[.forward]!.y / k(turns.count)

      var hue: Vec3<Double>
      var ratio: k
      if margin > k.zero {
        hue = Vec3(0.0, 0.0, 0.5)
        ratio = margin / expectedMargin
      } else {
        hue = Vec3(0.4, 0.4, 0.0)
        ratio = -margin / expectedMargin
      }
      let r = ratio.asDouble()
      let saturation = min(r / (r + 15.0), 0.8)
      //let white = Vec3(0.85, 0.85, 0.85)
      let white = Vec3(1.0, 1.0, 1.0)
      let color = hue + saturation * (white - hue)
      return CGColor(
        red: CGFloat(color.x),
        green: CGFloat(color.y),
        blue: CGFloat(color.z),
        alpha: 0.6)
      //let saturation = 
      //return hue
    }
  }
}


public class CycleFeasibility {
  public class Result {
    // "cycle" feasibility means feasible for an explicit cyclic trajectory,
    // or equivalently, that any finite number of repetitions of the path
    // induces a nonempty feasible region.
    // this is as opposed to "path" feasibility which requires that _some_
    // feasible trajectory induces the given combinatorial path, but does
    // not require that it be parallel to the path offset. equivalently "path
    // feasibility" means the given path induces a nonempty feasible region.
    // unlike cycle feasibility, path feasibility is not invariant under
    // rotations (i.e. reorderings) of the same path.
    //
    // in this context, the results are further refined by 
    /*public let baseFeasible: Bool
    public let apexFeasible: Bool
    public let feasible: Bool*/
  }

  let path: [Int]

  init(path: [Int]) {
    self.path = path
  }

  func forData<k: Field & Comparable>(_ billiards: BilliardsData<k>) -> Bool {
    var edge = DiscPathEdge(
      billiards: billiards,
      coords: Singularities(s0: Vec2<k>.origin, s1: Vec2(k.one, k.zero)))

    var leftBoundaries: [Vec2<k>] = []
    var rightBoundaries: [Vec2<k>] = []

    for degree in path {
      let turnSign = Sign.of(degree)!
      guard let newEdge = edge.reversed().turnedBy(degree, angleBound: .pi)
      else {
        // no feasible path can cover more than pi of a disc boundary
        return false
      }
      edge = newEdge
      switch turnSign {
        case .positive:
        leftBoundaries.append(edge.fromCoords())
        case .negative:
        rightBoundaries.append(edge.fromCoords())
      }
      leftBoundaries.append(edge.apexForSide(.left))
      rightBoundaries.append(edge.apexForSide(.right))
    }
    let offset = edge.fromCoords()

    // the vector orthogonal to the offset. higher inner product with this
    // vector means further left relative to the offset trajectory.
    let offsetNorm = Vec2(-offset.y, offset.x)

    let leftHeights = leftBoundaries.map(offsetNorm.dot)
    let rightHeights = rightBoundaries.map(offsetNorm.dot)

    return leftHeights.min()! > rightHeights.max()!
  }
}

public class PathFeasibility {
  let path: [Int]

  init(path: [Int]) {
    self.path = path
  }

  func forApex<k: Field & Comparable>(_ apex: Vec2<k>) -> Result {
    let upperHalfSphere = SphericalPolygon<k>.fullSphere.withConstraint(
        Vec3(x: k.zero, y: k.one, z: k.zero))
    var apexRegion = upperHalfSphere//SphericalPolygon<k>.fullSphere
    var baseRegion = upperHalfSphere//SphericalPolygon<k>.fullSphere
    let billiards = BilliardsData(apex: apex)
    // in this case let's still start on the unit interval
    // (phase plots are nicer with a normalized vertical but that
    // doesn't affect the actual outcome of feasibility tests).
    var edge = DiscPathEdge(
      billiards: billiards,
      coords: Singularities(s0: Vec2<k>.origin, s1: Vec2(k.one, k.zero)))
    /*apexRegion = apexRegion.withConstraints([
      -Vec3(affineXY: edge.apexForSide(.left)),
      Vec3(affineXY: edge.apexForSide(.right))])
    let lastTurnSign = Sign.of(path.last!)!
    baseRegion = baseRegion.withConstraint(-lastTurnSign * Vec3(affineXY: edge.fromCoords()))*/
    for degree in path {
      let turnSign = Sign.of(degree)!
      guard let newEdge = edge.reversed().turnedBy(degree, angleBound: .twoPi)
      else { return Result.empty() }
      let baseConstraint = -turnSign * Vec3(affineXY: newEdge.fromCoords())
      let leftApexConstraint = -Vec3(affineXY: newEdge.apexForSide(.left))
      let rightApexConstraint = Vec3(affineXY: newEdge.apexForSide(.right))
      apexRegion = apexRegion.withConstraints([
        leftApexConstraint, rightApexConstraint
      ])
      baseRegion = baseRegion.withConstraint(baseConstraint)
      if apexRegion.isEmpty() && baseRegion.isEmpty() {
        return Result.empty()
      }
      edge = newEdge
    }
    let pathOffset = edge.toCoords()
    let intersectedRegion = apexRegion.intersect(baseRegion)
    return Result(
      apexFeasible: !apexRegion.isEmpty(),
      baseFeasible: !baseRegion.isEmpty(),
      feasible: !intersectedRegion.isEmpty(),
      apexFeasibleCycle: false, baseFeasibleCycle: false, feasibleCycle: false)
  }

  public class Result {
    // apexFeasible: the region induced by the apex constraints is nonempty
    // baseFeasible: the region induced by the base constraints is nonempty
    // feasible: the region induced by all constraints is nonempty
    // the third implies the first two, but not vice versa.
    public let apexFeasible: Bool
    public let baseFeasible: Bool
    public let feasible: Bool

    // a trajectory parallel to the path offset satisfies all apex constraints
    public let apexFeasibleCycle: Bool

    // a trajectory parallel to the path offset satisfies all base constraints
    public let baseFeasibleCycle: Bool

    // a trajectory parallel to the path offset satisfies all constraints
    // (this is the case that was simply called "feasibility" in earlier
    // constructions)
    public let feasibleCycle: Bool

    init(apexFeasible: Bool, baseFeasible: Bool, feasible: Bool,
        apexFeasibleCycle: Bool, baseFeasibleCycle: Bool, feasibleCycle: Bool) {
      self.apexFeasible = apexFeasible
      self.baseFeasible = baseFeasible
      self.feasible = feasible
      self.apexFeasibleCycle = apexFeasibleCycle
      self.baseFeasibleCycle = baseFeasibleCycle
      self.feasibleCycle = feasibleCycle
    }

    static func empty() -> Result {
      return Result(apexFeasible: false, baseFeasible: false, feasible: false,
          apexFeasibleCycle: false, baseFeasibleCycle: false, feasibleCycle: false)
    }
  }
}

class PathFilter {
  let path: [Int]

  init(path: [Int]) {
    self.path = path
  }

  func includePoint<k: Field & Comparable>(_ p: Vec2<k>) -> Bool {
    var feasibleRegion = SphericalPolygon<k>.fullSphere
    let billiards = BilliardsData(apex: p)
    // in this case let's still start on the unit interval
    // (phase plots are nicer with a normalized vertical but that
    // doesn't affect the actual outcome of feasibility tests).
    var edge = DiscPathEdge(
      billiards: billiards,
      coords: Singularities(s0: Vec2<k>.origin, s1: Vec2(k.one, k.zero)))
    feasibleRegion = feasibleRegion.withConstraints([
      -Vec3(affineXY: edge.apexForSide(.left)),
      Vec3(affineXY: edge.apexForSide(.right))])
    /*if path.first! * path.last! > 0 {
      // the path starts on a flip, so add that constraint first so we can
      // bail out early in more cases.
      feasibleRegion = feasibleRegion.withConstraint(
        Vec3(affineXY: edge.apexForSide(.left)))
    } else {

    }*/
    for degree in path {
      let turnSign = Sign.of(degree)!
      guard let newEdge = edge.reversed().turnedBy(degree, angleBound: .pi)
      else { return false }
      let centerConstraint = -turnSign * Vec3(affineXY: newEdge.fromCoords())
      let leftConstraint = -Vec3(affineXY: newEdge.apexForSide(.left))
      let rightConstraint = Vec3(affineXY: newEdge.apexForSide(.right))
      feasibleRegion = feasibleRegion.withConstraints([
        centerConstraint, leftConstraint, rightConstraint
      ])
      if feasibleRegion.isEmpty() {
        return false
      }
      edge = newEdge
    }
    //SphericalPolygon
    /*let phaseMap = DoubleDiscPhaseMap(apexOverBase: p)
    let rootPolygon = SphericalPolygon<k>.fullSphere
    var curPolygon = rootPolygon
    var s = Singularity.S1
    for degree in path {
      let turn = s.turnBy(degree)
      guard let region: DoubleDiscPhaseMap<k>.Region = phaseMap.regions[turn]
      else { return false }
      let newPolygon = curPolygon.intersect(region.polygon)//regions[i].polygon)
      if newPolygon.isEmpty() {
        return false
      }
      curPolygon = region.transform * newPolygon
      s = s.next()
    }*/

    /*if p.x > k(1, over: 3) {
      return true
    }*/
    return true
  }
}

