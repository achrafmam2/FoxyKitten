import Clang
import ClangUtil
import Matching
import Foundation
import cclang
import ccmark

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

/// Remove Intersecting ranges.
/// In case two ranges intersect keep the largest one.
/// - parameter ranges: A range.
private func removeIntersecting(
  from ranges: [SourceRange]) -> [SourceRange] {
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
  from tupRanges: [(SourceRange, SourceRange)]) -> [(SourceRange, SourceRange)] {

  var tups = tupRanges.sorted { $0.0 < $1.0 }

  var firstPass = [(SourceRange, SourceRange)]()
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
  firstPass = [(SourceRange, SourceRange)]()
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

/// Processes a `FoxyClang` project for the Sherlock analysis.
/// The Sherlock analysis checks for similar substring AST nodes
/// in two projects using a suffix array. The first pass consists of
/// flattening the AST tree. The node's `kind` is used for comparison
/// the `cursors` are used later for extracting other metadate (e.g.,
/// the location of the match ...).
///
/// - parameter proj: A `FoxyClang` project.
///
/// - returns: A tuple (Array of AST node, Array of AST kinds)
private func preprocessForSherlockAnalysis(_ proj: FoxyClang) -> ([Cursor], [String]) {
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

/// Lookup similar occurences in two projects.
/// - parameters:
///   - first: A FoxyClang project.
///   - second: A FoxyClang project.
///   - threshold: The number of common entities (AST nodes) required to be
///       considered a plagiarism.
/// - returns: An array of similarities.
public func runSherlockFoxy(
  _ first: FoxyClang,
  _ second: FoxyClang,
  treshold: Int) -> [Evidence] {

  let (cursors_0, cursorKinds_0) = preprocessForSherlockAnalysis(first)
  let (cursors_1, cursorKinds_1) = preprocessForSherlockAnalysis(second)

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

  let rangeLocation_0 = ranges_0.map { r -> SourceRange  in
    let start = cursors_0[r.lowerBound].range.start
    let end = cursors_0[r.upperBound - 1].range.end
    assert(cursors_0[r.upperBound - 1].isNull == false)
    //    cursors_0[r0].forEach { cursor in
    //      if end.offset < cursor.range.end.offset {
    //        end = cursor.range.end
    //      }
    //    }

    return SourceRange(start: start, end: end)
  }

  let rangeLocation_1 = ranges_1.map { r -> SourceRange  in
    let start = cursors_1[r.lowerBound].range.start
    let end = cursors_1[r.upperBound - 1].range.end
    assert(cursors_1[r.upperBound - 1].isNull == false)
    //    cursors_0[r0].forEach { cursor in
    //      if end.offset < cursor.range.end.offset {
    //        end = cursor.range.end
    //      }
    //    }

    return SourceRange(start: start, end: end)
  }

  let (r0, r1) = unzip(removeNoise(from:
    (0..<ranges_0.count).map {
      return (rangeLocation_0[$0], rangeLocation_1[$0])
  }))

  var similarities = [Evidence]()
  for i in (0..<r0.count) {
    let firstLoc = SourceRange(start: r0[i].start, end: r0[i].end)
    let secondLoc = SourceRange(start: r1[i].start, end: r1[i].end)

    similarities.append(
      Evidence(lhs: EvidenceChunk(location: firstLoc),
            rhs: EvidenceChunk(location: secondLoc)))
  }

  return similarities
}

/// Blames a string using evidence chunks.
/// Blaming consists of delimiting the parts of interest by
/// `{{$}}`. For example: "{{$}} some plagiariased code here {{$}}".
/// The blaming is done after the Sherlock analysis.
/// The blamed string can be easilly highlighted afterwards by looking for
/// the delimiters.
/// - parameters:
///   - str: The string to blame. This is one of the files of a project.
///   - chunks: Plagiarism evidence.
/// - returns: A blamed string.
public func blame(_ str: String, on chunks: [EvidenceChunk]) -> String {
  var tagged = str

  for chunk in chunks.reversed() {
    let file = chunk.location.start.file
    let start = chunk.location.start.offset
    let end = chunk.location.end.offset
    let uuid = chunk.uuid!

    let cStr =
      try! [CChar](String(contentsOfFile: file.name).utf8CString[start ... end]) + [0]
    let pattern = "(" + NSRegularExpression.escapedPattern(for: String(cString: cStr)) + ")"

//        DEBUG SECTION
//        print(">>>>>>>>>>")
//        print(String(cString: cStr))
//        print("<<<<\n")


    let regex = try! NSRegularExpression(
      pattern: pattern, options: [.dotMatchesLineSeparators])

    assert(regex.numberOfCaptureGroups == 1)

    assert(regex.numberOfMatches(
      in: tagged,
      options: [],
      range: NSRange(location: 0, length: tagged.utf16.count)) >= 1)

    tagged = regex.stringByReplacingMatches(
      in: tagged,
      options: [],
      range: NSRange(location: 0, length: tagged.utf16.count),
      withTemplate: "{{\(uuid)}}$1{{\(uuid)}}")

//     DEBUG SECTION
//    let filemanager = FileManager.default
//    filemanager.createFile(
//      atPath: "/tmp/result.html", contents: tagged.data(using: .utf16))

  }

//  DEBUG SECTION
//  let root = cmark_parse_document(tagged, tagged.utf16.count, CMARK_OPT_DEFAULT)
//  let s = cmark_render_html(root, CMARK_OPT_DEFAULT)
//
//  let filemanager = FileManager.default
//  filemanager.createFile(
//    atPath: "/tmp/result.html", contents: String(cString: s!).data(using: .utf16))


  return tagged
}

/// Highlight a blamed string.
/// - parameter str: A blamed string.
public func highlight(
  _ str: String,
  forUUID uuid: UUID,
  withTemplate template: String) -> String {

  let delim = NSRegularExpression.escapedPattern(for: "{{\(uuid)}}")
  let pattern = delim  + "(.*?)" + delim
  let regex = try! NSRegularExpression(
    pattern: pattern,
    options: [.dotMatchesLineSeparators])

  let matches = regex.matches(
    in: str,
    options: [],
    range: NSRange(location: 0, length: str.utf16.count))

  assert(matches.count > 0)

  var s = str
  for match in matches.reversed() {
    let replacement =
      regex.replacementString(for: match,
                              in: s,
                              offset: 0,
                              template: template)

    s.replaceSubrange(s.range(from: match.range)!, with: replacement)
  }

  return s
}

extension String {
  var nsrange: NSRange {
    return NSRange(location: 0, length: utf16.count)
  }

  func range(from nsrange: NSRange) -> Range<Index>? {
    guard let range = Range(nsrange) else { return nil }

    let start = utf16.index(utf16.startIndex, offsetBy: range.lowerBound)
    let end = utf16.index(utf16.startIndex, offsetBy: range.upperBound)

    return start..<end
  }
}

extension SourceRange: Comparable {
  public static func == (lhs: SourceRange, rhs: SourceRange) -> Bool {
    return lhs.start.file.name == rhs.start.file.name &&
      lhs.start.offset == rhs.start.offset && lhs.end.offset == rhs.end.offset
  }

  public static func < (lhs: SourceRange, rhs: SourceRange) -> Bool {
    if lhs.start.file.name == rhs.start.file.name {
      if lhs.start.offset ==  rhs.start.offset {
        return lhs.end.offset < rhs.end.offset
      }
      return lhs.start.offset < rhs.start.offset
    }
    return lhs.start.file.name < rhs.start.file.name
  }

  /// Tells if two `SourceRange`s overlap or not.
  func overlaps(_ other: SourceRange) -> Bool {
    if self.start.file.name != other.start.file.name {
      return false
    }

    let r1 = (start.offset ... end.offset)
    let r2 = (other.start.offset ... other.end.offset)

    return r1.overlaps(r2)
  }

  /// Length of the range in terms of offset.
  var count: Int {
    return (start.offset ... end.offset).count
  }
}

/// Unzip an `Array` of key/value tuples.
///
/// - parameter array: `Array` of key/value tuples.
/// - returns: A tuple with two arrays, an `Array` of keys and an `Array` of values.
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

/// Create a markdown string for an array of files.
/// - parameter files: An array of files (usually part of a project,
///     or an evidence folder).
public func makeMarkdownFrom(_ files: [File]) -> String {
  var markdown = ""
  files.forEach { file in
    let content = try! String(contentsOfFile: file.name)

    markdown += "#### \(file.name)\n\n"
    markdown += "```\n" + content + "```\n"
    markdown += "---\n"
  }
  return markdown
}
