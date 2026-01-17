import SwiftUI
import NimbleViews

struct InstallationView: View {
    var body: some View {
        NBList(.localized("Installation")) {
            ServerView()
        }
    }
}
