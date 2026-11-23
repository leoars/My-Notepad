import AppKit

let application = NSApplication.shared
let delegate = NotepadApp()
application.setActivationPolicy(.regular)
application.delegate = delegate
application.run()
