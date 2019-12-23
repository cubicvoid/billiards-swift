import Foundation
import Logging

class Commands {
  let logger: Logger

  init(logger: Logger) {
    self.logger = logger
  }

  func run(_ args: [String]) {
    guard let command = args.first
    else {
      print("Usage: billiards [command]")
      exit(1)
    }
    switch command {
      case "apexSet":
        let apexSetCommands = ApexSetCommands(logger: logger)
        apexSetCommands.run(Array(args[1...]))
      default:
        print("Unrecognized command '\(command)'")
    }
  }
}

public protocol InitializedByString {
  init(_ str: String)
}

func ScanParams(_ args: [String]) -> [String: String] {
  var results: [String: String] = [:]
  for arg in args {
    if let separatorIndex = arg.firstIndex(of: ":") {
      let key = String(arg[..<separatorIndex])
      let valueStart = arg.index(after: separatorIndex)
      let value = String(arg[valueStart...])
      if key != "" {
        results[key] = value
      }
    }
  }
  return results
}

func defaultApexSetName() -> String {
  let formatter = DateFormatter()
  formatter.dateFormat = "yyyyMMdd-HHmmss"
  let dateString = formatter.string(from: Date())
  return "apexes-\(dateString)"
}

class ApexSetCommands {
  let logger: Logger
  let apexSetIndex: ApexSetIndex

  public init(logger: Logger) {
    self.logger = logger
    let path = FileManager.default.currentDirectoryPath
    let dataURL = URL(fileURLWithPath: path).appendingPathComponent("data")
    apexSetIndex = try! ApexSetIndex(
      rootURL: dataURL.appendingPathComponent("apexSet"),
      logger: logger)
  }

  func create(_ args: [String]) {
    let params = ScanParams(args)

    let name = params["name"] ?? defaultApexSetName()
    let countString = params["count"] ?? "100"
    let densityString = params["gridDensity"] ?? "5000000000"

    let count = Int(countString)!
    let density = UInt(densityString)!
    let apexSet = RandomApexesWithGridDensity(density, count: count)
    logger.info("Generated apex set with density: \(density), count: \(count)")
    try! apexSetIndex.save(apexSet, name: name)
  }

  func list() {
    let sets = try! apexSetIndex.list()
    for (name, metadata) in sets {
      var suffix = ""
      if let count = metadata.count {
        suffix = " (\(count))"
      }
      print("\(name)\(suffix)")
    }
  }

  func delete(_ args: [String]) {
    guard let name = args.first
    else {
      print("apexSet delete: expected apex set name")
      exit(1)
    }
    do {
      try apexSetIndex.delete(name: name)
      logger.info("Deleted apex set '\(name)'")
    } catch {
      logger.error("Couldn't delete apex set '\(name)': \(error)")
    }
  }

  func run(_ args: [String]) {
    guard let command = args.first
    else {
      print("apexSet: expected command")
      exit(1)
    }
    switch command {
      case "list":
        list()
      case "delete":
        delete(Array(args[1...]))
      case "create":
        create(Array(args[1...]))
      default:
        print("Unrecognized command '\(command)'")
    }
  }
}
