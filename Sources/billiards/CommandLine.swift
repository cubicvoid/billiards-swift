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
      case "pointset":
        let pointSetCommands = PointSetCommands(logger: logger)
        pointSetCommands.run(Array(args[1...]))
      default:
        print("Unrecognized command '\(command)'")
    }
  }
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

func defaultPointSetName() -> String {
  let formatter = DateFormatter()
  formatter.dateFormat = "yyyyMMdd-HHmmss"
  let dateString = formatter.string(from: Date())
  return "points-\(dateString)"
}

class PointSetCommands {
  let logger: Logger
  let pointSetManager: PointSetManager

  public init(logger: Logger) {
    self.logger = logger
    let path = FileManager.default.currentDirectoryPath
    let dataURL = URL(fileURLWithPath: path).appendingPathComponent("data")
    pointSetManager = try! PointSetManager(
      rootURL: dataURL.appendingPathComponent("pointset"),
      logger: logger)
  }

  func cmd_create(_ args: [String]) {
    let params = ScanParams(args)

    let name = params["name"] ?? defaultPointSetName()
    let countString = params["count"] ?? "100"
    let densityString = params["gridDensity"] ?? "5000000000"

    let count = Int(countString)!
    let density = UInt(densityString)!
    let pointSet = RandomApexesWithGridDensity(density, count: count)
    logger.info("Generated point set with density: \(density), count: \(count)")
    try! pointSetManager.save(pointSet, name: name)
  }

  func cmd_list() {
    let sets = try! pointSetManager.list()
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .short
    dateFormatter.timeStyle = .short
    dateFormatter.locale = .current
    dateFormatter.timeZone = .current
    let sortedNames = sets.keys.sorted(by: { (a: String, b: String) -> Bool in
      return a.lowercased() < b.lowercased()
    })
    for name in sortedNames {
      guard let metadata = sets[name]
      else { continue }
      var line = name
      if let count = metadata.count {
        line += " (\(count))"
      }
      if let created = metadata.created {
        let localized = dateFormatter.string(from: created)
        line += " \(localized)"
      }
      print(line)
    }
  }

  func cmd_print(_ args: [String]) {
    let params = ScanParams(args)

    guard let name = params["name"]
    else {
      print("pointset print: expected name\n")
      return
    }
    let pointSet = try! pointSetManager.load(name: name)
    for p in pointSet.elements {
      print("\(p.x),\(p.y)")
    }
  }

  func cmd_plot(_ args: [String]) {

  }

  func cmd_delete(_ args: [String]) {
    guard let name = args.first
    else {
      print("pointset delete: expected point set name")
      exit(1)
    }
    do {
      try pointSetManager.delete(name: name)
      logger.info("Deleted apex set '\(name)'")
    } catch {
      logger.error("Couldn't delete point set '\(name)': \(error)")
    }
  }

  func run(_ args: [String]) {
    guard let command = args.first
    else {
      print("pointset: expected command")
      exit(1)
    }
    switch command {
      case "list":
        cmd_list()
      case "print":
        cmd_print(Array(args[1...]))
      case "delete":
        cmd_delete(Array(args[1...]))
      case "create":
        cmd_create(Array(args[1...]))
      case "plot":
        cmd_plot(Array(args[1...]))
      default:
        print("Unrecognized command '\(command)'")
    }
  }
}
