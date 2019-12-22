import Foundation
import BilliardLib
import Dispatch

let path = FileManager.default.currentDirectoryPath
let dataURL = URL(fileURLWithPath: path).appendingPathExtension("Data")
let apexSetIndex = try! ApexSetIndex(rootURL: dataURL.appendingPathExtension("apexSet"))
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