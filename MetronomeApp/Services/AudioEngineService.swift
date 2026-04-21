@preconcurrency import AVFoundation

actor AudioEngineService {
    static let shared = AudioEngineService()

    private(set) var engine = AVAudioEngine()
    private var _isRunning = false
    var isRunning: Bool { _isRunning }

    // Fan-out broadcast: each subscriber gets its own continuation.
    private var stopContinuations: [UUID: AsyncStream<Void>.Continuation] = [:]
    private var notificationTasks: [Task<Void, Never>] = []

    private init() {}

    // MARK: – Session + engine lifecycle

    func configure(mixWithOthers: Bool = false) throws {
        let options: AVAudioSession.CategoryOptions = mixWithOthers ? .mixWithOthers : []
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: options)
        try session.setActive(true)
        registerForNotifications()
    }

    func start() throws {
        engine.prepare()
        try engine.start()
        _isRunning = true
    }

    func stop() {
        engine.stop()
        _isRunning = false
    }

    func ensureRunning() throws {
        guard !_isRunning else { return }
        try start()
    }

    // MARK: – Stop signal subscription

    func makeStopStream() -> AsyncStream<Void> {
        let id = UUID()
        var captured: AsyncStream<Void>.Continuation!
        let stream = AsyncStream<Void> { continuation in
            captured = continuation
            continuation.onTermination = { [weak self] _ in
                Task { await self?.cancelStopStream(id: id) }
            }
        }
        stopContinuations[id] = captured
        return stream
    }

    private func cancelStopStream(id: UUID) {
        stopContinuations.removeValue(forKey: id)
    }

    private func signalStop() {
        stopContinuations.values.forEach { $0.yield() }
    }

    // MARK: – Graph helpers

    var sampleRate: Double { outputFormat.sampleRate }

    var outputFormat: AVAudioFormat {
        engine.outputNode.outputFormat(forBus: 0)
    }

    var outputRenderTime: AVAudioTime? {
        engine.outputNode.lastRenderTime
    }

    func attachAndConnect(_ node: AVAudioNode, format: AVAudioFormat? = nil) {
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format ?? outputFormat)
    }

    func detach(_ node: AVAudioNode) {
        engine.detach(node)
    }

    // MARK: – Notification handling

    private func registerForNotifications() {
        notificationTasks.forEach { $0.cancel() }
        notificationTasks = [
            Task { [weak self] in
                for await notification in NotificationCenter.default.notifications(
                    named: AVAudioSession.interruptionNotification
                ) {
                    let typeValue    = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
                    let optionsValue = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt
                    await self?.handleInterruption(typeValue: typeValue, optionsValue: optionsValue)
                }
            },
            Task { [weak self] in
                for await notification in NotificationCenter.default.notifications(
                    named: AVAudioSession.routeChangeNotification
                ) {
                    let reasonValue = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt
                    await self?.handleRouteChange(reasonValue: reasonValue)
                }
            },
            Task { [weak self] in
                for await _ in NotificationCenter.default.notifications(
                    named: .AVAudioEngineConfigurationChange
                ) {
                    await self?.handleConfigurationChange()
                }
            }
        ]
    }

    private func handleInterruption(typeValue: UInt?, optionsValue: UInt?) {
        guard let typeValue,
              let kind = AVAudioSession.InterruptionType(rawValue: typeValue)
        else { return }

        switch kind {
        case .began:
            stop()
            signalStop()
        case .ended:
            let opts = AVAudioSession.InterruptionOptions(rawValue: optionsValue ?? 0)
            if opts.contains(.shouldResume) {
                // Re-activate session before restarting — required after interruption.
                try? AVAudioSession.sharedInstance().setActive(true)
                try? start()
            }
        @unknown default:
            break
        }
    }

    private func handleRouteChange(reasonValue: UInt?) {
        guard let reasonValue,
              AVAudioSession.RouteChangeReason(rawValue: reasonValue) == .oldDeviceUnavailable
        else { return }
        stop()
        signalStop()
    }

    private func handleConfigurationChange() {
        // Engine stopped automatically. Restart it so AVAudioPlayerNodes stay usable,
        // then always signal ViewModels: their scheduling chains are broken and must restart.
        guard _isRunning else { return }
        engine.prepare()
        if (try? engine.start()) == nil { _isRunning = false }
        signalStop()
    }
}
