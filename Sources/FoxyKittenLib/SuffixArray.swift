import Foundation

struct SuffixArray {
  /// Input string.
  let str: [CChar]

  /// Suffix array of `str`.
  /// The final order is in `suffixArray[m]`.
  let suffixArray: [[Int]]

  /// Number of characters in `str`
  let n: Int

  /// Represent the ceil of log_2(n).
  let m: Int

  /// Create the suffix array of `s`.
  /// - parameter s: Input string.
  init(_ s: String) {
    str = [CChar](s.utf8CString)
    n = str.count - 1
    m = Int(ceil(log2(Double(n))) + 1e-11)
    suffixArray = SuffixArray.build(from: str)
  }

  /// Build suffix array.
  /// - parameter str: Input string.
  /// - returns: suffix array.
  private static func build(from str: [CChar]) -> [[Int]] {
    let n = str.count - 1
    let m = Int(ceil(log2(Double(n))) + 1e-11)

    var ranks = [(Int, Int, Int)](repeating: (0, 0, 0), count: n)
    var sa = [[Int]](repeating: [Int](repeating: 0, count: n), count: m + 1)

    for i in 0..<n {
      sa[0][i] = Int(str[i])
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
  func lcp(_ a: Int, _ b: Int) -> Int {
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
