import AppKit
import Combine

final class AppModel: ObservableObject {
    @Published private(set) var enabled = false
    @Published private(set) var hasPermission = false
    @Published private(set) var globallyListening = false
    @Published private(set) var connectionFailed = false
    @Published var audioError: String?
    @Published var pulse = false
    @Published var volume: Double {
        didSet { UserDefaults.standard.set(volume, forKey: "volume"); audio.setVolume(volume) }
    }
    @Published var repeatKeys: Bool {
        didSet { UserDefaults.standard.set(repeatKeys, forKey: "repeatKeys") }
    }
    private let listener = KeyboardListener()
    private let audio = IceAudioPlayer()
    private var timer: Timer?
    private var wakeObserver: NSObjectProtocol?
    private var lastPulse: TimeInterval = 0

    init() {
        let defaults = UserDefaults.standard
        volume = defaults.object(forKey: "volume") == nil ? 0.65 : defaults.double(forKey: "volume")
        repeatKeys = defaults.bool(forKey: "repeatKeys")
        audio.onError = { [weak self] in self?.audioError = $0 }
        audio.setVolume(volume)
        listener.onKeyDown = { [weak self] isRepeat in
            guard let self, self.enabled, !isRepeat || self.repeatKeys else { return }
            self.audio.play()
            self.flash()
        }
        listener.onUnavailable = { [weak self] in self?.refreshPermission(force: true) }
        hasPermission = listener.hasPermission
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in self?.refreshPermission() }
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
            self?.refreshPermission(force: true)
        }
        if defaults.bool(forKey: "enabled") { setEnabled(true, requestPermission: false) }
    }

    var status: String {
        if !enabled { return "已暂停" }
        if globallyListening { return "正在聆听按键" }
        return connectionFailed ? "需要重新连接" : "等待输入监控权限"
    }

    func setEnabled(_ value: Bool, requestPermission: Bool = true) {
        enabled = value
        UserDefaults.standard.set(value, forKey: "enabled")
        audio.setEnabled(value)
        if value {
            if requestPermission && !listener.hasPermission { listener.requestPermission() }
            refreshPermission(force: true)
        } else {
            listener.stop()
            globallyListening = false
            connectionFailed = false
        }
    }

    func refreshPermission(force: Bool = false) {
        let granted = listener.hasPermission
        let changed = granted != hasPermission
        hasPermission = granted
        guard enabled else { return }
        if changed || force || (globallyListening && !listener.isListening) {
            globallyListening = granted && listener.start()
            connectionFailed = granted && !globallyListening
            if !globallyListening { listener.startLocalPreview() }
        }
    }

    func authorize() {
        listener.requestPermission()
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")!
        NSWorkspace.shared.open(url)
        refreshPermission(force: true)
    }

    func preview() { audio.play(preview: true); flash() }

    private func flash() {
        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastPulse > 0.09 else { return }
        lastPulse = now
        pulse = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.075) { [weak self] in self?.pulse = false }
    }

    func stop() {
        timer?.invalidate()
        listener.stop()
        audio.setEnabled(false)
    }

    deinit {
        timer?.invalidate()
        if let wakeObserver { NSWorkspace.shared.notificationCenter.removeObserver(wakeObserver) }
    }
}
