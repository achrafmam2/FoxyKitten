import Foundation

/// Represents a set with duplicates.
public struct MultiSet<T: Hashable>: Sequence {
  /// Keeps the count of elements.
  private var elementsCount = [T : Int]()

  /// Represents the number of elements in the container.
  public var count = 0

  /// Constructs a multiset from an comma separated list.
  public init(arrayLiteral: T...) {
    self.init(arrayLiteral)
  }

  /// Constructs a multiset from an array.
  public init(_ arr: [T]) {
    for e in arr {
      elementsCount[e] = (elementsCount[e] ?? 0) + 1
      count += 1
    }
  }

  /// Constructs an empty multiset.
  public init() {}

  /// Adds a new element to the multiset.
  /// - parameter newElement: Element to add to the multiset.
  public mutating func add(_ newElement: T) {
    elementsCount[newElement] = (elementsCount[newElement] ?? 0) + 1
    count += 1
  }

  /// Removes a single occurence the passed element.
  /// - parameter member: Element to delete.
  /// - returns: True in case of success, false otherwise.
  @discardableResult public mutating func remove(_ member: T) -> Bool {
    guard elementsCount[member] != nil else {
      return false
    }

    elementsCount[member] = elementsCount[member]! - 1
    if elementsCount[member] == 0 {
      elementsCount.remove(at: elementsCount.index(forKey: member)!)
    }
    count -= 1

    return true
  }

  /// Creates an intersection of two multiset.
  /// - parameter other: A multiset.
  /// - returns: Intersection of two multisets.
  public func intersection(_ other: MultiSet) -> MultiSet {
    var ret = MultiSet()
    for (element, count) in elementsCount {
      let m = Swift.min(count, other.elementsCount[element] ?? 0)
      (0..<m).forEach { _ in ret.add(element) }
    }
    return ret
  }

  /// Creates a unions of two multiset.
  /// If an element `e` is repeated `x` times in multiset A, and `y` times in multiset B,
  /// where `x` <= `y`, then in the union element `e` will be repeated `y` times.
  /// - parameter other: A multiset.
  /// - returns: Union of two multisets.
  public func union(_ other: MultiSet) -> MultiSet {
    var ret = MultiSet()

    var all = Set<T>()

    for (element, _) in self.elementsCount {
      all.insert(element)
    }

    for (element, _) in other.elementsCount {
      all.insert(element)
    }

    for element in all {
      let m =
        Swift.max(self.elementsCount[element] ?? 0, other.elementsCount[element] ?? 0)
      (0..<m).forEach { _ in ret.add(element) }
    }
    
    return ret
  }

  /// Makes an iterator.
  public func makeIterator() -> MultiSetIterator<T> {
    return MultiSetIterator(self.elementsCount)
  }
}


/// Represents a multiset iterator.
public struct MultiSetIterator<T: Hashable>: IteratorProtocol {
  public typealias Element = T

  /// Represents the multiset elements.
  let map: [T: Int]

  /// Dictionary iterator.
  var iterator: Dictionary<T, Int>.Iterator

  /// Current key pointed by the iterator.
  var currentKey: T?

  /// Number of times remaining before to move to next element.
  var rem = 0

  /// Constructs a `MultiSetIterator` from a dictionnary of count.
  init(_ map: [T: Int]) {
    self.map = map
    self.iterator = map.makeIterator()
  }

  /// Get next element of the sequence.
  mutating public func next() -> MultiSetIterator<T>.Element? {
    guard let key = currentKey, rem > 0 else {
      guard let element = iterator.next() else {
        return nil
      }

      currentKey = element.key
      rem = element.value
      return next()
    }

    rem -= 1
    return key
  }
}
