

public class Path: Hashable {
  public let orientation: Singularity.Orientation
  public var turns: [Int]

  public init(orientation: Singularity.Orientation, turns: [Int] = []) {
    self.orientation = orientation
    self.turns = turns
  }

  public func reversed() -> Path {
    if turns.count % 2 == 0 {
      return Path(orientation: -orientation, turns: turns.reversed())
    }
    return Path(orientation: orientation, turns: turns.reversed())
  }

  public var description: String {
    return orientation.description + "[" +
        turns.map { $0.description }.joined(separator: " ") + "]"
  }

  public static func ==(_ p0: Path, _ p1: Path) -> Bool {
    return (p0.orientation == p1.orientation && p0.turns == p1.turns)
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(orientation)
    hasher.combine(turns)
  }
}


public class FlipCoverNode<k: Field & Comparable> {
  public let params: BilliardsParamsDeprecated<k>

  weak public var parent: FlipCoverNode<k>?
  // The magnitude of the turn (all turns are positive)
  public let turn: Int
  public let enteringEdge: FanPathEdgeDeprecated<k>
  public let vectorRange: FeasibleVectorRange<k>
  public let flipRange: FeasibleVectorRange<k>?
  public let depth: Int

  private var _children: [FlipCoverNode<k>]?

  private init(params: BilliardsParamsDeprecated<k>, parent: FlipCoverNode<k>?,
      turn: Int, enteringEdge: FanPathEdgeDeprecated<k>,
      vectorRange: FeasibleVectorRange<k>,
      flipRange: FeasibleVectorRange<k>?) {
    self.params = params
    self.parent = parent
    self.turn = turn
    self.enteringEdge = enteringEdge
    self.vectorRange = vectorRange
    self.flipRange = flipRange

    /*let flipRange = vectorRange.copy()
    flipRange.addBoundaryVertex(
      coords: enteringEdge.toCoords(),
      side: Side.right.withSign(enteringEdge.orientation.sign()))
    self.flipRange = flipRange.isEmpty() ? nil : flipRange
    vectorRange.addBoundaryVertex(
      coords: enteringEdge.toCoords(),
      side: Side.left.withSign(enteringEdge.orientation.sign()))

    self.vectorRange = vectorRange*/
    if parent == nil {
      depth = 0
    } else {
      depth = parent!.depth + 1
    }
  }

  public convenience init(
      rootForParams params: BilliardsParamsDeprecated<k>,
      orientation: Singularity.Orientation) {
    let enteringEdge = FanPathEdgeDeprecated(
        fromParams: params, orientation: orientation)
    let vectorRange = FeasibleVectorRange(flipAroundEdge: enteringEdge)
    self.init(params: params, parent: nil, turn: 0,
        enteringEdge: enteringEdge, vectorRange: vectorRange, flipRange: nil)
  }

  public func path() -> Path {
    if parent == nil {
      return Path(orientation: enteringEdge.orientation)
    }
    let path = parent!.path()
    path.turns.append(turn)
    return path
  }

  public func children() -> [FlipCoverNode<k>] {
    if _children == nil {
      _children = _computeChildren()
    }
    return _children!
  }

  public func _computeChildForTurn(_ turn: Int) -> FlipCoverNode<k>? {
    if turn == 0 {
      return nil
    }

    let exitingEdge: FanPathEdgeDeprecated<k> = enteringEdge.turnBy(turn)

    let childVectorRange: FeasibleVectorRange<k> = vectorRange.copy()
    childVectorRange.addBoundaryVertex(
      coords: exitingEdge.apexForSide(.left), side: .left)
    childVectorRange.addBoundaryVertex(
      coords: exitingEdge.apexForSide(.right), side: .right)

    if childVectorRange.isEmpty() {
      return nil
    }

    let flipBoundary = exitingEdge.toCoords()
    let childFlipRange = childVectorRange.copy()
    let exitingSign = Sign(of: exitingEdge.orientation)
    childFlipRange.addBoundaryVertex(
        coords: flipBoundary,
        side: exitingSign * Side.left)
    childVectorRange.addBoundaryVertex(
        coords: flipBoundary,
        side: exitingSign * Side.right)
    return FlipCoverNode(
        params: params, parent: self, turn: turn,
        enteringEdge: exitingEdge,
        vectorRange: childVectorRange,
        flipRange: childFlipRange.isEmpty() ? nil : childFlipRange)
  }

  func _computeChildren() -> [FlipCoverNode<k>] {
    var children: [FlipCoverNode<k>] = []
    let maxTurn = params.maxTurnAroundSingularity(enteringEdge.orientation.to)
    for turn in 1...maxTurn {
      let child = self._computeChildForTurn(turn)
      if child != nil {
        children.append(child!)
      }
    }
    return children
  }
}


public class FlipCover<k: Field & Comparable> {
  public let roots: Singularities<FlipCoverNode<k>>
  public let elements: [Element]
  public let uncovered: [FlipCoverNode<k>]

  public init(apex: Vec2<k>, maxDepth: Int) {
    let params = BilliardsParamsDeprecated(apex: apex)
    roots = Singularities(
        FlipCoverNode(rootForParams: params, orientation: .forward),
        FlipCoverNode(rootForParams: params, orientation: .backward))
    var flipElements: [Element] = []
    var nodes: [FlipCoverNode<k>] = [ roots[.S0], roots[.S1] ]
    for _ in 1...maxDepth {
      var newNodes: [FlipCoverNode<k>] = []
      for node in nodes {
        for child in node.children() {
          //print("checking path \(child.path())")
          if child.flipRange != nil {
            flipElements.append(Element(
                path: child.path(),
                phaseBoundary: child.flipRange!))
          }
          if !child.vectorRange.isEmpty() {
            newNodes.append(child)
          }
        }
      }
      nodes = newNodes
      if nodes.count == 0 {
        break
      }
    }
    elements = flipElements
    uncovered = nodes
  }

  public class Element {
    public let path: Path
    public let phaseBoundary: FeasibleVectorRange<k>

    init(path: Path, phaseBoundary: FeasibleVectorRange<k>) {
      self.path = path
      self.phaseBoundary = phaseBoundary
    }
  }
}
