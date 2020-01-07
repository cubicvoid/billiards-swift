import Foundation
import BilliardLib
import Logging

typealias Point = Vec2<GmpRational>

class PointSet: Codable {
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
class PointSetManager {
  public let rootURL: URL
  
  private let logger: Logger

  init(rootURL: URL, logger: Logger) throws {
    try FileManager.default.createDirectory(
      at: rootURL, 
      withIntermediateDirectories: true)
    self.rootURL = rootURL
    self.logger = logger
    logger.info("PointSetManager initialized with root [\(rootURL.description)]")
  }

  func urlForName(_ name: String) -> URL {
    return rootURL.appendingPathComponent(name)
  }

  func load(name: String) throws -> PointSet {
    do {
      let metadata = try loadMetadata(name: name)
      let elementsURL = urlForName(name).appendingPathComponent("elements.json")
      let data = try Data(contentsOf: elementsURL)
      let elements = try JSONDecoder().decode([Point].self, from: data)
      return PointSet(elements: elements, metadata: metadata)
    } catch {
      logger.error("Couldn't load apex set '\(name)': \(error)")
      throw error
    }
  }

  func save(_ pointSet: PointSet, name: String) throws {
    do {
      let url = urlForName(name)
      try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false)
      let elementsURL = url.appendingPathComponent("elements.json")
      let metadataURL = url.appendingPathComponent("metadata.json")
      let encoder = JSONEncoder()
      let elements = try encoder.encode(pointSet.elements)
      let metadata = try encoder.encode(pointSet.metadata)
      try elements.write(to: elementsURL)
      try metadata.write(to: metadataURL)
      logger.info("Saved apex set '\(name)'")
    } catch {
      logger.error("Couldn't save apex set '\(name)': \(error)")
      throw error
    }
  }

  func delete(name: String) throws {
    let url = urlForName(name)
    try FileManager.default.removeItem(at: url)
  }

  func loadMetadata(name: String) throws -> PointSet.Metadata {
    let url = urlForName(name).appendingPathComponent("metadata.json")
    let data = try Data(contentsOf: url)
    let decoder = JSONDecoder()
    return try decoder.decode(PointSet.Metadata.self, from: data)
  }

  func list() throws -> [String: PointSet.Metadata] {
    let urls = try FileManager.default.contentsOfDirectory(
      at: rootURL,
      includingPropertiesForKeys:[URLResourceKey.isDirectoryKey])
    var results = [String: PointSet.Metadata]()
    for url in urls {
      let name = url.lastPathComponent
      do {
        let resourceValues = try url.resourceValues(forKeys: [URLResourceKey.isDirectoryKey])
        let isDirectory = resourceValues.isDirectory!
        if !isDirectory {
          // Apex sets are stored in directories under the root
          continue
        }
        let metadata = try loadMetadata(name: name)
        results[name] = metadata
      } catch {
        logger.warning("Couldn't load index data for apex set \"\(name)\": \(error)")
      }
    }
    return results
  }
}

func RandomApexesWithGridDensity(_ density: UInt, count: Int) -> PointSet {
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
