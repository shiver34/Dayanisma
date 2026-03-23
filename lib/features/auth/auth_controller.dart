import 'package:supabase_flutter/supabase_flutter.dart';

class AuthController {
  static final _client = Supabase.instance.client;

  /// KAYIT OLMA
  static Future<String> register({
    String? email,
    String? phone,
    required String password,
    required Map<String, dynamic> profileFields,
  }) async {
    // Şifre kontrolü
    final passwordValid = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[,.?*#]).{6,}$',
    ).hasMatch(password);

    if (!passwordValid) {
      return 'Şifre en az 1 büyük harf, 1 küçük harf, 1 sayı ve (, . ? * #) içermeli ve en az 6 karakter olmalı.';
    }

    try {
      final res = await _client.auth.signUp(email: email!, password: password);

      final user = res.user;
      if (user == null) {
        return 'Kayıt yapılamadı.';
      }

      await _client.from('profiles').insert({
        'id': user.id,
        'first_name': profileFields['first_name'],
        'last_name': profileFields['last_name'],
        'phone': profileFields['phone'],
        'age': profileFields['age'],
        'gender': profileFields['gender'],
      });

      return 'success';
    } on AuthException catch (e) {
      return 'Hata: ${e.message}';
    } catch (e) {
      return 'Hata: $e';
    }
  }

  /// GİRİŞ — kullanıcı e‑posta veya telefon yazabilir
  static Future<String> login(String userInput, String password) async {
    try {
      await _client.auth.signInWithPassword(
        email: userInput,
        password: password,
      );

      return 'success';
    } on AuthException catch (e) {
      return 'Hata: ${e.message}';
    } catch (e) {
      return 'Hata: $e';
    }
  }
}
