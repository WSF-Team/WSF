import SwiftUI
import AltSourceKit
import NimbleViews
import NukeUI

struct SourceAppsCellView: View {
    var source: ASRepository
    var app: ASRepository.App
    var showSourceBadge: Bool = false

    var body: some View {
        HStack(spacing: 2) {
            HStack(spacing: 12) {
                ZStack(alignment: .bottomLeading) {
                    LazyImage(url: app.iconURL) { state in
                        if let image = state.image {
                            image
                                .resizable()
                                .scaledToFill()
                                .scaleEffect(1.06)
                        } else {
                            Color.clear
                        }
                    }
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .compositingGroup()

                    if showSourceBadge, let iconURL = source.currentIconURL {
                        LazyImage(url: iconURL) { state in
                            if let image = state.image {
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .scaleEffect(1.12)
                            } else {
                                Color.clear
                            }
                        }
                        .frame(width: 18, height: 18)
                        .clipShape(Circle())
                        .background(
                            Circle()
                                .fill(Color(uiColor: .systemBackground))
                                .frame(width: 22, height: 22)
                        )
                        .offset(x: 41, y: 4)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(app.currentName)
                        .lineLimit(1)

                    Text(Self.versionAndSubtitle(app: app))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)
            }

            DownloadButtonView(app: app)
        }
    }

    static func versionAndSubtitle(app: ASRepository.App) -> String {
        let parts: [String?] = [
            app.currentVersion,
            app.subtitle
        ]

        return parts.compactMap { value in
            guard let v = value?.trimmingCharacters(in: .whitespacesAndNewlines), !v.isEmpty else { return nil }
            return v
        }
        .joined(separator: " • ")
    }
}
