import Foundation
import XCTest
@testable import FoxyKittenLib

class FoxyUtilTests: XCTestCase {
  func testComputeSimilarity() {
    do {
      let inputs = [
        ("input_tests/similarity/prog-0.c",
         "input_tests/similarity/prog-1.c",
         1.0),
        ("input_tests/similarity/prog-2.c",
         "input_tests/similarity/prog-3.c",
         0.521)
      ]

      for input in inputs {
        let p = try FoxyClang(path: input.0)
        let q = try FoxyClang(path: input.1)

        XCTAssertEqual(input.2, computeSimilarity(p, q), accuracy: 0.001)
      }
    } catch {
      XCTFail("\(error)")
    }
  }
}
