import SwiftUI
import NimbleViews
import UIKit
import Darwin
import IDeviceSwift

struct SettingsView: View {
    @AppStorage("feather.selectedCert") private var _storedSelectedCert: Int = 0
    @State private var _currentIcon: String? = UIApplication.shared.alternateIconName

    @FetchRequest(
        entity: CertificatePair.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)],
        animation: .snappy
    ) private var _certificates: FetchedResults<CertificatePair>

    private var selectedCertificate: CertificatePair? {
        guard _storedSelectedCert >= 0, _storedSelectedCert < _certificates.count else { return nil }
        return _certificates[_storedSelectedCert]
    }

    var body: some View {
        NBNavigationView(.localized("Settings")) {
            Form {
                Section {
                    NavigationLink(destination: AppearanceView(currentIcon: $_currentIcon)) {
                        Label(.localized("Appearance"), systemImage: "paintbrush")
                    }
                }

                NBSection(.localized("Features")) {
                    NavigationLink(destination: CertificatesView()) {
                        Label(.localized("Certificates"), systemImage: "checkmark.seal")
                    }
                    NavigationLink(destination: ConfigurationView()) {
                        Label(.localized("Signing Options"), systemImage: "signature")
                    }
                }

                Section {
                    NavigationLink(destination: ResetView()) {
                        Label(.localized("Reset"), systemImage: "trash")
                    }
                }
            }
        }
    }
}
