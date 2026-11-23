import Foundation

enum TextEncoding: Int, CaseIterable {
  case ansi, unicode, bigEndian, utf8
  var title: String { ["ANSI (CP-1252)", "UTF-16 LE", "UTF-16 BE", "UTF-8"][rawValue] }
  var encoding: String.Encoding {
    [.windowsCP1252, .utf16LittleEndian, .utf16BigEndian, .utf8][rawValue]
  }
  var marker: Data {
    [Data(), Data([255, 254]), Data([254, 255]), Data([239, 187, 191])][rawValue]
  }
}

struct TextFile {
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
