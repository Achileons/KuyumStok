import SwiftUI
import SwiftData

// ============================================================
// Uygulamanın giriş noktası.
// Model değişince eski veritabanı uyumsuz kalabilir; bu durumda
// eski depoyu otomatik silip yeniden oluşturuyoruz (geliştirme kolaylığı).
// ============================================================

@main
struct KuyumStokApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([Product.self, Branch.self, StoneType.self, Category.self, Stone.self, StockTransaction.self, Contact.self, LedgerEntry.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Şema değiştiyse eski veritabanını sil ve yeniden dene
            let appSupport = URL.applicationSupportDirectory
            for name in ["default.store", "default.store-shm", "default.store-wal"] {
                try? FileManager.default.removeItem(at: appSupport.appending(path: name))
            }
            do {
                container = try ModelContainer(for: schema, configurations: [config])
            } catch {
                fatalError("Veritabanı oluşturulamadı: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(container)
    }
}
