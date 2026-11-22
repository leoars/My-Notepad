import AppKit

final class Caption: NSView {
  override var mouseDownCanMoveWindow: Bool { true }
  override func mouseDown(with event: NSEvent) {
    if event.clickCount == 2 { window?.zoom(nil) } else { window?.performDrag(with: event) }
  }
  override func draw(_ dirtyRect: NSRect) {
    NSGradient(colors: [
      NSColor(red: 0.73, green: 0.84, blue: 0.94, alpha: 1),
      NSColor(red: 0.88, green: 0.93, blue: 0.98, alpha: 1),
    ])?.draw(in: bounds, angle: 90)
  }
}
