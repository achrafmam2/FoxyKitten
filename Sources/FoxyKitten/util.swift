import Foundation
import FoxyKittenLib
import ccmark


/// Blame, render to html, then highlight the given string
/// on evidence against it.
func mark(
  _ str: String,
  on chunks: [EvidenceChunk],
  uiids: [UUID],
  withTemplateFormat format: String) -> String {

  // Blame the input string.
  var markedStr = blame(str, on: chunks)

  // Render to html.
  let root = cmark_parse_document(
    markedStr, markedStr.utf16.count, CMARK_OPT_DEFAULT)
  markedStr = String(cString: cmark_render_html(root, CMARK_OPT_DEFAULT))

  // Highlight blamed parts.
  for uuid in uiids {
    let template = String(format: format, "\(uuid)", "\(uuid)")
    markedStr = highlight(markedStr, forUUID: uuid, withTemplate: template)
  }

  // Add syntax highliting.
  markedStr += "<script src=\"https://cdn.rawgit.com/google/code-prettify/master/loader/run_prettify.js\"></script>\n"
  let pattern = NSRegularExpression.escapedPattern(for: "<code>")
  let regex = try! NSRegularExpression(pattern: pattern)

  markedStr = regex.stringByReplacingMatches(in: markedStr,
                                             options: [],
                                             range: NSRange(location: 0, length: markedStr.utf16.count),
                                             withTemplate: "<code class=\"prettyprint\">")
  return markedStr
}

/// Concatenate two path components (e.g: `/tmp` + `small/` -> `/tmp/small`)
/// - parameters:
///   - lhs: first part of the path.
///   - rhs: second parth of the path.
func concatenatePaths(_ lhs: String, _ rhs: String) -> String {
  let url = URL(fileURLWithPath: lhs)
  return url.appendingPathComponent(rhs).path
}
