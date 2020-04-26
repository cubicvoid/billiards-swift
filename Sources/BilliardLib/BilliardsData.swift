

public class BilliardsParamsDeprecated<k: Field & Comparable> {
  public let apex: Vec2<k>
  public let base: Singularities<Vec2<k>>

  // The apex, as an offset from each of the two base vertices
  public let apexFromBase: Singularities<Vec2<k>>
  public let rotationCoeffs: Singularities<Vec2<k>>
  var rotationCache: Singularities<[Vec2<k>]>
  var fanLengthCache: Singularities<Int?>

  public init(apex: Vec2<k>) {
    let one = Vec2(x: k.one, y: k.zero)
    let base = Singularities(Vec2.origin, one)
    apexFromBase = Singularities() { singularity in apex - base[singularity] }
    rotationCoeffs = apexFromBase.map { v in
      v.complexDividedBy(v.complexConjugate())
    }

    rotationCache = Singularities([one], [one])
    fanLengthCache = Singularities(nil, nil)
   
    self.apex = apex
    self.base = base
  }

  // degree indicates the direction relative to the triangle
  // base: positive values mean "upward" from the initial
  // configuration, negative means "downward".
  public func vectorForTurn(_ r: Singularity.Turn) -> Vec2<k> {
    let s = r.singularity
    let sign = Sign.of(r.degree) ?? .positive
    let magnitude = abs(r.degree)
    let coeff = rotationCoeffs[s]
    var cache = rotationCache[s]
    if cache.count <= magnitude {
      while cache.count <= magnitude {
        let newVal = cache.last!.complexMul(coeff)
        cache.append(newVal)
      }
      rotationCache = rotationCache.withValue(cache, forSingularity: s)
    }
    let result = cache[magnitude]
    return result.complexConjugateBySign(sign)
  }

  public func maxTurnAroundSingularity(_ s: Singularity) -> Int {
    if fanLengthCache[s] == nil {
      let zero = k.zero
      let sign = Sign(of: Singularity.Orientation.from(s))
      var degree = 0
      var curTurn: Singularity.Turn
      repeat {
        degree += 1
        curTurn = s.turnBy(sign * degree)
      } while vectorForTurn(curTurn).y > zero
      fanLengthCache = fanLengthCache.withValue(degree, forSingularity: s)
    }
    return fanLengthCache[s]!
  }
}

public class BilliardsData<k: Field & Comparable> {
  // apex is the main input parameter. It is specified relative to the base
  // edge from (0,0) to (1,0), and thus for our purposes is usually in the range
  // 0 < x < 1 and 0 < y < 1/2, though values outside that range are still valid
  // whenever they make sense.
  public let apex: Vec2<k>

  // apexOverBase is the complex number (represented as a Vec2)
  // to multiply the base edge by, in the given orientation, to
  // get the vector from the same source vertex to the apex.
  public let apexOverBase: [Singularity.Orientation: Vec2<k>]
  //public let apexOverBase: Singularities<Vec2<k>>
  //public let maxTurnAroundSingularity: Singularities<Int>


  public let rotation: Singularities<UnitPowerCache<k>>
  
  public init(apexOverBase: [Singularity.Orientation: Vec2<k>]) {
    self.apex = apexOverBase[.forward]!
    self.apexOverBase = apexOverBase
    self.rotation = Singularities(
      // Reorient the relative apexes so they're both widdershins
      s0: apexOverBase[.forward]!,
      s1: apexOverBase[.backward]!.complexConjugate()
    ).map { apex in
      // reflection thru each edge rotates the base by the apex over its
      // conjugate
      UnitPowerCache(fromSquareRoot: apex)
    }
    
    /*maxTurnAroundSingularity = _rotationCache.map { powers in
      powers.firstLowerHalfPlane()
    }*/
  }
  
  public convenience init(apex: Vec2<k>) {
    self.init(apexOverBase: [
      .forward: apex,
      .backward: Vec2(x: k.one - apex.x, y: -apex.y)])
  }
  
  /*public func rotationVectorAroundSingularity(
      _ s: Singularity, byDegree degree: Int) -> Vec2<k> {
    return rotation[s].pow(degree)
  }*/
  
  /*public func rotationVectorAroundTurn(_ turn: Singularity.Turn) -> Vec2<k> {
    return rotationVectorAroundSingularity(
        turn.singularity, byDegree: turn.degree)
  }*/
}

public class BaseVertexData<k: Field & Comparable> {
  // the apex divided by the other base vertex (with the current
  // vertex taken to be the origin).
  public let apexOverBase: Vec2<k>
  public let maxTurnAroundSingularity: Int

  private let _rotationCache: LazyExpArray<k>
  
  public init(apexOverBase apex: Vec2<k>) {
    self.apexOverBase = apex
    self._rotationCache = LazyExpArray(base: apex.complexDividedBy(apex.complexConjugate()))

    maxTurnAroundSingularity = _rotationCache.firstLowerHalfPlane()
  }
  
  public func rotationVector(degree: Int) -> Vec2<k> {
    let magnitude = abs(degree)
    let turnVector = _rotationCache[magnitude]
    if degree < 0 {
      return turnVector.complexConjugate()
    }
    return turnVector
  }
}

// A helper class that lazily computes and caches positive integer powers of a
// given complex number
class LazyExpArray<k: Field & Comparable> {
  let base: Vec2<k>
  private var _cache: [Vec2<k>]
  
  init(base: Vec2<k>) {
    self.base = base
    self._cache = [Vec2(x: k.one, y: k.zero)]
  }
  
  subscript(index: Int) -> Vec2<k> {
    while _cache.count <= index {
      let newVal = _cache.last!.complexMul(base)
      _cache.append(newVal)
    }
    return _cache[index]
  }
  
  // returns the first positive power of base that has a nonpositive
  // complex part.
  // this is used to calculate how many powers of a rotation vector can fit into
  // a semicircle.
  func firstLowerHalfPlane() -> Int {
    var i = 1
    while self[i].y > k.zero {
      i += 1
    }
    return i
  }
}
