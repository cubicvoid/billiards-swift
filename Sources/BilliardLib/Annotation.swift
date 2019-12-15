import Foundation

public class Annotated {
  let content: Any
  var labels: [String]
  
  init(_ content: Any, _ labels: String...) {
    self.content = content
    self.labels = labels
  }
}

extension Annotated: CustomStringConvertible {
  public var description: String {
    switch content {
    case let csc as CustomStringConvertible:
      return csc.description
    default:
      return "{\(type(of:content))}"
    }
  }
}

public class AnnotatedList {
  var elements: [Annotated]
  
  public init() {
    self.elements = []
  }
  
  public func append(_ elements: Annotated...) {
    self.elements += elements
  }
  
  public func elementsOf<T>(type: T.Type, label:String? = nil) -> [T] {
    var result : [T] = []
    for el in elements {
      if let t = el.content as? T {
        if label == nil || el.labels.contains(label!) {
          result.append(t)
        }
      }
    }
    return result
  }
}

extension AnnotatedList: CustomStringConvertible {
  public var description: String {
    var elementStrings: [String] = []
    for el in elements {
      elementStrings.append(el.description)
    }
    return elementStrings.joined(separator: "\n")
  }
}
