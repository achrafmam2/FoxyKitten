import Clang
import ClangUtil
import Matching
import Foundation
import cclang

public struct FoxyOptions {
  let windownSize: Int
  let followDependencies: Bool

  public static var `default`: FoxyOptions {
    return FoxyOptions(windownSize: 4, followDependencies: false)
  }
}

/// Extract ngrams using a USR in a project.
/// - parameters:
///   - usr: A valid USR in `p`.
///   - p: A FoxyClang project.
///   - options: Options used to customize extraction
public func extractNgrams(
  from usr: String,
  in p: FoxyClang,
  using options: FoxyOptions) -> [Int] {

  let functions = options.followDependencies ?
    p.getDependencyGraph(of: usr) : [p.definitionCursor(withUsr: usr)!]

  return functions.flatMap { function -> [Int] in
    describeAst(root: function).slices(ofSize: options.windownSize).map {
      $0.joined(separator: " ").hashValue
    }
  }
}

/// Extracts ngrams from a clang project.
/// Only function definitions are used for ngram extraction.
/// - parameters:
///   - p: A FoxyClang project.
///   - options: Options used to customize extraction.
/// - returns: an array of ngram hashes.
public func extractNgrams(from p: FoxyClang, using options: FoxyOptions) -> [Int] {
  // For each function get its features.
  return p.usrs.flatMap { usr -> [Int] in
    return extractNgrams(from: usr, in: p, using: options)
  }
}

/// Computes the average of:
///   - jaccard coefficient:   (|A| ∩ |B|) / (|A| ∪ |B|)
///   - inclusion coefficient: (|A| ∩ |B|) / MIN(|A|, |B|)
///   - coverage coefficient:  (|A| ∩ |B|) / MAX(|A|, |B|)
/// - parameters:
///   - a: Multiset.
///   - b: Multiset.
public func foxyCoefficient<T>(_ a: MultiSet<T>, _ b: MultiSet<T>) -> Double {
  let intersection = Double(a.intersection(b).count)
  let union = Double(a.union(b).count)
  let largest = Double(max(a.count, b.count))
  let smallest = Double(min(a.count, b.count))

  return intersection * ((1.0 / union) + (1.0 / largest) + (1.0 / smallest)) / 3.0
}

/// Computes Similarity between two projects.
/// - parameters:
///   - p: A FoxyClang project.
///   - q: A FoxyClang project.
///   - q: Options used to make computation customizeable.
/// - returns:  A value between 0 and 1.0.
public func computeSimilarity(
  _ p: FoxyClang,
  _ q: FoxyClang,
  using options: FoxyOptions = .default) -> Double {

  let featureSet1 = MultiSet(extractNgrams(from: p, using: options))
  let featureSet2 = MultiSet(extractNgrams(from: q, using: options))

  return foxyCoefficient(featureSet1, featureSet2)
}

/// Build an assignment Matrix between two FoxyClang projects.
/// Each function from both projects are connected with a cost that
/// represents the number of shared ngrams.
/// - parameters:
///   - first: A FoxyClang project.
///   - second: A FoxyClang project.
///   - options: Options used for custom ngram extraction.
/// - note: rows represent the functions from the first project, while the
///     colums represent the function from the second.
public func buildAssignementMatrix(
  _ first: FoxyClang,
  _ second: FoxyClang,
  using options: FoxyOptions) -> [[Int]] {

  // TODO: Make the cost more sophisticated than matching ngrams.
  let n = first.count
  let m = second.count

  var costs = [[Int]](repeating: [Int](repeating: 0, count: m), count: n)
  for i in 0..<n {
    for j in 0..<m {
      let featureSet1 = MultiSet(
        extractNgrams(from: first.usrs[i], in: first, using: options))

      let featureSet2 = MultiSet(
        extractNgrams(from: second.usrs[j], in: second, using: options))

      let common = featureSet1.intersection(featureSet2).count

      costs[i][j] = common
    }
  }

  return costs
}

public struct Similarity {
  /// Represents where similarity occurs.
  let firstLocation: SourceRange

  /// Represents where similarity occurs.
  let secondLocation: SourceRange
}

extension CountableRange: Comparable where CountableRange.Bound == Int {
  public static func < (lhs: CountableRange<Bound>, rhs: CountableRange<Bound>) -> Bool {
    if lhs.lowerBound == rhs.lowerBound {
      return lhs.upperBound < rhs.upperBound
    }
    return lhs.lowerBound < rhs.lowerBound
  }
}

/// Remove Intersecting ranges.
/// In case two ranges intersect keep the largest one.
/// - parameter ranges: A range.
private func removeIntersecting(
  from ranges: [CountableRange<Int>]) -> [CountableRange<Int>] {
  // Sort the ranges.
  let sorted = ranges.sorted()

  guard let first = sorted.first else {
    return []
  }

  // Remove intersecting intervals.
  var nonIntersecting = [first]
  for r in sorted[1...] {
    let last = nonIntersecting.last!
    if r.overlaps(last) {
      if last.count < r.count {
        nonIntersecting.removeLast()
        nonIntersecting.append(r)
      }
    } else {
      nonIntersecting.append(r)
    }
  }

  return nonIntersecting
}

/// Remove Noisy ranges.
/// It removes all ranges that overlap.
private func removeNoise(
  from tupRanges: [(CountableRange<Int>, CountableRange<Int>)]) -> [(CountableRange<Int>, CountableRange<Int>)] {

  var tups = tupRanges.sorted { $0.0 < $1.0 }

  var firstPass = [(CountableRange<Int>, CountableRange<Int>)]()
  var nonIntersecting = Array(removeIntersecting(from: tups.map { $0.0 }).reversed())
  for tup in tups {
    guard let top = nonIntersecting.last else {
      break
    }
    if top == tup.0 {
      firstPass.append(tup)
      nonIntersecting.removeLast()
    }
  }
  assert(nonIntersecting.isEmpty)

  tups = firstPass.map { ($0.1, $0.0) }.sorted { $0.0 < $1.0 }
  firstPass = [(CountableRange<Int>, CountableRange<Int>)]()
  nonIntersecting = Array(removeIntersecting(from: tups.map { $0.0 }).reversed())
  for tup in tups {
    guard let top = nonIntersecting.last else {
      break
    }
    if top == tup.0 {
      firstPass.append(tup)
      nonIntersecting.removeLast()
    }
  }
  assert(nonIntersecting.isEmpty)

  return firstPass.map { ($0.1, $0.0) }
}

private func setupForBlaming(_ proj: FoxyClang) -> ([Cursor], [String]) {
  let cursors = proj.usrs.flatMap { usr -> [Cursor] in
    let def = proj.definitionCursor(withUsr: usr)!
    return [type(of: def).null] + flattenAst(root: def)
  }

  let cursorKinds = cursors.map { cursor in
    return cursor.isNull ?
      UUID().description : clang_getCursorKindSpelling(cursor.asClang().kind).asSwift()
  }

  return (cursors, cursorKinds)
}

/// Blame similar lines in two projects.
/// - parameters:
///   - first: A FoxyClang project.
///   - second: A FoxyClang project.
/// - returns: An array of similarities.
public func blame(
  _ first: FoxyClang,
  _ second: FoxyClang,
  treshold: Int) -> [Similarity] {

  let (cursors_0, cursorKinds_0) = setupForBlaming(first)
  let (cursors_1, cursorKinds_1) = setupForBlaming(second)

  let n = cursorKinds_0.count

  let suffArray = SuffixArray(cursorKinds_0 + ["$"] + cursorKinds_1)

  let order = (0..<suffArray.n).sorted {
    return suffArray.suffixArray[suffArray.m][$0] < suffArray.suffixArray[suffArray.m][$1]
  }

  var ranges_0 = [CountableRange<Int>]()
  var ranges_1 = [CountableRange<Int>]()
  for i in (0..<(order.count - 1)) {
    let lcp = suffArray.lcp(order[i], order[i + 1])
    if lcp >= treshold  {
      var a = 0, b = 0
      if (order[i] < n && order[i + 1] >= n) {
        a = order[i]
        b = order[i + 1] - n - 1
      } else if (order[i] >= n && order[i + 1] < n) {
        a = order[i + 1]
        b = order[i] - n - 1
      } else {
        continue
      }

      let r0 = (a ..< (a + lcp))
      let r1 = (b ..< (b + lcp))

      ranges_0.append(r0)
      ranges_1.append(r1)

    }
  }

  (ranges_0, ranges_1) = unzip(removeNoise(from:
    (0..<ranges_0.count).map {
      return (ranges_0[$0], ranges_1[$0])
  }))

  var similarities = [Similarity]()
  for i in (0..<ranges_0.count) {
    let r0 = ranges_0[i]
    // Get range.
    var start = cursors_0[r0.lowerBound].range.start
    var end = start
    cursors_0[r0].forEach { cursor in
      if end.offset < cursor.range.end.offset {
        end = cursor.range.end
      }
    }
    let firstLoc = SourceRange(start: start, end: end)

    let r1 = ranges_1[i]
    // Get range.
    start = cursors_1[r1.lowerBound].range.start
    end = start
    cursors_1[r1].forEach { cursor in
      if end.offset < cursor.range.end.offset {
        end = cursor.range.end
      }
    }
    let secondLoc = SourceRange(start: start, end: end)

    similarities.append(
      Similarity(firstLocation: firstLoc,
                 secondLocation: secondLoc))
  }

  return similarities
}

/// Unzip an `Array` of key/value tuples.
///
/// - Parameter array: `Array` of key/value tuples.
/// - Returns: A tuple with two arrays, an `Array` of keys and an `Array` of values.
func unzip<K, V>(_ array: [(key: K, value: V)]) -> ([K], [V]) {
  var keys = [K]()
  var values = [V]()

  keys.reserveCapacity(array.count)
  values.reserveCapacity(array.count)

  array.forEach { key, value in
    keys.append(key)
    values.append(value)
  }

  return (keys, values)
}
