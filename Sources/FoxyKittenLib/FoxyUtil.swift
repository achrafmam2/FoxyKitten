import Clang
import ClangUtil
import Matching

struct FoxyOptions {
  let windownSize: Int
  let followDependencies: Bool

  static var `default`: FoxyOptions {
    return FoxyOptions(windownSize: 4, followDependencies: false)
  }
}

/// Extract ngrams using a USR in a project.
/// - parameters:
///   - usr: A valid USR in `p`.
///   - p: A FoxyClang project.
///   - options: Options used to customize extraction
func extractNgrams(
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
func extractNgrams(from p: FoxyClang, using options: FoxyOptions) -> [Int] {
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
func foxyCoefficient<T>(_ a: MultiSet<T>, _ b: MultiSet<T>) -> Double {
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
func computeSimilarity(
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
func buildAssignementMatrix(
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
