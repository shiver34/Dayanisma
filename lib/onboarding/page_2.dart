import 'package:flutter/material.dart';

class Page2 extends StatelessWidget {
  final VoidCallback onNext;
  const Page2({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onNext,
      child: _OnboardShell(
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuBn5r0iX9iOMXMHKum1sJ2nsLAT_SfQJ3HkaLx_U1uI64Jb66Bb_MshgPKG_xHBl-wCqSRGBoxG8RowKMrDBspXxkVsWkcWlqJ01NAxtAx-K7a1DKEeIU3Zh7HjOZv0h47FgCQ-znD0XOru6jF3qQEXzdl6vMSrvgkkmUgoUCqov9mVkcHAf3ndbp1whGSZlzwOim6GXgeEbNbB2ZrMje5v267G3W_xZIBTjHoMRSLhXumf2lCScGGCgKCCg8uaa_CEBIf2Hjm22ko',
        titleWidget: RichText(
          textAlign: TextAlign.center,
          text: const TextSpan(
            style: TextStyle(
              fontSize: 22,
              height: 1.35,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
            children: [
              TextSpan(text: 'Bu süreçte '),
              TextSpan(
                text: 'yalnız\nkalmayın',
                style: TextStyle(color: Color(0xFF137FEC)),
              ),
              TextSpan(text: ' diye varız'),
            ],
          ),
        ),
        subtitle: 'Sizinle aynı yoldan geçen binlerce kişi var.',
        showButton: false,
        activeDot: 1,
      ),
    );
  }
}

/// ✅ ORTAK ŞABLON
class _OnboardShell extends StatelessWidget {
  final String imageUrl;
  final Widget titleWidget;
  final String subtitle;
  final bool showButton;
  final int activeDot;

  const _OnboardShell({
    required this.imageUrl,
    required this.titleWidget,
    required this.subtitle,
    required this.showButton,
    required this.activeDot,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.58,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    titleWidget,
                    const SizedBox(height: 12),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 22),
                    _Dots(activeIndex: activeDot),
                    const SizedBox(height: 10),
                    const Opacity(
                      opacity: 0.6,
                      child: Text(
                        'Devam etmek için dokunun',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final int activeIndex;
  const _Dots({required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    Widget dot(bool active) => AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: 8,
          width: active ? 28 : 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF13ECDA) : const Color(0xFFD1D5DB),
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
