import Foundation
import BilliardLib
import Logging

class Apex: Codable {
  let coords: Vec2<GmpRational>
  let radius: GmpRational?

  public init(_ coords: Vec2<GmpRational>, radius: GmpRational? = nil) {
    self.coords = coords
    self.radius = radius
  }
}

class ApexSet: Codable {
  public let elements: [Apex]
  public let metadata: Metadata
  
  public class Metadata: Codable {
    public let count: Int?
    public let density: UInt?

    public init(count: Int?, density: UInt? = nil) {
      self.count = count
      self.density = density
      }
  }

  public init(elements: [Apex], metadata: Metadata) {
    self.elements = elements
    self.metadata = metadata
  }
}

// A class that manages the directory of named apex sets that we
// use for serialization.
class ApexSetIndex {
  public let rootURL: URL
  
  private let logger: Logger

  init(rootURL: URL, logger: Logger) throws {
    try FileManager.default.createDirectory(
      at: rootURL, 
      withIntermediateDirectories: true)
    self.rootURL = rootURL
    self.logger = logger
    logger.info("ApexSetIndex initialized with root [\(rootURL.description)]")
  }

  func load(name: String) throws -> ApexSet {
    let metadata = try loadMetadata(name: name)
    let elementsURL = urlForName(name).appendingPathComponent("elements.json")
    let data = try Data(contentsOf: elementsURL)
    let elements = try JSONDecoder().decode([Apex].self, from: data)
    return ApexSet(elements: elements, metadata: metadata)
  }

  func urlForName(_ name: String) -> URL {
    return rootURL.appendingPathComponent(name)
  }

  func save(_ apexSet: ApexSet, name: String) throws {
    let url = urlForName(name)
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false)
    let elementsURL = url.appendingPathComponent("elements.json")
    let metadataURL = url.appendingPathComponent("metadata.json")
    let encoder = JSONEncoder()
    let elements = try encoder.encode(apexSet.elements)
    let metadata = try encoder.encode(apexSet.metadata)
    try elements.write(to: elementsURL)
    try metadata.write(to: metadataURL)
  }

  func loadMetadata(name: String) throws -> ApexSet.Metadata {
    let url = urlForName(name).appendingPathComponent("metadata.json")
    let data = try Data(contentsOf: url)
    let decoder = JSONDecoder()
    return try decoder.decode(ApexSet.Metadata.self, from: data)
  }

  func list() throws -> [String: ApexSet.Metadata] {
    let urls = try FileManager.default.contentsOfDirectory(
      at: rootURL,
      includingPropertiesForKeys:[URLResourceKey.isDirectoryKey])
    var results = [String: ApexSet.Metadata]()
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

func RandomApexesWithGridDensity(_ density: UInt, count: Int) -> ApexSet {
  // 17/24 > sqrt(2)/2 is the radius bound we need to make sure every point is
  // covered by at least one grid point neighborhood.
  let radius = GmpRational(17, over: 24) * GmpRational(1, over: UInt(density))
  let elements = (1...count).map { _ -> Apex in
    let coords = GmpRational.RandomApex(gridDensity: density)
    return Apex(coords, radius: radius)
  }
  let metadata = ApexSet.Metadata(
    count: count,
    density: density)
  return ApexSet(elements: elements, metadata: metadata)
}
