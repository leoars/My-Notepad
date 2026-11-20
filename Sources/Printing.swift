import AppKit

final class PrintedText: NSTextView {
  var heading = "", footing = "", filename = ""
  func expand(_ pattern: String) -> NSAttributedString {
    let page = NSPrintOperation.current?.currentPage ?? 1
    var parts = ["", "", ""]
    var alignment = 1
    var iterator = pattern.makeIterator()
    let date = Date()
    while let ch = iterator.next() {
      guard ch == "&", let code = iterator.next() else {
        parts[alignment].append(ch)
        continue
      }
      switch code.lowercased() {
      case "l": alignment = 0
      case "c": alignment = 1
      case "r": alignment = 2
      case "f": parts[alignment] += filename
      case "p": parts[alignment] += String(page)
      case "d":
        parts[alignment] += DateFormatter.localizedString(
          from: date, dateStyle: .short, timeStyle: .none)
      case "t":
        parts[alignment] += DateFormatter.localizedString(
          from: date, dateStyle: .none, timeStyle: .short)
      case "&": parts[alignment] += "&"
      default: parts[alignment] += "&" + String(code)
      }
    }
    let style = NSMutableParagraphStyle()
    style.tabStops = [
      NSTextTab(textAlignment: .center, location: bounds.width / 2),
      NSTextTab(textAlignment: .right, location: bounds.width),
    ]
    return NSAttributedString(
      string: parts.joined(separator: "\t"),
      attributes: [.paragraphStyle: style, .font: NSFont.systemFont(ofSize: 10)])
  }
  override var pageHeader: NSAttributedString { expand(heading) }
  override var pageFooter: NSAttributedString { expand(footing) }
}
extension Notepad {
  func pageSetup() {
    let a = NSAlert()
    a.messageText = L("Page Setup")
    let head = NSTextField(string: header)
    let foot = NSTextField(string: footer)
    let margins = [
      printInfo.leftMargin, printInfo.rightMargin, printInfo.topMargin, printInfo.bottomMargin,
    ].map { NSTextField(string: String(format: "%.1f", $0 * 25.4 / 72)) }
    a.accessoryView = form(
      [(L("Header:"), head), (L("Footer:"), foot)]
        + Array(
          zip([L("Left (mm):"), L("Right (mm):"), L("Top (mm):"), L("Bottom (mm):")], margins)))
    a.addButton(withTitle: L("OK"))
    a.addButton(withTitle: L("Paper and Orientation…"))
    a.addButton(withTitle: L("Cancel"))
    let staged = printInfo.copy() as! NSPrintInfo
    while true {
      switch runAlert(a) {
      case .alertSecondButtonReturn:
        _ = presentingDialog { NSPageLayout().runModal(with: staged) }
        continue
      case .alertFirstButtonReturn:
        let values = margins.compactMap {
          Double($0.stringValue.replacingOccurrences(of: ",", with: ".")).map {
            CGFloat($0 * 72 / 25.4)
          }
        }
        guard values.count == 4, values.allSatisfy({ $0 >= 0 }),
          values[0] + values[1] < staged.paperSize.width - 12,
          values[2] + values[3] < staged.paperSize.height - 12
        else {
          alert(L("The margins must fit on the page."))
          continue
        }
        staged.leftMargin = values[0]
        staged.rightMargin = values[1]
        staged.topMargin = values[2]
        staged.bottomMargin = values[3]
        printInfo = staged
        header = head.stringValue
        footer = foot.stringValue
      default: break
      }
      return
    }
  }
  func printDocument() {
    let info = printInfo.copy() as! NSPrintInfo
    let width = max(12, info.paperSize.width - info.leftMargin - info.rightMargin)
    let view = PrintedText(frame: NSRect(x: 0, y: 0, width: width, height: 12))
    view.heading = header
    view.footing = footer
    view.filename = name
    view.isRichText = false
    view.string = editor.string
    view.font = editor.font
    view.isVerticallyResizable = true
    view.textContainer?.containerSize = NSSize(
      width: width, height: CGFloat.greatestFiniteMagnitude)
    view.textContainer?.widthTracksTextView = true
    view.sizeToFit()
    info.horizontalPagination = .fit
    info.verticalPagination = .automatic
    info.isVerticallyCentered = false
    info.dictionary()[NSPrintInfo.AttributeKey.headerAndFooter] = true
    _ = presentingDialog { NSPrintOperation(view: view, printInfo: info).run() }
  }
}
