import Foundation
import BilliardLib
import Dispatch
import Logging


//let apexSet = RandomApexesWithGridDensity(5000000000, count: 100000)
//try! apexSetIndex.save(apexSet, name: "test-100000")

let logger = Logger(label: "me.faec.billiards")
let commands = Commands(logger: logger)
commands.run(Array(CommandLine.arguments[1...]))


//apexSetList()

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