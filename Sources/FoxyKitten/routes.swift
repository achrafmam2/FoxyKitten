import FoxyKittenLib
import Routing
import Vapor
import ccmark

/// Create routes to display the evidence.
/// - parameters:
///   - folders: Evidence folders to display.
///   - router: Router to use for routing.
public func routes(folders: [EvidenceFolder], using router: Router) throws {
  // Results page.
  router.get("results") { request -> Future<View> in
    // Creat markdown of the page then convert it to html.
    var out = "## Results\n"
    for folder in folders {
      guard let name = folder.culprit.name else {
        NSLog("folder \(folder.uuid) without a name")
        continue
      }
      let link = String(format: "result/%d", folder.uuid.hashValue)
      out += "- [\(name)](\(link))\n"
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

    let origMarked = mark(
      makeMarkdownFrom(folder.culprit.files),
      on: folder.evidences.map {$0.lhs},
      uiids: folder.evidences.map({$0.uuid}),
      withTemplateFormat: "<a href=\"http://localhost:8080/rhs/\(id)#%@\" id=\"%@\" target=\"rhs\" style=\"background-color: #d5f4e6;\">$1</a>")

    return try request.view().render(template: origMarked.data(using: .utf16)!, .null)
  }

  // Route for the right side (the evidence).
  router.get("rhs", Int.parameter) { request -> Future<View> in
    let id = try request.parameter(Int.self)

    guard let folder = folders.first(where: { $0.uuid.hashValue == id}) else {
      // TODO: return a 404 not found.
      return try request.view().render("")
    }

    let evidenceMarked = mark(
      makeMarkdownFrom(folder.evidenceFiles),
      on: folder.evidences.map {$0.rhs},
      uiids: folder.evidences.map({$0.uuid}),
      withTemplateFormat: "<a href=\"http://localhost:8080/lhs/\(id)#%@\" id=\"%@\" target=\"lhs\" style=\"background-color: #d5f4e6;\">$1</a>")

    return try request.view().render(template: evidenceMarked.data(using: .utf16)!, .null)
  }
}
