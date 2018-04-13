import Foundation
import ccmark

/// Delegate called when the html blamer is highlighting the evidence.
public protocol HtmlBlamerDelegate {
  /// Gives a suitable url to use when highlighting a blamed section with an identifier
  /// `id` (e.g: {{some_id_here}}).
  func urlForEvidence(withId id: String) -> String

  /// Gives a suitable target to used when highlighting a blamed sections with an
  /// identifier `id` (e.g: {{some_id_here}}).
  func targetForEvidence(withId id: String) -> String

  /// Gives a suitable CSS style to used when highlighting a blamed sections with an
  /// identifier `id` (e.g: {{some_id_here}}).
  func styleForEvidence(withId id: String) -> String
}

/// Used for rendering source code to html with plagiarised sections
/// highlighted.
public class HtmlBlamer {
  static public var `default` = HtmlBlamer()
  public var chunks: [EvidenceChunk] = []

  public var delegate: HtmlBlamerDelegate?

  public init() { }

  ///  Render source code to html with plagiarised sections highlited.
  /// - parameters:
  ///   - s: Source code.
  ///   - setup: A closure that sets up the delegate and passes it to the blamer.
  /// - returns: Html code.
  public func render(_ s: String, _ setup: (HtmlBlamer) -> Void) -> String {
    // FIXME: throw in case no delegate is set.
    setup(self)

    var str = blame(s, on: chunks)
    str = renderToHtml(str)
    str = highlight(str)

    // Add syntax highliting.
    str += "<script src=\"https://cdn.rawgit.com/google/code-prettify/master/loader/run_prettify.js\"></script>\n"
    let pattern = NSRegularExpression.escapedPattern(for: "<code>")
    let regex = try! NSRegularExpression(pattern: pattern)

    str = regex.stringByReplacingMatches(in: str,
                                         options: [],
                                         range: str.nsrange,
                                         withTemplate: "<code class=\"prettyprint\">")
    return str
  }

  /// Highlight a blamed string, and prettify code.
  /// - parameters:
  ///    - str: A blamed string.
  ///     - options:
  /// - returns: Html
  internal func highlight(_ str: String) -> String {

    let delim = "\\{\\{(.*?)\\}\\}"
    let pattern = delim  + "(.*?)" + delim
    let regex = try! NSRegularExpression(
      pattern: pattern,
      options: [.dotMatchesLineSeparators])

    assert(regex.numberOfCaptureGroups == 3)

    let matches = regex.matches(
      in: str,
      options: [],
      range: NSRange(location: 0, length: str.utf16.count))

    assert(matches.count > 0)

    var s = str
    for match in matches.reversed() {
      let range = str.range(from: match.range(at: 1))
      let id = String(str[range!])

      // FIXME: handle case of no delegate.
      let url = delegate?.urlForEvidence(withId: id)
      let target = delegate?.targetForEvidence(withId: id)
      let style = delegate?.styleForEvidence(withId: id)

      let template =
      "<a href='\(url!)#$1' id='$1' target='\(target!)' style='\(style!)'>$2</a>"
      let replacement =
        regex.replacementString(for: match,
                                in: s,
                                offset: 0,
                                template: template)

      s.replaceSubrange(s.range(from: match.range)!, with: replacement)
    }

    return s
  }


  /// Blames a string using evidence chunks.
  /// Blaming consists of delimiting the parts of interest by
  /// `{{:id}}`. For example: "{{78787}} some plagiariased code here {{78787}}".
  /// The blaming is done after the Sherlock analysis.
  /// The blamed string can be easilly highlighted afterwards by looking for
  /// the delimiters.
  /// - parameters:
  ///   - str: The string to blame. This is one of the files of a project.
  ///   - chunks: Plagiarism evidence.
  /// - returns: A blamed string.
  internal func blame(_ str: String, on chunks: [EvidenceChunk]) -> String {
    var tagged = str

    for chunk in chunks.reversed() {
      let file = chunk.location.start.file
      let start = chunk.location.start.offset
      let end = chunk.location.end.offset
      let uuid = chunk.uuid!

      let cStr =
        try! [CChar](String(contentsOfFile: file.name).utf8CString[start ... end]) + [0]
      let pattern = "(" + NSRegularExpression.escapedPattern(for: String(cString: cStr)) + ")"

      let regex = try! NSRegularExpression(
        pattern: pattern, options: [.dotMatchesLineSeparators])

      assert(regex.numberOfCaptureGroups == 1)

      assert(regex.numberOfMatches(
        in: tagged,
        options: [],
        range: NSRange(location: 0, length: tagged.utf16.count)) >= 1)

      tagged = regex.stringByReplacingMatches(
        in: tagged,
        options: [],
        range: NSRange(location: 0, length: tagged.utf16.count),
        withTemplate: "{{\(uuid)}}$1{{\(uuid)}}")
    }

    return tagged
  }

  internal func renderToHtml(_ s: String) -> String {
    let root = cmark_parse_document(s, s.utf16.count, 0)
    return String(cString: cmark_render_html(root, 0))
  }
}


extension String {
  var nsrange: NSRange {
    return NSRange(location: 0, length: utf16.count)
  }

  func range(from nsrange: NSRange) -> Range<Index>? {
    guard let range = Range(nsrange) else { return nil }

    let start = utf16.index(utf16.startIndex, offsetBy: range.lowerBound)
    let end = utf16.index(utf16.startIndex, offsetBy: range.upperBound)

    return start..<end
  }
}
