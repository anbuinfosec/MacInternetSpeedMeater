import Cocoa
import SwiftUI
import Network

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    var statusItem: NSStatusItem?
    let popover = NSPopover()
    var monitor = SpeedMonitor()
    var pathMonitor = NWPathMonitor()
    let queue = DispatchQueue(label: "InternetConnectionMonitor")

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let contentView = ContentView(monitor: monitor)

        popover.contentSize = NSSize(width: 300, height: 220)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: contentView)

        pathMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                if path.status == .satisfied {
                    self?.showStatusItem()
                } else {
                    self?.hideStatusItem()
                }
            }
        }
        pathMonitor.start(queue: queue)
    }

    func showStatusItem() {
        guard statusItem == nil else { return }
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            updateButtonTitle(button)
            button.action = #selector(togglePopover(_:))
            button.target = self
        }

        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let button = self.statusItem?.button else { return }
            self.updateButtonTitle(button)
        }
    }

    func hideStatusItem() {
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
            popover.performClose(nil)
        }
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem?.button else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func updateButtonTitle(_ button: NSStatusBarButton) {
        let up = monitor.uploadSpeed
        let down = monitor.downloadSpeed
        let upText = formatSpeed(speedInKBps: up)
        let downText = formatSpeed(speedInKBps: down)

        button.title = "⬆︎ \(upText)  ⬇︎ \(downText)"
        button.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
    }

    func formatSpeed(speedInKBps: Double) -> String {
        if speedInKBps < 1024 {
            return String(format: "%.0f KB/s", speedInKBps)
        } else {
            return String(format: "%.2f MB/s", speedInKBps / 1024)
        }
    }
}
