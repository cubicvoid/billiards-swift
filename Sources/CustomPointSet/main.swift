import Foundation
import Logging
import CoreGraphics
import BilliardLib

var points: [Point] = []
let targetY = sqrt(3.0) / 4.0
let delta = 0.1
let oneFourth = GmpRational(1, over: 4)
for i in 1...1000 {
	let yApprox = targetY - delta / Double(i * i)
	let rounded = Int(yApprox * Double(1 << 32))
	let y = GmpRational(rounded, over: 1 << 32)
	points.append(Point(x: oneFourth, y: y))
}

let logger = Logger(label: "me.faec.billiards.CustomPointSet")
let path = FileManager.default.currentDirectoryPath
let dataURL = URL(fileURLWithPath: path).appendingPathComponent("data")
let pointSetManager = try! PointSetManager(
	rootURL: dataURL.appendingPathComponent("pointset"),
	logger: logger)

let metadata = PointSet.Metadata(count: points.count)
let pointSet = PointSet(
	elements: points, metadata: metadata)

try! pointSetManager.save(pointSet, name: "thirty-sixty-ninety")