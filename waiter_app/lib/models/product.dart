class Product {
  final int id;
  final String name;
  final double price;
  final String category;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
  });

  // JSON'dan Product nesnesi üreten fonksiyon
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      // JSON'da int gelse bile double'a güvenli çevirmek için (json['price'] as num).toDouble() kullanılır
      price: (json['price'] as num).toDouble(), 
      category: json['category'] as String,
    );
  }

  // İleride backend'e veri göndermek istersen nesneyi JSON'a çeviren fonksiyon
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'category': category,
    };
  }
}