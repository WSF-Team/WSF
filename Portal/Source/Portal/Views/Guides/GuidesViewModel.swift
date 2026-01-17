import Foundation
import SwiftUI

@MainActor
final class GuidesViewModel: ObservableObject {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    @Published private(set) var state: LoadState = .idle
    @Published private(set) var items: [GuideIndexItem] = []
    @Published var query: String = ""

    private let client = GitHubGuidesClient()
    private let config: GitHubGuidesClient.Config

    init(indexURL: URL, baseURL: URL) {
        self.config = .init(indexURL: indexURL, baseURL: baseURL)
    }

    var filteredItems: [GuideIndexItem] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return items }
        return items.filter { $0.fileTitle.localizedCaseInsensitiveContains(q) || $0.fileName.localizedCaseInsensitiveContains(q) }
    }

    func load() async {
        state = .loading
        do {
            items = try await client.fetchIndex(from: config)
            state = .loaded
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func loadMarkdown(for item: GuideIndexItem) async throws -> String {
        try await client.fetchMarkdown(for: item, config: config)
    }
}
