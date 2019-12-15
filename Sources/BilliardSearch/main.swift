import Foundation
import BilliardLib
import Dispatch

class ApexSet: Codable {
  var minRadius: GmpRational
  var coords: [Vec2<GmpRational>]

  init(count: Int, density: UInt) {
    // 17/24 > sqrt(2)/2 is the radius bound we need to make sure every point is
    // covered by at least one grid point neighborhood.
    minRadius = GmpRational(17, over: 24) * GmpRational(1, over: UInt(density))
    coords = (1...count).map { _ -> Vec2<GmpRational> in
      return GmpRational.RandomApex(gridDensity: density)
    }
  }

  init(failedFromSearchResults results: [FanSearchResult],
       minRadius: GmpRational) {
    self.minRadius = minRadius
    self.coords = (results.filter {$0.cycle == nil}).map {$0.apex}
  }

  init(failedFromSearchResultsApprox results: [FanSearchResultApprox],
       minRadius: GmpRational) {
    self.minRadius = minRadius
    self.coords = (results.filter {$0.cycle == nil}).map {$0.apex}
  }
}

class RunConfig {
  enum RunMode {
    case singleSearch
  }

  var searchConfig: FanSearchConfig = FanSearchConfig()
  var runMode: RunMode = .singleSearch

  // If this run should generate its own random apexes, set apexCount to the
  // number of apexes that should be generated.
  var apexCount: Int?// = 10

  // If this run should load its apexes from a file, set apexFilename to the
  // name of the file.
  var apexFilename: String?

  // When generating random apexes, the number of points in the random grid
  // per unit length. The search config's minRadius parameter will be set based
  // on the grid's dimensions to ensure that any accepted cycle will cover at
  // least the region that is closest to the target grid point.
  var gridDensity: UInt = 2000000000

  init() {
  }
}


func RunConfigFromCommandLine() -> RunConfig {
  var runConfig = RunConfig()

  // Returns the number of arguments it consumed
  func ProcessArgument(_ argument: String, next: String?) -> Int {
    switch argument {
    case "--apexCount":
      if next != nil {
        runConfig.apexCount = Int(next!)
        return 2
      }
    case "--gridDensity":
      if next != nil {
        let gridDensity = UInt(next!)
        if gridDensity != nil {
          runConfig.gridDensity = gridDensity!
        }
        return 2
      }
    case "--apexFilename":
      runConfig.apexFilename = next
      if next != nil {
        return 2
      }
    case "--maxFanCount":
      if next != nil {
        let maxFanCount = Int(next!)
        if maxFanCount != nil {
          runConfig.searchConfig.maxFanCount = maxFanCount!
        }
        return 2
      }
    case "--maxFlipCount":
      if next != nil {
        let maxFlipCount = Int(next!)
        if maxFlipCount != nil {
          runConfig.searchConfig.maxFlipCount = maxFlipCount!
        }
        return 2
      }
    case "--unsafeMath":
      runConfig.searchConfig.unsafeMath = true
    default:
      print("Unknown argument: \(argument)")
    }
    return 1
  }

  let arguments = CommandLine.arguments
  var i = 1
  while i < arguments.count {
    let argument = arguments[i]
    i += ProcessArgument(argument,
                         next: (i+1 < arguments.count) ? arguments[i+1] : nil)
  }
  return runConfig
}

func SaveJson<T: Codable>(_ object: T, toUrl url: URL) {
  let stream = OutputStream(url: url, append: false)!
  let encoder = JSONEncoder()
  //encoder.outputFormatting = .prettyPrinted
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

func SaveSearchResults(
    config: FanSearchConfig, apexes: ApexSet, results: [FanSearchResult]) {
  let formatter = DateFormatter()
  formatter.dateFormat = "yyyyMMdd-HHmmss"
  let dateString = formatter.string(from: Date())
  // TODO: This will fail if two searches are saved at the same second. Pick
  // filenames more carefully.
  let prefix = "billiardsearch-\(dateString)"
  // TODO: Pick a better, more cross-platform target directory.
  let dirPath = "Data"
  let dir = URL(fileURLWithPath: dirPath)
  let configURL = dir.appendingPathComponent("\(prefix).config.json")
  let apexURL = dir.appendingPathComponent("\(prefix).apexes.json")
  let failedApexURL = dir.appendingPathComponent("\(prefix).failed-apexes.json")
  let resultsURL = dir.appendingPathComponent("\(prefix).results.json")
  let successURL = dir.appendingPathComponent("\(prefix).success.csv")
  let failURL = dir.appendingPathComponent("\(prefix).fail.csv")

  let failedApexes = ApexSet(
    failedFromSearchResults: results,
    minRadius: runConfig.searchConfig.minRadius)
  SaveJson(apexes, toUrl: apexURL)
  SaveJson(failedApexes, toUrl: failedApexURL)
  SaveJson(runConfig.searchConfig, toUrl: configURL)

  let minRadius = runConfig.searchConfig.minRadius
  var successStrings: [String] = []
  var failStrings: [String] = []
  for result in results {
    let apex = result.apex
    if result.cycle != nil {
      let radius = result.cycle!.radius
      let ratio = radius / minRadius
      let log2Ratio = log2(ratio.asDouble())
      let pathLength = result.cycle!.path.length
      successStrings.append(
        "\(apex.x.asDouble()),\(apex.y.asDouble())," +
        "\(result.cycle!.path.asString())," +
        "\(pathLength),\(radius),\(log2Ratio)\r\n")
    } else {
      failStrings.append("\(apex.x.asDouble()),\(apex.y.asDouble())\r\n")
    }
  }
  do {
    try successStrings.joined().write(
      to: successURL, atomically: false, encoding: String.Encoding.utf8)
    try failStrings.joined().write(
      to: failURL, atomically: false, encoding: String.Encoding.utf8)
    print("Wrote results to \(dirPath)/\(prefix).*")
  }
  catch {
    NSLog("Error writing search results")
  }
  // Save results last because it's the biggest data blob and thus most
  // likely to make the program explode.
  SaveJson(results, toUrl: resultsURL)
}

func SaveSearchResultsApprox(
    config: FanSearchConfig, apexes: ApexSet,
    results: [FanSearchResultApprox]) {
  let formatter = DateFormatter()
  formatter.dateFormat = "yyyyMMdd-HHmmss"
  let dateString = formatter.string(from: Date())
  // TODO: This will fail if two searches are saved at the same second. Pick
  // filenames more carefully.
  let prefix = "billiardsearchapprox-\(dateString)"
  // TODO: Pick a better, more cross-platform target directory.
  let dirPath = "Data"
  let dir = URL(fileURLWithPath: dirPath)
  let configURL = dir.appendingPathComponent("\(prefix).config.json")
  let apexURL = dir.appendingPathComponent("\(prefix).apexes.json")
  let failedApexURL = dir.appendingPathComponent("\(prefix).failed-apexes.json")
  let resultsURL = dir.appendingPathComponent("\(prefix).results.json")
  let successURL = dir.appendingPathComponent("\(prefix).success.csv")
  let failURL = dir.appendingPathComponent("\(prefix).fail.csv")

  let failedApexes = ApexSet(
    failedFromSearchResultsApprox: results,
    minRadius: runConfig.searchConfig.minRadius)
  SaveJson(apexes, toUrl: apexURL)
  SaveJson(failedApexes, toUrl: failedApexURL)
  SaveJson(runConfig.searchConfig, toUrl: configURL)

  let minRadius = runConfig.searchConfig.minRadius.asDouble()
  var successStrings: [String] = []
  var failStrings: [String] = []
  for result in results {
    let apex = result.apex
    if result.cycle != nil {
      let radius = result.cycle!.radius
      let ratio = radius / minRadius
      let log2Ratio = log2(ratio)
      let pathLength = result.cycle!.path.length
      successStrings.append(
        "\(apex.x.asDouble()),\(apex.y.asDouble())," +
        "\(result.cycle!.path.asString())," +
        "\(pathLength),\(radius),\(log2Ratio)\r\n")
    } else {
      failStrings.append("\(apex.x.asDouble()),\(apex.y.asDouble())\r\n")
    }
  }
  do {
    try successStrings.joined().write(
      to: successURL, atomically: false, encoding: String.Encoding.utf8)
    try failStrings.joined().write(
      to: failURL, atomically: false, encoding: String.Encoding.utf8)
    print("Wrote results to \(dirPath)/\(prefix).*")
  }
  catch {
    NSLog("Error writing search results")
  }
  // Save results last because it's the biggest data blob and thus most
  // likely to make the program explode.
  SaveJson(results, toUrl: resultsURL)
}

let runConfig = RunConfigFromCommandLine()

func LoadApexes(runConfig: RunConfig) throws -> ApexSet? {
  if runConfig.apexFilename != nil {
    let apexUrl = URL(fileURLWithPath: runConfig.apexFilename!)
    let apexStream = InputStream(url: apexUrl)!
    let apexData = Data(fromInputStream: apexStream)
    return try JSONDecoder().decode(ApexSet.self, from: apexData)
  }
  if runConfig.apexCount != nil {
    return ApexSet(count: runConfig.apexCount!, density: runConfig.gridDensity)
  }
  return nil
}

func RunSingleSearch() {
  var found = 0
  var searchResults: [FanSearchResult] = []
  let apexQueue = DispatchQueue(
    label: "me.faec.BilliardSearch.apexQueue",
    attributes: .concurrent)
  let resultsQueue = DispatchQueue(label: "me.faec.BilliardSearch.resultsQueue")
  let apexGroup = DispatchGroup()
  for apex in apexes!.coords {
    apexGroup.enter()
    apexQueue.async {
      let startTime = GetTimeOfDay()

      let cycle = FanPathSearch(apex: apex,
                                config: runConfig.searchConfig)
      let deltaTime = GetTimeOfDay() - startTime
      resultsQueue.sync(flags: .barrier) {
        if cycle != nil {
          found += 1
        }
        searchResults.append(
          FanSearchResult(apex: apex, searchTime: deltaTime, cycle: cycle))
        print("Found \(found) / \(searchResults.count) so far")
      }
      apexGroup.leave()
    }
  }
  let totalStartTime = GetTimeOfDay()
  apexGroup.wait()
  let totalTime = GetTimeOfDay() - totalStartTime

  print("Found \(found) / \(apexes!.coords.count) in \(totalTime) seconds")
  SaveSearchResults(
    config: runConfig.searchConfig, apexes: apexes!, results: searchResults)
}

func RunSingleSearchApprox() {
  var found = 0
  var searchResults: [FanSearchResultApprox] = []
  let apexQueue = DispatchQueue(
    label: "me.faec.BilliardSearch.apexQueue",
    attributes: .concurrent)
  let resultsQueue = DispatchQueue(label: "me.faec.BilliardSearch.resultsQueue")
  let apexGroup = DispatchGroup()
  for apex in apexes!.coords {
    apexGroup.enter()
    apexQueue.async {
      let startTime = GetTimeOfDay()

      let cycle = FanPathSearchApprox(
        apex: apex, config: runConfig.searchConfig)
      let deltaTime = GetTimeOfDay() - startTime
      resultsQueue.sync(flags: .barrier) {
        if cycle != nil {
          found += 1
        }
        searchResults.append(FanSearchResultApprox(
            apex: apex, searchTime: deltaTime, cycle: cycle))
        print("Found \(found) / \(searchResults.count) so far")
      }
      apexGroup.leave()
    }
  }
  let totalStartTime = GetTimeOfDay()
  apexGroup.wait()
  let totalTime = GetTimeOfDay() - totalStartTime

  print("Found \(found) / \(apexes!.coords.count) in \(totalTime) seconds")
  SaveSearchResultsApprox(
    config: runConfig.searchConfig, apexes: apexes!, results: searchResults)
}

let apexes = try LoadApexes(runConfig: runConfig)
if apexes == nil {
  print("Need a source of apex data")
  exit(1)
}
runConfig.searchConfig.minRadius = apexes!.minRadius

switch runConfig.runMode {
case .singleSearch:
  if runConfig.searchConfig.unsafeMath {
    RunSingleSearchApprox()
  } else {
    RunSingleSearch()
  }
}
