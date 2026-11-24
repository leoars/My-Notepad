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
  let updatesButton = NSButton(checkboxWithTitle: L("updates.automatic"), target: nil, action: nil)
  var updates = UpdatePreferences(defaults: .standard)
  let checkNowButton = NSButton(title: L("updates.check_now"), target: nil, action: nil)
  let updateStatus = NSTextField(wrappingLabelWithString: L("updates.status.idle"))
  /// The app's updater, for Check now and the status line; none in the tests.
  weak var updater: PackageUpdater? {
    didSet {
      updater?.changed = { [weak self] in self?.update() }
      update()
    }
  }
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
    var views: [NSView] = [heading, continueButton, continueDetail, newButton, newDetail]
    // Only the copies installed from GitHub update themselves; the store updates its own.
    if PackageUpdater.isAvailable {
      let updatesHeading = NSTextField(labelWithString: L("updates.heading"))
      updatesHeading.font = heading.font
      updatesButton.target = self
      updatesButton.action = #selector(toggleUpdates(_:))
      checkNowButton.target = self
      checkNowButton.action = #selector(checkNow(_:))
      checkNowButton.bezelStyle = .rounded
      // The option and Check now side by side, the status below, as in My Explorer's Options.
      let row = NSStackView(views: [updatesButton, checkNowButton])
      row.spacing = 12
      updateStatus.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
      updateStatus.textColor = .secondaryLabelColor
      updateStatus.preferredMaxLayoutWidth = 350
      updateStatus.widthAnchor.constraint(equalToConstant: 350).isActive = true
      // Room for two lines: the longest states take them in some languages.
      updateStatus.heightAnchor.constraint(greaterThanOrEqualToConstant: 2 * ceil(updateStatus.font!.boundingRectForFont.height)).isActive = true
      views += [updatesHeading, row, updateStatus]
    }
    let stack = NSStackView(views: views)
    stack.orientation = .vertical
    stack.alignment = .leading
    stack.spacing = 4
    stack.setCustomSpacing(10, after: heading)
    stack.setCustomSpacing(12, after: continueDetail)
    stack.setCustomSpacing(18, after: newDetail)
    if views.count > 5 { stack.setCustomSpacing(8, after: views[5]) }
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
    updatesButton.state = updates.automatic ? .on : .off
    updateStatus.stringValue = L(updater?.status ?? "updates.status.idle")
    checkNowButton.isEnabled = updater?.canCheckNow ?? false
  }

  @objc func checkNow(_ sender: NSButton) { updater?.checkNow() }

  @objc func toggleUpdates(_ sender: NSButton) {
    updates.automatic = sender.state == .on
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
