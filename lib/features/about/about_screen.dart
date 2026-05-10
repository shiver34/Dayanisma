// lib/features/about/about_screen.dart
import 'package:flutter/material.dart';
import '../../widgets/app_drawer.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      endDrawer: const AppDrawer(),

      // ---------------- APP BAR ----------------
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF335C85)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Hakkımızda',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Color(0xFF335C85)),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),

      // ---------------- BODY ----------------
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------- HERO ----------------
            Container(
              height: 240,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuBKRmSpq0pyJvUGYaGOnWDIWQ3E4s9yJAuy4dyCfwhEXvwiWOYe0727MgXDl4YCvz-HD8S86GB-xJhbsd_2FFgb94q_qe7CjRA7SUR_VGgn9b0aw16gWxOrY5we4ZI1IwtStFqMFBNv1nAgezjJjbJCpPiZ8JVkJ1STFK8cGXG7k4vFGVKsoIZ6zTvp73PQmuvrJJsxCnamEsMADqNCj8pDRDYjCOzTxAmQxAN73fnjlm5e-FyxVd9Xbm3rECohopiy3EdKKD7n6ZM',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(20),
                alignment: Alignment.bottomLeft,
                child: const Text(
                  'Birlikte Daha Güçlüyüz',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ---------------- CONTENT ----------------
            _sectionTitle('Yalnız Değilsiniz.'),
            _paragraph(
              'Bu platform, benzer sağlık sorunları yaşayan bireylerin bir araya gelerek deneyimlerini paylaşabileceği, '
              'birbirine destek olabileceği güvenli bir alandır. Amacımız, kimsenin bu yolculukta yalnız hissetmemesini sağlamaktır.',
            ),

            _subTitle('Misyonumuz'),
            _paragraph(
              'Sağlık yolculuğu zorlu olabilir. Biz, empatiye dayalı ve bilgi kirliliğinden uzak bir topluluk oluşturarak '
              'bu süreci daha katlanabilir hale getirmeyi hedefliyoruz.',
            ),

            _infoCard(
              icon: Icons.security,
              title: 'Güvenlik ve Gizlilik',
              text:
                  'Paylaştığınız tüm bilgiler en yüksek güvenlik standartlarıyla korunur. '
                  'Anonim kalma hakkınıza saygı duyarız.',
            ),

            _subTitle('Topluluk Değerleri'),
            _bullet('Karşılıklı saygı ve anlayış'),
            _bullet('Tıbbi tavsiye yerine deneyim paylaşımı'),
            _bullet('Her hikâye değerlidir'),

            const SizedBox(height: 32),

            // ---------------- FOOTER ----------------
            const Divider(),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: const [
                  Text(
                    'Bize Ulaşın',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Versiyon 2.1.0',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ---------------- HELPERS ----------------

  static Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color(0xFF335C85),
          ),
        ),
      );

  static Widget _subTitle(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
      );

  static Widget _paragraph(String text) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            height: 1.6,
            color: Color(0xFF4B5563),
          ),
        ),
      );

  static Widget _infoCard({
    required IconData icon,
    required String title,
    required String text,
  }) =>
      Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF10B981), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF10B981)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
          ],
        ),
      );

  static Widget _bullet(String text) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        child: Row(
          children: [
            const Icon(Icons.check_circle,
                size: 18, color: Color(0xFF10B981)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ],
        ),
      );
}
