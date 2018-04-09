import Foundation
import Clang

/// Represents a part of an a evidence.
public struct EvidenceChunk {
  /// Represents location evidence.
  public let location: SourceRange
}

/// Represents a plagiarism evidence.
/// The two evidence chunks both constitute an evidence.
/// When juxtaposing the left hand side with the right hand side
/// the plagiarism should become obvious.
public struct Evidence {
  /// Represents an evidence part in the left hand side project.
  public let lhs: EvidenceChunk

  /// Represents an evidence part in the right hand side project.
  public let rhs: EvidenceChunk
}

/// Represents all evidences against a file.
public struct EvidenceFolder {
  /// The cuplprit project.
  public let culpritProject: FoxyClang

  /// Evidences agains the cuplprit.
  public let evidences: [Evidence]

  /// Files from where the culprit took code.
  var evidenceFiles: [File] {
    var files = Set<File>()
    evidences.forEach { evidence in
      files.insert(evidence.rhs.location.start.file)
    }
    return files.map {$0}
  }
}
