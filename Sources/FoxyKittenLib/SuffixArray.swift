import Foundation

public struct SuffixArray<T: Comparable> {
  /// Input string.
  let arr: [T]

  /// Suffix array of `str`.
  /// The final order is in `suffixArray[m]`.
  let suffixArray: [[Int]]

  /// Number of characters in `str`
  let n: Int

  /// Represent the ceil of log_2(n).
  let m: Int

  /// Create the suffix array of `s`.
  /// - parameter s: Input string.
  public init(_ s: [T]) {
    arr = s
    n = arr.count
    m = Int(ceil(log2(Double(n))))
    suffixArray = SuffixArray.build(from: arr)
  }

  /// Build suffix array.
  /// - parameter str: Input string.
  /// - returns: suffix array.
  private static func build<T: Comparable>(from arr: [T]) -> [[Int]] {
    let n = arr.count
    let m = Int(ceil(log2(Double(n))))

    var ranks = [(Int, Int, Int)](repeating: (0, 0, 0), count: n)
    var sa = [[Int]](repeating: [Int](repeating: 0, count: n), count: m + 1)

    let sorted = arr.sorted()

    for i in 0..<n {
      var lo = 0, hi = n, idx = -1
      while lo <= hi {
        let mid = (lo + hi) / 2
        if sorted[mid] == arr[i] {
          idx = mid
          hi = mid - 1
        } else if arr[i] < sorted[mid] {
          hi = mid - 1
        } else {
          lo = mid + 1
        }
      }
      assert(idx >= 0)

      sa[0][i] = idx
    }

    for j in 1...m {
      for i in 0..<n {
        let k = i + (1 << (j - 1))
        ranks[i] = (sa[j - 1][i], (k < n) ? sa[j - 1][k] : -1, i)
      }
      ranks.sort { lhs, rhs in
        if lhs.0 == rhs.0 {
          return lhs.1 < rhs.1
        }
        return lhs.0 < rhs.0
      }
      for i in 0..<n {
        if i > 0 && ranks[i].0 == ranks[i - 1].0 && ranks[i].1 == ranks[i - 1].1 {
          sa[j][ranks[i].2] = sa[j][ranks[i - 1].2]
        } else {
          sa[j][ranks[i].2] = i
        }
      }
    }

    return sa
  }
}

extension SuffixArray {
  /// Returns longest common prefix for two suffixes.
  /// - parameters:
  ///   - a : Index of the first suffix.
  ///   - b : Index of the second suffix.
  public func lcp(_ a: Int, _ b: Int) -> Int {
    // TODO: throw in case `a` or `b` are out of range.
    var size = 0, x = a, y = b
    for j in (0..<m).reversed() {
      if suffixArray[j][x] == suffixArray[j][y] {
        size += (1 << j)
        x += (1 << j)
        y += (1 << j)
      }
      if x >= n || y >= n {
        break
      }
    }
    return size
  }
}

extension SuffixArray where T == Character {
  /// Build suffix array from a string.
  /// - parameter str: A String.
  public init(_ str: String) {
    let arr = str.map {$0}
    self.init(arr)
  }
}
