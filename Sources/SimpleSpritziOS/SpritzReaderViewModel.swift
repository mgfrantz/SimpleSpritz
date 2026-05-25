import Foundation
import SwiftUI

@MainActor
final class SpritzReaderViewModel: ObservableObject {
    @Published var left = ""
    @Published var pivot = "Paste text first"
    @Published var right = ""
    @Published var progress = "0 / 0"
    @Published var speed = 500
    @Published var rampDuration = 1.0
    @Published var isRunning = false
    @Published var draftText = ""

    private let reader = SpritzReader()
    private var refreshTimer: Timer?

    init(initialText: String = "") {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }

        let trimmed = initialText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            draftText = trimmed
            reader.load(trimmed)
        }
        refresh()
    }

    deinit {
        refreshTimer?.invalidate()
    }

    func readDraftText() {
        let trimmed = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            reader.clear()
            refresh()
            return
        }

        reader.load(trimmed)
        refresh()
    }

    func toggle() {
        reader.toggle()
        refresh()
    }

    func step(_ delta: Int) {
        reader.step(delta)
        refresh()
    }

    func setSpeed(_ newSpeed: Double) {
        reader.setSpeed(Int(newSpeed.rounded()))
        refresh()
    }

    func setRampDuration(_ duration: Double) {
        reader.setRampDuration(duration)
        refresh()
    }

    private func refresh() {
        left = reader.left
        pivot = reader.pivot
        right = reader.right
        progress = reader.progress
        speed = reader.speed
        rampDuration = reader.rampDuration
        isRunning = reader.isRunning
    }
}
