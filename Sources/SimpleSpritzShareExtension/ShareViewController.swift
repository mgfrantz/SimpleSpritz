import SwiftUI
import UIKit
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .dark
        view.overrideUserInterfaceStyle = .dark
        loadSharedText { [weak self] text in
            self?.showReader(text: text)
        }
    }

    private func showReader(text: String) {
        let controller = UIHostingController(rootView: SpritzReaderScreen(
            initialText: text,
            showsDoneButton: true,
            onDone: { [weak self] in
                self?.extensionContext?.completeRequest(returningItems: nil)
            }
        ).preferredColorScheme(.dark))
        controller.overrideUserInterfaceStyle = .dark
        controller.view.overrideUserInterfaceStyle = .dark
        controller.view.backgroundColor = .systemBackground

        addChild(controller)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controller.view)
        NSLayoutConstraint.activate([
            controller.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            controller.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            controller.view.topAnchor.constraint(equalTo: view.topAnchor),
            controller.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        controller.didMove(toParent: self)
    }

    private func loadSharedText(completion: @escaping (String) -> Void) {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else {
            completion("")
            return
        }

        let providers = items.flatMap { $0.attachments ?? [] }
        loadText(from: providers, completion: completion)
    }

    private func loadText(from providers: [NSItemProvider], completion: @escaping (String) -> Void) {
        guard let provider = providers.first else {
            completion("")
            return
        }

        if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, _ in
                DispatchQueue.main.async {
                    completion(Self.text(from: item))
                }
            }
            return
        }

        if provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { item, _ in
                DispatchQueue.main.async {
                    completion(Self.text(from: item))
                }
            }
            return
        }

        if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, _ in
                DispatchQueue.main.async {
                    completion(Self.text(from: item))
                }
            }
            return
        }

        loadText(from: Array(providers.dropFirst()), completion: completion)
    }

    private static func text(from item: NSSecureCoding?) -> String {
        switch item {
        case let text as String:
            return text
        case let url as URL:
            return url.absoluteString
        case let data as Data:
            return String(data: data, encoding: .utf8) ?? ""
        default:
            return ""
        }
    }
}
