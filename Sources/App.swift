import AppKit
import UniformTypeIdentifiers

final class Notepad: NSObject, NSApplicationDelegate, NSWindowDelegate, NSTextViewDelegate,
  NSMenuItemValidation
{
  var window: NSWindow!
  let editor = EditorTextView()
  let scroll = EditorScrollView()
  let status = NSTextField(labelWithString: "")
  let caption = NSTextField(labelWithString: "")
  let defaults = UserDefaults.standard
  var wrapping: Bool { defaults.bool(forKey: "wrap") }
  var statusVisible: Bool { !wrapping && defaults.bool(forKey: "status") }
  var statusHeight: NSLayoutConstraint!
  var file = TextFile()
  var url: URL?
  var pendingURL: URL?
  var finder: FinderPanel?
  var query = ""
  var replacement = ""
  var matchCase = false
  var backwards = false
  var header = "&f"
  var footer = L("print.footer")
  var printInfo = NSPrintInfo.shared.copy() as! NSPrintInfo
  var handlers: [Int: () -> Void] = [:]
  var shortcuts: [String: NSMenuItem] = [:]
  var menuStrip = NSStackView()
  var menus: [NSMenu] = []
  var keyMonitor: Any?
  var edited: Bool { editor.string != file.text }
  var name: String { url?.lastPathComponent ?? L("Untitled") }
  func applicationDidFinishLaunching(_ notification: Notification) {
    if let url = Bundle.main.url(forResource: "Notepad", withExtension: "icns"),
       let icon = NSImage(contentsOf: url) {
      let imageView = NSImageView(image: icon)
      imageView.imageScaling = .scaleProportionallyUpOrDown
      NSApp.dockTile.contentView = imageView
      NSApp.dockTile.display()
    }
    NSWindow.allowsAutomaticWindowTabbing = false
    NSApp.appearance = NSAppearance(named: .aqua)
    window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 760, height: 495),
      styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
      backing: .buffered, defer: false)
    window.delegate = self
    window.titleVisibility = .hidden
    window.titlebarAppearsTransparent = true
    window.styleMask.insert(.fullSizeContentView)
    window.minSize = NSSize(width: 360, height: 180)
    window.isReleasedWhenClosed = false
    window.tabbingMode = .disallowed
    layout()
    buildMenus()
    applyWrap()
    refresh()
    window.center()
    window.setFrameAutosaveName("My Notepad")
    window.makeKeyAndOrderFront(nil)
    window.makeFirstResponder(editor)
    NSApp.activate(ignoringOtherApps: true)
    keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
      guard let self, NSApp.keyWindow == self.window, NSApp.modalWindow == nil else { return event }
      return self.handleEditorShortcut(event) ? nil : event
    }
    if let pendingURL { _ = load(pendingURL) }
    DispatchQueue.main.async { self.offerDefaultTextEditor() }
  }

  private func offerDefaultTextEditor() {
    guard let type = UTType(filenameExtension: "txt"),
      let identifier = Bundle.main.bundleIdentifier else { return }
    let workspace = NSWorkspace.shared
    if let current = workspace.urlForApplication(toOpen: type),
      Bundle(url: current)?.bundleIdentifier == identifier { return }

    let prompt = NSAlert()
    prompt.messageText = L("defaultEditor.question")
    prompt.informativeText = L("defaultEditor.detail")
    prompt.addButton(withTitle: L("defaultEditor.accept"))
    prompt.addButton(withTitle: L("defaultEditor.later")).keyEquivalent = "\u{1b}"
    guard runAlert(prompt) == .alertFirstButtonReturn else { return }

    workspace.setDefaultApplication(at: Bundle.main.bundleURL, toOpen: type) { error in
      guard let error = error as NSError? else { return }
      if error.domain == NSCocoaErrorDomain && error.code == NSUserCancelledError { return }
      if error.domain == NSOSStatusErrorDomain && error.code == -128 { return }
      DispatchQueue.main.async {
        self.alert(L("defaultEditor.error"), error.localizedDescription)
      }
    }
  }

  func handleEditorShortcut(_ event: NSEvent) -> Bool {
    let mods = event.modifierFlags.intersection([.command, .control, .shift, .option])
    if mods == .option, let key = event.charactersIgnoringModifiers?.lowercased(),
      let i = L("menu.accessKeys").map(String.init).firstIndex(of: key)
    {
      showMenu(menuStrip.arrangedSubviews[i] as! NSButton)
      return true
    }
    if window.firstResponder === editor, !editor.hasMarkedText(),
      mods == .control || mods == [.control, .shift]
    {
      let symbol = event.charactersIgnoringModifiers
      if symbol == "+" || (symbol == "=" && mods == .control) {
        changeFontSize(by: 1)
        return true
      }
      if symbol == "-" {
        changeFontSize(by: -1)
        return true
      }
    }
    if window.firstResponder === editor, editor.handleEditingKey(event) { return true }
    guard mods == .control || mods == [.control, .shift] || mods.isEmpty || mods == .shift else {
      return false
    }
    let key =
      (mods.contains(.control) ? "^" : "") + (mods.contains(.shift) ? "+" : "")
      + (event.characters(byApplyingModifiers: [])?.lowercased() ?? "")
    if let item = shortcuts[key] {
      if validateMenuItem(item) { invoke(item) } else { NSSound.beep() }
      return true
    }
    return false
  }

  func layout() {
    let root = window.contentView!
    let bar = Caption()
    let icon = NSImageView()
    icon.image =
      Bundle.main.url(forResource: "Caption", withExtension: "png").flatMap(
        NSImage.init(contentsOf:)) ?? NSApp.applicationIconImage
    caption.font = .systemFont(ofSize: 13)
    let menuBackground = NSView()
    menuBackground.wantsLayer = true
    menuBackground.layer?.backgroundColor = NSColor(white: 0.95, alpha: 1).cgColor
    menuStrip.spacing = 0
    for v in [bar, menuBackground, scroll, status] {
      root.addSubview(v)
      v.translatesAutoresizingMaskIntoConstraints = false
    }
    for v in [icon, caption] {
      bar.addSubview(v)
      v.translatesAutoresizingMaskIntoConstraints = false
    }
    menuBackground.addSubview(menuStrip)
    menuStrip.translatesAutoresizingMaskIntoConstraints = false
    status.font = .systemFont(ofSize: 12)
    status.alignment = .right
    statusHeight = status.heightAnchor.constraint(equalToConstant: 0)
    NSLayoutConstraint.activate([
      bar.topAnchor.constraint(equalTo: root.topAnchor),
      bar.leadingAnchor.constraint(equalTo: root.leadingAnchor),
      bar.trailingAnchor.constraint(equalTo: root.trailingAnchor),
      bar.heightAnchor.constraint(equalToConstant: 30),
      // The standard macOS close, minimize and zoom buttons occupy the leading edge.
      icon.leadingAnchor.constraint(equalTo: bar.leadingAnchor, constant: 78),
      icon.centerYAnchor.constraint(equalTo: bar.centerYAnchor),
      icon.widthAnchor.constraint(equalToConstant: 16),
      icon.heightAnchor.constraint(equalToConstant: 16),
      caption.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 5),
      caption.centerYAnchor.constraint(equalTo: bar.centerYAnchor),
      caption.trailingAnchor.constraint(lessThanOrEqualTo: bar.trailingAnchor, constant: -10),
      menuBackground.topAnchor.constraint(equalTo: bar.bottomAnchor),
      menuBackground.leadingAnchor.constraint(equalTo: root.leadingAnchor),
      menuBackground.trailingAnchor.constraint(equalTo: root.trailingAnchor),
      menuBackground.heightAnchor.constraint(equalToConstant: 22),
      menuStrip.leadingAnchor.constraint(equalTo: menuBackground.leadingAnchor, constant: 2),
      menuStrip.centerYAnchor.constraint(equalTo: menuBackground.centerYAnchor),
      scroll.topAnchor.constraint(equalTo: menuBackground.bottomAnchor),
      scroll.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 2),
      scroll.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -2),
      scroll.bottomAnchor.constraint(equalTo: status.topAnchor),
      status.bottomAnchor.constraint(equalTo: root.bottomAnchor),
      status.leadingAnchor.constraint(equalTo: root.leadingAnchor),
      status.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -12), statusHeight,
    ])
    scroll.borderType = .bezelBorder
    scroll.hasVerticalScroller = true
    scroll.scrollerStyle = .legacy
    scroll.autohidesScrollers = false
    editor.isRichText = false
    editor.importsGraphics = false
    editor.allowsUndo = true
    editor.isAutomaticQuoteSubstitutionEnabled = false
    editor.isAutomaticDashSubstitutionEnabled = false
    editor.isAutomaticTextReplacementEnabled = false
    editor.isAutomaticSpellingCorrectionEnabled = false
    editor.isContinuousSpellCheckingEnabled = false
    editor.isAutomaticLinkDetectionEnabled = false
    editor.textContainerInset = NSSize(width: 0, height: 2)
    editor.textContainer?.lineFragmentPadding = 2
    editor.minSize = .zero
    editor.maxSize = NSSize(
      width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
    editor.isVerticallyResizable = true
    let size = defaults.double(forKey: "fontSize")
    editor.font = NSFont(
      name: defaults.string(forKey: "fontName") ?? "Menlo", size: size > 0 ? size : 13)
    editor.delegate = self
    scroll.changeFontSize = { [weak self] steps in self?.changeFontSize(by: steps) }
    scroll.documentView = editor
  }
  @objc func closeWindow() { window.performClose(nil) }
  func applyWrap() {
    scroll.hasHorizontalScroller = !wrapping
    editor.isHorizontallyResizable = !wrapping
    editor.autoresizingMask = [.width]
    window.contentView?.layoutSubtreeIfNeeded()
    editor.setFrameSize(scroll.contentSize)
    editor.textContainer?.containerSize = NSSize(
      width: wrapping ? scroll.contentSize.width : CGFloat.greatestFiniteMagnitude,
      height: CGFloat.greatestFiniteMagnitude)
    editor.textContainer?.widthTracksTextView = wrapping
    editor.sizeToFit()
    statusHeight.constant = statusVisible ? 20 : 0
    status.isHidden = !statusVisible
    refresh()
  }
  func windowDidResize(_ notification: Notification) {
    editor.minSize = scroll.contentSize
  }
  func refresh() {
    window.title = name + " - My Notepad"
    caption.stringValue = window.title
    window.isDocumentEdited = edited
    guard statusVisible else { return }
    let string = editor.string as NSString
    let end = min(editor.selectedRange().location, string.length)
    let prefix = string.substring(to: end) as NSString
    let line = prefix.components(separatedBy: "\n").count
    let last = prefix.range(of: "\n", options: .backwards)
    let column = end - (last.location == NSNotFound ? 0 : NSMaxRange(last)) + 1
    status.stringValue = String(format: L("status.position"), line, column)
  }
  func textDidChange(_ notification: Notification) { refresh() }
  func textViewDidChangeSelection(_ notification: Notification) { if window != nil { refresh() } }
  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
  func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
    confirm() ? .terminateNow : .terminateCancel
  }
  func windowShouldClose(_ sender: NSWindow) -> Bool {
    guard confirm() else { return false }
    file.text = editor.string
    return true
  }
  func application(_ sender: NSApplication, openFile filename: String) -> Bool {
    let target = URL(fileURLWithPath: filename)
    if window == nil {
      pendingURL = target
      return true
    }
    return confirm() && load(target)
  }
  func alert(_ title: String, _ detail: String = "") {
    let a = NSAlert()
    a.messageText = title
    a.informativeText = detail
    a.addButton(withTitle: L("OK"))
    _ = runAlert(a)
  }
  func confirm() -> Bool {
    guard edited else { return true }
    let a = NSAlert()
    a.messageText = String(format: L("document.confirmSave"), name)
    for label in [L("Save"), L("Don’t Save"), L("Cancel")] { a.addButton(withTitle: label) }
    switch runAlert(a) {
    case .alertFirstButtonReturn: return save()
    case .alertSecondButtonReturn: return true
    default: return false
    }
  }
  func install(_ doc: TextFile, _ target: URL?) {
    file = doc
    url = target
    editor.string = doc.text
    editor.setSelectedRange(NSRange(location: 0, length: 0))
    if doc.text.components(separatedBy: "\n").first == ".LOG" {
      editor.setSelectedRange(NSRange(location: (doc.text as NSString).length, length: 0))
      insert("\n" + dateStamp() + "\n")
    }
    editor.undoManager?.removeAllActions()
    editor.scrollRangeToVisible(editor.selectedRange())
    refresh()
  }
  func load(_ target: URL, forced: TextEncoding? = nil) -> Bool {
    do {
      let doc = try TextFile(data: Data(contentsOf: target), forced: forced)
      install(doc, target)
      return true
    } catch {
      alert(L("The file could not be opened."), error.localizedDescription)
      return false
    }
  }
  func encodingPicker(_ panel: NSSavePanel, opening: Bool) -> NSPopUpButton {
    let picker = NSPopUpButton()
    if opening { picker.addItem(withTitle: L("Auto-detect")) }
    picker.addItems(withTitles: TextEncoding.allCases.map(\.title))
    picker.selectItem(at: opening ? 0 : file.encoding.rawValue)
    panel.accessoryView = NSStackView(views: [NSTextField(labelWithString: L("Encoding:")), picker])
    return picker
  }
  func openFile() {
    guard confirm() else { return }
    let p = NSOpenPanel()
    p.title = L("Open")
    let picker = encodingPicker(p, opening: true)
    p.isAccessoryViewDisclosed = true
    if presentingDialog(p, { p.runModal() }) == .OK, let target = p.url {
      _ = load(target, forced: TextEncoding(rawValue: picker.indexOfSelectedItem - 1))
    }
  }
  @discardableResult func save(asNew: Bool = false) -> Bool {
    var next = file
    var target = url
    if asNew || target == nil {
      let p = NSSavePanel()
      p.title = L("Save As")
      p.nameFieldStringValue = url?.lastPathComponent ?? (L("Untitled") + ".txt")
      p.directoryURL = url?.deletingLastPathComponent()
      p.allowedContentTypes = [
        url.flatMap { UTType(filenameExtension: $0.pathExtension) } ?? .plainText
      ]
      p.allowsOtherFileTypes = true
      p.isExtensionHidden = false
      let picker = encodingPicker(p, opening: false)
      guard presentingDialog(p, { p.runModal() }) == .OK, let chosen = p.url else { return false }
      target = chosen
      let enc = TextEncoding(rawValue: picker.indexOfSelectedItem)!
      if enc != next.encoding || url == nil { next.bom = enc != .ansi }
      next.encoding = enc
    }
    guard let target else { return false }
    next.text = editor.string
    do {
      let bytes: Data
      do { bytes = try next.data() } catch {
        let a = NSAlert()
        a.messageText = L("The selected encoding cannot represent all characters.")
        a.informativeText = L("Save as UTF-8 to preserve all text.")
        a.addButton(withTitle: L("Save as UTF-8"))
        a.addButton(withTitle: L("Cancel"))
        guard runAlert(a) == .alertFirstButtonReturn else { return false }
        next.encoding = .utf8
        next.bom = true
        bytes = try next.data()
      }
      try bytes.write(to: target, options: .atomic)
      file = next
      url = target
      refresh()
      return true
    } catch {
      alert(L("The file could not be saved."), error.localizedDescription)
      return false
    }
  }
  func dateStamp() -> String {
    let f = DateFormatter()
    f.timeStyle = .short
    f.dateStyle = .none
    let date = Date()
    let time = f.string(from: date)
    f.timeStyle = .none
    f.dateStyle = .short
    return time + " " + f.string(from: date)
  }
  func insert(_ text: String) { editor.insertText(text, replacementRange: editor.selectedRange()) }
}
