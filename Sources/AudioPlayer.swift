import AVFoundation
import AudioToolbox

/// All engine state is confined to the audio queue. No files are opened per keystroke.
final class IceAudioPlayer {
    private let queue = DispatchQueue(label: "app.icekeys.audio", qos: .userInteractive)
    private let engine = AVAudioEngine()
    private var voices: [AVAudioPlayerNode] = []
    private var sample: AVAudioPCMBuffer?
    private var voiceIndex = 0
    private var volume: Float = 0.65
    private var lastTrigger: TimeInterval = 0
    private var enabled = false
    private var idleWork: DispatchWorkItem?
    var onError: ((String) -> Void)?

    init() {
        queue.async { [weak self] in self?.prepare() }
        NotificationCenter.default.addObserver(self, selector: #selector(configurationChanged), name: .AVAudioEngineConfigurationChange, object: engine)
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    private func prepare() {
        do {
            guard let url = Bundle.main.url(forResource: "ice", withExtension: "wav") else {
                throw NSError(domain: "IceKeys", code: 1, userInfo: [NSLocalizedDescriptionKey: "找不到内置音效，请重新构建 App。"])
            }
            let file = try AVAudioFile(forReading: url)
            guard let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length)) else { return }
            try file.read(into: buffer)
            sample = buffer
            // A peak limiter keeps overlapping tails controlled during fast typing.
            let limiter = AVAudioUnitEffect(audioComponentDescription: AudioComponentDescription(componentType: kAudioUnitType_Effect, componentSubType: kAudioUnitSubType_PeakLimiter, componentManufacturer: kAudioUnitManufacturer_Apple, componentFlags: 0, componentFlagsMask: 0))
            engine.attach(limiter)
            engine.connect(engine.mainMixerNode, to: limiter, format: buffer.format)
            engine.connect(limiter, to: engine.outputNode, format: nil)
            for _ in 0..<12 {
                let voice = AVAudioPlayerNode()
                engine.attach(voice)
                engine.connect(voice, to: engine.mainMixerNode, format: buffer.format)
                voices.append(voice)
            }
            engine.mainMixerNode.outputVolume = volume * 0.7
            engine.prepare()
        } catch { report(error) }
    }

    func setVolume(_ value: Double) {
        queue.async {
            self.volume = Float(value)
            self.engine.mainMixerNode.outputVolume = self.volume * 0.7
        }
    }

    func setEnabled(_ enabled: Bool) {
        queue.async {
            self.enabled = enabled
            self.idleWork?.cancel()
            if enabled {
                do { if !self.engine.isRunning { try self.engine.start() } }
                catch { self.report(error) }
            } else {
                self.voices.forEach { $0.stop() }
                self.engine.pause()
            }
        }
    }

    func play(preview: Bool = false) {
        queue.async {
            guard (self.enabled || preview), let sample = self.sample, !self.voices.isEmpty else { return }
            let now = ProcessInfo.processInfo.systemUptime
            guard now - self.lastTrigger > 0.012 else { return }
            self.lastTrigger = now
            do {
                if !self.engine.isRunning { try self.engine.start() }
                let voice = self.voices[self.voiceIndex]
                self.voiceIndex = (self.voiceIndex + 1) % self.voices.count
                voice.stop()
                voice.scheduleBuffer(sample)
                voice.play()
                if !self.enabled {
                    self.idleWork?.cancel()
                    let work = DispatchWorkItem { [weak player = self] in
                        guard let player, !player.enabled else { return }
                        player.voices.forEach { $0.stop() }
                        player.engine.pause()
                    }
                    self.idleWork = work
                    self.queue.asyncAfter(deadline: .now() + 1.1, execute: work)
                }
            } catch { self.report(error) }
        }
    }

    @objc private func configurationChanged() {
        queue.async {
            self.voices.forEach { $0.stop() }
            if self.enabled {
                do { try self.engine.start() }
                catch { self.report(error) }
            }
        }
    }

    private func report(_ error: Error) {
        DispatchQueue.main.async { [weak self] in self?.onError?(error.localizedDescription) }
    }
}
