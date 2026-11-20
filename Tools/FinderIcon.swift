import AppKit

let bundle = URL(fileURLWithPath: CommandLine.arguments[2]).standardizedFileURL
let workspace = NSWorkspace.shared
if CommandLine.arguments[1] == "clear" {
    // Remove os metadados do ícone personalizado antes de assinar uma nova compilação.
    let metadata = bundle.appendingPathComponent("Icon\r")
    if FileManager.default.fileExists(atPath: metadata.path) {
        guard workspace.setIcon(nil, forFile: bundle.path) else { exit(1) }
    }
} else {
    let url = bundle.appendingPathComponent("Contents/Resources/Notepad.icns")
    guard let icon = NSImage(contentsOf: url),
          workspace.setIcon(icon, forFile: bundle.path) else { exit(1) }
}
