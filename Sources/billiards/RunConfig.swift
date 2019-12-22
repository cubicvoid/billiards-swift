import Foundation
import BilliardLib

/*class RunConfig {
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

  func LoadApexes() throws -> ApexSet? {
    if apexFilename != nil {
      let apexUrl = URL(fileURLWithPath: apexFilename!)
      let apexStream = InputStream(url: apexUrl)!
      let apexData = Data(fromInputStream: apexStream)
      return try JSONDecoder().decode(ApexSet.self, from: apexData)
    }
    if apexCount != nil {
      return RandomApexesWithGridDensity(gridDensity, count: apexCount!)
    }
    return nil
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
}*/

