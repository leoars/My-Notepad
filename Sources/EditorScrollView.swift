import AppKit

final class EditorScrollView: NSScrollView {
  var changeFontSize: ((Int) -> Void)?
  private var accumulatedPixels: CGFloat = 0
  private var zoomGesture = false

  override func scrollWheel(with event: NSEvent) {
    if !event.momentumPhase.isEmpty && zoomGesture { return }
    zoomGesture = event.modifierFlags.contains(.control)
    guard zoomGesture else {
      accumulatedPixels = 0
      super.scrollWheel(with: event)
      return
    }

    let delta = event.scrollingDeltaY * (event.isDirectionInvertedFromDevice ? -1 : 1)
    guard event.momentumPhase.isEmpty, delta != 0 else { return }
    if event.hasPreciseScrollingDeltas {
      if event.phase.contains(.began) || accumulatedPixels * delta < 0 { accumulatedPixels = 0 }
      accumulatedPixels += delta
      let steps = Int(accumulatedPixels / 16)
      if steps != 0 {
        accumulatedPixels -= CGFloat(steps) * 16
        changeFontSize?(steps)
      }
    } else {
      changeFontSize?(delta > 0 ? 1 : -1)
    }
  }
}
