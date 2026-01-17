import SwiftUI
import Nuke
import IDeviceSwift
import OSLog

@main
struct FeatherApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var downloadManager = DownloadManager.shared
    let storage = Storage.shared
    let heartbeat = HeartbeatManager.shared
    private let serverPackUrl = "https://backloop.dev/pack.json"

    var body: some Scene {
        WindowGroup {
            VStack {
                DownloadHeaderView(downloadManager: downloadManager)
                    .transition(.move(edge: .top).combined(with: .opacity))
                VariedTabbarView()
                    .environment(\.managedObjectContext, storage.context)
                    .onOpenURL(perform: handleURL)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            .animation(.smooth, value: downloadManager.manualDownloads.description)
            .onReceive(NotificationCenter.default.publisher(for: .heartbeatInvalidHost)) { _ in
                DispatchQueue.main.async {
                    UIAlertController.showAlertWithOk(
                        title: "InvalidHostID",
                        message: .localized("Your pairing file is invalid and is incompatible with your device, please import a valid pairing file.")
                    )
                }
            }
            .onAppear {
                if let style = UIUserInterfaceStyle(rawValue: UserDefaults.standard.integer(forKey: "Feather.userInterfaceStyle")) {
                    UIApplication.topViewController()?.view.window?.overrideUserInterfaceStyle = style
                }
                UIApplication.topViewController()?.view.window?.tintColor = UIColor(Color(hex: UserDefaults.standard.string(forKey: "Feather.userTintColor") ?? "#848ef9"))
                
                // Silent background SSL update
                updateSSLCertificatesInBackground()
            }
        }
    }

    private func handleURL(_ url: URL) {
        if url.scheme == "feather" {
            if url.host == "import-certificate" {
                guard
                    let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                    let queryItems = components.queryItems
                else { return }

                func queryValue(_ name: String) -> String? {
                    queryItems.first(where: { $0.name == name })?.value?.removingPercentEncoding
                }

                guard
                    let p12Base64 = queryValue("p12"),
                    let provisionBase64 = queryValue("mobileprovision"),
                    let passwordBase64 = queryValue("password"),
                    let passwordData = Data(base64Encoded: passwordBase64),
                    let password = String(data: passwordData, encoding: .utf8)
                else { return }

                let generator = UINotificationFeedbackGenerator()
                generator.prepare()

                guard
                    let p12URL = FileManager.default.decodeAndWrite(base64: p12Base64, pathComponent: ".p12"),
                    let provisionURL = FileManager.default.decodeAndWrite(base64: provisionBase64, pathComponent: ".mobileprovision"),
                    FR.checkPasswordForCertificate(for: p12URL, with: password, using: provisionURL)
                else {
                    generator.notificationOccurred(.error)
                    return
                }

                FR.handleCertificateFiles(
                    p12URL: p12URL,
                    provisionURL: provisionURL,
                    p12Password: password
                ) { error in
                    if let error = error {
                        UIAlertController.showAlertWithOk(title: .localized("Error"), message: error.localizedDescription)
                    } else {
                        generator.notificationOccurred(.success)
                    }
                }
                return
            }

            if url.host == "export-certificate" {
                guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }
                let queryItems = components.queryItems?.reduce(into: [String: String]()) { $0[$1.name.lowercased()] = $1.value } ?? [:]
                guard let callbackTemplate = queryItems["callback_template"]?.removingPercentEncoding else { return }
                FR.exportCertificateAndOpenUrl(using: callbackTemplate)
            }

            if let fullPath = url.validatedScheme(after: "/source/") {
                FR.handleSource(fullPath) { }
            }

            if let fullPath = url.validatedScheme(after: "/install/"), let downloadURL = URL(string: fullPath) {
                _ = DownloadManager.shared.startDownload(from: downloadURL)
            }
        } else if url.pathExtension == "ipa" || url.pathExtension == "tipa" {
            if FileManager.default.isFileFromFileProvider(at: url) {
                guard url.startAccessingSecurityScopedResource() else { return }
                FR.handlePackageFile(url) { _ in }
            } else {
                FR.handlePackageFile(url) { _ in }
            }
        }
    }

    private func updateSSLCertificatesInBackground() {
        FR.downloadSSLCertificates(from: serverPackUrl) { success in
            if !success {
                Logger.misc.warning("Failed to update SSL certificates in background")
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        createPipeline()
        createDocumentsDirectories()
        ResetView.clearWorkCache()
        addDefaultCertificates()
        return true
    }

    private func createPipeline() {
        DataLoader.sharedUrlCache.diskCapacity = 0

        let pipeline = ImagePipeline {
            let dataLoader: DataLoader = {
                let config = URLSessionConfiguration.default
                config.urlCache = nil
                return DataLoader(configuration: config)
            }()
            let dataCache = try? DataCache(name: "thewonderofyou.Feather.datacache")
            let imageCache = Nuke.ImageCache()
            dataCache?.sizeLimit = 500 * 1024 * 1024
            imageCache.costLimit = 100 * 1024 * 1024
            $0.dataCache = dataCache
            $0.imageCache = imageCache
            $0.dataLoader = dataLoader
            $0.dataCachePolicy = .automatic
            $0.isStoringPreviewsInMemoryCache = false
        }
        ImagePipeline.shared = pipeline
    }

    private func createDocumentsDirectories() {
        let fileManager = FileManager.default
        let directories: [URL] = [
            fileManager.archives,
            fileManager.certificates,
            fileManager.signed,
            fileManager.unsigned
        ]
        for url in directories { try? fileManager.createDirectoryIfNeeded(at: url) }
    }

    private func addDefaultCertificates() {
        guard
            UserDefaults.standard.bool(forKey: "feather.didImportDefaultCertificates") == false,
            let signingAssetsURL = Bundle.main.url(forResource: "signing-assets", withExtension: nil)
        else { return }

        do {
            let folderContents = try FileManager.default.contentsOfDirectory(
                at: signingAssetsURL,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            )
            for folderURL in folderContents where folderURL.hasDirectoryPath {
                let certName = folderURL.lastPathComponent
                let p12Url = folderURL.appendingPathComponent("cert.p12")
                let provisionUrl = folderURL.appendingPathComponent("cert.mobileprovision")
                let passwordUrl = folderURL.appendingPathComponent("cert.txt")

                guard
                    FileManager.default.fileExists(atPath: p12Url.path),
                    FileManager.default.fileExists(atPath: provisionUrl.path),
                    FileManager.default.fileExists(atPath: passwordUrl.path)
                else {
                    Logger.misc.warning("Skipping \(certName): missing required files")
                    continue
                }

                let password = try String(contentsOf: passwordUrl, encoding: .utf8)
                FR.handleCertificateFiles(
                    p12URL: p12Url,
                    provisionURL: provisionUrl,
                    p12Password: password,
                    certificateName: certName,
                    isDefault: true
                ) { _ in }
            }
            UserDefaults.standard.set(true, forKey: "feather.didImportDefaultCertificates")
        } catch {
            Logger.misc.error("Failed to list signing-assets: \(error)")
        }
    }
}
