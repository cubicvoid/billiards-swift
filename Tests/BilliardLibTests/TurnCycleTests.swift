import XCTest

import BilliardLib

struct InitTestCase {
	let turnPath: TurnPath
	let expectedSegments: [TurnPath]
	let expectedError: TurnCycle.CycleError? = nil
}

class TurnCycleTests: XCTestCase {
	func testInit() {
		let tests = [
			InitTestCase(
				turnPath: TurnPath(
					initialOrientation: .forward,
					turns: [-6, 4, 6, -4]),
				expectedSegments: [
					TurnPath(
						initialOrientation: .forward,
						turns: [6, 4]
					),
					TurnPath(
						initialOrientation: .forward,
						turns: [6, 4]
					),
				]
			)
		]
		for test in tests {
			let cycle = try! TurnCycle(repeatingPath: test.turnPath)
			XCTAssertEqual(
				cycle.monotonicSegments,
				test.expectedSegments,
				"Wrong segment list when repeating turn path \(test.turnPath)")

		}

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