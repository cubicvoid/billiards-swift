public class ApexData<k: Field & Comparable> {
	// coords is the main input parameter. It is specified relative to the base
	// edge from (0,0) to (1,0), and thus for our purposes is usually in the range
	// 0 < x < 1 and 0 < y < 1/2, though values outside that range are still valid
	// whenever they make sense.
	public let coords: Vec2<k>
	public let r: S2<k>

	public let rotation: S2<UnitPowerCache<k>>
	

	public init(radii: S2<k>) {
		self.r = radii
		self.coords = Vec2(
			x: r[.S0] / (r[.S0] + r[.S1]),
			y: k.one / (r[.S0] + r[.S1]))
		self.rotation = radii.map {r in
			UnitPowerCache(fromSquareRoot: Vec2(r, k.one))
		}
	}

	public convenience init(apex: Vec2<k>) {
		let r = S2(apex.x / apex.y, (k.one - apex.x) / apex.y)
		self.init(radii: r)
	}
}
