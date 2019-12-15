import Foundation
import BilliardLib
import Dispatch

let apex = Vec2(x: GmpRational(21, over: 50), y: GmpRational(37, over: 100))
//let apex = Vec2(x: 0.42, y: 0.37)
//let apex = Vec2(x: 0.22, y: 0.01)
let params = BilliardsParamsDeprecated(apex: apex)

FeasiblePathStats(params: params, maxDepth: 50, maxFlips: 1)
/*
let root = FeasiblePathNode(rootForParams: params)
let children = root.children()
print("Got \(children.count) children")
*/
//let vr = TryFeasibleVectorRange()
//print("\(vr)")
