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

  func run(_ args: [String]) {
    guard let command = args.first
    else {
      print("apexSet: expected command")
      exit(1)
    }
    switch command {
      case "list":
        list()
        default:
        print("Unrecognized command '\(command)'")
    }
  }
}
