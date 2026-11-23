import AppKit

// Tests for My Notepad. Run with ./test.sh: every source except the app's entry point is compiled
// with this file, and the checks run in a plain process. No window is shown and nothing is
// written outside the settings of this test process, which are removed at the end.

// Line by line, so a crash still shows the checks before it.
setvbuf(stdout, nil, _IOLBF, 0)

var failures = 0

func check(_ condition: Bool, _ name: String) {
  print(condition ? "ok    \(name)" : "FAIL  \(name)")
  if !condition { failures += 1 }
}

// MARK: Text files: encodings, byte-order marks and line endings

do {
  let plain = try! TextFile(data: Data("abc\r\ndef".utf8))
  check(plain.encoding == .ansi && !plain.bom, "plain ASCII opens as ANSI without a mark")
  check(plain.text == "abc\ndef" && plain.newline == "\r\n", "Windows line endings are recognised and kept apart from the text")
  check(try! plain.data() == Data("abc\r\ndef".utf8), "a file saves back to the same bytes")

  let unix = try! TextFile(data: Data("a\nb".utf8))
  check(unix.newline == "\n" && (try! unix.data()) == Data("a\nb".utf8), "Unix line endings are kept")
  let classic = try! TextFile(data: Data("a\rb".utf8))
  check(classic.newline == "\r" && classic.text == "a\nb" && (try! classic.data()) == Data("a\rb".utf8), "classic Mac line endings are kept")
  check(TextFile().newline == "\r\n" && TextFile().encoding == .ansi, "a new document uses ANSI and Windows line endings")

  let accented = Data("ação".utf8)
  let utf8 = try! TextFile(data: accented)
  check(utf8.encoding == .utf8 && !utf8.bom && utf8.text == "ação", "UTF-8 without a mark is detected by its bytes")
  check(try! utf8.data() == accented, "UTF-8 without a mark saves without one")

  let marked = try! TextFile(data: Data([239, 187, 191]) + accented)
  check(marked.encoding == .utf8 && marked.bom && marked.text == "ação", "the UTF-8 mark is recognised and left out of the text")
  check(try! marked.data() == Data([239, 187, 191]) + accented, "the UTF-8 mark is written back")

  let little = Data([255, 254]) + "ação".data(using: .utf16LittleEndian)!
  let le = try! TextFile(data: little)
  check(le.encoding == .unicode && le.bom && le.text == "ação" && (try! le.data()) == little, "UTF-16 LE round-trips with its mark")
  let big = Data([254, 255]) + "ação".data(using: .utf16BigEndian)!
  let be = try! TextFile(data: big)
  check(be.encoding == .bigEndian && be.bom && be.text == "ação" && (try! be.data()) == big, "UTF-16 BE round-trips with its mark")

  let windows = Data([0x61, 0xE7, 0xE3, 0x6F]) // "ação" in Windows-1252: not valid UTF-8
  let ansi = try! TextFile(data: windows)
  check(ansi.encoding == .ansi && ansi.text == "ação" && (try! ansi.data()) == windows, "Windows-1252 bytes open and save as ANSI")

  let forced = try! TextFile(data: accented, forced: .ansi)
  check(forced.encoding == .ansi && forced.text != "ação", "an encoding chosen by hand wins over detection")
  check((try? TextFile(data: Data([0xFF, 0xFE, 0x41]), forced: .utf8)) == nil, "bytes that the chosen encoding cannot read are refused")

  let empty = try! TextFile(data: Data())
  check(empty.text.isEmpty && empty.encoding == .ansi && (try! empty.data()).isEmpty, "an empty file opens and saves empty")

  var japanese = TextFile()
  japanese.text = "橋"
  check((try? japanese.data()) == nil, "a character ANSI cannot hold makes the save fail instead of losing it")
  japanese.encoding = .utf8
  check((try? japanese.data()) == Data("橋".utf8), "the same text saves once the encoding is UTF-8")

  var mixed = TextFile()
  mixed.text = "a\r\nb\rc\nd"
  mixed.newline = "\n"
  check(try! mixed.data() == Data("a\nb\nc\nd".utf8), "mixed line endings are written as one kind")
}

// MARK: Header and footer codes

do {
  let page = PrintedText(frame: NSRect(x: 0, y: 0, width: 400, height: 400))
  page.filename = "notes.txt"
  check(page.expand("&f").string == "\tnotes.txt\t", "&f is the file name, centred by default")
  check(page.expand("&lleft&ccentre&rright").string == "left\tcentre\tright", "&l, &c and &r place the text")
  check(page.expand("Page &p").string == "\tPage 1\t", "&p is the page number")
  check(page.expand("A && B").string == "\tA & B\t", "&& is a literal ampersand")
  check(page.expand("&x").string == "\t&x\t", "an unknown code is printed as typed")
  check(page.expand("100&").string == "\t100&\t", "a trailing ampersand is printed as typed")
  check(!page.expand("&d").string.trimmingCharacters(in: .whitespaces).isEmpty
    && !page.expand("&t").string.trimmingCharacters(in: .whitespaces).isEmpty, "&d and &t produce the date and the time")
}

// MARK: Translations

do {
  let languages = ["en", "pt-BR", "es", "fr", "de", "it", "ja", "ko"]
  func strings(_ language: String) -> [String: String] {
    guard let url = Bundle.main.url(forResource: "Localizable", withExtension: "strings", subdirectory: nil, localization: language),
      let table = NSDictionary(contentsOf: url) as? [String: String] else { return [:] }
    return table
  }
  func placeholders(_ text: String) -> [String] {
    var found: [String] = []
    var rest = Substring(text)
    while let percent = rest.firstIndex(of: "%") {
      let after = rest[rest.index(after: percent)...]
      let spec = after.prefix { "0123456789$lh".contains($0) }
      if let kind = after.dropFirst(spec.count).first, "@dfs".contains(kind) { found.append(String(kind)) }
      rest = after.dropFirst(spec.count)
    }
    return found.sorted()
  }
  let english = strings("en")
  check(english.count > 80, "the English strings are found next to the test binary")
  check(!english.values.contains { $0.localizedCaseInsensitiveContains("windows") || $0.localizedCaseInsensitiveContains("microsoft") }
    && !TextEncoding.allCases.contains { $0.title.localizedCaseInsensitiveContains("windows") }, "en: no Microsoft or Windows names, in the encoding names either")
  for language in languages.dropFirst() {
    let table = strings(language)
    let missing = Set(english.keys).subtracting(table.keys), extra = Set(table.keys).subtracting(english.keys)
    check(missing.isEmpty && extra.isEmpty, "\(language): same keys as English" + (missing.isEmpty && extra.isEmpty ? "" : " — missing \(missing.sorted()), extra \(extra.sorted())"))
    check(table.values.allSatisfy { !$0.isEmpty }, "\(language): no empty text")
    check(!table.values.contains { $0.localizedCaseInsensitiveContains("windows") || $0.localizedCaseInsensitiveContains("microsoft") },
      "\(language): no Microsoft or Windows names")
    let mismatched = english.keys.filter { placeholders(english[$0]!) != placeholders(table[$0] ?? "") }
    check(mismatched.isEmpty, "\(language): same placeholders as English" + (mismatched.isEmpty ? "" : " — \(mismatched.sorted())"))
  }
}

// MARK: The application, built without showing its window

_ = NSApplication.shared
let settings = UserDefaults.standard
let touched = ["wrap", "status", "fontName", "fontSize"]
for key in touched { settings.removeObject(forKey: key) }
settings.set(true, forKey: "status")

let app = Notepad()
app.window = NSWindow(
  contentRect: NSRect(x: 0, y: 0, width: 760, height: 495),
  styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: true)
app.layout()
app.buildMenus()
app.applyWrap()
app.refresh()

func menu(_ title: String) -> NSMenu? { NSApp.mainMenu?.items.first { $0.title == title }?.submenu }
func item(_ menuTitle: String, _ identifier: String) -> NSMenuItem? {
  menu(menuTitle)?.items.first { $0.identifier?.rawValue == identifier }
}

// Menus
do {
  let titles = NSApp.mainMenu?.items.map(\.title) ?? []
  check(titles == ["My Notepad", "File", "Edit", "Format", "View", "Window", "Help"], "the menu bar has the application menu, the five of the original, Window and Help")
  let stripTitles = app.menuStrip.arrangedSubviews.compactMap { ($0 as? NSButton)?.title }
  check(stripTitles.count == 6 && stripTitles.first == "My Notepad",
    "the strip inside the window opens with the application's menu, then the five menus of the original")
  check(app.menuStrip.arrangedSubviews.compactMap { $0 as? NSButton }.filter { $0.tag >= 0 }.map(\.tag) == [0, 1, 2, 3, 4],
    "the access keys still reach the five menus")
  let own = NSApp.mainMenu?.items.first?.submenu?.items.map(\.title) ?? []
  check(own.contains("About My Notepad") && own.contains("Hide My Notepad") && own.contains("Hide Others")
    && own.contains("Show All") && own.last == "Quit My Notepad", "the application menu has About, the hiding commands and Quit")
  let saveAs = item("File", "Save As…")
  check(saveAs?.keyEquivalent == "S" && saveAs?.keyEquivalentModifierMask == [.command, .shift], "Save As answers to Shift-Command-S")
  check(app.shortcuts["^+s"] === saveAs, "Save As also answers to Control-Shift-S")
  check(item("Format", "Increase Font Size") != nil && item("Format", "Decrease Font Size") != nil, "Format has the two font size commands")
  check(menu("Window")?.items.map(\.title) == ["Minimize", "Zoom"] && NSApp.windowsMenu === menu("Window"), "the Window menu has Minimize and Zoom")
  check(menu("Help")?.items.last?.title == "About My Notepad", "About is also in Help, as in the original")
  let everyItem = (NSApp.mainMenu?.items ?? []).compactMap(\.submenu).flatMap(\.items).filter { !$0.isSeparatorItem }
  check(everyItem.allSatisfy { $0.action != nil }, "every menu item does something")
  let replace = item("Edit", "Replace…")
  check(replace?.keyEquivalent == "f" && replace?.keyEquivalentModifierMask == [.command, .option]
    && app.shortcuts["^h"] === replace && app.commandShortcuts["h"] == nil,
    "Replace answers to Option-Command-F and Control-H, and leaves Command-H to Hide")
  // Command keys act without the menu, whose shortcuts the system settings can move elsewhere.
  func press(_ characters: String, _ flags: NSEvent.ModifierFlags) -> Bool {
    guard let event = NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: flags, timestamp: 0,
      windowNumber: app.window.windowNumber, context: nil, characters: characters,
      charactersIgnoringModifiers: characters, isARepeat: false, keyCode: 0) else { return false }
    return app.handleEditorShortcut(event)
  }
  let selectAll = item("Edit", "Select All")
  let savedKey = selectAll?.keyEquivalent ?? ""
  selectAll?.keyEquivalent = ""
  app.window.makeFirstResponder(app.editor)
  app.editor.string = "one two"
  app.editor.setSelectedRange(NSRange(location: 3, length: 0))
  check(press("a", .command) && app.editor.selectedRange() == NSRange(location: 0, length: 7),
    "Command-A selects everything even when the menu no longer answers to it")
  selectAll?.keyEquivalent = savedKey
  app.editor.setSelectedRange(NSRange(location: 0, length: 3))
  let clipboard = NSPasteboard.general.string(forType: .string)
  NSPasteboard.general.clearContents()
  check(press("c", .command) && NSPasteboard.general.string(forType: .string) == "one", "Command-C copies the selection")
  check(press("x", .command) && app.editor.string == " two", "Command-X cuts the selection")
  check(press("v", .command) && app.editor.string == "one two", "Command-V pastes it back")
  check(!press("q", .command) && !press("h", .command) && !press("w", .command), "Command-Q, H and W are left to the menu")
  NSPasteboard.general.clearContents()
  if let clipboard { NSPasteboard.general.setString(clipboard, forType: .string) }
  app.editor.string = ""
}

// Menu states
do {
  app.install(TextFile(), nil)
  check(item("Edit", "Cut").map(app.validateMenuItem) == false && item("Edit", "Find…").map(app.validateMenuItem) == false, "with no text there is nothing to cut or to find")
  var file = TextFile()
  file.text = "one two"
  app.install(file, nil)
  app.editor.setSelectedRange(NSRange(location: 0, length: 3))
  check(item("Edit", "Cut").map(app.validateMenuItem) == true && item("Edit", "Find…").map(app.validateMenuItem) == true, "with text selected Cut and Find are available")
  check(item("Edit", "Go To…").map(app.validateMenuItem) == true && item("View", "Status Bar").map(app.validateMenuItem) == true, "without word wrap Go To and the status bar are available")
  settings.set(true, forKey: "wrap")
  app.applyWrap()
  check(item("Edit", "Go To…").map(app.validateMenuItem) == false && item("View", "Status Bar").map(app.validateMenuItem) == false && !app.statusVisible, "with word wrap Go To and the status bar are off")
  check(item("Format", "Word Wrap").map { _ = app.validateMenuItem($0); return $0.state == .on } == true, "Word Wrap shows its mark when on")
  settings.set(false, forKey: "wrap")
  app.applyWrap()
}

// Document state, status bar and the .LOG diary
do {
  var file = TextFile()
  file.text = "first\nsecond line\nthird"
  app.install(file, URL(fileURLWithPath: "/tmp/notes.txt"))
  check(app.window.title == "notes.txt - My Notepad" && !app.edited, "a document just opened shows its name and is not edited")
  app.editor.setSelectedRange(NSRange(location: 9, length: 0))
  app.refresh()
  check(app.status.stringValue == "Ln 2, Col 4", "the status bar shows the line and the column of the caret")
  app.insert("X")
  check(app.edited && app.editor.string == "first\nsecXond line\nthird", "typing marks the document as edited")

  app.install(TextFile(), nil)
  check(app.window.title == "Untitled - My Notepad" && app.editor.string.isEmpty, "a new document is untitled and empty")

  var diary = TextFile()
  diary.text = ".LOG\nearlier entry"
  app.install(diary, nil)
  let text = app.editor.string
  check(text.hasPrefix(".LOG\nearlier entry\n") && text.hasSuffix("\n") && text.count > ".LOG\nearlier entry\n\n".count, "a .LOG file gets the time and the date at its end when opened")
  check(app.editor.selectedRange().location == (text as NSString).length, "and the caret waits after the new entry")
  var notDiary = TextFile()
  notDiary.text = "notes\n.LOG"
  app.install(notDiary, nil)
  check(app.editor.string == "notes\n.LOG", ".LOG anywhere but the first line changes nothing")
  check(!app.dateStamp().isEmpty && app.dateStamp().contains(" "), "the time and date stamp has both parts")
}

// Find and replace
do {
  var file = TextFile()
  file.text = "Bridge, bridge and BRIDGE"
  app.install(file, nil)
  app.query = "bridge"
  app.matchCase = false
  app.backwards = false
  app.findNext()
  check(app.editor.selectedRange() == NSRange(location: 0, length: 6), "Find ignores case unless told otherwise")
  app.findNext()
  check(app.editor.selectedRange() == NSRange(location: 8, length: 6), "Find Next goes on from the selection")
  app.matchCase = true
  app.editor.setSelectedRange(NSRange(location: 0, length: 0))
  app.findNext()
  check(app.editor.selectedRange() == NSRange(location: 8, length: 6), "with Match case only the exact spelling is found")
  app.matchCase = false
  app.backwards = true
  app.editor.setSelectedRange(NSRange(location: 25, length: 0))
  app.findNext()
  check(app.editor.selectedRange() == NSRange(location: 19, length: 6), "searching upwards finds the match before the caret")

  let panel = FinderPanel(owner: app, replacing: true)
  panel.term.stringValue = "bridge"
  panel.sub.stringValue = "footbridge"
  app.editor.setSelectedRange(NSRange(location: 0, length: 6))
  panel.replaceOne()
  check(app.editor.string == "footbridge, bridge and BRIDGE", "Replace changes the selected match")
  check(app.editor.selectedRange() == NSRange(location: 12, length: 6), "and moves on to the next one")
  app.install(file, nil)
  panel.replaceAll()
  check(app.editor.string == "footbridge, footbridge and footbridge", "Replace All changes every match")
  app.install(file, nil)
  panel.exact.state = .on
  panel.replaceAll()
  check(app.editor.string == "Bridge, footbridge and BRIDGE", "Replace All respects Match case")

  // The layout of the Replace panel used to be ambiguous: about one opening in a hundred put the
  // Replace with field right under Find what. Lay it out many times and compare.
  var tops: Set<Int> = []
  for _ in 0..<200 {
    let replace = FinderPanel(owner: app, replacing: true)
    guard let content = replace.panel.contentView else { break }
    content.layoutSubtreeIfNeeded()
    tops.insert(Int(content.bounds.height - replace.sub.convert(replace.sub.bounds, to: content).maxY))
    replace.panel.close()
  }
  check(tops.count == 1, "the Replace panel always places Replace with in the same spot")
}

// Font size
do {
  let before = app.editor.font?.pointSize ?? 0
  app.changeFontSize(by: 1)
  check(app.editor.font?.pointSize == before + 1 && settings.double(forKey: "fontSize") == Double(before + 1), "Increase Font Size grows the font by one point and remembers it")
  app.changeFontSize(by: -1)
  check(app.editor.font?.pointSize == before, "Decrease Font Size brings it back")
  app.changeFontSize(by: -5000)
  check(app.editor.font?.pointSize == 1, "the font never goes below one point")
  app.changeFontSize(by: 5000)
  check(app.editor.font?.pointSize == 999, "nor above 999")
}

for key in touched { settings.removeObject(forKey: key) }
settings.synchronize()

print(failures == 0 ? "All tests passed." : "\(failures) test(s) failed.")
exit(failures == 0 ? 0 : 1)
