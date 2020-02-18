//
//  PhaseMapTests.swift
//  BilliardLibTests
//
//  Created by Fae on 9/18/19.
//

import XCTest

import BilliardLib

class PhaseMapTests: XCTestCase {

  func testDiscModel() {
    /*let apex = Vec2(x: k(1, over: 2), y: k(1, over: 2))
    let phaseMap = DoubleDiscPhaseMap(apexOverBase: apex)
    XCTAssertEqual(
      phaseMap.regions.count, 8,
      "Apex at (1/2, 1/2) should have 8 phase regions in DoubleDiscPhaseMap")
    if let r = phaseMap.regions[Singularity.Turn(around: .S1, by: 1)] {
      let billiards = BilliardsData(apex: apex)
      let baseEdge = DiscPathEdge(
        billiards: billiards, coords: phaseMap.base,
        orientation: Singularity.Orientation.to(.S1),
        rotationCounts: Singularities(s0: 0, s1: 0))
      let turnedEdge = baseEdge.reversed().turnedBy(1)
      let right = turnedEdge.apexForSide(.right)
      let left = turnedEdge.apexForSide(.left)
      let expectedPolygon = SphericalPolygon<k>.fromConstraints([
            Vec3(k(1, over: 2), -k(1, over: 2), k.one),
            Vec3(-k(3, over: 2), k(1, over: 2), -k.one),
            //Vec3(-k.one, k.zero, -k.one),
            Vec3(-k(1, over: 2), -k(1, over: 2), -k.one),
          ])
      
      /*XCTAssertNotEqual(r.polygon, SphericalPolygon<k>.empty)*/
      XCTAssertEqual(r.polygon, expectedPolygon)
    } else {
      XCTFail("Region for turn around S1 by 1 shouldn't be empty")
    }*/
  }
  
  
  
}
