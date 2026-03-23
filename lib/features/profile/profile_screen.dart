// lib/features/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _client = Supabase.instance.client;

  String? firstName;
  String? lastName;
  String? phone;
  int? age;
  String? gender;

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final userId = _client.auth.currentUser!.id;

      final data = await _client
          .from('profiles')
          .select('first_name, last_name, phone, age, gender')
          .eq('id', userId)
          .single();

      final rawGender = data['gender'];

      setState(() {
        firstName = data['first_name'];
        lastName = data['last_name'];
        phone = data['phone'];
        age = data['age'];

        // 🔥 DÖNÜŞÜM BURADA
        if (rawGender == 'Erkek') {
          gender = 'male';
        } else if (rawGender == 'Kadın') {
          gender = 'female';
        } else if (rawGender == 'Belirtmek istemiyorum') {
          gender = 'unknown';
        } else {
          gender = rawGender; // zaten male / female ise
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Profil yüklenirken hata: $e';
        _isLoading = false;
      });
    }
  }

  String get fullName {
    final f = firstName ?? '';
    final l = lastName ?? '';
    return (f + ' ' + l).trim();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(body: Center(child: Text(_error!)));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Profilim', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          children: [
            const SizedBox(height: 24),

            // ---------------- AVATAR ----------------
            Stack(
              children: [
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade300,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.person, size: 56),
                ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF3E5C76),
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ---------------- NAME ----------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                fullName.isNotEmpty ? fullName : 'Kullanıcı',
                textAlign: TextAlign.center,
                softWrap: true,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ---------------- BADGE ----------------
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, size: 16, color: Color(0xFF10B981)),
                  SizedBox(width: 6),
                  Text(
                    'Onaylı Üye',
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ---------------- INFO CARD ----------------
            _InfoCard(
              icon: Icons.call,
              title: 'Telefon Numarası',
              value: phone ?? '-',
            ),
            _InfoCard(
              icon: Icons.cake,
              title: 'Yaş',
              value: age != null ? age.toString() : '-',
            ),
            _InfoCard(
              icon: Icons.person,
              title: 'Cinsiyet',
              value: gender ?? '-',
            ),

            const SizedBox(height: 24),

            // ---------------- BUTTONS ----------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      final updated = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditProfileScreen(),
                        ),
                      );

                      if (updated == true) {
                        _loadProfile(); // geri dönünce profil yenilensin
                      }
                    },

                    icon: const Icon(Icons.edit, color: Colors.white),
                    label: const Text(
                      'Bilgileri Düzenle',
                      style: TextStyle(color: Color.fromARGB(255, 250, 250, 250),
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                      
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      backgroundColor: const Color(0xFF3E5C76),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () async {
                      await _client.auth.signOut();
                      if (context.mounted) {
                        Navigator.of(
                          context,
                        ).pushNamedAndRemoveUntil('/', (_) => false);
                      }
                    },
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    label: const Text(
                      'Çıkış Yap',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- INFO ROW WIDGET ----------------
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.grey),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
