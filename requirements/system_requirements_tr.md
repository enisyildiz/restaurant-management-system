# Restoran Yönetim Sistemi - Sistem Gereksinimleri ve Mimari Dokümantasyonu (SRS)

Bu doküman, Flutter (Dart) kullanılarak geliştirilmiş olan Restoran Yönetim Sistemi'nin tüm işlevsel, mimari ve altyapısal gereksinimlerini detaylı olarak listelemektedir. Bu dökümanın tamamı yapay zekaya yazdırılmıştır ileride daha detaylı bir şekilde insan tarafından yazılabilir. Bilginin kaybolmaması amaçlandı.

## 1. Mimari ve Temel Altyapı

### 1.1. Dağıtık Ağ Mimarisi (Client-Server WebSocket Modeli)
- Sistem, **Kasa/Yönetici (Admin)** ve **Garson (Client)** olmak üzere iki ayrı rolde çalışacak şekilde tek bir uygulama içine inşa edilmiştir.
- **Server (Sunucu) Rolü:** `admin` kullanıcısı sisteme giriş yaptığında uygulama bilgisayarda `8182` portu üzerinden bir WebSocket sunucusu başlatır. Tüm veri tabanı ve dosya yazma işlemleri **sadece** Admin cihazında gerçekleştirilir.
- **Client (İstemci) Rolü:** `garson` kullanıcısı giriş yaptığında, uygulama sunucuya (Admin IP'si üzerinden) bir WebSocket istemcisi olarak bağlanır. 
- **Veri Senkronizasyonu:**
  - Garson bağlandığı anda, aralarında bir `handshake` (el sıkışma) başlar. İstemcinin başlangıç zamanı (startupTime), sunucudan daha yeniyse, istemci tüm durumu yeniden talep eder (`request_full_state`).
  - Sunucu, anlık masaları, menüyü ve kategorileri bir `full_state` mesajıyla istemciye iletir ve garson ekranları eksiksiz senkronize olur.
  - Masalardaki her ekleme, silme, masa taşıma, fiyat değiştirme işlemi anlık olarak `NetworkService` üzerinden tüm istemcilere (broadcast) yayınlanır.

### 1.2. Veri Kalıcılığı (Persistence)
- **Geçici/Canlı Hafıza (`tables.json`):** Aktif oturan masalar, verilen siparişler ve özel tanımlı masa fiyatları uygulamanın her adımında saniyesi saniyesine (arka planda sessizce, `_saveTablesSilent()` fonksiyonu ile) `tables.json` dosyasına işlenir. Elektrik kesintisi veya uygulama çökmesi durumunda aktif masalar kaybolmaz, program tekrar açıldığında son haliyle yüklenir.
- **Tarihsel Hafıza (SQLite):** SQLite kullanılarak `closed_tables`, `order_events` (eklenen ve silinen ürünlerin saat bazlı detaylı logları) ve `receipts` (kapalı fişler) tabloları tutulmaktadır.

## 2. Kullanıcı Rolleri ve Kimlik Doğrulama

### 2.1. Yönetici (Admin) Rolü
- Sisteme `admin` / `admin` kimlik bilgileriyle girer.
- Sunucuyu (Host) başlatır.
- Dashboard (Canlı Veri Grafikleri), Masa Yönetimi, Menü Yönetimi ve genel tüm ayarlara erişim hakkı vardır.
- SQLite veri tabanına yazma hakkı **yalnızca** bu role aittir. Garson uygulamaları, siparişi Admin'e iletir; Admin diske yazar.

### 2.2. Garson (Waiter) Rolü
- Sisteme `garson` / `1234` kimlik bilgileriyle girer.
- Ekranında sadece "Sipariş (Order View)" bölümü açıktır.
- Görevi masalara sipariş girmek, miktar düzenlemek, mutfağa yazdır butonuna basmak veya hesap istemektir. Yönetim ekranlarına veya grafiklere erişemez.

## 3. Masa Yönetimi (Table Management)

### 3.1. Masaların Oluşturulması ve Düzenlenmesi
- Admin, "Masa Yönetimi" sekmesi üzerinden sisteme sınırsız sayıda yeni bölge (Örn: Bahçe, Teras, Salon) ve bu bölgelere masa (Örn: Masa 1, Masa 2) ekleyebilir.
- Mevcut masaların isimleri, kapasiteleri veya bulundukları bölgeler değiştirilebilir.
- Boş masalar yeşil, dolu (sipariş bekleyen veya hesabı olan) masalar farklı renklerde listelenir.

### 3.2. Masa Taşıma (Table Moving)
- Oturan bir masa, başka bir boş veya dolu masaya aktarılabilir (`moveTable` fonksiyonu).
- Masa taşındığında; eski masadaki sipariş grupları (`orderGroups`), önceden ödenmiş ara ödemeler (`payments`) ve o masaya özel yapılmış özel fiyatlandırmalar (`customPrices`) hedef masaya aktarılır.
- Aktarılan eski masa otomatik olarak temizlenir (Boş statüsüne çekilir).

## 4. Sipariş Sistemi (Order Management)

### 4.1. Sipariş Ekleme ve Tekil Satır Düzeni
- Masaya eklenen her ürün için "Benzersiz bir Sipariş ID'si" (`orderItemId`) oluşturulur.
- Garson menüden 3 kez "Coca Cola" seçtiğinde, ekranda tek satırda "3x Coca Cola" yazmak yerine; üç ayrı bağımsız "1x Coca Cola" satırı oluşur. Bu sistem, parça parça iptal etmeyi veya müşteriler arasında hesabı ayırmayı kolaylaştırmak için özellikle tasarlanmıştır.
- Ekleme/çıkarma işlemleri Numpad pencereleri aracılığıyla yapılabilir. Numpad'de hızlı silme (DEL) ve tamamen temizleme (C) butonları yer alır.

### 4.2. Özel Fiyatlandırma (Custom Price)
- Bir ürünün menü fiyatı 100 TL olsa bile, Yönetici dilerse sadece o masaya özel olarak o ürünün fiyatını 50 TL olarak güncelleyebilir.
- Bu özel fiyat (`customPrices`), masa tamamen kapanana (checkout) kadar geçerliliğini korur ve `tables.json`'a işlenerek kalıcı hale getirilir. Masa kapandığında eski fiyatına geri döner.

## 5. Ödeme ve Kasa (Checkout & Payments)

### 5.1. Parçalı ve Tam Ödeme
- Ödemeler Kredi Kartı, Nakit veya İndirim olarak alınabilir.
- Hesap tamamen kapatılmadan ara ödemeler (Örn: masadan kalkan bir kişinin kendi payını ödemesi) girilebilir. 

### 5.2. İndirim Mantığı (Discount Logic)
- **Aşım Engeli:** Girilen indirim miktarı, masanın ödenmemiş kalan tutarından yüksek olamaz. Yüksek girildiğinde sistem hata mesajı verir.
- **Tam Hesap Kapatma Onayı:** Eğer girilen indirim miktarı, masanın ödenmemiş tüm borcuna eşitse (yani hesabı sıfırlıyorsa), sistem özel bir pop-up çıkararak *"Emin misiniz? Geri kalan tüm tutarı indirim olarak girdiğiniz için masa tamamen kapatılacaktır"* uyarısı yapar. Kullanıcı onaylarsa masa kapatılır.

### 5.3. Checkout (Masayı Kapatma)
- Kalan miktar 0'a ulaştığında masa otomatik olarak `checkoutTable` komutuna düşer.
- Masa kapanırken `activeSessionId`, `payments`, `orderGroups` ve `customPrices` verileri sıfırlanır. Masanın geçmişi kalıcı veri tabanına (`closed_tables`) gönderilir.

## 6. Yazdırma Sistemi (Printing System)

### 6.1. PDF Tabanlı Grafiksel Yazdırma
- Klasik ESC/POS RAW text tabanlı yazdırma yerine modern `pdf` ve `printing` kütüphaneleri kullanılır. 
- Mutfak (MUTFAK) ve Kasa (KASA) olmak üzere iki ana hedef desteklenir.
- Yazıcı adları aranırken `.toUpperCase().contains()` fonksiyonu kullanılarak Windows spooler üzerinde oluşabilecek boşluk veya `(Kopya 1)` gibi eklere karşı dayanıklı bir tespit mantığı güdülür.

### 6.2. Mutfak ve Kasa Çıktısı Farkı
- **Mutfak:** Sadece daha önce mutfağa yazdırılmamış (`!isPrintedToKitchen`) yeni eklenen ürünler mutfak fişine gönderilir. Yazdırılan ürünler işaretlenir.
- **Kasa:** Masanın sahip olduğu tüm ürünler alt alta dökülür ve en alta genel toplam eklenir.

### 6.3. Türkçe Karakter Desteği ve Ses Ayarı
- Çıktılardaki Türkçe karakter problemlerini (Özellikle İ, Ş, Ğ gibi) çözebilmek adına PDF yapısının içine **Latin Extended** desteği bulunan 515 KB'lık eksiksiz `Roboto-Regular.ttf` Google fontu statik olarak gömülmüştür.
- Çıktı anında yazıcının (Buzzer) ötmesi (dıt dıt sesi) tamamen Windows yazıcı sürücüsü (Driver) üzerinden yönetilmektedir. "Device Settings -> Cash Drawer / Buzzer" ayarının aktif edilmesi gerekmektedir.

## 7. Yönetim Paneli ve Dashboard

### 7.1. Anlık Saatlik Ciro Karşılaştırma Grafiği
- Yöneticinin ilk karşısına çıkan "Genel Durum" ekranında "Bugün vs Dün" olarak anlık ciroları saat saat karşılaştıran canlı bir grafik (`fl_chart` kütüphanesi) bulunur.
- Bu grafik, dar ve küçük ekranlı bilgisayarlarda formunu kaybetmemesi ve ezilmemesi için **600 piksel** sabit yüksekliğe oturtulmuş ve tüm sayfa `SingleChildScrollView` (Aşağı kaydırılabilir) olarak tasarlanmıştır.

### 7.2. İstatistikler
- Açık masa sayısı, Boş masa sayısı ve aktif sipariş toplamı saniyelik güncellenir.
- "Günlük Özet" sayfası altında o günkü Kredi Kartı ve Nakit oranları yüzdesel olarak sunulur.

## 8. Teknik Notlar ve Bağımlılıklar (Dependencies)
- **Tasarım Dili:** Özel HSL tabanlı, glassmorphism içeren, Tailwind vari ancak özelleştirilmiş Flutter widget'larıyla modern, estetik bir UI (AppTheme) kurgulanmıştır.
- **Veri Tabanı:** `sqflite_common_ffi` kullanılarak Windows desktop ortamında native SQLite desteği sağlanmaktadır.
- **State Management:** Klasik `ChangeNotifier` ve `Provider` yapısına benzer, `RestaurantController` üzerinden `notifyListeners()` aracılığıyla projenin state'i yürütülmektedir.
