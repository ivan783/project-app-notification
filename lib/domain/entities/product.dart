import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String? id;
  final String name;
  final String description;
  final double price;
  final int stock;
  final String? imageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Product({
    this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
  });

  // 🔹 Factory para crear desde un Map genérico
  factory Product.fromMap(Map<String, dynamic> data, String id) {
    return Product(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      stock: data['stock'] ?? 0,
      imageUrl: data['imageUrl'],
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: (data['updatedAt'] is Timestamp)
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // 🔹 Factory para crear desde DocumentSnapshot de Firestore
  factory Product.fromFirebase(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product.fromMap(data, doc.id);
  }

  // 🔹 Convertir Product a Map para guardar en Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // 🔹 copyWith opcional
  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    int? stock,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
