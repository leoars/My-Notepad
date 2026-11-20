import AppKit

extension Notepad {
  func centerDialog(_ dialog: NSWindow) {
    guard let parent = window, parent !== dialog else { return }
    let frame = parent.frame
    let size = dialog.frame.size
    var origin = NSPoint(x: frame.midX - size.width / 2, y: frame.midY - size.height / 2)
    if let visible = parent.screen?.visibleFrame {
      origin.x = max(visible.minX, min(origin.x, visible.maxX - size.width))
      origin.y = max(visible.minY, min(origin.y, visible.maxY - size.height))
    }
    if dialog.frame.origin != origin { dialog.setFrameOrigin(origin) }
  }

  // AppKit creates some panels lazily and chooses a screen location during
  // presentation. Observe only for the duration of this particular command.
  func presentingDialog<Result>(_ expected: NSWindow? = nil, _ present: () -> Result) -> Result {
    let notifications = NotificationCenter.default
    let observers = [NSWindow.didBecomeKeyNotification, NSWindow.didResizeNotification].map { name in
      notifications.addObserver(forName: name, object: expected, queue: nil) { [weak self] note in
        guard let self, let dialog = note.object as? NSWindow,
          dialog !== self.window, expected != nil || dialog.isKeyWindow,
          dialog.sheetParent == nil else { return }
        self.centerDialog(dialog)
      }
    }
    defer { observers.forEach(notifications.removeObserver) }
    return present()
  }

  func runAlert(_ alert: NSAlert) -> NSApplication.ModalResponse {
    presentingDialog(alert.window) { alert.runModal() }
  }

}
