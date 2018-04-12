import Foundation
import FoxyKittenLib
import ccmark

/// Concatenate two path components (e.g: `/tmp` + `small/` -> `/tmp/small`)
/// - parameters:
///   - lhs: first part of the path.
///   - rhs: second parth of the path.
func concatenatePaths(_ lhs: String, _ rhs: String) -> String {
  let url = URL(fileURLWithPath: lhs)
  return url.appendingPathComponent(rhs).path
}
