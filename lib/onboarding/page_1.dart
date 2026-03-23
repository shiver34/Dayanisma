import 'dart:ui';
import 'package:flutter/material.dart';

class Page1 extends StatelessWidget {
  final VoidCallback onNext;
  const Page1({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onNext,
      child: Scaffold(
        body: Stack(
          children: [
            /// 🔹 ARKA PLAN GÖRSEL (ÇOK DAHA SİLİK)
            Positioned.fill(
              child: Opacity(
                opacity: 0.55, // ← YATAY AKIŞ HİSSİNİ KESER
                child: Image.network(
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuBG7u7fHkalXdJa4be6aHPBJSk2PcDJPzy2yMnuS6Jc5BESyYDAW3p3sSdKij8dMbLPsyJGhR8xWBNMCY6yJVy_WpFmtl8w8UtCvs0yRD0iHbknUWsM5xuMhv1q4x0059pfL_eWKtU4ASiQ6oLUXDBbRlB6_PlLdnE3m7FND0yHaPYJ3RZDsBqzdsap-sZncqzy09l8BFDDmdn1tzgjhGZobnzgECHYsFLfRCloPkRMy0a6jEB47j-gvteF9wB9v5BIMOEPopuUvVs',
                  fit: BoxFit.cover,
                ),
              ),
            ),

            /// 🔹 HAFİF BLUR (GENEL ATMOSFER)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(color: Colors.transparent),
              ),
            ),

            /// 🔹 ASIL İŞİ YAPAN GRADIENT (YUKARIDAN AŞAĞIYA)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFB7CED6), // üst yumuşak mavi
                      Color(0xFFDDECEF),
                      Color(0xFFF1F5F7),
                      Colors.white,      // alt TAM BEYAZ
                    ],
                    stops: [0.0, 0.35, 0.65, 1.0],
                  ),
                ),
              ),
            ),

            /// 🔹 ÜST ORTA İKON
            Positioned(
              top: h * 0.22,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.diversity_1,
                    color: Color(0xFF137FEC),
                    size: 30,
                  ),
                ),
              ),
            ),

            /// 🔹 METİN (AKIŞIN İÇİNDE)
            Positioned(
              left: 24,
              right: 24,
              bottom: h * 0.22,
              child: Column(
                children: const [
                  Text(
                    'Siz kendinizi daha iyi\nhissedin diye\nburadayız',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      height: 1.35,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Benzer deneyimleri paylaşan insanlarla tanışın,\ndestek alın ve yalnız olmadığınızı hissedin.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.55,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),

            /// 🔹 ALT SABİT (DOT + HINT)
            Positioned(
              left: 0,
              right: 0,
              bottom: 110,
              child: Column(
                children: const [
                  _Dots(activeIndex: 0),
                  SizedBox(height: 12),
                  Opacity(
                    opacity: 0.6,
                    child: Text(
                      'Devam etmek için dokunun',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
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

/// 🔹 DOTLAR
class _Dots extends StatelessWidget {
  final int activeIndex;
  const _Dots({required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    Widget dot(bool active) => AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: 6,
          width: active ? 22 : 6,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF137FEC) : const Color(0xFFCBD5E1),
            borderRadius: BorderRadius.circular(999),
          ),
        );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        dot(activeIndex == 0),
        dot(activeIndex == 1),
        dot(activeIndex == 2),
      ],
    );
  }
}
