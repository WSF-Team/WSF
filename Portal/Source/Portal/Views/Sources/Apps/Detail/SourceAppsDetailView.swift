//
//  SourceAppsDetailView.swift
//  Feather
//
//  Created by samsam on 7/25/25.
//

import SwiftUI
import Combine
import AltSourceKit
import NimbleViews
import NukeUI
import UIKit

struct SourceAppsDetailView: View {
    @ObservedObject var downloadManager = DownloadManager.shared
    @State private var _downloadProgress: Double = 0
    @State var cancellable: AnyCancellable?
    @State private var _isScreenshotPreviewPresented: Bool = false
    @State private var _selectedScreenshotIndex: Int = 0

    var currentDownload: Download? {
        downloadManager.getDownload(by: app.currentUniqueId)
    }

    var source: ASRepository
    var app: ASRepository.App

    private var _downloadURLString: String? {
        Self.extractDownloadURLString(from: app)
    }

    private var _allInfoString: String {
        Self.buildAllInfo(app: app, source: source, downloadURL: _downloadURLString)
    }

    var body: some View {
        ScrollView {
            if #available(iOS 18, *) {
                _header().flexibleHeaderContent()
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    if let iconURL = app.iconURL {
                        LazyImage(url: iconURL) { state in
                            if let image = state.image {
                                image.appIconStyle(size: 111, isCircle: false)
                            } else {
                                standardIcon
                            }
                        }
                    } else {
                        standardIcon
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(app.currentName)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                            .copyMenu(app.currentName)

                        Text(app.currentDescription ?? .localized("An awesome application"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .copyMenu(app.currentDescription ?? .localized("An awesome application"))

                        Spacer()

                        DownloadButtonView(app: app)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Divider()
                _infoPills(app: app)
                Divider()

                if let screenshotURLs = app.screenshotURLs {
                    NBSection(.localized("Screenshots")) {
                        _screenshots(screenshotURLs: screenshotURLs)
                    }
                    Divider()
                }

                if let currentVer = app.currentVersion,
                   let whatsNewDesc = app.currentAppVersion?.localizedDescription {
                    NBSection(.localized("What's New")) {
                        AppVersionInfo(
                            version: currentVer,
                            date: app.currentDate?.date,
                            description: whatsNewDesc
                        )
                        .copyMenu("\(currentVer)\n\n\(whatsNewDesc)")

                        if let versions = app.versions {
                            NavigationLink(
                                destination: VersionHistoryView(app: app, versions: versions)
                                    .navigationTitle(.localized("Version History"))
                                    .navigationBarTitleDisplayMode(.large)
                            ) {
                                Text(.localized("Version History"))
                            }
                        }
                    }
                    Divider()
                }

                if let appDesc = app.localizedDescription, !appDesc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    NBSection(.localized("Description")) {
                        VStack(alignment: .leading, spacing: 2) {
                            ExpandableText(text: appDesc, lineLimit: 3)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .copyMenu(appDesc)
                    }
                    Divider()
                }

                NBSection(.localized("Information")) {
                    VStack(spacing: 12) {
                        if let sourceName = source.name {
                            _infoRow(title: .localized("Source"), value: sourceName)
                        }

                        if let developer = app.developer {
                            _infoRow(title: .localized("Developer"), value: developer)
                        }

                        if let size = app.size {
                            _infoRow(title: .localized("Size"), value: size.formattedByteCount)
                        }

                        if let category = app.category {
                            _infoRow(title: .localized("Category"), value: category.capitalized)
                        }

                        if let version = app.currentVersion {
                            _infoRow(title: .localized("Version"), value: version)
                        }

                        if let date = app.currentDate?.date {
                            _infoRow(
                                title: .localized("Updated"),
                                value: DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none)
                            )
                        }

                        if let bundleId = app.id {
                            _infoRow(title: .localized("Identifier"), value: bundleId)
                        }
                    }
                    .copyMenu(_allInfoString)
                }

                if let appPermissions = app.appPermissions {
                    NBSection(.localized("Permissions")) {
                        Group {
                            if let entitlements = appPermissions.entitlements {
                                let text = entitlements.map(\.name).joined(separator: "\n")
                                NBTitleWithSubtitleView(
                                    title: .localized("Entitlements"),
                                    subtitle: text
                                )
                                .copyMenu(text)
                            } else {
                                Text(.localized("No Entitlements listed."))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .copyMenu(.localized("No Entitlements listed."))
                            }

                            if let privacyItems = appPermissions.privacy {
                                ForEach(privacyItems, id: \.self) { item in
                                    NBTitleWithSubtitleView(
                                        title: item.name,
                                        subtitle: item.usageDescription
                                    )
                                    .copyMenu("\(item.name)\n\(item.usageDescription)")
                                }
                            } else {
                                Text(.localized("No Privacy Permissions listed."))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .copyMenu(.localized("No Privacy Permissions listed."))
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color(.quaternarySystemFill))
                        )
                    }
                }
            }
            .padding([.horizontal, .bottom])
            .padding(.top, {
                if #available(iOS 18, *) { 8 } else { 0 }
            }())
        }
        .flexibleHeaderScrollView()
        .shouldSetInset()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if let url = _downloadURLString, !url.isEmpty {
                        Button(.localized("Copy Download URL")) {
                            UIPasteboard.general.string = url
                        }
                    }

                    Button(.localized("Copy All Info")) {
                        UIPasteboard.general.string = _allInfoString
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .fullScreenCover(isPresented: $_isScreenshotPreviewPresented) {
            if let screenshotURLs = app.screenshotURLs {
                ScreenshotPreviewView(
                    screenshotURLs: screenshotURLs,
                    initialIndex: _selectedScreenshotIndex
                )
            }
        }
    }

    var standardIcon: some View {
        Image("App_Unknown").appIconStyle(size: 111, isCircle: false)
    }

    var standardHeader: some View {
        Image("App_Unknown")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .clipped()
    }

    private static func buildAllInfo(app: ASRepository.App, source: ASRepository, downloadURL: String?) -> String {
        var lines: [String] = []

        lines.append(app.currentName)

        if let v = app.currentVersion, !v.isEmpty {
            lines.append("\(String.localized("Version")): \(v)")
        }

        if let bid = app.id, !bid.isEmpty {
            lines.append("\(String.localized("Identifier")): \(bid)")
        }

        if let dev = app.developer, !dev.isEmpty {
            lines.append("\(String.localized("Developer")): \(dev)")
        }

        if let cat = app.category?.trimmingCharacters(in: .whitespacesAndNewlines), !cat.isEmpty {
            lines.append("\(String.localized("Category")): \(cat.capitalized)")
        }

        if let size = app.size {
            lines.append("\(String.localized("Size")): \(size.formattedByteCount)")
        }

        if let date = app.currentDate?.date {
            lines.append("\(String.localized("Updated")): \(DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none))")
        }

        if let sub = app.currentDescription?.trimmingCharacters(in: .whitespacesAndNewlines), !sub.isEmpty {
            lines.append("")
            lines.append("\(String.localized("Subtitle")):")
            lines.append(sub)
        }

        if let desc = app.localizedDescription?.trimmingCharacters(in: .whitespacesAndNewlines), !desc.isEmpty {
            lines.append("")
            lines.append("\(String.localized("Description")):")
            lines.append(desc)
        }

        if let dl = downloadURL, !dl.isEmpty {
            lines.append("")
            lines.append("\(String.localized("Download URL")):")
            lines.append(dl)
        }

        if let sname = source.name, !sname.isEmpty {
            lines.append("")
            lines.append("\(String.localized("Source")): \(sname)")
        }

        if let website = source.website?.absoluteString, !website.isEmpty {
            lines.append("\(String.localized("Source URL")): \(website)")
        }

        return lines.joined(separator: "\n")
    }

    private static func extractDownloadURLString(from app: ASRepository.App) -> String? {
        let mirror = Mirror(reflecting: app)

        let preferredKeys = [
            "downloadURL",
            "downloadUrl",
            "installURL",
            "installUrl",
            "url",
            "uri",
            "packageURL",
            "packageUrl"
        ]

        for key in preferredKeys {
            if let child = mirror.children.first(where: { $0.label == key })?.value {
                if let u = child as? URL { return u.absoluteString }
                if let s = child as? String, !s.isEmpty { return s }
            }
        }

        for child in mirror.children {
            if let u = child.value as? URL { return u.absoluteString }
            if let s = child.value as? String, s.hasPrefix("http") { return s }
        }

        return nil
    }
}

extension SourceAppsDetailView {
    @available(iOS 18.0, *)
    @ViewBuilder
    private func _header() -> some View {
        ZStack {
            if let iconURL = app.iconURL {
                LazyImage(url: iconURL) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                            .clipped()
                    } else {
                        standardHeader
                    }
                }
            } else {
                standardHeader
            }

            Rectangle().fill(.ultraThinMaterial)
            Color.black.opacity(0.18)
        }
    }

    @ViewBuilder
    private func _infoPills(app: ASRepository.App) -> some View {
        let pillItems = _buildPills(from: app)
        HStack(spacing: 6) {
            ForEach(pillItems.indices, id: \.hashValue) { index in
                let pill = pillItems[index]
                NBPillView(
                    title: pill.title,
                    icon: pill.icon,
                    color: pill.color,
                    index: index,
                    count: pillItems.count
                )
            }
        }
        .copyMenu(_allInfoString)
    }

    private func _buildPills(from app: ASRepository.App) -> [NBPillItem] {
        var pills: [NBPillItem] = []

        if let version = app.currentVersion {
            pills.append(NBPillItem(title: version, icon: "tag", color: Color.accentColor))
        }

        if let category = app.category?.trimmingCharacters(in: .whitespacesAndNewlines), !category.isEmpty {
            pills.append(NBPillItem(title: category.capitalized, icon: "square.grid.2x2", color: .secondary))
        }

        if let size = app.size {
            pills.append(NBPillItem(title: size.formattedByteCount, icon: "archivebox", color: .secondary))
        }

        return pills
    }

    @ViewBuilder
    private func _infoRow(title: String, value: String) -> some View {
        LabeledContent {
            Text(value).copyMenu(value)
        } label: {
            Text(title)
        }
        Divider()
    }

    @ViewBuilder
    private func _screenshots(screenshotURLs: [URL]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(screenshotURLs.indices, id: \.self) { index in
                    let url = screenshotURLs[index]
                    LazyImage(url: url) { state in
                        if let image = state.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(
                                    maxWidth: UIScreen.main.bounds.width - 32,
                                    maxHeight: 400
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .strokeBorder(.gray.opacity(0.3), lineWidth: 1)
                                }
                                .onTapGesture {
                                    _selectedScreenshotIndex = index
                                    _isScreenshotPreviewPresented = true
                                }
                        }
                    }
                }
            }
            .padding(.horizontal)
            .compatScrollTargetLayout()
        }
        .compatScrollTargetBehavior()
        .padding(.horizontal, -16)
    }
}

private extension View {
    func copyMenu(_ text: String) -> some View {
        contentShape(Rectangle())
            .contextMenu {
                Button(.localized("Copy")) {
                    UIPasteboard.general.string = text
                }
            } preview: {
                EmptyView()
            }
    }
}
