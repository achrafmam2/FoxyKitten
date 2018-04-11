import FoxyVapor
import Service
import Vapor
import Foundation
import FoxyKittenLib
import ccmark
import Utility
import Basic

let executableName = CommandLine.arguments[0]

guard let cmdOptions = parseCommandLineArguments() else {
  exit(EXIT_SUCCESS)
}

let w = cmdOptions.windowLength
let threshold = cmdOptions.threshold
let inputPath = cmdOptions.inputPath

print("window = \(w)")
print("treshold = \(threshold)")
print("path = \(inputPath)")
print("")

// Read projects.
var projects = [FoxyClang]()
do {
  let filemanager = FileManager.default
  let paths = try filemanager.contentsOfDirectory(atPath: inputPath)

  for path in paths {
    print(path, terminator: " ... ")
    do {
      let fullPath = concatenatePaths(inputPath, path)
      let proj = try FoxyClang(path: fullPath)
      projects.append(proj)

      print("parsed succesfully.")
    } catch {
      print("\(error).")
    }
  }
} catch {
  print(error.localizedDescription)
  exit(EXIT_FAILURE)
}

// Make directory where to store the results.
let resultUUID = UUID()
print("\nResult Id: \(resultUUID.uuidString)\n")

// Process projects.
var folders = [EvidenceFolder]()
for id in (0..<projects.count) {
  let orig_proj = projects[id]

  let (value, closest_project) = projects.map { other -> (Double, FoxyClang) in
    if other === orig_proj {
      return (0.0, other)
    }

    let value = computeSimilarity(orig_proj, other)
    return (value, other)
  }.max { $0.0 < $1.0 }!

  print("\(orig_proj.path) \(closest_project.path) \(value)")

  let evidences = runSherlockFoxy(orig_proj,
                               closest_project,
                               treshold: threshold)


  let folder = EvidenceFolder(culprit: orig_proj, evidences: evidences)
  folders.append(folder)
}

// The contents of main are wrapped in a do/catch block because any errors that get raised to the top level will crash Xcode
do {
  var config = Config.default()
  var env = try Environment.detect(arguments: [executableName])
  var services = Services.default()

  try FoxyVapor.configure(&config, &env, &services)

  // Register routes to the router
  let router = EngineRouter.default()
  //try routes(router)
  services.register(router, as: Router.self)

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

  // Lhs
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
      withTemplateFormat: "<a href=\"http://localhost:8080/rhs/\(id)#%@\" id=\"%@\" target=\"rhs\">$1</a>")

    return try request.view().render(template: origMarked.data(using: .utf16)!, .null)
  }

  // Rhs
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
      withTemplateFormat: "<a href=\"http://localhost:8080/lhs/\(id)#%@\" id=\"%@\" target=\"lhs\">$1</a>")

    return try request.view().render(template: evidenceMarked.data(using: .utf16)!, .null)
  }

  let app = try Application(
    config: config,
    environment: env,
    services: services
  )

  try app.run()
} catch {
  print(error)
  exit(1)
}
