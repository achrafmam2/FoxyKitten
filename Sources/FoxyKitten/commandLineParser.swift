import Foundation
import Utility
import Basic

/// Represent command line options.
struct CommandLineOptions {
  let windowLength: Int
  let threshold: Int
  let inputPath: String
}

/// Parse Command line arguments.
/// In case of error print usage message.
/// - returns: Command line options or nil in case of error.
func parseCommandLineArguments() -> CommandLineOptions? {
  let parser = ArgumentParser(
    usage: "[window threshold path]",
    overview: "Check plagiarism in C/C++ projects.")

  let windowOption = parser.add(option: "--window", shortName: "-w", kind: Int.self)
  let thresholdOption = parser.add(option: "--threshold", shortName: "-t", kind: Int.self)
  let srcFolderOption = parser.add(option: "--path", shortName: "-path", kind: String.self)

  do {
    let arguments = Array(ProcessInfo.processInfo.arguments.dropFirst())
    let parsedArguments = try parser.parse(arguments)

    if let w    = parsedArguments.get(windowOption),
       let t    = parsedArguments.get(thresholdOption),
       let path = parsedArguments.get(srcFolderOption) {

      return CommandLineOptions(windowLength: w,
                                threshold: t,
                                inputPath: path)
    }
  } catch let error as ArgumentParserError {
    print(error.description)
  } catch let error {
    print(error.localizedDescription)
  }

  parser.printUsage(on: stdoutStream)

  return nil
}
