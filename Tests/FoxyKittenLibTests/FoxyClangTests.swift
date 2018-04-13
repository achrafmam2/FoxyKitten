import Foundation
import Clang
import XCTest
@testable import FoxyKittenLib

class FoxyClangTests: XCTestCase {
  func testInitSingleFile() {
    do {
      let foxy = try FoxyClang(path: "input_tests/foxy-init.c")
      XCTAssertEqual(
        foxy.usrs.map{foxy.definitionCursor(withUsr: $0)!.description}.sorted(),
        ["LCS", "main", "max"])
    } catch {
      XCTFail("\(error)")
    }
  }

  func testInitMultipleFiles() {
    do {
      let foxy = try FoxyClang(path: "input_tests/foxy-init-mult")
      XCTAssertEqual(
        foxy.usrs.map{foxy.definitionCursor(withUsr: $0)!.description}.sorted(),
        ["LCS", "main", "max"])
    } catch {
      XCTFail("\(error)")
    }
  }

  func testGetDependencyGraph() {
    do {
      let foxy = try FoxyClang(path: "input_tests/deps")
      let deps = foxy.getDependencyGraph(of: "c:@F@main")
      XCTAssertEqual(deps.map {"\($0)"}.sorted(),
                     ["print", "max", "LCS", "main"].sorted())
    } catch {
      XCTFail("\(error)")
    }
  }

  func testNumTokens() {
    do {
      let foxy = try FoxyClang(path: "input_tests/foxy-init.c")
      XCTAssertEqual(1, foxy.files.count)
      XCTAssertEqual(131, foxy.numTokens(inFile: foxy.files.first!))
    } catch {
      XCTFail("\(error)")
    }
  }

  func testNumTokensInRange() {
    do {
      let foxy = try FoxyClang(path: "input_tests/foxy-init.c")
      XCTAssertEqual(1, foxy.files.count)

      let start = SourceLocation(
        translationUnit: foxy.units.first!,
        file: foxy.files.first!,
        line: 12, column: 1)

      let end = SourceLocation(
        translationUnit: foxy.units.first!,
        file: foxy.files.first!,
        line: 14, column: 3)

      let range = SourceRange(start: start, end: end)

      XCTAssertEqual(22, foxy.numTokens(inRange: range))
    } catch {
      XCTFail("\(error)")
    }
  }
}
