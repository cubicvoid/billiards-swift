import XCTest

@testable import BilliardLib

typealias k = GmpRational

final class SphericalPolygonTests: XCTestCase {
  func testOppositeLines() {
    let v0 = Vec3(
        x: -k(71, over: 150),
        y: -k(37, over: 300),
        z: k.one)
    let v1 = Vec3(
      x: -k(79, over: 150),
      y: k(37, over: 300),
      z: -k.one)

    let empty2 =
        SphericalPolygon<k>.fullSphere.withConstraints([v0, -v0])
    XCTAssert(empty2.isEmpty(), "Expected empty polygon, got \(empty2)")

    let empty3 =
        SphericalPolygon<k>.fullSphere.withConstraints([v0, v1, -v0])
    XCTAssert(empty3.isEmpty(), "Expected empty polygon, got \(empty3)")
  }

  func testFullyConstrained() {
    let constraints: [Vec3<k>] = [
        Vec3(-k.one, k.one, k.zero),
        Vec3(k.one, k.one, k.zero),
        Vec3(k.zero, -k.one, -k.one),
        Vec3(k.zero, -k.one, k.zero)]
    let polygon =
        SphericalPolygon<k>.fullSphere.withConstraints(Array(constraints[..<3]))
    XCTAssert(!polygon.isEmpty(),
        "Constraints \(constraints[..<3]) should not be empty")
    XCTAssert(polygon.withConstraint(constraints[3]).isEmpty(),
        "Constraints \(constraints) should be empty")
  }
  
  func testMergeConstraint() {
    let v0 = Vec3(
      x: -k(71, over: 150),
      y: -k(37, over: 300),
      z: k.one)
    let constraints = [v0]
    let polygon = mergeConstraint(v0, withList: constraints)
    XCTAssert(polygon == nil,
              "Merging a constraint with itself shouldn't change anything")
  }

  func testRedundantConstraints() {
    let v0 = Vec3(
        x: -k(71, over: 150),
        y: -k(37, over: 300),
        z: k.one)
    let oneConstraint = SphericalPolygon<k>.fullSphere.withConstraints([v0])
    let redundantConstraint = oneConstraint.withConstraints([v0])
    XCTAssertEqual(oneConstraint, redundantConstraint)

    // the middle constraint is redundant
    let constraints: [Vec3<k>] = [
        Vec3(-k.one, k.one, k.zero),
        Vec3(k.zero, k.one, k.zero),
        Vec3(k.one, k.one, k.zero)]
    let polygon =
        SphericalPolygon<k>.fullSphere.withConstraints(constraints)
    let mergedConstraints = polygon.constraints
    XCTAssert(mergedConstraints.count == 2,
        "Expected 2 constraints, got \(mergedConstraints.count)")

    XCTAssert(mergedConstraints.contains(constraints[0]),
        "Missing expected constraint \(constraints[0])")
    XCTAssert(mergedConstraints.contains(constraints[2]),
        "Missing expected constraint \(constraints[2])")
  }
  
  func testEquality() {
    let constraints: [Vec3<k>] = [
      Vec3(k.zero, k.zero, k.one),
      Vec3(k.zero, -k.one, -k.one),
      Vec3(-k.one, k.zero, k.one),
      Vec3(k.one, k.zero, k.one)
    ]
    
    let polygon = SphericalPolygon.fromConstraints(constraints)
    for offset in 1...3 {
      let rotatedPolygon = SphericalPolygon.fromConstraints(
          Array(constraints[0..<offset] + constraints[offset...]))
      XCTAssertEqual(polygon, rotatedPolygon)
    }
  }

  static var allTests = [
      ("testOppositeLines", testOppositeLines),
      ("testFullyConstrained", testFullyConstrained),
      ("testRedundantConstraints", testRedundantConstraints),
      ("testEquality", testEquality)
  ]
}
