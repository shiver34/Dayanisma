import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _client = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();

  String? _gender;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final userId = _client.auth.currentUser!.id;

    final data = await _client
        .from('profiles')
        .select('first_name, last_name, phone, age, gender')
        .eq('id', userId)
        .single();

    _firstNameController.text = data['first_name'] ?? '';
    _lastNameController.text = data['last_name'] ?? '';
    _phoneController.text = data['phone'] ?? '';
    _ageController.text = data['age']?.toString() ?? '';
    final rawGender = data['gender'];

    if (rawGender == 'Erkek') {
      _gender = 'male';
    } else if (rawGender == 'Kadın') {
      _gender = 'female';
    } else if (rawGender == 'Belirtmek istemiyorum') {
      _gender = 'unknown';
    } else {
      _gender = rawGender; // zaten male/female/unknown ise
    }

    setState(() {});

    setState(() {});
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final userId = _client.auth.currentUser!.id;

    await _client
        .from('profiles')
        .update({
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'age': int.tryParse(_ageController.text),
          'gender': _gender,
        })
        .eq('id', userId);

    if (context.mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bilgileri Düzenle'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _input(_firstNameController, 'Ad'),
              _input(_lastNameController, 'Soyad'),
              _input(
                _phoneController,
                'Telefon',
                keyboard: TextInputType.phone,
              ),
              _input(
                _ageController,
                'Yaş',
                keyboard: TextInputType.number,
                validator: (v) {
                  final age = int.tryParse(v ?? '');
                  if (age == null || age < 0 || age > 120) {
                    return 'Geçerli bir yaş gir';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _gender,
                decoration: const InputDecoration(
                  labelText: 'Cinsiyet',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Erkek')),
                  DropdownMenuItem(value: 'female', child: Text('Kadın')),
                  DropdownMenuItem(
                    value: 'unknown',
                    child: Text('Belirtmek istemiyorum'),
                  ),
                ],
                onChanged: (v) => setState(() => _gender = v),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Kaydet'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _input(
    TextEditingController c,
    String label, {
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: c,
        keyboardType: keyboard,
        validator:
            validator ??
            (v) => v == null || v.isEmpty ? 'Boş bırakılamaz' : null,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
