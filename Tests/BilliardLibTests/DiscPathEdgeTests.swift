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
    let baseEdge = DiscPathEdge(
      billiards: billiards, coords: base,
      orientation: Singularity.Orientation.to(.S1),
      rotationCounts: Singularities(s0: 0, s1: 0))
    let turnedEdge = baseEdge.reversed().turnedBy(1)
    let right = turnedEdge.apexForSide(.right)
    let left = turnedEdge.apexForSide(.left)
    XCTAssertEqual(right, Vec2(x: k(1, over: 2), y: -k(1, over: 2)))
    XCTAssertEqual(left, Vec2(x: k(3, over: 2), y: -k(1, over: 2)))
  }
}
