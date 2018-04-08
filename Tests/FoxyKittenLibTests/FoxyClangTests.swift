import Foundation
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
}
