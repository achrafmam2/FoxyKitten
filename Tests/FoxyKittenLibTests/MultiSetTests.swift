import Foundation
import XCTest
@testable import FoxyKittenLib

class MultiSetTests: XCTestCase {
  func testInit() {
    let set = MultiSet<Int>(arrayLiteral: 1, 2, 3, 5, 10, 10, 10)
    XCTAssertEqual([1, 2, 3, 5, 10, 10, 10], set.map{$0}.sorted())
  }

  func testAdd() {
    var set = MultiSet<String>()
    set.add("marco")
    XCTAssertEqual(["marco"], set.map{$0}.sorted())
    set.add("marco")
    XCTAssertEqual(["marco", "marco"], set.map{$0}.sorted())
    set.add("luffy")
    XCTAssertEqual(["luffy", "marco", "marco"], set.map{$0}.sorted())
  }

  func testRemove() {
    var set = MultiSet<String>()
    set.add("marco")
    set.remove("marco")
    XCTAssertEqual([], set.map{$0}.sorted())
    XCTAssertEqual(0, set.count)

    set.add("marco")
    set.add("marco")
    set.add("doffy")
    set.remove("marco")
    XCTAssertEqual(["doffy", "marco"], set.map{$0}.sorted())
    XCTAssertEqual(2, set.count)
  }

  func testIntersection() {
    let set1 = MultiSet<String>(arrayLiteral: "arigato", "durara", "durara", "miao")
    let set2 = MultiSet<String>(arrayLiteral: "luffy", "durara", "miao", "boum")

    XCTAssertEqual(["durara", "miao"], set1.intersection(set2).map{$0}.sorted())
  }

  func testUnion() {
    let set1 = MultiSet<String>(arrayLiteral: "arigato", "durara", "durara", "miao")
    let set2 = MultiSet<String>(arrayLiteral: "luffy", "durara", "miao", "zebra", "boum")

    XCTAssertEqual(["arigato", "boum", "durara", "durara", "luffy", "miao", "zebra"],
                   set1.union(set2).map{$0}.sorted())

  }
}
