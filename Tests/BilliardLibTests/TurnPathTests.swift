import XCTest

import BilliardLib

/*struct TurnPathComparisonTestCase {
	let first: TurnPath
	let second: TurnPath
	let expectedResult: Comparison
}*/

class TurnPathTests: XCTestCase {
	func testPaths() {
		let a: TurnPath = TurnPath.g[.B0]
		let b: TurnPath = TurnPath.g[.B1]
		XCTAssertEqual(a * (a ** -1), TurnPath.empty)
		XCTAssertEqual(a * a * a, a ** 3)
		XCTAssertEqual((a * b).inverse(), (b ** -1) * (a ** -1))
		XCTAssertEqual((a * b) * (b * a), a * (b ** 2) * a)
		
		let p = a**5 * b**3 * a**4 * b**4
		XCTAssertEqual(p.rotatedLeftBy(1), b**3 * a**4 * b**4 * a**5)
		XCTAssertEqual(p.rotatedLeftBy(2), a**4 * b**4 * a**5 * b**3)
	}
	/*func testComparison() {
		let tests = [
			// [10] is shorter than [1, 1]
			TurnPathComparisonTestCase(
				first: TurnPath(
					initialOrientation: .backward,
					turns: [10]),
				second: TurnPath(
					initialOrientation: .forward,
					turns: [1, 1]),
				expectedResult: .less
			),
			// [2, 3] has a higher total turn count than [3, 1]
			TurnPathComparisonTestCase(
				first: TurnPath(
					initialOrientation: .forward,
					turns: [2, 3]),
				second: TurnPath(
					initialOrientation: .forward,
					turns: [3, 1]),
				expectedResult: .greater
			),
			// [1, 2] has lower lex order than [2, 1]
			TurnPathComparisonTestCase(
				first: TurnPath(
					initialOrientation: .forward,
					turns: [2, 1]),
				second: TurnPath(
					initialOrientation: .forward,
					turns: [1, 2]),
				expectedResult: .greater
			),
			// forward orientation precedes backward
			TurnPathComparisonTestCase(
				first: TurnPath(
					initialOrientation: .backward,
					turns: [1, 2, 3]),
				second: TurnPath(
					initialOrientation: .forward,
					turns: [1, 2, 3]),
				expectedResult: .greater
			),
			TurnPathComparisonTestCase(
				first: TurnPath(
					initialOrientation: .forward,
					turns: [1, 2, 3]),
				second: TurnPath(
					initialOrientation: .forward,
					turns: [1, 2, 3]),
				expectedResult: .equal
			),
		]

		for testCase in tests {
			XCTAssertEqual(
				testCase.first.compareTo(testCase.second),
				testCase.expectedResult,
				"expected comparison of \(testCase.first) and " +
				"\(testCase.second) to be \(testCase.expectedResult)")
		}
	}*/
}
