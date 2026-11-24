import AppKit

/// File > Open Recent: the last files opened or saved, most recent first, one list for every
/// window. Each keeps a bookmark beside its path, so the App Store copy, in its sandbox, can open
/// it again, and a file moved or renamed in the Finder is still found.
final class RecentFiles {
  static let key = "recentFiles"
  /// As many as File > Open Recent shows in the Mac's own apps.
  static let limit = 10
  static var shared = RecentFiles(defaults: .standard)

  struct Entry {
    var url: URL
    var bookmark: Data?
  }

  let defaults: UserDefaults
  /// Off in the tests: the Dock and the Finder's recent items hear about each file too.
  let notesSystem: Bool
  private(set) var entries: [Entry]

  init(defaults: UserDefaults, notesSystem: Bool = true) {
    self.defaults = defaults
    self.notesSystem = notesSystem
    let stored = defaults.array(forKey: RecentFiles.key) as? [[String: Any]] ?? []
    var entries: [Entry] = []
    for item in stored {
      guard let path = item["path"] as? String else { continue }
      let url = URL(fileURLWithPath: path)
      if entries.contains(where: { Notepad.identity(of: $0.url) == Notepad.identity(of: url) }) { continue }
      entries.append(Entry(url: url, bookmark: item["bookmark"] as? Data))
    }
    self.entries = Array(entries.prefix(RecentFiles.limit))
  }

  var urls: [URL] { entries.map(\.url) }

  /// Puts the file first, once; when the list is full the oldest one leaves.
  func add(_ url: URL) {
    let file = url.standardizedFileURL
    let key = Notepad.identity(of: file)
    entries.removeAll { Notepad.identity(of: $0.url) == key }
    entries.insert(Entry(url: file, bookmark: RecentFiles.bookmark(for: file)), at: 0)
    if entries.count > RecentFiles.limit { entries.removeLast(entries.count - RecentFiles.limit) }
    save()
    if notesSystem { NSDocumentController.shared.noteNewRecentDocumentURL(file) }
  }

  /// Takes a file that no longer exists off the list.
  func remove(_ url: URL) {
    let key = Notepad.identity(of: url)
    entries.removeAll { Notepad.identity(of: $0.url) == key }
    save()
  }

  /// Clear Menu, which also empties the recent files the Dock shows.
  func clear() {
    entries = []
    save()
    if notesSystem { NSDocumentController.shared.clearRecentDocuments(nil) }
  }

  /// The file at `index`, found through its bookmark, which follows it when it is moved. `scoped`
  /// says the sandbox access was opened and must be closed when the file is let go.
  func resolve(at index: Int) -> (url: URL, scoped: Bool)? {
    guard entries.indices.contains(index) else { return nil }
    var entry = entries[index]
    guard let bookmark = entry.bookmark else { return (entry.url, false) }
    var stale = false
    var scoped = false
    if let found = try? URL(resolvingBookmarkData: bookmark, options: .withSecurityScope, bookmarkDataIsStale: &stale) {
      entry.url = found
      scoped = found.startAccessingSecurityScopedResource()
    } else if let found = try? URL(resolvingBookmarkData: bookmark, bookmarkDataIsStale: &stale) {
      entry.url = found
    }
    if entry.url != entries[index].url || stale {
      if stale { entry.bookmark = RecentFiles.bookmark(for: entry.url) ?? bookmark }
      entries[index] = entry
      save()
    }
    return (entry.url, scoped)
  }

  /// What the menu shows: the name, and the folder when two files have the same name.
  func titles() -> [String] {
    let names = entries.map { $0.url.lastPathComponent }
    return entries.enumerated().map { index, entry in
      let name = names[index]
      guard names.filter({ $0 == name }).count > 1 else { return name }
      return name + " — " + entry.url.deletingLastPathComponent().lastPathComponent
    }
  }

  static func bookmark(for url: URL) -> Data? {
    (try? url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil))
      ?? (try? url.bookmarkData())
  }

  private func save() {
    defaults.set(entries.map { entry -> [String: Any] in
      var item: [String: Any] = ["path": entry.url.path]
      if let bookmark = entry.bookmark { item["bookmark"] = bookmark }
      return item
    }, forKey: RecentFiles.key)
  }
}

extension Notepad: NSMenuDelegate {
  /// File > Open Recent, below Open…; its items are rebuilt each time it opens, so every window
  /// shows the list as it is now.
  func addRecentMenu(to file: NSMenu) {
    let holder = NSMenuItem(title: L("Open Recent"), action: nil, keyEquivalent: "")
    holder.identifier = NSUserInterfaceItemIdentifier("Open Recent")
    let submenu = NSMenu(title: L("Open Recent"))
    submenu.delegate = self
    holder.submenu = submenu
    file.addItem(holder)
    recentMenu = submenu
    menuNeedsUpdate(submenu)
  }

  func menuNeedsUpdate(_ menu: NSMenu) {
    guard menu === recentMenu else { return }
    menu.removeAllItems()
    let recents = RecentFiles.shared
    for (index, title) in recents.titles().enumerated() {
      let item = NSMenuItem(title: title, action: #selector(openRecent(_:)), keyEquivalent: "")
      item.target = self
      item.tag = index
      item.toolTip = recents.entries[index].url.path
      menu.addItem(item)
    }
    if menu.numberOfItems > 0 { menu.addItem(.separator()) }
    let clear = NSMenuItem(title: L("Clear Menu"), action: #selector(clearRecents(_:)), keyEquivalent: "")
    clear.target = self
    clear.identifier = NSUserInterfaceItemIdentifier("Clear Menu")
    menu.addItem(clear)
  }

  /// Opens a recent file as Open… does, in this window after asking about unsaved changes. A file
  /// already open in another window brings that window forward instead; one that no longer exists
  /// leaves the list.
  @objc func openRecent(_ item: NSMenuItem) {
    guard let (target, scoped) = RecentFiles.shared.resolve(at: item.tag) else { return }
    func release() { if scoped { target.stopAccessingSecurityScopedResource() } }
    let key = Notepad.identity(of: target)
    if let other = owner?.documents.first(where: { $0 !== self && $0.url.map(Notepad.identity) == key }) {
      release()
      if !other.isClosed { other.window.makeKeyAndOrderFront(nil) }
      return
    }
    guard confirm() else { return release() }
    do {
      install(try Notepad.read(target), target)
      if scoped { scopedURL = target }
    } catch {
      release()
      if !FileManager.default.fileExists(atPath: target.path) { RecentFiles.shared.remove(target) }
      alert(L("The file could not be opened."), error.localizedDescription)
    }
  }

  @objc func clearRecents(_ sender: Any?) { RecentFiles.shared.clear() }
}
