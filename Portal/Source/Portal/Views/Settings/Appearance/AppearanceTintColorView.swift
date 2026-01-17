import SwiftUI

struct AppearanceTintColorView: View {
    @AppStorage("Feather.userTintColor") private var selectedColorHex: String = "#848ef9"
    @AppStorage("Feather.userTintColor.custom") private var customColorHex: String = "#848ef9"

    @State private var customColor: Color = .blue

    private let tintOptions: [(name: String, hex: String)] = [
        (name: "Cherry Jam",        hex: "#C1121F"),
        (name: "Watermelon Slice",  hex: "#F43F5E"),
        (name: "Pink Macaron",      hex: "#F9A8D4"),
        (name: "Orchid Glow",       hex: "#D946EF"),
        (name: "Lavender Ink",      hex: "#8B5CF6"),
        (name: "Deep Ocean",        hex: "#1D4ED8"),
        (name: "Sky Glass",         hex: "#38BDF8"),
        (name: "Mint Leaf",         hex: "#34D399"),
        (name: "Wasabi Pop",        hex: "#84CC16"),
        (name: "Mango Sorbet",      hex: "#FACC15"),
        (name: "Pumpkin Spice",     hex: "#F97316"),
        (name: "Apricot Nectar",    hex: "#FDBA74"),
        (name: "Peach Latte",       hex: "#F4A896"),
        (name: "Biscoff Spread",    hex: "#A47C65"),
        (name: "Slate Stone",       hex: "#6B7280"),
        (name: "Vanilla Cream",     hex: "#F7F2E8"),
    ]

    private var cornerRadius: Double {
        if #available(iOS 26.0, *) { return 28.0 }
        return 10.5
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHGrid(rows: [GridItem(.fixed(100))], spacing: 12) {
                customCard()

                ForEach(tintOptions, id: \.hex) { option in
                    presetCard(name: option.name, hex: option.hex)
                }
            }
        }
        .onAppear {
            customColor = Color(hex: customColorHex)
        }
        .onChange(of: selectedColorHex) { value in
            UIApplication.topViewController()?.view.window?.tintColor = UIColor(Color(hex: value))
        }
    }

    private func customCard() -> some View {
        let borderColor = Color(hex: customColorHex)

        return VStack(spacing: 8) {
            ColorPicker("", selection: $customColor, supportsOpacity: false)
                .labelsHidden()
                .frame(width: 30, height: 30)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .strokeBorder(Color.black.opacity(0.3), lineWidth: 2)
                )
                .onChange(of: customColor) { newValue in
                    let hex = UIColor(newValue).toHexString()
                    customColorHex = hex
                    selectedColorHex = hex
                }
                .onTapGesture {
                    selectedColorHex = customColorHex
                }

            Text("Custom")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(width: 120, height: 100)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(selectedColorHex == customColorHex ? borderColor : .clear, lineWidth: 2)
        )
        .onTapGesture {
            selectedColorHex = customColorHex
        }
        .accessibilityLabel(Text("Custom"))
    }

    private func presetCard(name: String, hex: String) -> some View {
        let color = Color(hex: hex)

        return VStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 30, height: 30)
                .overlay(
                    Circle()
                        .strokeBorder(Color.black.opacity(0.3), lineWidth: 2)
                )

            Text(name)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(width: 120, height: 100)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(selectedColorHex == hex ? color : .clear, lineWidth: 2)
        )
        .onTapGesture {
            selectedColorHex = hex
        }
        .accessibilityLabel(Text(name))
    }
}

private extension UIColor {
    convenience init(_ color: Color) {
        if let cg = color.cgColor {
            self.init(cgColor: cg)
            return
        }
        self.init(red: 0, green: 0, blue: 0, alpha: 1)
    }

    func toHexString() -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
