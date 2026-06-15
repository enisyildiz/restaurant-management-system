# Restoran Yönetim Sistemi - Terminal ve Sürüm Bilgileri

## Sürüm Bilgileri
* **Flutter SDK:** 3.7.12 *(Windows 7 uyumluluğu için kilitli sürüm)*
* **Dart SDK:** 2.19.x *(Flutter 3.7 ile birlikte gelen kararlı sürüm)*
* **Visual Studio:** 2026 (Sürüm 18) - *İçerisinde "MSVC v142 - VS 2019 C++ x64/x86" aracı kurulu olmalıdır.*
* **Hedef Platform:** Windows *(Windows 7 POSSlim ve x64 mimarili sistemler)*

> **⚠️ KRİTİK BİLGİ:**
> Bu projede global/güncel Flutter komutları veya VS Code Play (F5) butonu **kullanılmamalıdır**. İşlemler sadece aşağıdaki terminal komutlarıyla, eski Flutter motoru hedef gösterilerek yapılmalıdır.

---

## Terminal Komutları

### 1. Hatalı CMake ve Build Klasörünü Fiziksel Olarak Silme
*Özellikle derleyici arama hatalarında kullanılır.*
```powershell
Remove-Item -Recurse -Force build
```

### 2. Eski Flutter Derleme Dosyalarını Temizleme
```powershell
C:\flutter_3_7_12\bin\flutter.bat clean
```

### 3. Sabitlenmiş (Kilitli) Paketleri İndirme
*pubspec.yaml güncellendiğinde kullanılır.*
```powershell
C:\flutter_3_7_12\bin\flutter.bat pub get
```

### 4. Debug (Geliştirici) Modunda Başlatma
*Geliştirme yaparken veya hata detaylarını terminalde görmek için kullanılır.*
```powershell
C:\flutter_3_7_12\bin\flutter.bat run -d windows
```

### 5. Release (Canlı) Ortam İçin .exe Derleme
*POS cihazına atılacak nihai dosyaları oluşturur.*
```powershell
C:\flutter_3_7_12\bin\flutter.bat build windows --release
```