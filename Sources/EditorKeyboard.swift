import AppKit

/// Windows editing commands that differ from the standard macOS text bindings.
final class EditorTextView: NSTextView {
  private var keyboardAnchor: Int?

  override func setSelectedRanges(
    _ ranges: [NSValue], affinity: NSSelectionAffinity, stillSelecting: Bool
  ) {
    keyboardAnchor = nil
    super.setSelectedRanges(ranges, affinity: affinity, stillSelecting: stillSelecting)
  }

  func handleEditingKey(_ event: NSEvent) -> Bool {
    let modifiers = event.modifierFlags.intersection([.control, .shift, .option, .command])
    let extending = modifiers.contains(.shift)
    let control = modifiers.contains(.control)
    guard modifiers.isSubset(of: [.control, .shift]), !hasMarkedText() else { return false }
    switch event.keyCode {
    case 114 where modifiers == .control: copy(nil)
    case 114 where modifiers == .shift: paste(nil)
    case 117 where modifiers == .shift: cut(nil)
    case 51, 117:
      guard modifiers == .control else { return false }
      if selectedRange().length == 0 {
        move(
          to: wordBoundary(from: selectedRange().location, forward: event.keyCode == 117),
          extending: true)
      }
      if selectedRange().length > 0 { insertText("", replacementRange: selectedRange()) }
    case 123, 124, 125, 126, 115, 119:
      let forward = [124, 125, 119].contains(event.keyCode)
      let cursor = activeCursor()
      let text = string as NSString
      let destination: Int
      switch event.keyCode {
      case 123, 124:
        guard control else { return false }
        destination = wordBoundary(from: cursor, forward: forward)
      case 125, 126:
        guard control else { return false }
        let line = text.lineRange(for: NSRange(location: cursor, length: 0))
        if forward {
          destination = NSMaxRange(line)
        } else if cursor == line.location && cursor > 0 {
          destination = text.lineRange(for: NSRange(location: cursor - 1, length: 0)).location
        } else {
          destination = line.location
        }
      default:
        if control {
          destination = forward ? text.length : 0
        } else {
          if forward {
            if extending { moveToEndOfLineAndModifySelection(nil) } else { moveToEndOfLine(nil) }
          } else {
            if extending {
              moveToBeginningOfLineAndModifySelection(nil)
            } else {
              moveToBeginningOfLine(nil)
            }
          }
          return true
        }
      }
      move(to: destination, extending: extending)
    default: return false
    }
    return true
  }

  private func activeCursor() -> Int {
    let range = selectedRange()
    if let anchor = keyboardAnchor, range.length > 0 {
      return anchor == range.location ? NSMaxRange(range) : range.location
    }
    if range.length > 0 && selectionAffinity == .upstream { return range.location }
    return NSMaxRange(range)
  }

  private func move(to destination: Int, extending: Bool) {
    let range = selectedRange()
    let cursor = activeCursor()
    let anchor = keyboardAnchor ?? (cursor == range.location ? NSMaxRange(range) : range.location)
    let start = extending ? anchor : destination
    let selection = NSRange(location: min(start, destination), length: abs(start - destination))
    setSelectedRange(
      selection, affinity: destination < start ? .upstream : .downstream, stillSelecting: false)
    keyboardAnchor = extending ? anchor : nil
    scrollRangeToVisible(NSRange(location: destination, length: 0))
  }

  private func wordBoundary(from cursor: Int, forward: Bool) -> Int {
    // Windows stops at the start of the next word, including intervening spaces
    // in a forward selection. AppKit's double-click ranges respect Unicode.
    guard let storage = textStorage else { return cursor }
    let text = storage.mutableString
    var pos = cursor
    func isSpace(_ index: Int) -> Bool {
      guard let scalar = UnicodeScalar(text.character(at: index)) else { return false }
      return CharacterSet.whitespaces.contains(scalar)
    }
    if forward {
      guard pos < text.length else { return pos }
      if !isSpace(pos) { pos = NSMaxRange(storage.doubleClick(at: pos)) }
      while pos < text.length && isSpace(pos) { pos += 1 }
    } else {
      while pos > 0 && isSpace(pos - 1) { pos -= 1 }
      if pos > 0 { pos = storage.doubleClick(at: pos - 1).location }
    }
    return pos
  }
}
