import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../features/product/presentation/pages/product_detail_page.dart';

class FlashDropApp extends StatelessWidget {
  const FlashDropApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // In app.dart, add to MaterialApp:
      showPerformanceOverlay: true,
      title: 'Flash Drop',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const ProductDetailPage(),
    );
  }
}
