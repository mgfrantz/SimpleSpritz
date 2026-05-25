import Foundation

open class SpritzReader {
    private static let initialStartDelay: TimeInterval = 0.5

    public private(set) var word = ""
    public private(set) var left = ""
    public private(set) var pivot = ""
    public private(set) var right = ""
    public private(set) var progress = "0 / 0"
    public private(set) var isRunning = false
    public var hasWords: Bool {
        !words.isEmpty
    }
    public var isAtEnd: Bool {
        !words.isEmpty && index >= words.count - 1
    }

    public var speed: Int {
        didSet {
            speed = min(900, max(100, speed))
            if isRunning {
                schedule()
            }
        }
    }

    public var rampDuration: Double {
        didSet {
            rampDuration = min(10.0, max(0.0, rampDuration))
            if isRunning {
                schedule()
            }
        }
    }

    private var words: [String] = []
    private var index = 0
    private var timer: Timer?
    private var rampStartTime: Date?

    public init(speed: Int = 500, rampDuration: Double = 1.0) {
        self.speed = speed
        self.rampDuration = rampDuration
        showCurrent()
    }

    deinit {
        timer?.invalidate()
    }

    public func load(_ text: String) {
        words = Self.words(in: text)
        index = 0
        showCurrent()
        start()
    }

    public func clear() {
        pause()
        words = []
        index = 0
        showCurrent()
    }

    public func start() {
        guard !words.isEmpty else { return }
        if isAtEnd {
            index = 0
            showCurrent()
        }
        isRunning = true
        rampStartTime = Date()
        scheduleStartDelay()
    }

    public func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    public func toggle() {
        isRunning ? pause() : start()
    }

    public func setSpeed(_ newSpeed: Int) {
        speed = newSpeed
    }

    public func setRampDuration(_ duration: Double) {
        rampDuration = duration
    }

    public func step(_ delta: Int) {
        guard !words.isEmpty else { return }
        index = min(words.count - 1, max(0, index + delta))
        showCurrent()
    }

    public static func words(in text: String) -> [String] {
        text
            .replacingOccurrences(of: #"[\r\n\t]+"#, with: " ", options: .regularExpression)
            .split(whereSeparator: { $0.isWhitespace })
            .map(String.init)
    }

    private func schedule() {
        schedule(after: currentInterval())
    }

    private func schedule(after interval: TimeInterval) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.advance()
        }
    }

    private func scheduleStartDelay() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: Self.initialStartDelay, repeats: false) { [weak self] _ in
            self?.advance()
        }
    }

    private func advance() {
        guard !words.isEmpty else { return }
        if index >= words.count - 1 {
            pause()
            return
        }
        index += 1
        showCurrent()
        if isRunning {
            schedule()
        }
    }

    private func currentInterval() -> TimeInterval {
        60.0 / currentSpeed()
    }

    private func currentSpeed() -> Double {
        let targetSpeed = Double(speed)
        guard rampDuration > 0, let rampStartTime else {
            return targetSpeed
        }

        let elapsed = Date().timeIntervalSince(rampStartTime)
        let progress = min(1.0, max(0.0, elapsed / rampDuration))
        let speedMultiplier = 0.5 + (0.5 * progress)
        return targetSpeed * speedMultiplier
    }

    private func showCurrent() {
        guard !words.isEmpty else {
            word = ""
            left = ""
            pivot = "Paste text first"
            right = ""
            progress = "0 / 0"
            return
        }

        let current = words[index]
        let pivotIndex = pivotOffset(for: current.count)
        let chars = Array(current)
        left = String(chars.prefix(pivotIndex))
        pivot = String(chars[pivotIndex])
        right = String(chars.dropFirst(pivotIndex + 1))
        word = current
        progress = "\(index + 1) / \(words.count)"
    }

    private func pivotOffset(for count: Int) -> Int {
        switch count {
        case 0...1: return 0
        case 2...5: return 1
        case 6...9: return 2
        case 10...13: return 3
        default: return 4
        }
    }
}
