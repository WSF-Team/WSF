import Foundation

actor GitHubGuidesClient {
    struct Config: Hashable {
        let indexURL: URL
        let baseURL: URL
    }

    enum ClientError: Error, LocalizedError {
        case badHTTPStatus(Int)
        case emptyData

        var errorDescription: String? {
            switch self {
            case .badHTTPStatus(let code): "Request failed (\(code))."
            case .emptyData: "No data received."
            }
        }
    }

    private let session: URLSession
    private let cacheDir: URL

    init() {
        let cfg = URLSessionConfiguration.default
        cfg.requestCachePolicy = .useProtocolCachePolicy
        cfg.urlCache = URLCache(memoryCapacity: 50_000_000, diskCapacity: 200_000_000, diskPath: "GuidesURLCache")
        self.session = URLSession(configuration: cfg)

        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.cacheDir = base.appendingPathComponent("GuidesDiskCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
    }

    func fetchIndex(from config: Config) async throws -> [GuideIndexItem] {
        let data = try await fetchData(url: config.indexURL, cacheKey: "index.plist", maxAge: 60 * 10)
        return try PropertyListDecoder().decode([GuideIndexItem].self, from: data)
    }

    func fetchMarkdown(for item: GuideIndexItem, config: Config) async throws -> String {
        let url = config.baseURL.appendingPathComponent(item.fileName)
        let data = try await fetchData(url: url, cacheKey: "md-\(item.fileName)", maxAge: 60 * 60 * 24)
        return String(data: data, encoding: .utf8) ?? ""
    }

    private func fetchData(url: URL, cacheKey: String, maxAge: TimeInterval) async throws -> Data {
        if let cached = try readDiskCache(key: cacheKey, maxAge: maxAge) {
            return cached
        }

        var req = URLRequest(url: url)
        req.timeoutInterval = 30
        req.setValue("no-cache", forHTTPHeaderField: "Cache-Control")

        let (data, resp) = try await session.data(for: req)
        if let http = resp as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw ClientError.badHTTPStatus(http.statusCode)
        }
        guard !data.isEmpty else { throw ClientError.emptyData }

        try writeDiskCache(key: cacheKey, data: data)
        return data
    }

    private func cacheFileURL(for key: String) -> URL {
        cacheDir.appendingPathComponent(key.replacingOccurrences(of: "/", with: "_"))
    }

    private func readDiskCache(key: String, maxAge: TimeInterval) throws -> Data? {
        let url = cacheFileURL(for: key)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
        if let date = attrs[.modificationDate] as? Date, Date().timeIntervalSince(date) <= maxAge {
            return try Data(contentsOf: url)
        }
        return nil
    }

    private func writeDiskCache(key: String, data: Data) throws {
        let url = cacheFileURL(for: key)
        try data.write(to: url, options: .atomic)
    }
}
