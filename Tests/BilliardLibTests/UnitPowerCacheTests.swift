import XCTest

import BilliardLib

class UnitPowerCacheTests: XCTestCase {
  func testAngleBound() {
    let apex = Vec2(x: k(1, over: 2), y: k(1, over: 2))
    let cache = UnitPowerCache(fromSquareRoot: apex)

    XCTAssert(cache.power(1, matchesAngleBound: .pi))
    XCTAssert(cache.power(2, matchesAngleBound: .pi))
    XCTAssert(cache.power(3, matchesAngleBound: .pi))

    XCTAssertEqual(cache.pow(0, angleBound: .pi), Vec2(x: k.one, y: k.zero))
    XCTAssertEqual(cache.pow(1, angleBound: .pi), Vec2(x: k.zero, y: k.one))
    XCTAssertEqual(cache.pow(2, angleBound: .pi), Vec2(x: -k.one, y: k.zero))
    XCTAssertEqual(cache.pow(3, angleBound: .pi), nil)
  }


}