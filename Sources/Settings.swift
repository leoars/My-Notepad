import AppKit

/// The Settings window: what happens to the documents not saved when a window closes or the app
/// quits. On by default: closing asks nothing and what was not saved comes back; with Start a new
/// session chosen, closing asks whether to save, as in the original.
final class SettingsPanel: NSObject, NSWindowDelegate {
  static let key = "restoreSession"
  static var continuesSession: Bool { UserDefaults.standard.object(forKey: key) as? Bool ?? true }

  let panel = NSPanel(
    contentRect: .zero, styleMask: [.titled, .closable], backing: .buffered, defer: true)
  let continueButton = NSButton(radioButtonWithTitle: L("settings.continue"), target: nil, action: nil)
  let newButton = NSButton(radioButtonWithTitle: L("settings.new"), target: nil, action: nil)
  /// Called after the choice changes, so the open windows write or drop their drafts.
  var changed: ((Bool) -> Void)?

  override init() {
    super.init()
    panel.title = L("Settings")
    panel.isReleasedWhenClosed = false
    panel.delegate = self
    for button in [continueButton, newButton] {
      button.target = self
      button.action = #selector(choose(_:))
    }
    func detail(_ text: String) -> NSTextField {
      let label = NSTextField(wrappingLabelWithString: text)
      label.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
      label.textColor = .secondaryLabelColor
      label.preferredMaxLayoutWidth = 330
      label.widthAnchor.constraint(equalToConstant: 330).isActive = true
      return label
    }
    let heading = NSTextField(labelWithString: L("settings.startup"))
    heading.font = .boldSystemFont(ofSize: NSFont.systemFontSize)
    let continueDetail = detail(L("settings.continue.detail"))
    let newDetail = detail(L("settings.new.detail"))
    let stack = NSStackView(views: [heading, continueButton, continueDetail, newButton, newDetail])
    stack.orientation = .vertical
    stack.alignment = .leading
    stack.spacing = 4
    stack.setCustomSpacing(10, after: heading)
    stack.setCustomSpacing(12, after: continueDetail)
    // The details line up with the titles of the radio buttons.
    for label in [continueDetail, newDetail] {
      label.leadingAnchor.constraint(equalTo: stack.leadingAnchor, constant: 20).isActive = true
    }
    stack.edgeInsets = NSEdgeInsets(top: 18, left: 20, bottom: 20, right: 20)
    panel.contentView = stack
    panel.setContentSize(stack.fittingSize)
    update()
  }

  func update() {
    continueButton.state = SettingsPanel.continuesSession ? .on : .off
    newButton.state = SettingsPanel.continuesSession ? .off : .on
  }

  @objc func choose(_ sender: NSButton) {
    let on = sender === continueButton
    UserDefaults.standard.set(on, forKey: SettingsPanel.key)
    update()
    changed?(on)
  }

  func show(over parent: NSWindow?) {
    update()
    if !panel.isVisible, let parent {
      let frame = parent.frame, size = panel.frame.size
      panel.setFrameOrigin(NSPoint(x: frame.midX - size.width / 2, y: frame.midY - size.height / 2))
    }
    panel.makeKeyAndOrderFront(nil)
  }
}
