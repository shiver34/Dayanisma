import 'package:flutter/material.dart';
import 'auth_controller.dart';
import '../categories/categories_screen.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  bool _obscure = true;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();

  // Login
  final _userFieldController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  // Register
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _gender;

  bool _passwordValid = false;
  String? _passwordError;

  final List<String> allowedDomains = [
    'gmail.com',
    'hotmail.com',
    'outlook.com',
    'yahoo.com',
    '.edu.tr',
  ];

  final _phoneFormatter = MaskTextInputFormatter(
    mask: '0(5##) ### ## ##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    String result;

    if (!_formKey.currentState!.validate()) {
      setState(() => _isLoading = false);
      return;
    }

    if (isLogin) {
      result = await AuthController.login(
        _userFieldController.text.trim(),
        _loginPasswordController.text,
      );
    } else {
      final age = int.tryParse(_ageController.text.trim());
      if (!_passwordValid || age == null || _gender == null) {
        result = 'Lütfen tüm alanları doğru doldurun.';
      } else {
        result = await AuthController.register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          profileFields: {
            'first_name': _firstNameController.text.trim(),
            'last_name': _lastNameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'age': age,
            'gender': _gender,
          },
        );
      }
    }

    setState(() => _isLoading = false);

    if (result == 'success') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CategoriesScreen()),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result)));
    }
  }

  void _onPasswordChanged(String v) {
    final password = v.trim();
    final valid =
        password.length >= 6 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'\d').hasMatch(password) &&
        RegExp(r'[,\.\?\*\#]').hasMatch(password);

    setState(() {
      _passwordValid = valid;
      _passwordError = valid ? null : 'Şifre kurallarına uymuyor';
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF2C5282);
    final bg = const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 12),

                /// TOP BAR
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: primary.withOpacity(.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.health_and_safety,
                        color: Color(0xFF2C5282),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                /// IMAGE
                AspectRatio(
                  aspectRatio: 2 / 1,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      image: const DecorationImage(
                        image: NetworkImage(
                          'https://lh3.googleusercontent.com/aida-public/AB6AXuDECK1gwyyTjItD7hl_m2yIOgV5HKnXmiFaeSm5vgcHTbz5ybQYbiI4XYV6lZs-A8kcm1m8VB97UyAFn2CF9GloY0Tmx9CWu_W-4HpyDSndQD09EpaJwOwY5n3zfRtXurSDnQrspv3Vez36eGR2oW9GRCR_DZxqXfOXjJbTtuULQ_OvwHGgsCrVmugoO3zi_dC-ZV9pE4vfAKfjakFIaQE08a0goAQB6GEmxTQYR9cmet8auJhnHAlYcBZ3H5tQx15Jrik1TW9UT8k',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                Text(
                  isLogin ? 'Hoş Geldiniz' : 'Kayıt Ol',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                /// FORM
                if (isLogin) ...[
                  _input(
                    controller: _userFieldController,
                    hint: 'E-posta veya Telefon',
                    icon: Icons.mail,
                  ),
                  const SizedBox(height: 16),
                  _input(
                    controller: _loginPasswordController,
                    hint: 'Şifre',
                    icon: Icons.lock,
                    obscure: _obscure,
                    suffix: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 4),

                  // İsim - Soyisim
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _firstNameController,
                          decoration: InputDecoration(
                            labelText: 'İsim',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Gerekli';
                            if (!RegExp(
                              r'^[a-zA-ZğüşöçİĞÜŞÖÇ\s]+$',
                            ).hasMatch(v)) {
                              return 'Sadece harf';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _lastNameController,
                          decoration: InputDecoration(
                            labelText: 'Soyisim',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Gerekli';
                            if (!RegExp(
                              r'^[a-zA-ZğüşöçİĞÜŞÖÇ\s]+$',
                            ).hasMatch(v)) {
                              return 'Sadece harf';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Telefon
                  TextFormField(
                    controller: _phoneController,
                    inputFormatters: [_phoneFormatter],
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Telefon',
                      hintText: '5XX XXX XX XX',
                      prefixIcon: const Icon(Icons.phone_iphone),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (v) {
                      final digits = _phoneFormatter.getUnmaskedText();
                      if (digits.length != 9) return 'Geçerli telefon girin';
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'E-posta',
                      hintText: 'ornek@mail.com',
                      prefixIcon: const Icon(Icons.mail),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      final email = value.trim();
                      final emailRegex = RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      );
                      if (!emailRegex.hasMatch(email))
                        return 'Geçersiz e-posta';
                      final domain = email.split('@').last.toLowerCase();
                      if (!allowedDomains.contains(domain)) {
                        return 'Desteklenmeyen domain';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Yaş + Cinsiyet
                  Row(
                    children: [
                      // YAŞ
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Yaş',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (v) {
                            final n = int.tryParse(v ?? '');
                            if (n == null || n <= 0) return 'Geçerli yaş';
                            return null;
                          },
                        ),
                      ),

                      const SizedBox(width: 12),

                      // CİNSİYET
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 4, bottom: 6),
                              child: Text(
                                'Cinsiyet',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            DropdownButtonFormField<String>(
                              value: _gender,
                              isExpanded: true, // 🔥 BU ÇOK ÖNEMLİ
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'male',
                                  child: Text('Erkek'),
                                ),
                                DropdownMenuItem(
                                  value: 'female',
                                  child: Text('Kadın'),
                                ),
                                DropdownMenuItem(
                                  value: 'unknown',
                                  child: Text('Belirtmek istemiyorum'),
                                ),
                              ],
                              onChanged: (v) => setState(() => _gender = v),
                              validator: (v) {
                                if (v == null) return 'Cinsiyet seçiniz';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Şifre
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    onChanged: _onPasswordChanged,
                    decoration: InputDecoration(
                      labelText: 'Şifre',
                      errorText: _passwordError,
                      prefixIcon: const Icon(Icons.lock),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  LinearProgressIndicator(
                    value: _passwordValid ? 1.0 : 0.3,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _passwordValid ? Colors.green : Colors.red,
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                _isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _submit,
                          child: Text(
                            isLogin ? 'Giriş Yap' : 'Kayıt Ol',
                            style: const TextStyle(fontSize: 18,color: Colors.white),
                          ),
                        ),
                      ),

                const SizedBox(height: 16),

                TextButton(
                  onPressed: () => setState(() => isLogin = !isLogin),
                  child: Text(
                    isLogin
                        ? 'Hesabın yok mu? Kayıt Ol'
                        : 'Zaten hesabın var mı? Giriş Yap',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    bool obscure = false,
    Widget? suffix,
    String? error,
    TextInputType keyboard = TextInputType.text,
    MaskTextInputFormatter? formatter,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      inputFormatters: formatter != null ? [formatter] : null,
      onChanged: onChanged,
      decoration: InputDecoration(
        errorText: error,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon) : null,
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
