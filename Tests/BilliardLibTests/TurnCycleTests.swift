import XCTest

import BilliardLib

struct CanonicalizationTestCase {
	let input: [Int]
	let expected: [Int]
}

class TurnCycleTests: XCTestCase {
	func testAngleBound() {
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
	}


}