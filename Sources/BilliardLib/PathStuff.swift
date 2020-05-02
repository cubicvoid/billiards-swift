public class CycleSearch {
  public let config: Config
  public var results: [Result]? = nil

  public init(config: Config) {
    self.config = config
  }

  public class Config {
    // Any paths found will be written to the PathSet of the
    // same name, and the one-many mapping from the point set
    // to its path set is saved as point-path/[name].json
    // as an array of tuples
    // (pointIndex: Point)
    public let pointSetName: String
    
    // How many trajectories to attempt.
    public var attemptCount: Int = 300

    public var stopAfterSuccess: Bool = true

    public init(pointSetName: String) {
      self.pointSetName = pointSetName
    }
  }  

  public class Result {

  }

}

// TurnPath represents a homotopy class from S0 -> S0 as an even-length
// sequence of signed turns around the singularities, beginning with S1 and
// alternating each step.
public class TurnPath {
  public let turns: [Int]
  public let canonical: Bool = false

  public enum PathError: Error {
    case oddPathLength
  }

  public init(turns: [Int]) throws {
    if turns.count % 2 != 0 {
      throw PathError.oddPathLength
    }
    self.turns = turns
  }

  // canonical paths:
  // - start with a flip from S0 into S1 (which, by the next constraint, means the
  //   path begins and ends with a negative value)
  // - start with a negative (clockwise) turn around S1 (always possible bc we can
  //   negate all turn signs for any path to get an equivalent one (albeit
  //   also corresponding to a negated trajectory), but this means
  //   that our canonicalization function needs to account for both possible signs
  //   when establishing other invariants)
  // - starts with a turn of maximum magnitude (given the preceding constraints)
  // - is otherwise chosen to minimize lexical ordering on the turn sequence
  public func canonicalized() -> TurnPath {
    return self
  }
}

public class PathSet {
  private var _nextID: Int = 0
  private var _root: TreeNode

  // Initializes an empty PathSet
  public init() {
    _root = TreeNode()
  }

  public func copy() -> PathSet {
    print("copy() isn't written yet")
    return self
  }

  public func add(_ path: TurnPath) {
    
  }

  class TreeNode {
    // nil if this path set doesn't contain the path ending at this
    // node, otherwise a unique integer identifying this path. Path
    // IDs are stable under insertion, i.e. a single ID will never
    // change once it is chosen.
    var pathID: Int? = nil
    var children: [Child] = []

    class Child {
      let turnPrefix: [Int]
      let node: TreeNode

      init(turnPrefix: [Int], node: TreeNode) {
        self.turnPrefix = turnPrefix
        self.node = node
      }
    }
  }
}