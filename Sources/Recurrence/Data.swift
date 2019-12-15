import BilliardLib

class Data: CustomStringConvertible {
  // this node represents the transformation of
  // (transform^-1 polygon) by transform to polygon, by successively
  // selecting the subregion in regionIndex and performing the respective
  // reflection.
  // typealias RegionIndex = Int
  typealias RegionIndex = Singularity.Turn
  let polygon: SphericalPolygon<k>
  let transform: Matrix3x3<k>
  let depth: Int
  let regionIndex: RegionIndex?
  let rootIndex: RegionIndex?
  let flipDepth: Int?
  
  init(polygon: SphericalPolygon<k>,
       transform: Matrix3x3<k>,
       depth: Int,
       regionIndex: RegionIndex?, rootIndex: RegionIndex?,
       flipDepth: Int?) {
    self.polygon = polygon
    self.depth = depth
    self.regionIndex = regionIndex
    self.rootIndex = rootIndex
    self.transform = transform
    self.flipDepth = flipDepth
  }
  
  public var description: String {
    if let regionIndex = self.regionIndex {
      return "(regionIndex: \(regionIndex), transform: \(transform))"
    }
    return "(root, transform: \(transform))"
  }
}
