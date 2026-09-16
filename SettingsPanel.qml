import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.Commons
import qs.Ui
import "FontOptions.js" as Fonts
import "ClockModel.js" as Clock
import "ClockTheme.js" as Theme
import "PluginConfig.js" as Config

Item {
  id: root

  property var shell: null
  property var manifest: null
  property bool opened: false
  property bool closingFromHost: false

  readonly property bool openedState: root.opened
  readonly property string pluginId: manifest && manifest.id ? manifest.id : "MASH2RAFI.orbital-clock"
  readonly property bool popupBlocked: positionField.popupOpen
    || centerLayoutField.popupOpen
    || screenModeField.popupOpen
    || accentField.popupOpen
    || clockFontField.popupOpen
    || labelFontField.popupOpen
    || hourFontField.popupOpen
    || dateFontField.popupOpen
    || minuteCapsuleFontField.popupOpen
    || secondCapsuleFontField.popupOpen
  readonly property color scrim: Color.menu.scrim
  readonly property color cardBackground: Color.popups.background
  readonly property var cardBorderSpec: Border.surfaceSpec(
    "popups", "border", Color.popups.border, Math.max(1, Style.space(2))
  )
  readonly property int cardPadding: Style.spacing.panelPadding + Style.space(6)
  readonly property int contentGap: Style.space(16)
  readonly property int scrollBottomPad: Style.space(12)

  readonly property var fakeBar: QtObject {
    readonly property color foreground: Color.foreground
    readonly property color background: Color.background
    readonly property color urgent: Color.urgent
    readonly property string fontFamily: Style.font.family
    readonly property string position: "top"
    readonly property bool vertical: false
    readonly property int barSize: Style.bar.sizeHorizontal
  }

  readonly property var positionOptions: [
    { value: "top-left", label: "Top left" },
    { value: "top-center", label: "Top center" },
    { value: "top-right", label: "Top right" },
    { value: "middle-left", label: "Middle left" },
    { value: "middle-center", label: "Middle center" },
    { value: "middle-right", label: "Middle right" },
    { value: "bottom-left", label: "Bottom left" },
    { value: "bottom-center", label: "Bottom center" },
    { value: "bottom-right", label: "Bottom right" }
  ]

  readonly property var accentOptions: Theme.accentModeOptions()
  readonly property var layoutStyleOptions: Clock.layoutStyleOptions()
  readonly property var screenModeOptions: Clock.screenModeOptions()

  property string settingsPage: "general"
  property var draft: Clock.readSettings({})

  readonly property var clockFontOptions: Fonts.fontOptions(Fonts.CLOCK_FONTS, draft.clockFont)
  readonly property var labelFontOptions: Fonts.fontOptions(Fonts.LABEL_FONTS, draft.labelFont)
  readonly property var autoFontOption: [{ value: "", label: "Auto — match clock font" }]
  readonly property var hourFontOptions: autoFontOption.concat(Fonts.fontOptions(Fonts.CLOCK_FONTS, draft.hourFont))
  readonly property var dateFontOptions: autoFontOption.concat(Fonts.fontOptions(Fonts.CLOCK_FONTS, draft.dateFont))
  readonly property var minuteCapsuleFontOptions: autoFontOption.concat(Fonts.fontOptions(Fonts.CLOCK_FONTS, draft.minuteCapsuleFont))
  readonly property var secondCapsuleFontOptions: autoFontOption.concat(Fonts.fontOptions(Fonts.CLOCK_FONTS, draft.secondCapsuleFont))

  ShellConfigWatcher {
    id: liveConfig
    pluginId: root.pluginId
  }

  function pluginEntry() {
    return liveConfig.entry || Config.entryOrDefault(shell, root.pluginId)
  }

  function allScreenNames() {
    var names = []
    var screens = Quickshell.screens || []
    for (var i = 0; i < screens.length; i++) {
      var screen = screens[i]
      if (screen && screen.name) names.push(String(screen.name))
    }
    return names
  }

  function isDraftMonitorSelected(name) {
    return Clock.monitorListIncludes(root.draft.selectedMonitors, name)
  }

  function focusedMonitorName() {
    return Hyprland.focusedMonitor ? String(Hyprland.focusedMonitor.name || "") : ""
  }

  function isMonitorChecked(name, screen) {
    name = String(name || "")
    if (root.draft.screenMode === "all") return true
    if (root.draft.screenMode === "selected")
      return root.isDraftMonitorSelected(name)
    return Clock.shouldShowOnScreen(
      screen,
      root.draft.screenMode,
      "",
      root.focusedMonitorName(),
      root.draft.selectedMonitors
    )
  }

  function beginCustomMonitorSelection() {
    if (root.draft.screenMode === "selected") return
    var list = []
    var screens = Quickshell.screens || []
    for (var i = 0; i < screens.length; i++) {
      var screen = screens[i]
      if (!screen || !screen.name) continue
      var name = String(screen.name)
      if (root.isMonitorChecked(name, screen)) list.push(name)
    }
    root.patchDraft({ selectedMonitors: list, screenMode: "selected" })
  }

  function setDraftMonitorSelected(name, on) {
    name = String(name || "")
    if (name === "") return
    root.beginCustomMonitorSelection()
    var list = root.draft.selectedMonitors.slice()
    var idx = list.indexOf(name)
    if (on && idx < 0) list.push(name)
    else if (!on && idx >= 0) list.splice(idx, 1)
    root.patchDraft({ selectedMonitors: list })
  }

  function toggleDraftMonitor(name, screen) {
    root.setDraftMonitorSelected(name, !root.isMonitorChecked(name, screen))
  }

  function selectAllMonitors() {
    root.patchDraft({ screenMode: "selected", selectedMonitors: root.allScreenNames() })
  }

  function selectNoMonitors() {
    root.patchDraft({ screenMode: "selected", selectedMonitors: [] })
  }

  function applyDraft(entry) {
    draft = Clock.readSettings(entry)
  }

  function patchDraft(updates, save) {
    if (save === undefined) save = true
    draft = Clock.mergeSettings(root.pluginId, draft, updates)
    if (save) persist()
  }

  function syncFromConfig() {
    applyDraft(pluginEntry())
  }

  function resetToDefaults() {
    var defaults = Config.defaultSettings()
    defaults.savedLayouts = root.draft.savedLayouts
    applyDraft(defaults)
    persist()
  }

  function saveCurrentAsLayout(name) {
    var list = Clock.saveLayoutPreset(root.draft.savedLayouts, name, root.draft)
    root.patchDraft({ savedLayouts: list })
  }

  function applyLayout(id) {
    var preset = Clock.findLayoutPreset(root.draft.savedLayouts, id)
    if (!preset) return
    root.patchDraft(Clock.applyLayoutSnapshot(root.draft, preset.settings))
  }

  function renameLayout(id, name) {
    var list = Clock.updateLayoutPreset(root.draft.savedLayouts, id, { name: name })
    root.patchDraft({ savedLayouts: list })
  }

  function updateLayoutFromCurrent(id) {
    var list = Clock.updateLayoutPreset(root.draft.savedLayouts, id, { settings: root.draft })
    root.patchDraft({ savedLayouts: list })
  }

  function deleteLayout(id) {
    var list = Clock.removeLayoutPreset(root.draft.savedLayouts, id)
    root.patchDraft({ savedLayouts: list })
  }

  function refreshRateForScreen(screen) {
    return Clock.refreshRateForMonitor(Hyprland.monitorFor(screen))
  }

  function persist() {
    if (!shell || typeof shell.updateEntryInline !== "function") return
    shell.updateEntryInline(root.pluginId, Clock.settingsToEntry(root.pluginId, draft))
  }

  function open(payloadJson) {
    closingFromHost = false
    syncFromConfig()
    root.opened = true
    Qt.callLater(function() {
      if (keyCatcher) keyCatcher.forceActiveFocus()
    })
  }

  function close() {
    closingFromHost = true
    root.opened = false
    closingFromHost = false
  }

  function requestClose() {
    if (root.draft.screenMode === "selected" && root.draft.selectedMonitors.length === 0)
      root.patchDraft({ screenMode: "all", selectedMonitors: root.allScreenNames() })
    if (shell && typeof shell.hide === "function") shell.hide(root.pluginId)
    else root.close()
  }

  PanelWindow {
    id: panel
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "MASH2RAFI-orbital-clock-settings"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    onVisibleChanged: {
      if (!visible && !root.closingFromHost && root.shell && typeof root.shell.hide === "function")
        root.shell.hide(root.pluginId)
    }

    Rectangle {
      anchors.fill: parent
      color: root.scrim
    }

    MouseArea {
      anchors.fill: parent
      onClicked: root.requestClose()
    }

    BorderSurface {
      id: card
      anchors.centerIn: parent
      width: Math.min(Style.space(500), panel.width - Style.gapsOut * 6)
      height: Math.min(Style.space(780), panel.height - Style.gapsOut * 6)
      radius: Style.cornerRadius
      color: root.cardBackground
      borderSpec: root.cardBorderSpec
      padding: root.cardPadding

      MouseArea {
        anchors.fill: parent
        onClicked: {}
      }

      FocusScope {
        id: contentScope
        anchors.fill: parent
        anchors.topMargin: card.contentTopInset
        anchors.rightMargin: card.contentRightInset
        anchors.bottomMargin: card.contentBottomInset
        anchors.leftMargin: card.contentLeftInset
        focus: true

        readonly property real previewHeight: Style.space(112)
        readonly property real footerReserve: Math.max(settingsFooter.implicitHeight, 88)
        readonly property real scrollHeight: Math.max(
          160,
          height
            - titleBlock.height
            - pageTabs.height
            - previewFrame.height
            - footerReserve
            - root.contentGap * 4
        )

        PanelKeyCatcher {
          id: keyCatcher
          anchors.fill: parent
          blocked: root.popupBlocked
          onCloseRequested: root.requestClose()
        }

        Column {
          anchors.fill: parent
          spacing: root.contentGap

          Text {
            id: titleBlock
            width: parent.width
            text: "Orbital Clock"
            color: Color.foreground
            font.family: Style.font.family
            font.pixelSize: Style.font.title
            font.bold: true
            topPadding: Style.space(2)
          }

          Row {
            id: pageTabs
            width: parent.width
            spacing: Style.spacing.sm

            Button {
              width: (parent.width - parent.spacing * 3) / 4
              text: "General"
              bordered: root.settingsPage === "general"
              focusable: true
              onClicked: root.settingsPage = "general"
            }

            Button {
              width: (parent.width - parent.spacing * 3) / 4
              text: "Fonts & sizes"
              bordered: root.settingsPage === "fonts"
              focusable: true
              onClicked: root.settingsPage = "fonts"
            }

            Button {
              width: (parent.width - parent.spacing * 3) / 4
              text: "Components"
              bordered: root.settingsPage === "components"
              focusable: true
              onClicked: root.settingsPage = "components"
            }

            Button {
              width: (parent.width - parent.spacing * 3) / 4
              text: "Monitors"
              bordered: root.settingsPage === "monitors"
              focusable: true
              onClicked: root.settingsPage = "monitors"
            }
          }

          BorderSurface {
            id: previewFrame
            width: parent.width
            height: contentScope.previewHeight
            radius: Style.cornerRadius
            color: Qt.rgba(Color.background.r, Color.background.g, Color.background.b, 0.55)
            borderSpec: Border.localOrSurfaceSpec(
              "popups", "border", Color.popups.border, Color.foreground, Style.normalBorderWidth
            )

            Item {
              id: previewClip
              anchors.fill: parent
              anchors.margins: Style.space(10)
              clip: true

              Item {
                id: previewScaler
                scale: Math.min(
                  previewClip.width / Math.max(1, previewFace.implicitWidth),
                  previewClip.height / Math.max(1, previewFace.implicitHeight)
                ) * 0.9
                transformOrigin: Item.TopLeft
                x: (previewClip.width - previewFace.implicitWidth * scale) / 2
                y: (previewClip.height - previewFace.implicitHeight * scale) / 2

                OrbitalClockFace {
                  id: previewFace
                  active: root.opened
                  position: root.draft.position
                  centerLayout: root.draft.centerLayout
                  ringDiameter: root.draft.ringDiameter
                  ringGap: root.draft.ringGap
                  ringArcDegrees: root.draft.ringArcDegrees
                  ringTransparency: root.draft.ringTransparency
                  scaleFactor: root.draft.scale * 0.38
                  hourScaleFactor: root.draft.hourScale
                  dateScaleFactor: root.draft.dateScale
                  subtimeScaleFactor: root.draft.subtimeScale
                  ringLabelScaleFactor: root.draft.ringLabelScale
                  minuteCapsuleScaleFactor: root.draft.minuteCapsuleScale
                  secondCapsuleScaleFactor: root.draft.secondCapsuleScale
                  availableHeight: 420
                  availableWidth: 560
                  use24h: root.draft.use24h
                  showSeconds: root.draft.showSeconds
                  showDate: root.draft.showDate
                  accentMode: root.draft.accentMode
                  clockFont: root.draft.clockFont
                  labelFont: root.draft.labelFont
                  hourColor: root.draft.hourColor
                  dateColor: root.draft.dateColor
                  minuteCapsuleColor: root.draft.minuteCapsuleColor
                  secondCapsuleColor: root.draft.secondCapsuleColor
                  minuteRingColor: root.draft.minuteRingColor
                  secondRingColor: root.draft.secondRingColor
                  ringLabelColor: root.draft.ringLabelColor
                  hourFont: root.draft.hourFont
                  dateFont: root.draft.dateFont
                  minuteCapsuleFont: root.draft.minuteCapsuleFont
                  secondCapsuleFont: root.draft.secondCapsuleFont
                  showHour: root.draft.showHour
                  showMinuteCapsule: root.draft.showMinuteCapsule
                  showSecondCapsule: root.draft.showSecondCapsule
                  showRingLabels: root.draft.showRingLabels
                  showRings: root.draft.showRings
                  hourOffsetX: root.draft.hourOffsetX
                  hourOffsetY: root.draft.hourOffsetY
                  dateOffsetX: root.draft.dateOffsetX
                  dateOffsetY: root.draft.dateOffsetY
                  minuteCapsuleAngleOffset: root.draft.minuteCapsuleAngleOffset
                  secondCapsuleAngleOffset: root.draft.secondCapsuleAngleOffset
                  minuteCapsuleRadiusOffset: root.draft.minuteCapsuleRadiusOffset
                  secondCapsuleRadiusOffset: root.draft.secondCapsuleRadiusOffset
                  ringRotationOffset: root.draft.ringRotationOffset
                  lowPower: true
                }
              }
            }
          }

          Item {
            id: scrollHost
            width: parent.width
            height: contentScope.scrollHeight

            ScrollView {
              id: generalScroll
              anchors.fill: parent
              clip: true
              visible: root.settingsPage === "general"
              ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            Column {
              id: generalPage
              width: generalScroll.availableWidth
              spacing: root.contentGap

              Item {
                width: parent.width
                height: Style.space(4)
              }

              Text {
                width: parent.width
                wrapMode: Text.WordWrap
                text: "Changes apply immediately. Right-click the clock on your wallpaper to reopen this menu."
                color: Qt.darker(Color.foreground, 1.35)
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
              }

              PanelSeparator { width: parent.width }

              PanelSectionHeader {
                width: parent.width
                text: "Layout"
              }

              Dropdown {
                id: positionField
                width: parent.width
                label: "Position"
                value: root.draft.position
                options: root.positionOptions
                onChanged: function(v) {
                  root.patchDraft({
                    position: v,
                    ringArcDegrees: Clock.defaultArcDegreesForPosition(v)
                  })
                }
              }

              Dropdown {
                id: centerLayoutField
                width: parent.width
                label: "Layout style"
                value: root.draft.centerLayout
                options: root.layoutStyleOptions
                onChanged: function(v) {
                  root.patchDraft({ centerLayout: Clock.normalizeLayoutStyle(v) })
                }
              }

              PanelSeparator { width: parent.width }

              PanelSectionHeader {
                width: parent.width
                text: "Saved layouts"
              }

              Text {
                width: parent.width
                wrapMode: Text.WordWrap
                visible: root.draft.savedLayouts.length === 0
                text: "No saved layouts yet. Dial in a look anywhere in this panel, then save it below to switch back to it anytime."
                color: Qt.darker(Color.foreground, 1.45)
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
              }

              Repeater {
                model: root.draft.savedLayouts

                Column {
                  width: parent ? parent.width : implicitWidth
                  spacing: Style.spacing.sm

                  property var layoutData: modelData
                  property bool renaming: false

                  Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: layoutData.name
                    color: Color.foreground
                    font.family: Style.font.family
                    font.pixelSize: Style.font.body
                    font.bold: true
                  }

                  Flow {
                    width: parent.width
                    spacing: Style.spacing.sm

                    Button {
                      text: "Apply"
                      focusable: true
                      onClicked: root.applyLayout(layoutData.id)
                    }
                    Button {
                      text: "Update with current"
                      focusable: true
                      onClicked: root.updateLayoutFromCurrent(layoutData.id)
                    }
                    Button {
                      text: renaming ? "Cancel rename" : "Rename"
                      focusable: true
                      onClicked: renaming = !renaming
                    }
                    Button {
                      text: "Delete"
                      focusable: true
                      onClicked: root.deleteLayout(layoutData.id)
                    }
                  }

                  Row {
                    width: parent.width
                    visible: renaming
                    spacing: Style.spacing.sm

                    TextField {
                      id: renameField
                      width: parent.width - saveRenameBtn.implicitWidth - parent.spacing
                      text: layoutData.name
                      onAccepted: {
                        root.renameLayout(layoutData.id, text)
                        renaming = false
                      }
                    }
                    Button {
                      id: saveRenameBtn
                      text: "Save name"
                      focusable: true
                      onClicked: {
                        root.renameLayout(layoutData.id, renameField.text)
                        renaming = false
                      }
                    }
                  }

                  PanelSeparator { width: parent.width }
                }
              }

              Row {
                width: parent.width
                spacing: Style.spacing.sm

                TextField {
                  id: newLayoutName
                  width: parent.width - saveNewLayoutBtn.implicitWidth - parent.spacing
                  placeholderText: "New layout name"
                  onAccepted: {
                    if (text.trim() === "") return
                    root.saveCurrentAsLayout(text)
                    text = ""
                  }
                }
                Button {
                  id: saveNewLayoutBtn
                  text: "Save current as new layout"
                  focusable: true
                  enabled: newLayoutName.text.trim() !== ""
                  onClicked: {
                    root.saveCurrentAsLayout(newLayoutName.text)
                    newLayoutName.text = ""
                  }
                }
              }

              PanelSeparator { width: parent.width }

              PanelSectionHeader {
                width: parent.width
                text: "Rings"
              }

              SettingsSlider {
                width: parent.width
                bar: root.fakeBar
                label: "Ring diameter"
                helpText: "Outer ring size relative to screen height — independent of layout size and ring spacing."
                minimum: 0.25
                maximum: 0.55
                step: 0.01
                value: root.draft.ringDiameter
                valueText: Math.round(root.draft.ringDiameter * 100) + "%"
                onMoved: function(v) {
                  root.patchDraft({ ringDiameter: Clock.clampRingDiameter(v) }, false)
                }
                onReleased: function(v) {
                  root.patchDraft({ ringDiameter: Clock.clampRingDiameter(v) })
                }
              }

              SettingsSlider {
                width: parent.width
                bar: root.fakeBar
                label: "Ring spacing"
                helpText: "Gap between the minute and seconds rings in pixels — independent of layout size."
                minimum: 24
                maximum: 100
                step: 1
                value: root.draft.ringGap
                valueText: Math.round(root.draft.ringGap) + "px"
                onMoved: function(v) {
                  root.patchDraft({ ringGap: Clock.clampRingGap(v) }, false)
                }
                onReleased: function(v) {
                  root.patchDraft({ ringGap: Clock.clampRingGap(v) })
                }
              }

              SettingsSlider {
                width: parent.width
                bar: root.fakeBar
                label: "Ring arc"
                helpText: "How much of the ring is visible, centered on the dial focus. 360° shows the full circle."
                minimum: 30
                maximum: 360
                step: 5
                value: root.draft.ringArcDegrees
                valueText: Math.round(root.draft.ringArcDegrees) + "°"
                onMoved: function(v) {
                  root.patchDraft({
                    ringArcDegrees: Clock.clampRingArcDegrees(v, root.draft.position)
                  }, false)
                }
                onReleased: function(v) {
                  root.patchDraft({
                    ringArcDegrees: Clock.clampRingArcDegrees(v, root.draft.position)
                  })
                }
              }

              SettingsSlider {
                width: parent.width
                bar: root.fakeBar
                label: "Ring transparency"
                helpText: "Fade both rings together. 0% hides the rings; 100% is fully visible."
                minimum: 0
                maximum: 1
                step: 0.01
                livePreview: false
                value: root.draft.ringTransparency
                valueText: Math.round(root.draft.ringTransparency * 100) + "%"
                onReleased: function(v) {
                  root.patchDraft({ ringTransparency: Clock.clampRingOpacity(v) })
                }
              }

              Toggle {
                width: parent.width
                label: "Show seconds ring"
                description: "Show the outer seconds ring and capsule."
                checked: root.draft.showSeconds
                onClicked: {
                  root.patchDraft({ showSeconds: !root.draft.showSeconds })
                }
              }

              Dropdown {
                id: accentField
                width: parent.width
                label: "Ring colors"
                value: root.draft.accentMode
                options: root.accentOptions
                onChanged: function(v) {
                  root.patchDraft({ accentMode: Theme.normalizeAccentMode(v) })
                }
              }

              PanelSeparator { width: parent.width }

              PanelSectionHeader {
                width: parent.width
                text: "Hour & date"
              }

              Toggle {
                width: parent.width
                label: "24-hour clock"
                description: "Show hour in 24-hour format instead of 12-hour."
                checked: root.draft.use24h
                onClicked: {
                  root.patchDraft({ use24h: !root.draft.use24h })
                }
              }

              Toggle {
                width: parent.width
                label: "Show date block"
                description: "Show date and weekday with the hour."
                checked: root.draft.showDate
                onClicked: {
                  root.patchDraft({ showDate: !root.draft.showDate })
                }
              }

              PanelSeparator { width: parent.width }

              Item {
                width: parent.width
                height: root.scrollBottomPad
              }
            }
            }

            ScrollView {
              id: fontsScroll
              anchors.fill: parent
              clip: true
              visible: root.settingsPage === "fonts"
              ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            Column {
              id: fontsPage
              width: fontsScroll.availableWidth
              spacing: root.contentGap

              Item {
                width: parent.width
                height: Style.space(4)
              }

              Text {
                width: parent.width
                wrapMode: Text.WordWrap
                text: "Font and scale controls are independent — adjust each without affecting ring diameter or spacing."
                color: Qt.darker(Color.foreground, 1.35)
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
              }

              PanelSeparator { width: parent.width }

              PanelSectionHeader {
                width: parent.width
                text: "Sizes"
              }

              SettingsSlider {
                width: parent.width
                bar: root.fakeBar
                label: "Layout size"
                helpText: "Capsule chrome and dial padding."
                minimum: 0.5
                maximum: 2.5
                step: 0.05
                value: root.draft.scale
                valueText: root.draft.scale.toFixed(2) + "×"
                onMoved: function(v) {
                  root.patchDraft({ scale: Clock.roundScale(v) }, false)
                }
                onReleased: function(v) {
                  root.patchDraft({ scale: Clock.roundScale(v) })
                }
              }

              SettingsSlider {
                width: parent.width
                bar: root.fakeBar
                label: "Ring label size"
                helpText: "00–59 tick labels on the rings."
                minimum: 0.5
                maximum: 2.5
                step: 0.05
                value: root.draft.ringLabelScale
                valueText: root.draft.ringLabelScale.toFixed(2) + "×"
                onMoved: function(v) {
                  root.patchDraft({ ringLabelScale: Clock.roundScale(v) }, false)
                }
                onReleased: function(v) {
                  root.patchDraft({ ringLabelScale: Clock.roundScale(v) })
                }
              }

              SettingsSlider {
                width: parent.width
                bar: root.fakeBar
                label: "Hour size"
                minimum: 0.5
                maximum: 2.5
                step: 0.05
                value: root.draft.hourScale
                valueText: root.draft.hourScale.toFixed(2) + "×"
                onMoved: function(v) {
                  root.patchDraft({ hourScale: Clock.roundScale(v) }, false)
                }
                onReleased: function(v) {
                  root.patchDraft({ hourScale: Clock.roundScale(v) })
                }
              }

              SettingsSlider {
                width: parent.width
                bar: root.fakeBar
                label: "Date size"
                minimum: 0.5
                maximum: 2.5
                step: 0.05
                value: root.draft.dateScale
                valueText: root.draft.dateScale.toFixed(2) + "×"
                onMoved: function(v) {
                  root.patchDraft({ dateScale: Clock.roundScale(v) }, false)
                }
                onReleased: function(v) {
                  root.patchDraft({ dateScale: Clock.roundScale(v) })
                }
              }

              SettingsSlider {
                width: parent.width
                bar: root.fakeBar
                label: "Subtime size (legacy)"
                helpText: "Legacy — no current layout shows a separate subtime line; kept for older saved configs."
                minimum: 0.5
                maximum: 2.5
                step: 0.05
                value: root.draft.subtimeScale
                valueText: root.draft.subtimeScale.toFixed(2) + "×"
                onMoved: function(v) {
                  root.patchDraft({ subtimeScale: Clock.roundScale(v) }, false)
                }
                onReleased: function(v) {
                  root.patchDraft({ subtimeScale: Clock.roundScale(v) })
                }
              }

              SettingsSlider {
                width: parent.width
                bar: root.fakeBar
                label: "Minute capsule size"
                helpText: "Minute capsule chrome and text scale together, independent of the seconds capsule."
                minimum: 0.5
                maximum: 2.5
                step: 0.05
                value: root.draft.minuteCapsuleScale
                valueText: root.draft.minuteCapsuleScale.toFixed(2) + "×"
                onMoved: function(v) {
                  root.patchDraft({ minuteCapsuleScale: Clock.roundScale(v) }, false)
                }
                onReleased: function(v) {
                  root.patchDraft({ minuteCapsuleScale: Clock.roundScale(v) })
                }
              }

              SettingsSlider {
                width: parent.width
                bar: root.fakeBar
                label: "Second capsule size"
                helpText: "Seconds capsule chrome and text scale together, independent of the minute capsule."
                minimum: 0.5
                maximum: 2.5
                step: 0.05
                value: root.draft.secondCapsuleScale
                valueText: root.draft.secondCapsuleScale.toFixed(2) + "×"
                onMoved: function(v) {
                  root.patchDraft({ secondCapsuleScale: Clock.roundScale(v) }, false)
                }
                onReleased: function(v) {
                  root.patchDraft({ secondCapsuleScale: Clock.roundScale(v) })
                }
              }

              PanelSeparator { width: parent.width }

              PanelSectionHeader {
                width: parent.width
                text: "Fonts"
              }

              FontDropdown {
                id: clockFontField
                width: parent.width
                label: "Hour & date font"
                value: root.draft.clockFont
                options: root.clockFontOptions
                maxVisibleRows: 6
                onChanged: function(v) {
                  root.patchDraft({ clockFont: v })
                }
              }

              FontDropdown {
                id: labelFontField
                width: parent.width
                label: "Ring label font"
                value: root.draft.labelFont
                options: root.labelFontOptions
                maxVisibleRows: 6
                onChanged: function(v) {
                  root.patchDraft({ labelFont: v })
                }
              }

              PanelSeparator { width: parent.width }

              Item {
                width: parent.width
                height: root.scrollBottomPad
              }
            }
            }

            ScrollView {
              id: componentsScroll
              anchors.fill: parent
              clip: true
              visible: root.settingsPage === "components"
              ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            Column {
              id: componentsPage
              width: componentsScroll.availableWidth
              spacing: root.contentGap

              Item {
                width: parent.width
                height: Style.space(4)
              }

              Text {
                width: parent.width
                wrapMode: Text.WordWrap
                text: "Fine-tune each piece independently — color and font override the theme/clock-font defaults when set; offsets nudge position without disturbing auto-layout. Size and Show date/seconds live on the other tabs."
                color: Qt.darker(Color.foreground, 1.35)
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
              }

              Rectangle {
                width: parent.width
                height: hourCard.implicitHeight + Style.spacing.panelPadding * 2
                radius: Style.cornerRadius
                color: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.04)
                border.color: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.12)
                border.width: Math.max(1, Style.space(1))

                Column {
                  id: hourCard
                  x: Style.spacing.panelPadding
                  y: Style.spacing.panelPadding
                  width: parent.width - Style.spacing.panelPadding * 2
                  spacing: Style.spacing.md

                  PanelSectionHeader { width: parent.width; text: "Hour" }

                  Toggle {
                    width: parent.width
                    label: "Show hour"
                    checked: root.draft.showHour
                    onClicked: root.patchDraft({ showHour: !root.draft.showHour })
                  }

                  FontDropdown {
                    id: hourFontField
                    width: parent.width
                    label: "Hour font"
                    value: root.draft.hourFont
                    options: root.hourFontOptions
                    maxVisibleRows: 6
                    onChanged: function(v) { root.patchDraft({ hourFont: v }) }
                  }

                  ColorField {
                    width: parent.width
                    label: "Hour color"
                    helpText: "Overrides the theme-derived hour color."
                    value: root.draft.hourColor
                    onChanged: function(v) { root.patchDraft({ hourColor: v }) }
                  }

                  Row {
                    width: parent.width
                    spacing: Style.spacing.md

                    SettingsSlider {
                      width: (parent.width - parent.spacing) / 2
                      bar: root.fakeBar
                      label: "Horizontal offset"
                      minimum: -40
                      maximum: 40
                      step: 1
                      value: root.draft.hourOffsetX
                      valueText: Math.round(root.draft.hourOffsetX) + "px"
                      onMoved: function(v) { root.patchDraft({ hourOffsetX: Math.round(v) }, false) }
                      onReleased: function(v) { root.patchDraft({ hourOffsetX: Math.round(v) }) }
                    }

                    SettingsSlider {
                      width: (parent.width - parent.spacing) / 2
                      bar: root.fakeBar
                      label: "Vertical offset"
                      minimum: -40
                      maximum: 40
                      step: 1
                      value: root.draft.hourOffsetY
                      valueText: Math.round(root.draft.hourOffsetY) + "px"
                      onMoved: function(v) { root.patchDraft({ hourOffsetY: Math.round(v) }, false) }
                      onReleased: function(v) { root.patchDraft({ hourOffsetY: Math.round(v) }) }
                    }
                  }
                }
              }

              Rectangle {
                width: parent.width
                height: dateCard.implicitHeight + Style.spacing.panelPadding * 2
                radius: Style.cornerRadius
                color: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.04)
                border.color: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.12)
                border.width: Math.max(1, Style.space(1))

                Column {
                  id: dateCard
                  x: Style.spacing.panelPadding
                  y: Style.spacing.panelPadding
                  width: parent.width - Style.spacing.panelPadding * 2
                  spacing: Style.spacing.md

                  PanelSectionHeader { width: parent.width; text: "Date" }

                  FontDropdown {
                    id: dateFontField
                    width: parent.width
                    label: "Date font"
                    value: root.draft.dateFont
                    options: root.dateFontOptions
                    maxVisibleRows: 6
                    onChanged: function(v) { root.patchDraft({ dateFont: v }) }
                  }

                  ColorField {
                    width: parent.width
                    label: "Date color"
                    helpText: "Overrides the weekday line; date/AM-PM stay muted."
                    value: root.draft.dateColor
                    onChanged: function(v) { root.patchDraft({ dateColor: v }) }
                  }

                  Row {
                    width: parent.width
                    spacing: Style.spacing.md

                    SettingsSlider {
                      width: (parent.width - parent.spacing) / 2
                      bar: root.fakeBar
                      label: "Horizontal offset"
                      minimum: -40
                      maximum: 40
                      step: 1
                      value: root.draft.dateOffsetX
                      valueText: Math.round(root.draft.dateOffsetX) + "px"
                      onMoved: function(v) { root.patchDraft({ dateOffsetX: Math.round(v) }, false) }
                      onReleased: function(v) { root.patchDraft({ dateOffsetX: Math.round(v) }) }
                    }

                    SettingsSlider {
                      width: (parent.width - parent.spacing) / 2
                      bar: root.fakeBar
                      label: "Vertical offset"
                      minimum: -40
                      maximum: 40
                      step: 1
                      value: root.draft.dateOffsetY
                      valueText: Math.round(root.draft.dateOffsetY) + "px"
                      onMoved: function(v) { root.patchDraft({ dateOffsetY: Math.round(v) }, false) }
                      onReleased: function(v) { root.patchDraft({ dateOffsetY: Math.round(v) }) }
                    }
                  }
                }
              }

              Rectangle {
                width: parent.width
                height: minuteCapsuleCard.implicitHeight + Style.spacing.panelPadding * 2
                radius: Style.cornerRadius
                color: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.04)
                border.color: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.12)
                border.width: Math.max(1, Style.space(1))

                Column {
                  id: minuteCapsuleCard
                  x: Style.spacing.panelPadding
                  y: Style.spacing.panelPadding
                  width: parent.width - Style.spacing.panelPadding * 2
                  spacing: Style.spacing.md

                  PanelSectionHeader { width: parent.width; text: "Minute capsule" }

                  Toggle {
                    width: parent.width
                    label: "Show minute capsule"
                    checked: root.draft.showMinuteCapsule
                    onClicked: root.patchDraft({ showMinuteCapsule: !root.draft.showMinuteCapsule })
                  }

                  FontDropdown {
                    id: minuteCapsuleFontField
                    width: parent.width
                    label: "Minute capsule font"
                    value: root.draft.minuteCapsuleFont
                    options: root.minuteCapsuleFontOptions
                    maxVisibleRows: 6
                    onChanged: function(v) { root.patchDraft({ minuteCapsuleFont: v }) }
                  }

                  ColorField {
                    width: parent.width
                    label: "Minute capsule color"
                    helpText: "Overrides the minute capsule's text color."
                    value: root.draft.minuteCapsuleColor
                    onChanged: function(v) { root.patchDraft({ minuteCapsuleColor: v }) }
                  }

                  Row {
                    width: parent.width
                    spacing: Style.spacing.md

                    SettingsSlider {
                      width: (parent.width - parent.spacing) / 2
                      bar: root.fakeBar
                      label: "Angle offset"
                      minimum: -90
                      maximum: 90
                      step: 1
                      value: root.draft.minuteCapsuleAngleOffset
                      valueText: Math.round(root.draft.minuteCapsuleAngleOffset) + "°"
                      onMoved: function(v) { root.patchDraft({ minuteCapsuleAngleOffset: Math.round(v) }, false) }
                      onReleased: function(v) { root.patchDraft({ minuteCapsuleAngleOffset: Math.round(v) }) }
                    }

                    SettingsSlider {
                      width: (parent.width - parent.spacing) / 2
                      bar: root.fakeBar
                      label: "Radius offset"
                      minimum: -40
                      maximum: 40
                      step: 1
                      value: root.draft.minuteCapsuleRadiusOffset
                      valueText: Math.round(root.draft.minuteCapsuleRadiusOffset) + "px"
                      onMoved: function(v) { root.patchDraft({ minuteCapsuleRadiusOffset: Math.round(v) }, false) }
                      onReleased: function(v) { root.patchDraft({ minuteCapsuleRadiusOffset: Math.round(v) }) }
                    }
                  }
                }
              }

              Rectangle {
                width: parent.width
                height: secondCapsuleCard.implicitHeight + Style.spacing.panelPadding * 2
                radius: Style.cornerRadius
                color: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.04)
                border.color: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.12)
                border.width: Math.max(1, Style.space(1))

                Column {
                  id: secondCapsuleCard
                  x: Style.spacing.panelPadding
                  y: Style.spacing.panelPadding
                  width: parent.width - Style.spacing.panelPadding * 2
                  spacing: Style.spacing.md

                  PanelSectionHeader { width: parent.width; text: "Second capsule" }

                  Toggle {
                    width: parent.width
                    label: "Show second capsule"
                    checked: root.draft.showSecondCapsule
                    onClicked: root.patchDraft({ showSecondCapsule: !root.draft.showSecondCapsule })
                  }

                  FontDropdown {
                    id: secondCapsuleFontField
                    width: parent.width
                    label: "Second capsule font"
                    value: root.draft.secondCapsuleFont
                    options: root.secondCapsuleFontOptions
                    maxVisibleRows: 6
                    onChanged: function(v) { root.patchDraft({ secondCapsuleFont: v }) }
                  }

                  ColorField {
                    width: parent.width
                    label: "Second capsule color"
                    helpText: "Overrides the seconds capsule's text color."
                    value: root.draft.secondCapsuleColor
                    onChanged: function(v) { root.patchDraft({ secondCapsuleColor: v }) }
                  }

                  Row {
                    width: parent.width
                    spacing: Style.spacing.md

                    SettingsSlider {
                      width: (parent.width - parent.spacing) / 2
                      bar: root.fakeBar
                      label: "Angle offset"
                      minimum: -90
                      maximum: 90
                      step: 1
                      value: root.draft.secondCapsuleAngleOffset
                      valueText: Math.round(root.draft.secondCapsuleAngleOffset) + "°"
                      onMoved: function(v) { root.patchDraft({ secondCapsuleAngleOffset: Math.round(v) }, false) }
                      onReleased: function(v) { root.patchDraft({ secondCapsuleAngleOffset: Math.round(v) }) }
                    }

                    SettingsSlider {
                      width: (parent.width - parent.spacing) / 2
                      bar: root.fakeBar
                      label: "Radius offset"
                      minimum: -40
                      maximum: 40
                      step: 1
                      value: root.draft.secondCapsuleRadiusOffset
                      valueText: Math.round(root.draft.secondCapsuleRadiusOffset) + "px"
                      onMoved: function(v) { root.patchDraft({ secondCapsuleRadiusOffset: Math.round(v) }, false) }
                      onReleased: function(v) { root.patchDraft({ secondCapsuleRadiusOffset: Math.round(v) }) }
                    }
                  }
                }
              }

              Rectangle {
                width: parent.width
                height: ringsCard.implicitHeight + Style.spacing.panelPadding * 2
                radius: Style.cornerRadius
                color: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.04)
                border.color: Qt.rgba(Color.foreground.r, Color.foreground.g, Color.foreground.b, 0.12)
                border.width: Math.max(1, Style.space(1))

                Column {
                  id: ringsCard
                  x: Style.spacing.panelPadding
                  y: Style.spacing.panelPadding
                  width: parent.width - Style.spacing.panelPadding * 2
                  spacing: Style.spacing.md

                  PanelSectionHeader { width: parent.width; text: "Rings & tick labels" }

                  Toggle {
                    width: parent.width
                    label: "Show rings"
                    checked: root.draft.showRings
                    onClicked: root.patchDraft({ showRings: !root.draft.showRings })
                  }

                  Toggle {
                    width: parent.width
                    label: "Show tick labels"
                    checked: root.draft.showRingLabels
                    onClicked: root.patchDraft({ showRingLabels: !root.draft.showRingLabels })
                  }

                  ColorField {
                    width: parent.width
                    label: "Minute ring color"
                    helpText: "Overrides the inner ring's dot color."
                    value: root.draft.minuteRingColor
                    onChanged: function(v) { root.patchDraft({ minuteRingColor: v }) }
                  }

                  ColorField {
                    width: parent.width
                    label: "Second ring color"
                    helpText: "Overrides the outer ring's dot color."
                    value: root.draft.secondRingColor
                    onChanged: function(v) { root.patchDraft({ secondRingColor: v }) }
                  }

                  ColorField {
                    width: parent.width
                    label: "Ring label color"
                    helpText: "Overrides both rings' tick label color. Empty matches each ring's own dot color."
                    value: root.draft.ringLabelColor
                    onChanged: function(v) { root.patchDraft({ ringLabelColor: v }) }
                  }

                  SettingsSlider {
                    width: parent.width
                    bar: root.fakeBar
                    label: "Rotation offset"
                    helpText: "Rotates which tick sits at the dial focus — the visible arc and capsules don't move."
                    minimum: -180
                    maximum: 180
                    step: 1
                    value: root.draft.ringRotationOffset
                    valueText: Math.round(root.draft.ringRotationOffset) + "°"
                    onMoved: function(v) { root.patchDraft({ ringRotationOffset: Math.round(v) }, false) }
                    onReleased: function(v) { root.patchDraft({ ringRotationOffset: Math.round(v) }) }
                  }
                }
              }

              Item {
                width: parent.width
                height: root.scrollBottomPad
              }
            }
            }

            ScrollView {
              id: monitorsScroll
              anchors.fill: parent
              clip: true
              visible: root.settingsPage === "monitors"
              ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            Column {
              id: monitorsPage
              width: monitorsScroll.availableWidth
              spacing: root.contentGap

              Item {
                width: parent.width
                height: Style.space(4)
              }

              Text {
                width: parent.width
                wrapMode: Text.WordWrap
                text: "Control which outputs show the clock and how each screen sizes the dial."
                color: Qt.darker(Color.foreground, 1.35)
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
              }

              PanelSeparator { width: parent.width }

              PanelSectionHeader {
                width: parent.width
                text: "Monitors"
              }

              Text {
                width: parent.width
                wrapMode: Text.WordWrap
                text: Quickshell.screens.length + " monitor"
                  + (Quickshell.screens.length === 1 ? "" : "s") + " detected — choose where the clock appears."
                color: Color.foreground
                font.family: Style.font.family
                font.pixelSize: Style.font.bodySmall
                font.bold: true
              }

              Row {
                width: parent.width
                spacing: Style.spacing.sm

                Button {
                  text: "Select all"
                  bordered: true
                  onClicked: root.selectAllMonitors()
                }

                Button {
                  text: "Select none"
                  bordered: true
                  onClicked: root.selectNoMonitors()
                }
              }

              Repeater {
                model: Quickshell.screens

                BorderSurface {
                  required property var modelData
                  width: monitorsPage.width
                  radius: Style.cornerRadius
                  color: Qt.rgba(Color.background.r, Color.background.g, Color.background.b, 0.35)
                  borderSpec: Border.localOrSurfaceSpec(
                    "popups", "border", Color.popups.border, Color.foreground, Style.normalBorderWidth
                  )
                  padding: Style.space(10)
                  implicitHeight: screenRow.implicitHeight + padding * 2

                  Column {
                    id: screenRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Style.spacing.xs

                    Text {
                      width: parent.width
                      text: modelData.name || "Unknown"
                      color: Color.foreground
                      font.family: Style.font.family
                      font.pixelSize: Style.font.body
                      font.bold: true
                    }

                    Text {
                      width: parent.width
                      text: modelData.width + " × " + modelData.height + " px · "
                        + Clock.formatRefreshRate(root.refreshRateForScreen(modelData))
                      color: Qt.darker(Color.foreground, 1.35)
                      font.family: Style.font.family
                      font.pixelSize: Style.font.caption
                    }

                    Toggle {
                      width: parent.width
                      label: "Show clock on this monitor"
                      checked: root.isMonitorChecked(modelData.name, modelData)
                      onClicked: root.toggleDraftMonitor(modelData.name, modelData)
                    }
                  }
                }
              }

              Text {
                width: parent.width
                wrapMode: Text.WordWrap
                visible: root.draft.screenMode === "selected" && root.draft.selectedMonitors.length === 0
                text: "No monitors selected — the clock will be hidden on every output. Re-open settings with: omarchy-shell shell summon MASH2RAFI.orbital-clock \"{}\""
                color: Color.urgent
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
              }

              PanelSeparator { width: parent.width }

              PanelSectionHeader {
                width: parent.width
                text: "Display preset"
              }

              Dropdown {
                id: screenModeField
                width: parent.width
                label: "Quick preset"
                value: root.draft.screenMode
                options: root.screenModeOptions
                onChanged: function(v) {
                  var mode = Clock.normalizeScreenMode(v)
                  var monitors = root.draft.selectedMonitors
                  if (mode === "all")
                    monitors = root.allScreenNames()
                  else if (mode === "selected" && monitors.length === 0)
                    monitors = root.allScreenNames()
                  root.patchDraft({ screenMode: mode, selectedMonitors: monitors })
                }
              }

              Text {
                width: parent.width
                wrapMode: Text.WordWrap
                text: "Use the toggles above to pick monitors directly. Presets override that selection — All shows every output; Custom keeps your picks; others follow primary, focused, or external rules."
                color: Qt.darker(Color.foreground, 1.45)
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
              }

              Text {
                width: parent.width
                wrapMode: Text.WordWrap
                text: "Ring repaint is capped at 60 Hz per monitor (1 Hz when seconds are off). The settings preview uses a slower tick while open."
                color: Qt.darker(Color.foreground, 1.45)
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
              }

              PanelSeparator { width: parent.width }

              PanelSectionHeader {
                width: parent.width
                text: "Per-monitor sizing"
              }

              Toggle {
                width: parent.width
                label: "Scale per monitor"
                description: "Adjust clock size by each monitor height relative to the reference below."
                checked: root.draft.perMonitorScale
                onClicked: {
                  root.patchDraft({ perMonitorScale: !root.draft.perMonitorScale })
                }
              }

              NumberField {
                width: parent.width
                label: "Reference height (px)"
                value: root.draft.scaleReferenceHeight
                from: 720
                to: 2160
                stepSize: 10
                onModified: function(v) {
                  root.patchDraft({ scaleReferenceHeight: Clock.clampReferenceHeight(v) })
                }
              }

              PanelSeparator { width: parent.width }

              PanelSectionHeader {
                width: parent.width
                text: "Placement"
              }

              NumberField {
                width: parent.width
                label: "Edge margin (px)"
                value: root.draft.margin
                from: 0
                to: 240
                stepSize: 1
                onModified: function(v) {
                  root.patchDraft({ margin: v })
                }
              }

              NumberField {
                width: parent.width
                label: "Bar padding (px, 0 = auto)"
                value: root.draft.barPadding
                from: 0
                to: 240
                stepSize: 1
                onModified: function(v) {
                  root.patchDraft({ barPadding: v })
                }
              }

              Text {
                width: parent.width
                wrapMode: Text.WordWrap
                text: "Bar padding adds extra inset when the Omarchy bar shares the same edge. 0 auto-detects."
                color: Qt.darker(Color.foreground, 1.45)
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
              }

              PanelSeparator { width: parent.width }

              Item {
                width: parent.width
                height: root.scrollBottomPad
              }
            }
            }
          }

          Column {
            id: settingsFooter
            width: parent.width
            spacing: Style.spacing.sm

            Button {
              width: parent.width
              text: "Reset to defaults"
              bordered: true
              focusable: true
              onClicked: root.resetToDefaults()
            }

            Button {
              width: parent.width
              text: "Close"
              focusable: true
              onClicked: root.requestClose()
            }
          }
        }
      }
    }
  }
}
