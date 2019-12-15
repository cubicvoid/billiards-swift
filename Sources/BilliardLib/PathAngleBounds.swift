import Foundation


public func PathIsAbstractCycle(_ path : EdgePath) -> Bool {
  var edgeIndex = 0
  var reflect = 1
  var counts = [0, 0, 0]
  for i in 0..<path.length {
    let nextEdge =  Mod3(edgeIndex + path[i].sign() * reflect)
    let vertexIndex = Mod3(edgeIndex + (1 + path[i].sign() * reflect) / 2)
    counts[vertexIndex] += path[i].sign()

    edgeIndex = nextEdge
    reflect = -reflect
  }
  return (counts == [0, 0, 0])
}

public class BoundaryPoint<k: Field & Comparable> {
  let _coords: Vec2<k>
  var _prev: BoundaryPoint?

  init(coords: Vec2<k>, prev: BoundaryPoint? = nil) {
    _coords = coords
    _prev = prev
  }
}

// Positive for left, negative for right
public func TurnSign<k>(
    _ c1: Vec2<k>, _ c2: Vec2<k>, _ c3: Vec2<k>) -> k {
  //let v1 = c2.asOffsetFrom(c1)
  //let v2 = c3.asOffsetFrom(c1)
  //return v1.cross().dot(v2)
  let dx1: k = c2.x - c1.x
  let dy1: k = c2.y - c1.y
  let dx2: k = c3.x - c1.x
  let dy2: k = c3.y - c1.y
  return dy2 * dx1 - dy1 * dx2
  //return (c3.x - c1.x) * (c1.y - c2.y) + (c3.y - c1.y) * (c2.x - c1.x)
}

public class PathAngleNode<k: Field & Comparable> {
  let _bounds: PathAngleBounds<k>
  let _parent: PathAngleNode<k>?
  let _direction: EdgePathDirection?
  let _vertexCounts: [Int]
  var _leftBase: BoundaryPoint<k>
  var _rightBase: BoundaryPoint<k>
  let _apex: Vec2<k>

  //var _leftBoundary: 𝝙Vec2<R>
  //var _rightBoundary: 𝝙Vec2<R>
  //var _curVector: 𝝙Vec2<R>
  var _edgeIndex: Int
  var _depth: Int

  // Pruning constraints:
  // Any rotation of a valid path that takes its first step from the base
  // edge is also a valid path. To reduce search space, require paths are
  // lexicographically minimized, i.e. we choose the copy of the base edge
  // that has the most "left"s after it. This means if any child node starts
  // at the base edge, it cannot go further left than its own path from the
  // root.
  // This is ugly and complicated though because "left" and "right" flip
  // every step, so visits of the 0 edge on odd steps flip things... ugh.

  //

  init(bounds: PathAngleBounds<k>) {
    _bounds = bounds
    _parent = nil
    _direction = nil
    _vertexCounts = [0, 0, 0]
    //_curVector = 𝝙Vec2(dx: R.zero, dy: R.one)
    //_leftBoundary = _curVector.copy()
    //_rightBoundary = _curVector.copy()
    _leftBase = BoundaryPoint(coords: bounds._v[0])
    _rightBase = BoundaryPoint(coords: bounds._v[1])
    _apex = bounds._v[2]
    _edgeIndex = 0
    _depth = 0
  }

  init(parent: PathAngleNode, direction: EdgePathDirection,
       vertexCounts: [Int],
       edgeIndex: Int) {
    _parent = parent
    _bounds = parent._bounds
    _direction = direction
    _vertexCounts = vertexCounts
    //_leftBase = leftBase
    //_rightBase = rightBase
    //_curVector = curVector
    _edgeIndex = edgeIndex
    _depth = parent._depth + 1
    var reflectionVertex: Vec2<k>
    if direction == .Left {
      _leftBase = parent._leftBase
      _rightBase = BoundaryPoint(coords: parent._apex, prev: parent._rightBase)
      reflectionVertex = parent._rightBase._coords
      // apex = reflect parent._rightBase through new edge index
    } else {
      _leftBase = BoundaryPoint(coords: parent._apex, prev: parent._leftBase)
      _rightBase = parent._rightBase
      reflectionVertex = parent._leftBase._coords
    }
    _apex = reflectionVertex.reflectThroughLine(
      from: _leftBase._coords, to: _rightBase._coords)
    self.restoreConvex()
  }

  public func advance(direction: EdgePathDirection) -> PathAngleNode? {
    //NSLog("advance \(direction) from \(self.pathString()), \(_vertexCounts)")
    let reflect = (_depth % 2 == 0) ? 1 : -1
    let nextEdge = Mod3(_edgeIndex + direction.sign() * reflect)
    // The index of the vertex the path is rotating around (common vertex
    // between _edgeIndex and nextEdge)
    let vertexIndex = Mod3(_edgeIndex + (1 + direction.sign() * reflect) / 2)
    var counts: [Int] = _vertexCounts
    counts[vertexIndex] += direction.sign()
    //NSLog("New counts \(counts)")
    let child = PathAngleNode<k>(parent: self, direction: direction,
                                vertexCounts: counts,
                                //leftBase: newLeft, rightBase: newRight,
                                edgeIndex: nextEdge)
    var leftBoundary: [Vec2<k>] = []
    var rightBoundary: [Vec2<k>] = []
    var cur: BoundaryPoint<k>? = child._leftBase
    while cur != nil {
      leftBoundary.append(cur!._coords)
      cur = cur!._prev
    }
    cur = child._rightBase
    while cur != nil {
      rightBoundary.append(cur!._coords)
      cur = cur!._prev
    }

    var rightIndex = 1

    for leftIndex in 1..<leftBoundary.count {
      // Turn signs are flipped because we're traversing the vertices
      // last-to-first.
      while rightIndex < rightBoundary.count &&
        TurnSign(leftBoundary[leftIndex - 1],
                 leftBoundary[leftIndex],
                 rightBoundary[rightIndex]) > k.zero {
                  // The full right edge is still to the right of the current left
                  // edge, keep advancing
                  rightIndex += 1
      }
      if rightIndex >= rightBoundary.count {
        return child
      }
      if TurnSign(rightBoundary[rightIndex - 1],
                  rightBoundary[rightIndex],
                  leftBoundary[leftIndex]) >= k.zero {
        return nil
      }
    }
    return child
  }

  func restoreConvex() {
    while _leftBase._prev != nil && _leftBase._prev!._prev != nil {
      if TurnSign(_leftBase._prev!._prev!._coords,
                  _leftBase._prev!._coords, _leftBase._coords) > k.zero {
        // Left turn, all is well
        break
      }
      _leftBase._prev = _leftBase._prev!._prev
    }
    while _rightBase._prev != nil && _rightBase._prev!._prev != nil {
      if TurnSign(_rightBase._prev!._prev!._coords,
                  _rightBase._prev!._coords, _rightBase._coords) < k.zero {
        // Right turn, all is well
        break
      }
      _rightBase._prev = _rightBase._prev!._prev
    }
  }

  public func isCycle() -> Bool {
    return (_parent != nil && _vertexCounts[0] == 0 && _vertexCounts[1] == 0 &&
      _vertexCounts[2] == 0)
  }

  public func pathString() -> String {
    if _parent == nil {
      return ""
    }
    return _parent!.pathString() + (_direction! == .Left ? "L" : "R")
  }

  public func totalCounts() -> Int {
    return abs(_vertexCounts[0]) + abs(_vertexCounts[1]) + abs(_vertexCounts[2])
  }
}

public class PathAngleBounds<k: Field & Comparable> {
  //let _angleVectors: [𝝙Vec2<R>]
  var _root: PathAngleNode<k>?
  var _v: [Vec2<k>]

  init(apex: Vec2<k>) {
    _v = [Vec2(x: k(0), y: k(0)), Vec2(x: k(1), y: k(0)), apex]
  }

  var root: PathAngleNode<k> {
    if _root == nil {
      _root = PathAngleNode<k>(bounds: self)
    }
    return _root!
  }

}

public func Cycles<k: Field & Comparable>(
  forApex apex: Vec2<k>, checkAtMost: Int) -> [String] {
  //upToLength length: Int) -> [String] {
  var cycles: [String] = []
  let bounds = PathAngleBounds(apex: apex)
  //let queue = Queue<PathAngleNode<k>>()
  var nodes: [PathAngleNode<k>] = [bounds.root]
  //queue.add(bounds.root)
  var checked = 0
  var i = 0
  var pathLength = 0
  while checked < checkAtMost {//i < nodes.count {
    let pathNode = nodes[i]//queue.take()!
    i += 1
    if pathNode._depth > pathLength {
      pathLength = pathNode._depth
    }
    if pathNode._depth + pathNode.totalCounts() >= pathLength + 4 {
      nodes.append(pathNode)
      continue
    }
    checked += 1
    if pathNode.isCycle() {
      let ps = pathNode.pathString()
      if VerifiedRadiusForPath(EdgePath(fromString:ps), withApex: apex) != nil {
        NSLog("Found path: \(ps)")
        cycles.append(ps)
        continue
      }
    }
    //if pathNode._depth >= length {
    //  break
    //}
    let left = pathNode.advance(direction: .Left)
    if left != nil {
      //queue.add(left!)
      nodes.append(left!)
    }
    let right = pathNode.advance(direction: .Right)
    if right != nil {
      //queue.add(right!)
      nodes.append(right!)
    }
  }
  NSLog("Checked \(checked) paths, final length \(pathLength)")
  return cycles
}

func gcd(_ a: Int, _ b: Int) -> Int {
  if b == 0 {
    return a
  }
  return gcd(b, a % b)
}

public class Triple: Hashable, CustomStringConvertible {
  public let a: Int
  public let b: Int
  public let c: Int

  init(_ _a: Int, _ _b: Int, _ _c: Int) {
    a = _a
    b = _b
    c = _c
  }
  init(_ values: [Int]) {
    a = values[0]
    b = values[1]
    c = values[2]
  }

  public var description: String {
    return "(\(a), \(b), \(c))"
  }

  public func hash(into hasher: inout Hasher) {
    description.hash(into: &hasher)
  }

  public static func ==(lhs: Triple, rhs: Triple) -> Bool {
    return (lhs.a == rhs.a && lhs.b == rhs.b && lhs.c == rhs.c)
  }
}

/*func Flip(_ d: EdgePathDirection) -> EdgePathDirection {
  if d == .Left {
    return .Right
  }
  return .Left
}

func Flip(_ path: EdgePath) -> EdgePath {
  return path.map { Flip($0) }
}*/
