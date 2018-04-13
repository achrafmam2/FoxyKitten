import FoxyKittenLib
import Routing
import Vapor
import ccmark

/// Setup an Html delegate for an `EvidenceFolder`
/// - parameter folder: An `EvidenceFolder` for which a delegate will be created.
/// - returns: An `HtmlBlamerDelegate`
func setupHtmlDelegate(forFolder folder: EvidenceFolder) -> HtmlBlamerDelegate {
  return EvidenceFolderProvider(
    url: "", target: "", styleFromId: setupStyle(forFolder: folder))
}

/// Setup a CSS style to be used for an `EvidenceFolder`
/// - parameter folder:  An `EvidenceFolder` for which the style will be created.
/// - returns: A dictionnary that maps every `Evidence` to a style.
func setupStyle(forFolder folder: EvidenceFolder) -> [String : String] {
  // TODO: Make the dictionary takes `Evidence`s as keys.
  var styleForId = [String : String]()

  for evidence in folder.evidences {
    // Set the style for that evidence.
    let colors = ["#FFC6BC", "#E5E5E5", "#E0F5FF", "#D6FFFA", "#FFF8F0"]
    let color = colors[Int(arc4random_uniform(UInt32(colors.count)))]
    let cssStyle = "background-color: \(color); text-decoration: none;"

    // Unique identifier of the evidence chunk.
    let id = evidence.uuid.uuidString

    styleForId[id] = cssStyle
  }

  return styleForId
}

/// Create routes to display the evidence.
/// - parameters:
///   - folders: Evidence folders to display.
///   - router: Router to use for routing.
public func routes(folders: [EvidenceFolder], using router: Router) throws {
  // Setup delegates to be used when routing.
  var htmlDelegateForFolder = [EvidenceFolder : HtmlBlamerDelegate]()
  for folder in folders {
    htmlDelegateForFolder[folder] = setupHtmlDelegate(forFolder: folder)
  }

  // Results page.
  router.get("results") { request -> Future<View> in
    // Creat markdown of the page then convert it to html.
    var out = "## Results\n"
    for folder in folders {
      guard let name = folder.culprit.name else {
        NSLog("folder \(folder.uuid) without a name")
        continue
      }
      let link = String(format: "http://localhost:8080/result/%d", folder.uuid.hashValue)
      out += "- [\(name)](\(link))  (\(Int(folder.percentPlagiarised * 100.0)) %)\n"
    }

    let root = cmark_parse_document(out, out.utf16.count, 0)
    let html = String(cString: cmark_render_html(root, 0))
    let htmlData = html.data(using: .utf16)

    return try request.view().render(template: htmlData!, .null)
  }

  // Individual result.
  router.get("result", Int.parameter) { request -> Future<View> in
    let id = try request.parameter(Int.self)

    // TODO: check if id exists.
    let context = TemplateData.dictionary(
      [
        "lhs-link": .string("lhs/\(id)"),
        "rhs-link": .string("rhs/\(id)"),
        ]
    )

    return try request.view().render("result", context)
  }

  // Route for the left side (the culprit)
  router.get("lhs", Int.parameter) { request -> Future<View> in
    let id = try request.parameter(Int.self)

    guard let folder = folders.first(where: { $0.uuid.hashValue == id}) else {
      // TODO: return a 404 not found.
      return try request.view().render("")
    }

    let md = makeMarkdownFrom(folder.culprit.files)
    let template = HtmlBlamer().render(md) { blamer in
      // TODO: Make chunks go through the delegate.
      blamer.chunks = folder.evidences.map { $0.lhs }
      if var delegate = htmlDelegateForFolder[folder] as? EvidenceFolderProvider {
        // FIXME: Some parts of the delegate are custom depending if it will show up
        // on the left or right. It is not clear from the code.
        delegate.url = "http://localhost:8080/rhs/\(id)"
        delegate.target = "rhs"

        blamer.delegate = delegate
      }
    }

    return try request.view().render(template: template.data(using: .utf16)!, .null)
  }

  // Route for the right side (the evidence).
  router.get("rhs", Int.parameter) { request -> Future<View> in
    let id = try request.parameter(Int.self)

    guard let folder = folders.first(where: { $0.uuid.hashValue == id}) else {
      // TODO: return a 404 not found.
      return try request.view().render("")
    }

    let md = makeMarkdownFrom(folder.evidenceFiles)
    let template = HtmlBlamer().render(md) { blamer in
      blamer.chunks = folder.evidences.map { $0.rhs }
      if var delegate = htmlDelegateForFolder[folder] as? EvidenceFolderProvider {
        delegate.url = "http://localhost:8080/lhs/\(id)"
        delegate.target = "lhs"

        blamer.delegate = delegate
      }
    }

    return try request.view().render(template: template.data(using: .utf16)!, .null)
  }
}
