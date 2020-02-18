//
//  DiscPathEdgeTests.swift
//  BilliardLibTests
//
//  Created by Fae on 9/20/19.
//

import XCTest

import BilliardLib

class DiscPathEdgeTests: XCTestCase {
  
  func testApexForSide() {
    let apex = Vec2(x: k(1, over: 2), y: k(1, over: 2))
    let billiards = BilliardsData(apex: apex)
    let base = Singularities(Vec2.origin, Vec2(x: k.one, y: k.zero))
    let edge0 = DiscPathEdge(
      billiards: billiards, coords: base,
      orientation: Singularity.Orientation.to(.S1),
      rotationCounts: Singularities(s0: 0, s1: 0))
    XCTAssertEqual(edge0.fromCoords(), Vec2.origin)
    XCTAssertEqual(edge0.toCoords(), Vec2(x: k.one, y: k.zero))
    XCTAssertEqual(edge0.apexForSide(.left), Vec2(x: k(1, over: 2), y: k(1, over: 2)))
    XCTAssertEqual(edge0.apexForSide(.right), Vec2(x: k(1, over: 2), y: k(-1, over: 2)))
    
    let reversed0 = edge0.reversed()
    XCTAssertEqual(reversed0.fromCoords(), Vec2(x: k.one, y: k.zero))
    XCTAssertEqual(reversed0.toCoords(), Vec2.origin)
    XCTAssertEqual(reversed0.apexForSide(.left), Vec2(x: k(1, over: 2), y: k(-1, over: 2)))
    XCTAssertEqual(reversed0.apexForSide(.right), Vec2(x: k(1, over: 2), y: k(1, over: 2)))

    let ortho0 = edge0.reversed().turnedBy(-1, angleBound: .pi)!
    XCTAssertEqual(ortho0.fromCoords(), Vec2(x: k.one, y: k.zero))
    XCTAssertEqual(ortho0.toCoords(), Vec2(x: k.one, y: k.one))
    XCTAssertEqual(ortho0.apexForSide(.left), Vec2(x: k(1, over: 2), y: k(1, over: 2)))
    XCTAssertEqual(ortho0.apexForSide(.right), Vec2(x: k(3, over: 2), y: k(1, over: 2)))

    let edge1 = edge0.reversed().turnedBy(-2, angleBound: .pi)!
    XCTAssertEqual(edge1.fromCoords(), Vec2(x: k.one, y: k.zero))
    XCTAssertEqual(edge1.toCoords(), Vec2(x: k(2), y: k.zero))
    XCTAssertEqual(edge1.apexForSide(.left), Vec2(x: k(3, over: 2), y: k(1, over: 2)))
    XCTAssertEqual(edge1.apexForSide(.right), Vec2(x: k(3, over: 2), y: k(-1, over: 2)))

    let edge2 = edge1.reversed().turnedBy(2, angleBound: .pi)!
    XCTAssertEqual(edge2.fromCoords(), Vec2(x: k(2), y: k.zero))
    XCTAssertEqual(edge2.toCoords(), Vec2(x: k(3), y: k.zero))
    XCTAssertEqual(edge2.apexForSide(.left), Vec2(x: k(5, over: 2), y: k(1, over: 2)))
    XCTAssertEqual(edge2.apexForSide(.right), Vec2(x: k(5, over: 2), y: k(-1, over: 2)))
  }
}
