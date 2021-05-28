import XCTest

import BilliardLib

/*struct InitTestCase {
	let turnPath: TurnPath
	let expectedSegments: [TurnCycle.Segment]
	let expectedError: TurnCycle.CycleError? = nil
}*/

class TurnCycleTests: XCTestCase {
	func testCycles() {
		let b0 = TurnPath.g[.B0]
		let b1 = TurnPath.g[.B1]
		let p0 = b0**2 * b1**(-2) * b0**(-2) * b1**2
		print(p0)
		//XCTAssertTrue(OuterConjugateLength(p0) == 0)
		let p1 = b1**(-1) * b0**2 * b1**(-2) * b0**(-2) * b1**3
		
		//let (c0,_) = CycleForPath(p0)
		let c0 = TurnCycle(repeatingPath: p0)
		print(c0.anyPath())
		//let (c1,_) = CycleForPath(p1)
		let c1 = TurnCycle(repeatingPath: p1)
		XCTAssertEqual(c0.anyPath(), c1.anyPath())
	}
	
	func testInit() {
		/*let tests = [
			InitTestCase(
				turnPath: TurnPath(
					initialOrientation: .forward,
					turns: [-6, 4, 6, -4]),
				expectedSegments: [
					TurnCycle.Segment(
						initialOrientation: .forward,
						turnDegrees: [6, 4]
					),
					TurnCycle.Segment(
						initialOrientation: .forward,
						turnDegrees: [6, 4]
					),
				]
			)
		]
		for test in tests {
			let cycle = try! TurnCycle(repeatingPath: test.turnPath)
			XCTAssertEqual(
				cycle.segments,
				test.expectedSegments,
				"Wrong segment list when repeating turn path \(test.turnPath)")

		}
		*/
	}
	/*func testAngleBound() {
		let testCases = [
			CanonicalizationTestCase(
				input: [-2, 2, 2, -2],
				expected: [-2, 2, 2, -2]),
			CanonicalizationTestCase(
				input: [2, -2, -2, 2],
				expected: [-2, 2, 2, -2]),
			CanonicalizationTestCase(
				input: [-10, 1, -5, -3],
				expected: [-5, -3, -10, 1]),
			CanonicalizationTestCase(
				input: [-5, 1, -5, 2],
				expected: [-5, 1, -5, 2]),
		]
		for testCase in testCases {
			let turnCycle = try! TurnCycle(turns: testCase.input)
			let canonical = turnCycle.canonicalized()
			XCTAssertEqual(canonical.turns, testCase.expected)
		}
	}*/


}
