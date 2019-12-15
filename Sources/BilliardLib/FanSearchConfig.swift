import Foundation

public class FanSearchConfig: Codable {
  // The minimum radius in which a cycle must work to be considered valid.
  public var minRadius: GmpRational = GmpRational(0)

  // The maximum number of fan steps to attempt when looking for a cycle.
  public var maxFanCount: Int = 50

  // The maximum number of sign flips (monotonic segments) to attempt during
  // a fan path search.
  public var maxFlipCount: Int = 4

  // Whether to skip exact-computation verification. Setting to true
  // dramatically improves performance, but can result in false positives.
  // Empirically, false positives appear to be very rare, so this is useful for
  // quickly collecting a lot of sample paths for further testing.
  public var unsafeMath: Bool = false

  public init() { }
}

public class FanCycle: Codable {
  public let path: FanPath
  public let radius: GmpRational

  public init(path: FanPath, radius: GmpRational) {
    self.path = path
    self.radius = radius
  }
}

// The same as Cycle, but generated using floating point math (and therefore
// susceptible to false positives), so we make it a separate type to avoid
// possible ambiguity.
public class FanCycleApprox: Codable {
  public let path: FanPath
  public let radius: Double

  public init(path: FanPath, radius: Double) {
    self.path = path
    self.radius = radius
  }
}

public class FanSearchResult: Codable {
  public let apex: Vec2<GmpRational>
  public let searchTime: CFTimeInterval
  public let cycle: FanCycle?

  public init(apex: Vec2<GmpRational>, searchTime: CFTimeInterval,
      cycle: FanCycle?) {
    self.apex = apex
    self.searchTime = searchTime
    self.cycle = cycle
  }
}

public class FanSearchResultApprox: Codable {
  public let apex: Vec2<GmpRational>
  public let searchTime: CFTimeInterval
  public let cycle: FanCycleApprox?

  public init(apex: Vec2<GmpRational>, searchTime: CFTimeInterval,
      cycle: FanCycleApprox?) {
    self.apex = apex
    self.searchTime = searchTime
    self.cycle = cycle
  }
}
