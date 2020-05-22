public enum AngleBound {
  case pi
  case twoPi
}


fileprivate func binarySearch(
	from: Int, to: Int, highEnough: (Int) -> Bool
) -> Int {
	if from == to { return from }
	let delta = to - from
	let center = from + delta / 2
	if highEnough(center) {
		return binarySearch(
			from: from, to: center,
			highEnough: highEnough)
	}
	return binarySearch(
		from: center + 1, to: to,
		highEnough: highEnough)
}

// for exponents on the unit circle.
// the turn bounds are only meaningful if `base` is in the upper half
// plane (which is always true when the base is derived from a base
// vertex of an obtuse triangle)
public class UnitPowerCache<k: Field & Comparable & CustomStringConvertible> {
	public let base: Vec2<k>
	var _cache: [Vec2<k>?]

	// the maximum exponent that has been computed and written
	// to the cache so far
	var _maxPower: Int

	// _logBound[.pi] (resp .twoPi) is the smallest integer n such that
	// base^n spans at least pi (resp 2pi), or nil if that value
	// hasn't been found yet.
	// no feasible path can have a turn of magnitude greater
	// than _logBound[.pi].
	var _logBound: [AngleBound: Int] = [:]

	// input invariant: power <= 2 * _highestComputedPower
	// output invariant: if _logBound[.pi] and / or _logBound[.pi] are
	// at most power, then they will be non-nil when _writeToCache
	// returns.
	func _writeToCache(power: Int, value: Vec2<k>) {
		while _cache.count <= power { _cache.append(nil) }
		if power > _maxPower {
			// if this is higher than previously stored values, we
			// might need to update _logBound.
			var updatingBound: AngleBound? = nil
			if _logBound[.pi] == nil {
				if value.y <= k.zero {
					updatingBound = .pi
				}
			} else if _logBound[.twoPi] == nil && value.y >= k.zero {
				updatingBound = .twoPi
			}
			if let targetBound = updatingBound {
				let startValue = _cache[_maxPower]!
				_logBound[targetBound] = binarySearch(
					from: _maxPower, to: power
				) { (curPower: Int) in
					let offset = curPower - _maxPower
					// offset is guaranteed to be <=
					// _maxPower so it is safe to
					// call recursively here
					let curValue = startValue.complexMul(pow(offset))
					_cache[curPower] = curValue
					switch targetBound {
						case .pi: return curValue.y <= k.zero
						case .twoPi: return curValue.y >= k.zero
					}
				}
			}
			_maxPower = power
		}
		_cache[power] = value
	}

	// construct a rational unit base value from (root^2 / |root|^2)
	public init(fromSquareRoot root: Vec2<k>) {
		base = (k.one / root.squaredLength()) * root.complexMul(root)
		_cache = [Vec2(x: k.one, y: k.zero), base]
		_maxPower = 1
	}

	public func power(_ n: Int, matchesAngleBound bound: AngleBound?) -> Bool {
		guard let b = bound
		else { return true }
		let magnitude = abs(n)
		switch b {
		case .pi:
			if let logPi = _logBound[.pi] {
				return magnitude <= logPi
			}
			return true
		case .twoPi:
			if let log2Pi = _logBound[.twoPi] {
				return magnitude <= log2Pi
			}
			if let logPi = _logBound[.pi] {
				// assume the most permissive match (highest possible bound) until
				// we actually compute that high
				return magnitude <= 2 * logPi
			}
			// we have no information, so we match with anything.
			return true
		}
	}

	// greedily compute the exponents up to the given bound.
	public func maxTurnMagnitudeForBound(_ angleBound: AngleBound) -> Int {
		while true {
			if let value = _logBound[angleBound] {
				return value
			}
			let _ = pow(_maxPower * 2, angleBound: angleBound)
		}
	}

	public func pow(_ n: Int) -> Vec2<k> {
		return pow(n, angleBound: nil)!
	}

	public func pow(_ exponent: Int, angleBound: AngleBound?) -> Vec2<k>? {
		if exponent < 0 {
			return pow(-exponent, angleBound: angleBound)?.complexConjugate()
		}
		// we check this again below, but if we already
		// know enough to stop now we can avoid the cost
		// of computing the result
		if !power(exponent, matchesAngleBound: angleBound) {
			return nil
		}
		if exponent >= _cache.count || _cache[exponent] == nil {
			let rootExp = exponent / 2
			guard let root = pow(rootExp, angleBound: angleBound)
			else { return nil }
			let rootSquared = root.complexMul(root)
			_writeToCache(power: 2 * rootExp, value: rootSquared)
			if exponent % 2 == 1 {
				// the power is odd, so we need to add one more
				_writeToCache(
					power: exponent,
					value: rootSquared.complexMul(base))
			}
		}
		if !power(exponent, matchesAngleBound: angleBound) {
			return nil
		}
		return _cache[exponent]!
	}
}
