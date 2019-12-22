import Foundation
import BilliardLib
import Dispatch
/*
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
}*/