import 'package:flutter/material.dart';

class Page3 extends StatelessWidget {
  final VoidCallback onFinish;
  const Page3({super.key, required this.onFinish});

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
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuCttl63jDfyLUXjnbxwwH807wPlbfdg9GkXEtPW6xPgkelVCvU0HnRBPuf3xZfXOufPt1r0teB8qj9n4Qc-t5RErle36o8t1Y03b6B-8kaUMqAgij6-_bHvnHsYIWJI6cKMQjvJpGqnAi7T3ngD3NZOMIoj-zY3iqWxE-LfpHVpj1JZl1hn0BNLYc06taVP_Ob2rjmRHVmJJBoINlxySuc-veVvIOxIsgmCJktOc1AIsqC-CepuvLmYRaDf9kbOXCYH15WpYyf3kv4',
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
                    const Text(
                      'Birlikte güçlüyüz',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Deneyimlerinizi paylaşın, destek bulun ve yalnız olmadığınızı hissedin.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 22),
                    const _Dots(activeIndex: 2),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: onFinish,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF137FEC),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Giriş Yap',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
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
            color: active ? const Color(0xFF137FEC) : const Color(0xFFD1D5DB),
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
