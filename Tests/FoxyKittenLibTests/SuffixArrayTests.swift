import Foundation
import XCTest
@testable import FoxyKittenLib

class SuffixArrayTests: XCTestCase {
  func testBuild() {
    let sa = SuffixArray("abac")
    XCTAssertEqual([0, 2, 1, 3], sa.suffixArray.last!)
  }

  func testLCP() {
    let sa = SuffixArray("abac")
    XCTAssertEqual(1, sa.lcp(0, 2))
    XCTAssertEqual(0, sa.lcp(0, 1))
  }

  func testBuil1() {
    let sa = SuffixArray("abracadabra0AbRa4Cad14abra")
    XCTAssertEqual([11, 20, 16, 21, 12, 17, 14, 25, 10, 15, 22, 7, 0, 3, 18, 5,
                    13, 23, 8, 1, 4, 19, 6, 24, 9, 2],
                   (0..<sa.n).sorted {
                      sa.suffixArray.last![$0] < sa.suffixArray.last![$1]
                    }
    )
  }
}
