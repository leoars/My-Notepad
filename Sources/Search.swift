import AppKit

extension Notepad {
  func select(_ range: NSRange) {
    editor.setSelectedRange(range)
    editor.scrollRangeToVisible(range)
  }
  func findNext() {
    guard !query.isEmpty else {
      searchPanel(false)
      return
    }
    let s = editor.string as NSString
    let sel = editor.selectedRange()
    let range =
      backwards
      ? NSRange(location: 0, length: sel.location)
      : NSRange(location: NSMaxRange(sel), length: s.length - NSMaxRange(sel))
    var options: NSString.CompareOptions = [.literal]
    if !matchCase { options.insert(.caseInsensitive) }
    if backwards { options.insert(.backwards) }
    let match = s.range(of: query, options: options, range: range)
    if match.location == NSNotFound {
      alert(String(format: L("find.missing"), query))
    } else {
      select(match)
    }
  }
  func searchPanel(_ replace: Bool) {
    finder?.panel.close()
    let controller = FinderPanel(owner: self, replacing: replace)
    finder = controller
    controller.show()
  }
}

final class FinderPanel: NSObject {
  unowned let owner: Notepad
  let replacing: Bool
  let panel = NSPanel(
    contentRect: .zero, styleMask: [.titled, .closable, .utilityWindow], backing: .buffered,
    defer: false)
  let term = NSTextField()
  let sub = NSTextField()
  let exact = NSButton(
    checkboxWithTitle: L("Match case"), target: nil, action: nil)
  let direction = NSPopUpButton()
  init(owner: Notepad, replacing: Bool) {
    self.owner = owner
    self.replacing = replacing
    super.init()
    panel.title = replacing ? L("Replace") : L("Find")
    panel.isReleasedWhenClosed = false
    panel.isFloatingPanel = true
    let selection = (owner.editor.string as NSString).substring(with: owner.editor.selectedRange())
    term.stringValue = selection.isEmpty ? owner.query : selection
    sub.stringValue = owner.replacement
    exact.state = owner.matchCase ? .on : .off
    direction.addItems(withTitles: [L("Down"), L("Up")])
    direction.selectItem(at: owner.backwards ? 1 : 0)
    var rows: [(String, NSView)] = [(L("Find what:"), term)]
    if replacing {
      rows.append((L("Replace with:"), sub))
    } else {
      rows.append((L("Direction:"), direction))
    }
    let grid = owner.form(rows)
    let buttons = NSStackView()
    buttons.orientation = .vertical
    buttons.alignment = .leading
    let next = NSButton(title: L("Find Next"), target: self, action: #selector(nextMatch))
    next.keyEquivalent = "\r"
    buttons.addArrangedSubview(next)
    if replacing {
      buttons.addArrangedSubview(
        NSButton(title: L("Replace"), target: self, action: #selector(replaceOne)))
      buttons.addArrangedSubview(
        NSButton(title: L("Replace All"), target: self, action: #selector(replaceAll)))
    }
    let cancel = NSButton(
      title: L("Cancel"), target: panel, action: #selector(NSWindow.performClose(_:)))
    cancel.keyEquivalent = "\u{1b}"
    buttons.addArrangedSubview(cancel)
    let fields = NSStackView(views: [grid, exact])
    fields.orientation = .vertical
    fields.alignment = .leading
    let content = NSStackView(views: [fields, buttons])
    content.alignment = .top
    content.edgeInsets = NSEdgeInsets(top: 14, left: 14, bottom: 14, right: 14)
    panel.contentView = content
    panel.setContentSize(content.fittingSize)
  }
  func show() {
    owner.centerDialog(panel)
    owner.window.addChildWindow(panel, ordered: .above)
    panel.makeKeyAndOrderFront(nil)
    panel.makeFirstResponder(term)
    term.selectText(nil)
  }
  func readFields() -> Bool {
    owner.query = term.stringValue
    owner.replacement = sub.stringValue
    owner.matchCase = exact.state == .on
    owner.backwards = !replacing && direction.indexOfSelectedItem == 1
    if owner.query.isEmpty {
      NSSound.beep()
      panel.makeFirstResponder(term)
      return false
    }
    return true
  }
  var options: NSString.CompareOptions {
    owner.matchCase ? [.literal] : [.literal, .caseInsensitive]
  }
  @objc func nextMatch() { if readFields() { owner.findNext() } }
  @objc func replaceOne() {
    guard readFields() else { return }
    let selected = (owner.editor.string as NSString).substring(with: owner.editor.selectedRange())
    if (selected as NSString).compare(owner.query, options: options) == .orderedSame {
      owner.insert(owner.replacement)
    }
    owner.findNext()
  }
  @objc func replaceAll() {
    guard readFields() else { return }
    let s = owner.editor.string as NSString
    guard s.range(of: owner.query, options: options).location != NSNotFound else {
      owner.alert(String(format: L("find.missing"), owner.query))
      return
    }
    let result = s.replacingOccurrences(
      of: owner.query, with: owner.replacement, options: options,
      range: NSRange(location: 0, length: s.length))
    owner.editor.selectAll(nil)
    owner.insert(result)
  }
}
