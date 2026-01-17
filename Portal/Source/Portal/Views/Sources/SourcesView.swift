import CoreData
import AltSourceKit
import SwiftUI
import NimbleViews

struct SourcesView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @StateObject var viewModel = SourcesViewModel.shared
    @State private var _isAddingPresenting = false
    @State private var _addingSourceLoading = false
    @State private var _searchText = ""

    @FetchRequest(
        entity: AltSource.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \AltSource.name, ascending: true)],
        animation: .snappy
    ) private var _sources: FetchedResults<AltSource>

    private var _sourcesArray: [AltSource] { Array(_sources) }

    private var _taskID: [NSManagedObjectID] {
        _sources.map { $0.objectID }
    }

    private var _filteredSources: [AltSource] {
        if _searchText.isEmpty { return _sourcesArray }
        return _sourcesArray.filter { s in
            (s.name?.localizedCaseInsensitiveContains(_searchText) ?? false)
        }
    }

    private func _repoAppCount(_ repo: ASRepository) -> Int {
        if let apps = Mirror(reflecting: repo).children.first(where: { $0.label == "apps" })?.value as? [ASRepository.App] {
            return apps.count
        }
        if let apps = Mirror(reflecting: repo).children.first(where: { $0.label == "applications" })?.value as? [ASRepository.App] {
            return apps.count
        }
        if let apps = Mirror(reflecting: repo).children.first(where: { $0.label == "items" })?.value as? [ASRepository.App] {
            return apps.count
        }
        return 0
    }

    private func _subtitleForSource(_ source: AltSource) -> String {
        guard let repo = viewModel.sources[source] else { return "" }
        let c = _repoAppCount(repo)
        return "\(c) \(c == 1 ? "app" : "apps")"
    }

    private var _totalAppsSubtitle: String {
        let total = _sourcesArray.reduce(0) { acc, s in
            guard let repo = viewModel.sources[s] else { return acc }
            return acc + _repoAppCount(repo)
        }
        return "\(total) \(total == 1 ? "app" : "apps")"
    }

    @ViewBuilder
    private var _allReposRow: some View {
        let isRegular = horizontalSizeClass != .compact
        HStack(spacing: 18) {
            Image("Repositories").appIconStyle()
            NBTitleWithSubtitleView(
                title: .localized("All Repositories"),
                subtitle: _totalAppsSubtitle
            )
        }
        .padding(isRegular ? 12 : 0)
        .background(
            Group {
                if isRegular {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(.quaternarySystemFill))
                }
            }
        )
    }

    @ViewBuilder
    private func _repoRow(_ source: AltSource) -> some View {
        SourcesCellView(
            source: source,
            subtitle: _subtitleForSource(source)
        )
    }

    @ViewBuilder
    private var _emptyOverlay: some View {
        if _filteredSources.isEmpty {
            if #available(iOS 17, *) {
                ContentUnavailableView {
                    Label(.localized("No Repositories"), systemImage: "globe.desk.fill")
                }
            }
        }
    }

    var body: some View {
        NavigationStack {
            NBListAdaptable {
                if !_filteredSources.isEmpty {
                    Section {
                        NavigationLink {
                            SourceAppsView(object: _sourcesArray, viewModel: viewModel)
                        } label: {
                            _allReposRow
                        }
                        .buttonStyle(.plain)
                    }

                    NBSection(.localized("Repositories")) {
                        ForEach(_filteredSources) { source in
                            NavigationLink {
                                SourceAppsView(object: [source], viewModel: viewModel)
                            } label: {
                                _repoRow(source)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle(.localized("Sources"))
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $_searchText, placement: .platform(), prompt: "")
            .overlay { _emptyOverlay }
            .toolbar {
                NBToolbarButton(
                    systemImage: "plus",
                    style: .icon,
                    placement: .topBarTrailing,
                    isDisabled: _addingSourceLoading
                ) {
                    _isAddingPresenting = true
                }
            }
            .refreshable {
                await viewModel.fetchSources(_sources, refresh: true)
            }
            .sheet(isPresented: $_isAddingPresenting) {
                SourcesAddView()
            }
        }
        .task(id: _taskID) {
            await viewModel.fetchSources(_sources)
        }
    }
}
