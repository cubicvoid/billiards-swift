import Foundation
import BilliardLib

typealias k = GmpRational
let edgePath = EdgePath(fromString: "RLRLRL")
let (left, right) =
  PathBoundaryPolynomials(path: edgePath, ringElement: k.one)

let offset = left[left.count - 1] - left[0]
let pairOffset = right[2] - left[1]

let total = -pairOffset.y * offset.x + pairOffset.x * offset.y

print(total.description)

let val = total.evaluate(vars: [k(1, over: 2), k(49, over: 100)])
print("\(val)")
