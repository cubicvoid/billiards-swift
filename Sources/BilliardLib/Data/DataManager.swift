import Foundation
import Logging


public class DataManager {
	public typealias Path = [String]
	public let rootURL: URL

	let logger: Logger

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
		//print("trying to load url: \(url)")
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
