import AppKit

let application = NSApplication.shared
let delegate = Notepad()
application.setActivationPolicy(.regular)
application.delegate = delegate
application.run()
