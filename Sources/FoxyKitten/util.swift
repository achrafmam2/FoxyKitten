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

  return markedStr
}
