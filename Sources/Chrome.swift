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
final class CaptionButton: NSButton {
  enum Kind { case minimize, maximize, close }
  let kind: Kind
  init(_ kind: Kind, title: String, target: AnyObject, action: Selector) {
    self.kind = kind
    super.init(frame: .zero)
    self.target = target
    self.action = action
    isBordered = false
    toolTip = title
    setAccessibilityLabel(title)
  }
  required init?(coder: NSCoder) { fatalError() }
  override func draw(_ dirtyRect: NSRect) {
    let red = kind == .close
    let top =
      red ? NSColor(red: 0.98, green: 0.73, blue: 0.65, alpha: 1) : NSColor(white: 0.97, alpha: 1)
    let bottom =
      red
      ? NSColor(red: 0.72, green: 0.24, blue: 0.18, alpha: 1)
      : NSColor(red: 0.62, green: 0.75, blue: 0.86, alpha: 1)
    NSGradient(starting: bottom, ending: top)?.draw(in: bounds, angle: 90)
    NSColor(white: 0.35, alpha: 0.6).setStroke()
    NSBezierPath(rect: bounds.insetBy(dx: 0.5, dy: 0.5)).stroke()
    let x = bounds.midX
    let y = bounds.midY
    let p = NSBezierPath()
    if kind == .maximize { p.appendRect(NSRect(x: x - 4, y: y - 3, width: 8, height: 6)) }
    if kind == .minimize {
      p.move(to: NSPoint(x: x - 4, y: y + 2))
      p.line(to: NSPoint(x: x + 4, y: y + 2))
    }
    if red {
      p.move(to: NSPoint(x: x - 4, y: y - 4))
      p.line(to: NSPoint(x: x + 4, y: y + 4))
      p.move(to: NSPoint(x: x + 4, y: y - 4))
      p.line(to: NSPoint(x: x - 4, y: y + 4))
    }
    (red ? NSColor.white : .black).setStroke()
    p.lineWidth = 1.8
    p.stroke()
  }
}
