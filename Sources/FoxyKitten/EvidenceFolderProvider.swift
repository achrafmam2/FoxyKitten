import FoxyKittenLib

/// Provides necessary information for the HtmlBlamer to do its work.
struct EvidenceFolderProvider: HtmlBlamerDelegate {
  var url: String
  var target: String
  var styleFromId: [String : String]

  func urlForEvidence(withId id: String) -> String {
    return url
  }

  func targetForEvidence(withId id: String) -> String {
    return target
  }

  func styleForEvidence(withId id: String) -> String {
    return styleFromId[id]!
  }
}
