import Foundation
import SwiftData

// ============================================================
// VERİ MODELLERİ (SwiftData)
// ============================================================

enum ProductStatus: String, Codable, CaseIterable, Identifiable {
    case stokta, satildi, transferde
    var id: String { rawValue }
    var label: String {
        switch self {
        case .stokta:     return "Stokta"
        case .satildi:    return "Satıldı"
        case .transferde: return "Transferde"
        }
    }
}

enum TxType: String, Codable, CaseIterable, Identifiable {
    case giris, satis, iade, transfer
    var id: String { rawValue }
    var label: String {
        switch self {
        case .giris:    return "Eklendi"
        case .satis:    return "Satıldı"
        case .iade:     return "İade"
        case .transfer: return "Transfer"
        }
    }
}

let defaultStoneTypes = ["Pırlanta", "Zümrüt", "Ruby", "Sapphire", "Fancy"]

// Kategoriler (kullanıcı yenisini de ekleyebilir)
let defaultCategories = ["Yüzük", "Alyans", "Kolye", "Küpe", "Bileklik", "Bilezik", "Set", "Taş", "Künye", "Broş"]

enum CaratRange: String, CaseIterable, Identifiable {
    case all, r0_1, r1_3, r3_5, r5_10, r10plus

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all:     return "Tümü"
        case .r0_1:    return "0–1 ct"
        case .r1_3:    return "1–3 ct"
        case .r3_5:    return "3–5 ct"
        case .r5_10:   return "5-10 ct"
        case .r10plus: return "10+ ct"
        }
    }

    func contains(_ ct: Double) -> Bool {
        switch self {
        case .all:     return true
        case .r0_1:    return ct > 0 && ct <= 1
        case .r1_3:    return ct > 1 && ct <= 3
        case .r3_5:    return ct > 3 && ct <= 5
        case .r5_10:   return ct > 5 && ct <= 10
        case .r10plus: return ct > 10
        }
    }
}

// Taş türü sözlüğü (kalıcı)
@Model
final class StoneType {
    var name: String
    var createdAt: Date

    init(name: String) {
        self.name = name
        self.createdAt = Date()
    }
}

// Kategori sözlüğü (kalıcı)
@Model
final class Category {
    var name: String
    var createdAt: Date

    init(name: String) {
        self.name = name
        self.createdAt = Date()
    }
}

@Model
final class Branch {
    var name: String
    var createdAt: Date

    init(name: String) {
        self.name = name
        self.createdAt = Date()
    }
}

@Model
final class Stone {
    var type: String
    var carat: Double
    var order: Int
    var isMain: Bool
    var product: Product?

    init(type: String, carat: Double, order: Int = 0, isMain: Bool = false) {
        self.type = type
        self.carat = carat
        self.order = order
        self.isMain = isMain
    }
}

@Model
final class Product {
    var name: String
    var code: String?
    var category: String?
    var karat: Int
    var cost: Double
    var salePrice: Double
    var soldPrice: Double
    var soldAt: Date?
    var notes: String?
    var imageData: Data?
    var statusRaw: String
    var branchName: String?
    var originBranch: String?
    var isConsignment: Bool
    var consignmentOwner: String?
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Stone.product)
    var stones: [Stone] = []

    @Relationship(deleteRule: .cascade, inverse: \StockTransaction.product)
    var transactions: [StockTransaction] = []

    var status: ProductStatus {
        get { ProductStatus(rawValue: statusRaw) ?? .stokta }
        set { statusRaw = newValue.rawValue }
    }

    var sortedStones: [Stone] {
        stones.sorted { $0.order < $1.order }
    }

    var sortedMainStones: [Stone] {
        sortedStones.filter { $0.isMain }
    }

    init(name: String,
         code: String? = nil,
         category: String? = nil,
         karat: Int = 0,
         cost: Double = 0,
         salePrice: Double = 0,
         soldPrice: Double = 0,
         soldAt: Date? = nil,
         notes: String? = nil,
         imageData: Data? = nil,
         branchName: String? = nil,
         originBranch: String? = nil,
         isConsignment: Bool = false,
         consignmentOwner: String? = nil) {
        self.name = name
        self.code = code
        self.category = category
        self.karat = karat
        self.cost = cost
        self.salePrice = salePrice
        self.soldPrice = soldPrice
        self.soldAt = soldAt
        self.notes = notes
        self.imageData = imageData
        self.statusRaw = ProductStatus.stokta.rawValue
        self.branchName = branchName
        self.originBranch = originBranch
        self.isConsignment = isConsignment
        self.consignmentOwner = consignmentOwner
        self.createdAt = Date()
    }
}

@Model
final class StockTransaction {
    var typeRaw: String
    var note: String?
    var branchName: String
    var counterBranchName: String?
    var occurredAt: Date
    var product: Product?

    var type: TxType {
        TxType(rawValue: typeRaw) ?? .giris
    }

    init(type: TxType,
         note: String? = nil,
         branchName: String,
         counterBranchName: String? = nil,
         product: Product? = nil) {
        self.typeRaw = type.rawValue
        self.note = note
        self.branchName = branchName
        self.counterBranchName = counterBranchName
        self.product = product
        self.occurredAt = Date()
    }
}

// ============================================================
// CARİ HESAP
// ============================================================

enum LedgerType: String, Codable, CaseIterable, Identifiable {
    case borc, alacak
    var id: String { rawValue }
    var label: String {
        switch self {
        case .borc:   return "Borç"
        case .alacak: return "Alacak"
        }
    }
}

// Cari (müşteri / tedarikçi)
@Model
final class Contact {
    var name: String
    var phone: String?
    var note: String?
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \LedgerEntry.contact)
    var entries: [LedgerEntry] = []

    init(name: String, phone: String? = nil, note: String? = nil) {
        self.name = name
        self.phone = phone
        self.note = note
        self.createdAt = Date()
    }

    // Yön: borç +, alacak -  (pozitif = cari size borçlu)
    private func net(_ v: (LedgerEntry) -> Double) -> Double {
        entries.reduce(0) { $0 + ($1.type == .borc ? v($1) : -v($1)) }
    }
    var balanceCash: Double { net { $0.cash } }
    var balanceGold: Double { net { $0.goldGram } }
    var balancePieces: Int { Int(net { Double($0.pieceCount) }) }

    var sortedEntries: [LedgerEntry] { entries.sorted { $0.occurredAt > $1.occurredAt } }
}

@Model
final class LedgerEntry {
    var typeRaw: String
    var cash: Double          // nakit
    var goldGram: Double      // altın gram
    var pieceCount: Int       // mücevher adet
    var jewelryGram: Double   // mücevher gramı
    var stoneCarat: Double    // taş karatı
    var labor: Double         // işçilik tutarı
    var note: String?
    var occurredAt: Date
    var contact: Contact?

    var type: LedgerType { LedgerType(rawValue: typeRaw) ?? .borc }

    init(type: LedgerType,
         cash: Double = 0,
         goldGram: Double = 0,
         pieceCount: Int = 0,
         jewelryGram: Double = 0,
         stoneCarat: Double = 0,
         labor: Double = 0,
         note: String? = nil,
         occurredAt: Date = Date(),
         contact: Contact? = nil) {
        self.typeRaw = type.rawValue
        self.cash = cash
        self.goldGram = goldGram
        self.pieceCount = pieceCount
        self.jewelryGram = jewelryGram
        self.stoneCarat = stoneCarat
        self.labor = labor
        self.note = note
        self.occurredAt = occurredAt
        self.contact = contact
    }
}
