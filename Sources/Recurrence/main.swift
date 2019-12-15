import Foundation
import CoreGraphics
import BilliardLib

let applyTransform = false
let recursionDepth = 1
//let apex = Vec2(
//    x: k(1, over: 2),
//    y: k(36327, over: 100000))
//    x: k(65451, over: 100000),
//    y: k(47553, over: 100000))
    //x: k(1001, over: 2000),
    //y: k(999, over: 2000))
//    x: k(70711, over: 100000),
//    y: k(29289, over: 100000))
//    x: k(1, over: 2),
//    y: k(1, over: 2))
let apex = Vec2(
    //x: k(21, over: 50),
    x: k(1, over: 2),
    y: k(1, over: 100))
//let apex = Vec2(x: k(1, over: 2), y: k(866, over: 1000))
/*let apex = Vec2(
  x: k(1, over: 2),
  // we want "almost" an equilateral triangle but we haven't implemented
  // quadratic fields yet :-P
  y:
)*/
// let apex = Vec2(
//   x: k(1, over: 2),
//   y: k(1, over: 5)
// )


func makeTree() -> Tree<Data> {
  //let phaseMap = QuadPhaseMap(apex: apex)
  let phaseMap = DiscPhaseMap(apexOverBase: apex)
  //let phaseMap = MinimalTrianglePhaseMap(apex: apex)

  let flipRegion = SphericalPolygon.fromConstraints([
    Vec3(affineXY: phaseMap.base[.S0]),
    Vec3(affineXY: phaseMap.base[.S1])
  ])
  let rootPolygon = SphericalPolygon<k>.fullSphere
  //let rootPolygon = flipRegion
  //let rootPolygon = SphericalPolygon.fromConstraints([
  //  Vec3(k.zero, k.zero, k.one), Vec3(k.one, k.zero, k.one)])
//  let rootPolygon = SphericalPolygon<k>.fullSphere.withConstraints([
//      phaseMap.vertices[1],
//      -phaseMap.vertices[2],
//      phaseMap.vertices[3]])
  let rootData = Data(
      polygon: rootPolygon,
      transform: Matrix3x3<k>.identity(),
      depth: 0,
      regionIndex: nil, rootIndex: nil,
      flipDepth: nil)
  let root = Tree(data: rootData)

  let regions = phaseMap.regions

  root.subdivide() { parent -> [Data]? in
    if parent.data.depth > recursionDepth {
      return nil
    }
    let parentPolygon = parent.data.polygon
    return regions.keys.compactMap { i -> Data? in
      /*let isFlip =
          parent.data.regionIndex == 1 && i == 2 ||
          parent.data.regionIndex == 2 && i == 1
      var flipDepth: Int? = nil
      if isFlip {
        flipDepth = 0
      } else if let parentFlipDepth = parent.data.flipDepth {
        flipDepth = parentFlipDepth + 1
      }*/
      let region: DiscPhaseMap<k>.Region = regions[i]!
      let childPolygon = parentPolygon.intersect(region.polygon)//regions[i].polygon)
      if childPolygon.isEmpty() {
        return nil
      }
      return Data(
        polygon: region.transform * childPolygon,
        transform: region.transform * parent.data.transform,
        depth: parent.data.depth + 1,
        regionIndex: i,
        rootIndex: parent.data.rootIndex ?? i,
        flipDepth: nil//flipDepth
      )
    }
  }
  return root
}

func renderTree(_ root: Tree<Data>) {
  let frontConstraint = Vec3(x: k.zero, y: k.one, z: k.zero)

  HalfSpheresRender(outputHeight: 4000, filename: "phase.png")
  { (context: CGContext, sign: Sign) in
    for leaf in root.leafs() {
      guard let regionIndex = leaf.data.regionIndex
      else { continue }
      let singularity = regionIndex.singularity
      let turnMagnitude = abs(regionIndex.degree)
      let colorIndex = Mod(leaf.data.rootIndex!.degree, by: colors.count)
      var color: CGColor
      color = colors[colorIndex]//!]
      /*color = CGColor(
        red: 0.4,
        green: 0.2,
        blue: 5.0 / (4.0 + CGFloat(leaf.data.depth)),
        alpha: 1.0)*/
      /*if regionIndex.singularity == .S0 {
        color = CGColor(red: 0.975, green: 0.510, blue: 0.257, alpha: 1.0)
      } else {
        color = CGColor(red: 0.257, green: 0.510, blue: 0.975, alpha: 1.0)
      }*/
      //if turnMagnitude == leaf
      let polygon = applyTransform
          ? leaf.data.polygon
          : leaf.data.transform.inverse()! * leaf.data.polygon

      let clipped = polygon.withConstraint(sign * frontConstraint)
      guard let vertices = clipped.approximateBoundary(anglePrecision: 0.01)
      else { continue }
      let transformed = vertices.map { v in
        // project the ZX plane orthogonally
        Vec2(x: sign * v.z, y: v.x)
      }

      context.beginPath()
      context.move(to: transformed[0].asCGPoint())
      for p in transformed[1...] {
        context.addLine(to: p.asCGPoint())
      }
      context.closePath()

      context.setFillColor(color)
      context.drawPath(using: .fillStroke)
    }
  }
}

func childRatio(_ t: Tree<Data>) {
  guard let children = t.children else { return }
  let area = t.data.polygon.approximateArea() / Double.pi
  let childAreas = children.map {
      child in child.data.polygon.approximateArea() }
  //print("child areas \(childAreas)")
  let childArea = childAreas.reduce(0.0, +) / Double.pi
  print("area \(area) maps to \(children.count) children with area \(childArea)")
  for child in children {
    childRatio(child)
  }
}

extension Tree where NodeData == Data {
  func leafForCoords(
      _ coords: Vec3<k>) -> Tree<NodeData>? {
    if !data.polygon.containsCoords(coords) {
      return nil
    }
    guard let children = self.children else { return self }
    for child in children {
      if child.data.polygon.containsCoords(coords) {
        return child.leafForCoords(coords)
      }
    }
    // this should only happen if the coords are exactly on a boundary or
    // the children are a strict subset of the parent.
    return nil
  }
}

func propagateTrajectory() {
  
  /*let normal = Vec2(k(-9), k.one)
   let offset0 = normal.dot(tri.affineVertices[0])
   let offset1 = normal.dot(tri.affineVertices[1])
   let offset = offset0 + (offset1 - offset0) * k(2, over: 3)
   
   var trajectory = Vec3(x: normal.x, y: normal.y, z: -offset)
   var edgePair = tri.edgePairForLine(trajectory)!
   
   print("trajectory: \(trajectory)")
   print("edge pair: \(edgePair)")
   for i in 0..<5 {
   print("iteration \(i)")
   let reflection = tri.edgeReflections[edgePair.to]
   print("reflection: \(reflection)")
   let newTrajectory = trajectory * reflection
   guard let newEdgePair = tri.edgePairForLine(newTrajectory)
   else {
   print("couldn't find an edge pair for \(newTrajectory)")
   break
   }
   trajectory = newTrajectory
   edgePair = newEdgePair
   print("trajectory: \(trajectory)")
   print("edge pair: \(edgePair)")
   }*/

}

/*let originalArea = leaf.data.polygon.approximateArea()
 let transformedArea =
 (leaf.data.transform * leaf.data.polygon).approximateArea()
 let areaScale = transformedArea / originalArea
 let areaLogScale = 2.0*log(areaScale)
 let brightness = (0.5 + areaLogScale).clamp(min: 0.0, max: 1.0)
 let color = CGColor(gray: CGFloat(brightness), alpha: 1.0)*/
/*var color = CGColor(red: 1.0, green: 0.7, blue: 0.7, alpha: 1.0)
 if let flipDepth = leaf.data.flipDepth {
 let intensity = CGFloat(10.0 / (10.0 + Double(flipDepth)))
 color = CGColor(
 red: intensity / 2.0,
 green: intensity / 2.0,
 blue: intensity, alpha: 1.0)
 }*/

let root = makeTree()
renderTree(root)

