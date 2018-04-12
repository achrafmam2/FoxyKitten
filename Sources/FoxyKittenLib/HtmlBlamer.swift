import Foundation
import ccmark

/// Hyperlink options used when blaming, and highliting.
public struct HyperLinkTagOptions {
  /// The url used in the hyperlink tag.
  public let url: String

  /// The target used in the hyperlink tag.
  public let target: String

  /// Css style to be used in the hyperlink tag.
  public let style: String

  public init(url: String, target: String, style: String = "background-color: #d5f4e6;") {
    self.url = url
    self.target = target
    self.style = style
  }
}

/// Used for rendering source code to html with plagiarised sections
/// highlighted.
public class HtmlBlamer {
  static public var `default` = HtmlBlamer()
  public var hyperlinkTagOptions: HyperLinkTagOptions = HyperLinkTagOptions(url: "", target: "")
  public var chunks: [EvidenceChunk] = []

  public init() { }

  ///  Render source code to html with plagiarised sections highlited.
  /// - parameters:
  ///   - s: Source code.
  ///   - setup: closure function that initializes the `chunks` and
  ///       the `hyperlinkTagOptions`.
  /// - returns: Html code.
  public func render(_ s: String, _ setup: (HtmlBlamer) -> Void) -> String {
    setup(self)

    var str = blame(s, on: chunks)
    str = renderToHtml(str)
    str = highlight(str, options: hyperlinkTagOptions)

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
  internal func highlight(
    _ str: String,
    options: HyperLinkTagOptions) -> String {

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
      let template =
      "<a href='\(options.url)#$1' id='$1' target='\(options.target)' style='\(options.style)'>$2</a>"
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
