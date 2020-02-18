import Foundation

import BilliardLib

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

