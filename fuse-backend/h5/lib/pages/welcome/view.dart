import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'logic.dart';

/// Auto-login entry. Keeps the 2x2 startup skeleton on screen until the home route opens.
class WelcomePage extends StatelessWidget {
  final logic = Get.find<WelcomeLogic>();

  WelcomePage({super.key});

  static const _bg = Color(0xFF151413);
  static const _card = Color(0xFF242322);
  static const _border = Color(0xFF302F2E);
  static const _block = Color(0xFF343332);

  Widget _cell() {
    return Container(
      padding: const EdgeInsets.all(14),
      alignment: Alignment.bottomLeft,
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Container(
        width: 64,
        height: 12,
        decoration: BoxDecoration(color: _block, borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            children: [
              SizedBox(
                height: 36,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(width: 110, height: 22, decoration: BoxDecoration(color: _block, borderRadius: BorderRadius.circular(8))),
                    Container(width: 28, height: 28, decoration: const BoxDecoration(color: _block, shape: BoxShape.circle)),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: Column(
                  children: [
                    Expanded(child: Row(children: [Expanded(child: _cell()), const SizedBox(width: 12), Expanded(child: _cell())])),
                    const SizedBox(height: 12),
                    Expanded(child: Row(children: [Expanded(child: _cell()), const SizedBox(width: 12), Expanded(child: _cell())])),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
