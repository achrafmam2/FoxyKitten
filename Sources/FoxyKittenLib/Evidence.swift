import Foundation
import Clang

/// Represents a part of an a evidence.
public struct EvidenceChunk {
  /// Represents the evidence's uuid where this chunk resides.
  public let uuid: UUID?

  /// Represents location evidence.
  public let location: SourceRange

  public init(location: SourceRange) {
    self.location = location
    self.uuid = nil
  }

  public init(location: SourceRange, uuid: UUID) {
    self.location = location
    self.uuid = uuid
  }
}

/// Represents a plagiarism evidence.
/// The two evidence chunks both constitute an evidence.
/// When juxtaposing the left hand side with the right hand side
/// the plagiarism should become obvious.
public struct Evidence {
  /// Represents a unique id.
  public let uuid = UUID()

  /// Represents an evidence part in the left hand side project.
  public let lhs: EvidenceChunk

  /// Represents an evidence part in the right hand side project.
  public let rhs: EvidenceChunk

  public init(lhs: EvidenceChunk, rhs: EvidenceChunk) {
    self.lhs = EvidenceChunk(location: lhs.location, uuid: self.uuid)
    self.rhs = EvidenceChunk(location: rhs.location, uuid: self.uuid)
  }
}

/// Represents all evidences against a file.
public struct EvidenceFolder : Hashable {
  /// Public id for this evidence.
  /// It is almost always guaranteed to be unique.
  public let uuid = UUID()

  /// The cuplprit project.
  public let culprit: FoxyClang

  /// Evidences agains the cuplprit.
  public let evidences: [Evidence]

  /// Files from where the culprit took code.
  public var evidenceFiles: [File] {
    var files = Set<File>()
    evidences.forEach { evidence in
      files.insert(evidence.rhs.location.start.file)
    }
    return files.map {$0}
  }

  /// Percentage plagiarised.
  /// The percentage is calculated based on the number of tokens
  /// plagiarised.
  public var percentPlagiarised: Double {
    let totNumTokens = culprit.files.reduce(0) { (sum, file) -> Int in
      return sum + culprit.numTokens(inFile: file)
    }

    let plagiarizedTokens = evidences.reduce(0) { (sum, evidence) -> Int in
      return sum + culprit.numTokens(inRange: evidence.lhs.location)
    }

    return Double(plagiarizedTokens) / Double(totNumTokens)
  }

  public init(culprit: FoxyClang, evidences: [Evidence]) {
    self.culprit = culprit
    self.evidences = evidences
  }

  public var hashValue: Int {
    return uuid.hashValue
  }

  public static func == (lhs: EvidenceFolder, rhs: EvidenceFolder) -> Bool {
    return lhs.uuid == rhs.uuid
  }
}
