

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

public class ApexData<k: Field & Comparable> {
	// coords is the main input parameter. It is specified relative to the base
	// edge from (0,0) to (1,0), and thus for our purposes is usually in the range
	// 0 < x < 1 and 0 < y < 1/2, though values outside that range are still valid
	// whenever they make sense.
	public let coords: Vec2<k>

	// coordsOverBase is the complex number (represented as a Vec2)
	// to multiply the base edge by, in the given orientation, to
	// get the vector from the same source vertex to the apex.
	public let coordsOverBase: [Singularity.Orientation: Vec2<k>]

	public let rotation: Singularities<UnitPowerCache<k>>
	
	public init(coordsOverBase: [Singularity.Orientation: Vec2<k>]) {
		self.coords = coordsOverBase[.forward]!
		self.coordsOverBase = coordsOverBase
		self.rotation = Singularities(
			// Reorient the relative apexes so they're both widdershins
			s0: coordsOverBase[.forward]!,
			s1: coordsOverBase[.backward]!.complexConjugate()
		).map { apex in
			// reflection thru each edge rotates the base by the apex over its
			// conjugate
			UnitPowerCache(fromSquareRoot: apex)
		}
	}
	
	public convenience init(coords: Vec2<k>) {
		self.init(coordsOverBase: [
			.forward: coords,
			.backward: Vec2(x: k.one - coords.x, y: -coords.y)])
	}
}
