import Foundation
import BilliardLib

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
/*
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
*/