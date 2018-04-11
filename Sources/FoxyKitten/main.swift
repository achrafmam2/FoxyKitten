import FoxyKittenLib
import Service
import Vapor
import Foundation
import FoxyKittenLib
import ccmark
import Utility
import Basic
import Leaf

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

  try FoxyKitten.configure(&config, &env, &services)

  // Register routes to the router.
  let router = EngineRouter.default()
  services.register(router, as: Router.self)
  try routes(folders: folders, using: router)

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
