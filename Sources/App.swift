import AppKit
import UniformTypeIdentifiers

/// The application: it keeps one `Notepad` per window and decides where an opened file goes.
final class NotepadApp: NSObject, NSApplicationDelegate {
  private(set) var documents: [Notepad] = []
  private var pending: [URL] = []
  private var launched = false
  /// Off in the tests, which build windows without putting them on screen.
  var showsWindows = true

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
    launched = true
    let first = newDocument()
    restoreDrafts()
    NSApp.activate(ignoringOtherApps: true)
    let waiting = pending
    pending = []
    for target in waiting { open(target) }
    DispatchQueue.main.async { first.offerDefaultTextEditor() }
    if showsWindows { updater.startAutomatically() }
  }

  /// Updates from the GitHub releases; absent from the App Store build.
  lazy var updater = PackageUpdater(appName: "My Notepad", repository: "leoars/My-Notepad", prefix: "My-Notepad") {
    [weak self] in self?.frontDocument?.window
  }

  /// A new, empty window, placed a step below and to the right of the frontmost one.
  @discardableResult func newDocument() -> Notepad {
    let previous = frontDocument?.window
    let document = Notepad()
    document.owner = self
    documents.append(document)
    if showsWindows { document.show(after: previous) }
    return document
  }

  /// The document of the frontmost window, or the last one opened when none is on screen.
  var frontDocument: Notepad? {
    for window in NSApp.orderedWindows where window.isVisible {
      if let document = documents.first(where: { $0.window === window }) { return document }
    }
    return documents.last
  }

  /// Opens a file that came from outside the window: the Finder, My Explorer or the Dock. A file
  /// already open brings its window forward; an empty untitled window takes the file; otherwise
  /// the file gets a window of its own, so the document on screen is never asked to give way.
  @discardableResult func open(_ target: URL) -> Bool {
    guard launched else {
      pending.append(target)
      return true
    }
    let key = Notepad.identity(of: target)
    if let open = documents.first(where: { $0.url.map(Notepad.identity) == key }) {
      if showsWindows { open.window.makeKeyAndOrderFront(nil) }
      return true
    }
    let front = frontDocument
    if let front, front.isPristine { return front.load(target) }
    let file: TextFile
    do {
      file = try Notepad.read(target)
    } catch {
      if let front {
        front.alert(L("The file could not be opened."), error.localizedDescription)
      }
      return false
    }
    newDocument().install(file, target)
    return true
  }

  func application(_ sender: NSApplication, openFile filename: String) -> Bool {
    open(URL(fileURLWithPath: filename))
  }

  func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    if !flag { frontDocument?.window.makeKeyAndOrderFront(nil) }
    return true
  }

  func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
    let menu = NSMenu()
    menu.addItem(withTitle: L("New Window"), action: #selector(newWindowFromDock), keyEquivalent: "").target = self
    return menu
  }

  @objc private func newWindowFromDock() {
    newDocument()
    NSApp.activate(ignoringOtherApps: true)
  }

  /// One Settings window for the app. Turning the option on writes the drafts of the windows with
  /// changes at once; turning it off removes them, so nothing comes back that was not asked for.
  lazy var settings: SettingsPanel = {
    let panel = SettingsPanel()
    panel.updater = updater
    panel.changed = { [weak self] on in
      for document in self?.documents ?? [] {
        if on { document.keepDraft() } else { DraftStore.remove(document.draftID) }
      }
    }
    return panel
  }()

  func showSettings(over window: NSWindow?) { settings.show(over: window) }

  func closed(_ document: Notepad) {
    documents.removeAll { $0 === document }
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

  /// With Continue the previous session chosen in Settings, quitting, also when the Mac restarts or
  /// logs out, asks nothing: what was not saved is kept as a draft and comes back at the next
  /// launch. Otherwise, or when a draft cannot be written, it asks about each document with
  /// changes, front to back, showing its window first.
  func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
    let ordered = NSApp.orderedWindows.compactMap { window in documents.first { $0.window === window } }
    for document in ordered + documents.filter({ d in !ordered.contains { $0 === d } }) where document.edited {
      if document.keepDraft() { continue }
      document.window.makeKeyAndOrderFront(nil)
      guard document.confirm() else { return .terminateCancel }
    }
    return .terminateNow
  }

  /// Brings back, each in its own window, the drafts the last run left. The empty window of the
  /// launch takes the first one.
  func restoreDrafts() {
    guard SettingsPanel.continuesSession else { return }
    let me = ProcessInfo.processInfo.processIdentifier
    let identifier = Bundle.main.bundleIdentifier
    let drafts = DraftStore.leftovers { pid in
      pid != me && NSRunningApplication(processIdentifier: pid)?.bundleIdentifier == identifier
        && identifier != nil
    }
    for draft in drafts {
      let target = documents.count == 1 && documents[0].isPristine ? documents[0] : newDocument()
      target.restore(draft)
    }
  }
}

extension Notification.Name {
  /// Word wrap, the status bar and the font are settings of the application: every window
  /// follows a change made in any of them.
  static let notepadPreferencesChanged = Notification.Name("NotepadPreferencesChanged")
}

/// One window and its document.
final class Notepad: NSObject, NSWindowDelegate, NSTextViewDelegate, NSMenuItemValidation {
  var window: NSWindow!
  weak var owner: NotepadApp?
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
  /// The same commands by their Command key, carried out without the menu: the App Shortcuts of
  /// the system can move a menu shortcut to another key, and then Command stops answering.
  var commandShortcuts: [String: NSMenuItem] = [:]
  var menuStrip = NSStackView()
  var menus: [NSMenu] = []
  /// This window's menu bar, installed while the window is key.
  var mainMenu = NSMenu()
  var windowMenuItem = NSMenuItem()
  /// File > Open Recent of this window.
  var recentMenu: NSMenu?
  var keyMonitor: Any?
  /// The draft this window writes while its document has changes not saved.
  var draftID = UUID()
  var draftPending = false
  var isClosed = false
  /// A file reopened through a security-scoped bookmark, accessed while the window is open.
  var scopedURL: URL?
  var edited: Bool { editor.string != file.text }
  var name: String { url?.lastPathComponent ?? L("Untitled") }
  /// An untitled window nobody has typed in: a file opened from outside may take it.
  var isPristine: Bool { url == nil && editor.string.isEmpty && file.text.isEmpty }

  override init() {
    super.init()
    window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 760, height: 495),
      styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
      backing: .buffered, defer: true)
    window.delegate = self
    window.titleVisibility = .hidden
    window.titlebarAppearsTransparent = true
    window.minSize = NSSize(width: 360, height: 180)
    window.isReleasedWhenClosed = false
    window.tabbingMode = .disallowed
    layout()
    buildMenus()
    applyWrap()
    refresh()
    NotificationCenter.default.addObserver(
      self, selector: #selector(preferencesChanged(_:)), name: .notepadPreferencesChanged, object: nil)
  }

  /// Puts the window on screen. The first one keeps the remembered frame; the others cascade from
  /// the window in front, and start again at the top of the screen when they would leave it.
  func show(after previous: NSWindow?) {
    if let previous {
      var frame = previous.frame
      frame.origin.x += 22
      frame.origin.y -= 22
      if let visible = (previous.screen ?? NSScreen.main)?.visibleFrame,
         frame.maxX > visible.maxX || frame.minY < visible.minY {
        frame.origin = NSPoint(x: visible.minX + 22, y: visible.maxY - frame.height - 22)
      }
      window.setFrame(window.constrainFrameRect(frame, to: previous.screen), display: false)
    } else {
      window.center()
      window.setFrameAutosaveName("My Notepad")
    }
    window.makeKeyAndOrderFront(nil)
    window.makeFirstResponder(editor)
    keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
      guard let self, NSApp.keyWindow == self.window, NSApp.modalWindow == nil else { return event }
      return self.handleEditorShortcut(event) ? nil : event
    }
  }

  func offerDefaultTextEditor() {
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
      if let button = menuStrip.arrangedSubviews.compactMap({ $0 as? NSButton }).first(where: { $0.tag == i }) {
        showMenu(button)
      }
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
    if mods == .command || mods == [.command, .shift] {
      let key = (mods.contains(.shift) ? "+" : "") + (event.charactersIgnoringModifiers?.lowercased() ?? "")
      guard let item = commandShortcuts[key] else { return false }
      // Cut, Copy, Paste and Select All belong to whatever is being edited; outside the editor
      // they are left to the menu and the responder chain.
      if item.target == nil, window.firstResponder !== editor { return false }
      if validateMenuItem(item) { invoke(item) } else { NSSound.beep() }
      return true
    }
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
  func textDidChange(_ notification: Notification) {
    refresh()
    scheduleDraft()
  }
  func textViewDidChangeSelection(_ notification: Notification) { if window != nil { refresh() } }
  /// With the session kept, closing never asks: changes not saved stay in a draft. Otherwise, or
  /// when the draft cannot be written, the window asks, so nothing is lost silently.
  func windowShouldClose(_ sender: NSWindow) -> Bool {
    if !keepDraft() {
      guard confirm() else { return false }
      file.text = editor.string
    }
    return true
  }
  func windowWillClose(_ notification: Notification) {
    isClosed = true
    if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
    keyMonitor = nil
    finder?.panel.close()
    finder = nil
    NotificationCenter.default.removeObserver(self)
    owner?.closed(self)
    scopedURL?.stopAccessingSecurityScopedResource()
    scopedURL = nil
    // The menu commands hold the window's controller: let them go once the command that closed
    // the window has returned, so a closed window is freed.
    DispatchQueue.main.async { self.handlers.removeAll() }
  }
  func windowDidBecomeKey(_ notification: Notification) { installMenus() }
  @objc func preferencesChanged(_ notification: Notification) {
    guard notification.object as AnyObject? !== self else { return }
    let size = defaults.double(forKey: "fontSize")
    if let font = NSFont(name: defaults.string(forKey: "fontName") ?? "Menlo", size: size > 0 ? size : 13) {
      editor.font = font
    }
    applyWrap()
  }
  /// Tells the other windows that word wrap, the status bar or the font changed.
  func announcePreferences() {
    NotificationCenter.default.post(name: .notepadPreferencesChanged, object: self)
  }
  /// Writes the draft about a second after the first change, then again after the next ones, so
  /// even a Mac that stops at once loses at most the last second of typing.
  func scheduleDraft() {
    guard SettingsPanel.continuesSession, !draftPending else { return }
    draftPending = true
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
      guard let self else { return }
      self.draftPending = false
      if !self.isClosed { self.keepDraft() }
    }
  }

  /// Writes this window's draft, or removes it when nothing is left unsaved. False when the draft
  /// could not be written, or when the session is not kept (see Settings): then closing asks.
  @discardableResult func keepDraft() -> Bool {
    guard edited else {
      DraftStore.remove(draftID)
      return true
    }
    guard SettingsPanel.continuesSession else { return false }
    let bookmark = url.flatMap {
      (try? $0.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil))
        ?? (try? $0.bookmarkData())
    }
    let draft = Draft(
      id: draftID, file: file, text: editor.string, path: url?.path, bookmark: bookmark,
      selection: editor.selectedRange().location, frame: NSStringFromRect(window.frame),
      saved: Date(), process: ProcessInfo.processInfo.processIdentifier)
    do {
      try DraftStore.write(draft)
      return true
    } catch {
      return false
    }
  }

  /// Puts a draft back on screen: the file it came from, the text that was not saved, the caret
  /// and the window's place. The draft is written again at once, now owned by this process.
  func restore(_ draft: Draft) {
    var target = draft.path.map { URL(fileURLWithPath: $0) }
    if let bookmark = draft.bookmark {
      var stale = false
      if let resolved = (try? URL(resolvingBookmarkData: bookmark, options: .withSecurityScope, bookmarkDataIsStale: &stale))
        ?? (try? URL(resolvingBookmarkData: bookmark, bookmarkDataIsStale: &stale)) {
        target = resolved
        if resolved.startAccessingSecurityScopedResource() { scopedURL = resolved }
      }
    }
    draftID = draft.id
    file = draft.file
    url = target
    editor.string = draft.text
    let location = min(max(0, draft.selection), (draft.text as NSString).length)
    editor.setSelectedRange(NSRange(location: location, length: 0))
    editor.undoManager?.removeAllActions()
    if let frame = draft.frame.map(NSRectFromString), frame.width >= window.minSize.width,
       NSScreen.screens.contains(where: { $0.visibleFrame.intersects(frame) }) {
      window.setFrame(frame, display: false)
    }
    editor.scrollRangeToVisible(editor.selectedRange())
    refresh()
    keepDraft()
  }

  /// The same file reached by another path (a symbolic link, a different spelling) is the same
  /// document.
  static func identity(of url: URL) -> URL { url.standardizedFileURL.resolvingSymlinksInPath() }
  static func read(_ target: URL, forced: TextEncoding? = nil) throws -> TextFile {
    try TextFile(data: Data(contentsOf: target), forced: forced)
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
    DraftStore.remove(draftID)
    draftID = UUID()
    scopedURL?.stopAccessingSecurityScopedResource()
    scopedURL = nil
    file = doc
    url = target
    if let target { RecentFiles.shared.add(target) }
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
      let doc = try Notepad.read(target, forced: forced)
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
      RecentFiles.shared.add(target)
      refresh()
      if !edited { DraftStore.remove(draftID) }
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
