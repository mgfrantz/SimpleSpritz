import SwiftUI
#if os(iOS)
import UIKit
#else
import AppKit
#endif

struct SpritzReaderScreen: View {
    @StateObject private var model: SpritzReaderViewModel
    let showsDoneButton: Bool
    let onDone: (() -> Void)?

    init(initialText: String = "", showsDoneButton: Bool = false, onDone: (() -> Void)? = nil) {
        _model = StateObject(wrappedValue: SpritzReaderViewModel(initialText: initialText))
        self.showsDoneButton = showsDoneButton
        self.onDone = onDone
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                readerPanel
                controls
                inputPanel
            }
            .padding(20)
            .navigationTitle("SimpleSpritz")
            .toolbar {
                if showsDoneButton {
                    ToolbarItem(placement: .automatic) {
                        Button("Done") {
                            onDone?()
                        }
                    }
                }
            }
        }
    }

    private var readerPanel: some View {
        VStack(spacing: 14) {
            HStack(spacing: 0) {
                Text(model.left)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Text(model.pivot)
                    .foregroundStyle(.red)
                    .frame(width: 42)
                Text(model.right)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .font(.system(size: 40, weight: .medium, design: .monospaced))
            .lineLimit(1)
            .minimumScaleFactor(0.45)
            .frame(height: 76)

            Text(model.progress)
                .font(.system(.footnote, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var controls: some View {
        VStack(spacing: 18) {
            HStack(spacing: 18) {
                Button {
                    model.step(-1)
                } label: {
                    Image(systemName: "backward.fill")
                }

                Button {
                    model.toggle()
                } label: {
                    Image(systemName: model.isRunning ? "pause.fill" : "play.fill")
                }
                .font(.title2)
                .buttonStyle(.borderedProminent)

                Button {
                    model.step(1)
                } label: {
                    Image(systemName: "forward.fill")
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Speed")
                    Spacer()
                    Text("\(model.speed) wpm")
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                Slider(value: Binding(
                    get: { Double(model.speed) },
                    set: { model.setSpeed($0) }
                ), in: 100...900, step: 25)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Ramp")
                    Spacer()
                    Text(String(format: "%.1fs", model.rampDuration))
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                Slider(value: Binding(
                    get: { model.rampDuration },
                    set: { model.setRampDuration($0) }
                ), in: 0...10, step: 0.5)
            }
        }
    }

    private var inputPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Text")
                .font(.headline)

            TextEditor(text: $model.draftText)
                .frame(minHeight: 140)
                .padding(8)
                .background(secondaryBackgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            Button {
                model.readDraftText()
            } label: {
                Label("Read Text", systemImage: "text.word.spacing")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(model.draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private var secondaryBackgroundColor: Color {
        #if os(iOS)
        Color(uiColor: .secondarySystemBackground)
        #else
        Color(nsColor: .controlBackgroundColor)
        #endif
    }
}
