import SwiftUI
import NimbleViews
import Zsign

struct LibraryInfoView: View {
    var app: AppInfoPresentable

    var body: some View {
        NBNavigationView(app.name ?? "", displayMode: .inline) {
            List {
                _infoSection(for: app)
                _certSection(for: app)
                _bundleSection(for: app)
                _executableSection(for: app)

                Section {
                    Button(.localized("Open in Files"), systemImage: "folder") {
                        UIApplication.open(Storage.shared.getUuidDirectory(for: app)!.toSharedDocumentsURL()!)
                    }
                }
            }
            .toolbar {
                NBToolbarButton(role: .close)
            }
        }
    }
}

extension LibraryInfoView {
    @ViewBuilder
    private func _infoSection(for app: AppInfoPresentable) -> some View {
        NBSection(.localized("Info")) {
            if let name = app.name {
                _infoCell(.localized("Name"), desc: name)
            }

            if let ver = app.version {
                _infoCell(.localized("Version"), desc: ver)
            }

            if let id = app.identifier {
                _infoCell(.localized("Identifier"), desc: id)
            }

            if let date = app.date {
                _infoCell(.localized("Date Added"), desc: date.formatted())
            }
        }
    }

    @ViewBuilder
    private func _certSection(for app: AppInfoPresentable) -> some View {
        if let cert = Storage.shared.getCertificate(from: app) {
            NBSection(.localized("Certificate")) {
                CertificatesCellView(cert: cert)
            }
        }
    }

    @ViewBuilder
    private func _bundleSection(for app: AppInfoPresentable) -> some View {
        NBSection(.localized("Bundle")) {
            NavigationLink(.localized("Alternative Icons")) {
                SigningAlternativeIconView(app: app, appIcon: .constant(nil), isModifing: .constant(false))
            }
            NavigationLink(.localized("Frameworks & PlugIns")) {
                SigningFrameworksView(app: app, options: .constant(nil))
            }
        }
    }

    @ViewBuilder
    private func _executableSection(for app: AppInfoPresentable) -> some View {
        NBSection(.localized("Executable")) {
            NavigationLink(.localized("Dylibs")) {
                SigningDylibView(app: app, options: .constant(nil))
            }
        }
    }

    @ViewBuilder
    private func _infoCell(_ title: String, desc: String) -> some View {
        LabeledContent(title) {
            Text(desc)
        }
        .copyableText(desc)
    }
}
