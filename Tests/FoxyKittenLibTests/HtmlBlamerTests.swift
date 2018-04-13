import XCTest
import Clang
import Foundation
@testable import FoxyKittenLib

class HtmlBlamerTests: XCTestCase {
  func testBlameAllFile() {
    do {
      let filename = "input_tests/highlighting/highlight.c"
      let tu = try TranslationUnit(filename: filename)
      let content = try String(contentsOfFile: filename)

      // Blame the whole file.
      let range = tu.cursor.range
      let uiidstring = "E621E1F8-C36C-495A-93FC-0C247A3E6E5F"
      let evidence = EvidenceChunk(location: range, uuid: UUID(uuidString: uiidstring)!)

      let expected = """
{{E621E1F8-C36C-495A-93FC-0C247A3E6E5F}}#include <stdio.h>

int main(void) {
  int a, b;
  return 0;
}
{{E621E1F8-C36C-495A-93FC-0C247A3E6E5F}}
"""
      XCTAssertEqual(expected, HtmlBlamer.default.blame(content, on: [evidence]))

    } catch {
      XCTFail("\(error)")
    }
  }

  func testBlamePartsOfFile() {
    do {
      let filename = "input_tests/highlighting/highlight.c"
      let tu = try TranslationUnit(filename: filename)
      let content = try String(contentsOfFile: filename)

      // Blame the whole file.
      let file = tu.getFile(for: tu.spelling)!

      let start1 = SourceLocation(translationUnit: tu, file: file, offset: 0)
      let end1 = SourceLocation(translationUnit: tu, file: file, offset: 17)
      let range1 = SourceRange(start: start1, end: end1)
      let uiidstring1 = "E621E1F8-C36C-495A-93FC-0C247A3E6E5F"
      let evidence1 = EvidenceChunk(location: range1, uuid: UUID(uuidString: uiidstring1)!)

      let start2 = SourceLocation(translationUnit: tu, file: file, line: 4, column: 1)
      let end2 = SourceLocation(translationUnit: tu, file: file, line: 4, column: 11)
      let range2 = SourceRange(start: start2, end: end2)
      let uiidstring2 = "ACD1E1F8-C36C-495A-93FC-0C247A3E6E5F"
      let evidence2 = EvidenceChunk(location: range2, uuid: UUID(uuidString: uiidstring2)!)

      let expected = """
{{E621E1F8-C36C-495A-93FC-0C247A3E6E5F}}#include <stdio.h>{{E621E1F8-C36C-495A-93FC-0C247A3E6E5F}}

int main(void) {
{{ACD1E1F8-C36C-495A-93FC-0C247A3E6E5F}}  int a, b;{{ACD1E1F8-C36C-495A-93FC-0C247A3E6E5F}}
  return 0;
}

"""
      XCTAssertEqual(expected, HtmlBlamer.default.blame(content, on: [evidence1, evidence2]))

    } catch {
      XCTFail("\(error)")
    }
  }

  func testHighlight() {
    let s = """
{{123}} one lineer {{123}}
{{ac-12}} spans over many lines
goes
till here {{ac-12}}
"""

    let expected = """
<a href='foxy#123' id='123' target='__blank' style='background-color: #d5f4e6;'> one lineer </a>
<a href='kitten#ac-12' id='ac-12' target='__blank' style='background-color: #a6ffe6;'> spans over many lines
goes
till here </a>
"""

    struct Delegate: HtmlBlamerDelegate {
      func urlForEvidence(withId id: String) -> String {
        return ["123": "foxy",
                "ac-12": "kitten"][id]!
      }

      func targetForEvidence(withId id: String) -> String {
        return ["123": "__blank",
                "ac-12": "__blank"][id]!
      }

      func styleForEvidence(withId id: String) -> String {
        return ["123": "background-color: #d5f4e6;",
                "ac-12": "background-color: #a6ffe6;"][id]!
      }
    }

    let blamer = HtmlBlamer.default
    blamer.delegate = Delegate()

    XCTAssertEqual(expected, HtmlBlamer.default.highlight(s))
  }
}
