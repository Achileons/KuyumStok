import SwiftUI
import SwiftData

// Giriş kilidi geçidi: kilit açıksa önce LockView, sonra menü
struct ContentView: View {
    @AppStorage("lockEnabled") private var lockEnabled = false
    @State private var unlocked = false

    var body: some View {
        Group {
            if lockEnabled && !unlocked {
                LockView(unlocked: $unlocked)
            } else {
                MenuView(unlocked: $unlocked)
            }
        }
    }
}

// Ana menü: şifreden sonra buradaki tuşlarla bölümlere gidilir
struct MenuView: View {
    @Binding var unlocked: Bool
    @AppStorage("lockEnabled") private var lockEnabled = false

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Kuyum Stok")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Theme.text)
                        Text("Bir bölüm seç")
                            .font(.system(size: 15))
                            .foregroundColor(Theme.textDim)
                    }
                    .padding(.top, 8)

                    LazyVGrid(columns: columns, spacing: 14) {
                        NavigationLink {
                            ProductsView()
                        } label: {
                            MenuTile(icon: "diamond.fill", title: "Ürünler",
                                     subtitle: "Stok & konum", color: Theme.gold)
                        }
                        NavigationLink {
                            CalendarView()
                        } label: {
                            MenuTile(icon: "calendar", title: "Takvim",
                                     subtitle: "Hareketler", color: Theme.info)
                        }
                        NavigationLink {
                            SoldProductsView()
                        } label: {
                            MenuTile(icon: "dollarsign.circle.fill", title: "Satılanlar",
                                     subtitle: "Satış & rapor", color: Theme.success)
                        }
                        NavigationLink {
                            CariView()
                        } label: {
                            MenuTile(icon: "person.2.fill", title: "Cari Hesap",
                                     subtitle: "Borç & ödeme", color: Theme.goldSoft)
                        }
                        NavigationLink {
                            SettingsView()
                        } label: {
                            MenuTile(icon: "gearshape.fill", title: "Ayarlar",
                                     subtitle: "Şube & güvenlik", color: Theme.purple)
                        }
                    }
                }
                .padding(16)
            }
            .background(Theme.bg)
            .navigationTitle("Menü")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                if lockEnabled {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { unlocked = false } label: {
                            Image(systemName: "lock.fill")
                        }
                        .tint(Theme.gold)
                    }
                }
            }
        }
        .tint(Theme.gold)
    }
}

// Menüdeki büyük kutu tuş
struct MenuTile: View {
    let icon: String
    let title: String
    var subtitle: String = ""
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(color)
                .frame(width: 64, height: 64)
                .background(color.opacity(0.13), in: RoundedRectangle(cornerRadius: 18))
            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.text)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textFaint)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Theme.border, lineWidth: 1))
    }
}
