import SwiftUI
import UIKit

// ============================================================
// TEMA + ORTAK BİLEŞENLER
// Renkler, biçimlendiriciler ve tekrar kullanılan görünümler.
// ============================================================

enum Theme {
    static let bg          = Color(hex: "0B0E14")
    static let surface     = Color(hex: "141925")
    static let surfaceAlt  = Color(hex: "1C2333")
    static let border      = Color(hex: "272F42")
    static let gold        = Color(hex: "D4AF37")
    static let goldSoft    = Color(hex: "E8CE7A")
    static let goldDeep    = Color(hex: "9A7B22")
    static let text        = Color(hex: "F2F4F8")
    static let textDim     = Color(hex: "9AA3B5")
    static let textFaint   = Color(hex: "5C6680")
    static let success     = Color(hex: "3FBF87")
    static let danger      = Color(hex: "E5544B")
    static let info        = Color(hex: "4C8DD6")
    static let purple      = Color(hex: "9B7BD4")
}

// Hex string -> Color
extension Color {
    init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        s = s.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: s).scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1.0)
    }
}

// Biçimlendiriciler
enum Fmt {
    static func money(_ value: Double) -> String {
        let n = NumberFormatter()
        n.numberStyle = .decimal
        n.minimumFractionDigits = 0
        n.maximumFractionDigits = 0
        n.locale = Locale(identifier: "en_US")
        return "$" + (n.string(from: NSNumber(value: value)) ?? "0")
    }
    static func gram(_ value: Double) -> String {
        let n = NumberFormatter()
        n.numberStyle = .decimal
        n.minimumFractionDigits = 2
        n.maximumFractionDigits = 3
        n.locale = Locale(identifier: "tr_TR")
        return (n.string(from: NSNumber(value: value)) ?? "0") + " gr"
    }
    static func date(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateFormat = "dd.MM.yyyy HH:mm"
        return f.string(from: date)
    }
    static func longDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateFormat = "d MMMM yyyy, EEEE"
        return f.string(from: date)
    }
}

// ---- Kart ----
struct Card<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 0) { content }
            .padding(16)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.border, lineWidth: 1))
    }
}

// ---- Rozet ----
struct Badge: View {
    let text: String
    var color: Color = Theme.gold
    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.13), in: Capsule())
            .overlay(Capsule().stroke(color, lineWidth: 1))
    }
}

// ---- Ana buton ----
struct PrimaryButton: View {
    let title: String
    var loading: Bool = false
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            ZStack {
                if loading {
                    ProgressView().tint(Theme.bg)
                } else {
                    Text(title).font(.system(size: 16, weight: .bold)).foregroundColor(Theme.bg)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(Theme.gold, in: RoundedRectangle(cornerRadius: 12))
        }
        .disabled(loading)
    }
}

// ---- Form alanı stili ----
struct FieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
            .foregroundColor(Theme.text)
    }
}
extension View {
    func fieldStyle() -> some View { modifier(FieldStyle()) }
}

// ---- Etiketli giriş alanı ----
struct LabeledField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var keyboard: UIKeyboardType = .default
    var digitsOnly: Bool = false
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !label.isEmpty {
                Text(label).font(.system(size: 13, weight: .medium)).foregroundColor(Theme.textDim)
            }
            TextField("", text: $text, prompt: Text(placeholder).foregroundColor(Theme.textFaint))
                .keyboardType(digitsOnly ? .numberPad : keyboard)
                .fieldStyle()
                .onChange(of: text) { _, newValue in
                    guard digitsOnly else { return }
                    let f = newValue.filter { ("0"..."9").contains($0) }
                    if f != newValue { text = f }
                }
        }
    }
}

// ---- Ürün küçük görseli ----
struct ProductThumb: View {
    let data: Data?
    let size: CGFloat
    var body: some View {
        Group {
            if let data, let ui = UIImage(data: data) {
                Image(uiImage: ui).resizable().scaledToFill()
            } else {
                Image(systemName: "diamond")
                    .font(.system(size: size * 0.4))
                    .foregroundColor(Theme.textFaint)
            }
        }
        .frame(width: size, height: size)
        .background(Theme.surfaceAlt)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// ---- Boş durum ----
struct EmptyStateView: View {
    let title: String
    var subtitle: String = ""
    var body: some View {
        VStack(spacing: 8) {
            Text(title).font(.system(size: 18, weight: .semibold)).foregroundColor(Theme.text)
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.system(size: 15))
                    .foregroundColor(Theme.textDim)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// ---- Yatay seçim çipleri ----
struct ChipRow: View {
    let items: [String]
    let selected: String?
    let onSelect: (String) -> Void
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(items, id: \.self) { item in
                    Button { onSelect(item) } label: {
                        Text(item)
                            .font(.system(size: 13))
                            .foregroundColor(selected == item ? Theme.goldSoft : Theme.textDim)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selected == item ? Theme.goldDeep : Theme.surface, in: Capsule())
                            .overlay(Capsule().stroke(selected == item ? Theme.gold : Theme.border, lineWidth: 1))
                    }
                }
            }
        }
    }
}

// ---- İstatistik kutusu ----
struct StatBox: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    var body: some View {
        Card {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.13), in: RoundedRectangle(cornerRadius: 12))
            Text(value).font(.system(size: 20, weight: .bold)).foregroundColor(Theme.text).padding(.top, 8)
            Text(label).font(.system(size: 13)).foregroundColor(Theme.textDim)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// ---- Filtre butonu ----
struct FilterChip: View {
    let title: String
    let active: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: active ? .semibold : .regular))
                .foregroundColor(active ? Theme.bg : Theme.textDim)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(active ? Theme.gold : Theme.surface, in: Capsule())
                .overlay(Capsule().stroke(active ? Theme.gold : Theme.border, lineWidth: 1))
        }
    }
}

// Başlık ve etiket yardımcıları
extension Text {
    func sectionTitle() -> some View {
        self.font(.system(size: 18, weight: .semibold)).foregroundColor(Theme.text)
    }
    func fieldLabel() -> some View {
        self.font(.system(size: 13, weight: .medium)).foregroundColor(Theme.textDim)
    }
}

// Ortak bilgi satırı (etiket — değer)
struct InfoRow: View {
    let label: String
    let value: String
    var color: Color = Theme.text
    var body: some View {
        HStack {
            Text(label).foregroundColor(Theme.textDim).font(.system(size: 15))
            Spacer()
            Text(value).foregroundColor(color).font(.system(size: 15, weight: .semibold))
        }
        .padding(.vertical, 6)
    }
}
