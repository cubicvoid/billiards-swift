import Foundation
import Logging

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

// A class that manages the directory of named apex sets that we
// use for serialization.
public class DataManager {
	public let rootURL: URL
	private let logger: Logger
	public typealias Path = [String]

	public init(rootURL: URL, logger: Logger) throws {
    let pointsetURL = rootURL.appendingPathComponent("pointset")
		try FileManager.default.createDirectory(
			at: pointsetURL, 
			withIntermediateDirectories: true)
		self.rootURL = rootURL
		self.logger = logger
		logger.info("DataManager initialized with root [\(rootURL.description)]")
	}

	private func urlForPath(_ path: Path) -> URL {
		return path.reduce(rootURL) {
			$0.appendingPathComponent($1)
		}
	}

	public func save<T: Codable>(
		_ thing: T, toPath path: Path
	) throws {
		do {
			if path.count > 0 {
				// create the containing directory if needed
				let pathPrefix = Array(path[..<(path.count - 1)])
				try FileManager.default.createDirectory(
					at: urlForPath(pathPrefix),
					withIntermediateDirectories: true)
			}
			let url = urlForPath(path)
			let encoder = JSONEncoder()
			let contents = try encoder.encode(thing)
			try contents.write(to: url)
			logger.info("Saved: \(path)")
		} catch {
			logger.error("Couldn't save data to path '\(path)': \(error)")
			throw error
		}
	}

	public func deletePath(_ path: Path) throws {
		let url = urlForPath(path)
		try FileManager.default.removeItem(at: url)
	}

	public func loadPath<T: Codable>(_ path: Path) throws -> T {
		let url = urlForPath(path)
		let data = try Data(contentsOf: url)
		let decoder = JSONDecoder()
		return try decoder.decode(T.self, from: data)
	}

	public struct Contents {
		let containers: [String]
		let files: [String]
	}

	public func contentsOfPath(_ path: Path) throws -> Contents {
		let contents = try FileManager.default.contentsOfDirectory(
			at: urlForPath(path),
			includingPropertiesForKeys:[URLResourceKey.isDirectoryKey])
		var containers: [String] = []
		var files: [String] = []
		for url in contents {
			let name = url.lastPathComponent
			let resourceValues = try url.resourceValues(forKeys: [URLResourceKey.isDirectoryKey])
			let isDirectory = resourceValues.isDirectory!
			if isDirectory {
				containers.append(name)
			} else {
				files.append(name)
			}
		}
		return Contents(containers: containers, files: files)	
	}
}

// Extra helpers for handling point sets
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
