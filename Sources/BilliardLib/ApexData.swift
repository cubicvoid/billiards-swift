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
