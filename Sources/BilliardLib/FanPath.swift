
public final class FanPath: Codable {
  // turns must have even length. Entry 0 is a fan around singularity index
  // 1 (the default initial state for a FanPathEdge).
  public var turns: [Int]

  init(turns: [Int]) {
    self.turns = turns
  }

  public var length: Int {
    get {
      return turns.count
    }
  }

  subscript(index: Int) -> Int {
    get {
      return turns[index]
    }
  }

  public func asString() -> String {
    let strings = turns.map {"\($0)"}
    return strings.joined(separator: " ")
  }
}
