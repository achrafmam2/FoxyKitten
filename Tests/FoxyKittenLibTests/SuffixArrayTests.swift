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
}
