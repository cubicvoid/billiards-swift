import Foundation

class QueueNode<T> {
  let value: T
  var next: QueueNode<T>?

  init(value: T) {
    self.value = value
  }
}

public class Queue<T> {
  var first: QueueNode<T>?
  var last: QueueNode<T>?

  public init() {
  }

  public func take() -> T? {
    if let firstNode = first {
      first = firstNode.next
      if first == nil {
        last = nil
      }
      return firstNode.value
    }
    return nil
  }

  public func add(_ value: T) {
    let node = QueueNode(value: value)
    if let lastNode = last {
      lastNode.next = node
    } else {
      first = node
    }
    last = node
  }

  public var isEmpty: Bool {
    return first == nil
  }
}

// Simple wrapper to dump a data block to a given filename.
func WriteToFile(_ name: String, _ data: String) {
  let dir = URL(fileURLWithPath: "/Users/fae")
  let path = dir.appendingPathComponent(name)

  //writing
  do {
    try data.write(to: path, atomically: false, encoding: String.Encoding.utf8)
  }
  catch {
    print("Error writing \(name)")
  }
}

extension Field where Self: Comparable {
  // Chooses a random Vec2 that is within the top left quadrant of the
  // radius-1/2 circle centered at (1/2, 0), suitable to use as a triangle apex.
  //
  public static func RandomApex(gridDensity: UInt) -> Vec2<Self> {
    var dx = Self.one
    var dy = Self.one
    var x: Self = Self.zero
    var y: Self = Self.zero
    let numeratorRange = (gridDensity - 1) / 2
    while dx*dx + dy*dy >= Self(1, over: 4) {
      x = Self(RandomUniform(numeratorRange) + 1, over: gridDensity)
      //y = Self(1, over: 1000)
      y = Self(RandomUniform(numeratorRange) + 1, over: gridDensity)
      dx = Self(1, over: 2) - x
      dy = y
    }
    return Vec2(x: x, y: y)
  }
}

public func RandomUniform(_ upperBound: UInt?) -> UInt {
  if upperBound == nil {
    return UInt(arc4random()) * 0x100000000 + UInt(arc4random())
  }
  if upperBound! < UInt32.max {
    return UInt(arc4random_uniform(UInt32(upperBound!)))
  }
  let ub_hi = UInt32(upperBound! >> 32)
  var result = UInt.max
  // This doesn't work if ub_hi is itself UInt32.max
  while result >= upperBound! {
    result =
      UInt(arc4random_uniform(ub_hi+1)) * 0x100000000 + UInt(arc4random())
  }
  return result
}

public func GetTimeOfDay() -> Double {
  var t : timeval = timeval(tv_sec: 0, tv_usec: 0)
  gettimeofday(&t, nil)
  return Double(t.tv_sec) + Double(t.tv_usec) / 1000000.0
}

extension Data {
  public init(fromInputStream stream: InputStream) {
    self.init()
    stream.open()
    let bufferSize = 1024
    let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
    while stream.hasBytesAvailable {
      let read = stream.read(buffer, maxLength: bufferSize)
      self.append(buffer, count: read)
    }
    buffer.deallocate()
    stream.close()
  }

  public func writeToOutputStream(_ stream: OutputStream) -> Bool {
    stream.open()
    defer { stream.close() }
    var written = 0
    while written < self.count {
      let result = self.withUnsafeBytes {
          (ptr: UnsafeRawBufferPointer) -> Int in
        let basePtr = ptr.bindMemory(to: UInt8.self).baseAddress!
        return stream.write(basePtr + written, maxLength: self.count - written)
      }
      if result <= 0 {
        // Couldn't write the whole thing
        return false
      }
      written += result
    }
    return true
  }
}

public func Mod3(_ i : Int) -> Int {
  let v = i % 3
  if v < 0 {
    return v + 3
  }
  return v
}

public func Mod(_ i: Int, by n: Int) -> Int {
  let v = i % n
  if v < 0 {
    return v + n
  }
  return v
}
