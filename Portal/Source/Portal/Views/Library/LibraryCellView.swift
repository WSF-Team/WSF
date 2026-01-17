import SwiftUI
import NimbleExtensions
import NimbleViews

struct LibraryCellView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.editMode) private var editMode

    var app: AppInfoPresentable
    @Binding var selectedInfoAppPresenting: AnyApp?
    @Binding var selectedSigningAppPresenting: AnyApp?
    @Binding var selectedInstallAppPresenting: AnyApp?
    @Binding var selectedAppUUIDs: Set<String>

    private var _isSelected: Bool {
        guard let uuid = app.uuid else { return false }
        return selectedAppUUIDs.contains(uuid)
    }

    private func _toggleSelection() {
        guard let uuid = app.uuid else { return }
        if selectedAppUUIDs.contains(uuid) {
            selectedAppUUIDs.remove(uuid)
        } else {
            selectedAppUUIDs.insert(uuid)
        }
    }

    private var certInfo: Date.ExpirationInfo? {
        Storage.shared.getCertificate(from: app)?.expiration?.expirationInfo()
    }

    private var certRevoked: Bool {
        Storage.shared.getCertificate(from: app)?.revoked == true
    }

    private var _desc: String {
        if let version = app.version, let id = app.identifier {
            return "\(version) • \(id)"
        } else {
            return .localized("Unknown")
        }
    }

    var body: some View {
        let isRegular = horizontalSizeClass != .compact
        let isEditing = editMode?.wrappedValue == .active

        HStack(spacing: 18) {
            if isEditing {
                Button {
                    _toggleSelection()
                } label: {
                    Image(systemName: _isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(_isSelected ? .accentColor : .secondary)
                        .font(.title2)
                }
                .buttonStyle(.borderless)
            }

            FRAppIconView(app: app, size: 57)

            NBTitleWithSubtitleView(
                title: app.name ?? .localized("Unknown"),
                subtitle: _desc,
                linelimit: 0
            )

            if !isEditing {
                _buttonActions(for: app)
            }
        }
        .padding(isRegular ? 12 : 0)
        .background(
            isRegular
            ? RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(_isSelected && isEditing ? Color.accentColor.opacity(0.1) : Color(.quaternarySystemFill))
            : nil
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if isEditing {
                _toggleSelection()
            } else {
                selectedInfoAppPresenting = AnyApp(base: app)
            }
        }
        .swipeActions {
            if !isEditing {
                Button(.localized("Delete"), systemImage: "trash", role: .destructive) {
                    Storage.shared.deleteApp(for: app)
                }
            }
        }
    }

    @ViewBuilder
    private func _buttonActions(for app: AppInfoPresentable) -> some View {
        Group {
            if app.isSigned {
                Button {
                    selectedInstallAppPresenting = AnyApp(base: app)
                } label: {
                    FRExpirationPillView(
                        title: .localized("Install"),
                        revoked: certRevoked,
                        expiration: certInfo
                    )
                }
            } else {
                Button {
                    selectedSigningAppPresenting = AnyApp(base: app)
                } label: {
                    FRExpirationPillView(
                        title: .localized("Sign"),
                        revoked: false,
                        expiration: nil
                    )
                }
            }
        }
        .buttonStyle(.borderless)
    }
}
