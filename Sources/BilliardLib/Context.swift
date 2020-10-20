public class BilliardsContext<k: Field & Comparable> {
	// coords is the main input parameter. It is specified relative to the base
	// edge from (0,0) to (1,0), and thus for our purposes is usually in the range
	// 0 < x < 1 and 0 < y < 1/2, though values outside that range are still valid
	// whenever they make sense.
	public let coords: Vec2<k>
	public let r: BaseValues<k>

	public let rotation: BaseValues<UnitPowerCache<k>>
	

	public init(radii: BaseValues<k>) {
		self.r = radii
		self.coords = Vec2(
			x: r[.B0] / (r[.B0] + r[.B1]),
			y: k.one / (r[.B0] + r[.B1]))
		self.rotation = radii.map {(r: k) -> UnitPowerCache<k> in
			UnitPowerCache(fromSquareRoot: Vec2(r, k.one))
		}
	}

	public convenience init(apex: Vec2<k>) {
		let r = BaseValues(apex.x / apex.y, (k.one - apex.x) / apex.y)
		self.init(radii: r)
	}
}
