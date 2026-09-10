import SwiftUI
import SwiftData
import PhotosUI
import UIKit

// ============================================================
// YARDIMCILAR
// ============================================================

func statusColor(_ s: ProductStatus) -> Color {
    switch s {
    case .stokta:     return Theme.success
    case .satildi:    return Theme.textDim
    case .transferde: return Theme.purple
    }
}

// Etkin ana şube adını çöz: kayıtlı ana şube geçerliyse onu, değilse ilk şubeyi, o da yoksa "Ana Şube"
func resolveMainBranch(stored: String, branches: [Branch]) -> String {
    if !stored.isEmpty && branches.contains(where: { $0.name == stored }) { return stored }
    return branches.first?.name ?? "Ana Şube"
}

// Ürün ana şubede mi? (konum ana şube adıyla başlıyorsa — "Ana Şube" veya "Ana Şube (Kaynak: ...)")
func atMainBranch(_ branchName: String?, mainName: String) -> Bool {
    guard let b = branchName, !b.isEmpty else { return false }
    return b == mainName || b.hasPrefix(mainName + " ")
}

// Görünen durum: satıldıysa Satıldı; ana şubedeyse Stokta; değilse Transferde
func displayStatus(_ p: Product, mainName: String) -> ProductStatus {
    if p.statusRaw == ProductStatus.satildi.rawValue { return .satildi }
    return atMainBranch(p.branchName, mainName: mainName) ? .stokta : .transferde
}

// Çipleri yana kaydırmak yerine alta sararak hepsini gösteren düzen
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, widest: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0; y += rowHeight + spacing; rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            widest = max(widest, x - spacing)
        }
        return CGSize(width: min(widest, maxWidth), height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > bounds.minX + maxWidth, x > bounds.minX {
                x = bounds.minX; y += rowHeight + spacing; rowHeight = 0
            }
            sub.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// Liste sonundaki "+" kutusu
struct PlusChip: View {
    var label: String = ""
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "plus").font(.system(size: 13, weight: .bold))
                if !label.isEmpty { Text(label).font(.system(size: 14, weight: .semibold)) }
            }
            .foregroundColor(Theme.gold)
            .padding(.horizontal, 14).padding(.vertical, 9)
            .background(Theme.surface, in: Capsule())
            .overlay(Capsule().stroke(Theme.gold, style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
        }
    }
}

func txColor(_ type: TxType) -> Color {
    switch type {
    case .giris:    return Theme.success
    case .satis:    return Theme.info
    case .iade:     return Theme.gold
    case .transfer: return Theme.purple
    }
}

func txIcon(_ type: TxType) -> String {
    switch type {
    case .giris:    return "plus"
    case .satis:    return "cart.fill"
    case .iade:     return "arrow.uturn.backward"
    case .transfer: return "arrow.left.arrow.right"
    }
}

func caratStr(_ c: Double) -> String { String(format: "%.2f ct", c) }

func caratText(_ c: Double) -> String {
    if c == 0 { return "" }
    if c == c.rounded() { return String(Int(c)) }
    return String(c)
}

func intText(_ v: Double) -> String { v > 0 ? String(Int(v)) : "" }

func stoneLabel(_ s: Stone) -> String {
    let t = s.type.isEmpty ? "Taş" : s.type
    return s.carat > 0 ? "\(t) · \(caratStr(s.carat))" : t
}

// Form içinde taş girişi (geçici)
struct StoneInput: Identifiable {
    let id = UUID()
    var type: String? = nil
    var carat: String = ""
    var isMain: Bool = false
    var typeSearch: String = ""

    init(type: String? = nil, carat: String = "", isMain: Bool = false) {
        self.type = type
        self.carat = carat
        self.isMain = isMain
    }
}

// iOS içinde checkbox görünümü: ana taş seçimi için
struct MainStoneCheckbox: View {
    @Binding var isOn: Bool

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isOn ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(isOn ? Theme.gold : Theme.textFaint)

                Text("Ana taş")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isOn ? Theme.gold : Theme.textDim)
            }
        }
        .buttonStyle(.plain)
    }
}

// Küçük arama kutusu (form içindeki çip listelerini süzmek için)
struct MiniSearchField: View {
    let placeholder: String
    @Binding var text: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").font(.system(size: 13)).foregroundColor(Theme.textFaint)
            TextField("", text: $text, prompt: Text(placeholder).foregroundColor(Theme.textFaint))
                .font(.system(size: 14)).foregroundColor(Theme.text)
                .autocorrectionDisabled()
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill").font(.system(size: 13)).foregroundColor(Theme.textFaint)
                }
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 1))
    }
}

let trCalendar: Calendar = {
    var c = Calendar(identifier: .gregorian)
    c.firstWeekday = 2
    c.locale = Locale(identifier: "tr_TR")
    return c
}()

func monthDays(_ month: Date) -> [Date?] {
    let cal = trCalendar
    guard let interval = cal.dateInterval(of: .month, for: month),
          let firstWeekday = cal.dateComponents([.weekday], from: interval.start).weekday,
          let count = cal.range(of: .day, in: .month, for: month)?.count else { return [] }
    let leading = (firstWeekday - cal.firstWeekday + 7) % 7
    var days: [Date?] = Array(repeating: nil, count: leading)
    for i in 0..<count {
        if let d = cal.date(byAdding: .day, value: i, to: interval.start) { days.append(d) }
    }
    return days
}

func monthTitle(_ month: Date) -> String {
    let f = DateFormatter()
    f.locale = Locale(identifier: "tr_TR")
    f.dateFormat = "LLLL yyyy"
    return f.string(from: month).capitalized
}

struct TxRow: View {
    let t: StockTransaction
    var body: some View {
        Card {
            HStack(spacing: 12) {
                Image(systemName: txIcon(t.type))
                    .font(.system(size: 16)).foregroundColor(txColor(t.type))
                    .frame(width: 40, height: 40)
                    .background(txColor(t.type).opacity(0.13), in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(t.product?.name ?? "Ürün").foregroundColor(Theme.text).fontWeight(.semibold).lineLimit(1)
                        Spacer()
                        Badge(text: t.type.label, color: txColor(t.type))
                    }
                    if t.branchName != "—" {
                        Text(t.branchName).font(.system(size: 13)).foregroundColor(Theme.textDim)
                    }
                    Text(Fmt.date(t.occurredAt)).font(.system(size: 11)).foregroundColor(Theme.textFaint)
                    if let note = t.note {
                        Text(note).font(.system(size: 13)).italic().foregroundColor(Theme.textDim)
                    }
                }
                Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(Theme.textFaint)
            }
        }
    }
}

// MARK: - Giriş kilidi

struct LockView: View {
    @Binding var unlocked: Bool
    @AppStorage("lockUsername") private var savedUser = ""
    @AppStorage("lockPassword") private var savedPass = ""
    @State private var user = ""
    @State private var pass = ""
    @State private var showError = false

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 18) {
                Image(systemName: "lock.fill").font(.system(size: 44)).foregroundColor(Theme.gold)
                Text("Kuyum Stok").font(.system(size: 24, weight: .bold)).foregroundColor(Theme.text)
                Text("Devam etmek için giriş yap").font(.system(size: 14)).foregroundColor(Theme.textDim)

                VStack(spacing: 12) {
                    TextField("", text: $user, prompt: Text("Kullanıcı adı").foregroundColor(Theme.textFaint))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .fieldStyle()
                    SecureField("", text: $pass, prompt: Text("Şifre").foregroundColor(Theme.textFaint))
                        .fieldStyle()
                }
                .padding(.top, 8)

                if showError {
                    Text("Kullanıcı adı veya şifre hatalı")
                        .font(.system(size: 13)).foregroundColor(Theme.danger)
                }

                PrimaryButton(title: "Giriş") {
                    if user == savedUser && pass == savedPass {
                        unlocked = true
                    } else {
                        showError = true
                    }
                }
                .padding(.top, 4)
            }
            .padding(24)
            .frame(maxWidth: 380)
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Ürünler (ana ekran)

struct ProductsView: View {
    @Query(sort: \Product.createdAt, order: .reverse) var products: [Product]
    @Query(sort: \StoneType.name) var customStones: [StoneType]
    @Query(sort: \Category.name) var customCategories: [Category]
    @Query(sort: \Branch.name) var branches: [Branch]
    @AppStorage("mainBranch") private var mainBranch = ""
    @State private var search = ""
    @State private var locationTab = 0     // 0 Tümü, 1 Ana Şube, 2 Diğer Yerler
    @State private var ownership = 0       // 0 Tümü, 1 Bizim, 2 Konsinye
    @State private var categoryFilter: String? = nil
    @State private var caratFilter: CaratRange = .all
    @State private var stoneFilter: String? = nil
    @State private var showAdd = false
    @State private var showList = true

    private var stoneTypes: [String] {
        var list = defaultStoneTypes
        for s in customStones.map(\.name) where !list.contains(s) { list.append(s) }
        return list
    }

    private var categoryList: [String] {
        var list = defaultCategories
        for c in customCategories.map(\.name) where !list.contains(c) { list.append(c) }
        return list
    }

    private var filtered: [Product] {
        let q = search.lowercased()
        let mainName = resolveMainBranch(stored: mainBranch, branches: branches)
        return products.filter { p in
            // Satılanlar bu sayfada görünmez (kendi sekmesinde)
            if p.statusRaw == ProductStatus.satildi.rawValue { return false }

            let matchesSearch = q.isEmpty
                || p.name.lowercased().contains(q)
                || (p.code?.lowercased().contains(q) ?? false)
                || (p.category?.lowercased().contains(q) ?? false)
                || p.stones.contains { $0.type.lowercased().contains(q) }

            let isMain = atMainBranch(p.branchName, mainName: mainName)
            let matchesLocation: Bool
            switch locationTab {
            case 1:  matchesLocation = isMain        // Ana Şube
            case 2:  matchesLocation = !isMain       // Diğer Yerler
            default: matchesLocation = true          // Tümü
            }

            let matchesOwnership = ownership == 0
                || (ownership == 1 && !p.isConsignment)
                || (ownership == 2 && p.isConsignment)

            let matchesCategory = categoryFilter == nil || p.category == categoryFilter

            let mainStones = p.sortedMainStones
            let matchesMainStoneFilters: Bool
            if caratFilter == .all && stoneFilter == nil {
                matchesMainStoneFilters = true
            } else {
                matchesMainStoneFilters = mainStones.contains { stone in
                    let st = stoneFilter == nil || stone.type == stoneFilter
                    let ct = caratFilter == .all || caratFilter.contains(stone.carat)
                    return st && ct
                }
            }

            return matchesSearch && matchesLocation && matchesOwnership && matchesCategory && matchesMainStoneFilters
        }
    }

    var body: some View {
        
            ScrollView {
                let mainName = resolveMainBranch(stored: mainBranch, branches: branches)
                VStack(alignment: .leading, spacing: 16) {

                    // Sayfa: Tümü / Ana Şube / Diğer Yerler
                    Picker("", selection: $locationTab) {
                        Text("Tümü").tag(0)
                        Text("Ana Şube").tag(1)
                        Text("Diğer").tag(2)
                    }
                    .pickerStyle(.segmented)

                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass").foregroundColor(Theme.textFaint)
                        TextField("", text: $search,
                                  prompt: Text("Ürün, kod, kategori veya taş ara").foregroundColor(Theme.textFaint))
                            .foregroundColor(Theme.text)
                            .autocorrectionDisabled()
                        if !search.isEmpty {
                            Button { search = "" } label: {
                                Image(systemName: "xmark.circle.fill").foregroundColor(Theme.textFaint)
                            }
                        }
                    }
                    .padding(.horizontal, 14).padding(.vertical, 12)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))

                    if search.isEmpty {
                        Text("Sahiplik").fieldLabel()
                        FlowLayout {
                            FilterChip(title: "Tümü", active: ownership == 0) { ownership = 0 }
                            FilterChip(title: "Bizim Ürünler", active: ownership == 1) { ownership = 1 }
                            FilterChip(title: "Konsinye", active: ownership == 2) { ownership = 2 }
                        }

                        Text("Kategori").fieldLabel()
                        FlowLayout {
                            FilterChip(title: "Tümü", active: categoryFilter == nil) { categoryFilter = nil }
                            ForEach(categoryList, id: \.self) { c in
                                FilterChip(title: c, active: categoryFilter == c) {
                                    categoryFilter = (categoryFilter == c ? nil : c)
                                }
                            }
                        }

                        Text("Taş Boyutu (ct)").fieldLabel()
                        FlowLayout {
                            ForEach(CaratRange.allCases) { range in
                                FilterChip(title: range.label, active: caratFilter == range) {
                                    caratFilter = range
                                }
                            }
                        }

                        Text("Taş Türü").fieldLabel()
                        FlowLayout {
                            FilterChip(title: "Tümü", active: stoneFilter == nil) { stoneFilter = nil }
                            ForEach(stoneTypes, id: \.self) { s in
                                FilterChip(title: s, active: stoneFilter == s) {
                                    stoneFilter = (stoneFilter == s ? nil : s)
                                }
                            }
                        }
                    }

                    HStack {
                        Text("\(filtered.count) ürün")
                            .font(.system(size: 13)).foregroundColor(Theme.textFaint)
                        Spacer()
                        Button {
                            withAnimation { showList.toggle() }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: showList ? "eye.slash" : "eye")
                                Text(showList ? "Ürünleri Gizle" : "Ürünleri Göster")
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Theme.gold)
                        }
                    }
                    .padding(.top, 4)

                    if showList {
                        LazyVStack(spacing: 12) {
                            ForEach(filtered) { product in
                                NavigationLink {
                                    ProductDetailView(product: product)
                                } label: {
                                    ProductRow(product: product, mainName: mainName)
                                }
                                .buttonStyle(.plain)
                            }
                            if filtered.isEmpty {
                                EmptyStateView(title: "Ürün yok",
                                               subtitle: products.isEmpty
                                                    ? "Sağ üstteki + ile ilk ürünü ekle."
                                                    : "Bu sayfada/filtrede ürün yok.")
                                    .padding(.top, 40)
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(Theme.bg)
            .navigationTitle("Ürünler")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: {
                        Image(systemName: "plus")
                    }
                    .tint(Theme.gold)
                }
            }
            .sheet(isPresented: $showAdd) { ProductFormView() }
        
    }
}

struct ProductRow: View {
    let product: Product
    var mainName: String = "Ana Şube"

    var body: some View {
        let st = displayStatus(product, mainName: mainName)
        return Card {
            HStack(spacing: 12) {
                ProductThumb(data: product.imageData, size: 56)
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.name).foregroundColor(Theme.text).fontWeight(.semibold).lineLimit(1)
                    HStack(spacing: 6) {
                        if let c = product.category {
                            Text(c).font(.system(size: 11, weight: .semibold)).foregroundColor(Theme.goldSoft)
                        }
                        ForEach(product.sortedStones.prefix(2)) { st in
                            Badge(text: st.type.isEmpty ? "Taş" : st.type, color: st.isMain ? Theme.gold : Theme.info)
                        }
                        if product.stones.count > 2 {
                            Text("+\(product.stones.count - 2)")
                                .font(.system(size: 11, weight: .semibold)).foregroundColor(Theme.textFaint)
                        }
                    }
                    if product.isConsignment {
                        Text(product.consignmentOwner != nil ? "Konsinye · \(product.consignmentOwner!)" : "Konsinye")
                            .font(.system(size: 11, weight: .semibold)).foregroundColor(Theme.purple)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Badge(text: st.label, color: statusColor(st))
                    if product.salePrice > 0 {
                        Text(Fmt.money(product.salePrice)).font(.system(size: 12, weight: .semibold)).foregroundColor(Theme.text)
                    }
                }
            }
        }
    }
}

// MARK: - Ürün ekle / düzenle (tek form)

struct ProductFormView: View {
    let editing: Product?
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \StoneType.name) var customStones: [StoneType]
    @Query(sort: \Category.name) var customCategories: [Category]
    @Query(sort: \Branch.name) var branches: [Branch]
    @AppStorage("mainBranch") private var mainBranch = ""

    @State private var name: String
    @State private var code: String
    @State private var category: String?
    @State private var cost: String
    @State private var salePrice: String
    @State private var markup: String
    @State private var stoneInputs: [StoneInput]
    @State private var newStone = ""
    @State private var newCategory = ""
    @State private var isConsignment: Bool
    @State private var consignmentOwner: String
    @State private var imageData: Data?
    @State private var photoItem: PhotosPickerItem?
    @State private var originSel: String?
    @State private var useOtherOrigin = false
    @State private var otherOriginName = ""
    @State private var categorySearch = ""
    @State private var originSearch = ""
    @State private var showAddCategory = false
    @State private var showAddStone = false
    @State private var showAddBranch = false
    @State private var newBranchName = ""

    init(editing: Product? = nil) {
        self.editing = editing
        _name = State(initialValue: editing?.name ?? "")
        _code = State(initialValue: editing?.code ?? "")
        _category = State(initialValue: editing?.category)
        _cost = State(initialValue: editing.map { intText($0.cost) } ?? "")
        _salePrice = State(initialValue: editing.map { intText($0.salePrice) } ?? "")
        _markup = State(initialValue: editing == nil ? (UserDefaults.standard.string(forKey: "defaultMarkup") ?? "") : "")
        _isConsignment = State(initialValue: editing?.isConsignment ?? false)
        _consignmentOwner = State(initialValue: editing?.consignmentOwner ?? "")
        _imageData = State(initialValue: editing?.imageData)
        _originSel = State(initialValue: editing?.originBranch)

        if let stones = editing?.sortedStones, !stones.isEmpty {
            _stoneInputs = State(initialValue: stones.map {
                StoneInput(
                    type: $0.type.isEmpty ? nil : $0.type,
                    carat: caratText($0.carat),
                    isMain: $0.isMain
                )
            })
        } else {
            _stoneInputs = State(initialValue: [StoneInput()])
        }
    }

    private var stoneOptions: [String] {
        var list = defaultStoneTypes
        for s in customStones.map(\.name) where !list.contains(s) { list.append(s) }
        return list
    }

    private var categoryOptions: [String] {
        var list = defaultCategories
        for c in customCategories.map(\.name) where !list.contains(c) { list.append(c) }
        return list
    }

    private var isEdit: Bool { editing != nil }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    photoSection

                    LabeledField(label: "Ürün Adı *", text: $name, placeholder: "Örn. Pırlanta Tektaş Yüzük")

                    categorySection

                    LabeledField(label: "Barkod / Etiket No", text: $code, placeholder: "Örn. YZK-0001")

                    priceSection

                    stonesSection

                    addStoneButton

                    consignmentSection

                    locationSection

                    PrimaryButton(title: isEdit ? "Değişiklikleri Kaydet" : "Ürünü Kaydet") {
                        save()
                    }
                    .padding(.top, 8)
                }
                .padding(16)
            }
            .background(Theme.bg)
            .navigationTitle(isEdit ? "Ürünü Düzenle" : "Yeni Ürün")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Kapat") { dismiss() }.tint(Theme.gold)
                }
            }
            .onChange(of: photoItem) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self) {
                        imageData = data
                    }
                }
            }
            .onChange(of: cost) { _, _ in recomputeSalePrice() }
            .onChange(of: markup) { _, _ in recomputeSalePrice() }
            .onAppear {
                let mainName = resolveMainBranch(stored: mainBranch, branches: branches)
                let known = [mainName] + branches.map(\.name)
                if let o = originSel, !o.isEmpty, !known.contains(o) {
                    useOtherOrigin = true
                    otherOriginName = o
                    originSel = nil
                }
            }
            .alert("Yeni Kategori", isPresented: $showAddCategory) {
                TextField("Kategori adı", text: $newCategory)
                Button("Ekle") { addCategory() }
                Button("Vazgeç", role: .cancel) {}
            }
            .alert("Yeni Taş Türü", isPresented: $showAddStone) {
                TextField("Taş türü adı", text: $newStone)
                Button("Ekle") { addStoneType() }
                Button("Vazgeç", role: .cancel) {}
            }
            .alert("Yeni Şube", isPresented: $showAddBranch) {
                TextField("Şube adı", text: $newBranchName)
                Button("Ekle") {
                    let t = newBranchName.trimmingCharacters(in: .whitespaces)
                    if !t.isEmpty {
                        if !branches.contains(where: { $0.name == t }) { context.insert(Branch(name: t)) }
                        useOtherOrigin = false
                        originSel = t
                    }
                }
                Button("Vazgeç", role: .cancel) {}
            }
        }
    }

    @ViewBuilder private var photoSection: some View {
        HStack {
            Spacer()
            PhotosPicker(selection: $photoItem, matching: .images) {
                ProductThumb(data: imageData, size: 140)
            }
            Spacer()
        }
    }

    @ViewBuilder private var priceSection: some View {
        HStack(spacing: 12) {
            LabeledField(label: "Maliyet ($)", text: $cost, placeholder: "0", digitsOnly: true)
            LabeledField(label: "Katlama %", text: $markup, placeholder: "0", digitsOnly: true)
        }
        LabeledField(label: "Etiket Fiyatı ($)", text: $salePrice, placeholder: "0", digitsOnly: true)
        Text("Maliyet ve katlama % girince etiket fiyatı otomatik hesaplanır. İstersen elle de değiştirebilirsin.")
            .font(.system(size: 11)).foregroundColor(Theme.textFaint)
    }

    private func recomputeSalePrice() {
        let m = markup.trimmingCharacters(in: .whitespaces)
        guard !m.isEmpty else { return }
        let c = Double(cost.replacingOccurrences(of: ",", with: ".")) ?? 0
        let p = Double(m.replacingOccurrences(of: ",", with: ".")) ?? 0
        guard c > 0 else { return }
        salePrice = String(Int((c * (1 + p / 100)).rounded()))
    }

    @ViewBuilder private var categorySection: some View {
        Text("Kategori").fieldLabel()
        MiniSearchField(placeholder: "Kategori ara", text: $categorySearch)
        FlowLayout {
            ForEach(categoryOptions.filter { categorySearch.isEmpty || $0.localizedCaseInsensitiveContains(categorySearch) }, id: \.self) { c in
                FilterChip(title: c, active: category == c) {
                    category = (category == c ? nil : c)
                }
            }
            PlusChip(label: "Yeni") { newCategory = ""; showAddCategory = true }
        }
    }

    @ViewBuilder private var stonesSection: some View {
        Text("Taşlar").sectionTitle()
        ForEach(stoneInputs.indices, id: \.self) { i in
            stoneCard(i)
        }
    }

    private func stoneCard(_ i: Int) -> some View {
        Card {
            HStack {
                Text("Taş \(i + 1)").foregroundColor(Theme.text).fontWeight(.semibold)
                Spacer()
                if stoneInputs.count > 1 {
                    Button { stoneInputs.remove(at: i) } label: {
                        Image(systemName: "trash").foregroundColor(Theme.danger)
                    }
                }
            }

            MiniSearchField(placeholder: "Taş türü ara",
                            text: Binding(get: { stoneInputs[i].typeSearch },
                                          set: { stoneInputs[i].typeSearch = $0 }))
                .padding(.top, 8)

            FlowLayout {
                ForEach(stoneOptions.filter { stoneInputs[i].typeSearch.isEmpty || $0.localizedCaseInsensitiveContains(stoneInputs[i].typeSearch) }, id: \.self) { s in
                    FilterChip(title: s, active: stoneInputs[i].type == s) {
                        stoneInputs[i].type = (stoneInputs[i].type == s ? nil : s)
                    }
                }
                PlusChip(label: "Yeni") { newStone = ""; showAddStone = true }
            }
            .padding(.top, 8)

            LabeledField(label: "Boyut (ct)",
                         text: Binding(
                            get: { stoneInputs[i].carat },
                            set: { newVal in
                                stoneInputs[i].carat = newVal
                                if stoneInputs.count == 1 && !newVal.trimmingCharacters(in: .whitespaces).isEmpty {
                                    stoneInputs[0].isMain = true
                                }
                            }
                         ),
                         placeholder: "Örn. 0.50",
                         keyboard: .decimalPad)
                .padding(.top, 10)

            MainStoneCheckbox(
                isOn: Binding(
                    get: { stoneInputs[i].isMain },
                    set: { stoneInputs[i].isMain = $0 }
                )
            )
            .padding(.top, 8)
        }
    }

    @ViewBuilder private var addStoneButton: some View {
        Button {
            if stoneInputs.count == 1 { stoneInputs[0].isMain = false }
            stoneInputs.append(StoneInput())
        } label: {
            HStack {
                Image(systemName: "plus")
                Text("Taş Ekle")
            }
            .font(.system(size: 15, weight: .semibold)).foregroundColor(Theme.gold)
            .frame(maxWidth: .infinity, minHeight: 48)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.gold, lineWidth: 1.5))
        }
    }

    @ViewBuilder private var consignmentSection: some View {
        Card {
            Toggle(isOn: $isConsignment) {
                Text("Konsinye ürün").foregroundColor(Theme.text).font(.system(size: 15, weight: .medium))
            }
            .tint(Theme.gold)
            if isConsignment {
                LabeledField(label: "Konsinye sahibi (kimden geldi)",
                             text: $consignmentOwner, placeholder: "Örn. Mehmet Kuyumcu")
                    .padding(.top, 10)
                Text("Konum otomatik ana şube olur; iade edilince bu kişiye döner.")
                    .font(.system(size: 11)).foregroundColor(Theme.textFaint).padding(.top, 6)
            }
        }
    }

    @ViewBuilder private var locationSection: some View {
        if !isConsignment {
            let mainName = resolveMainBranch(stored: mainBranch, branches: branches)
            Text("Konum / Geldiği Yer").fieldLabel()
            MiniSearchField(placeholder: "Konum / şube ara", text: $originSearch)
            FlowLayout {
                FilterChip(title: "\(mainName) (Ana)",
                           active: !useOtherOrigin && (originSel == nil || originSel == mainName)) {
                    useOtherOrigin = false
                    originSel = mainName
                }
                ForEach(branches.filter { $0.name != mainName && (originSearch.isEmpty || $0.name.localizedCaseInsensitiveContains(originSearch)) }) { b in
                    FilterChip(title: b.name, active: !useOtherOrigin && originSel == b.name) {
                        useOtherOrigin = false
                        originSel = b.name
                    }
                }
                FilterChip(title: "Başka yer (…)", active: useOtherOrigin) {
                    useOtherOrigin = true
                    originSel = nil
                }
                PlusChip(label: "Şube") { newBranchName = ""; showAddBranch = true }
            }
            if useOtherOrigin {
                LabeledField(label: "Geldiği yer — isim yaz", text: $otherOriginName,
                             placeholder: "Örn. Ali Kuyumcu / Fuar")
            }
            Text("Varsayılan ana şube. Başka şubeden/yerden geldiyse seç; iade edilince oraya döner.")
                .font(.system(size: 11)).foregroundColor(Theme.textFaint)
        }
    }

    private func addStoneType() {
        let t = newStone.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        if !stoneOptions.contains(t) { context.insert(StoneType(name: t)) }
        newStone = ""
    }

    private func addCategory() {
        let t = newCategory.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        if !categoryOptions.contains(t) { context.insert(Category(name: t)) }
        category = t
        newCategory = ""
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        func d(_ s: String) -> Double {
            Double(s.replacingOccurrences(of: ",", with: ".")) ?? 0
        }

        let owner = consignmentOwner.trimmingCharacters(in: .whitespaces)

        let prod = editing ?? Product(name: trimmed)
        if editing == nil { context.insert(prod) }

        prod.name = trimmed
        prod.code = code.isEmpty ? nil : code
        prod.category = category
        prod.cost = d(cost)
        prod.salePrice = d(salePrice)
        prod.isConsignment = isConsignment
        prod.consignmentOwner = (isConsignment && !owner.isEmpty) ? owner : nil
        prod.imageData = imageData

        // Konum / geldiği yer (iade bu konuma döner)
        let mainName = resolveMainBranch(stored: mainBranch, branches: branches)
        let origin: String
        if isConsignment {
            origin = mainName
        } else if useOtherOrigin {
            let n = otherOriginName.trimmingCharacters(in: .whitespaces)
            origin = n.isEmpty ? mainName : n
        } else {
            origin = originSel ?? mainName
        }
        prod.originBranch = origin
        if editing == nil { prod.branchName = origin }

        // Taşları yeniden oluştur
        for s in Array(prod.stones) {
            context.delete(s)
        }

        var order = 0
        for input in stoneInputs {
            let c = d(input.carat)
            let type = input.type ?? ""

            if type.isEmpty && c == 0 { continue }

            let stone = Stone(type: type, carat: c, order: order, isMain: input.isMain)
            stone.product = prod
            context.insert(stone)

            order += 1
        }

        if editing == nil {
            context.insert(StockTransaction(type: .giris, branchName: prod.branchName ?? "—", product: prod))
        }

        dismiss()
    }
}

// MARK: - Ürün detay

struct ProductDetailView: View {
    @Bindable var product: Product
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Branch.name) var branches: [Branch]
    @AppStorage("mainBranch") private var mainBranch = ""
    @State private var showSell = false
    @State private var showReturn = false
    @State private var showTransfer = false
    @State private var showEdit = false
    @State private var showDelete = false
    @State private var showBringToMain = false
    @State private var showInfo = false
    @State private var infoText = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 16) {
                    ProductThumb(data: product.imageData, size: 120)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(product.name).font(.system(size: 22, weight: .bold)).foregroundColor(Theme.text)
                        HStack(spacing: 6) {
                            if let c = product.category {
                                Badge(text: c, color: Theme.gold)
                            }

                            ForEach(product.sortedStones.prefix(2)) { st in
                                Badge(text: st.type.isEmpty ? "Taş" : st.type, color: st.isMain ? Theme.gold : Theme.info)
                            }

                            if product.stones.count > 2 {
                                Text("+\(product.stones.count - 2)")
                                    .font(.system(size: 11, weight: .semibold)).foregroundColor(Theme.textFaint)
                            }
                        }

                        if product.isConsignment {
                            Badge(text: product.consignmentOwner != nil ? "Konsinye · \(product.consignmentOwner!)" : "Konsinye", color: Theme.purple)
                        }

                        if let code = product.code {
                            Text(code).font(.system(size: 13)).foregroundColor(Theme.textFaint)
                        }
                    }
                    Spacer()
                }

                Card {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Durum").font(.system(size: 13)).foregroundColor(Theme.textDim)
                            let ds = displayStatus(product, mainName: resolveMainBranch(stored: mainBranch, branches: branches))
                            Badge(text: ds.label, color: statusColor(ds))
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 6) {
                            Text("Konum").font(.system(size: 13)).foregroundColor(Theme.textDim)
                            Text(product.branchName ?? "—").foregroundColor(Theme.text).fontWeight(.semibold)
                        }
                    }
                }

                Text("İşlemler").sectionTitle()
                HStack(spacing: 12) {
                    actionButton("Satış", "cart.fill", Theme.info) {
                        if product.status == .satildi {
                            infoText = "Bu ürün zaten satıldı."
                            showInfo = true
                        } else {
                            showSell = true
                        }
                    }
                    actionButton("İade", "arrow.uturn.backward", Theme.gold) {
                        if isAtHome {
                            infoText = "Bu ürün zaten kaynağında (konum: \(returnTarget))."
                            showInfo = true
                        } else {
                            showReturn = true
                        }
                    }
                    actionButton("Transfer", "arrow.left.arrow.right", Theme.purple) {
                        if cameFromElsewhere {
                            showBringToMain = true
                        } else {
                            showTransfer = true
                        }
                    }
                }

                if !product.stones.isEmpty {
                    Text("Taşlar").sectionTitle()
                    Card {
                        ForEach(Array(product.sortedStones.enumerated()), id: \.element.id) { idx, st in
                            InfoRow(
                                label: st.isMain ? "Taş \(idx + 1) · Ana Taş" : "Taş \(idx + 1)",
                                value: st.type.isEmpty ? (st.carat > 0 ? caratStr(st.carat) : "—") : stoneLabel(st),
                                color: st.isMain ? Theme.gold : Theme.info
                            )
                        }
                    }
                }

                Text("Detaylar").sectionTitle()
                Card {
                    if let c = product.category {
                        InfoRow(label: "Kategori", value: c, color: Theme.gold)
                    }

                    InfoRow(label: "Maliyet", value: product.cost > 0 ? Fmt.money(product.cost) : "—")
                    InfoRow(label: "Etiket Fiyatı", value: product.salePrice > 0 ? Fmt.money(product.salePrice) : "—", color: Theme.success)

                    if product.status == .satildi && product.soldPrice > 0 {
                        InfoRow(label: "Satış Fiyatı", value: Fmt.money(product.soldPrice), color: Theme.gold)
                    }

                    if let code = product.code {
                        InfoRow(label: "Barkod", value: code)
                    }

                    if product.isConsignment {
                        InfoRow(label: "Konsinye", value: product.consignmentOwner ?? "Evet", color: Theme.purple)
                    }
                }

                if let notes = product.notes, !notes.isEmpty {
                    Card {
                        Text("Notlar").font(.system(size: 13)).foregroundColor(Theme.textDim)
                        Text(notes).foregroundColor(Theme.text).padding(.top, 4)
                    }
                }
            }
            .padding(16)
        }
        .background(Theme.bg)
        .navigationTitle(product.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showEdit = true } label: {
                    Image(systemName: "pencil")
                }
                .tint(Theme.gold)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) { showDelete = true } label: {
                    Image(systemName: "trash")
                }
                .tint(Theme.danger)
            }
        }
        .sheet(isPresented: $showEdit) { ProductFormView(editing: product) }
        .sheet(isPresented: $showTransfer) { TransferView(product: product) }
        .sheet(isPresented: $showSell) { SellView(product: product) }
        .alert("İade", isPresented: $showReturn) {
            Button("Vazgeç", role: .cancel) {}
            Button("İade Et") { doReturn() }
        } message: {
            Text("Ürün \"\(returnTarget)\" konumuna geri gönderilecek.")
        }
        .alert("Ana Şubeye Al", isPresented: $showBringToMain) {
            Button("Vazgeç", role: .cancel) {}
            Button("Ana Şubeye Al") { bringToMain() }
        } message: {
            Text("Bu ürün başka bir yerden geldi. Ana şubeye alınacak ve durumu Stokta olacak; geldiği yer (\(product.originBranch ?? "?")) parantez içinde saklanır.")
        }
        .alert("Bilgi", isPresented: $showInfo) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(infoText)
        }
        .alert("Ürünü kaldır", isPresented: $showDelete) {
            Button("Vazgeç", role: .cancel) {}
            Button("Kaldır", role: .destructive) {
                context.delete(product)
                dismiss()
            }
        } message: {
            Text("Bu ürün ve tüm geçmişi silinecek. Onaylıyor musun?")
        }
    }

    private var returnTarget: String {
        // Konsinye ürün -> konsinye sahibine döner
        if product.isConsignment, let owner = product.consignmentOwner, !owner.isEmpty {
            return owner
        }
        if let o = product.originBranch, !o.isEmpty { return o }
        return resolveMainBranch(stored: mainBranch, branches: branches)
    }

    // Ürün hâlihazırda kaynağında mı? (tekrar iade engeli)
    private var isAtHome: Bool {
        product.statusRaw != ProductStatus.satildi.rawValue && (product.branchName ?? "") == returnTarget
    }

    // Ürün ana şube dışında bir yerden mi geldi?
    private var cameFromElsewhere: Bool {
        let mainName = resolveMainBranch(stored: mainBranch, branches: branches)
        if let o = product.originBranch, !o.isEmpty { return o != mainName }
        return false
    }

    private func doReturn() {
        let target = returnTarget
        product.branchName = target
        product.statusRaw = ProductStatus.stokta.rawValue   // satış işaretini kaldır
        product.soldAt = nil
        product.soldPrice = 0
        context.insert(StockTransaction(type: .iade, note: "Konum: \(target)", branchName: target, product: product))
    }

    private func bringToMain() {
        let mainName = resolveMainBranch(stored: mainBranch, branches: branches)
        let src = product.originBranch ?? "?"
        product.branchName = "\(mainName) (Kaynak: \(src))"
        product.status = .stokta
        context.insert(StockTransaction(type: .transfer, note: "Ana şubeye alındı (Kaynak: \(src))",
                                        branchName: mainName, counterBranchName: src, product: product))
    }

    private func actionButton(_ title: String, _ icon: String, _ color: Color,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20)).foregroundColor(color)
                    .frame(width: 52, height: 52)
                    .background(color.opacity(0.13), in: RoundedRectangle(cornerRadius: 12))
                Text(title).font(.system(size: 11)).foregroundColor(Theme.textDim)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Transfer

struct TransferView: View {
    @Bindable var product: Product
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Branch.name) var branches: [Branch]

    @State private var dest: String? = nil
    @State private var useOther = false
    @State private var otherName = ""
    @State private var recipient = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Card {
                        HStack(spacing: 12) {
                            Image(systemName: "diamond.fill").foregroundColor(Theme.gold)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(product.name).foregroundColor(Theme.text).fontWeight(.semibold)
                                Text("Mevcut konum: \(product.branchName ?? "—")")
                                    .font(.system(size: 13)).foregroundColor(Theme.textDim)
                            }
                            Spacer()
                        }
                    }

                    Text("Hedef").fieldLabel()
                    FlowLayout {
                        ForEach(branches) { b in
                            FilterChip(title: b.name, active: !useOther && dest == b.name) {
                                useOther = false
                                dest = b.name
                            }
                        }
                        FilterChip(title: "Diğer (…)", active: useOther) {
                            useOther = true
                            dest = nil
                        }
                    }

                    if useOther {
                        LabeledField(label: "Diğer — isim yaz", text: $otherName, placeholder: "Örn. Ali Kuyumcu / Fuar")
                    } else if dest != nil {
                        LabeledField(label: "Alan kişi (opsiyonel)", text: $recipient,
                                     placeholder: "Örn. Ahmet — konum \"şube - kişi\" olarak kaydedilir")
                    }

                    PrimaryButton(title: "Transfer Et") {
                        transfer()
                    }
                    .padding(.top, 8)
                }
                .padding(16)
            }
            .background(Theme.bg)
            .navigationTitle("Transfer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Kapat") { dismiss() }.tint(Theme.gold)
                }
            }
        }
    }

    private func transfer() {
        let location: String
        if useOther {
            let n = otherName.trimmingCharacters(in: .whitespaces)
            guard !n.isEmpty else { return }
            location = n
        } else {
            guard let b = dest else { return }
            let r = recipient.trimmingCharacters(in: .whitespaces)
            location = r.isEmpty ? b : "\(b) - \(r)"
        }

        let from = product.branchName
        product.branchName = location
        product.status = .transferde

        context.insert(
            StockTransaction(
                type: .transfer,
                note: from != nil ? "Kaynak: \(from!)" : nil,
                branchName: location,
                counterBranchName: from,
                product: product
            )
        )

        dismiss()
    }
}

// MARK: - İşlem (gün) düzenle

struct EditTransactionView: View {
    @Bindable var tx: StockTransaction
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var date: Date
    @State private var note: String
    @State private var typeSel: TxType
    @State private var price: String
    @State private var showDelete = false

    init(tx: StockTransaction) {
        self.tx = tx
        _date = State(initialValue: tx.occurredAt)
        _note = State(initialValue: tx.note ?? "")
        _typeSel = State(initialValue: tx.type)
        let sp = tx.product?.soldPrice ?? 0
        _price = State(initialValue: sp > 0 ? intText(sp) : "")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Card {
                        HStack(spacing: 12) {
                            Image(systemName: txIcon(tx.type)).foregroundColor(txColor(tx.type))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(tx.product?.name ?? "Ürün").foregroundColor(Theme.text).fontWeight(.semibold)
                                Text(tx.type.label).font(.system(size: 13)).foregroundColor(Theme.textDim)
                            }
                            Spacer()
                        }
                    }

                    Text("İşlem Türü").fieldLabel()
                    FlowLayout {
                        ForEach(TxType.allCases) { t in
                            FilterChip(title: t.label, active: typeSel == t) { typeSel = t }
                        }
                    }

                    if typeSel == .satis {
                        LabeledField(label: "Satış Fiyatı ($)", text: $price, placeholder: "0", digitsOnly: true)
                    }

                    Text("Tarih / Saat").fieldLabel()
                    Card {
                        DatePicker("Tarih", selection: $date, displayedComponents: [.date, .hourAndMinute])
                            .environment(\.locale, Locale(identifier: "tr_TR"))
                            .tint(Theme.gold)
                            .foregroundColor(Theme.text)
                    }

                    LabeledField(label: "Not", text: $note, placeholder: "Açıklama (opsiyonel)")

                    PrimaryButton(title: "Kaydet") {
                        tx.occurredAt = date
                        tx.note = note.isEmpty ? nil : note
                        tx.typeRaw = typeSel.rawValue
                        // Satışsa ürünün satış bilgisini de güncelle (Satılanlar bununla senkron olur)
                        if let p = tx.product, typeSel == .satis {
                            p.soldAt = date
                            p.soldPrice = Double(price.replacingOccurrences(of: ",", with: ".")) ?? 0
                            p.statusRaw = ProductStatus.satildi.rawValue
                        }
                        dismiss()
                    }
                    .padding(.top, 4)

                    Button(role: .destructive) { showDelete = true } label: {
                        Text("İşlemi Sil")
                            .font(.system(size: 16, weight: .bold)).foregroundColor(Theme.danger)
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.danger, lineWidth: 1.5))
                    }
                }
                .padding(16)
            }
            .background(Theme.bg)
            .navigationTitle("İşlemi Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Kapat") { dismiss() }.tint(Theme.gold)
                }
            }
            .alert("İşlemi sil", isPresented: $showDelete) {
                Button("Vazgeç", role: .cancel) {}
                Button("Sil", role: .destructive) {
                    context.delete(tx)
                    dismiss()
                }
            } message: {
                Text("Bu işlem kaydı silinecek.")
            }
        }
    }
}

// MARK: - Takvim (Gün / Aralık / Hareketler)

struct CalendarView: View {
    @Query(sort: \StockTransaction.occurredAt, order: .reverse) var transactions: [StockTransaction]
    @State private var mode = 0
    @State private var month = Date()
    @State private var selectedDay = Date()
    @State private var rangeStart = trCalendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    @State private var rangeEnd = Date()
    @State private var typeFilter: TxType? = nil
    @State private var selectedTx: StockTransaction? = nil

    private let weekdays = ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"]
    private let typeFilters: [(String, TxType?)] = [
        ("Tümü", nil),
        ("Satış", .satis),
        ("İade", .iade),
        ("Transfer", .transfer),
        ("Eklenen", .giris)
    ]

    private var shownEvents: [StockTransaction] {
        let base: [StockTransaction]

        if mode == 0 {
            base = transactions.filter { trCalendar.isDate($0.occurredAt, inSameDayAs: selectedDay) }
        } else if mode == 1 {
            let start = trCalendar.startOfDay(for: rangeStart)
            let end = trCalendar.date(byAdding: .day, value: 1, to: trCalendar.startOfDay(for: rangeEnd)) ?? rangeEnd
            base = transactions.filter { $0.occurredAt >= start && $0.occurredAt < end }
        } else {
            base = transactions
        }

        guard let f = typeFilter else { return base }
        return base.filter { $0.type == f }
    }

    var body: some View {
        
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Picker("", selection: $mode) {
                        Text("Gün").tag(0)
                        Text("Aralık").tag(1)
                        Text("Hareketler").tag(2)
                    }
                    .pickerStyle(.segmented)

                    if mode == 0 {
                        calendarCard
                        Text(Fmt.longDate(selectedDay)).sectionTitle()
                    } else if mode == 1 {
                        rangeCard
                        Text("\(shownEvents.count) işlem").sectionTitle()
                    } else {
                        Text("Tüm Hareketler").sectionTitle()
                    }

                    FlowLayout {
                        ForEach(typeFilters, id: \.0) { item in
                            FilterChip(title: item.0, active: typeFilter == item.1) {
                                typeFilter = item.1
                            }
                        }
                    }

                    LazyVStack(spacing: 8) {
                        ForEach(shownEvents) { t in
                            Button { selectedTx = t } label: {
                                TxRow(t: t)
                            }
                            .buttonStyle(.plain)
                        }

                        if shownEvents.isEmpty {
                            EmptyStateView(title: "İşlem yok",
                                           subtitle: mode == 0 ? "Bu günde işlem yok." : "Kayıt yok.")
                                .padding(.top, 40)
                        }
                    }
                }
                .padding(16)
            }
            .background(Theme.bg)
            .navigationTitle("Takvim")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(item: $selectedTx) { tx in
                EditTransactionView(tx: tx)
            }
        
    }

    private var calendarCard: some View {
        Card {
            HStack {
                Button { changeMonth(-1) } label: {
                    Image(systemName: "chevron.left").foregroundColor(Theme.gold).font(.system(size: 16, weight: .semibold))
                }

                Spacer()

                Text(monthTitle(month)).foregroundColor(Theme.text).fontWeight(.semibold)

                Spacer()

                Button { changeMonth(1) } label: {
                    Image(systemName: "chevron.right").foregroundColor(Theme.gold).font(.system(size: 16, weight: .semibold))
                }
            }
            .padding(.bottom, 10)

            HStack(spacing: 4) {
                ForEach(weekdays, id: \.self) { w in
                    Text(w)
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textFaint)
                        .frame(maxWidth: .infinity)
                }
            }

            let days = monthDays(month)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(days.indices, id: \.self) { i in
                    if let d = days[i] {
                        dayCell(d)
                    } else {
                        Color.clear.frame(height: 42)
                    }
                }
            }
            .padding(.top, 6)
        }
    }

    private func dayCell(_ d: Date) -> some View {
        let selected = trCalendar.isDate(d, inSameDayAs: selectedDay)
        let today = trCalendar.isDateInToday(d)
        let has = transactions.contains { trCalendar.isDate($0.occurredAt, inSameDayAs: d) }

        return Button {
            selectedDay = d
        } label: {
            VStack(spacing: 3) {
                Text("\(trCalendar.component(.day, from: d))")
                    .font(.system(size: 14, weight: selected ? .bold : .regular))
                    .foregroundColor(selected ? Theme.bg : (today ? Theme.gold : Theme.text))

                Circle()
                    .fill(has ? (selected ? Theme.bg : Theme.gold) : Color.clear)
                    .frame(width: 5, height: 5)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .background(selected ? Theme.gold : Color.clear, in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(today && !selected ? Theme.gold : Color.clear, lineWidth: 1))
        }
    }

    private var rangeCard: some View {
        Card {
            DatePicker("Başlangıç", selection: $rangeStart, displayedComponents: .date)
                .environment(\.locale, Locale(identifier: "tr_TR"))
                .tint(Theme.gold)
                .foregroundColor(Theme.text)

            Rectangle().fill(Theme.border).frame(height: 1).padding(.vertical, 10)

            DatePicker("Bitiş", selection: $rangeEnd, displayedComponents: .date)
                .environment(\.locale, Locale(identifier: "tr_TR"))
                .tint(Theme.gold)
                .foregroundColor(Theme.text)
        }
    }

    private func changeMonth(_ delta: Int) {
        if let m = trCalendar.date(byAdding: .month, value: delta, to: month) {
            month = m
        }
    }
}

// MARK: - Satış (fiyat girişi)

struct SellView: View {
    @Bindable var product: Product
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var price: String

    init(product: Product) {
        self.product = product
        // Etiket fiyatını öneri olarak getir
        _price = State(initialValue: product.salePrice > 0 ? intText(product.salePrice) : "")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Card {
                        HStack(spacing: 12) {
                            ProductThumb(data: product.imageData, size: 52)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(product.name).foregroundColor(Theme.text).fontWeight(.semibold)
                                if product.salePrice > 0 {
                                    Text("Etiket: \(Fmt.money(product.salePrice))")
                                        .font(.system(size: 13)).foregroundColor(Theme.textDim)
                                }
                            }
                            Spacer()
                        }
                    }

                    LabeledField(label: "Satış Fiyatı ($)", text: $price, placeholder: "0", digitsOnly: true)

                    Text("Ürün satıldı olarak işaretlenecek ve bu tutar Satılanlar sekmesinde görünecek.")
                        .font(.system(size: 12)).foregroundColor(Theme.textFaint)

                    PrimaryButton(title: "Satıldı Olarak Kaydet") { sell() }
                        .padding(.top, 4)
                }
                .padding(16)
            }
            .background(Theme.bg)
            .navigationTitle("Satış")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Kapat") { dismiss() }.tint(Theme.gold)
                }
            }
        }
    }

    private func sell() {
        let amount = Double(price.replacingOccurrences(of: ",", with: ".")) ?? 0
        product.soldPrice = amount
        product.soldAt = Date()
        product.status = .satildi
        let note = amount > 0 ? "Satış: \(Fmt.money(amount))" : nil
        context.insert(StockTransaction(type: .satis, note: note,
                                        branchName: product.branchName ?? "—", product: product))
        dismiss()
    }
}

// MARK: - Satılan ürünler

struct SoldProductsView: View {
    @Query(sort: \Product.createdAt, order: .reverse) var products: [Product]
    @State private var viewMode = 0           // 0 Liste, 1 Rapor
    @State private var ownership = 0          // 0 Tümü, 1 Bizim, 2 Konsinye
    @State private var preset = "30"          // today / 7 / 30 / month / all / custom
    @State private var rangeStart = trCalendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    @State private var rangeEnd = Date()
    @State private var copied = false

    private let presets: [(String, String)] = [
        ("Bugün", "today"), ("7 Gün", "7"), ("30 Gün", "30"),
        ("Bu Ay", "month"), ("Tümü", "all"), ("Özel", "custom")
    ]

    private var interval: (Date, Date) {
        let cal = trCalendar
        let now = Date()
        let endToday = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: now)) ?? now
        switch preset {
        case "today": return (cal.startOfDay(for: now), endToday)
        case "7":     return (cal.date(byAdding: .day, value: -6, to: cal.startOfDay(for: now)) ?? now, endToday)
        case "30":    return (cal.date(byAdding: .day, value: -29, to: cal.startOfDay(for: now)) ?? now, endToday)
        case "month": return (cal.dateInterval(of: .month, for: now)?.start ?? now, endToday)
        case "all":   return (.distantPast, .distantFuture)
        default:
            let s = cal.startOfDay(for: rangeStart)
            let e = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: rangeEnd)) ?? rangeEnd
            return (s, e)
        }
    }

    private var sold: [Product] {
        let (start, end) = interval
        return products
            .filter { p in
                guard p.statusRaw == ProductStatus.satildi.rawValue, let d = p.soldAt, d >= start, d < end else { return false }
                switch ownership {
                case 1:  return !p.isConsignment
                case 2:  return p.isConsignment
                default: return true
                }
            }
            .sorted { ($0.soldAt ?? .distantPast) > ($1.soldAt ?? .distantPast) }
    }

    private var totalRevenue: Double { sold.reduce(0) { $0 + $1.soldPrice } }
    private var totalCost: Double { sold.reduce(0) { $0 + $1.cost } }
    private var profit: Double { totalRevenue - totalCost }

    private var periodLabel: String {
        switch preset {
        case "today": return "Bugün"
        case "7":     return "Son 7 gün"
        case "30":    return "Son 30 gün"
        case "month": return "Bu ay"
        case "all":   return "Tüm zamanlar"
        default:      return "\(dstr(rangeStart)) – \(dstr(rangeEnd))"
        }
    }

    var body: some View {
        
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    Picker("", selection: $viewMode) {
                        Text("Liste").tag(0)
                        Text("Rapor").tag(1)
                    }
                    .pickerStyle(.segmented)

                    Text("Tarih Aralığı").fieldLabel()
                    FlowLayout {
                        ForEach(presets, id: \.1) { item in
                            FilterChip(title: item.0, active: preset == item.1) {
                                preset = item.1; copied = false
                            }
                        }
                    }

                    if preset == "custom" {
                        Card {
                            DatePicker("Başlangıç", selection: $rangeStart, displayedComponents: .date)
                                .environment(\.locale, Locale(identifier: "tr_TR"))
                                .tint(Theme.gold).foregroundColor(Theme.text)
                            Rectangle().fill(Theme.border).frame(height: 1).padding(.vertical, 10)
                            DatePicker("Bitiş", selection: $rangeEnd, displayedComponents: .date)
                                .environment(\.locale, Locale(identifier: "tr_TR"))
                                .tint(Theme.gold).foregroundColor(Theme.text)
                        }
                    }

                    FlowLayout {
                        FilterChip(title: "Tümü", active: ownership == 0) { ownership = 0 }
                        FilterChip(title: "Bizim Ürünler", active: ownership == 1) { ownership = 1 }
                        FilterChip(title: "Konsinye", active: ownership == 2) { ownership = 2 }
                    }

                    if viewMode == 0 {
                        summaryCard
                        if sold.isEmpty {
                            EmptyStateView(title: "Bu aralıkta satış yok",
                                           subtitle: "Farklı bir tarih aralığı seç.")
                                .padding(.top, 40)
                        } else {
                            LazyVStack(spacing: 10) {
                                ForEach(sold) { p in
                                    NavigationLink {
                                        ProductDetailView(product: p)
                                    } label: {
                                        soldRow(p)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    } else {
                        reportCard
                        Button {
                            UIPasteboard.general.string = reportText
                            withAnimation { copied = true }
                        } label: {
                            HStack {
                                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                Text(copied ? "Kopyalandı" : "Raporu Kopyala")
                            }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(copied ? Theme.success : Theme.gold)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .stroke(copied ? Theme.success : Theme.gold, lineWidth: 1.5))
                        }
                    }
                }
                .padding(16)
            }
            .background(Theme.bg)
            .navigationTitle("Satılanlar")
            .toolbarColorScheme(.dark, for: .navigationBar)
        
    }

    private var summaryCard: some View {
        Card {
            HStack {
                Text(periodLabel.uppercased())
                    .font(.system(size: 11, weight: .semibold)).foregroundColor(Theme.textFaint)
                Spacer()
                Text("\(sold.count) satış")
                    .font(.system(size: 11, weight: .semibold)).foregroundColor(Theme.textFaint)
            }
            Rectangle().fill(Theme.border).frame(height: 1).padding(.vertical, 12)
            HStack(alignment: .top) {
                statCol("Ciro", Fmt.money(totalRevenue), Theme.gold)
                Spacer()
                statCol("Maliyet", Fmt.money(totalCost), Theme.textDim)
                Spacer()
                statCol("Kâr", Fmt.money(profit), profit >= 0 ? Theme.success : Theme.danger)
            }
        }
    }

    private var reportCard: some View {
        let bizim = sold.filter { !$0.isConsignment }
        let kons = sold.filter { $0.isConsignment }
        let avg = sold.isEmpty ? 0 : totalRevenue / Double(sold.count)
        return Card {
            Text("SATIŞ RAPORU").font(.system(size: 13, weight: .bold)).foregroundColor(Theme.gold)
            Text(periodLabel).font(.system(size: 13)).foregroundColor(Theme.textDim).padding(.bottom, 6)
            Rectangle().fill(Theme.border).frame(height: 1).padding(.bottom, 4)
            InfoRow(label: "Satış adedi", value: "\(sold.count)")
            InfoRow(label: "Toplam ciro", value: Fmt.money(totalRevenue), color: Theme.gold)
            InfoRow(label: "Toplam maliyet", value: Fmt.money(totalCost))
            InfoRow(label: "Kâr", value: Fmt.money(profit), color: profit >= 0 ? Theme.success : Theme.danger)
            InfoRow(label: "Ortalama satış", value: Fmt.money(avg))
            Rectangle().fill(Theme.border).frame(height: 1).padding(.vertical, 4)
            InfoRow(label: "Bizim (adet · ciro)", value: "\(bizim.count) · \(Fmt.money(bizim.reduce(0){ $0 + $1.soldPrice }))")
            InfoRow(label: "Konsinye (adet · ciro)", value: "\(kons.count) · \(Fmt.money(kons.reduce(0){ $0 + $1.soldPrice }))", color: Theme.purple)
        }
    }

    private var reportText: String {
        let bizim = sold.filter { !$0.isConsignment }
        let kons = sold.filter { $0.isConsignment }
        let avg = sold.isEmpty ? 0 : totalRevenue / Double(sold.count)
        var s = "KUYUM STOK — SATIŞ RAPORU\n"
        s += "Dönem: \(periodLabel)\n"
        s += "Satış adedi: \(sold.count)\n"
        s += "Toplam ciro: \(Fmt.money(totalRevenue))\n"
        s += "Toplam maliyet: \(Fmt.money(totalCost))\n"
        s += "Kâr: \(Fmt.money(profit))\n"
        s += "Ortalama satış: \(Fmt.money(avg))\n"
        s += "Bizim: \(bizim.count) adet, ciro \(Fmt.money(bizim.reduce(0){ $0 + $1.soldPrice }))\n"
        s += "Konsinye: \(kons.count) adet, ciro \(Fmt.money(kons.reduce(0){ $0 + $1.soldPrice }))\n"
        return s
    }

    private func statCol(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.system(size: 12)).foregroundColor(Theme.textDim)
            Text(value).font(.system(size: 19, weight: .bold)).foregroundColor(color)
                .lineLimit(1).minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func soldRow(_ p: Product) -> some View {
        let margin = p.soldPrice - p.cost
        return Card {
            HStack(spacing: 12) {
                ProductThumb(data: p.imageData, size: 50)
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        Text(p.name).foregroundColor(Theme.text).fontWeight(.semibold).lineLimit(1)
                        if p.isConsignment { Badge(text: "Konsinye", color: Theme.purple) }
                    }
                    if let d = p.soldAt {
                        Text(Fmt.date(d)).font(.system(size: 11)).foregroundColor(Theme.textFaint)
                    }
                    HStack(spacing: 16) {
                        priceTag("Maliyet", p.cost > 0 ? Fmt.money(p.cost) : "—", Theme.textDim)
                        priceTag("Etiket", p.salePrice > 0 ? Fmt.money(p.salePrice) : "—", Theme.info)
                        priceTag("Satış", p.soldPrice > 0 ? Fmt.money(p.soldPrice) : "—", Theme.gold)
                    }
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Kâr").font(.system(size: 10)).foregroundColor(Theme.textFaint)
                    Text(Fmt.money(margin))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(margin >= 0 ? Theme.success : Theme.danger)
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(p.isConsignment ? Theme.purple.opacity(0.55) : Color.clear, lineWidth: 1.5)
        )
    }

    private func priceTag(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.system(size: 10)).foregroundColor(Theme.textFaint)
            Text(value).font(.system(size: 13, weight: .semibold)).foregroundColor(color)
        }
    }

    private func dstr(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateFormat = "dd.MM.yyyy"
        return f.string(from: d)
    }
}

// MARK: - Ayarlar

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Branch.name) var branches: [Branch]
    @AppStorage("lockEnabled") private var lockEnabled = false
    @AppStorage("lockUsername") private var lockUsername = ""
    @AppStorage("lockPassword") private var lockPassword = ""
    @AppStorage("mainBranch") private var mainBranch = ""
    @AppStorage("defaultMarkup") private var defaultMarkup = ""

    @State private var showBranch = false
    @State private var newBranch = ""
    @State private var editingBranch: Branch? = nil
    @State private var editBranchName = ""
    @State private var showEditBranch = false
    @State private var branchToDelete: Branch? = nil
    @State private var showDeleteBranch = false
    @State private var pass1 = ""
    @State private var pass2 = ""
    @State private var passMsg = ""
    @State private var passMsgOk = false

    var body: some View {
        
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Fiyatlandırma
                    Text("Fiyatlandırma").sectionTitle()
                    Card {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Varsayılan katlama %").font(.system(size: 13, weight: .medium)).foregroundColor(Theme.textDim)
                            TextField("", text: $defaultMarkup,
                                      prompt: Text("Örn. 50").foregroundColor(Theme.textFaint))
                                .keyboardType(.numberPad)
                                .fieldStyle()
                                .onChange(of: defaultMarkup) { _, v in
                                    let f = v.filter { ("0"..."9").contains($0) }
                                    if f != v { defaultMarkup = f }
                                }
                        }
                        Text("Yeni ürün eklerken bu oran hazır gelir; maliyete uygulanıp etiket fiyatı otomatik hesaplanır.")
                            .font(.system(size: 11)).foregroundColor(Theme.textFaint).padding(.top, 8)
                    }

                    // Güvenlik
                    Text("Güvenlik").sectionTitle()
                    Card {
                        Toggle(isOn: $lockEnabled) {
                            Text("Uygulama kilidi").foregroundColor(Theme.text).font(.system(size: 15, weight: .medium))
                        }
                        .tint(Theme.gold)

                        if lockEnabled {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Kullanıcı adı")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Theme.textDim)

                                TextField("", text: $lockUsername,
                                          prompt: Text("Kullanıcı adı").foregroundColor(Theme.textFaint))
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .fieldStyle()
                            }
                            .padding(.top, 12)

                            VStack(alignment: .leading, spacing: 8) {
                                Text(lockPassword.isEmpty ? "Şifre belirle" : "Şifreyi değiştir")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Theme.textDim)

                                SecureField("", text: $pass1,
                                            prompt: Text("Yeni şifre").foregroundColor(Theme.textFaint))
                                    .fieldStyle()
                                SecureField("", text: $pass2,
                                            prompt: Text("Yeni şifre (tekrar)").foregroundColor(Theme.textFaint))
                                    .fieldStyle()

                                Button { updatePassword() } label: {
                                    Text(lockPassword.isEmpty ? "Şifre Belirle" : "Şifreyi Güncelle")
                                        .font(.system(size: 14, weight: .semibold)).foregroundColor(Theme.gold)
                                        .frame(maxWidth: .infinity, minHeight: 44)
                                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.gold, lineWidth: 1.5))
                                }

                                if !passMsg.isEmpty {
                                    Text(passMsg).font(.system(size: 12))
                                        .foregroundColor(passMsgOk ? Theme.success : Theme.danger)
                                }
                            }
                            .padding(.top, 12)

                            Text("Kilit bir sonraki açılışta uygulanır. Şifre, iki kutuya da aynı yazılıp eşleştiğinde güncellenir.")
                                .font(.system(size: 11))
                                .foregroundColor(Theme.textFaint)
                                .padding(.top, 8)
                        }
                    }

                    // Şubeler
                    HStack {
                        Text("Şubeler").sectionTitle()
                        Spacer()
                        Button {
                            newBranch = ""
                            showBranch = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(Theme.gold)
                        }
                    }

                    if branches.isEmpty {
                        Text("Henüz şube yok. Sağdaki + ile ekle.")
                            .font(.system(size: 13))
                            .italic()
                            .foregroundColor(Theme.textFaint)
                    } else {
                        let effectiveMain = resolveMainBranch(stored: mainBranch, branches: branches)
                        ForEach(branches) { b in
                            Card {
                                HStack(spacing: 12) {
                                    Image(systemName: "storefront.fill").foregroundColor(Theme.gold)
                                    Text(b.name).foregroundColor(Theme.text).fontWeight(.medium).lineLimit(1)
                                    if b.name == effectiveMain {
                                        Badge(text: "Ana Şube", color: Theme.gold)
                                    }
                                    Spacer()
                                    Button { mainBranch = b.name } label: {
                                        Image(systemName: b.name == effectiveMain ? "star.fill" : "star")
                                            .foregroundColor(Theme.gold)
                                    }
                                    Button {
                                        editingBranch = b
                                        editBranchName = b.name
                                        showEditBranch = true
                                    } label: {
                                        Image(systemName: "pencil").foregroundColor(Theme.info)
                                    }
                                    Button {
                                        branchToDelete = b
                                        showDeleteBranch = true
                                    } label: {
                                        Image(systemName: "trash").foregroundColor(Theme.danger)
                                    }
                                }
                            }
                        }
                        Text("Yıldız ile ana şubeyi seç. Yeni ürünler varsayılan olarak ana şubeye eklenir.")
                            .font(.system(size: 11)).foregroundColor(Theme.textFaint)
                    }

                    Text("Uygulama").sectionTitle()
                    Card {
                        InfoRow(label: "Sürüm", value: "1.0.0")
                        InfoRow(label: "Veri", value: "Cihazda (SwiftData)")
                    }
                }
                .padding(16)
            }
            .background(Theme.bg)
            .navigationTitle("Ayarlar")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert("Yeni Şube", isPresented: $showBranch) {
                TextField("Şube adı", text: $newBranch)

                Button("Ekle") {
                    let trimmed = newBranch.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty {
                        let b = Branch(name: trimmed)
                        context.insert(b)
                        if mainBranch.isEmpty { mainBranch = trimmed }
                    }
                }

                Button("Vazgeç", role: .cancel) {}
            }
            .alert("Şubeyi Düzenle", isPresented: $showEditBranch) {
                TextField("Şube adı", text: $editBranchName)
                Button("Kaydet") {
                    let trimmed = editBranchName.trimmingCharacters(in: .whitespaces)
                    if let b = editingBranch, !trimmed.isEmpty {
                        let old = b.name
                        b.name = trimmed
                        if mainBranch == old { mainBranch = trimmed }
                    }
                }
                Button("Vazgeç", role: .cancel) {}
            }
            .alert("Şubeyi Sil", isPresented: $showDeleteBranch, presenting: branchToDelete) { b in
                Button("Sil", role: .destructive) {
                    if mainBranch == b.name { mainBranch = "" }
                    context.delete(b)
                }
                Button("Vazgeç", role: .cancel) {}
            } message: { b in
                Text("\"\(b.name)\" şubesi silinecek. Mevcut ürünler etkilenmez.")
            }
        
    }

    private func updatePassword() {
        if pass1.isEmpty {
            passMsg = "Şifre boş olamaz."
            passMsgOk = false
            return
        }
        if pass1 != pass2 {
            passMsg = "Şifreler eşleşmiyor."
            passMsgOk = false
            return
        }
        lockPassword = pass1
        pass1 = ""
        pass2 = ""
        passMsg = "Şifre güncellendi."
        passMsgOk = true
    }
}

// MARK: - Cari Hesap

struct CariView: View {
    @Query(sort: \Contact.name) var contacts: [Contact]
    @State private var search = ""
    @State private var showAdd = false

    private var filtered: [Contact] {
        let q = search.lowercased()
        return contacts.filter { q.isEmpty || $0.name.lowercased().contains(q) || ($0.phone?.contains(search) ?? false) }
    }
    private var totalReceivable: Double { contacts.reduce(0) { $0 + max($1.balanceCash, 0) } }
    private var totalPayable: Double { contacts.reduce(0) { $0 + max(-$1.balanceCash, 0) } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Card {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Toplam Alacak").font(.system(size: 12)).foregroundColor(Theme.textFaint)
                            Text(Fmt.money(totalReceivable)).font(.system(size: 18, weight: .bold)).foregroundColor(Theme.gold)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Toplam Borç").font(.system(size: 12)).foregroundColor(Theme.textFaint)
                            Text(Fmt.money(totalPayable)).font(.system(size: 18, weight: .bold)).foregroundColor(Theme.danger)
                        }
                    }
                }

                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass").foregroundColor(Theme.textFaint)
                    TextField("", text: $search, prompt: Text("Cari ara (isim / telefon)").foregroundColor(Theme.textFaint))
                        .foregroundColor(Theme.text).autocorrectionDisabled()
                    if !search.isEmpty {
                        Button { search = "" } label: { Image(systemName: "xmark.circle.fill").foregroundColor(Theme.textFaint) }
                    }
                }
                .padding(.horizontal, 14).padding(.vertical, 12)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))

                Text("\(filtered.count) cari").font(.system(size: 13)).foregroundColor(Theme.textFaint)

                LazyVStack(spacing: 12) {
                    ForEach(filtered) { c in
                        NavigationLink { CariDetailView(contact: c) } label: { contactRow(c) }
                            .buttonStyle(.plain)
                    }
                    if filtered.isEmpty {
                        EmptyStateView(title: "Cari yok", subtitle: "Sağ üstteki + ile cari ekle.")
                            .padding(.top, 40)
                    }
                }
            }
            .padding(16)
        }
        .background(Theme.bg)
        .navigationTitle("Cari Hesap")
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAdd = true } label: { Image(systemName: "plus") }.tint(Theme.gold)
            }
        }
        .sheet(isPresented: $showAdd) { ContactFormView() }
    }

    private func contactRow(_ c: Contact) -> some View {
        let b = c.balanceCash
        let g = c.balanceGold
        let pcs = c.balancePieces
        return Card {
            HStack(spacing: 12) {
                Image(systemName: "person.circle.fill").font(.system(size: 34)).foregroundColor(Theme.goldSoft)
                VStack(alignment: .leading, spacing: 2) {
                    Text(c.name).foregroundColor(Theme.text).fontWeight(.semibold).lineLimit(1)
                    if let p = c.phone, !p.isEmpty {
                        Text(p).font(.system(size: 12)).foregroundColor(Theme.textDim)
                    }
                    if g != 0 || pcs != 0 {
                        Text([g != 0 ? "Altın " + Fmt.gram(abs(g)) : nil,
                              pcs != 0 ? "\(abs(pcs)) adet" : nil]
                                .compactMap { $0 }.joined(separator: " · "))
                            .font(.system(size: 11)).foregroundColor(Theme.textFaint)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(b == 0 ? "—" : Fmt.money(abs(b)))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(b > 0 ? Theme.gold : (b < 0 ? Theme.success : Theme.textDim))
                    Text(b > 0 ? "Size borçlu" : (b < 0 ? "Alacaklı" : "Kapalı"))
                        .font(.system(size: 10)).foregroundColor(Theme.textFaint)
                }
            }
        }
    }
}

struct CariDetailView: View {
    @Bindable var contact: Contact
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var showAddEntry = false
    @State private var showEdit = false
    @State private var showDelete = false
    @State private var entryToDelete: LedgerEntry? = nil
    @State private var showDeleteEntry = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if (contact.phone?.isEmpty == false) || (contact.note?.isEmpty == false) {
                    Card {
                        if let p = contact.phone, !p.isEmpty {
                            InfoRow(label: "Telefon", value: p)
                        }
                        if let n = contact.note, !n.isEmpty {
                            InfoRow(label: "Not", value: n)
                        }
                    }
                }

                balanceCard

                PrimaryButton(title: "İşlem Ekle") { showAddEntry = true }

                Text("Hareketler").sectionTitle()
                LazyVStack(spacing: 10) {
                    ForEach(contact.sortedEntries) { e in
                        entryRow(e)
                    }
                    if contact.entries.isEmpty {
                        EmptyStateView(title: "Henüz hareket yok",
                                       subtitle: "Borç veya ödeme eklemek için İşlem Ekle.")
                            .padding(.top, 30)
                    }
                }
            }
            .padding(16)
        }
        .background(Theme.bg)
        .navigationTitle(contact.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showEdit = true } label: { Image(systemName: "pencil") }.tint(Theme.gold)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) { showDelete = true } label: { Image(systemName: "trash") }.tint(Theme.danger)
            }
        }
        .sheet(isPresented: $showAddEntry) { AddLedgerView(contact: contact) }
        .sheet(isPresented: $showEdit) { ContactFormView(editing: contact) }
        .alert("Cariyi sil", isPresented: $showDelete) {
            Button("Vazgeç", role: .cancel) {}
            Button("Sil", role: .destructive) { context.delete(contact); dismiss() }
        } message: {
            Text("Bu cari ve tüm hareketleri silinecek.")
        }
        .alert("Hareketi sil", isPresented: $showDeleteEntry, presenting: entryToDelete) { e in
            Button("Vazgeç", role: .cancel) {}
            Button("Sil", role: .destructive) { context.delete(e) }
        } message: { e in
            Text("\(e.type.label) kaydı silinecek.")
        }
    }

    private var balanceCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Net Bakiye").sectionTitle()
            Card {
                balanceLine("Nakit", Fmt.money(abs(contact.balanceCash)), contact.balanceCash)
                Rectangle().fill(Theme.border).frame(height: 1).padding(.vertical, 8)
                balanceLine("Altın", Fmt.gram(abs(contact.balanceGold)), contact.balanceGold)
                Rectangle().fill(Theme.border).frame(height: 1).padding(.vertical, 8)
                balanceLine("Mücevher", "\(abs(contact.balancePieces)) adet", Double(contact.balancePieces))
            }
        }
    }

    private func balanceLine(_ label: String, _ value: String, _ signed: Double) -> some View {
        HStack {
            Text(label).font(.system(size: 15, weight: .medium)).foregroundColor(Theme.text)
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                Text(signed == 0 ? "—" : value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(signed > 0 ? Theme.gold : (signed < 0 ? Theme.success : Theme.textDim))
                Text(signed > 0 ? "Cari borçlu" : (signed < 0 ? "Cari alacaklı" : "Kapalı"))
                    .font(.system(size: 10)).foregroundColor(Theme.textFaint)
            }
        }
    }

    private func facets(_ e: LedgerEntry) -> [String] {
        var f: [String] = []
        if e.cash > 0 { f.append("Nakit " + Fmt.money(e.cash)) }
        if e.goldGram > 0 { f.append("Altın " + Fmt.gram(e.goldGram)) }
        if e.pieceCount > 0 { f.append("\(e.pieceCount) adet") }
        if e.jewelryGram > 0 { f.append("Müc. " + Fmt.gram(e.jewelryGram)) }
        if e.stoneCarat > 0 { f.append(caratStr(e.stoneCarat)) }
        if e.labor > 0 { f.append("İşçilik " + Fmt.money(e.labor)) }
        return f
    }

    private func entryRow(_ e: LedgerEntry) -> some View {
        Card {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: e.type == .borc ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(e.type == .borc ? Theme.gold : Theme.success)
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Badge(text: e.type.label, color: e.type == .borc ? Theme.gold : Theme.success)
                        Spacer()
                        Text(Fmt.date(e.occurredAt)).font(.system(size: 11)).foregroundColor(Theme.textFaint)
                    }
                    FlowLayout(spacing: 6) {
                        ForEach(facets(e), id: \.self) { fx in
                            Text(fx)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Theme.text)
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Theme.surfaceAlt, in: Capsule())
                        }
                    }
                    if let n = e.note, !n.isEmpty {
                        Text(n).font(.system(size: 13)).foregroundColor(Theme.textDim)
                    }
                }
                Button { entryToDelete = e; showDeleteEntry = true } label: {
                    Image(systemName: "trash").foregroundColor(Theme.danger)
                }
            }
        }
    }
}

struct ContactFormView: View {
    let editing: Contact?
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var phone: String
    @State private var note: String

    init(editing: Contact? = nil) {
        self.editing = editing
        _name = State(initialValue: editing?.name ?? "")
        _phone = State(initialValue: editing?.phone ?? "")
        _note = State(initialValue: editing?.note ?? "")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    LabeledField(label: "Cari Adı *", text: $name, placeholder: "Örn. Ahmet Yılmaz")
                    LabeledField(label: "Telefon", text: $phone, placeholder: "Örn. 0555 555 55 55", keyboard: .phonePad)
                    LabeledField(label: "Not", text: $note, placeholder: "Opsiyonel")
                    PrimaryButton(title: editing == nil ? "Cari Ekle" : "Kaydet") { save() }
                        .padding(.top, 8)
                }
                .padding(16)
            }
            .background(Theme.bg)
            .navigationTitle(editing == nil ? "Yeni Cari" : "Cariyi Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Kapat") { dismiss() }.tint(Theme.gold)
                }
            }
        }
    }

    private func save() {
        let n = name.trimmingCharacters(in: .whitespaces)
        guard !n.isEmpty else { return }
        let p = phone.trimmingCharacters(in: .whitespaces)
        let nt = note.trimmingCharacters(in: .whitespaces)
        let c = editing ?? Contact(name: n)
        if editing == nil { context.insert(c) }
        c.name = n
        c.phone = p.isEmpty ? nil : p
        c.note = nt.isEmpty ? nil : nt
        dismiss()
    }
}

struct AddLedgerView: View {
    let contact: Contact
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var type: LedgerType = .borc
    @State private var cash = ""
    @State private var labor = ""
    @State private var gold = ""
    @State private var jewelryGram = ""
    @State private var carat = ""
    @State private var pieces = ""
    @State private var note = ""
    @State private var date = Date()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Card {
                        HStack(spacing: 12) {
                            Image(systemName: "person.circle.fill").font(.system(size: 28)).foregroundColor(Theme.goldSoft)
                            Text(contact.name).foregroundColor(Theme.text).fontWeight(.semibold)
                            Spacer()
                        }
                    }

                    Text("İşlem Türü").fieldLabel()
                    FlowLayout {
                        ForEach(LedgerType.allCases) { t in
                            FilterChip(title: t.label, active: type == t) { type = t }
                        }
                    }

                    Text("Nakit / İşçilik").fieldLabel()
                    HStack(spacing: 12) {
                        LabeledField(label: "Nakit ($)", text: $cash, placeholder: "0", digitsOnly: true)
                        LabeledField(label: "İşçilik ($)", text: $labor, placeholder: "0", digitsOnly: true)
                    }

                    Text("Altın / Mücevher").fieldLabel()
                    HStack(spacing: 12) {
                        LabeledField(label: "Altın (gram)", text: $gold, placeholder: "0", keyboard: .decimalPad)
                        LabeledField(label: "Mücevher (gram)", text: $jewelryGram, placeholder: "0", keyboard: .decimalPad)
                    }
                    HStack(spacing: 12) {
                        LabeledField(label: "Taş (karat)", text: $carat, placeholder: "0", keyboard: .decimalPad)
                        LabeledField(label: "Mücevher (adet)", text: $pieces, placeholder: "0", digitsOnly: true)
                    }

                    Text("Tarih").fieldLabel()
                    Card {
                        DatePicker("Tarih", selection: $date, displayedComponents: [.date, .hourAndMinute])
                            .environment(\.locale, Locale(identifier: "tr_TR"))
                            .tint(Theme.gold).foregroundColor(Theme.text)
                    }

                    LabeledField(label: "Açıklama", text: $note, placeholder: "İşlem açıklaması (opsiyonel)")

                    Text(type == .borc
                         ? "Borç: carinin size borcu artar (nakit/altın/adet)."
                         : "Alacak: cari lehine kayıt, borcu azalır.")
                        .font(.system(size: 11)).foregroundColor(Theme.textFaint)

                    PrimaryButton(title: "Kaydet") { save() }
                        .padding(.top, 4)
                }
                .padding(16)
            }
            .background(Theme.bg)
            .navigationTitle("İşlem Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Kapat") { dismiss() }.tint(Theme.gold)
                }
            }
        }
    }

    private func d(_ s: String) -> Double { Double(s.replacingOccurrences(of: ",", with: ".")) ?? 0 }

    private func save() {
        let c = d(cash), l = d(labor), g = d(gold), jg = d(jewelryGram), ct = d(carat)
        let pc = Int(pieces) ?? 0
        guard c > 0 || l > 0 || g > 0 || jg > 0 || ct > 0 || pc > 0 else { return }
        let nt = note.trimmingCharacters(in: .whitespaces)
        context.insert(LedgerEntry(type: type, cash: c, goldGram: g, pieceCount: pc,
                                   jewelryGram: jg, stoneCarat: ct, labor: l,
                                   note: nt.isEmpty ? nil : nt, occurredAt: date, contact: contact))
        dismiss()
    }
}
