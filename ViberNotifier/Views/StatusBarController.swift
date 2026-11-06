import AppKit
import Monitor

let defaultIconSize: CGFloat = 18
let defaultIcon = NSImage(named: "ViberMenuBarIcon")!

// Keep the colored badge outside the template image rendered by NSStatusBarButton.
private final class BadgeOverlayView: NSView {
    var image: NSImage? {
        didSet { needsDisplay = true }
    }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func draw(_ dirtyRect: NSRect) {
        guard let button = superview as? NSStatusBarButton,
              let image = image,
              let imageRect = button.cell?.imageRect(forBounds: button.bounds) else { return }
        image.draw(in: convert(imageRect, from: button), from: .zero,
                   operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
    }
}

class StatusBarController: NSObject {
    private var statusBar: NSStatusBar!
    private var isDark = false
    private var latestBadgeText = ""
    private let badgeOverlay = BadgeOverlayView()
    public var statusItem: NSStatusItem!
    public var monitoredApp: MonitoredApp? {
        didSet {
            refreshIcon()
        }
    }
    private var monitoredAppIcon: NSImage?

    override init() {
        super.init()
        setupStatusBar()
    }

    func setupStatusBar(icon: NSImage? = nil) {
        statusBar = .system
        statusItem = statusBar.statusItem(withLength: defaultIconSize)
        if let statusBarButton = statusItem.button {
            statusBarButton.sendAction(on: [.leftMouseUp, .rightMouseUp])
            statusBarButton.image = icon ?? defaultIcon
            statusBarButton.image?.size = NSSize(width: defaultIconSize, height: defaultIconSize)
            statusBarButton.image?.isTemplate = true
            statusBarButton.imagePosition = .imageLeft
            statusBarButton.action = #selector(onIconClicked(sender:))
            statusBarButton.target = self
            badgeOverlay.frame = statusBarButton.bounds
            badgeOverlay.autoresizingMask = [.width, .height]
            badgeOverlay.setAccessibilityElement(false)
            statusBarButton.addSubview(badgeOverlay)
            statusBarButton.toolTip = "Viber Notifier — click to open Viber; right-click for options"
        }
    }

    func refreshIcon() {
        monitoredAppIcon = defaultIcon.copy() as? NSImage

        if(AppSettings.isIconMask(for: monitoredApp?.appName ?? "") && isDark) {
            monitoredAppIcon = monitoredAppIcon?.invert()
        }

        updateBadgeText(latestBadgeText, force: true)
    }

    @objc func onIconClicked(sender: AnyObject) {
        let isRightClick = NSApp.currentEvent?.isRightClick == true
        let isOptionKeyHolding = NSEvent.modifierFlags.contains(.option)
        if isRightClick || isOptionKeyHolding {
            let menu = NSMenu()
            if !AXIsProcessTrusted() {
                let permissionItem = menu.addItem(withTitle: "Allow Accessibility Access…", action: #selector(openAccessibilitySettings), keyEquivalent: "")
                permissionItem.target = self
                menu.addItem(.separator())
            }
            let quitItem = menu.addItem(withTitle: "Quit Viber Notifier", action: #selector(quit), keyEquivalent: "q")
            quitItem.target = self
            if let button = statusItem.button {
                statusItem.menu = menu
                button.performClick(nil)
                statusItem.menu = nil
            }
        } else if let bundleId = monitoredApp?.bundleId,
                  let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func openAccessibilitySettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    func monitorApp(app: MonitoredApp) {
        monitoredApp = app

        let appName = app.appName
        statusItem.autosaveName = "ViberNotifier_\(app.bundleId)"
        updateBadgeText(nil)

        guard let monitoredAppIcon = monitoredAppIcon else {
            return
        }
        updateBadgeIcon(icon: monitoredAppIcon, size: CGSize(width: defaultIconSize, height: defaultIconSize))

        MonitorService.observe(appName: appName, bundleIdentifier: app.bundleId) { [weak self] badge in
            let appRunning = MonitorService.isMonitoredAppRunning(bundleIdentifier: app.bundleId)
            let appIsNotRunningAndIconShouldBeHidden = AppSettings.hideWhenAppNotRunning && !appRunning
            let badgeIsEmptyAndIconShouldBeHidden = AppSettings.hideWhenNothingComing && (badge.isNil || badge?.isEmpty == true)

            if appIsNotRunningAndIconShouldBeHidden || badgeIsEmptyAndIconShouldBeHidden {
                self?.hideStatusBar()
            } else {
                let currentIsDark = self?.statusItem.button?.effectiveAppearance.name.rawValue.lowercased().contains("dark") ?? false
                if(self?.isDark != currentIsDark) {
                    self?.isDark = currentIsDark
                    self?.refreshIcon()
                }

                self?.updateBadgeText(badge)
            }
        }
    }

    func hideStatusBar() {
        statusItem.isVisible = false
    }

    func updateBadgeText(_ text: String?, force: Bool = false) {
        statusItem.isVisible = true

        guard !AppSettings.showOnlyAppIcon else {
            latestBadgeText = text ?? ""
            refreshAppIcon()
            return
        }

        let newText = text ?? ""
        guard force || latestBadgeText != newText else {
            return
        }

        let textWidth = (text ?? "")
            .width(withConstrainedHeight: defaultIconSize, font: .systemFont(ofSize: 14))
        statusItem.length = defaultIconSize + textWidth

        guard let monitoredAppIcon = monitoredAppIcon else {
            return
        }

        if AppSettings.showAsRedBadge {
            badgeOverlay.image = newText.isEmpty ? nil : monitoredAppIcon.addBadgeToImage(drawText: newText, includingIcon: false)
            let defaultIcon = monitoredAppIcon
            let adjustedIcon = (newText.isEmpty && AppSettings.grayoutIconWhenNothingComing) ? (defaultIcon.grayOut() ?? defaultIcon) : defaultIcon
            updateBadgeIcon(icon: adjustedIcon)
            statusItem.length = defaultIconSize
            statusItem.button?.title = ""
        } else {
            badgeOverlay.image = nil
            let defaultIcon = monitoredAppIcon
            let adjustedIcon = (newText.isEmpty && AppSettings.grayoutIconWhenNothingComing) ? (defaultIcon.grayOut() ?? defaultIcon) : defaultIcon
            updateBadgeIcon(icon: adjustedIcon)
            statusItem.length = defaultIconSize + textWidth
            updateBadgeIcon(icon: adjustedIcon, size: CGSize(width: defaultIconSize, height: defaultIconSize))
            statusItem.button?.title = newText
        }

        latestBadgeText = newText
    }

    func refreshDisplayMode() {
        if AppSettings.showOnlyAppIcon {
            refreshAppIcon()
        } else {
            updateBadgeText(latestBadgeText, force: true)
        }
    }

    func refreshAppIcon() {
        badgeOverlay.image = nil
        guard let monitoredAppIcon else { return }
        let adjustedIcon = (latestBadgeText.isEmpty && AppSettings.grayoutIconWhenNothingComing) ? (monitoredAppIcon.grayOut() ?? monitoredAppIcon) : monitoredAppIcon
        statusItem.length = defaultIconSize
        statusItem.button?.title = ""
        updateBadgeIcon(icon: adjustedIcon, size: CGSize(width: defaultIconSize, height: defaultIconSize))
    }

    func updateBadgeIcon(icon: NSImage?, size: CGSize? = nil) {
        icon?.isTemplate = true
        statusItem.button?.image = icon
        if let iconSize = size ?? icon?.size {
            statusItem.button?.image?.size = iconSize
        }
    }

}

extension String {
    func width(withConstrainedHeight height: CGFloat, font: NSFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)

        return ceil(boundingBox.width)
    }
}

extension NSScreen {
    var safeAreaTopInset: CGFloat {
        guard #available(macOS 12, *) else { return 0 }
        return safeAreaInsets.top
    }

    static var screenWithMouse: NSScreen? {
        let mouseLocation = NSEvent.mouseLocation
        let screens = NSScreen.screens
        let screenWithMouse = (screens.first {
            NSMouseInRect(mouseLocation, $0.frame, false)
        })

        return screenWithMouse
    }
    var hasTopNotchDesign: Bool {
        guard #available(macOS 12, *) else { return false }
        return safeAreaInsets.top != 0
    }
}
