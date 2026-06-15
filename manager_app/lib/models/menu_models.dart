class MenuCategory {
  final String name;
  final List<MenuSubcategory> subcategories;

  MenuCategory({
    required this.name,
    required this.subcategories,
  });

  static List<MenuCategory> listFromRestaurantJson(
    Map<String, dynamic> json,
  ) {
    final menuMap = json['Menu'] as Map<String, dynamic>;

    return menuMap.entries.map((categoryEntry) {
      final categoryName = categoryEntry.key;
      final categoryData = categoryEntry.value as Map<String, dynamic>;

      final optionsMap = categoryData['Seçenekler'] as Map<String, dynamic>;

      final products = optionsMap.entries.map((productEntry) {
        final productKey = productEntry.key;
        final productData = productEntry.value as Map<String, dynamic>;

        return MenuProduct.fromRestaurantJson(
          key: productKey,
          json: productData,
        );
      }).toList();

      return MenuCategory(
        name: categoryName,
        subcategories: [
          MenuSubcategory(
            name: 'Seçenekler',
            items: products,
          ),
        ],
      );
    }).toList();
  }
}

class MenuSubcategory {
  final String name;
  final List<MenuProduct> items;

  MenuSubcategory({
    required this.name,
    required this.items,
  });
}

class MenuProduct {
  final String id;
  final String name;
  final double price;
  final String portion;
  final List<MenuProduct> variants;

  MenuProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.portion,
    this.variants = const [],
  });

  bool get hasVariants => variants.isNotEmpty;

  factory MenuProduct.fromRestaurantJson({
    required String key,
    required Map<String, dynamic> json,
  }) {
    final variantMap = json['cl_seçenekleri'];

    final variants = <MenuProduct>[];

    if (variantMap is Map<String, dynamic>) {
      for (final variantEntry in variantMap.entries) {
        final variantKey = variantEntry.key;
        final variantData = variantEntry.value as Map<String, dynamic>;

        variants.add(
          MenuProduct(
            id: '${key}_$variantKey',
            name: variantData['isim'] as String,
            price: (variantData['fiyat'] as num).toDouble(),
            portion: variantData['porsiyon'] as String,
          ),
        );
      }
    }

    return MenuProduct(
      id: key,
      name: json['isim'] as String,
      price: (json['fiyat'] as num).toDouble(),
      portion: json['porsiyon'] as String,
      variants: variants,
    );
  }
}