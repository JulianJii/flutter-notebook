import 'package:flutter/material.dart';

import '../biometrics_demo.dart';

/// [BiometricsDemo] 的一个轻量级、可路由的包装器——生物识别认证演示已经完整实现，
/// 但没有自己的页面/路由，因此无法从应用中访问。这个包装器为它提供了页面/路由。
class BiometricExampleScreen extends StatelessWidget {
  const BiometricExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Biometric authentication')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: BiometricsDemo(),
      ),
    );
  }
}
