import SwiftUI

struct GuidesView: View {
    @StateObject private var vm: GuidesViewModel

    init(
        indexURL: URL = URL(string: "https://raw.githubusercontent.com/WSF-Team/WSF/refs/heads/main/Portal/Guides/Markdown_filenames.plist")!,
        baseURL: URL = URL(string: "https://raw.githubusercontent.com/WSF-Team/WSF/refs/heads/main/Portal/Guides/")!
    ) {
        _vm = StateObject(wrappedValue: GuidesViewModel(indexURL: indexURL, baseURL: baseURL))
    }

    var body: some View {
        NavigationStack {
            Group {
                switch vm.state {
                case .idle, .loading:
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Loading guides…")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                case .failed(let message):
                    VStack(spacing: 12) {
                        Image(systemName: "wifi.exclamationmark")
                            .font(.system(size: 28))
                        Text("Couldn’t load guides")
                            .font(.headline)
                        Text(message)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                        Button("Retry") {
                            Task { await vm.load() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                case .loaded:
                    List {
                        ForEach(vm.filteredItems) { item in
                            NavigationLink {
                                GuideScreen(item: item, vm: vm)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.fileTitle)
                                        .font(.headline)
                                    Text(item.fileName)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Guides")
            .searchable(text: $vm.query, placement: .navigationBarDrawer(displayMode: .always))
            .task { if vm.state == .idle { await vm.load() } }
            .refreshable { await vm.load() }
        }
    }
}

private struct GuideScreen: View {
    let item: GuideIndexItem
    @ObservedObject var vm: GuidesViewModel

    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var parsed: ParsedGuideContent?

    var body: some View {
        ScrollView {
            if isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Loading…")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else if let errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.red)

                    Text("Couldn’t load guide")
                        .font(.headline)

                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    Button("Retry") {
                        Task { await load() }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else if let parsed {
                MarkdownView(parsed: parsed)
                    .padding()
            } else {
                Text("No content.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .navigationTitle(item.fileTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        parsed = nil

        do {
            let md = try await vm.loadMarkdown(for: item)
            parsed = GuideParser.parse(markdown: md)
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}
