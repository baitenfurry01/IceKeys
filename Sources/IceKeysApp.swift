import AppKit
import SwiftUI
import Combine

@main
enum IceKeysApp {
    static let delegate = AppDelegate()
    static func main() {
        let app = NSApplication.shared
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let model = AppModel()
    private var window: NSWindow!
    private var statusItem: NSStatusItem!
    private var enabledItem: NSMenuItem!
    private var stateItem: NSMenuItem!
    private var subscriptions = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let appMenu = NSMenu()
        let root = NSMenuItem()
        let submenu = NSMenu()
        submenu.addItem(withTitle: "退出冰键", action: #selector(quit), keyEquivalent: "q").target = self
        root.submenu = submenu
        appMenu.addItem(root)
        // Standard text editing actions remain available in the practice field.
        let editRoot = NSMenuItem(title: "编辑", action: nil, keyEquivalent: "")
        let editMenu = NSMenu(title: "编辑")
        editMenu.addItem(withTitle: "撤销", action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(withTitle: "剪切", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "复制", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "粘贴", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "全选", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editRoot.submenu = editMenu
        appMenu.addItem(editRoot)
        NSApp.mainMenu = appMenu

        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 460, height: 740), styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView], backing: .buffered, defer: false)
        window.title = "冰键 IceKeys"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: ContentView(model: model))
        window.center()
        window.setFrameAutosaveName("IceKeysMainWindow")

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        let symbol = NSImage(systemSymbolName: "snowflake", accessibilityDescription: "冰键")
        symbol?.isTemplate = true
        statusItem.button?.image = symbol
        statusItem.button?.toolTip = "冰键 · 键盘音效"
        let menu = NSMenu()
        stateItem = NSMenuItem(title: model.status, action: nil, keyEquivalent: "")
        menu.addItem(stateItem)
        menu.addItem(.separator())
        enabledItem = NSMenuItem(title: "开启音效", action: #selector(toggle), keyEquivalent: "")
        enabledItem.target = self
        menu.addItem(enabledItem)
        menu.addItem(withTitle: "试听冰音效", action: #selector(preview), keyEquivalent: "").target = self
        menu.addItem(withTitle: "打开冰键", action: #selector(showWindow), keyEquivalent: "").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "退出冰键", action: #selector(quit), keyEquivalent: "q").target = self
        statusItem.menu = menu
        model.objectWillChange.receive(on: DispatchQueue.main).sink { [weak self] _ in self?.updateMenu() }.store(in: &subscriptions)
        showWindow()
    }

    private func updateMenu() {
        enabledItem?.title = model.enabled ? "暂停音效" : "开启音效"
        stateItem?.title = model.status
        statusItem?.button?.appearsDisabled = !model.enabled
    }

    @objc private func toggle() { model.setEnabled(!model.enabled) }
    @objc private func preview() { model.preview() }
    @objc private func showWindow() {
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
    @objc private func quit() { NSApp.terminate(nil) }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool { showWindow(); return true }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
    func applicationWillTerminate(_ notification: Notification) { model.stop() }
}
