import 'package:equatable/equatable.dart';

/// Complete product metadata displayed on the Product Detail Page.
class ProductDetail extends Equatable {
  final String id;
  final String name;
  final String brand;
  final String edition;
  final String description;
  final double basePrice;
  final int totalInventory;
  final String imageUrl;       // placeholder / asset path
  final List<String> tags;     // e.g. ['Limited Edition', 'Authenticated', 'Swiss Made']
  final String dropEndsAt;     // e.g. "23:47:12" remaining

  const ProductDetail({
    required this.id,
    required this.name,
    required this.brand,
    required this.edition,
    required this.description,
    required this.basePrice,
    required this.totalInventory,
    required this.imageUrl,
    required this.tags,
    required this.dropEndsAt,
  });

  /// Static mock — the luxury Rolex used throughout the demo.
  static ProductDetail mock() {
    return const ProductDetail(
      id: 'rolex-daytona-fd-001',
      name: 'Daytona Cosmograph',
      brand: 'ROLEX',
      edition: 'Meteorite Dial — Flash Drop #001',
      description:
          'Crafted in 18ct Everose gold with a meteorite dial sourced from '
          'the Gibeon meteorite field. Each piece bears a unique Widmanstätten '
          'pattern — no two are identical. Certified by Rolex Geneva.',
      basePrice: 48500.00,
      totalInventory: 12,
      imageUrl: 'assets/images/rolex_placeholder.png',
      tags: ['Limited Edition', 'Authenticated', 'Swiss Made', 'Meteorite Dial'],
      dropEndsAt: '01:47:33',
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        brand,
        edition,
        description,
        basePrice,
        totalInventory,
        imageUrl,
        tags,
        dropEndsAt,
      ];

  @override
  String toString() => 'ProductDetail(id: $id, name: $name, brand: $brand)';
}
