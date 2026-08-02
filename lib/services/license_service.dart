import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../config/firebase_config.dart';

class LicenseException implements Exception {
  final String message;
  LicenseException(this.message);
  @override
  String toString() => message;
}

class LicenseInfo {
  final bool isActive;
  final DateTime expireDate;
  final List<String> allowedMachines;
  final int maxTablets;

  LicenseInfo({
    required this.isActive,
    required this.expireDate,
    required this.allowedMachines,
    required this.maxTablets,
  });
}

class LicenseService {
  static final LicenseService instance = LicenseService._init();
  LicenseService._init();

  String? _machineUuid;
  
  // 7 Gün offline limiti
  static const int _offlineDaysLimit = 7;
  
  // Basit şifreleme anahtarı (Korsan koruması için XOR)
  final String _xorKey = "A7b9Q2xZ"; 

  Future<String> getMachineUuid() async {
    if (_machineUuid != null) return _machineUuid!;
    
    try {
      if (Platform.isWindows) {
        final result = await Process.run('powershell', [
          '-Command', 
          'Get-CimInstance -Class Win32_ComputerSystemProduct | Select-Object -ExpandProperty UUID'
        ]);
        _machineUuid = result.stdout.toString().trim();
      } else {
        // Fallback for non-Windows (if ever needed)
        _machineUuid = "UNKNOWN-MACHINE";
      }
    } catch (e) {
      _machineUuid = "ERROR-MACHINE";
    }
    
    return _machineUuid!;
  }

  // Firebase Auth ile giriş yapıp token alır
  Future<String> _getAuthToken(String email, String password) async {
    final response = await http.post(
      Uri.parse(FirebaseConfig.authUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
        'returnSecureToken': true,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['idToken'];
    } else {
      final data = json.decode(response.body);
      final error = data['error']?['message'] ?? 'Bilinmeyen Hata';
      throw LicenseException('Kimlik doğrulama başarısız: $error');
    }
  }

  // Firestore'dan lisans belgesini çeker
  Future<LicenseInfo> _fetchLicense(String token, String email) async {
    // E-posta adresini güvenli bir ID'ye çeviriyoruz (Örn: admin@test.com -> admin_test_com)
    final safeDocId = email.replaceAll('@', '_').replaceAll('.', '_');
    final url = '${FirebaseConfig.firestoreUrl}/licenses/$safeDocId';

    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final fields = data['fields'];
      
      if (fields == null) {
        throw LicenseException('Lisans kaydı bulunamadı.');
      }

      final isActive = fields['isActive']?['booleanValue'] ?? false;
      final expireDateStr = fields['expireDate']?['timestampValue'];
      final maxTablets = int.tryParse(fields['maxTablets']?['integerValue'] ?? '1') ?? 1;
      
      List<String> allowedMachines = [];
      if (fields['allowedMachines'] != null && fields['allowedMachines']['arrayValue'] != null && fields['allowedMachines']['arrayValue']['values'] != null) {
        final values = fields['allowedMachines']['arrayValue']['values'] as List;
        allowedMachines = values.map((e) => e['stringValue'].toString()).toList();
      }

      if (expireDateStr == null) {
        throw LicenseException('Lisans bitiş tarihi geçersiz.');
      }

      return LicenseInfo(
        isActive: isActive,
        expireDate: DateTime.parse(expireDateStr),
        allowedMachines: allowedMachines,
        maxTablets: maxTablets,
      );
    } else if (response.statusCode == 404) {
      throw LicenseException('Lisans kaydı (Firestore) henüz oluşturulmamış.');
    } else {
      throw LicenseException('Lisans kontrolü başarısız: Sunucu Hatası (${response.statusCode})');
    }
  }

  // İlk giren makineyi kaydetme isteği (Firestore REST API ile)
  Future<void> _registerMachine(String token, String email, String uuid, LicenseInfo currentLicense) async {
    final safeDocId = email.replaceAll('@', '_').replaceAll('.', '_');
    final url = '${FirebaseConfig.firestoreUrl}/licenses/$safeDocId?updateMask.fieldPaths=allowedMachines';

    // Mevcut makinelere yenisini ekle
    final updatedMachines = List<String>.from(currentLicense.allowedMachines)..add(uuid);
    
    final body = {
      'fields': {
        'allowedMachines': {
          'arrayValue': {
            'values': updatedMachines.map((m) => {'stringValue': m}).toList()
          }
        }
      }
    };

    final response = await http.patch(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode != 200) {
      throw LicenseException('Makine kaydı başarısız oldu. Lütfen internet bağlantınızı kontrol edin.');
    }
  }

  // Offline lisans dosyasını şifreler (Tam korsan koruması)
  String _encrypt(String text) {
    List<int> bytes = utf8.encode(text);
    List<int> xorBytes = [];
    for (int i = 0; i < bytes.length; i++) {
      xorBytes.add(bytes[i] ^ _xorKey.codeUnitAt(i % _xorKey.length));
    }
    return base64.encode(xorBytes);
  }

  String _decrypt(String encryptedBase64) {
    try {
      List<int> bytes = base64.decode(encryptedBase64);
      List<int> xorBytes = [];
      for (int i = 0; i < bytes.length; i++) {
        xorBytes.add(bytes[i] ^ _xorKey.codeUnitAt(i % _xorKey.length));
      }
      return utf8.decode(xorBytes);
    } catch (e) {
      return "";
    }
  }

  Future<File> get _offlineFile async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String path = p.join(appDocDir.path, 'KarPos', 'sys_cache.bin');
    return File(path);
  }

  Future<void> _saveOfflineCache(LicenseInfo info) async {
    final file = await _offlineFile;
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    
    final payload = {
      'expireDate': info.expireDate.toIso8601String(),
      'maxTablets': info.maxTablets,
      'lastValidationDate': DateTime.now().toIso8601String(),
    };
    
    final encryptedData = _encrypt(json.encode(payload));
    await file.writeAsString(encryptedData);
  }

  // Offline kontrolü
  Future<LicenseInfo?> _checkOfflineCache() async {
    final file = await _offlineFile;
    if (!await file.exists()) return null;

    final encryptedData = await file.readAsString();
    final decryptedData = _decrypt(encryptedData);
    
    if (decryptedData.isEmpty) {
      return null; // Dosya bozuk veya hile yapılmış
    }

    try {
      final data = json.decode(decryptedData);
      final expireDate = DateTime.parse(data['expireDate']);
      final lastValidationDate = DateTime.parse(data['lastValidationDate']);
      final maxTablets = data['maxTablets'] ?? 1;
      
      final now = DateTime.now();

      // Hile Koruması: Bilgisayar saati geri alınmışsa!
      if (now.isBefore(lastValidationDate)) {
        throw LicenseException('Sistem saati ile oynandığı tespit edildi. Lütfen internete bağlanıp tekrar deneyin.');
      }

      // 7 gün kuralı
      final difference = now.difference(lastValidationDate).inDays;
      if (difference > _offlineDaysLimit) {
        throw LicenseException('Çevrimdışı kullanım süresi ($difference gün) doldu. Lütfen internete bağlanın.');
      }

      if (now.isAfter(expireDate)) {
        throw LicenseException('Lisans süreniz dolmuştur. Lütfen sistem yöneticisi ile iletişime geçin.');
      }

      return LicenseInfo(
        isActive: true,
        expireDate: expireDate,
        allowedMachines: [], // Offline modda donanım UUID zaten ilk başta kontrol edildi
        maxTablets: maxTablets,
      );
    } catch (e) {
      if (e is LicenseException) throw e;
      return null;
    }
  }

  // Ana giriş fonksiyonu
  Future<LicenseInfo> validateLicense(String email, String password) async {
    if (FirebaseConfig.webApiKey == 'BURAYA_WEB_API_KEY_GELECEK') {
      throw LicenseException('Lütfen firebase_config.dart dosyasındaki API bilgilerini doldurun.');
    }

    try {
      // 1. Online Doğrulama Dene
      final token = await _getAuthToken(email, password);
      final license = await _fetchLicense(token, email);

      if (!license.isActive) {
        throw LicenseException('Lisansınız aktif değil veya askıya alınmış.');
      }

      if (DateTime.now().isAfter(license.expireDate)) {
        throw LicenseException('Lisans süreniz dolmuştur.');
      }

      final uuid = await getMachineUuid();

      // Donanım kilit kontrolü
      if (license.allowedMachines.isEmpty) {
        // Makine kayıtlı değil, otomatik kaydet
        await _registerMachine(token, email, uuid, license);
        license.allowedMachines.add(uuid);
      } else if (!license.allowedMachines.contains(uuid)) {
        throw LicenseException('Bu bilgisayar kayıtlı cihazlar listesinde yok. Lisans başka bir cihazda kullanılıyor.');
      }

      // Her şey başarılı, offline cache güncelle
      await _saveOfflineCache(license);

      return license;
    } catch (e) {
      // Eğer hata "İnternet Yok" ile alakalıysa offline cache kontrol et
      if (e is SocketException || e.toString().contains('Failed host lookup')) {
        final offlineLicense = await _checkOfflineCache();
        if (offlineLicense != null) {
          return offlineLicense;
        } else {
          throw LicenseException('İnternet bağlantısı yok ve çevrimdışı lisans bulunamadı. Lütfen internete bağlanın.');
        }
      }
      
      // Şifre yanlışsa, lisans dolmuşsa vs. direkt fırlat
      if (e is LicenseException) rethrow;
      
      // Başka bilinmeyen hata
      throw LicenseException('Lisans kontrolü sırasında bir hata oluştu: ${e.toString()}');
    }
  }
}
