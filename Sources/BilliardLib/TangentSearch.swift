import Foundation

extension Vec2 where R: Numeric {
  public var shortDescription: String {
    get {
      return "(\(self.x.asDouble()), \(self.y.asDouble()))"
    }
  }
}

func TangentPickerForApex(
  _ apex: Vec2<GmpRational>, config: SearchConfig) -> TangentPicker {
  switch config.tangentPickerType! {
    case .edgeInterpolation:
      return EdgeInterpolationTangentPicker(forApex: apex, config: config)
    case .nearApproach:
      return NearApproachTangentPicker(forApex: apex, config: config)
  }
}

func TangentCheckerForApex(
  _ apex: Vec2<GmpRational>, config: SearchConfig) -> TangentChecker {
  switch config.tangentCheckerType! {
    case .exact:
      return ExactTangentChecker(forApex: apex, config: config)
    case .floatFilter:
      return FloatFilterTangentChecker(forApex: apex, config: config)
    case .bandFilter:
      return BandFilterTangentChecker(forApex: apex, config: config)
  }
}

public func TangentSearchForCycleApprox(
  apex: Vec2<GmpRational>, config: SearchConfig) -> CycleApprox? {
  print("Finding cycles for apex \(apex.shortDescription)")

  let tangentPicker = TangentPickerForApex(apex, config: config)
  let tangentChecker = TangentCheckerForApex(apex, config: config)

  let dMinRadius = config.minRadius.asDouble()
  for i in 1...config.attemptCount {
    if i % 100 == 0 {
      print("\(apex.shortDescription): Attempt \(i)")
    }
    let (path, radius, dRadius) =
      tangentChecker.checkForCycles(tangent: tangentPicker.pickTangent())
    var r: Double?
    if dRadius != nil {
      r = dRadius
    } else if radius != nil {
      r = radius!.asDouble()
    }
    if r != nil && r! >= dMinRadius {
      print("\(apex.shortDescription): Found cycle of length \(path!.length)")
      return CycleApprox(path: path!, radius: r!)
    }
    if r != nil {
      let ratio = log2(r! / dMinRadius)
      print("\(apex.shortDescription): Found cycle, but its radius was too " +
        "low (log2 offset \(ratio))")
    }
  }
  print("\(apex.shortDescription): No valid cycles found")
  return nil
}

public func TangentSearchForCycle(
  apex: Vec2<GmpRational>, config: SearchConfig) -> Cycle? {
  typealias k = GmpRational
  print("Finding cycles for apex \(apex.shortDescription)")

  let tangentPicker = TangentPickerForApex(apex, config: config)
  let tangentChecker = TangentCheckerForApex(apex, config: config)

  for i in 1...config.attemptCount {
    if i % 100 == 0 {
      print("\(apex.shortDescription): Attempt \(i)")
    }
    let (path, radius, _) =
      tangentChecker.checkForCycles(tangent: tangentPicker.pickTangent())
    if radius != nil && radius! >= config.minRadius {
      print("\(apex.shortDescription): Found cycle of length \(path!.length)")
      return Cycle(path: path!, radius: radius!)
    }
    if radius != nil {
      let ratio = log2((radius! / config.minRadius).asDouble())
      print("\(apex.shortDescription): Found cycle, but its radius was too " +
        "low (log2 offset \(ratio))")
    }
  }
  print("\(apex.shortDescription): No valid cycles found")
  return nil
}

protocol TangentChecker {
  func checkForCycles(
    tangent: TangentCoords2d<GmpRational>
  ) -> (EdgePath?, GmpRational?, Double?)
}

class ExactTangentChecker: TangentChecker {
  typealias k = GmpRational
  let _triangleApex: Vec2<k>
  var _maxPathLength: Int
  let _pathLengthIncrement: Int

  init(forApex apex: Vec2<k>, config: SearchConfig) {
    _triangleApex = apex
    _maxPathLength = config.maxPathLength - config.pathLengthIncrement
    _pathLengthIncrement = config.pathLengthIncrement
  }

  func checkForCycles(tangent: TangentCoords2d<k>) -> (EdgePath?, k?, Double?) {
    _maxPathLength += _pathLengthIncrement
    var baseEdges: [Int] = []

    let baseVector = Vec2<k>.origin - tangent.base
    var v: [Vec2<k>] = [
      Vec2<k>.origin + baseVector,
      Vec2(x: k.one, y: k.zero) + baseVector,
      _triangleApex + baseVector
    ]
    let pathOffsetVector = tangent.vector.cross()
    var depth = 0
    var counts = [0, 0, 0]
    var edgeIndex = 0
    let path = EdgePath()
    for _ in 0..<_maxPathLength {
      baseEdges.append(edgeIndex)
      let apexIndex = Mod3(edgeIndex + 2)
      let reflect = (depth % 2 == 0) ? 1 : -1
      depth += 1
      // Intersect pathVector with the triangle edges
      // and reflect through the one it hits
      let apex = v[apexIndex]
      let apexOffset: k =
        apex.x * pathOffsetVector.x + apex.y * pathOffsetVector.y
      if apexOffset == k.zero {
        // hit a vertex exactly, bail out
        return (nil, nil, nil)
      }
      var direction: EdgePathDirection
      if apexOffset < k.zero {
        direction = .Left
      } else {
        direction = .Right
      }
      path.append(direction)
      let nextEdge = Mod3(edgeIndex + direction.sign() * reflect)
      let reflectionIndex = Mod3(nextEdge + 2)
      // The index of the vertex the path is rotating around (common vertex
      // between edgeIndex and nextEdge)
      let vertexIndex = Mod3(edgeIndex + (1 + direction.sign() * reflect) / 2)
      counts[vertexIndex] += direction.sign()

      if counts[0] == 0 && counts[1] == 0 && counts[2] == 0 {
        // Candidate path, need to confirm with the right vector
        let radius = VerifiedRadiusForPath(path, withApex: _triangleApex)
        if radius != nil {
          return (path, radius, nil)
        } else {
          print("\(_triangleApex.shortDescription): Candidate path didn't work")
        }
      }
      v[reflectionIndex] = v[reflectionIndex].reflectThroughLine(
        from: v[nextEdge], to: v[Mod3(nextEdge + 1)])
      edgeIndex = nextEdge
    }
    return (nil, nil, nil)
  }
}

class FloatFilterTangentChecker: TangentChecker {
  typealias k = GmpRational
  typealias fk = Double
  let _triangleApex: Vec2<k>
  let _fTriangleApex: Vec2<fk>
  var _maxPathLength: Int
  let _pathLengthIncrement: Int
  let _dMinRadius: Double
  let _unsafeMath: Bool

  init(forApex apex: Vec2<k>, config: SearchConfig) {
    _triangleApex = apex
    _fTriangleApex = Vec2(x: apex.x.asDouble(), y: apex.y.asDouble())
    _maxPathLength = config.maxPathLength - config.pathLengthIncrement
    _pathLengthIncrement = config.pathLengthIncrement
    _dMinRadius = config.minRadius.asDouble()
    _unsafeMath = config.unsafeMath
  }

  func checkForCycles(tangent: TangentCoords2d<k>) -> (EdgePath?, k?, fk?) {
    let fTangent = TangentCoords2d(
      base: Vec2(x: tangent.base.x.asDouble(),
                     y: tangent.base.x.asDouble()),
      vector: Vec2(x: tangent.vector.x.asDouble(),
                        y: tangent.vector.y.asDouble()))
    _maxPathLength += _pathLengthIncrement
    var baseEdges: [Int] = []

    let baseVector = Vec2<fk>.origin - fTangent.base
    var v: [Vec2<fk>] = [
      baseVector,
      baseVector + Vec2(x: fk.one, y: fk.zero),
      baseVector + _fTriangleApex
    ]
    let pathOffsetVector: Vec2<fk> = fTangent.vector.cross()
    var depth = 0
    var counts = [0, 0, 0]
    var edgeIndex = 0
    let path = EdgePath()
    for _ in 0..<_maxPathLength {
      baseEdges.append(edgeIndex)
      let apexIndex = Mod3(edgeIndex + 2)
      let reflect = (depth % 2 == 0) ? 1 : -1
      depth += 1
      // Intersect pathVector with the triangle edges
      // and reflect through the one it hits
      let apex = v[apexIndex]
      let apexOffset: fk =
        apex.x * pathOffsetVector.x + apex.y * pathOffsetVector.y
      if apexOffset == fk.zero {
        // hit a vertex exactly, bail out
        return (nil, nil, nil)
      }
      var direction: EdgePathDirection
      if apexOffset < fk.zero {
        direction = .Left
      } else {
        direction = .Right
      }
      path.append(direction)
      let nextEdge = Mod3(edgeIndex + direction.sign() * reflect)
      let reflectionIndex = Mod3(nextEdge + 2)
      // The index of the vertex the path is rotating around (common vertex
      // between edgeIndex and nextEdge)
      let vertexIndex = Mod3(edgeIndex + (1 + direction.sign() * reflect) / 2)
      counts[vertexIndex] += direction.sign()

      if counts[0] == 0 && counts[1] == 0 && counts[2] == 0 {
        // Candidate path, need to confirm with the right vector
        let dRadius = VerifiedRadiusForPath(path, withApex: _fTriangleApex)
        if dRadius != nil && dRadius! >= _dMinRadius {
          if (_unsafeMath) {
            return (path, nil, dRadius)
          }
          let radius = VerifiedRadiusForPath(path, withApex: _triangleApex)
          if radius != nil {
            return (path, radius, dRadius)
          } else {
            print("\(_triangleApex.shortDescription): " +
                  "Candidate path didn't work")
          }
        }
      }
      v[reflectionIndex] = v[reflectionIndex].reflectThroughLine(
        from: v[nextEdge], to: v[Mod3(nextEdge + 1)])
      edgeIndex = nextEdge
    }
    return (nil, nil, nil)
  }
}

class BandFilterTangentChecker: TangentChecker {
  typealias k = GmpRational
  typealias fk = Double
  let _triangleApex: Vec2<k>
  let _fTriangleApex: Vec2<fk>
  var _maxPathLength: Int
  let _pathLengthIncrement: Int
  let _bandFocus: UInt

  init(forApex apex: Vec2<k>, config: SearchConfig) {
    _triangleApex = apex
    _fTriangleApex = Vec2(x: apex.x.asDouble(), y: apex.y.asDouble())
    _maxPathLength = config.maxPathLength - config.pathLengthIncrement
    _pathLengthIncrement = config.pathLengthIncrement
    _bandFocus = config.bandFocus
  }

  func checkForCycles(
      tangent ktangent: TangentCoords2d<k>) -> (EdgePath?, k?, fk?) {
    let tangent = TangentCoords2d(
      base: Vec2(x: ktangent.base.x.asDouble(),
                     y: ktangent.base.x.asDouble()),
      vector: Vec2(x: ktangent.vector.x.asDouble(),
                        y: ktangent.vector.y.asDouble()))
    let bandSpread = fk(1, over: _bandFocus)
    var leftVector =
      Vec2(x: tangent.vector.x - bandSpread * tangent.vector.y,
                y: tangent.vector.y + bandSpread * tangent.vector.x)
    var rightVector =
      Vec2(x: tangent.vector.x + bandSpread * tangent.vector.y,
                y: tangent.vector.y - bandSpread * tangent.vector.x)
    _maxPathLength += _pathLengthIncrement
    var baseEdges: [Int] = []

    let baseVector = Vec2<fk>.origin - tangent.base
    var v: [Vec2<fk>] = [
      baseVector,
      baseVector + Vec2(x: fk.one, y: fk.zero),
      baseVector + _fTriangleApex
    ]
    var leftOffsetVector = leftVector.cross()
    var rightOffsetVector = rightVector.cross()
    var depth = 0
    var counts = [0, 0, 0]
    var edgeIndex = 0
    let path = EdgePath()
    for _ in 0..<_maxPathLength {
      baseEdges.append(edgeIndex)
      let apexIndex = Mod3(edgeIndex + 2)
      let reflect = (depth % 2 == 0) ? 1 : -1
      depth += 1
      // Intersect pathVector with the triangle edges
      // and reflect through the one it hits
      let apex = v[apexIndex]
      let leftApexOffset: fk =
        apex.x * leftOffsetVector.x + apex.y * leftOffsetVector.y
      let rightApexOffset: fk =
        apex.x * rightOffsetVector.x + apex.y * rightOffsetVector.y
      if leftApexOffset == fk.zero || rightApexOffset == fk.zero {
        // hit a vertex exactly, bail out
        return (nil, nil, nil)
      }
      var leftDirection: EdgePathDirection
      var rightDirection: EdgePathDirection
      if leftApexOffset < fk.zero {
        leftDirection = .Left
      } else {
        leftDirection = .Right
      }
      if rightApexOffset < fk.zero {
        rightDirection = .Left
      } else {
        rightDirection = .Right
      }
      var direction: EdgePathDirection = leftDirection
      if leftDirection != rightDirection {
        // Flip a coin
        if (arc4random() & 1) == 0 {
          direction = rightDirection
          leftVector = apex
          leftOffsetVector = leftVector.cross()
        } else {
          rightVector = apex
          rightOffsetVector = rightVector.cross()
        }
      }
      path.append(direction)
      let nextEdge = Mod3(edgeIndex + direction.sign() * reflect)
      let reflectionIndex = Mod3(nextEdge + 2)
      // The index of the vertex the path is rotating around (common vertex
      // between edgeIndex and nextEdge)
      let vertexIndex = Mod3(edgeIndex + (1 + direction.sign() * reflect) / 2)
      counts[vertexIndex] += direction.sign()

      if counts[0] == 0 && counts[1] == 0 && counts[2] == 0 {
        // Candidate path, need to confirm with the right vector
        let radius = VerifiedRadiusForPath(path, withApex: _triangleApex)
        if radius != nil {
          return (path, radius, nil)
        } else {
          print("\(_triangleApex.shortDescription): Candidate path didn't work")
        }
      }
      v[reflectionIndex] = v[reflectionIndex].reflectThroughLine(
        from: v[nextEdge], to: v[Mod3(nextEdge + 1)])
      edgeIndex = nextEdge
    }
    return (nil, nil, nil)
  }
}

protocol TangentPicker {
  func pickTangent() -> TangentCoords2d<GmpRational>
}

class EdgeInterpolationTangentPicker: TangentPicker {
  let _apex: Vec2<GmpRational>
  let _baseEdgeGranularity: Int
  let _apexEdgeGranularity: Int

  init(forApex apex: Vec2<GmpRational>, config: SearchConfig) {
    _apex = apex
    _baseEdgeGranularity = config.baseEdgeGranularity
    _apexEdgeGranularity = config.apexEdgeGranularity
  }

  func pickTangent() -> TangentCoords2d<GmpRational> {
    typealias k = GmpRational
    //let delta = k(1, over: UInt(_edgeGranularity))
    let baseIndex = arc4random_uniform(UInt32(_baseEdgeGranularity - 1)) + 1
    let baseCoeff = k(Int(baseIndex), over: UInt(_baseEdgeGranularity))
    let apexIndex = arc4random_uniform(UInt32(_apexEdgeGranularity - 1)) + 1
    let apexCoeff = k(Int(apexIndex), over: UInt(_apexEdgeGranularity))
    let basePoint = Vec2(x: baseCoeff, y: k.zero)
    let apexPoint = Vec2(x: k.one - apexCoeff + _apex.x * apexCoeff,
                             y: _apex.y * apexCoeff)
    return TangentCoords2d(from: basePoint, to: apexPoint)
  }
}

class NearApproachTangentPicker: TangentPicker {
  typealias k = GmpRational

  let _apex: Vec2<k>
  let _angleGranularity: Int
  let _distanceGranularity: Int

  init(forApex apex: Vec2<k>, config: SearchConfig) {
    _apex = apex
    _angleGranularity = config.angleGranularity
    _distanceGranularity = config.distanceGranularity
  }

  func pickTangent() -> TangentCoords2d<k> {
    let edgeB = Vec2(x: k.one, y: k.zero) - _apex
    let flippedB = Vec2(x: edgeB.x, y: -edgeB.y)
    let leftAngleBound = flippedB.cross()
    let rightAngleBound = edgeB.cross()
    let angleIndex = arc4random_uniform(UInt32(_angleGranularity - 1)) + 1
    let angleCoeff = k(Int(angleIndex), over: UInt(_angleGranularity))
    let angleVector =
        angleCoeff * leftAngleBound + (k.one - angleCoeff) * rightAngleBound
    let inverseSlope = angleVector.x / angleVector.y
    // The leftmost point this vector can hit along the base edge.
    let baseBound = _apex.x - inverseSlope * _apex.y
    let baseRange = k.one - baseBound
    let baseIndex = arc4random_uniform(UInt32(_distanceGranularity - 1)) + 1
    let baseAffine = k(Int(baseIndex), over: UInt(_distanceGranularity))
    let baseCoeff = baseAffine * baseAffine * baseAffine * baseAffine
    let base = Vec2(x: k.one - baseCoeff * baseRange, y: k.zero)

    return TangentCoords2d(base: base, vector: angleVector)
  }
}
/*public func OldCycleScan<k: Field & Comparable>(
 apex: Vec2<k>) -> (String, k)? {
 let attemptCount = 500
 let angleLimit = 23
 let baseCount = 996
 var angleVectors: [Vec2<k>] = []
 for x in -angleLimit...angleLimit {
 for y in 1...angleLimit {
 if gcd(x, y) == 1 {
 angleVectors.append(Vec2(x: k(x), y: k(y)))
 }
 }
 }
 var tuples: [(Vec2<k>, Vec2<k>)] = []
 let dx = k(1) / k(baseCount + 1)
 for b in 1...baseCount {
 let x = k(b) * dx
 let basePoint = Vec2(x: x, y: k.zero)
 for av in angleVectors {
 tuples.append((basePoint, av))
 }
 }
 for i in 0..<min(attemptCount, tuples.count) {
 let offset = Int(arc4random_uniform(UInt32(tuples.count - i)))
 let tmp = tuples[i]
 tuples[i] = tuples[i + offset]
 tuples[i + offset] = tmp
 }
 NSLog("Created \(angleVectors.count) angle vectors")
 for i in 0..<min(attemptCount, tuples.count) {
 let result = CycleScan(
 apex: apex, pathBase: tuples[i].0, pathVector: tuples[i].1)
 if result != nil {
 return result
 }
 }
 return nil
 }*/
