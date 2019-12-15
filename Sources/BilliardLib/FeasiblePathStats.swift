
// One FeasiblePathNode corresponds roughly to one fundamental quadrilateral
// (the original triangle plus its reflection through the base), or
// equivalently to one embedded base edge. It can also be thought of as
// the connection between two adjacent discs / singularities.
//
// Generally this will start from a root node with the initial path space
// constrained to be a flip, i.e. where all paths pass through the two
// edges on the same side of the base edge, and then fan out monotonically
// from there.
public class FeasiblePathNode<k: Field  & Comparable> {
  public let params: BilliardsParamsDeprecated<k>

  weak public var parent: FeasiblePathNode<k>?
  // The (signed) number of reflections around the central singularity
  // (enteringEdge.destCoords()) relative to parent. Ignored if parent is nil.
  public let turn: Int
  public let enteringEdge: FanPathEdgeDeprecated<k>
  public let vectorRange: FeasibleVectorRange<k>
  public let depth: Int
  public let flipCount: Int

  private var _children: [FeasiblePathNode<k>]?

  private init(params: BilliardsParamsDeprecated<k>, parent: FeasiblePathNode<k>?,
      turn: Int, enteringEdge: FanPathEdgeDeprecated<k>,
      vectorRange: FeasibleVectorRange<k>) {
    self.params = params
    self.parent = parent
    self.turn = turn
    self.enteringEdge = enteringEdge
    self.vectorRange = vectorRange
    if parent == nil {
      depth = 0
      flipCount = 0
    } else {
      depth = parent!.depth + 1
      let flip = (parent!.turn >= 0) != (turn >= 0)
      flipCount = parent!.flipCount + (flip ? 1 : 0)
    }
  }

  public convenience init(
      rootForParams params: BilliardsParamsDeprecated<k>,
      orientation: Singularity.Orientation) {
    let enteringEdge = FanPathEdgeDeprecated(
        fromParams: params, orientation: orientation)
    let vectorRange = FeasibleVectorRange(flipAroundEdge: enteringEdge)
    self.init(params: params, parent: nil, turn: 0,
        enteringEdge: enteringEdge, vectorRange: vectorRange)
  }

  public func isFlip() -> Bool {
    if parent == nil {
      return false
    }
    return (parent!.turn >= 0) != (turn >= 0)
  }

  public func path() -> [Int] {
    if parent == nil {
      return []
    }
    var path = parent!.path()
    path.append(turn)
    return path
  }

  public func children() -> [FeasiblePathNode<k>] {
    if _children == nil {
      _children = _computeChildren()
    }
    return _children!
  }

  public func _computeChildForTurn(_ turn: Int) -> FeasiblePathNode<k>? {
    guard let turnSign = Sign.of(turn)
    else { return nil }

    let exitingEdge: FanPathEdgeDeprecated<k> = enteringEdge.turnBy(turn)

    let childVectorRange: FeasibleVectorRange<k> = vectorRange.copy()
    // See the logs for 2019/06/06 for details on this, but tldr:
    // this workaround to avoid duplicate boundaries makes me very
    // unhappy.
    let enteringSign = Sign(of: enteringEdge.orientation)
    if enteringSign * turn != 1 {
      // If we're only turning by 1, then we already added the
      // nearest apex, so skip it.
      childVectorRange.addBoundaryVertex(
        coords: exitingEdge.apexForSide(.left), side: .left)
    }
    if enteringSign * turn != -1 {
      childVectorRange.addBoundaryVertex(
        coords: exitingEdge.apexForSide(.right), side: .right)
    }

    childVectorRange.addBoundaryVertex(
        coords: exitingEdge.fromCoords(),
        side: Side.right * enteringSign * turnSign)

    if childVectorRange.isEmpty() {
      return nil
    }
    return FeasiblePathNode(
          params: params, parent: self, turn: turn,
        enteringEdge: exitingEdge, vectorRange: childVectorRange)
  }

  func _computeChildren() -> [FeasiblePathNode<k>] {
    var children: [FeasiblePathNode<k>] = []
    let maxTurn =
        params.maxTurnAroundSingularity(enteringEdge.orientation.to)
    let minTurn = (parent == nil) ? 1 : -maxTurn
    for turn in minTurn...maxTurn {
      let child = self._computeChildForTurn(turn)
      if child != nil {
        children.append(child!)
      }
    }
    return children
  }
}


public func FeasiblePathStats<k>(
    params: BilliardsParamsDeprecated<k>, maxDepth: Int, maxFlips: Int) {
  let root = FeasiblePathNode(rootForParams: params, orientation: .forward)
  var nodes: [FeasiblePathNode<k>] = [ root ]
  var pathCount = 0
  for _ in 1...maxDepth {
    var newNodes: [FeasiblePathNode<k>] = []
    for node in nodes {
      let children = node.children()
      for child in children {
        if child.enteringEdge.isAngleZero() && child.turn < 0 {
          // The child.turn < 0 check is redundant-ish with the geometric
          // check below, but it's faster and filters out closed paths that
          // don't start / end on a flip, which is usually desirable.
          print("Closed path found")
          let offset = child.enteringEdge.fromCoords()
          if child.vectorRange.hasElementWithOffset(offset) {
            print("Cyclic trajectory found")
            print("\(child.path())")
            return
          }
        }
        if child.flipCount >= maxFlips {
          pathCount += 1
          print("\(child.path())")
        } else {
          newNodes.append(child)
        }
      }
    }
    nodes = newNodes
  }
  print("\(pathCount) completed paths, \(nodes.count) still in progress")
  /*for node in nodes {
    print("\(node.path())")
  }*/
}

// VerifiedRadiusForFanPath checks whether the given fan path is a billiard
// cycle for the triangle with the given apex, and if so, returns the positive
// radius to which it can be verified.
// If annotations is non-nil, a visualization of the path is added to it.
public func VerifiedRadiusForFanPath<k : Field & Comparable>(
    _ path: FanPath,
    withParams params: BilliardsParamsDeprecated<k>) -> k? {
  /*if params.apex.y == k.zero() {
    // Degenerate case, bail out before we hit division by zero or something.
    return nil
  }
  var edge = FanPathEdge(fromParams: params)
  var boundaries = [
    [edge.fromCoords()], // lower
    [edge.apexForSide(.left)]] // upper
  var stepCount = 0
  for i in 0..<path.length {
    let turn = Int(path[i])
    stepCount += abs(turn)
    let nearSign = turn.withSign(edge.orientation.sign())
    let nearIndex = (nearSign >= 0) ? 0 : 1
    boundaries[nearIndex].append(edge.toCoords())
    let nonzeroTurn = try! Nonzero(path[i])
    edge = edge.turn(by: nonzeroTurn)

    boundaries[nearIndex].append(edge.apexForSide(Side.right turn))
    boundaries[1 - nearIndex].append(edge.apexForSign(-turn))
  }

  if !edge.isAngleZero() {
    // This should never happen with the current program flow, but just in
    // case it does, don't report a false positive.
    return nil
  }

  let cycleVector = edge.sourceCoords().asOffsetFromOrigin()
  let heightVector = OffsetVec2<k>(dx: -cycleVector.dy, dy: cycleVector.dx)
  //NSLog("CheckPath cycleVector: \(cycleVector)")

  // The leftBoundary must be entirely above cycleVector,
  // rightBoundary below it, as measured along heightVector.
  var upper: [k] = []
  var lower: [k] = []
  for b in boundaries[0] {
    lower.append(b.asOffsetFromOrigin().dot(heightVector))
  }
  for b in boundaries[1] {
    upper.append(b.asOffsetFromOrigin().dot(heightVector))
  }
  let upperBound = upper.min()!
  let lowerBound = lower.max()!

  if upperBound > lowerBound {
    return WorstCaseRadiusForFanPath(
        params: params, fanCount: path.length, stepCount: stepCount,
        boundsMargin: upperBound - lowerBound)
  }*/
  return nil
}

// TODO: Confirm that the bound here is correct (currently is envelope math)
public func WorstCaseRadiusForFanPath<k: Field & Comparable>(
    params: BilliardsParamsDeprecated<k>, fanCount: Int, stepCount: Int,
    boundsMargin: k) -> k {
  let minLength = max(params.apex.x, params.apex.y)
  let n = k(fanCount + 2)
  let s = k(stepCount)
  return k(8) * minLength * boundsMargin / (s * n * n)
}

public func FanPathSearch(
    apex: Vec2<GmpRational>, config: FanSearchConfig) -> FanCycle? {
  return nil
}

public func FanPathSearchApprox(
    apex: Vec2<GmpRational>,
    config: FanSearchConfig) -> FanCycleApprox? {
  typealias k = Double
  let fApex = Vec2(x: apex.x.asDouble(), y: apex.y.asDouble())
  if fApex.y < 0.01 {
    return nil
  }
  let params = BilliardsParamsDeprecated(apex: fApex)

  let root = FeasiblePathNode(rootForParams: params, orientation: .forward)
  var nodes: [FeasiblePathNode<k>] = [ root ]
  var totalNodes = 0
  var pathCount = 0
  let minRadius = config.minRadius.asDouble()
  for _ in 1...config.maxFanCount {
    var newNodes: [FeasiblePathNode<k>] = []
    for node in nodes {
      let children = node.children()
      for child in children {
        if child.enteringEdge.isAngleZero() && child.turn < 0 {
          // The child.turn < 0 check is redundant-ish with the geometric
          // check below, but it's faster and filters out closed paths that
          // don't start / end on a flip, which is usually desirable.
          print("Closed path found")
          let offset = child.enteringEdge.fromCoords()
          if child.vectorRange.hasElementWithOffset(offset) {
            print("Cyclic trajectory found")
            let path = FanPath(turns: child.path())
            let radius = VerifiedRadiusForFanPath(path, withParams: params)
            if radius != nil && radius! > minRadius {
              print("Success")
              return FanCycleApprox(path: path, radius: radius!)
            } else {
              print("Radius too low")
            }
          }
        }
        if child.flipCount >= config.maxFlipCount {
          pathCount += 1
        } else {
          newNodes.append(child)
          totalNodes += 1
          if totalNodes > 4000000 {
            print("Abandoning apex \(fApex) for exceeding 4000000 nodes")
            return nil
          }
        }
      }
    }
    nodes = newNodes
  }
  print("\(pathCount) completed paths, \(nodes.count) still in progress")
  /*for node in nodes {
    print("\(node.path())")
  }*/
  return nil
}
