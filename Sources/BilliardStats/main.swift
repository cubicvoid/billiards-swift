import Foundation
import BilliardLib
import Dispatch
/*
class ApexSet: Codable {
  var minRadius: GmpRational
  var coords: [Vec2<GmpRational>]

  init(count: Int, density: UInt) {
    // 17/24 > sqrt(2)/2 is the radius bound we need to make sure every point is
    // covered by at least one grid point neighborhood.
    minRadius = GmpRational(17, over: 12) * GmpRational(1, over: UInt(density))
    coords = (1...count).map { _ -> Vec2<GmpRational> in
      return GmpRational.RandomApex(gridDensity: density)
    }
  }

  init(fromFile filename: String) {
    // TODO
    minRadius = GmpRational.zero
    coords = []
  }

  init(failedFromSearchResults results: [SearchResult],
       minRadius: GmpRational) {
    self.minRadius = minRadius
    self.coords = (results.filter {$0.cycle == nil}).map {$0.apex}
  }
}

func SaveJson<T: Codable>(_ object: T, toUrl url: URL) {
  let stream = OutputStream(url: url, append: false)!
  let encoder = JSONEncoder()
  encoder.outputFormatting = .prettyPrinted
  var written = false
  do {
    let data = try encoder.encode(object)
    written = data.writeToOutputStream(stream)
  }
  catch { }
  if !written {
    print("Error: Couldn't write to \(url)")
  }
}

func SaveSearchResults(minRadius: GmpRational, results: [SearchResult]) {
  let dir = URL(fileURLWithPath: ".")
  let successURL = dir.appendingPathComponent("stats.csv")

  var successStrings: [String] = []
  //var verified = 0
  for result in results {
    let apex = result.apex
    if result.cycle != nil {
      //let radius = VerifiedRadiusForPath(result.cycle!.path, withApex: apex)
      let radius = result.cycle!.radius
      if radius < minRadius {
        print("Error: \(result.cycle!.path) could not be verified")
        continue
      }
      let ratio = radius / minRadius
      let log2Ratio = log2(ratio.asDouble())
      let pathLength = result.cycle!.path.length
      successStrings.append(
        "\(apex.x.asDouble()),\(apex.y.asDouble())," +
        "\(result.cycle!.path.asString())," +
        "\(pathLength),\(radius),\(log2Ratio)\r\n")
    }
  }
  do {
    try successStrings.joined().write(
      to: successURL, atomically: false, encoding: String.Encoding.utf8)
    print("minRadius: \(minRadius.asDouble())")
    print("Wrote results to stats.csv")
  }
  catch {
    NSLog("Error writing search results")
  }
}

func LoadApexes(filename: String) throws -> ApexSet? {
  let apexUrl = URL(fileURLWithPath: filename)
  let apexStream = InputStream(url: apexUrl)!
  let apexData = Data(fromInputStream: apexStream)
  return try JSONDecoder().decode(ApexSet.self, from: apexData)
}

func LoadResults(filename: String) throws -> [SearchResult]? {
  let resultsUrl = URL(fileURLWithPath: filename)
  let resultsStream = InputStream(url: resultsUrl)!
  let resultsData = Data(fromInputStream: resultsStream)
  return try JSONDecoder().decode([SearchResult].self, from: resultsData)
}

let arguments = CommandLine.arguments
let minRadius = GmpRational(fromString: "17/1200000000000000")
var allResults: [SearchResult] = []
for prefix in arguments[1...] {
  let resultsPath = "/home/fae/billiards/results/\(prefix).results.json"
  let results = try! LoadResults(filename: resultsPath)
  if results != nil {
    allResults += results!
  }
}

SaveSearchResults(minRadius: minRadius, results: allResults)
*/