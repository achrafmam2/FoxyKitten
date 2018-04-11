import Foundation
import Clang
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

  func testBuildAssignementMatrix() {
    do {
      let p = try FoxyClang(path: "input_tests/assignment/prog-0.c")
      let q = try FoxyClang(path: "input_tests/assignment/prog-1.c")
      let options = FoxyOptions(windownSize: 4, followDependencies: true)

      XCTAssertEqual(
        [[4, 4, 1], [4, 6, 1], [1, 1, 1]],
        buildAssignementMatrix(p, q, using: options))

    } catch {
      XCTFail("\(error)")
    }
  }

  func testFoxySherlock() {
    do {
      let p = try FoxyClang(path: "input_tests/similarity/prog-2.c")
      let q = try FoxyClang(path: "input_tests/similarity/prog-3.c")

      let proofs = runSherlockFoxy(p, q, treshold: 17)
      XCTAssertEqual(6, proofs.count)
    } catch {
      XCTFail("\(error)")
    }
  }

  func testMakeMarkdownFrom() {
    do {
      let unit0 = try TranslationUnit(filename: "input_tests/to_markdown/main.c")
      let unit1 = try TranslationUnit(filename: "input_tests/to_markdown/roll.c")

      let file0 = unit0.getFile(for: unit0.spelling)!
      let file1 = unit1.getFile(for: unit1.spelling)!

      XCTAssertEqual(
        try! String(contentsOfFile: "input_tests/to_markdown/golden.in"),
        makeMarkdownFrom([file0, file1]))
    } catch {
      XCTFail("\(error)")
    }
  }
}
