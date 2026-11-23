import AppKit

extension Notepad {
  func buildMenus() {
    let main = NSMenu()
    let appItem = main.addItem(withTitle: "My Notepad", action: nil, keyEquivalent: "")
    let app = NSMenu()
    appItem.submenu = app
    app.addItem(withTitle: L("About My Notepad"), action: #selector(showAbout), keyEquivalent: "").target = self
    app.addItem(.separator())
    app.addItem(withTitle: L("Hide My Notepad"), action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
    let others = app.addItem(
      withTitle: L("Hide Others"), action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
    others.keyEquivalentModifierMask = [.command, .option]
    app.addItem(withTitle: L("Show All"), action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
    app.addItem(.separator())
    app.addItem(
      withTitle: L("Quit My Notepad"), action: #selector(NSApplication.terminate(_:)),
      keyEquivalent: "q")
    for title in [L("File"), L("Edit"), L("Format"), L("View"), L("Help")] {
      let menu = NSMenu(title: title)
      main.addItem(withTitle: title, action: nil, keyEquivalent: "").submenu = menu
      let b = NSButton(title: title, target: self, action: #selector(showMenu(_:)))
      b.font = .systemFont(ofSize: 12)
      b.isBordered = false
      b.tag = menus.count
      menus.append(menu)
      b.widthAnchor.constraint(equalToConstant: b.intrinsicContentSize.width + 12).isActive = true
      menuStrip.addArrangedSubview(b)
    }
    window.minSize.width = max(window.minSize.width, menuStrip.fittingSize.width + 4)
    // The Window menu belongs to the menu bar of the system only: the strip inside the window
    // keeps the five menus of the original.
    let windowMenu = NSMenu(title: L("Window"))
    windowMenu.addItem(withTitle: L("Minimize"), action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
    windowMenu.addItem(withTitle: L("Zoom"), action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")
    let windowItem = NSMenuItem(title: windowMenu.title, action: nil, keyEquivalent: "")
    windowItem.submenu = windowMenu
    main.insertItem(windowItem, at: main.numberOfItems - 1)
    NSApp.windowsMenu = windowMenu
    NSApp.mainMenu = main
    func add(_ m: Int, _ title: String, _ key: String = "", _ act: @escaping () -> Void) {
      let i = NSMenuItem(title: L(title), action: #selector(invoke(_:)), keyEquivalent: key)
      i.identifier = NSUserInterfaceItemIdentifier(title)
      i.tag = handlers.count
      handlers[i.tag] = act
      i.target = self
      menus[m].addItem(i)
      if !key.isEmpty {
        let isFunction = (key.unicodeScalars.first?.value ?? 0) >= 0xf700
        i.keyEquivalentModifierMask = isFunction ? [] : .command
        shortcuts[(isFunction ? "" : "^") + key] = i
        if !isFunction { commandShortcuts[key] = i }
      }
    }
    func gap(_ m: Int) { menus[m].addItem(.separator()) }
    add(0, "New", "n") { if self.confirm() { self.install(TextFile(), nil) } }
    add(0, "Open…", "o", openFile)
    add(0, "Save", "s") { self.save() }
    add(0, "Save As…") { self.save(asNew: true) }
    shortcuts["^+s"] = menus[0].items.last
    commandShortcuts["+s"] = menus[0].items.last
    menus[0].items.last?.keyEquivalent = "S"
    menus[0].items.last?.keyEquivalentModifierMask = [.command, .shift]
    gap(0)
    add(0, "Page Setup…", "", pageSetup)
    add(0, "Print…", "p", printDocument)
    gap(0)
    add(0, "Exit", "", closeWindow)
    add(1, "Undo", "z") { self.editor.undoManager?.undo() }
    add(1, "Redo") { self.editor.undoManager?.redo() }
    let redo = menus[1].items.last!
    redo.keyEquivalent = "Z"
    redo.keyEquivalentModifierMask = [.command, .shift]
    shortcuts["^+z"] = redo
    commandShortcuts["+z"] = redo
    shortcuts["^y"] = redo
    gap(1)
    // Standard responder-chain actions also work inside the search and file dialogs.
    for (title, key, action) in [
      ("Cut", "x", #selector(NSText.cut(_:))), ("Copy", "c", #selector(NSText.copy(_:))),
      ("Paste", "v", #selector(NSText.paste(_:))),
    ] {
      add(1, title, key) { NSApp.sendAction(action, to: self.editor, from: nil) }
      let i = menus[1].items.last!
      i.action = action
      i.target = nil
    }
    add(1, "Delete") { self.insert("") }
    gap(1)
    add(1, "Find…", "f") { self.searchPanel(false) }
    add(1, "Find Next", "\u{f706}") { self.findNext() }
    add(1, "Replace…", "h") { self.searchPanel(true) }
    // Command-H hides the application, as in every Mac app; Replace keeps Control-H and shows
    // the Mac shortcut, Option-Command-F.
    let replace = menus[1].items.last!
    replace.keyEquivalent = "f"
    replace.keyEquivalentModifierMask = [.command, .option]
    commandShortcuts["h"] = nil
    add(1, "Go To…", "g", goToLine)
    gap(1)
    add(1, "Select All", "a") {
      self.editor.selectAll(nil)
    }
    let all = menus[1].items.last!
    all.action = #selector(NSText.selectAll(_:))
    all.target = nil
    add(1, "Time/Date", "\u{f708}") { self.insert(self.dateStamp()) }
    add(2, "Word Wrap") {
      self.defaults.set(!self.wrapping, forKey: "wrap")
      self.applyWrap()
    }
    add(2, "Font…", "", fontDialog)
    gap(2)
    add(2, "Increase Font Size") { self.changeFontSize(by: 1) }
    add(2, "Decrease Font Size") { self.changeFontSize(by: -1) }
    add(3, "Status Bar") {
      self.defaults.set(!self.defaults.bool(forKey: "status"), forKey: "status")
      self.applyWrap()
    }
    add(4, "View Help", "\u{f704}") {
      self.alert(
        L("My Notepad Help"),
        L("help.body")
      )
    }
    gap(4)
    add(4, "About My Notepad") { self.showAbout() }
  }
  @objc func invoke(_ item: NSMenuItem) { handlers[item.tag]?() }
  @objc func showMenu(_ sender: NSButton) {
    menus[sender.tag].popUp(
      positioning: nil, at: NSPoint(x: 0, y: sender.isFlipped ? sender.bounds.maxY : 0), in: sender)
  }
  func validateMenuItem(_ item: NSMenuItem) -> Bool {
    switch item.identifier?.rawValue {
    case "Status Bar":
      item.state = statusVisible ? .on : .off
      return !wrapping
    case "Word Wrap": item.state = wrapping ? .on : .off
    case "Go To…": return !wrapping
    case "Undo": return editor.undoManager?.canUndo ?? false
    case "Redo": return editor.undoManager?.canRedo ?? false
    case "Cut", "Copy", "Delete": return editor.selectedRange().length > 0
    case "Find…", "Find Next": return !editor.string.isEmpty
    default: break
    }
    return true
  }
  func changeFontSize(by steps: Int) {
    let font = editor.font ?? .monospacedSystemFont(ofSize: 13, weight: .regular)
    let size = min(999, max(1, font.pointSize + CGFloat(steps)))
    guard size != font.pointSize else { return }
    applyFont(NSFontManager.shared.convert(font, toSize: size))
  }

  private func applyFont(_ font: NSFont) {
    editor.font = font
    defaults.set(font.fontName, forKey: "fontName")
    defaults.set(font.pointSize, forKey: "fontSize")
  }

  func fontDialog() {
    let a = NSAlert()
    a.messageText = L("Font")
    let family = NSPopUpButton()
    family.addItems(withTitles: NSFontManager.shared.availableFontFamilies.sorted())
    family.selectItem(withTitle: editor.font?.familyName ?? "Menlo")
    let size = NSTextField(string: String(Int(editor.font?.pointSize ?? 13)))
    let style = NSPopUpButton()
    style.addItems(withTitles: [L("Regular"), L("Italic"), L("Bold"), L("Bold Italic")])
    let traits = NSFontManager.shared.traits(of: editor.font ?? .systemFont(ofSize: 13))
    style.selectItem(
      at: (traits.contains(.boldFontMask) ? 2 : 0) + (traits.contains(.italicFontMask) ? 1 : 0))
    a.accessoryView = form([(L("Font:"), family), (L("Style:"), style), (L("Size:"), size)])
    a.addButton(withTitle: L("OK"))
    a.addButton(withTitle: L("Cancel"))
    while runAlert(a) == .alertFirstButtonReturn {
      guard (1...999).contains(size.integerValue), let familyName = family.titleOfSelectedItem
      else {
        alert(L("Enter a size from 1 to 999."))
        continue
      }
      var traits: NSFontTraitMask = []
      if style.indexOfSelectedItem & 1 == 1 { traits.insert(.italicFontMask) }
      if style.indexOfSelectedItem & 2 == 2 { traits.insert(.boldFontMask) }
      let font =
        NSFontManager.shared.font(
          withFamily: familyName, traits: traits, weight: 5, size: CGFloat(size.integerValue))
        ?? NSFont(name: familyName, size: CGFloat(size.integerValue))
      guard let font else {
        alert(L("This font is unavailable."))
        continue
      }
      applyFont(font)
      break
    }
  }
  func form(_ rows: [(String, NSView)]) -> NSGridView {
    let grid = NSGridView(views: rows.map { [NSTextField(labelWithString: $0.0), $0.1] })
    grid.column(at: 0).xPlacement = .trailing
    grid.column(at: 1).width = 190
    grid.layoutSubtreeIfNeeded()
    grid.frame.size = grid.fittingSize
    return grid
  }
  func goToLine() {
    let a = NSAlert()
    a.messageText = L("Go to Line")
    let prefix = (editor.string as NSString).substring(to: editor.selectedRange().location)
    let value = NSTextField(string: String(prefix.components(separatedBy: "\n").count))
    a.accessoryView = form([(L("Line number:"), value)])
    a.addButton(withTitle: L("OK"))
    a.addButton(withTitle: L("Cancel"))
    a.window.initialFirstResponder = value
    while runAlert(a) == .alertFirstButtonReturn {
      let lines = editor.string.components(separatedBy: "\n")
      guard let n = Int(value.stringValue), (1...lines.count).contains(n) else {
        alert(L("The line number is out of range."))
        continue
      }
      let offset = lines.prefix(n - 1).reduce(0) { $0 + $1.utf16.count + 1 }
      select(NSRange(location: offset, length: 0))
      break
    }
  }
}
