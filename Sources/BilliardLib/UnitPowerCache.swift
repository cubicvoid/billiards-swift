// for exponents on the unit circle.
// the turn bounds are only meaningful if `base` is in the upper half
// plane (which is always true when the base is derived from a base
// vertex of an obtuse triangle)
public class UnitPowerCache<k: Field & Comparable & CustomStringConvertible> {
  public let base: Vec2<k>
  var _cache: [Vec2<k>]

  // _logPi (resp. _log2Pi) is the smallest integer n such that base^n spans
  // at least pi (resp. 2pi), or nil if that value is > _cache.count.
  // no feasible path can have a turn of magnitude greater than _logPi, and
  // no apex-feasible path can have a turn of magnitude greater than _log2Pi.
  var _logPi: Int? = nil
  var _log2Pi: Int? = nil

  // construct a rational unit base value from (root^2 / |root|^2)
  public init(fromSquareRoot root: Vec2<k>) {
    base = (k.one / root.squaredLength()) * root.complexMul(root)
    _cache = [Vec2(x: k.one, y: k.zero), base]
  }

  public func power(_ n: Int, matchesAngleBound bound: AngleBound?) -> Bool {
    guard let b = bound
    else {
      return true
    }
    switch b {
      case .pi:
        if let logPi = _logPi {
          return n <= logPi
        }
        return true
      case .twoPi:
        if let log2Pi = _log2Pi {
          return n <= log2Pi
        }
        if let logPi = _logPi {
          // assume the most permissive match (highest possible bound) until
          // we actually compute that high
          return n <= 2 * logPi
        }
        // we have no information, so we match with anything.
        return true
    }
  }

  private func _valueForBound(_ angleBound: AngleBound) -> Int? {
    switch angleBound {
      case .pi:
        return _logPi
      case .twoPi:
        return _log2Pi
    }
  }

  // greedily compute the exponents up to the given bound.
  public func maxTurnMagnitudeForBound(_ angleBound: AngleBound) -> Int {
    while true {
      if let value = _valueForBound(angleBound) {
        return value
      }
      let _ = pow(_cache.count)
    }
  }

  public func pow(_ n: Int) -> Vec2<k> {
    return pow(n, angleBound: nil)!
  }

  public func pow(_ exponent: Int, angleBound: AngleBound?) -> Vec2<k>? {
    if exponent < 0 {
      return pow(-exponent, angleBound: angleBound)?.complexConjugate()
    }
    guard power(exponent, matchesAngleBound: angleBound)
    else { return nil }

    while exponent >= _cache.count {
      let prevPower = _cache.last!
      let n = _cache.count
      // curPower = base^n = base * prevPower
      let curPower = prevPower.complexMul(base)
      _cache.append(curPower)
      if _logPi == nil {
        if prevPower.y > k.zero && curPower.y <= k.zero {
          _logPi = n
          if !power(exponent, matchesAngleBound: angleBound) {
            return nil
          }
        }
      } else if _log2Pi == nil && n > _logPi! {
        if prevPower.y < k.zero && curPower.y >= k.zero {
          _log2Pi = n
          if !power(exponent, matchesAngleBound: angleBound) {
            return nil
          }
        }
      }
    }
    return _cache[exponent]
  }
}
