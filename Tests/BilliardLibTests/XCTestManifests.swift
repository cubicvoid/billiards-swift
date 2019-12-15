import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(SphericalPolygonTests.allTests),
        testCase(BilliardsDataTests.allTests)
    ]
}
#endif
