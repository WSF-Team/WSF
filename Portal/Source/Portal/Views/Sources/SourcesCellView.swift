import SwiftUI
import NimbleViews
import NukeUI

struct SourcesCellView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    var source: AltSource
    var subtitle: String

    var body: some View {
        let isRegular = horizontalSizeClass != .compact

        HStack(spacing: 12) {
            LazyImage(url: source.iconURL) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .scaledToFill()
                        .scaleEffect(1.06)
                } else {
                    Image(systemName: "shippingbox.fill")
                        .resizable()
                        .scaledToFit()
                        .padding(10)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 44, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .compositingGroup()

            NBTitleWithSubtitleView(
                title: source.name ?? .localized("Unknown"),
                subtitle: subtitle
            )

            Spacer(minLength: 8)
        }
        .padding(isRegular ? 12 : 0)
        .background(
            isRegular
            ? RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.quaternarySystemFill))
            : nil
        )
        .swipeActions {
            _actions(for: source)
            _contextActions(for: source)
        }
        .contextMenu {
            _contextActions(for: source)
            Divider()
            _actions(for: source)
        }
    }
}

extension SourcesCellView {
    @ViewBuilder
    private func _actions(for source: AltSource) -> some View {
        Button(.localized("Delete"), systemImage: "trash", role: .destructive) {
            Storage.shared.deleteSource(for: source)
        }
    }

    @ViewBuilder
    private func _contextActions(for source: AltSource) -> some View {
        Button(.localized("Copy"), systemImage: "doc.on.clipboard") {
            UIPasteboard.general.string = source.sourceURL?.absoluteString
        }
    }
}
