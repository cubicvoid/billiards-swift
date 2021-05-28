//
//  DiscPathEdgeTests.swift
//  BilliardLibTests
//
//  Created by Fae on 9/20/19.
//

import XCTest

import BilliardLib

class KiteEmbeddingTests: XCTestCase {
  
  func testApexCoordsForSide() {
    let apexCoords = Vec2(x: k(1, over: 2), y: k(1, over: 2))
    let context = BilliardsContext(apex: apexCoords)
		
		let kite0 = KiteEmbedding(context: context)
		XCTAssertEqual(kite0[Singularity.B0], Vec2(-k.one, k.zero))
		XCTAssertEqual(kite0[Singularity.B1], Vec2(k.one, k.zero))
		XCTAssertEqual(kite0[Singularity.A0], Vec2(k.zero, k.one))
		XCTAssertEqual(kite0[Singularity.A1], Vec2(k.zero, -k.one))

		let kite1 = kite0 * TurnPath.g[.B1]**(-1)
		XCTAssertEqual(kite1[Singularity.B0], Vec2(k.one, k(2)))
		XCTAssertEqual(kite1[Singularity.B1], Vec2(k.one, k.zero))
		XCTAssertEqual(kite1[Singularity.A0], Vec2(k(2), k.one))
		XCTAssertEqual(kite1[Singularity.A1], Vec2(k.zero, k.one))

		let kite2 = kite0 * TurnPath.g[.B1]**(-2)
		XCTAssertEqual(kite2[Singularity.B0], Vec2(k(3), k.zero))
		XCTAssertEqual(kite2[Singularity.B1], Vec2(k.one, k.zero))
		XCTAssertEqual(kite2[Singularity.A0], Vec2(k(2), -k.one))
		XCTAssertEqual(kite2[Singularity.A1], Vec2(k(2), k.one))

		
		let kite3 = kite2 * TurnPath.g[.B0]**2
		XCTAssertEqual(kite3[Singularity.B0], Vec2(k(3), k.zero))
		XCTAssertEqual(kite3[Singularity.B1], Vec2(k(5), k.zero))
		XCTAssertEqual(kite3[Singularity.A0], Vec2(k(4), k.one))
		XCTAssertEqual(kite3[Singularity.A1], Vec2(k(4), -k.one))
  }

  func testNextTurnForTrajectory() {
    let apexCoords = Vec2(x: k(1, over: 2), y: k(1, over: 2))
    let context = BilliardsContext(apex: apexCoords)
		let kite0 = KiteEmbedding(context: context)
    
    let t0 = Vec3(k.zero, k.one, k(-1, over: 2))
    let t1 = Vec3(k.zero, k.one, k(1, over: 2))

    XCTAssertEqual(
			kite0.nextTurnForTrajectory(t0),
			TurnPath.Turn(degree: -2, singularity: .B1))
    XCTAssertEqual(
			kite0.nextTurnForTrajectory(t1),
			TurnPath.Turn(degree: 2, singularity: .B1))
		
		let kite1 = kite0 * kite0.nextTurnForTrajectory(t0)!
		XCTAssertEqual(
			kite1.nextTurnForTrajectory(t0),
			TurnPath.Turn(degree: -2, singularity: .B0))
		XCTAssertEqual(
			kite1.nextTurnForTrajectory(t1),
			TurnPath.Turn(degree: 2, singularity: .B0))
  }
}
