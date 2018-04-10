import FoxyVapor
import Service
import Vapor
import Foundation
import FoxyKittenLib
import ccmark

// Parse CommandLine arguments.
if CommandLine.argc != 4 {
  print("Usage: [window srcFolder]")
  exit(EXIT_SUCCESS)
}

let w = Int(CommandLine.arguments[1])!
let treshold = Int(CommandLine.arguments[2])!
let srcFolder = CommandLine.arguments[3]

print("window = \(w)")
print("treshold = \(treshold)")
print("srcFolder = \(srcFolder)")
print("")

// Read projects.
let filemanager = FileManager.default
// TODO: Handle gracefully the case of an invalid `srcFolder`.
let paths = try! filemanager.contentsOfDirectory(atPath: srcFolder)

var projects = [FoxyClang]()
for path in paths {
  print(path, terminator: " ... ")
  do {
    // TODO: Handle concatenation of two paths.
    let fullPath = srcFolder + "/" + path
    let proj = try FoxyClang(path: fullPath)
    projects.append(proj)

    print("parsed succesfully.")
  } catch {
    print("\(error).")
  }
}

// Make directory where to store the results.
let resultUUID = UUID()
print("\nResult Id: \(resultUUID.uuidString)\n")
let resultsFolder = "/tmp/" + resultUUID.uuidString
// TODO: Handle the case it is impossible to create a directory.
try! filemanager.createDirectory(atPath: resultsFolder, withIntermediateDirectories: true)

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
                               treshold: treshold)


  let folder = EvidenceFolder(culprit: orig_proj, evidences: evidences)
  folders.append(folder)


//  let filename = resultsFolder + "/" + orig_proj.name! + ".html"
////  print(filename)
//
//  var blamed = blame(makeMarkdownFrom(orig_proj.files), on: chunks)
//  let root = cmark_parse_document(blamed, blamed.utf16.count, CMARK_OPT_DEFAULT)
//  blamed = String(cString: cmark_render_html(root, CMARK_OPT_DEFAULT))
//  blamed = highlight(blamed)
//
//  assert(filemanager.createFile(
//    atPath: filename,
//    contents: blamed.data(using: .utf16)))
}

for folder in folders {
  let culpritFiles = folder.culprit.files
  let evidenceFiles = folder.evidenceFiles
  let name = folder.culprit.name!

  let origMarked = mark(
    makeMarkdownFrom(culpritFiles),
    on: folder.evidences.map {$0.lhs},
    uiids: folder.evidences.map({$0.uuid}),
    withTemplateFormat: "<a href=\"\(name)-rhs#%@\" id=\"%@\">$1</a>")


  let evidenceMarked = mark(
    makeMarkdownFrom(evidenceFiles),
    on: folder.evidences.map {$0.rhs},
    uiids: folder.evidences.map({$0.uuid}),
    withTemplateFormat: "<a href=\"\(name)-rhs#%@\" id=\"%@\">$1</a>")

// DEBUG SESSION
  var filename = "\(resultsFolder)/\(name)-lhs.html"
  assert(filemanager.createFile(
    atPath: filename,
    contents: origMarked.data(using: .utf16)))

  filename = "\(resultsFolder)/\(name)-rhs.html"
  assert(filemanager.createFile(
    atPath: filename,
    contents: evidenceMarked.data(using: .utf16)))
}

// The contents of main are wrapped in a do/catch block because any errors that get raised to the top level will crash Xcode
do {
  var config = Config.default()
  var env = try Environment.detect(arguments: [CommandLine.arguments[0]])
  var services = Services.default()

  try FoxyVapor.configure(&config, &env, &services)

  let app = try Application(
    config: config,
    environment: env,
    services: services
  )

  try FoxyVapor.boot(app)

  try app.run()
} catch {
  print(error)
  exit(1)
}
