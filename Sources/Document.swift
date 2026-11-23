import Foundation

enum TextEncoding: Int, CaseIterable, Codable {
  case ansi, unicode, bigEndian, utf8
  var title: String { ["ANSI (CP-1252)", "UTF-16 LE", "UTF-16 BE", "UTF-8"][rawValue] }
  var encoding: String.Encoding {
    [.windowsCP1252, .utf16LittleEndian, .utf16BigEndian, .utf8][rawValue]
  }
  var marker: Data {
    [Data(), Data([255, 254]), Data([254, 255]), Data([239, 187, 191])][rawValue]
  }
}

struct TextFile: Codable {
  var text = ""
  var encoding = TextEncoding.ansi
  var bom = false
  var newline = "\r\n"

  init() {}
  init(data: Data, forced: TextEncoding? = nil) throws {
    let marked = TextEncoding.allCases.first { !$0.marker.isEmpty && data.starts(with: $0.marker) }
    let detected: TextEncoding =
      String(data: data, encoding: .utf8) != nil && data.contains { $0 >= 128 } ? .utf8 : .ansi
    encoding = forced ?? marked ?? detected
    bom = marked == encoding
    let bytes = bom ? data.dropFirst(encoding.marker.count) : data[...]
    let value: String
    if bytes.isEmpty {
      value = ""
    } else if let decoded = String(data: Data(bytes), encoding: encoding.encoding) {
      value = decoded
    } else {
      throw CocoaError(.fileReadInapplicableStringEncoding)
    }
    if value.contains("\r\n") {
      newline = "\r\n"
    } else if value.contains("\n") {
      newline = "\n"
    } else if value.contains("\r") {
      newline = "\r"
    }
    text = value.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(
      of: "\r", with: "\n")
  }

  func data() throws -> Data {
    let normalized = text.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(
      of: "\r", with: "\n")
    guard
      let bytes = normalized.replacingOccurrences(of: "\n", with: newline).data(
        using: encoding.encoding, allowLossyConversion: false)
    else {
      throw CocoaError(.fileWriteInapplicableStringEncoding)
    }
    return (bom ? encoding.marker : Data()) + bytes
  }
}

/// What a window had not saved when it closed or the app quit: the text on screen and the file it
/// came from, kept on this Mac until the window is opened again.
struct Draft: Codable {
  var id: UUID
  /// The document as last read or saved; `text` is what was on screen.
  var file: TextFile
  var text: String
  var path: String?
  var bookmark: Data?
  var selection: Int
  var frame: String?
  var saved: Date
  /// The process that wrote it, so a second copy of the app running at the same time leaves it to
  /// its owner.
  var process: Int32
}

/// Drafts live in the app's own Application Support folder, one file per window, readable by the
/// user only.
enum DraftStore {
  static var directory: URL = {
    let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    return base.appendingPathComponent("My Notepad/Drafts", isDirectory: true)
  }()

  static func url(for id: UUID) -> URL {
    directory.appendingPathComponent(id.uuidString + ".json")
  }

  static func write(_ draft: Draft) throws {
    let manager = FileManager.default
    try manager.createDirectory(at: directory, withIntermediateDirectories: true,
                                attributes: [.posixPermissions: 0o700])
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    let target = url(for: draft.id)
    try encoder.encode(draft).write(to: target, options: .atomic)
    try? manager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: target.path)
  }

  static func remove(_ id: UUID) {
    try? FileManager.default.removeItem(at: url(for: id))
  }

  /// The drafts left by earlier runs, oldest first, so the newest window ends up in front. Drafts
  /// of another copy of the app still running are left alone; unreadable ones are skipped.
  static func leftovers(isRunning: (Int32) -> Bool) -> [Draft] {
    let names = (try? FileManager.default.contentsOfDirectory(
      at: directory, includingPropertiesForKeys: nil)) ?? []
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return names.filter { $0.pathExtension == "json" }
      .compactMap { try? decoder.decode(Draft.self, from: Data(contentsOf: $0)) }
      .filter { !isRunning($0.process) }
      .sorted { $0.saved < $1.saved }
  }
}
