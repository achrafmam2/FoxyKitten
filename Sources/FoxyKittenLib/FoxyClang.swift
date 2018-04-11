import Clang
import Foundation
import cclang
import ccmark

public enum ClangProjectError: Error {
  case pathError
  case empty
}

public class FoxyClang {
  /// Index that contains all translation units of the project.
  private let index = Index()

  /// Project path.
  public let path: String

  /// Translation Units of the project.
  private let units: [TranslationUnit]

  /// Mapping between Usrs and function Definitions.
  private let usrToFunctionDefinition: [String: Cursor]

  /// Represent the name of the project.
  /// It takes the name of the folder project or file project.
  public var name: String? {
    if let last = path.split(separator: "/").last {
      return String(last)
    }
    return nil
  }

  /// Represents the count of functions in the project.
  public var count: Int {
    return self.usrToFunctionDefinition.count
  }

  /// Represents the function usrs in the project.
  public var usrs: [String] {
    return self.usrToFunctionDefinition.map{$0.key}.sorted()
  }

  /// Files that constitute the project.
  public var files: [File] {
    return units.compactMap { unit in
      return unit.getFile(for: unit.spelling)
    }
  }

  /// Gets function definition for given USR.
  /// - parameter usr: USR of the function.
  /// - note: The usrs can be fetched using `functionUsrs`.
  public func definitionCursor(withUsr usr: String) -> Cursor? {
    return self.usrToFunctionDefinition[usr]
  }

  /// Creates a FoxyClang instance.
  /// - parameter path: Path to the Clang project (either file or a directory).
  /// - throws:
  ///   - `ClangProjectError.empty` in case no translation unit can be created.
  ///   - `ClangProjectError.pathError` if the path given does not exist.
  public init(path: String) throws {
    self.path = path
    self.units =
      try FoxyClang.makeTranslationUnits(in: self.path,
                                         withIndex: self.index,
                                         options: .incomplete)
    self.usrToFunctionDefinition =
      FoxyClang.makeMapping(forUnits: self.units, andIndex: self.index)

    // If no translation unit is created.
    if self.units.isEmpty {
      throw ClangProjectError.empty
    }
  }

  /// Returns function definitions for all functions reacheable from `cursor`.
  public func getDependencyGraph(of name: String) -> [Cursor] {
    let cursor = self.usrToFunctionDefinition[name]!

    // Get all dependencies in a depth first traversal.
    func dfs(_ s: Cursor, _ seen: inout Set<String>) {
      // Make sure that it is a definition.
      guard clang_isCursorDefinition(s.asClang()) != 0 && s is FunctionDecl else {
        assertionFailure("dfs(): Trying to get dependency of a non definition of \(s)")
        return
      }

      seen.insert(s.referenced!.usr)

      s.visitChildren { child in
        if child is DeclRefExpr,                            // Is DeclRefExpr
          let ref = child.referenced, ref is FunctionDecl,  // Get its reference
          let def = self.usrToFunctionDefinition[ref.usr],  // Only user defined functions
          !seen.contains(ref.usr) {                         // Not seen before
            dfs(def, &seen)
        }

        return .recurse
      }
    }

    var deps = Set<String>()
    dfs(cursor, &deps)

    return deps.map { self.usrToFunctionDefinition[$0]! }
  }

  // MARK: Private

  /// Concatenates two path components.
  /// - parameters:
  ///   - s: left part of the path.
  ///   - t: right part of the path.
  /// - returns: concatenation of the two paths.
  private static func concatenatePath(_ s: String, _ t: String) -> String {
    var url = URL(fileURLWithPath: s)
    url.appendPathComponent(t)
    return url.path
  }

  /// Makes `TranslationUnits` from source files in the path given.
  /// - parameters:
  ///   - path: Path where the source files reside.
  ///   - index: Index used when building translation units.
  ///   - options: Options passed to the parser.
  /// - returns: An array of `TranslationUnit`s
  /// - note: In case the `path` is a directory, then it is traversed recursively.
  /// - throws: `ClangProjectError.pathError` if the path given does not exist.
  private static func
    makeTranslationUnits(in path: String,
                         withIndex index: Index,
                         options: TranslationUnitOptions = .none) throws -> [TranslationUnit] {
    let filemanager = FileManager.default
    var isDirectory: ObjCBool = false
    guard filemanager.fileExists(atPath: path, isDirectory: &isDirectory) else {
      throw ClangProjectError.pathError
    }

    let filenames = isDirectory.boolValue ?
      try filemanager.subpathsOfDirectory(atPath: path).map {concatenatePath(path, $0)} : [path]

    return filenames.compactMap { filename in
      do {
        return try TranslationUnit(filename: filename,
                                   index: index,
                                   options: options)
      } catch {
        // TODO: Log something here.
        NSLog("\(error): \(filename)")
        return nil
      }
    }
  }

  /// Make a mapping from `Usrs` to function definitions.
  /// - parameters:
  ///   - units: The translation Units from which the mapping will be crated.
  ///   - index: The index used for creating the translation units.
  /// - returns: A dictionnary from USR to function definition (e.g, `String` to `Cursor`).
  static private func makeMapping(forUnits units: [TranslationUnit],
                                  andIndex index: Index) -> [String: Cursor] {
    let indexerCallbacks = Clang.IndexerCallbacks()

    var muttableUsrToDefinition = [String : Cursor]()
    indexerCallbacks.indexDeclaration = { decl in
      guard let cursor = decl.cursor else {
        assertionFailure("makeMapping(): nil cursor")
        return
      }

      /// Check if declaration is from main file.
      guard clang_Location_isFromMainFile(cursor.range.start.asClang()) != 0 else {
        return
      }

      // Check if it's a definition and is a function.
      guard decl.isDefinition && decl.cursor is FunctionDecl else {
        return
      }

      guard let ref = cursor.referenced else {
        assertionFailure("makeMapping(): Definition with no reference")
        return
      }

      assert(!ref.usr.isEmpty,
             "makeMapping(): Reference of function definition is empty.")

      muttableUsrToDefinition[ref.usr] = cursor
    }

    let indexAction = IndexAction(index: index)
    units.forEach { tu in
      try! tu.indexTranslationUnit(indexAction: indexAction,
                                   indexerCallbacks: indexerCallbacks,
                                   options: .none)
    }

    return muttableUsrToDefinition
  }
}
