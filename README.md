# KuyumStok

**In progress · Geliştirme aşamasında**

Kuyum ve mücevher işletmeleri için geliştirilen bir iPhone ve iPad uygulaması. Ürün bilgilerini, taş detaylarını, şube hareketlerini, satışları ve cari hesapları tek bir yerde takip etmeyi amaçlar.

SwiftUI ile hazırlanmış Türkçe arayüzü ve cihazda çalışan SwiftData veritabanı vardır. Mevcut sürüm yerel bir prototiptir.

## Özellikler

| Bölüm | Yapılabilenler |
|---|---|
| **Ürünler** | Ürün ekleme ve düzenleme; fotoğraf, ürün kodu, kategori, ayar, maliyet, satış fiyatı ve not kaydetme |
| **Taş detayları** | Bir ürüne birden fazla taş ekleme; tür, karat ve ana taş seçimi |
| **Arama ve filtreler** | Ürün adı, kod, kategori veya taş üzerinden arama; şube, konsinye durumu, taş türü ve karat aralığına göre filtreleme |
| **Stok hareketleri** | Ürün girişleri, satış, iade ve şubeler arası transfer; işlem geçmişi ve takvim görünümü |
| **Satılanlar** | Satılan ürünleri, satış tarihlerini ve tutarlarını ayrı ekranda takip etme |
| **Cari hesaplar** | Müşteri ve tedarikçi kartları; borç/alacak hareketleri; nakit, altın gramı, mücevher adedi, taş karatı ve işçilik bilgileri |
| **Ayarlar** | Şubeleri ve ana şubeyi yönetme, varsayılan kâr oranı ve isteğe bağlı uygulama kilidi |

## Teknolojiler

- **Swift ve SwiftUI:** uygulama mantığı ve kullanıcı arayüzü.
- **SwiftData:** ürün, taş, şube, stok hareketi ve cari hesap kayıtlarının cihazda saklanması.
- **PhotosUI:** fotoğraf arşivinden ürün görseli seçimi.
- **AppStorage:** uygulama tercihleri.

Mevcut kodda harici paket bağımlılığı veya kurulması gereken bir backend servisi bulunmuyor.

## Kurulum ve çalıştırma

### Gereksinimler

- macOS üzerinde, **iOS 26.2 SDK** desteği olan Xcode.
- iOS/iPadOS **26.2 veya üzeri** bir simülatör ya da cihaz. Bu alt sürüm sınırı mevcut Xcode proje ayarından gelir.

### Adımlar

1. Repoyu indir ve Xcode projesini aç:

   ```sh
   git clone https://github.com/Achileons/KuyumStok.git
   cd KuyumStok
   open KuyumStok.xcodeproj
   ```

2. Xcode'da **KuyumStok** scheme'ini ve uygun bir iPhone/iPad simülatörünü seç.
3. **Run / ⌘R** ile uygulamayı başlat.
4. Fiziksel cihaz kullanacaksan **Signing & Capabilities → Team** alanında kendi geliştirme hesabını seç. Gerekirse Bundle Identifier değerini kendi hesabına uygun şekilde değiştir.

İlk kullanımda **Ayarlar** bölümünden şubeleri ve ana şubeyi tanımlayabilir, ardından **Ürünler** ekranından örnek ürünler ekleyebilirsin. Uygulama kilidi varsayılan olarak kapalıdır; etkinleştirmeden önce Ayarlar'dan kullanıcı adı ve şifre belirlenir.

## Proje yapısı

```text
KuyumStok.xcodeproj/          Xcode proje ayarları
KuyumStok/
  KuyumStokApp .swift         Uygulama başlangıcı ve SwiftData kurulumu
  ContentView .swift          Ana menü ve kilit ekranı geçişi
  Models.swift               Veri modelleri
  Screens.swift              Ürün, satış, transfer, takvim ve cari hesap ekranları
  Theme.swift                Renkler, biçimlendirme ve ortak arayüz bileşenleri
  Assets.xcassets/            Görsel kaynaklar
```

İki Swift dosyasının adında uzantıdan önce boşluk vardır; yukarıdaki liste mevcut dosya adlarını gösterir.

## Mevcut sınırlar

**Bu sürümü örnek verilerle kullan.** SwiftData deposu oluşturulurken hata oluşursa uygulama mevcut `default.store` veritabanını ve yan dosyalarını silmeyi deneyip boş bir depo oluşturmayı yeniden dener. Bu davranış veri kaybına yol açabilir; güvenli veri geçişi ve yedekleme akışı henüz uygulanmış değildir.

Uygulama kilidinin kullanıcı adı ve şifresi şu anda `AppStorage` içinde tutulur. Üretim kullanımı için güvenli kimlik bilgisi saklama ve erişim yönetimi geliştirilmelidir.

Bulut senkronizasyonu, çok kullanıcılı sunucu erişimi, otomatik yedekleme ve dosyaya dışa aktarma mevcut sürüme dahil değildir. Şubeler, aynı cihazdaki stok kayıtları üzerinde yönetilir.

## Geliştirme

Proje aktif geliştirme aşamasındadır. Hata veya önerilerini [Issues](https://github.com/Achileons/KuyumStok/issues) üzerinden paylaşabilirsin. Örneklerde gerçek müşteri bilgileri veya işletme kayıtları kullanma.
