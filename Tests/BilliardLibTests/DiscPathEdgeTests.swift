//
//  DiscPathEdgeTests.swift
//  BilliardLibTests
//
//  Created by Fae on 9/20/19.
//

import XCTest

import BilliardLib

class DiscPathEdgeTests: XCTestCase {
  
  func testApexCoordsForSide() {
    let apexCoords = Vec2(x: k(1, over: 2), y: k(1, over: 2))
    let apex = BilliardsContext(apex: apexCoords)
    let base = S2(Vec2.origin, Vec2(x: k.one, y: k.zero))
    let edge0 = DiscPathEdge(
      context: apex, coords: base,
      orientation: Singularity.Orientation.to(.S1),
      rotationCounts: S2(s0: 0, s1: 0))
    XCTAssertEqual(edge0.fromCoords(), Vec2.origin)
    XCTAssertEqual(edge0.toCoords(), Vec2(x: k.one, y: k.zero))
    XCTAssertEqual(edge0.apexCoordsForSide(.left), Vec2(x: k(1, over: 2), y: k(1, over: 2)))
    XCTAssertEqual(edge0.apexCoordsForSide(.right), Vec2(x: k(1, over: 2), y: k(-1, over: 2)))
    
    let reversed0 = edge0.reversed()
    XCTAssertEqual(reversed0.fromCoords(), Vec2(x: k.one, y: k.zero))
    XCTAssertEqual(reversed0.toCoords(), Vec2.origin)
    XCTAssertEqual(reversed0.apexCoordsForSide(.left), Vec2(x: k(1, over: 2), y: k(-1, over: 2)))
    XCTAssertEqual(reversed0.apexCoordsForSide(.right), Vec2(x: k(1, over: 2), y: k(1, over: 2)))

    let ortho0 = edge0.reversed().turnedBy(-1, angleBound: .pi)!
    XCTAssertEqual(ortho0.fromCoords(), Vec2(x: k.one, y: k.zero))
    XCTAssertEqual(ortho0.toCoords(), Vec2(x: k.one, y: k.one))
    XCTAssertEqual(ortho0.apexCoordsForSide(.left), Vec2(x: k(1, over: 2), y: k(1, over: 2)))
    XCTAssertEqual(ortho0.apexCoordsForSide(.right), Vec2(x: k(3, over: 2), y: k(1, over: 2)))

    let edge1 = edge0.reversed().turnedBy(-2, angleBound: .pi)!
    XCTAssertEqual(edge1.fromCoords(), Vec2(x: k.one, y: k.zero))
    XCTAssertEqual(edge1.toCoords(), Vec2(x: k(2), y: k.zero))
    XCTAssertEqual(edge1.apexCoordsForSide(.left), Vec2(x: k(3, over: 2), y: k(1, over: 2)))
    XCTAssertEqual(edge1.apexCoordsForSide(.right), Vec2(x: k(3, over: 2), y: k(-1, over: 2)))

    let edge2 = edge1.reversed().turnedBy(2, angleBound: .pi)!
    XCTAssertEqual(edge2.fromCoords(), Vec2(x: k(2), y: k.zero))
    XCTAssertEqual(edge2.toCoords(), Vec2(x: k(3), y: k.zero))
    XCTAssertEqual(edge2.apexCoordsForSide(.left), Vec2(x: k(5, over: 2), y: k(1, over: 2)))
    XCTAssertEqual(edge2.apexCoordsForSide(.right), Vec2(x: k(5, over: 2), y: k(-1, over: 2)))
  }

  func testNextTurnForTrajectory() {
    let apexCoords = Vec2(x: k(1, over: 2), y: k(1, over: 2))
    let apex = BilliardsContext(apex: apexCoords)
    let base = S2(Vec2.origin, Vec2(x: k.one, y: k.zero))
    let edge0 = DiscPathEdge(
      context: apex, coords: base,
      orientation: Singularity.Orientation.to(.S1),
      rotationCounts: S2(s0: 0, s1: 0))
    
    let t0 = Vec3(k.zero, k.one, k(-1, over: 4))
    let t1 = Vec3(k.zero, k.one, k(1, over: 4))

    XCTAssertEqual(edge0.nextTurnForTrajectory(t0), -2)
    XCTAssertEqual(edge0.nextTurnForTrajectory(t1), 2)

    let t2 = Vec3(-k.one, k.one, k(1, over: 2)) // up and right
    let t3 = Vec3(k.one, k.one, k(-1, over: 2)) // down and right
    XCTAssertEqual(edge0.nextTurnForTrajectory(t2), -1)
    XCTAssertEqual(edge0.nextTurnForTrajectory(t3), 1)
  }
}
