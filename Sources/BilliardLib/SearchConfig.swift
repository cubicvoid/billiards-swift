import Foundation

public class SearchConfig: Codable {
  // The minimum radius in which a cycle must work to be considered valid.
  public var minRadius: GmpRational = GmpRational(0)

  ///////////////////////
  // TangentCycleSearch
  // How many tangent paths to attempt.
  public var attemptCount: Int = 300

  //////////////////////////
  // TangentSearchForCycle
  public var knownPathsFilename: String?

  public enum TangentPickerType: String, Codable {
    case edgeInterpolation
    case nearApproach
  }
  // Which tangent picker to use
  public var tangentPickerType: TangentPickerType? = .edgeInterpolation

  public enum TangentCheckerType: String, Codable {
    case exact
    case floatFilter
    case bandFilter
  }
  // Which tangent checker to use
  public var tangentCheckerType: TangentCheckerType? = .exact

  ////////////////////////////////////
  // EdgeInterpolationTangentPicker
  // The number of slices to split the base edge into.
  public var baseEdgeGranularity: Int = 61
  // The number of slices to split the apex edge into.
  public var apexEdgeGranularity: Int = 59

  ////////////////////////////////////
  // NearApproachTangentPicker
  // The number of slices to split the angle range into
  public var angleGranularity: Int = 10000000
  // The number of distinct distances to choose from when placing the tangent
  // relative to vertex 1. (Unlike many parameters, the distance is not
  // divided into linear slices, but more heavily weights distances nearer
  // the vertex.)
  public var distanceGranularity: Int = 10000000

  //////////////////////////
  // TangentChecker (all)
  // The maximum number of bounces to attempt when looking for a cycle.
  public var maxPathLength: Int = 150
  public var pathLengthIncrement: Int = 0

  ///////////////////////////////
  // FloatFilterTangentChecker
  // Whether to skip exact-computation verification. Setting to true
  // dramatically improves performance, but can result in false positives.
  // Empirically, false positives appear to be very rare, so this is useful for
  // quickly collecting a lot of sample paths for further testing.
  public var unsafeMath: Bool = false

  ///////////////////////////////
  // BandFilterTangentChecker
  public var bandFocus: UInt = 100

  public init() { }
}

public class Cycle: Codable {
  public let path: EdgePath
  public let radius: GmpRational

  public init(path: EdgePath, radius: GmpRational) {
    self.path = path
    self.radius = radius
  }
}

// The same as Cycle, but generated using floating point math (and therefore
// susceptible to false positives), so we make it a separate type to avoid
// possible ambiguity.
public class CycleApprox: Codable {
  public let path: EdgePath
  public let radius: Double

  public init(path: EdgePath, radius: Double) {
    self.path = path
    self.radius = radius
  }
}

public class SearchResult: Codable {
  public let apex: Vec2<GmpRational>
  public let searchTime: CFTimeInterval
  public let cycle: Cycle?

  public init(apex: Vec2<GmpRational>, searchTime: CFTimeInterval,
       cycle: Cycle?) {
    self.apex = apex
    self.searchTime = searchTime
    self.cycle = cycle
  }
}

public class SearchResultApprox: Codable {
  public let apex: Vec2<GmpRational>
  public let searchTime: CFTimeInterval
  public let cycle: CycleApprox?

  public init(apex: Vec2<GmpRational>, searchTime: CFTimeInterval,
      cycle: CycleApprox?) {
    self.apex = apex
    self.searchTime = searchTime
    self.cycle = cycle
  }
}
