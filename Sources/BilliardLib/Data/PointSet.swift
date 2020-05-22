import Foundation

public typealias Point = Vec2<GmpRational>

public class PointSet: Codable {
	public let elements: [Point]
	public let metadata: Metadata
	
	public class Metadata: Codable {
		public let count: Int?
		public let density: UInt?
		public let created: Date?

		public init(count: Int?, density: UInt? = nil, created: Date? = nil) {
			self.count = count
			self.density = density
			self.created = created
		}
	}

	public init(elements: [Point], metadata: Metadata) {
		self.elements = elements
		self.metadata = metadata
	}
}


// Helpers for handling point sets
extension DataManager {
	public func loadPointSet(name: String) throws -> PointSet {
		do {
			let metadata: PointSet.Metadata =
				try loadPath(["pointset", name, "metadata.json"])
			let elements: [Point] =
				try loadPath(["pointset", name, "elements.json"])
			return PointSet(elements: elements, metadata: metadata)
		} catch {
			logger.error("Couldn't load point set '\(name)': \(error)")
			throw error
		}
	}

	public func savePointSet(_ pointSet: PointSet, name: String) throws {
		try save(pointSet.elements, toPath: ["pointset", name, "elements.json"])
		try save(pointSet.metadata, toPath: ["pointset", name, "metadata.json"])
	}

	public func listPointSets() throws -> [String: PointSet.Metadata] {
		let pointSetNames = try contentsOfPath(["pointset"]).containers
		var results: [String: PointSet.Metadata] = [:]
		for name in pointSetNames {
			do {
				let metadata: PointSet.Metadata =
					try loadPath(["pointset", name, "metadata.json"])
				results[name] = metadata
			} catch {
				logger.warning("Couldn't load index data for point set \"\(name)\": \(error)")
			}
		}
		return results
	}
}

public func RandomApexesWithGridDensity(_ density: UInt, count: Int) -> PointSet {
	// 17/24 > sqrt(2)/2 is the radius bound we need to make sure every point is
	// covered by at least one grid point neighborhood.
	// let radius = GmpRational(17, over: 24) * GmpRational(1, over: UInt(density))
	let elements = (1...count).map { _ -> Point in
		try! RandomObtuseApex(gridDensity: density)
	}
	let metadata = PointSet.Metadata(
		count: count,
		density: density,
		created: Date())
	return PointSet(elements: elements, metadata: metadata)
}
