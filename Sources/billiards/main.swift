import Foundation
import BilliardLib
import Dispatch
import Logging

let logger = Logger(label: "me.faec.billiards")
let path = FileManager.default.currentDirectoryPath
let dataURL = URL(fileURLWithPath: path).appendingPathComponent("data")
let apexSetIndex = try! ApexSetIndex(
  rootURL: dataURL.appendingPathComponent("apexSet"),
  logger: logger)

let apexSet = RandomApexesWithGridDensity(5000000000, count: 100000)
try! apexSetIndex.save(apexSet, name: "test-100000")
//print(path)
//let apexSetIndex = ApexSetIndex("")

/*let runConfig = RunConfigFromCommandLine()

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
*/