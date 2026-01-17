import SwiftUI
import NimbleJSON
import NimbleViews

extension ServerView {
    struct ServerPackModel: Decodable {
        var cert: String
        var ca: String
        var key: String
        var info: ServerPackInfo
        
        private enum CodingKeys: String, CodingKey {
            case cert, ca, key1, key2, info
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            cert = try container.decode(String.self, forKey: .cert)
            ca = try container.decode(String.self, forKey: .ca)
            let key1 = try container.decode(String.self, forKey: .key1)
            let key2 = try container.decode(String.self, forKey: .key2)
            key = key1 + key2
            info = try container.decode(ServerPackInfo.self, forKey: .info)
        }
        
        struct ServerPackInfo: Decodable {
            var issuer: Domains
            var domains: Domains
        }
        
        struct Domains: Decodable {
            var commonName: String
        }
    }
}

struct ServerView: View {
    @AppStorage("Feather.ipFix") private var _ipFix: Bool = false
    @AppStorage("Feather.serverMethod") private var _serverMethod: Int = 0
    private let _serverMethods: [String] = [.localized("Fully Local"), .localized("Semi Local")]
    
    var body: some View {
        Group {
            Section {
                Picker(.localized("Server Type"), systemImage: "server.rack", selection: $_serverMethod) {
                    ForEach(_serverMethods.indices, id: \.description) { index in
                        Text(_serverMethods[index]).tag(index)
                    }
                }
                Toggle(.localized("Only use localhost address"), systemImage: "lifepreserver", isOn: $_ipFix)
                    .disabled(_serverMethod != 1)
            }
        }
    }
}
