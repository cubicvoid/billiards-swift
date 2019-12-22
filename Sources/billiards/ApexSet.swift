import Foundation
import BilliardLib

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
    public let count: Int? = nil
    public let density: UInt? = nil

    public init() { }
  }

  public init(elements: [Apex], metadata: Metadata) {
    self.elements = elements
    self.metadata = metadata
  }
}

// A class that manages the directory of named apex sets that we
// use for serialization.
class ApexSetIndex {
  let rootURL: URL

  init(rootURL: URL) throws {
    try FileManager.default.createDirectory(
      at: rootURL, 
      withIntermediateDirectories: true)
    self.rootURL = rootURL
    print("ApexSetIndex initialized with root \(rootURL.description)")
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

  }

  func loadMetadata(name: String) throws -> ApexSet.Metadata {
    let url = urlForName(name).appendingPathComponent("metadata.json")
    let data = try Data(contentsOf: url)
    let decoder = JSONDecoder()
    return try decoder.decode(ApexSet.Metadata.self, from: data)
  }

  func list() throws -> [String: ApexSet.Metadata] {
    let urls = try FileManager.default.contentsOfDirectory(at: rootURL,
      includingPropertiesForKeys:[URLResourceKey.isDirectoryKey])
    var results = [String: ApexSet.Metadata]()
    for url in urls {
      let resourceValues = try url.resourceValues(forKeys: [URLResourceKey.isDirectoryKey])
      let isDirectory = resourceValues.isDirectory!
      if !isDirectory {
        // Apex sets are stored in directories under the root
        continue
      }
      let name = url.lastPathComponent
      results[name] = try loadMetadata(name: name)
    }
    return results
  }
}

func RandomApexesWithGridDensity(_ density: UInt, count: Int) -> [Apex] {
  // 17/24 > sqrt(2)/2 is the radius bound we need to make sure every point is
  // covered by at least one grid point neighborhood.
  let radius = GmpRational(17, over: 24) * GmpRational(1, over: UInt(density))
  return (1...count).map { _ -> Apex in
    let coords = GmpRational.RandomApex(gridDensity: density)
    return Apex(coords, radius: radius)
  }
}
