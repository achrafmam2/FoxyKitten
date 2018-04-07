import ClangUtil

struct FoxyOptions {
  let windownSize: Int

  static var `default`: FoxyOptions {
    return FoxyOptions(windownSize: 4)
  }
}

/// Extracts ngrams from a clang project.
/// Only function definitions are used for ngram extraction.
/// - parameters:
///   - p: A FoxyClang project.
///   - options: Options used to cutumize extraction.
/// - returns: an array of ngram hashes.
func extractNgram(from p: FoxyClang, using options: FoxyOptions) -> [Int] {
  // For each function get its features.
  return p.functionUsrs.flatMap { usr -> [Int] in
    guard let def = p.functionDefinition(withUsr: usr) else {
      assertionFailure("Could not materialize a function definition from usr.")
      return []
    }

    // Flatten ast and get all windows.
    return describeAst(root: def).slices(ofSize: options.windownSize).compactMap {
      $0.joined(separator: " ").hashValue
    }
  }
}

/// Computes Similarity between two projects.
/// - parameters:
///   - p: A FoxyClang project.
///   - q: A FoxyClang project.
///   - q: Options used to make computation custumizable.
/// - returns:  A value between 0 and 1.0.
func computeSimilarity(
  _ p: FoxyClang,
  _ q: FoxyClang,
  using options: FoxyOptions = .default) -> Double {

  let featureSet1 = MultiSet(extractNgram(from: p, using: options))
  let featureSet2 = MultiSet(extractNgram(from: q, using: options))

  let intersection = Double(featureSet1.intersection(featureSet2).count)
  let union = Double(featureSet1.union(featureSet2).count)
  let largest = Double(max(featureSet1.count, featureSet2.count))
  let smallest = Double(min(featureSet1.count, featureSet2.count))

  return intersection * ((1.0 / union) + (1.0 / largest) + (1.0 / smallest)) / 3.0
}
