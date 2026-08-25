import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Ui

// Text-only toast naming the keybind that just fired. Modeled on the
// built-in OSD (qs.plugins.osd) for visual consistency, but without an
// icon column (nothing to center around, nothing to leave a stray gap)
// and with a generous, wrap-capable text width instead of a hard
// single-line elide, so most keybind descriptions never truncate.
Item {
  id: root

  property bool opened: false
  property string message: ""
  property int duration: 1200

  // The IPC target is callable by any local process, not just our own
  // Lua config -- these bound what a caller can force this plugin to
  // retain/render, regardless of intent behind the call.
  readonly property int maxPayloadBytes: 8192
  readonly property int maxMessageLength: 300
  readonly property int maxDurationMs: 10000

  readonly property int pad: Style.space(16)
  // Generous cap: most descriptions fit on one line under this; the
  // longest wrap to a second line instead of eliding.
  readonly property int maxTextWidth: Style.space(360)
  // TextMetrics.advanceWidth is a font-metrics ideal width; the actual bold
  // Text item can need a hair more (kerning/ink overhang), and with zero
  // slack that was enough to push single-line messages like "Close window"
  // into an unwanted wrap. A few px of buffer fixes it without being
  // visually noticeable.
  readonly property int textWidth: Math.min(Math.ceil(messageMetrics.advanceWidth) + Style.space(4), root.maxTextWidth)

  function show(rawMessage, rawDuration) {
    var msg = String(rawMessage || "")
    if (msg.length > root.maxMessageLength) msg = msg.slice(0, root.maxMessageLength)
    message = msg

    var parsedDuration = parseInt(rawDuration || "1200", 10)
    if (isNaN(parsedDuration)) parsedDuration = 1200
    duration = Math.max(0, Math.min(parsedDuration, root.maxDurationMs))

    opened = true
    if (duration > 0) hideTimer.restart()
    else hideTimer.stop()
  }

  function open(payloadJson) {
    var raw = payloadJson || "{}"
    // Reject oversized payloads before parsing -- the IPC target is
    // callable by any local process, so this can't rely on well-behaved
    // callers.
    if (raw.length > root.maxPayloadBytes) return
    try {
      var p = JSON.parse(raw)
      show(p.message || "", p.duration === undefined ? "1200" : String(p.duration))
    } catch (e) {}
  }

  function close() { opened = false }

  Timer {
    id: hideTimer
    interval: root.duration
    onTriggered: root.opened = false
  }

  TextMetrics {
    id: messageMetrics
    font.family: Style.font.family
    font.bold: true
    font.pixelSize: Style.font.title
    text: root.message
  }

  IpcHandler {
    target: "keybindToast"
    function show(payloadJson: string): string {
      root.open(payloadJson)
      return "ok"
    }
    function close(): string { root.close(); return "ok" }
    function state(): string { return root.opened ? "open" : "closed" }
    function ping(): string { return "ok" }
  }

  PanelWindow {
    id: panel
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "keybind-toast"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    // Visual-only surface: keep the layer-shell input region empty so the
    // toast never blocks clicks to the desktop below it.
    mask: Region {}

    BorderSurface {
      id: card
      width: card.borderLeft + root.pad + root.textWidth + root.pad + card.borderRight
      height: card.borderTop + root.pad + textItem.height + root.pad + card.borderBottom
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      anchors.bottomMargin: Style.space(67)
      color: Util.alpha(Color.background, 0.97)
      borderSpec: Border.surfaceSpec("popups", "border", Color.popups.border, Math.max(1, Style.space(2)))
      radius: Style.cornerRadius
      opacity: root.opened ? 1 : 0

      Text {
        id: textItem
        anchors.centerIn: parent
        width: root.textWidth
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        maximumLineCount: 2
        elide: Text.ElideRight
        text: root.message
        font: messageMetrics.font
        color: Color.popups.text
      }
    }
  }
}
